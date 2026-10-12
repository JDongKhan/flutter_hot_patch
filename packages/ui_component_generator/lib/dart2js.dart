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
///
/// 初始值二选一：普通类给 [initializer]（AST，渲染期翻译）；组件路径
/// （字段翻译已由组件翻译器完成）直接给预渲染好的 [jsInitial] JS 表达式。
class ClassField {
  final String name;
  final String typeName;
  final Expression? initializer; // 无初始化则 null
  final bool isStatic;
  final String? jsInitial; // 预渲染 JS 初始值（非 null 时优先于 initializer）
  const ClassField({
    required this.name,
    required this.typeName,
    this.initializer,
    this.isStatic = false,
    this.jsInitial,
  });
}

/// 类的实例方法 / getter。
///
/// 方法体二选一：普通类给 [body]（AST，渲染期翻译）；组件路径给预渲染好的
/// [bodyJs] JS 语句串（组件动作体已由组件翻译器完成）。
class ClassMethod {
  final String name;
  final List<String> params; // 形参名（JS 一比一）
  final bool isAsync;
  final bool isGetter;
  final FunctionBody? body;
  final String? bodyJs; // 预渲染方法体（非 null 时优先于 body）
  const ClassMethod({
    required this.name,
    required this.params,
    this.isAsync = false,
    this.isGetter = false,
    this.body,
    this.bodyJs,
  });
}

/// 一个 Dart 类翻译成 JS 后的中立描述（按「声明」建模，不看用途）。
///
/// 同一份模型承载两条来源：普通类（字段/方法给 AST，渲染期翻译）与组件
/// （字段/方法给预渲染 JS，另带 build 树等组件专属数据）。两者的 JS 声明
/// 形状一致，差异只在渲染期由 [component] 这一个参数控制（类名后缀/工厂）。
class ClassInfo {
  final String name;
  final String sourceFile; // dart 源文件路径（用于推导 import/相对产物）
  final String? superType; // extends 的类名（如 ChangeNotifier）
  final List<ClassField> instanceFields;
  final List<ClassField> staticFields;
  final List<ClassMethod> methods; // 含 getter
  final Set<String> ctorParams; // this.x 构造形参名

  /// 无参构造：true → 渲染 `constructor()`，false → 渲染 `constructor(args)`。
  /// 组件无构造参数时用无参形态；普通类恒带 `args`（历史契约）。
  final bool ctorNoArgs;

  /// build() 的 JS 树（节点 Map 或 JS 表达式字符串）；非 null → 渲染 build()。
  final Object? tree;

  /// 响应式 builder 闭包子树（ListenableBuilder/Consumer）。
  final List<Object?> builders;
  final List<String> builderNames;
  final List<String?> builderParams;
  final List<String> builderPreludes;

  /// build() return 前的局部变量声明（JS 语句串）。
  final List<String> localDecls;

  const ClassInfo({
    required this.name,
    required this.sourceFile,
    this.superType,
    required this.instanceFields,
    required this.staticFields,
    required this.methods,
    this.ctorParams = const {},
    this.ctorNoArgs = false,
    this.tree,
    this.builders = const [],
    this.builderNames = const [],
    this.builderParams = const [],
    this.builderPreludes = const [],
    this.localDecls = const [],
  });

  bool get isStaticOnly => instanceFields.isEmpty && methods.isEmpty;

  Set<String> get instanceFieldNames =>
      {for (final f in instanceFields) f.name};

  Set<String> get methodNames => {for (final m in methods) m.name};
}

/// 方法形参 → JS 形参名列表（解 DefaultFormalParameter 包裹）。
///
/// 过滤掉 JS 无对应物的形参类型（`BuildContext`：JS 侧没有 context 概念，
/// 组件回调由运行时按需传值）。组件与普通类共用这一处——新增「要过滤的形参
/// 类型」只改这里，组件/模型同时生效。
List<String> jsMethodParams(MethodDeclaration m) {
  final out = <String>[];
  for (final p in m.parameters?.parameters ?? const <FormalParameter>[]) {
    final inner = p is DefaultFormalParameter ? p.parameter : p;
    final name = inner.name?.lexeme;
    if (name == null || name.isEmpty) continue;
    if (inner is SimpleFormalParameter &&
        _noJsParamTypes.contains(_eraseGeneric(inner.type?.toSource()))) {
      continue;
    }
    out.add(name);
  }
  return out;
}

/// JS 侧无对应物、需从方法签名中剔除的形参类型。
const Set<String> _noJsParamTypes = {'BuildContext'};

/// 去掉可空 / 泛型后缀：`BuildContext?` → `BuildContext`、`List<T>` → `List`。
String _eraseGeneric(String? type) {
  var t = (type ?? '').trim();
  if (t.endsWith('?')) t = t.substring(0, t.length - 1);
  final lt = t.indexOf('<');
  if (lt >= 0) t = t.substring(0, lt).trim();
  return t;
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
        methods.add(ClassMethod(
          name: m.name.lexeme,
          params: jsMethodParams(m),
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
// （组件路径）较特殊外，其余普通类 1:1 还原。具体要把哪些 Flutter
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
  // 相邻字符串字面量（`'a' 'b'`）→ `+` 拼接。
  if (e is AdjacentStrings) {
    final parts = <String>[];
    for (final s in e.strings) {
      final v = exprToJs(s, scope, classes);
      if (v == null) return null;
      parts.add(v);
    }
    return parts.join(' + ');
  }
  // `a ?? b` → JS 原生空值合并（方法体内如 `_switchOn = v ?? false`）
  if (e is BinaryExpression && e.operator.lexeme == '??') {
    final l = exprToJs(e.leftOperand, scope, classes);
    final r = exprToJs(e.rightOperand, scope, classes);
    if (l == null || r == null) return null;
    return '($l ?? $r)';
  }
  // 比较 / 逻辑 / 算术二元运算：一比一翻译（条件、循环、三目、数据绑定都用得到；
  // 组件数据表达式与模型方法体共用这一处，不再各写一套）。
  if (e is BinaryExpression) {
    final op = e.operator.lexeme;
    if (const <String>{
      '>', '<', '>=', '<=', '==', '!=', '&&', '||', '+', '-', '*', '/', '%'
    }.contains(op)) {
      final l = exprToJs(e.leftOperand, scope, classes);
      final r = exprToJs(e.rightOperand, scope, classes);
      if (l == null || r == null) return null;
      return '($l $op $r)';
    }
    // Dart 整除 `a ~/ b`：JS 无对应运算符，转 Math.floor(a / b)。
    if (op == '~/') {
      final l = exprToJs(e.leftOperand, scope, classes);
      final r = exprToJs(e.rightOperand, scope, classes);
      if (l == null || r == null) return null;
      return 'Math.floor($l / $r)';
    }
  }
  // 三目 `c ? a : b`（组件数据/样式与模型方法体共用）。
  if (e is ConditionalExpression) {
    final c = exprToJs(e.condition, scope, classes);
    final t = exprToJs(e.thenExpression, scope, classes);
    final f = exprToJs(e.elseExpression, scope, classes);
    if (c == null || t == null || f == null) return null;
    return '($c ? $t : $f)';
  }
  if (e is Identifier) {
    // kDebugMode / kReleaseMode → 运行时注入的全局标志
    final flag = globalFlagJs(e.name);
    if (flag != null) return flag;
    // State.mounted：JS 组件基类有 __unmounted 标记，未卸载即视为已挂载
    if (e.name == 'mounted') return '!this.__unmounted';
    return scope.fieldRef(e.name);
  }
  // null 字面量（`data ?? null` 等）：只影响表达式位置，字段默认值仍走
  // literalToJs 的 undefined 语义，故不并入 literalToJs。
  if (e is NullLiteral) return 'null';
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
  // 自增/自减（表达式位置，如 for 更新子 `i++`）；Postfix `!` 是 Dart null
  // 断言，JS 无此概念，直接取操作数（条件短路保护）。
  if (e is PostfixExpression) {
    final v = exprToJs(e.operand, scope, classes);
    if (v == null) return null;
    if (e.operator.lexeme == '!') return v;
    return '($v${e.operator.lexeme})';
  }
  // 前缀一元（`!flag` / `-n` / `++i` / `--i`）。
  if (e is PrefixExpression) {
    final v = exprToJs(e.operand, scope, classes);
    return v == null ? null : '(${e.operator.lexeme}$v)';
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
  // Identifier 一律交给 exprToJs 统一处理（全局标志 kDebugMode、State.mounted、
  // 字段/形参/局部变量同一套解析）——不再在此处单独 fieldRef，否则这些
  // 「非字段标识符」会被漏掉。
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
  // Dart `num.toStringAsFixed(n)` → JS `toFixed(n)`（插值格式化数字常用）。
  // 组件数据表达式与模型方法体共用这一处翻译。
  if (e.methodName.name == 'toStringAsFixed' &&
      e.target != null &&
      e.argumentList.arguments.length == 1) {
    final t = exprToJs(e.target!, scope, classes);
    final a = exprToJs(e.argumentList.arguments.first, scope, classes);
    if (t != null && a != null) return '$t.toFixed($a)';
    return null;
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

/// **唯一**的「方法体 → JS」翻译器：组件动作/State 生命周期、模型方法、状态类
/// 方法全部走这里。
///
/// 语句（表达式语句 / 变量声明 / return / if …）与表达式（[exprToJs]/[rhsToJs]/
/// [exprStmtToJs]）都只在这一处与那一处处理——新增一种语法/能力，组件与普通类
/// 同时生效，不存在「组件的搞一遍、普通类再搞一遍」。
///
/// 参数：
///   - [scope]：标识符解析作用域（组件：状态字段→属性；模型：实例字段）。
///   - [widgetCtx]：可选。传入后，返回 Widget 的表达式（如 `return Container(...)`）
///     走 widget 树翻译路径。
///   - [returnExpressionBody]：箭头体是否包 `return`（Dart 有返回值语义时为真；
///     组件动作方法为假，产物与语句一致）。
String translateMethodBody(
  FunctionBody? body,
  FieldScope scope,
  Map<String, ClassInfo> classes, {
  Object? widgetCtx,
  bool returnExpressionBody = false,
}) {
  final out = <String>[];
  if (body is ExpressionFunctionBody) {
    final e = body.expression;
    String? t;
    if (widgetCtx != null && e is InstanceCreationExpression) {
      t = _widgetExprToJs(widgetCtx, e);
    }
    t ??= _bodyExprStmtJs(e, scope, classes);
    if (t != null) out.add(returnExpressionBody ? 'return $t;' : t);
  } else if (body is BlockFunctionBody) {
    final r = translateStmtList(body.block.statements, scope, classes, widgetCtx);
    if (r.isNotEmpty) out.add(r);
  }
  return out.isEmpty ? '' : out.join(' ');
}

/// 语句列表 → JS（方法体块、if 分支体共用同一套循环）。
///
/// 支持：表达式语句（super 调用忽略、setState 展开）、变量声明、return、
/// if/else。无法翻译的语句出声告警（不静默丢代码）。
String translateStmtList(
  List<Statement> stmts,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  Object? widgetCtx,
) {
  final out = <String>[];
  for (final s in stmts) {
    if (s is ExpressionStatement) {
      final e = s.expression;
      // super.initState() 等 super 调用：JS 无 super 语义，忽略。
      if (e is MethodInvocation && e.target is SuperExpression) continue;
      final t = _bodyExprStmtJs(e, scope, classes);
      if (t != null) {
        out.add(t);
      } else {
        log.warning('[ui_component_generator] 语句无法翻译，已在 JS 产物中'
            '丢弃：${e.toSource()}');
      }
    } else if (s is VariableDeclarationStatement) {
      // 局部变量声明 `String? name = await X.y();` → `var name = ...;`，
      // 名字登记进 scope，后续语句（含插值）可直接引用。
      for (final v in s.variables.variables) {
        final name = v.name.lexeme;
        if (v.initializer == null) {
          out.add('var $name;');
          scope.localVars.add(name);
          continue;
        }
        final init = rhsToJs(v.initializer!, scope, classes);
        if (init == null) {
          // 变量没声明 → 后面引用它的语句（含插值）会连带失效，必须出声。
          log.warning('[ui_component_generator] 局部变量声明无法翻译，已在 JS '
              '产物中丢弃：${s.toSource()}');
          continue;
        }
        out.add('var $name = $init;');
        scope.localVars.add(name);
      }
    } else if (s is ReturnStatement) {
      // `return "22";` 是 ReturnStatement（不是 ExpressionStatement），
      // 需单独翻译为 `return <expr>;`，否则 async 方法体被整体丢弃。
      final e = s.expression;
      if (e == null) {
        out.add('return;');
        continue;
      }
      String? v;
      if (widgetCtx != null && e is InstanceCreationExpression) {
        v = _widgetExprToJs(widgetCtx, e);
      }
      v ??= rhsToJs(e, scope, classes);
      if (v != null) out.add('return $v;');
    } else if (s is IfStatement) {
      final condJs = exprToJs(s.expression, scope, classes);
      if (condJs == null) {
        log.warning('[ui_component_generator] if 条件无法翻译，已在 JS 产物中'
            '丢弃：${s.toSource()}');
        continue;
      }
      final thenStmts =
          s.thenStatement is Block ? (s.thenStatement as Block).statements : [s.thenStatement];
      var js =
          'if ($condJs) { ${translateStmtList(thenStmts, scope, classes, widgetCtx)} }';
      final els = s.elseStatement;
      if (els != null) {
        final elseStmts = els is Block ? els.statements : [els];
        js +=
            ' else { ${translateStmtList(elseStmts, scope, classes, widgetCtx)} }';
      }
      out.add(js);
    }
  }
  return out.join(' ');
}

/// 一条表达式语句 → JS：`setState(...)` 展开为 `this.setState(function(){...})`，
/// 其余走 [exprStmtToJs]（赋值 / 自增 / `_model.inc()` 对象方法调用等）。
String? _bodyExprStmtJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is MethodInvocation &&
      e.methodName.name == 'setState' &&
      e.argumentList.arguments.length == 1) {
    final fn = e.argumentList.arguments.first;
    if (fn is FunctionExpression) return _setStateJs(fn, scope, classes);
    return null;
  }
  return exprStmtToJs(e, scope, classes);
}

/// `setState(() => _x++)` → `this.setState(function(){ this._x += 1; });`
/// （回调体逐语句翻译，与 Dart 原封同构）。
String _setStateJs(
  FunctionExpression fn,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final body = fn.body;
  String inner = '';
  if (body is ExpressionFunctionBody) {
    inner = exprStmtToJs(body.expression, scope, classes) ?? '';
  } else if (body is BlockFunctionBody) {
    inner = translateStmtList(body.block.statements, scope, classes, null);
  }
  return inner.isEmpty
      ? 'this.setState(function(){});'
      : 'this.setState(function(){ $inner });';
}

/// 翻译一个模型/状态类的方法体 → JS（字段表 = 类自身实例字段）。
///
/// 只是为统一翻译器 [translateMethodBody] 组装模型侧作用域；组件动作侧同理。
String translateClassMethodBody(
  ClassInfo info,
  ClassMethod m,
  Map<String, ClassInfo> classes, {
  Map<String, Map<String, String>> hostMethods = const {},
  Object? widgetCtx,
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
  return translateMethodBody(
    m.body,
    scope,
    classes,
    widgetCtx: widgetCtx,
    returnExpressionBody: true,
  );
}

/// 把一个 Widget 构造表达式（如 `Container(...)`）通过 WidgetTranslateContext
/// 翻译成 JS 构造调用字符串。失败返回 null（回退到普通表达式翻译）。
String? _widgetExprToJs(Object widgetCtx, Expression e) {
  try {
    // WidgetTranslateContext.translate(Expression) → JSON Map / String
    final json = (widgetCtx as dynamic).translate(e);
    // renderJs(Object?, int depth) → JS 字符串
    return (widgetCtx as dynamic).renderJs(json, 0) as String?;
  } catch (_) {
    return null;
  }
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

/// 类声明 → JS（export 可选）。含 constructor / 方法 / getter / extends 基类，
/// 并数据驱动地追加 build()/builder 子方法（[ClassInfo.tree] 非空）。
/// 普通类与组件共用这一条渲染路径——**没有对外工厂函数**：元素的 type 就是
/// 类本身（宿主 widget 则是类型名字符串），由渲染层统一写成
/// `__h(type, props, children)`，JS 侧不存在「factory」这层包装。
///
/// [widgetCtx]：可选。传入后，方法体里返回 Widget 构造表达式
/// （如 `return Container(...)`）会走 widget 树翻译路径，而不是被当作普通
/// 方法调用丢弃（model 类里的 `getWidget()` 方法也能用）。
/// [treeCtx]：可选。[ClassInfo.tree] 非空（组件）时渲染 build/builders 必需。
String renderClassDecl(
  ClassInfo info,
  Map<String, ClassInfo> classes, {
  bool exported = false,
  Map<String, Map<String, String>> hostMethods = const {},
  Object? widgetCtx,
  WidgetTranslateContext? treeCtx,
}) {
  final b = StringBuffer();
  b.write(exported ? 'export class ' : 'class ');
  b.write(info.name);
  final base = sdkBaseName(info);
  if (base != null) b.write(' extends $base');
  b.write(' {\n');

  // constructor
  b.write(info.ctorNoArgs ? '  constructor() {\n' : '  constructor(args) {\n');
  if (base != null) b.write('    super();\n');
  for (final f in info.instanceFields) {
    final def = f.jsInitial ??
        (f.initializer != null
            ? (literalToJs(f.initializer) ?? 'undefined')
            : 'undefined');
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
      final body = m.bodyJs ??
          translateClassMethodBody(info, m, classes,
              hostMethods: hostMethods, widgetCtx: widgetCtx);
      b.write('  $fn${m.name}(${m.params.join(', ')}) { $body }\n');
    }
  }

  // build()：tree 非空即渲染（数据驱动，组件与普通类同一逻辑）。
  if (info.tree != null) {
    final ctx = treeCtx!;
    b.write('  build() {\n');
    for (final d in info.localDecls) {
      b.write('$d\n');
    }
    b.write('    return ${ctx.renderJs(info.tree, 2)};\n');
    b.write('  }\n');
    // 响应式 builder 闭包子树（ListenableBuilder/Consumer）→ 实例方法
    // `_lbBuilderN()` / `_consumerBuilderN(value)`。运行时时模型 notify 后
    // 重新调用本方法拿到最新子树（含已求值的 this._model.n / value.count），
    // 做「仅此节点」的局部重建。方法名与形参由 translator 声明。
    for (var i = 0; i < info.builders.length; i++) {
      final name =
          i < info.builderNames.length ? info.builderNames[i] : '_lbBuilder$i';
      final param = i < info.builderParams.length ? info.builderParams[i] : null;
      final prelude =
          i < info.builderPreludes.length ? info.builderPreludes[i] : '';
      b.write('  $name(${param ?? ''}) {\n');
      if (prelude.isNotEmpty) b.write('      $prelude\n');
      b.write('      return ${ctx.renderJs(info.builders[i], 2)};\n');
      b.write('  }\n');
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

/// ===========================================================================
/// 统一入口：Dart 类 → JS 源码。
///
/// 只有这一处决定「类 → JS」的渲染：普通类（模型/状态类/静态单例）与组件
/// （@UIComponent widget，widget 与 state 已在建模期合并为同一 [ClassInfo]）
/// 全部走这里，没有任何按用途分叉的模式开关——所有差异都由 [ClassInfo] 数据
/// 驱动（类名/工厂函数名、build 树、builder 子方法、字段/方法的预渲染值）。
///
/// 因此新增一种「类结构能力」（如工厂、build、getter、注解 …）只需改这一处，
/// 组件与普通类同时生效。
///
/// 参数：
///   - [exported]：类声明是否 `export`。
///   - [classes]：方法体内构造调用（`new X({...})`）用的类表。
///   - [hostMethods]：@HostInjected 方法表。
///   - [widgetCtx]：类方法体里 `return Container(...)` 走的 widget 翻译上下文。
///   - [treeCtx]：[ClassInfo.tree] 非空（组件）时渲染 build/builders 必需。
///   - [singletonValueRenderer]：纯 static 类的字段值渲染器（颜色/字面量求值）。
/// ===========================================================================
String dart2js(
  ClassInfo info, {
  bool exported = false,
  Map<String, ClassInfo> classes = const {},
  Map<String, Map<String, String>> hostMethods = const {},
  Object? widgetCtx,
  WidgetTranslateContext? treeCtx,
  String Function(ClassField field)? singletonValueRenderer,
}) {
  if (info.isStaticOnly && singletonValueRenderer != null) {
    return renderStaticConst(info,
        valueRenderer: singletonValueRenderer, exported: exported);
  }
  return renderClassDecl(info, classes,
      exported: exported,
      hostMethods: hostMethods,
      widgetCtx: widgetCtx,
      treeCtx: treeCtx);
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
// ===========================================================================
// widget → JSON 翻译的策略扩展点
//
// 设计目标：新增/自定义 widget 时不动 ComponentBuilder 的核心代码。
// 扩展一个 widget 只需要两步：
//   1. 实现 WidgetTranslator（type + toJson）
//   2. 注册：registry.register(MyTranslator())
//
// 核心代码（注解解析、状态/动作提取、产物组装）只与
// WidgetTranslateContext / WidgetTranslatorRegistry 交互。
// ===========================================================================

/// 一个 widget 构造节点的中立表示（build() 树解析的中间产物）。
///
/// 不直接依赖某个具体 widget：type 是构造名（'Column'/'Text'/...）。
/// [args] 保留原始参数列表（含 NamedExpression，供 ctx 的 namedArg/
/// positionalArg/listArg 解析）；[positionalArgs]/[namedArgs] 是拆分视图。
class WidgetNode {
  final String type;
  final List<Expression> args;
  final List<Expression> positionalArgs;
  final Map<String, Expression> namedArgs;

  /// 原始表达式（InstanceCreationExpression 等，取类型参数等用）。
  final Expression? expr;

  final String? factory;

  WidgetNode(this.type, this.args, {this.factory, this.expr})
      : positionalArgs = [
          for (final a in args)
            if (a is! NamedExpression) a,
        ],
        namedArgs = {
          for (final a in args)
            if (a is NamedExpression) a.name.label.name: a.expression,
        };
}

/// 翻译上下文：持有注册表与组件元数据，并向 translator 提供通用解析能力。
///
/// translator 通过 [translate] 递归子节点、通过 [renderJs] 递归渲染子节点，
/// 通过 [jsDataExpr]/[eventOf]/[propOf] 等 helper 解析参数。
class WidgetTranslateContext {
  final WidgetTranslatorRegistry registry;
  final Map<String, String> propByField;
  final Map<String, String> actionByMethod;
  final String sourcePath;

  /// 组件名 → 依赖产物 jsAsset 路径（null = 无法确定，渲染层走原生注入）。
  /// 由生成器注入：本文件私有/注解组件 → 本文件产物；跨文件组件 →
  /// 从 import directives 推导源文件产物。Component 节点据此产出 import，
  /// 运行时按 import 递归挂载嵌套组件（使用方无需知道依赖）。
  final String? Function(String component)? importResolver;

  /// 跨文件「静态单例类」解析器：build 树里 `MyColors.background`
  /// 这类静态引用翻译成 JS 表达式并登记 import 依赖。
  /// 由生成器从组件文件的 import 源文件解析注入；null = 不启用。
  final SingletonResolver? singletons;

  /// 翻译过程中遇到的未知自定义组件（Component 兜底），供生成器
  /// 收集后把本文件内可解析的私有组件（_Xxx）翻译成嵌套组件注册进产物。
  final Set<String> dependencies = {};

  /// 翻译/渲染过程中**实际用到**的 widget 类型：package → {type}。
  /// [renderJs] 在此登记，生成器据此按 package 产出 JS widget 模块并 import。
  final Map<String, Set<String>> usedWidgetPackages = {};

  /// ListenableBuilder 等「builder 闭包」翻译：闭包返回的子树抽到组件方法
  /// `_lbBuilderN()`，运行时时模型 notify 后重新调用拿到最新子树做局部重建。
  /// 收集顺序即 `_lbBuilder${index}` 命名序号。
  final List<Object?> builderTrees = []; // Map = 节点；String = 三目 JS 表达式

  /// 与 [builderTrees] 同步的方法名（`_lbBuilderN` / `_consumerBuilderN`）。
  final List<String> builderNames = [];

  /// 与 [builderTrees] 同步的形参名（null = 无参；Consumer 为 value）。
  final List<String?> builderParams = [];

  /// 与 [builderTrees] 同步的「方法体前置语句」（JS 源码，如 Builder 闭包
  /// 块体里的 `var model = this.__watch('MyModel');`）。
  final List<String> builderPreludes = [];

  WidgetTranslateContext({
    required this.registry,
    required this.propByField,
    required this.actionByMethod,
    required this.sourcePath,
    this.importResolver,
    this.singletons,
    this.jsClassWidgets = const {},
    this.delegateClassWidgets = const {},
  });

  /// 有 JS 类实现的 widget 类型（组件、逻辑 widget、sliver builder 代理）。
  /// 由生成器注入（builder 的模板表是唯一事实源）。
  final Set<String> jsClassWidgets;

  /// 仅「builder/delegate 形态」才走 JS 类的类型（sliver 代理：普通
  /// `GridView(children: [...])` 仍是宿主节点，`.builder` 懒加载形态才需要
  /// 类来循环调用拥有者方法展开子树）。
  final Set<String> delegateClassWidgets;

  /// 本节点的元素 type 用 **JS 类引用**还是**类型名字符串**。
  ///
  /// JS 里没有「factory」这层包装：元素的 type 就是类本身（有 JS 逻辑的类型）
  /// 或宿主 widget 的类型名（由宿主注册表映射成 Flutter widget）。有 JS 类的
  /// 类型要 import 类名，宿主类型名是字符串字面量、无需 import。
  bool usesJsClass(String type, Map<String, dynamic>? props) {
    if (!jsClassWidgets.contains(type)) return false;
    if (!delegateClassWidgets.contains(type)) return true;
    return props != null && props.containsKey('delegateBuilder');
  }

  /// 记录一个被兜底为 Component 节点的自定义组件名。
  void collectDependency(String name) => dependencies.add(name);

  // -------------------------------------------------------------------------
  // 递归入口：表达式 → JSON 描述 / JS 渲染
  // -------------------------------------------------------------------------

  /// 把 build() 里的一个 widget 表达式翻译成中立描述（渲染层据此产出 JS）。
  ///
  /// 返回 Map = 普通节点；返回 String = JS 表达式（widget 位置三目
  /// `cond ? A() : B()` → `(condJs ? [A] : [B])`），渲染层对 String 原样嵌入。
  Object? translate(Expression e) {
    if (e is ConditionalExpression) {
      final cond = jsDataExpr(e.condition);
      final thenJs = _collectionArrayJs(e.thenExpression);
      final elseJs = _collectionArrayJs(e.elseExpression);
      return '($cond ? $thenJs : $elseJs)';
    }
    final node = _toNode(e);
    final translator = registry.lookup(node.type);
    if (translator != null) return translator.toJson(node, this);
    // 未注册：按「嵌套组件」兜底翻译（需注册 fallback = ComponentTranslator）。
    // 有 @UIComponent 注解的组件运行时递归渲染 JS 版本；
    // 无注解的 lib 自定义 widget 原生直接可用，JS 版渲染为 Component 占位。
    final fb = registry.fallback;
    if (fb != null && _isUpperCamel(node.type)) {
      collectDependency(node.type);
      return fb.toJson(node, this);
    }
    throw FormatException(
        'ui_component_generator: 不支持的组件 "${node.type}"，'
        '请实现并注册对应的 WidgetTranslator（当前已注册: '
        '${registry.registeredTypes.join('/')}）');
  }

  /// children 列表项翻译：Expression → 节点 Map；IfElement / ForElement →
  /// JS spread 表达式字符串（`...(cond ? [a] : [b])` / `...(function(){...})()`），
  /// 渲染层对 String 原样嵌入（内联构造调用 + 条件/循环展开）。
  Object? translateElement(CollectionElement e) {
    if (e is Expression) return translate(e);
    if (e is IfElement) return '...${_ifAsArray(e)}';
    if (e is ForElement) return '...${_forAsArray(e)}';
    throw FormatException('不支持的 collection element: ${e.toSource()}');
  }

  /// if/for 作为「元素数组」出现（数组字面量里嵌套、三目分支等），
  /// 不带 spread 前缀：`(cond ? [a] : [b])`。
  String _ifAsArray(IfElement e) {
    final cond = jsDataExpr(e.expression);
    final thenJs = _collectionArrayJs(e.thenElement);
    final elseJs = e.elseElement == null ? '[]' : _collectionArrayJs(e.elseElement!);
    return '($cond ? $thenJs : $elseJs)';
  }

  /// for 循环 → JS IIFE 展开数组（循环变量 var 提升在 IIFE 内，body 直接引用）。
  String _forAsArray(ForElement e) {
    final parts = e.forLoopParts;
    if (parts is! ForParts) {
      throw FormatException('不支持的 for 循环形式: ${e.toSource()}');
    }
    String head;
    if (parts is ForPartsWithDeclarations) {
      // 传统 for：`for (var i = 0; i < n; i++)` → JS 同构
      final vars = parts.variables.variables.toList();
      // 循环变量先入作用域：condition/updaters/body 里引用 i 都走 loopVars
      for (final v in vars) {
        pushLoopVar(v.name.lexeme);
      }
      final varList = vars.isEmpty
          ? ''
          : 'var ${vars.map((v) => '${v.name.lexeme} = ${v.initializer == null ? '0' : jsDataExpr(v.initializer!)}').join(', ')}';
      final condJs = parts.condition == null ? '' : jsDataExpr(parts.condition!);
      final incJs = parts.updaters.isEmpty
          ? ''
          : parts.updaters.map((u) => jsDataExpr(u)).join(', ');
      head = 'for ($varList; $condJs; $incJs)';
    } else if (parts is ForPartsWithExpression) {
      // 无声明：`for (i = 0; i < n; i++)`（变量需为已收集的状态字段）
      final initJs = parts.initialization == null ? '' : jsDataExpr(parts.initialization!);
      final condJs = parts.condition == null ? '' : jsDataExpr(parts.condition!);
      final incJs = parts.updaters.isEmpty
          ? ''
          : parts.updaters.map((u) => jsDataExpr(u)).join(', ');
      head = 'for ($initJs; $condJs; $incJs)';
    } else {
      throw FormatException('暂不支持该 for 形式（for-in 后续补充）: ${e.toSource()}');
    }
    final bodyJs = _collectionArrayJs(e.body);
    // 清除循环变量作用域（翻译完成后，body 内已引用 i）
    popLoopVars();
    return '(function(){ var out = []; $head { out.push.apply(out, $bodyJs); } return out; })()';
  }

  /// collection element → JS 数组字面量（元素数组语义；嵌套 if/for 递归展开）。
  String _collectionArrayJs(CollectionElement e) {
    if (e is Expression) {
      final t = translate(e);
      if (t is String) return '[$t]';
      return '[${renderJs(t, 2)}]';
    }
    if (e is IfElement) return _ifAsArray(e);
    if (e is ForElement) return _forAsArray(e);
    throw FormatException('不支持的 collection element: ${e.toSource()}');
  }

  /// 循环变量作用域：for 循环变量（i 等）在 body 翻译期间遮蔽状态字段查表。
  final Set<String> _loopVars = {};
  void pushLoopVar(String name) => _loopVars.add(name);
  void popLoopVars() => _loopVars.clear();

  /// build() return 前的局部变量（`final isAdult = ...;`）：树里直接引用。
  final Set<String> _locals = {};
  void addLocal(String name) => _locals.add(name);

  /// Builder 闭包局部变量 → 模型类型（`final model = context.watch<T>()`）。
  /// 事件表达式（`() => model.inc()`，局部变量不在回传作用域内）据此翻译成
  /// `this.__read("T").inc()`——两条运行时都在实例上挂了 `__read`，不依赖
  /// 局部作用域即可回传执行。
  final Map<String, String> _localModels = {};
  void addLocalModel(String name, String modelType) => _localModels[name] = modelType;

  static bool _isUpperCamel(String name) =>
      name.isNotEmpty && name[0] == name[0].toUpperCase();

  /// 渲染一个已翻译的中立节点为统一元素构造 `__h(type, props, children)`。
  ///
  /// 值契约：toJson 的叶子值一律是 JS 表达式字符串（`"Text"` 这类字符串
  /// 字面量由 [jsString] 产生），因此分发前剥离字符串字面量的引号取语义名。
  String renderJs(Object? json, int depth) {
    if (json is String) return json; // 三目/条件表达式（JS 源码字符串）
    if (json is! Map<String, dynamic>) {
      throw FormatException('无法渲染的节点: $json');
    }
    final type = _semanticType(json['type']);
    final translator = registry.lookupJson(type);
    if (translator == null) {
      // Component 兜底节点（未注册的第三方/自定义 widget）：
      //   - 该组件名有 JS 产物（importResolver 命中）→ 渲染成类引用元素
      //     `__h(X, {...args})`，与组件产物契约一致（运行时递归挂载 JS 组件）；
      //   - 无产物（无注解的 lib 普通 widget / @UIComponentIgnore）→
      //     `__h("Component", {...})` 占位，运行时由宿主 nativeComponents
      //     原生注入或占位。
      if (type == 'Component') {
        final call = _renderComponentCall(json, depth);
        if (call != null) return call;
        // 无 JS 产物（无注解的 lib widget / @UIComponentIgnore）：运行时由宿主
        // nativeComponents 原生注入。仍经 __h 归一成与其它结点同形状的元素，
        // 保证运行时统一按 el.children 挂载（不再有裸字面量特例）。
        final props = json['props'];
        final propsJs = (props is Map && props.isNotEmpty)
            ? jsLiteral(props, depth + 1)
            : '{}';
        return '__h("Component", $propsJs, null)';
      }
      throw FormatException('未知节点类型: $type');
    }
    final props = json['props'];
    // 元素 type 用类引用（有 JS 逻辑）还是类型名字符串（宿主 widget）：前者
    // 需要 import 该类的 widget 模块，后者是字符串字面量、零 import。
    final asClass = usesJsClass(type, props is Map<String, dynamic> ? props : null);
    if (asClass) {
      (usedWidgetPackages[translator.packageName] ??= <String>{}).add(type);
    }
    return _renderCall(type, json, depth, asClass: asClass);
  }

  /// 把已翻译的 JSON 节点渲染成统一元素构造：`__h(<type>, {...}, [...])`。
  ///
  /// JS 没有「factory」这层包装：元素 type 直接是类（有 JS 逻辑的类型，[asClass]
  /// 为 true）或宿主 widget 类型名字符串。`props` 为空 → `{}`；`children` 为空 →
  /// 省略第三参（`__h` 归一为 `[]`）。嵌套子节点（children、以及
  /// ListTile.leading 这类「props 里的节点」）同样递归成元素构造。
  String _renderCall(
    String type,
    Map<String, dynamic> json,
    int depth, {
    required bool asClass,
  }) {
    final props = json['props'];
    final children = json['children'];
    final propsJs = (props is Map && props.isNotEmpty)
        ? jsLiteral(props, depth + 1)
        : '{}';
    final typeArg = asClass ? type : "'$type'";
    final b = StringBuffer()
      ..write('__h(')
      ..write(typeArg)
      ..write(', ')
      ..write(propsJs);
    if (children is List && children.isNotEmpty) {
      b
        ..write(', ')
        ..write(jsLiteral(children, depth + 1));
    }
    b.write(')');
    return b.toString();
  }

  /// Component 节点的渲染：命中 JS 产物时输出 `__h(X, {...args})`（X 是组件
  /// 产物的类引用，需 import；args 复用 [jsLiteral]，与其它元素同一值渲染
  /// 规则）；无产物（importResolver 返回 null）→ 返回 null，调用方回退
  /// `__h("Component", ...)` 占位（运行时走宿主 nativeComponents 原生注入）。
  String? _renderComponentCall(Map<String, dynamic> json, int depth) {
    final props = json['props'];
    if (props is! Map) return null;
    final name = _semanticType(props['component']);
    if (name.isEmpty || importResolver?.call(name) == null) return null;
    final args = props['args'];
    final argsJs = (args is Map && args.isNotEmpty)
        ? jsLiteral(args, depth + 1)
        : '{}';
    return '__h($name, $argsJs)';
  }

  /// 剥离 JS 字符串字面量引号（`"Column"` → `Column`）；非字面量原样返回。
  static String _semanticType(Object? v) {
    final s = v?.toString() ?? '';
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }

  // -------------------------------------------------------------------------
  // 通用 AST 解析 helper（translator 可直接复用）
  // -------------------------------------------------------------------------

  /// 取构造调用：`Foo(...)` 在无 resolution 的 parseString 下可能是
  /// InstanceCreationExpression 或 MethodInvocation（无 const 时），统一处理。
  ///
  /// 静态工厂形态（`Image.asset(...)` / `Image.network(...)`）把 ctor 名
  /// 归一为 target 名（'Image'），与注册表 {Image: ImageTranslator} 匹配。
  (String?, List<Expression>) ctorOf(Expression e) {
    if (e is InstanceCreationExpression) {
      return (
        e.constructorName.type.name2.lexeme,
        e.argumentList.arguments.toList(),
      );
    }
    if (e is MethodInvocation) {
      final target = e.target;
      if (target is Identifier) {
        return (target.name, e.argumentList.arguments.toList());
      }
      return (e.methodName.name, e.argumentList.arguments.toList());
    }
    return (null, const []);
  }

  Expression? namedArg(List<Expression> args, String name) {
    for (final a in args) {
      if (a is NamedExpression && a.name.label.name == name) return a.expression;
    }
    return null;
  }

  Expression? positionalArg(List<Expression> args, int i) =>
      i < args.length ? args[i] : null;

  /// 第一个非命名参数（单子组件的 child 定位）：
  /// `Container(width: 120)` 无 child 时，跳过命名参数，返回 null。
  Expression? nonNamedArg(List<Expression> args) {
    for (final a in args) {
      if (a is! NamedExpression) return a;
    }
    return null;
  }

  /// children 等列表参数：保留全部 collection elements。
  /// 注意返回 [CollectionElement]（Expression / IfElement / ForElement），
  /// 由 [translateElement] 统一翻译（if/for 展开成 JS spread 表达式）。
  List<CollectionElement> listArg(List<Expression> args, String name, String ctor) {
    final e = namedArg(args, name);
    if (e is ListLiteral) return e.elements.toList();
    throw FormatException('$ctor 缺少 $name 列表');
  }

  /// 字段名（`_count`）→ 状态名（`count`）
  String propOf(Identifier id) {
    final prop = propByField[id.name];
    if (prop != null) return prop;
    throw FormatException('"${id.name}" 不是 @UIProp 状态字段');
  }

  /// 方法名 → 事件名
  String eventOf(String method) {
    final event = actionByMethod[method];
    if (event != null) return event;
    throw FormatException('"$method" 不是组件方法（未注册为动作）');
  }

  /// 事件参数解析：`onTap: _tap` / `onTap: () => _tap()` → 组件方法名；
  /// 带 receiver 的调用（Builder 闭包局部变量 `model.inc()`、
  /// `context.read<T>().reset()` 链式）→ 翻译为 JS 方法调用表达式
  /// （一比一，不查动作表——方法/属性全量生成，无需标注）。
  String eventExpr(Expression e) {
    if (e is Identifier) return eventOf(e.name);
    if (e is FunctionExpression) {
      final inner = functionInner(e);
      if (inner is MethodInvocation) {
        final target = inner.target;
        // 局部变量 receiver：`model.inc()` → 事件表达式中局部变量已不在
        // 作用域，模型局部（context.watch<T>()）改用 `this.__read('T')`；
        // 其余局部变量原样保留（`model.inc()`，闭包内 var 已声明）。
        if (target is Identifier && _locals.contains(target.name)) {
          final modelType = _localModels[target.name];
          final recv =
              modelType != null ? 'this.__read(${jsString(modelType)})' : target.name;
          return '$recv.${inner.methodName.name}'
              '(${_eventArgsJs(inner.argumentList)})';
        }
        // context.read<T>().reset() 链式：先翻译 receiver（jsDataExpr →
        // this.__read('T')），再拼方法调用。
        if (target is MethodInvocation) {
          final recv = jsDataExpr(target);
          return '$recv.${inner.methodName.name}'
              '(${_eventArgsJs(inner.argumentList)})';
        }
        // 组件字段/实例 receiver（非局部变量即组件成员）：`_controller.clear()`
        // / `_scrollController.jumpTo(...)` → this._controller.clear()，
        // 不查动作表（实例方法全量生成，与 Dart 写法一致）。
        if (target is Identifier) {
          return 'this.${target.name}.${inner.methodName.name}'
              '(${_eventArgsJs(inner.argumentList)})';
        }
        return eventOf(inner.methodName.name);
      }
    }
    throw FormatException('事件参数需要直接引用方法（如 onTap: _tap 或 () => _tap()）');
  }

  /// 事件「构建期句柄」：把事件表达式包成 `this.__bind("表达式")`。
  ///
  /// 这是事件回传的唯一注入方式：`this` 是 build 作用域的组件实例（也就是
  /// **定义该事件方法/表达式归属的组件**），运行时据此登记句柄并按（实例,
  /// 表达式）缓存——重建产出同一句柄（props 稳定、增量补丁仍生效），宿主
  /// 点击只回传 `{__fn:id}`。相比运行时按裸方法名沿组件链启发式查找，绑定
  /// 信息在构建期就确定，语义与 Dart tear-off 一致，且不依赖运行时树形状。
  String eventHandle(Expression e) => 'this.__bind(${jsString(eventExpr(e))})';

  /// 事件参数列表翻译：逐参数走 [jsDataExpr]（字符串/字段/局部变量/字面量）。
  String _eventArgsJs(ArgumentList args) {
    final out = <String>[];
    for (final a in args.arguments) {
      if (a is NamedExpression) {
        out.add(jsDataExpr(a.expression));
      } else {
        out.add(jsDataExpr(a));
      }
    }
    return out.join(', ');
  }

  /// 颜色表达式（Color(0x..)/Colors.x/静态引用/三目）→ JS 表达式字符串。
  /// 委托给 style_translators 的顶层 [colorExpr]（生成器与样式翻译共用一套逻辑）。
  String? colorExpr(Expression e) => translateColor(e, this);

  /// BorderRadius.all(Radius.circular(n)) / BorderRadius.circular(n) → 数字字符串。
  String? borderRadiusExpr(Expression e) {
    final (ctor, args) = ctorOf(e);
    if (ctor != 'all' && ctor != 'circular') return null;
    for (final a in args) {
      final n = _radiusNum(a);
      if (n != null) return n;
    }
    return null;
  }

  String? _radiusNum(Expression e) {
    if (e is IntegerLiteral && e.value != null) return '${e.value}';
    if (e is DoubleLiteral) return '${e.value}';
    final (ctor, args) = ctorOf(e);
    if (ctor == 'circular') {
      for (final a in args) {
        if (a is IntegerLiteral && a.value != null) return '${a.value}';
        if (a is DoubleLiteral) return '${a.value}';
      }
    }
    return null;
  }

  /// 状态字段引用或字面量 → JS 表达式
  /// （Switch value / Slider value 等「绑定状态或常量」的场景）。
  /// 与数据表达式共用同一套翻译（一个地方支持新语法，处处生效）。
  String propExpr(Expression e) => jsDataExpr(e);

  /// 数据表达式 → JS 表达式。
  ///
  /// 委托给**唯一**的表达式翻译器 [rhsToJs]（组件数据表达式与模型方法体、
  /// 语句翻译共用同一套语法支持——新增语法只改那一处），只是把作用域换成
  /// 组件侧：状态字段（[propByField]）+ 循环变量 + build 局部变量 + 组件方法。
  /// 无法翻译即抛错（组件数据绑定不允许静默丢表达式）。
  String jsDataExpr(Expression e) {
    final scope = FieldScope(
      propByField: propByField,
      params: {..._loopVars, ..._locals},
      methods: actionByMethod.keys.toSet(),
    );
    final js = rhsToJs(e, scope, const {});
    if (js == null) {
      throw FormatException(
          '文本内容只支持字符串/插值/状态字段/模型属性/三目，不支持 ${e.toSource()}');
    }
    return js;
  }

  /// 方法 tear-off 或 `() => _inc()` 内部的方法调用表达式
  Expression? functionInner(FunctionExpression fn) {
    final body = fn.body;
    if (body is ExpressionFunctionBody) return body.expression;
    if (body is BlockFunctionBody) {
      for (final s in body.block.statements) {
        if (s is ExpressionStatement) return s.expression;
      }
    }
    return null;
  }

  /// 把 toJson 产物的值序列化为 JS 源码（构造调用树）。
  ///
  /// 值约定：toJson 输出的叶子值一律为 **JS 表达式字符串**（字符串字面量
  /// 用 [jsString] 带引号、数字/布尔/表达式原样），这里原样嵌入、不加引号。
  ///
  /// 容器：Map 含 `type` 键 → 视作**节点**，递归 [renderJs] 产出构造调用
  /// （如 `Text(...)`）——props 里嵌套的节点（如 ListTile.leading）据此还原；
  /// 普通 Map/List → 递归容器。
  String jsLiteral(Object? value, int depth) {
    if (value is Map) {
      if (value.containsKey('type')) {
        return renderJs(Map<String, dynamic>.from(value), depth);
      }
      if (value.isEmpty) return '{}';
      final ind = '  ' * depth;
      final ind2 = '  ' * (depth + 1);
      final entries = value.entries
          .map((e) => '"${e.key}": ${jsLiteral(e.value, depth + 1)}')
          .join(',\n$ind2');
      return '{\n$ind2$entries\n$ind}';
    }
    if (value is List) {
      if (value.isEmpty) return '[]';
      final ind = '  ' * depth;
      final ind2 = '  ' * (depth + 1);
      final items = value.map((v) => jsLiteral(v, depth + 1)).join(',\n$ind2');
      return '[\n$ind2$items\n$ind]';
    }
    // 叶子值 = JS 表达式字符串（已带引号的字符串 / 数字 / 表达式）
    var s = value?.toString() ?? 'null';
    if (s.contains('\n')) {
      // 多行 JS 表达式（if/for spread、IIFE）：压缩为单行，保持树缩进整洁
      s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return s;
  }

  /// 生成 JS 双引号字符串字面量
  String jsString(String s) {
    final escaped = s
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return '"$escaped"';
  }

  WidgetNode _toNode(Expression e) {
    final (ctor, args) = ctorOf(e);
    if (ctor == null) {
      throw FormatException('不支持的 UI 表达式: ${e.toSource()}');
    }
    return WidgetNode(
      ctor,
      args,
      factory: e is MethodInvocation ? e.methodName.name : null,
      expr: e,
    );
  }
}

/// ===========================================================================
/// 策略抽象类：一个 widget 类型族的「widget → JSON 描述」
///
/// - [types]：处理的源码 widget 构造名（如 {'Text'} 或 {'Column','Row'}）
/// - [jsonTypes]：产物 JSON 里的节点 type 名（默认与 [types] 相同；
///   如 ElevatedButton 的产物节点叫 'Button' 时覆写）
/// - [toJson]：AST 节点 → 中立 JSON 描述（渲染层据此输出 JS 构造调用）
/// ===========================================================================
abstract class WidgetTranslator {
  const WidgetTranslator();

  /// 本 translator 对应的**单一**源码 widget 构造名（如 'Text' / 'Column'）。
  /// 一个 type 一个实现；共用逻辑用继承（基类 + 子类覆写 type）。
  String get type;

  /// 本 translator 产物 JSON 中使用的节点 type 名集合（默认与 [type] 相同；
  /// 如三种按钮产物统一叫 'Button'）。
  Set<String> get jsonTypes => {type};

  /// 该 widget 所属的「包」（决定生成器把 JS widget 模块放到哪个目录）。
  /// 默认 'flutter'（Flutter SDK / material / widgets）；三方包覆写，
  /// 如 provider 包的 ChangeNotifierProvider → 'provider'。
  String get packageName => 'flutter';

  /// 把 [node] 翻译成 JSON 描述（type/props/children）。
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx);
}

/// ===========================================================================
/// 管理类：注册 / 分发 translator
///
/// ComponentBuilder 持有一个 registry；运行时按 widget 构造名查 translator。
/// 扩展新 widget = 写一个 WidgetTranslator 并 register，核心代码零改动。
/// ===========================================================================
class WidgetTranslatorRegistry {
  /// 源码构造名 → translator（Map 直查，O(1)；组件几千个也不退化）。
  final Map<String, WidgetTranslator> _translators = {};

  /// 产物 JSON 节点 type → translator（renderJs 分发用，同样 O(1)）。
  final Map<String, WidgetTranslator> _jsonIndex = {};

  /// 兜底 translator（如 ComponentTranslator）：lookup 未命中时由
  /// WidgetTranslateContext.translate 显式判定后使用（仅 UpperCamel 组件）。
  WidgetTranslator? _fallback;

  /// 注册一个 translator（同 type 覆盖旧的，后注册者优先）。
  void register(WidgetTranslator translator) {
    _translators[translator.type] = translator;
    for (final jsonType in translator.jsonTypes) {
      _jsonIndex[jsonType] = translator;
    }
  }

  /// 设置兜底 translator（未注册的自定义组件 → Component 节点）。
  void registerFallback(WidgetTranslator translator) {
    _fallback = translator;
  }

  /// 兜底 translator。
  WidgetTranslator? get fallback => _fallback;

  /// 按源码 widget 构造名查找 translator；未注册返回 null。
  WidgetTranslator? lookup(String type) => _translators[type];

  /// 按产物 JSON 节点 type 查找 translator；未注册返回 null。
  WidgetTranslator? lookupJson(String type) => _jsonIndex[type];

  /// 当前已注册的源码类型集合（用于报错信息）。
  Set<String> get registeredTypes => _translators.keys.toSet();
}


/// 嵌套组件兜底翻译：build 树里出现其他自定义 widget 时统一翻译为
/// Component 节点（{ type: 'Component', props: { component, args? } }）。
/// 有注解的组件由生成器直接产出 JS 工厂调用（自动 import 其产物）；本兜底
/// 节点只承载**无 JS 产物**的组件（无注解的 lib 普通 widget）→ 运行时经
/// nativeComponents 原生注入或占位。
class ComponentTranslator extends WidgetTranslator {
  const ComponentTranslator();

  /// 兜底 translator 不需要参与 Map 注册（registry.registerFallback 持有），
  /// type 取哨兵值 'Component' 仅满足抽象约束。
  @override
  String get type => 'Component';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    // 构造参数字面量 → 值契约（叶子值一律为 JS 表达式字符串）：
    // 字符串经 jsString 带引号、数字/布尔转字面量，运行时 jsonEncode 即得原值。
    final args = <String, dynamic>{};
    for (final entry in node.namedArgs.entries) {
      final v = _literalValue(entry.value);
      if (v != null) args[entry.key] = _jsLiteral(v, ctx);
    }
    // 只承载无 JS 产物的组件（有注解组件的依赖已在 _renderJs 里用
    // ES module import 表达，运行时按 import 递归挂载）。
    return {
      'type': ctx.jsString('Component'),
      'props': {
        'component': ctx.jsString(node.type),
        if (args.isNotEmpty) 'args': args,
      },
    };
  }

  /// AST 字面量 → Dart 值（null 表示不可翻译）。
  static Object? _literalValue(Expression e) {
    if (e is StringLiteral) return e.stringValue;
    if (e is IntegerLiteral) return e.value;
    if (e is DoubleLiteral) return e.value;
    if (e is BooleanLiteral) return e.value;
    if (e is NullLiteral) return null;
    return null;
  }

  /// Dart 值 → JS 表达式字面量。
  static String _jsLiteral(Object? v, WidgetTranslateContext ctx) {
    if (v is String) return ctx.jsString(v);
    if (v is bool) return v ? 'true' : 'false';
    if (v == null) return 'null';
    return '$v';
  }
}

/// 跨文件「静态单例类」解析器（如 theme/panel_colors.dart 的 MyColors）。
///
/// 组件 build 树里出现 `MyColors.background` 这类静态引用时，把它翻译成
/// JS 表达式 `MyColors.background`（不带引号，jsLiteral 原样输出），并登记
/// 该单例类为 import 依赖，产物顶部生成 `import { MyColors } from '...'`。
///
/// 由生成器从组件文件的 import 源文件解析填充；未命中映射时 staticRef
/// 返回 null，调用方维持「丢键」现状，不影响其它产物。
class SingletonResolver {
  /// 类名 → 该类非私有 static 字段名集合。
  final Map<String, Set<String>> _fields = {};

  /// 类名 → 源文件 dart 路径（lib/...dart，用于推导 import 相对路径）。
  final Map<String, String> _sourceFile = {};

  /// 翻译过程中实际被引用的单例类（→ 产物 import）。
  final Set<String> used = {};

  bool get isEmpty => _fields.isEmpty;

  void add(String className, Set<String> publicStaticFields, String sourceFile) {
    _fields[className] = publicStaticFields;
    _sourceFile[className] = sourceFile;
  }

  String? sourceFileOf(String className) => _sourceFile[className];

  bool hasField(String className, String field) =>
      _fields[className]?.contains(field) ?? false;

  /// 命中静态单例字段引用（`MyColors.background`）→ 登记依赖并
  /// 返回 JS 表达式 `MyColors.background`；否则返回 null。
  String? staticRef(Expression e) {
    String? cls;
    String? field;
    if (e is PropertyAccess && e.target is Identifier) {
      cls = (e.target as Identifier).name;
      field = e.propertyName.name;
    } else if (e is PrefixedIdentifier) {
      // `MyColors.background`（两段点号名，前缀是简单标识符）→ 前缀是类名
      cls = e.prefix.name;
      field = e.identifier.name;
    }
    if (cls != null && field != null && hasField(cls, field)) {
      used.add(cls);
      return '$cls.$field';
    }
    return null;
  }
}
