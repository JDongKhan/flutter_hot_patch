import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart' show log;
import 'style_translators.dart';

// ===========================================================================
// 统一「Dart 类 → JS 类」转换处理器
//
// 不按用途分流：任何普通 Dart 类（value object 如 User、ChangeNotifier 状态
// 对象如 MyModel、静态单例如 MyColors）都按同一套「如何声明 +
// 如何被 State 字段 / 构建 / 方法引用」处理。
//
//   - 实例字段    → constructor 里 this.x（this.x 形参取值 / 字段初始化器）
//   - static 字段 → JS 属性（纯 static 类渲染成 const 对象）
//   - 实例方法    → class 方法；getter → get 访问器
//   - extends ChangeNotifier → extends NotifierBase（运行时注入的 JS 基类）
//
// 表达式/语句翻译统一以 [FieldScope] 为键：组件动作（字段=State 属性表）与
// 模型方法（字段=模型自身实例字段）走同一套 translator。
// ===========================================================================

/// 类的一个字段（实例或 static）。
class ClassField {
  final String name;
  final String typeName;
  final Expression? initializer; // 无初始化则 null
  final bool isStatic;
  const ClassField({
    required this.name,
    required this.typeName,
    this.initializer,
    this.isStatic = false,
  });
}

/// 类的实例方法 / getter。
class ClassMethod {
  final String name;
  final List<String> params; // 形参名（JS 一比一）
  final bool isAsync;
  final bool isGetter;
  final FunctionBody body;
  const ClassMethod({
    required this.name,
    required this.params,
    this.isAsync = false,
    this.isGetter = false,
    required this.body,
  });
}

/// 一个 Dart 类翻译成 JS 后的中立描述（按「声明」建模，不看用途）。
class ClassInfo {
  final String name;
  final String sourceFile; // dart 源文件路径（用于推导 import/相对产物）
  final String? superType; // extends 的类名（如 ChangeNotifier）
  final List<ClassField> instanceFields;
  final List<ClassField> staticFields;
  final List<ClassMethod> methods; // 含 getter
  final Set<String> ctorParams; // this.x 构造形参名

  const ClassInfo({
    required this.name,
    required this.sourceFile,
    this.superType,
    required this.instanceFields,
    required this.staticFields,
    required this.methods,
    this.ctorParams = const {},
  });

  bool get isStaticOnly => instanceFields.isEmpty && methods.isEmpty;

  Set<String> get instanceFieldNames =>
      {for (final f in instanceFields) f.name};

  Set<String> get methodNames => {for (final m in methods) m.name};
}

/// 提取 ClassDeclaration → ClassInfo（统一入口）。
///
/// getter/setter 只保留 getter；static 方法不翻译（Dart static 方法无 JS
/// 等价物，通常业务不用）；构造收集 this.x 形参名。
ClassInfo classInfoOf(ClassDeclaration decl, String sourceFile) {
  final instanceFields = <ClassField>[];
  final staticFields = <ClassField>[];
  final methods = <ClassMethod>[];
  final ctorParams = <String>{};

  // 构造器 this.x 形参（DefaultFormalParameter 解包）
  for (final m in decl.members) {
    if (m is ConstructorDeclaration) {
      for (final p in m.parameters.parameters) {
        final inner = p is DefaultFormalParameter ? p.parameter : p;
        if (inner is FieldFormalParameter) ctorParams.add(inner.name.lexeme);
      }
    }
  }

  for (final m in decl.members) {
    if (m is FieldDeclaration) {
      final typeName = m.fields.type?.toSource() ?? 'dynamic';
      for (final v in m.fields.variables) {
        final f = ClassField(
          name: v.name.lexeme,
          typeName: typeName,
          initializer: v.initializer,
          isStatic: m.isStatic,
        );
        if (m.isStatic) {
          staticFields.add(f);
        } else {
          instanceFields.add(f);
        }
      }
    } else if (m is MethodDeclaration) {
      if (m.isGetter) {
        methods.add(ClassMethod(
          name: m.name.lexeme,
          params: const [],
          isGetter: true,
          body: m.body,
        ));
      } else if (m.isSetter || m.isStatic) {
        // static 方法 / setter：暂不翻译
      } else {
        final params = <String>[
          for (final p in (m.parameters?.parameters ?? const <FormalParameter>[]))
            (p is DefaultFormalParameter ? p.parameter : p).name?.lexeme ?? '',
        ];
        methods.add(ClassMethod(
          name: m.name.lexeme,
          params: params,
          isAsync: m.body.isAsynchronous,
          body: m.body,
        ));
      }
    }
  }

  String? superType;
  final ext = decl.extendsClause;
  if (ext != null) superType = ext.superclass.toSource();

  return ClassInfo(
    name: decl.name.lexeme,
    sourceFile: sourceFile,
    superType: superType,
    instanceFields: instanceFields,
    staticFields: staticFields,
    methods: methods,
    ctorParams: ctorParams,
  );
}

// ---------------------------------------------------------------------------
// FieldScope：把 Dart 标识符解析成 JS 引用的抽象
// ---------------------------------------------------------------------------

/// 字段作用域：决定一个 Identifier 怎么转 JS。
///
/// 组件动作：字段名 → propByField[name]（`_count`→`this._count`），形参 extraVars。
/// 模型方法：字段名 → instanceFields（`_n`→`this._n`），形参、白名单方法。
class FieldScope {
  final Map<String, String> propByField; // 组件：字段→属性名
  final Set<String> instanceFields; // 模型：自身实例字段名
  final Set<String> params; // 形参名（原样引用）
  final Set<String> methods; // 裸调白名单（this.method()）

  /// 方法体内声明的局部变量（`var data = ...`），后续引用原样返回。
  final Set<String> localVars;

  /// 宿主注入方法表：`类名 → {方法名 → 通道名}`（见 @HostInjected）；
  /// 顶层函数（全局方法）挂在空串 key 下（`'' → {函数名 → 通道名}`）。
  /// 命中时调用点整体翻译成 `__jsui.host("通道名", 参数载荷)`（载荷形态见
  /// [hostArgsJs]）——参数个数、是否具名、返回值类型都无关（宿主侧用
  /// Function.apply 调实现）。
  final Map<String, Map<String, String>> hostMethods;

  FieldScope({
    this.propByField = const {},
    this.instanceFields = const {},
    this.params = const {},
    this.methods = const {},
    this.hostMethods = const {},
    Set<String>? localVars,
  }) : localVars = localVars ?? {};

  /// 该名字是否本 scope 可解析的字段。
  bool hasField(String name) =>
      propByField.containsKey(name) ||
      instanceFields.contains(name) ||
      localVars.contains(name);

  /// 字段 Identifier → JS 引用（`this.x`）；形参/局部变量原样返回；未知返回 null。
  String? fieldRef(String name) {
    if (params.contains(name)) return name;
    if (localVars.contains(name)) return name;
    final p = propByField[name];
    if (p != null) return 'this.$p';
    if (instanceFields.contains(name)) return 'this.$name';
    return null;
  }

  bool isMethod(String name) => methods.contains(name);
}

// ===========================================================================
// Flutter SDK → JS 基类 映射表（便于后续扩展）
//
// 统一「Dart 类 → JS 类」处理器的扩展点：除 StatefulWidget 子类走组件翻译
// （widget_translator）较特殊外，其余普通类 1:1 还原。具体要把哪些 Flutter
// SDK 类转成 JS 基类/宿主能力，由这张表按需登记即可，生成器逻辑零改动。
//
//   key = Dart 父类名（extends 命中的类名）
//   value = 生成的 JS 基类名（运行时需注入该基类，见 hot_patch 的
//           JsRuntimeManager -> NotifierBase）
//
// 额外语义（针对登记在表的类）：
//   - 渲染时自动 `extends <value>` + constructor 里 `super()`
//   - 类方法体裸调白名单自动加上基类能力方法（如 ChangeNotifier 的
//     notifyListeners）
//
// 后续新增 SDK 支持 = 往这张表加一行 +（如需要）在运行时注册对应基类 + 在
// builtin_translators.dart 登记对应 widget 翻译策略。
const Map<String, String> sdkSuperClassMap = {
  'ChangeNotifier': 'ChangeNotifier',
};

/// 由父类名查 JS 基类名；未登记返回 null。
String? sdkBaseName(ClassInfo info) => sdkSuperClassMap[info.superType];

// ---------------------------------------------------------------------------
// 表达式 / 语句翻译（以 FieldScope + 已知类表为键）
// ---------------------------------------------------------------------------

/// 字面量 → JS 字面量（字符串带双引号、数字/布尔原样）。不可翻译返回 null。
String? literalToJs(Expression? e) {
  if (e == null) return null;
  if (e is StringLiteral) return jsString(e.stringValue ?? '');
  if (e is IntegerLiteral) return e.value?.toString();
  if (e is DoubleLiteral) return e.value.toString();
  if (e is BooleanLiteral) return e.value.toString();
  return null;
}

/// 读位置表达式 → JS 表达式（this._model.n / this._model / 字面量 / 形参）。
String? exprToJs(Expression e, FieldScope scope, Map<String, ClassInfo> classes) {
  // Platform.isAndroid 等（PrefixedIdentifier 是 Identifier 子类，必须先判）
  if (e is PrefixedIdentifier && e.prefix.name == 'Platform') {
    final flag = platformFlagJs(e.identifier.name);
    if (flag != null) return flag;
  }
  // 通用 `a.b`：前缀与属性都是简单标识符时 analyzer 用 PrefixedIdentifier
  // （不是 PropertyAccess），如 `ids.length` / `_user.name` / `m.keys`。
  // 不在这里拦下来，它会落到下面的 Identifier 分支，用整串 `a.b` 去查字段
  // 必然失败——这是「属性访问普遍翻译不出来」的根因。
  if (e is PrefixedIdentifier) {
    final p = scope.fieldRef(e.prefix.name);
    if (p != null) return '$p.${e.identifier.name}';
    // prefix 是大写开头的外部类名（如 Network.post）→ 原样保留。
    if (e.prefix.name.isNotEmpty &&
        RegExp(r'^[A-Z]').hasMatch(e.prefix.name)) {
      return '${e.prefix.name}.${e.identifier.name}';
    }
    return null;
  }
  // StringInterpolation 是 StringLiteral 子类，必须先判（否则被字面量分支
  // 吞成 ""——插值表达式丢失）：拼接触发与 _logArgJs 同一逻辑。
  if (e is StringInterpolation) return _logArgJs(e, scope, classes);
  // `a ?? b` → JS 原生空值合并（方法体内如 `_switchOn = v ?? false`）
  if (e is BinaryExpression && e.operator.lexeme == '??') {
    final l = exprToJs(e.leftOperand, scope, classes);
    final r = exprToJs(e.rightOperand, scope, classes);
    if (l == null || r == null) return null;
    return '($l ?? $r)';
  }
  if (e is Identifier) {
    // kDebugMode / kReleaseMode → 运行时注入的全局标志
    final flag = globalFlagJs(e.name);
    if (flag != null) return flag;
    // State.mounted：JS 组件基类有 __unmounted 标记，未卸载即视为已挂载
    if (e.name == 'mounted') return '!this.__unmounted';
    return scope.fieldRef(e.name);
  }
  final lit = literalToJs(e);
  if (lit != null) return lit;
  if (e is PropertyAccess && e.target is Identifier &&
      (e.target as Identifier).name == 'Platform') {
    // Platform.isAndroid 等 → 运行时注入的平台标志
    final flag = platformFlagJs(e.propertyName.name);
    if (flag != null) return flag;
  }
  if (e is PropertyAccess && e.target != null) {
    final t = exprToJs(e.target!, scope, classes);
    if (t == null) return null;
    final op = e.operator.lexeme;
    if (op == '?.') {
      return '($t == null ? null : $t.${e.propertyName.name})';
    }
    return '$t.${e.propertyName.name}';
  }
  // 下标访问 `a[b]`（如 `userMap["code"]`）：JS 的方括号语法一一对应。
  // 与上面的通用 `a.b` 同理，不在 exprToJs 里兜住就会整条翻译失败（在插值里
  // 表现为片段被丢弃，如 `"用户信息:${userMap["code"]}"` → `"用户信息:"`）。
  if (e is IndexExpression) {
    final tgt = e.target;
    if (tgt == null) return null;
    final t = exprToJs(tgt, scope, classes);
    final i = exprToJs(e.index, scope, classes);
    if (t == null || i == null) return null;
    return '$t[$i]';
  }
  if (e is ParenthesizedExpression) {
    final inner = exprToJs(e.expression, scope, classes);
    return inner == null ? null : '($inner)';
  }
  if (e is MethodInvocation) return methodCallExprJs(e, scope, classes);
  return null;
}

/// 赋值右侧：字面量 / 形参 / 字段读 / 模型构造 `new X({...})` /
/// 插值、`??` 等其余形态兜底走 exprToJs。
String? rhsToJs(Expression e, FieldScope scope, Map<String, ClassInfo> classes) {
  // StringInterpolation 是 StringLiteral 子类，必须先判（否则被吞成 ""）
  if (e is StringInterpolation) return _logArgJs(e, scope, classes);
  // `await <expr>` 统一在这里处理：声明初始化、赋值右侧、实参、独立语句
  // 全都经过 rhsToJs，await 不再只认声明那一种位置（原来 `_x = await f()`
  // 会整条丢掉）。
  if (e is AwaitExpression) {
    final v = _awaitInnerJs(e.expression, scope, classes);
    return v == null ? null : 'await $v';
  }
  final lit = literalToJs(e);
  if (lit != null) return lit;
  // PrefixedIdentifier（`a.b`）不是单纯字段名，交给 exprToJs 的属性分支；
  // 若走下面的 Identifier 分支会用整串名字查字段而必然失败。
  if (e is PrefixedIdentifier) return exprToJs(e, scope, classes);
  if (e is Identifier) return scope.fieldRef(e.name);
  if (e is InstanceCreationExpression) return modelCtorToJs(e, scope, classes);
  // 集合字面量：与 JS 对象/数组一一对应（元素递归翻译）。
  // 缺了这两条，`Network.post({"name": name})` 这类调用会因「参数翻译不了」
  // 整体返回 null，调用方再把整条语句丢掉（原来的静默丢代码就出在这里）。
  if (e is SetOrMapLiteral) return _collectionLiteralJs(e, scope, classes);
  if (e is ListLiteral) return _listLiteralJs(e.elements, scope, classes);
  return exprToJs(e, scope, classes);
}

/// `await <expr>` 里的 `<expr>`（不含 await 前缀）。
/// 特殊形态 `Future.delayed(Duration(...))` → setTimeout Promise——JS 没有
/// 等价的 Dart 异步延迟 API，只映射这一种；其余 await 走普通表达式翻译。
String? _awaitInnerJs(
  Expression inner,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final delay = delayedMsJs(inner);
  if (delay != null) {
    return 'new Promise(function(r){ setTimeout(r, $delay); })';
  }
  return rhsToJs(inner, scope, classes);
}

/// `Future.delayed(Duration(seconds: n))` → setTimeout 毫秒数（不是则 null）。
String? delayedMsJs(Expression e) {
  if (e is! MethodInvocation || e.methodName.name != 'delayed') return null;
  final target = e.target;
  if (target == null || target.toSource() != 'Future') return null;
  final args = e.argumentList.arguments;
  if (args.isEmpty) return null;
  final dur = args.first;
  String? unit;
  double? value;
  if (dur is InstanceCreationExpression &&
      dur.constructorName.type.name2.lexeme == 'Duration') {
    for (final a in dur.argumentList.arguments) {
      if (a is NamedExpression) {
        final lit = a.expression;
        if (lit is IntegerLiteral) {
          if (unit != null) return null; // 多个时间单位不支持
          unit = a.name.label.name;
          value = (lit.value ?? 0).toDouble();
        } else if (lit is DoubleLiteral) {
          if (unit != null) return null;
          unit = a.name.label.name;
          value = lit.value;
        }
      }
    }
  }
  if (unit == null || value == null) return null;
  final ms = switch (unit) {
    'seconds' => value * 1000,
    'milliseconds' => value,
    'microseconds' => value / 1000,
    'minutes' => value * 60 * 1000,
    _ => null,
  };
  if (ms == null) return null;
  return ms == ms.roundToDouble() ? '${ms.round()}' : '$ms';
}

/// `{k: v, ...}` → JS 对象字面量；`{a, b}`（Set）→ `new Set([a, b])`。
String? _collectionLiteralJs(
  SetOrMapLiteral e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final entries = e.elements;
  // 无 resolution 下不依赖 isMap：元素全是 entry 即 Map，否则按 Set 处理。
  if (entries.every((el) => el is MapLiteralEntry)) {
    final parts = <String>[];
    for (final el in entries.whereType<MapLiteralEntry>()) {
      final k = rhsToJs(el.key, scope, classes);
      final v = rhsToJs(el.value, scope, classes);
      if (k == null || v == null) return null;
      parts.add('$k: $v');
    }
    return '{${parts.join(', ')}}';
  }
  final items = _listLiteralJs(entries, scope, classes);
  return items == null ? null : 'new Set($items)';
}

/// `[a, b]` → JS 数组字面量。展开（`...xs`）与 collection-if/for 不支持。
String? _listLiteralJs(
  NodeList<CollectionElement> elements,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final parts = <String>[];
  for (final el in elements) {
    if (el is! Expression) return null;
    final v = rhsToJs(el, scope, classes);
    if (v == null) return null;
    parts.add(v);
  }
  return '[${parts.join(', ')}]';
}

/// 模型构造调用 → JS：`new User({name:..., age:...})`。
/// 位置参数按类实例字段声明顺序映射；命名参数按 label。
String? modelCtorToJs(
  InstanceCreationExpression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) =>
    modelCtorFromPartsJs(e.constructorName.type.name2.lexeme,
        e.argumentList.arguments.toList(), scope, classes);

/// 按「构造名 + 参数」生成 `new X({...})`。供 modelCtorToJs（InstanceCreation）
/// 与字段初始化的 MethodInvocation 形式（parseString 无 resolution 下 `Foo()`
/// 会被解析成 MethodInvocation）共用同一套映射逻辑。
String? modelCtorFromPartsJs(
  String name,
  List<Expression> args,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final info = classes[name];
  if (info == null) return null;
  final named = <String>[];
  final positional = <String>[];
  for (final a in args) {
    if (a is NamedExpression) {
      final v = rhsToJs(a.expression, scope, classes);
      if (v == null) return null;
      named.add('${a.name.label.name}: $v');
    } else {
      final v = rhsToJs(a, scope, classes);
      if (v == null) return null;
      positional.add(v);
    }
  }
  final entries = <String>[];
  for (var i = 0; i < info.instanceFields.length && i < positional.length; i++) {
    entries.add('${info.instanceFields[i].name}: ${positional[i]}');
  }
  entries.addAll(named);
  return 'new $name({${entries.join(', ')}})';
}

/// 方法调用（语句位置，带分号）：`_model.inc()` → `this._model.inc();`；
/// 裸调用 `notifyListeners()`（MethodScope 白名单）→ `this.notifyListeners();`。
String? methodCallStmtJs(
  MethodInvocation e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  // Dart 日志 → JS 原生日志方法（运行时注入 console 对象，桥到 log 服务）：
  // debugPrint → console.debug（仅 debug 模式输出）、print → console.log。
  // 参数支持字符串插值（拼接翻译）。
  if (e.target == null) {
    final name = e.methodName.name;
    if (name == 'debugPrint' || name == 'print') {
      final args = e.argumentList.arguments;
      final v = args.isEmpty ? '""' : _logArgJs(args.first, scope, classes);
      if (v == null) return null;
      final method = name == 'debugPrint' ? 'debug' : 'log';
      return 'console.$method($v);';
    }
  }
  final call = methodCallExprJs(e, scope, classes);
  return call == null ? null : '$call;';
}

/// 日志参数 → JS 表达式：字符串 / 插值拼接 / 字段引用 / 属性链。
String? _logArgJs(
  Expression a,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  // 注意：StringInterpolation 是 StringLiteral 的子类，必须先判插值
  //（否则 stringValue 会把插值表达式拼进字面量、丢失 this._x 引用）。
  if (a is StringInterpolation) {
    final parts = <String>[];
    for (final el in a.elements) {
      if (el is InterpolationString) {
        if (el.value.isNotEmpty) parts.add(jsString(el.value));
      } else if (el is InterpolationExpression) {
        final v = exprToJs(el.expression, scope, classes);
        if (v != null) {
          parts.add(v);
        } else {
          // 丢片段会让产物「看着对、其实少东西」（如 `"用户信息:$x"` →
          // `"用户信息:"`），故必须出声，不能静默。
          log.warning('[ui_component_generator] 插值片段无法翻译，已在 JS 产物中'
              '丢失：\${${el.expression.toSource()}}');
        }
      }
    }
    return parts.isEmpty ? '""' : parts.join(' + ');
  }
  return exprToJs(a, scope, classes);
}

/// 混合调用时承载**位置实参**的哨兵键。
///
/// 用哨兵键而不是靠「有没有 `p`/`n` 两个键」来猜，是因为 Dart 标识符
/// 不允许 `@`：任何具名形参都不可能叫 `@args`，判定零歧义。
const String hostPositionalKey = '@args';

/// 宿主注入调用的参数载荷（按实参形态给最简编码）。
///
///   - 纯位置：数组 `[a, b]`（运行时用 `Array.isArray` 判定）
///   - 纯具名：具名表本身 `{"times": 2}`
///   - 混合：具名表 + [hostPositionalKey] 装位置实参
///     `{"@args": ["hi"], "times": 2}`
///
/// 位置实参与具名实参**必须分开传**，宿主侧才能用
/// `Function.apply(impl, 位置, 具名)` 还原 Dart 调用语义。绝不能像普通 JS
/// 调用那样把具名实参扁平化进数组：`Network.post(params: {...})` 会变成 1 个
/// 位置实参，而该函数只接受具名参数 `params`，`Function.apply` 直接抛异常。
///
/// 实参**个数不限**（位置数组与具名键数量都无上限）；未传的可选位置参数
/// (`[int b]`) / 具名默认值 (`int times = 1`) 由 Dart 函数自身兜底，
/// `Function.apply` 自动走默认值。
String hostArgsJs(List<String> positional, List<String> named) {
  if (named.isEmpty) return '[${positional.join(', ')}]';
  if (positional.isEmpty) return '{${named.join(', ')}}';
  return '{${jsString(hostPositionalKey)}: [${positional.join(', ')}], '
      '${named.join(', ')}}';
}

/// 闭包参数 → JS 函数表达式：`() {...}` → `function(){ ... }`、
/// `(v) => expr` → `function(v){ return <expr>; }`。
///
/// 闭包体逐语句翻译，其中 `setState(() {...})` 展开为
/// `this.setState(function(){ ... })`（与组件方法体里的 setState 同构）。
String? closureToJs(
  FunctionExpression fn,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final params = <String>[];
  for (final p in fn.parameters?.parameters ?? const <FormalParameter>[]) {
    final name = p is DefaultFormalParameter
        ? p.parameter.name?.lexeme
        : p.name?.lexeme;
    if (name != null && name.isNotEmpty) params.add(name);
  }
  final pjs = params.join(', ');
  final body = fn.body;
  // 一律输出箭头函数：this 词法绑定到定义处（组件实例），与 Dart 闭包
  // 捕获 this 的语义一致——回调（如 addListener 闭包）由宿主经 invoke
  // 普通调用触发时 this 不会丢失，无需 .bind。引擎为 flutter_js
  // （macOS/iOS JavaScriptCore、Android QuickJS），均完整支持 ES6。
  if (body is ExpressionFunctionBody) {
    // 表达式体也按语句翻译（赋值 `_x = rhs`、方法调用等），
    // 返回值无意义时保留语句即可（Dart 闭包返回值在 JS 侧常被忽略）。
    final v = exprStmtToJs(body.expression, scope, classes);
    if (v == null) return null;
    return '($pjs) => { $v }';
  }
  if (body is BlockFunctionBody) {
    final parts = <String>[];
    for (final s in body.block.statements) {
      if (s is ExpressionStatement) {
        final t = closureBodyStmtJs(s.expression, scope, classes);
        if (t != null) parts.add(t);
      }
    }
    if (parts.isEmpty) return null;
    return '($pjs) => { ${parts.join(' ')} }';
  }
  return null;
}

/// 闭包体内的语句翻译：setState(...) 展开 + 其余走 exprStmtToJs。
String? closureBodyStmtJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is MethodInvocation &&
      e.methodName.name == 'setState' &&
      e.argumentList.arguments.length == 1) {
    final fn = e.argumentList.arguments.first;
    if (fn is FunctionExpression) {
      final inner = closureToJs(fn, scope, classes);
      return inner == null
          ? 'this.setState(function(){});'
          : 'this.setState($inner);';
    }
    return null;
  }
  return exprStmtToJs(e, scope, classes);
}

/// 方法调用（表达式位置）：返回 `obj.method(args)` / `this.method(args)`。
String? methodCallExprJs(
  MethodInvocation e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  // `context.watch<T>()` / `context.read<T>()`（provider 包）→ 运行时挂载的
  // 实例方法：__watch（取最近模型 + 订阅局部刷新）/ __read（仅取，不订阅）。
  // 类型参数即模型类名（__lookupProvider 按 key+model 找最近实例）。
  final tgt = e.target;
  if (tgt is Identifier && tgt.name == 'context') {
    final name = e.methodName.name;
    if ((name == 'watch' || name == 'read') &&
        e.argumentList.arguments.isEmpty) {
      final ta = e.typeArguments?.arguments;
      if (ta != null && ta.length == 1 && ta.first is NamedType) {
        final model = (ta.first as NamedType).name2.lexeme;
        final method = name == 'watch' ? '__watch' : '__read';
        return 'this.$method(${jsString(model)})';
      }
      return null;
    }
  }
  final args = e.argumentList.arguments;
  final argJs = <String>[]; // 普通调用：位置化扁平（JS 无具名参数）
  final posJs = <String>[]; // 宿主注入：位置实参
  final namedJs = <String>[]; // 宿主注入：具名实参（`"名": 值`）
  for (final a in args) {
    // 闭包参数（addListener(() {...}) / TextButton(onPressed: () => ...) 等）：
    // 翻译成 JS 函数表达式，匿名天然支持——不合成方法名、无重名问题。
    // 闭包体逐语句翻译，setState(...) 展开为 this.setState(function(){...})。
    if (a is FunctionExpression) {
      final fnJs = closureToJs(a, scope, classes);
      if (fnJs == null) return null;
      argJs.add(fnJs);
      posJs.add(fnJs);
      continue;
    }
    // 命名方法引用（`_controller.addListener(_onControllerChanged)`）：Dart
    // tear-off 语义 → 箭头包装（this 词法绑定组件实例，与匿名闭包形态一致），
    // 参数透传以便用于带参回调（builder 等）。仅当名字是本组件方法时包装，
    // 状态字段/局部变量照常 rhsToJs。
    if (a is Identifier && scope.isMethod(a.name)) {
      final wrap = '(...args) => this.${a.name}(...args)';
      argJs.add(wrap);
      posJs.add(wrap);
      continue;
    }
    if (a is NamedExpression) {
      final v = rhsToJs(a.expression, scope, classes);
      if (v == null) return null;
      argJs.add(v);
      namedJs.add('${jsString(a.name.label.name)}: $v');
    } else {
      final v = rhsToJs(a, scope, classes);
      if (v == null) return null;
      argJs.add(v);
      posJs.add(v);
    }
  }
  // 宿主注入（@HostInjected）：static 调用 `AccountCenter.getUserName(a)`
  // 整体替换为 `__jsui.host("通道名", {p: [a], n: {...}})`（返回 Promise，可 await）。
  final hostTarget = e.target;
  if (hostTarget is Identifier) {
    final channel = scope.hostMethods[hostTarget.name]?[e.methodName.name];
    if (channel != null) {
      return '__jsui.host(${jsString(channel)}, ${hostArgsJs(posJs, namedJs)})';
    }
  }
  final passed = argJs.join(', ');
  final target = e.target;
  if (target == null) {
    // 顶层函数（全局方法）：@HostInjected → `__jsui.host("通道", {p, n})`。
    final topChannel = scope.hostMethods['']?[e.methodName.name];
    if (topChannel != null) {
      return '__jsui.host(${jsString(topChannel)}, ${hostArgsJs(posJs, namedJs)})';
    }
    if (!scope.isMethod(e.methodName.name)) return null;
    return 'this.${e.methodName.name}($passed)';
  }
  if (target is Identifier) {
    final ref = scope.fieldRef(target.name);
    if (ref != null) return '$ref.${e.methodName.name}($passed)';
  }
  final t = exprToJs(target, scope, classes);
  if (t != null) return '$t.${e.methodName.name}($passed)';
  return null;
}

/// 一条表达式语句 → JS 语句（带分号）。
///
/// 支持：`_x++ / _x-- / ++_x / --_x`（字段→this）、赋值 `_x = rhs / _x op= rhs`、
/// 方法调用（对象方法 / 白名单裸调）。不可翻译返回 null（由调用方丢弃）。
String? exprStmtToJs(Expression e, FieldScope scope, Map<String, ClassInfo> classes) {
  // _x++ / ++_x / _x--
  if (e is PostfixExpression && e.operand is Identifier) {
    final ref = scope.fieldRef((e.operand as Identifier).name);
    if (ref != null) {
      final delta = e.operator.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$ref += $delta;';
    }
    return null;
  }
  if (e is PrefixExpression && e.operand is Identifier) {
    final ref = scope.fieldRef((e.operand as Identifier).name);
    if (ref != null) {
      final delta = e.operator.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$ref += $delta;';
    }
    return null;
  }
  if (e is AssignmentExpression && e.leftHandSide is Identifier) {
    final ref = scope.fieldRef((e.leftHandSide as Identifier).name);
    if (ref != null) {
      final rhs = rhsToJs(e.rightHandSide, scope, classes);
      if (rhs != null) return '$ref ${e.operator.lexeme} $rhs;';
    }
    return null;
  }
  // 独立语句 `await <expr>;`：await 的翻译统一在 rhsToJs 里。
  if (e is AwaitExpression) {
    final v = rhsToJs(e, scope, classes);
    return v == null ? null : '$v;';
  }
  if (e is MethodInvocation) return methodCallStmtJs(e, scope, classes);
  return null;
}

// ---------------------------------------------------------------------------
// 类 JS 声明渲染
// ---------------------------------------------------------------------------

/// 翻译一个模型/状态类的方法体 → JS（字段表 = 类自身实例字段）。
String translateClassMethodBody(
  ClassInfo info,
  ClassMethod m,
  Map<String, ClassInfo> classes, {
  Map<String, Map<String, String>> hostMethods = const {},
}) {
  final scope = FieldScope(
    instanceFields: info.instanceFieldNames,
    params: m.params.toSet(),
    methods: {
      ...info.methodNames,
      if (sdkBaseName(info) != null) 'notifyListeners',
    },
    hostMethods: hostMethods,
  );
  final stmts = <String>[];
  final body = m.body;
  if (body is ExpressionFunctionBody) {
    final t = exprStmtToJs(body.expression, scope, classes);
    if (t != null) stmts.add(t);
  } else if (body is BlockFunctionBody) {
    for (final s in body.block.statements) {
      if (s is ExpressionStatement) {
        final ex = s.expression;
        if (ex is MethodInvocation && ex.target is SuperExpression) continue;
        final t = exprStmtToJs(ex, scope, classes);
        if (t != null) stmts.add(t);
      } else if (s is ReturnStatement) {
        // `return "22";` 是 ReturnStatement（不是 ExpressionStatement），
        // 需单独翻译为 `return <expr>;`，否则 async 方法体被整体丢弃。
        final e = s.expression;
        final v = e == null ? null : rhsToJs(e, scope, classes);
        if (v != null) stmts.add('return $v;');
      } else if (s is VariableDeclarationStatement) {
        // `dynamic data = await Network.post(...);` → `var data = await ...;`
        for (final v in s.variables.variables) {
          final name = v.name.lexeme;
          final init = v.initializer;
          if (init != null) {
            final rhs = rhsToJs(init, scope, classes);
            if (rhs != null) {
              stmts.add('var $name = $rhs;');
              // 把局部变量加入 scope，后续引用（如 print("$data")）能解析到。
              scope.localVars.add(name);
            }
          } else {
            stmts.add('var $name;');
            scope.localVars.add(name);
          }
        }
      }
    }
  }
  return stmts.isEmpty ? '/* 空方法体 */' : stmts.join(' ');
}

/// getter 表达式体 → JS 返回值表达式（`int get n => _n` → `this._n`）。
String? _getterReturnJs(ClassInfo info, ClassMethod m) {
  Expression? e;
  final body = m.body;
  if (body is ExpressionFunctionBody) {
    e = body.expression;
  } else if (body is BlockFunctionBody) {
    for (final s in body.block.statements) {
      if (s is ReturnStatement) {
        e = s.expression;
        break;
      }
    }
  }
  if (e == null) return 'null';
  final scope = FieldScope(instanceFields: info.instanceFieldNames);
  return exprToJs(e, scope, const {}) ?? 'null';
}

/// 类声明 → JS（export 可选）。含 constructor / 方法 / getter / extends NotifierBase。
String renderClassDecl(
  ClassInfo info,
  Map<String, ClassInfo> classes, {
  bool exported = false,
  Map<String, Map<String, String>> hostMethods = const {},
}) {
  final b = StringBuffer();
  b.write(exported ? 'export class ' : 'class ');
  b.write(info.name);
  final base = sdkBaseName(info);
  if (base != null) b.write(' extends $base');
  b.write(' {\n');

  // constructor
  b.write('  constructor(args) {\n');
  if (base != null) b.write('    super();\n');
  for (final f in info.instanceFields) {
    String def;
    if (f.initializer != null) {
      def = literalToJs(f.initializer) ?? 'undefined';
    } else {
      def = 'undefined';
    }
    if (info.ctorParams.contains(f.name)) {
      b.write(
        '    this.${f.name} = (args && args.${f.name} !== undefined) '
        '? args.${f.name} : $def;\n',
      );
    } else {
      b.write('    this.${f.name} = $def;\n');
    }
  }
  b.write('  }\n');

  // 方法 + getter
  for (final m in info.methods) {
    if (m.isGetter) {
      b.write('  get ${m.name}() { return ${_getterReturnJs(info, m)}; }\n');
    } else {
      final fn = m.isAsync ? 'async ' : '';
      final body =
          translateClassMethodBody(info, m, classes, hostMethods: hostMethods);
      b.write('  $fn${m.name}(${m.params.join(', ')}) { $body }\n');
    }
  }

  b.write('}');
  return b.toString();
}

/// 纯 static 类 → JS const 对象：`const MyColors = { a: v, b: v };`。
/// [valueRenderer] 由调用方提供（颜色/字符串/字面量统一求值）。
String renderStaticConst(
  ClassInfo info, {
  required String Function(ClassField field) valueRenderer,
  bool exported = false,
}) {
  final prefix = exported ? 'export const ' : 'const ';
  final entries =
      info.staticFields.map((f) => '  ${f.name}: ${valueRenderer(f)}').join(',\n');
  return '$prefix${info.name} = {\n$entries\n};';
}

/// JS 双引号字符串字面量。
String jsString(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  return '"$escaped"';
}