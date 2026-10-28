import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart' show log;

import '../class_info.dart';
import '../../shared/ctor_signatures.dart';
import 'js_value.dart';

// ===========================================================================
// 表达式 / 语句翻译：Dart 语言 → JS 语言
//
// 只做语言层转换，不认识 widget / 组件，也不承担类结构收集：
//   - 类结构模型见 class_info.dart；
//   - 字面量 / 作用域 / SDK 映射等共享值工具见 js_value.dart；
//   - 本文件负责：exprToJs / rhsToJs / methodCallExprJs / closureToJs /
//     exprStmtToJs / translateStmtList / translateMethodBody /
//     translateClassMethodBody 等表达式与语句翻译。
//
// 依赖方向单向、无环：analyze_dart_class / dart2js / widget2js → 本文件。
// 新增一门表达式 / 语句语法只改本文件，各调用方同时生效。
//
// 唯一的「向上」缝：方法体里 `return Container(...)` 需要 widget 层参与，
// 用 js_value.dart 的 [WidgetExprRenderer] 接口解耦——本文件只依赖接口，
// 由 widget2js 实现。
// ===========================================================================

// ---------------------------------------------------------------------------
// 表达式 / 语句翻译（以 FieldScope + 已知类表为键）
// ---------------------------------------------------------------------------

// Dart 集合 / 字符串 / 数字的同名成员（`first` / `where` / `add` / `compareTo` …）
// **不在生成器做名字映射**：生成器看不到接收者类型，按名字改写会把同名业务方法
// 静默改错。统一原样产出 `x.first` / `x.where(...)` / `x.add(...)`，由运行时
//【1c】节给 Array / Number / String 内建原型补同名同义成员，按接收者类型分发。

/// 读位置表达式 → JS 表达式（this._model.n / this._model / 字面量 / 形参）。
String? exprToJs(Expression e, FieldScope scope, Map<String, ClassInfo> classes) {
  // 构造表达式（`Color(0xFF…)` / `Color.fromARGB(…)` / 任意 `X(…)`）→
  // `new X({...})`（命名构造 `X.b({...})` 仅在签名表命中时接管）。
  // 颜色不是特殊形态：`Color` 与其它类一样由运行时注入同名类。
  final ctorJs = valueCtorJs(e, scope, classes);
  if (ctorJs != null) return ctorJs;
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
    // State 内 `widget.x`（访问 widget 自身字段）→ 合并类的实例属性 `this.x`：
    // widget 与 State 在 JS 侧是同一个类，widget 字段即实例字段。
    if (e.prefix.name == 'widget') {
      return scope.fieldRef(e.identifier.name);
    }
    // `Icons.chevron_right` → 图标名字符串（运行时按名映射回 IconData）。
    // 不在这里拦下来，会落到下面的「大写开头前缀原样保留」，产出未定义的 JS
    // 全局 `Icons`——作为组件实参（`_DevRow(icon: Icons.x)`）直接运行时崩。
    if (e.prefix.name == 'Icons') return jsString(e.identifier.name);
    final p = scope.fieldRef(e.prefix.name);
    String? base;
    if (p != null) {
      base = p;
    } else if (scope.globalConsts.contains(e.prefix.name)) {
      // 前缀是顶层常量（如 `kOrderStatus.first`）→ JS 侧同名模块级常量。
      base = e.prefix.name;
    } else if (e.prefix.name.isNotEmpty &&
        RegExp(r'^[A-Z]').hasMatch(e.prefix.name)) {
      // prefix 是大写开头的外部类名（如 Network.post）→ 原样保留。
      base = e.prefix.name;
    }
    if (base == null) return null;
    return '$base.${e.identifier.name}';
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
  // 级联 `target..m(a)..n(b)`：Dart 返回 target 本身。译成 IIFE：
  // `(() => { const _t = <target>; _t.m(a); _t.n(b); return _t; })()`。
  // 常见形态 `list..sort(cmp)`（原方法体内就地排序）与 `c..addListener(..)`，
  // 顺序与返回值都与 Dart 一致。
  if (e is CascadeExpression) {
    final t = exprToJs(e.target, scope, classes);
    if (t == null) return null;
    final stmts = <String>[];
    for (final s in e.cascadeSections) {
      if (s is MethodInvocation) {
        final argsJs = <String>[];
        for (final a in s.argumentList.arguments) {
          final inner = a is NamedExpression ? a.expression : a;
          final v = inner is FunctionExpression
              ? closureToJs(inner, scope, classes)
              : rhsToJs(inner, scope, classes);
          if (v == null) return null;
          argsJs.add(v);
        }
        stmts.add('_t.${s.methodName.name}(${argsJs.join(', ')})');
      } else if (s is PropertyAccess) {
        stmts.add('_t.${s.propertyName.name}');
      } else {
        return null;
      }
    }
    return '(() => { const _t = $t; ${stmts.join('; ')}; return _t; })()';
  }
  // 三目 `c ? a : b`（组件数据/样式与模型方法体共用）。
  if (e is ConditionalExpression) {
    final c = exprToJs(e.condition, scope, classes);
    final t = exprToJs(e.thenExpression, scope, classes);
    final f = exprToJs(e.elseExpression, scope, classes);
    if (c == null || t == null || f == null) return null;
    return '($c ? $t : $f)';
  }
  // switch 表达式（Dart 3）→ IIFE + JS switch（JS 无 switch 表达式语法）。
  if (e is SwitchExpression) return _switchExpressionJs(e, scope, classes);
  // `this`（如 `TabController(length: n, vsync: this)`）：JS 侧方法/构造实参里
  // 的 this 就是组件实例，一比一透传；Dart 侧专属的实参（vsync）由 JS 代理类
  // 构造自行忽略。
  if (e is ThisExpression) return 'this';
  if (e is Identifier) {
    // kDebugMode / kReleaseMode → 运行时注入的全局标志
    final flag = globalFlagJs(e.name);
    if (flag != null) return flag;
    // State.mounted：JS 组件基类有 __unmounted 标记，未卸载即视为已挂载
    if (e.name == 'mounted') return '!this.__unmounted';
    // 顶层常量（如 `kBanners`）：JS 侧是同名模块级常量，原样引用。
    if (scope.globalConsts.contains(e.name)) return e.name;
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
  // 组件/值对象出现在**任意表达式位置**（方法实参、三元分支、列表元素）时，
  // 先交给属性管线（[widgetArgJsHook]，由 widget2js 安装）：子结点槽位与
  // 值转换器必须与 children 里的组件一致，否则会出现「JS 侧不存在的类调用」
  // （如 `ImageFilter.blur`）。钩子只接管 JS 侧能解析成类的类型，其余回落。
  final hooked = widgetArgJsHook?.call(e);
  if (hooked != null) return hooked;
  // StringInterpolation 是 StringLiteral 子类，必须先判（否则被吞成 ""）
  if (e is StringInterpolation) return _logArgJs(e, scope, classes);
  // 相邻字符串字面量拼接（`'a' 'b'`，Dart 语义是**拼接**）同为 StringLiteral 子类，
  // 在 literalToJs 里只能翻「全为常量」的情况；这里交给 exprToJs 的
  // AdjacentStrings 分支逐段翻译，含插值的段才翻得出来（必须早于下面的 literalToJs）。
  if (e is AdjacentStrings) return exprToJs(e, scope, classes);
  // `await <expr>` 统一在这里处理：声明初始化、赋值右侧、实参、独立语句
  // 全都经过 rhsToJs，await 不再只认声明那一种位置（原来 `_x = await f()`
  // 会整条丢掉）。
  if (e is AwaitExpression) {
    final v = _awaitInnerJs(e.expression, scope, classes);
    return v == null ? null : 'await $v';
  }
  final lit = literalToJs(e);
  if (lit != null) return lit;
  // 构造统一翻译（唯一一条规则）：
  //   `A(args)`   → `new A({...})`
  //   `A.b(args)` → `A.b({...})`
  // 位置实参按**源码构造签名**映射成形参名（CtorSignatures 自动抽取，覆盖
  // 项目类 / SDK / 全部依赖包）。不再维护 Key / 控制器 / 值类 / 异常的类名表：
  // 这些类由运行时注入同名类（capabilities/ 下），翻译层与运行时都不感知扩展。
  final ctorJs = valueCtorJs(e, scope, classes);
  if (ctorJs != null) return ctorJs;
  // PrefixedIdentifier（`a.b`）不是单纯字段名，交给 exprToJs 的属性分支；
  // 若走下面的 Identifier 分支会用整串名字查字段而必然失败。
  if (e is PrefixedIdentifier) return exprToJs(e, scope, classes);
  // Identifier 一律交给 exprToJs 统一处理（全局标志 kDebugMode、State.mounted、
  // 字段/形参/局部变量同一套解析）——不再在此处单独 fieldRef，否则这些
  // 「非字段标识符」会被漏掉。
  if (e is InstanceCreationExpression) return modelCtorToJs(e, scope, classes);
  // 无 `const`/`new` 的模型构造（如 `const kX = [HomeBanner(...)]` 的元素）在无
  // resolution 的 parseString 下是 MethodInvocation。仅当名字命中已知类表时才按
  // 模型构造处理（避免把 widget 构造 `Text(...)` 误当模型）。
  if (e is MethodInvocation && e.target == null && e.typeArguments == null) {
    final n = e.methodName.name;
    if (classes.containsKey(n)) {
      final ctor = modelCtorFromPartsJs(
          n, e.argumentList.arguments.toList(), scope, classes);
      if (ctor != null) return ctor;
    }
  }
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

/// 构造表达式 → JS 构造调用；非构造返回 null。
///
/// 唯一规则（所有类一视同仁，不含任何类名表）：
/// - `A(args)` → `new A({...})`
/// - `A.b(args)` → `A.b({...})`（签名表能证明 `A` 有构造 `b` 时才接管，避免
///   把 `Theme.of(context)` 这类静态方法/普通调用误当构造）
///
/// 位置实参用 [CtorSignatures] 从源码签名映射成形参名；签名缺失时落
/// `__pos` 下标数组并出声告警，由运行时按构造签名展开——不静默丢弃。
String? valueCtorJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  String? cls;
  String? ctorName;
  List<Expression> args = const [];
  if (e is InstanceCreationExpression) {
    // 类型实参在 JS 里不存在（Dart→JS 语义即擦除），构造名只取类型实参之前
    // 的部分：`GlobalKey<AnimatedListState>()` 与 `GlobalKey()` 是同一个类。
    var src = e.constructorName.type.toSource();
    final lt = src.indexOf('<');
    if (lt >= 0) src = src.substring(0, lt).trim();
    final dot = src.indexOf('.');
    cls = dot < 0 ? src : src.substring(0, dot);
    ctorName = dot < 0 ? null : src.substring(dot + 1);
    args = e.argumentList.arguments.toList();
  } else if (e is MethodInvocation && e.target is SimpleIdentifier) {
    cls = (e.target! as SimpleIdentifier).name;
    ctorName = e.methodName.name;
    args = e.argumentList.arguments.toList();
  } else if (e is MethodInvocation && e.target == null) {
    // 无 `new` 的构造调用：`GlobalKey()` / `GlobalKey<AnimatedListState>()` ——
    // 类型实参在 JS 里不存在，一律擦除；非类名（首字母非大写）由下面拦掉。
    cls = e.methodName.name;
    args = e.argumentList.arguments.toList();
  }
  if (cls == null || !_isClassLikeName(cls)) return null;
  final posCount = args.where((a) => a is! NamedExpression).length;
  // 命名形态（`A.b(...)`）只在签名表命中时接管：否则可能是静态方法调用。
  final signatures = CtorSignatures.instance;
  final sig = signatures?.of(cls,
      ctorName: ctorName, positionalCount: posCount);
  if (ctorName != null && sig == null) return null;
  final positional = sig?.positional ?? const <String>[];
  final entries = <String>[];
  final rest = <String>[];
  var posIndex = 0;
  for (final a in args) {
    if (a is NamedExpression) {
      final v = _ctorArgJs(a.expression, scope, classes);
      if (v == null) return null;
      entries.add('${a.name.label.name}: $v');
      continue;
    }
    final v = _ctorArgJs(a, scope, classes);
    if (v == null) return null;
    if (posIndex < positional.length) {
      entries.add('${positional[posIndex]}: $v');
    } else {
      rest.add(v);
    }
    posIndex++;
  }
  if (rest.isNotEmpty) {
    // 签名未知（源码里找不到该类）→ 下标兜底，运行时按构造签名展开。
    // ignore: avoid_print - 构建期日志
    print('[hot_patch_generator] 构造 $cls${ctorName == null ? '' : '.$ctorName'} '
        '的位置实参缺少形参名签名，落 __pos 兜底：${rest.join(', ')}');
    entries.add('__pos: [${rest.join(', ')}]');
  }
  // 类型实参：Dart 泛型在 AOT 是 **reified** 的（运行时真实存在），一比一映射为
  // `typeArguments`（类型名数组，与 `context.read<T>()` 把 T 当参数下发同一原则）。
  // 运行时/宿主谁需要谁取（如 `GlobalKey<T>.currentState` 用它确定代理类），
  // 翻译层不做类型判断、不维护类型名单。无类型实参时不产生该键。
  final typeArgs = _typeArgsOf(e);
  if (typeArgs.isNotEmpty) {
    entries.add(
      'typeArguments: [${typeArgs.map((t) => "'${t.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'").join(', ')}]',
    );
  }
  final props = entries.isEmpty ? '' : '{${entries.join(', ')}}';
  return ctorName == null ? 'new $cls($props)' : '$cls.$ctorName($props)';
}

/// 构造调用的类型实参名（`GlobalKey<AnimatedListState>()` → ['AnimatedListState']）。
///
/// 覆盖三种写法：`const A<T>()`、`A<T>.b()`、`A<T>()`（无 const，parseString 下
/// 是 MethodInvocation）。嵌套泛型保留源码文本（`List<int>`）。
List<String> _typeArgsOf(Expression e) {
  final List<TypeAnnotation>? args = switch (e) {
    InstanceCreationExpression() => e.constructorName.type.typeArguments?.arguments,
    MethodInvocation() => e.typeArguments?.arguments,
    _ => null,
  };
  return [for (final a in args ?? const <TypeAnnotation>[]) a.toSource()];
}

/// 实参位置的「结构化值」钩子：由 widget2js 在求值数据表达式期间安装
/// （[WidgetTranslateContext.jsDataExpr]）。命中返回 JS 源码时，该实参按
/// **组件/值对象属性管线**翻译（子结点槽位协议、值转换器、builder 展开全部
/// 生效）；返回 null 则回落到通用构造翻译。
///
/// 必要性：通用构造翻译（[valueCtorJs]）只有签名表，没有属性管线。于是
/// `helper(ImageFiltered(imageFilter: ImageFilter.blur(...)))` 这种「组件当
/// 实参」的位置会把 `ImageFilter.blur` 译成 JS 类调用（JS 侧不存在该类），
/// 子结点也不会拆成槽位。钩子让这类实参与 children 里的组件走**同一条**
/// 翻译路径，不再有两套产物形态。
typedef WidgetArgJsHook = String? Function(Expression e);

/// 当前生效的实参钩子（翻译是单线程的，按数据表达式调用期安装/还原）。
WidgetArgJsHook? widgetArgJsHook;

bool _isClassLikeName(String name) {
  if (name.isEmpty) return false;
  final c = name.codeUnitAt(0);
  return c >= 0x41 && c <= 0x5A;
}

/// 构造实参 → JS：闭包走 [closureToJs]（与普通方法调用 `addListener(() {...})`
/// 同一口径），其余走 [rhsToJs]。
///
/// 构造实参里的闭包在 Dart 里很常见（`Timer.periodic(d, (t) {...})`、
/// `ValueNotifier(...)` 包装、`XxxModel(onDone: () {...})`）。缺了这一条，
/// [rhsToJs] 对 FunctionExpression 返回 null，整个构造翻译失败，外层语句被
/// 丢弃——正是「静默丢代码」的来源。
String? _ctorArgJs(
  Expression a,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (a is FunctionExpression) return closureToJs(a, scope, classes);
  return rhsToJs(a, scope, classes);
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
  // 参数支持字符串插值（拼接翻译），插值对象时经 `__str` 展开字段
  //（`console.log(oldWidget)` 这类直接传对象的由运行时 console 桥负责展开）。
  if (e.target == null) {
    final name = e.methodName.name;
    if (name == 'debugPrint' || name == 'print') {
      final args = e.argumentList.arguments;
      final v = args.isEmpty
          ? '""'
          : _logArgJs(args.first, scope, classes, expand: true);
      if (v == null) return null;
      final method = name == 'debugPrint' ? 'debug' : 'log';
      return 'console.$method($v);';
    }
  }
  final call = methodCallExprJs(e, scope, classes);
  return call == null ? null : '$call;';
}

/// 日志参数 → JS 表达式：字符串 / 插值拼接 / 字段引用 / 属性链。
///
/// [expand] 仅由「日志调用」置真（`print` / `debugPrint` 的实参）：插值片段
/// 包一层运行时 `__str`，把对象/数组展开成字段文本（Dart 的 `'$x'` 走
/// `toString()`，JS 的 `+` 只给 `[object Object]`）。
/// **其余位置（widget 文案、props 数据、模型初始化）保持原样**：那里的插值
/// 值都是字符串/数字，包一层只是无谓地给产物引入 `__str` 全局依赖。
String? _logArgJs(
  Expression a,
  FieldScope scope,
  Map<String, ClassInfo> classes, {
  bool expand = false,
}) {
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
          parts.add(expand ? '__str($v)' : v);
        } else {
          // 丢片段会让产物「看着对、其实少东西」（如 `"用户信息:$x"` →
          // `"用户信息:"`），故必须出声，不能静默。
          log.warning('[hot_patch_generator] 插值片段无法翻译，已在 JS 产物中'
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

/// 闭包参数 → JS 函数表达式：`() {...}` → `() => { ... }`、
/// `(v) => expr` → `(v) => { return <expr>; }`（一律箭头函数）。
///
/// 闭包体逐语句翻译，其中 `setState(() {...})` 展开为
/// `this.setState(() => { ... })`（与组件方法体里的 setState 同构）。
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
  // 闭包形参登记进作用域：`where((o) => o.status == _status)` 里的 `o` 必须
  // 解析为形参，否则谓词翻译失败、连带整个 `where(...)` 与外围表达式被丢弃。
  final bodyScope = params.isEmpty ? scope : scope.withParams(params);
  final body = fn.body;
  // 一律输出箭头函数：this 词法绑定到定义处（组件实例），与 Dart 闭包
  // 捕获 this 的语义一致——回调（如 addListener 闭包）由宿主经 invoke
  // 普通调用触发时 this 不会丢失，无需 .bind。引擎为 flutter_js
  // （macOS/iOS JavaScriptCore、Android QuickJS），均完整支持 ES6。
  if (body is ExpressionFunctionBody) {
    // 表达式体在 Dart 里就是一个**值**，JS 侧必须 `return`，否则
    // `sort((a, b) => a.compareTo(b))` / `map((e) => e.name)` 这类回调会把
    // 返回值丢掉（谓词恒为 undefined）。先按值翻译并 return；只有值形态翻译
    // 不出来（赋值 `_x = 5`、`setState(...)` 等语句形态）才退回语句翻译。
    final rv = rhsToJs(body.expression, bodyScope, classes);
    if (rv != null) return '($pjs) => { return $rv; }';
    final v = closureBodyStmtJs(body.expression, bodyScope, classes);
    if (v != null) return '($pjs) => { $v }';
    return null;
  }
  if (body is BlockFunctionBody) {
    // 块体逐语句翻译——与方法体、`_setStateJs` 共用**同一条** [translateStmtList]：
    // 声明、if/for/while/switch、setState 展开全部覆盖。旧实现只收
    // `ExpressionStatement`，`onPick: (k, v) { setState(() { switch ... }) }`
    // 这类块体会被静默丢成 `(...) => {}`（筛选面板点选条件无任何反应）。
    final stmts =
        translateStmtList(body.block.statements, bodyScope, classes, null);
    if (stmts.trim().isEmpty) return null;
    return '($pjs) => { ${stmts.trim()} }';
  }
  return null;
}

/// 闭包体内的单条表达式语句 → JS：与方法体共用 [\_bodyExprStmtJs]
/// （`setState(...)` 展开 + 赋值/自增/对象方法调用等）。保留本函数只为兼容
/// 表达式体闭包的调用点（`(v) => expr` 分支）。
String? closureBodyStmtJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) =>
    _bodyExprStmtJs(e, scope, classes);

/// 方法调用（表达式位置）：返回 `obj.method(args)` / `this.method(args)`。
String? methodCallExprJs(
  MethodInvocation e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  // `context.watch<T>()` / `context.read<T>()`（provider 包）→ **调用面与 Dart
  // 完全一致**：`context.watch("T")`，`context` 是运行时传入 build 的
  // BuildContext 代理（见 hot_patch 的 capabilities/build_context/build_context_js.dart）。
  // 类型实参 `T` 原样传给 JS——本端按类型名沿 `__parent` 找最近的 provider
  // 宿主结点，同时把类型名发给宿主（Dart 端通用 VM 记着它）。
  // receiver 走 [exprToJs] 而非硬编码：构建作用域里就是形参 `context`；
  // 事件等**延迟作用域**里形参不可见，由作用域别名解析成 `this.context`
  // （运行时按执行位置解析到对应代理，见 WidgetTranslateContext._eventScope）。
  final tgt = e.target;
  if (tgt is Identifier && tgt.name == 'context') {
    final name = e.methodName.name;
    if ((name == 'watch' || name == 'read') &&
        e.argumentList.arguments.isEmpty) {
      final ta = e.typeArguments?.arguments;
      if (ta != null && ta.length == 1 && ta.first is NamedType) {
        final model = (ta.first as NamedType).name2.lexeme;
        final recv = exprToJs(tgt, scope, classes) ?? 'context';
        return '$recv.$name(${jsString(model)})';
      }
      return null;
    }
  }
  // Dart 集合 / num 的成员与 JS 内建同名同义（`first` / `where` / `add` /
  // `removeAt` / `insert` / `toList` / `compareTo` / `toStringAsFixed` …）：
  // 生成器**不做任何名字映射**，统一走下面的通用调用路径原样产出
  // `xs.where(...)` / `xs.add(...)` / `a.compareTo(b)`，由运行时【1c】节给
  // Array / Number / String 内建原型补同名同义成员，按接收者类型分发。
  final args = e.argumentList.arguments;
  final argJs = <String>[]; // 普通调用：位置化扁平（JS 无具名参数）
  final posJs = <String>[]; // 宿主注入：位置实参
  final namedJs = <String>[]; // 宿主注入：具名实参（`"名": 值`）
  for (final a in args) {
    // 闭包参数（addListener(() {...}) / TextButton(onPressed: () => ...) 等）：
    // 翻译成 JS 函数表达式，匿名天然支持——不合成方法名、无重名问题。
    // 闭包体逐语句翻译，setState(...) 展开为 this.setState(() => {...})。
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
  // 整体替换为 `_app_host_.invoke("通道名", {p: [a], n: {...}})`（返回 Promise，可 await）。
  final hostTarget = e.target;
  if (hostTarget is Identifier) {
    final channel = scope.hostMethods[hostTarget.name]?[e.methodName.name];
    if (channel != null) {
      return '_app_host_.invoke(${jsString(channel)}, ${hostArgsJs(posJs, namedJs)})';
    }
  }
  final passed = argJs.join(', ');
  final target = e.target;
  if (target == null) {
    // 顶层函数（全局方法）：@HostInjected → `_app_host_.invoke("通道", {p, n})`。
    final topChannel = scope.hostMethods['']?[e.methodName.name];
    if (topChannel != null) {
      return '_app_host_.invoke(${jsString(topChannel)}, ${hostArgsJs(posJs, namedJs)})';
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

/// `<字段>.<属性>`（PrefixedIdentifier）→ JS 引用串（`this._count.value`）。
///
/// 用于 SDK 值对象（`ValueNotifier<int>` 等）的典型用法：字段本身走
/// [FieldScope.fieldRef]（→ `this._count` / 局部变量名），属性部分原样拼接
/// （JS 侧同名属性 / get 访问器）。LHS 不是「本 scope 可解析字段」时返回 null，
/// 交由调用方丢弃（保持「不可翻译不静默错译」的纪律）。
String? _prefixedFieldRef(Expression e, FieldScope scope) {
  if (e is! PrefixedIdentifier) return null;
  final base = scope.fieldRef(e.prefix.name);
  if (base == null) return null;
  return '$base.${e.identifier.name}';
}

/// 纯标识符判定：`_x` 是，`_x.y`（[PrefixedIdentifier]）**不是**。
///
/// **不能只写 `is Identifier`**：analyzer 里 `PrefixedIdentifier` 也
/// `implements Identifier`，裸判定会把 `_count.value++` 当成字段 `_count.value`
/// 的标识符，`fieldRef` 解析不到就整条丢弃（静默丢代码）。
bool _isPlainIdentifier(Expression e) => e is Identifier && e is! PrefixedIdentifier;

/// 一条表达式语句 → JS 语句（带分号）。
///
/// 支持：`_x++ / _x-- / ++_x / --_x`（字段→this）、赋值 `_x = rhs / _x op= rhs`、
/// 字段属性赋值/自增 `_x.y = rhs` / `_x.y++`（[`_prefixedFieldRef`]）、
/// 方法调用（对象方法 / 白名单裸调）。不可翻译返回 null（由调用方丢弃）。
String? exprStmtToJs(Expression e, FieldScope scope, Map<String, ClassInfo> classes) {
  // `throw <expr>;`：Dart 的 throw 在 AST 里是 ThrowExpression（包在
  // ExpressionStatement 里），JS 的 throw 是语句，这里直接产出 `throw ...;`。
  if (e is ThrowExpression) {
    final v = rhsToJs(e.expression, scope, classes);
    return v == null ? null : 'throw $v;';
  }
  // _x++ / ++_x / _x--
  if (e is PostfixExpression && _isPlainIdentifier(e.operand)) {
    final ref = scope.fieldRef((e.operand as Identifier).name);
    if (ref != null) {
      final delta = e.operator.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$ref += $delta;';
    }
    return null;
  }
  if (e is PrefixExpression && _isPlainIdentifier(e.operand)) {
    final ref = scope.fieldRef((e.operand as Identifier).name);
    if (ref != null) {
      final delta = e.operator.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$ref += $delta;';
    }
    return null;
  }
  if (e is AssignmentExpression && _isPlainIdentifier(e.leftHandSide)) {
    final ref = scope.fieldRef((e.leftHandSide as Identifier).name);
    if (ref != null) {
      final rhs = rhsToJs(e.rightHandSide, scope, classes);
      if (rhs != null) return '$ref ${e.operator.lexeme} $rhs;';
    }
    return null;
  }
  // 字段的属性赋值 / 自增（`_count.value = 5`、`_count.value++`）：
  // SDK 值对象（ValueNotifier / Listenable 代理类）的典型用法，LHS 是
  // PrefixedIdentifier（`<字段>.<属性>`）。字段部分走 fieldRef（→ `this._count`），
  // 属性部分原样保留（JS 侧同名属性/访问器，如 ValueNotifier.prototype.value）。
  if (e is AssignmentExpression && _prefixedFieldRef(e.leftHandSide, scope) != null) {
    final lhs = _prefixedFieldRef(e.leftHandSide, scope)!;
    final rhs = rhsToJs(e.rightHandSide, scope, classes);
    if (rhs != null) return '$lhs ${e.operator.lexeme} $rhs;';
    return null;
  }
  if ((e is PostfixExpression || e is PrefixExpression)) {
    final operand = e is PostfixExpression ? e.operand : (e as PrefixExpression).operand;
    final lhs = _prefixedFieldRef(operand, scope);
    if (lhs != null) {
      final op = e is PostfixExpression ? e.operator : (e as PrefixExpression).operator;
      final delta = op.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$lhs += $delta;';
    }
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
  WidgetExprRenderer? widgetCtx,
  bool returnExpressionBody = false,
  bool returnsWidget = true,
  int depth = 2,
}) {
  final out = <String>[];
  final ind = '  ' * depth;
  if (body is ExpressionFunctionBody) {
    final e = body.expression;
    String? t;
    if (widgetCtx != null && returnsWidget && _isWidgetCtorExpr(e)) {
      t = _widgetExprToJs(widgetCtx, e, depth);
    }
    t ??= _bodyExprStmtJs(e, scope, classes);
    if (t != null) {
      out.add('$ind${returnExpressionBody ? 'return $t;' : t}');
    } else {
      // 语句级不认的表达式（switch 表达式、集合字面量、纯值表达式）：回退到
      // 通用表达式翻译。缺这一步会让「箭头体方法」静默产出空方法体
      // （如 `Color _statusColor(s) => switch (s) {...}` → 空 `{}`）。
      final v = rhsToJs(e, scope, classes);
      if (v != null) {
        out.add('$ind${returnExpressionBody ? 'return $v;' : v}');
      } else {
        log.warning('[hot_patch_generator] 方法体表达式无法翻译，已在 JS '
            '产物中丢弃：${e.toSource()}');
      }
    }
  } else if (body is BlockFunctionBody) {
    final r = translateStmtList(body.block.statements, scope, classes, widgetCtx,
        depth: depth, returnsWidget: returnsWidget);
    if (r.isNotEmpty) out.add(r);
  }
  return out.isEmpty ? '' : out.join('\n');
}

/// 「纯字段路径」形初始化器：`x` / `feed.spots` / `this.a.b`——只有标识符与点号，
/// 没有调用、下标、运算、await。变量声明的**别名折算**只对这类形态生效（见
/// [translateStmtList] 的声明分支）：折算出的别名是「按引用重求值」语义，
/// 带调用的表达式一旦被折算，每次使用都会重跑，语义就不再等价。
final RegExp _fieldPath = RegExp(
  r'^[A-Za-z_$][A-Za-z0-9_$]*(?:\s*\.\s*[A-Za-z_$][A-Za-z0-9_$]*)*\s*$',
);

/// 语句列表 → JS（方法体块、if 分支体共用同一套循环）。
///
/// 支持：表达式语句（super 调用忽略、setState 展开）、变量声明、return、
/// if/else、for（三段式 / for-in）、while、do-while、switch（常量 case）、
/// break / continue。无法翻译的语句出声告警（不静默丢代码）。
///
/// 输出为**多行可读**格式：每条语句一行、按 [depth] 缩进（2 空格/层）。
String translateStmtList(
  List<Statement> stmts,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  WidgetExprRenderer? widgetCtx, {
  int depth = 0,
  bool returnsWidget = true,
}) {
  final out = <String>[];
  final ind = '  ' * depth;
  for (final s in stmts) {
    if (s is ExpressionStatement) {
      final e = s.expression;
      // super 调用：查当前方法的 superMap（mixin 线性化展开后链上下一个实现）。
      // 命中 → `this._m$Mixin$m(...)`；未命中 → 基类无 JS 等价物，忽略（原行为）。
      if (e is MethodInvocation && e.target is SuperExpression) {
        final target = scope.superMap[e.methodName.name];
        if (target == null) continue;
        final argsJs = <String>[];
        var ok = true;
        for (final a in e.argumentList.arguments) {
          final inner = a is NamedExpression ? a.expression : a;
          final v = inner is FunctionExpression
              ? closureToJs(inner, scope, classes)
              : rhsToJs(inner, scope, classes);
          if (v == null) {
            ok = false;
            break;
          }
          argsJs.add(v);
        }
        if (!ok) {
          log.warning('[hot_patch_generator] super 调用实参无法翻译，已在 JS '
              '产物中丢弃：${e.toSource()}');
          continue;
        }
        out.add('$ind' 'this.$target(${argsJs.join(', ')});');
        continue;
      }
      final t = _bodyExprStmtJs(e, scope, classes);
      if (t != null) {
        out.add('$ind$t');
      } else {
        log.warning('[hot_patch_generator] 语句无法翻译，已在 JS 产物中'
            '丢弃：${e.toSource()}');
      }
    } else if (s is VariableDeclarationStatement) {
      // 局部变量声明 `String? name = await X.y();` → `var name = ...;`，
      // 名字登记进 scope，后续语句（含插值）可直接引用。
      for (final v in s.variables.variables) {
        final name = v.name.lexeme;
        // 同步登记到 widget 层：方法体里随后 `return Text('$name')` 时，
        // widget 翻译器要用同一份局部变量表解析标识符（与语句翻译同源）。
        widgetCtx?.registerLocal(name);
        if (v.initializer == null) {
          out.add('${ind}var $name;');
          scope.localVars.add(name);
          continue;
        }
        // 初始化器单独用一份作用域（[FieldScope.forInitializer]）：把**已登记
        // 的字段别名**折算进来，方法体其余语句不受影响。
        //
        // 只对「纯字段路径」（`x` / `feed.spots` / `this.a.b`，无调用、下标、运算）
        // 折算：别的形态（`ctx.findRenderObject()`、`label + "…"`）一旦折算，
        // 局部会被登记成「按引用重求值」的别名，那**每一次使用**都要重跑——
        // 有调用的表达式（GlobalKey.currentContext、List.removeAt）重跑即语义
        // 不同，会把既有产物改坏。链式别名的收益只发生在字段路径上，收窄到它即可。
        final purePath = _fieldPath.hasMatch(v.initializer!.toSource());
        // 初始化器按通用表达式翻译：`const Text('x')` → `new Text({...})`
        // （组件包装类构造即产出元素，普通类产出实例，运行时统一归一化）。
        final init = rhsToJs(
          v.initializer!,
          purePath ? scope.forInitializer() : scope,
          classes,
        );
        if (init == null) {
          // 变量没声明 → 后面引用它的语句（含插值）会连带失效，必须出声。
          log.warning('[hot_patch_generator] 局部变量声明无法翻译，已在 JS '
              '产物中丢弃：${s.toSource()}');
          continue;
        }
        out.add('${ind}var $name = $init;');
        scope.localVars.add(name);
        // 该局部只是「字段 / getter 的别名」（`final list = _list;` →
        // `this._list`）：登记进 widget 层，懒加载 builder 抽成实例方法后引用它
        // 时才能落到 `this._list`，而不是未定义的自由变量（`ReferenceError`）。
        //
        // 同时记进 [FieldScope.declAliases]，供**后续声明的初始化器**折算——
        // 链式别名靠这一步闭合：`final spots = feed.spots;` 里的 `feed` 先折成
        // `this._feed`，`spots` 于是也成了字段别名。缺这一步，二级别名会以裸名
        // 进产物（`spots[index]`），被抽进 builder 方法后就是
        // `ReferenceError: Can't find variable: spots`。
        //
        // 仅限 final / const：别名语义是「按引用重求值」，可重新赋值的变量用它
        // 会让后续声明拿到旧表达式（`list = other;` 之后再声明就以旧值折算）。
        if (init.startsWith('this.')) {
          widgetCtx?.registerLocalAlias(name, init);
          if (purePath && (s.variables.isFinal || s.variables.isConst)) {
            scope.declAliases[name] = init;
          }
        }
      }
    } else if (s is ReturnStatement) {
      // `return "22";` 是 ReturnStatement（不是 ExpressionStatement），
      // 需单独翻译为 `return <expr>;`，否则 async 方法体被整体丢弃。
      final e = s.expression;
      if (e == null) {
        out.add('${ind}return;');
        continue;
      }
      String? v;
      if (widgetCtx != null && returnsWidget && _isWidgetCtorExpr(e)) {
        v = _widgetExprToJs(widgetCtx, e, depth);
      }
      v ??= rhsToJs(e, scope, classes);
      if (v != null) {
        out.add('${ind}return $v;');
      } else {
        log.warning('[hot_patch_generator] return 表达式无法翻译，已在 JS '
            '产物中丢弃：${s.toSource()}');
      }
    } else if (s is IfStatement) {
      final condJs = exprToJs(s.expression, scope, classes);
      if (condJs == null) {
        log.warning('[hot_patch_generator] if 条件无法翻译，已在 JS 产物中'
            '丢弃：${s.toSource()}');
        continue;
      }
      final thenStmts =
          s.thenStatement is Block ? (s.thenStatement as Block).statements : [s.thenStatement];
      var js = '$ind' 'if ($condJs) {\n'
          '${translateStmtList(thenStmts, scope, classes, widgetCtx, depth: depth + 1, returnsWidget: returnsWidget)}\n'
          '$ind}';
      final els = s.elseStatement;
      if (els != null) {
        final elseStmts = els is Block ? els.statements : [els];
        js += ' else {\n'
            '${translateStmtList(elseStmts, scope, classes, widgetCtx, depth: depth + 1, returnsWidget: returnsWidget)}\n'
            '$ind}';
      }
      out.add(js);
    } else if (s is ForStatement) {
      final js = _forStatementJs(s, scope, classes, widgetCtx, depth, returnsWidget);
      if (js == null) {
        log.warning('[hot_patch_generator] for 语句无法翻译，已在 JS 产物中'
            '丢弃：${s.toSource()}');
      } else {
        out.add(js);
      }
    } else if (s is WhileStatement) {
      final condJs = exprToJs(s.condition, scope, classes);
      if (condJs == null) {
        log.warning('[hot_patch_generator] while 条件无法翻译，已在 JS 产物'
            '中丢弃：${s.toSource()}');
        continue;
      }
      out.add('$ind' 'while ($condJs) {\n'
          '${translateStmtList(_bodyStmts(s.body), scope, classes, widgetCtx, depth: depth + 1, returnsWidget: returnsWidget)}\n'
          '$ind}');
    } else if (s is DoStatement) {
      final condJs = exprToJs(s.condition, scope, classes);
      if (condJs == null) {
        log.warning('[hot_patch_generator] do-while 条件无法翻译，已在 JS '
            '产物中丢弃：${s.toSource()}');
        continue;
      }
      out.add('$ind' 'do {\n'
          '${translateStmtList(_bodyStmts(s.body), scope, classes, widgetCtx, depth: depth + 1, returnsWidget: returnsWidget)}\n'
          '$ind} while ($condJs);');
    } else if (s is SwitchStatement) {
      final js = _switchStatementJs(s, scope, classes, widgetCtx, depth, returnsWidget);
      if (js == null) {
        log.warning('[hot_patch_generator] switch 语句无法翻译（仅支持常量 '
            'case），已在 JS 产物中丢弃：${s.toSource()}');
      } else {
        out.add(js);
      }
    } else if (s is BreakStatement) {
      out.add('${ind}break;');
    } else if (s is ContinueStatement) {
      out.add('${ind}continue;');
    } else if (s is AssertStatement) {
      // Dart `assert(condition, [message])` → JS 原样调用 `assert(...)`；
      // 函数本体由运行时【1c】节注入（debug 门控 + 失败抛 Error），
      // 生成器不改写语义，保持与 Dart 源码一比一。
      final condJs = exprToJs(s.condition, scope, classes);
      if (condJs == null) {
        log.warning('[hot_patch_generator] assert 条件无法翻译，已在 JS 产物'
            '中跳过：${s.toSource()}');
        continue;
      }
      String? msgJs;
      final message = s.message;
      if (message != null) {
        msgJs = rhsToJs(message, scope, classes);
        if (msgJs == null) {
          log.warning('[hot_patch_generator] assert 消息无法翻译，已在 JS 产物'
              '中跳过：${s.toSource()}');
          continue;
        }
      }
      out.add('$ind' 'assert($condJs${msgJs == null ? '' : ', $msgJs'});');
    } else if (s is TryStatement) {
      final js =
          _tryStatementJs(s, scope, classes, widgetCtx, depth, returnsWidget);
      if (js == null) {
        log.warning('[hot_patch_generator] try 语句无法翻译，已在 JS 产物中'
            '跳过：${s.toSource()}');
      } else {
        out.add(js);
      }
    } else if (s is EmptyStatement) {
      // 空语句没有语义，跳过不需要告警。
    } else if (s is Block) {
      // 裸块语句：作用域语义在 JS 侧由 `{}` 保留，逐条递归即可。
      out.add('$ind{\n'
          '${translateStmtList(s.statements, scope, classes, widgetCtx, depth: depth + 1, returnsWidget: returnsWidget)}\n'
          '$ind}');
    } else {
      // 兜底：任何未覆盖的语句都必须出声，禁止静默丢代码。
      // 典型：try/catch、throw、assert、局部函数、pattern 声明、label 等。
      log.warning('[hot_patch_generator] 不支持的语句类型 ${s.runtimeType}，'
          '已在 JS 产物中跳过：${s.toSource()}');
    }
  }
  return out.join('\n');
}

/// 语句体 → 语句列表（Block 或单条语句统一成列表，供 translateStmtList 递归）。
List<Statement> _bodyStmts(Statement s) => s is Block ? s.statements : [s];

/// for 语句 → JS（三段式与 for-in）：
///   - `for (var i = 0; i < n; i++)` → 一比一（循环变量登记进 localVars）；
///   - `for (var x in list)` → `for (var x of list)`（Dart 可迭代 → JS 数组）。
/// 不可翻译返回 null（调用方出声告警）。
String? _forStatementJs(
  ForStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  WidgetExprRenderer? widgetCtx,
  int depth,
  bool returnsWidget,
) {
  final parts = s.forLoopParts;
  String? header;
  if (parts is ForEachPartsWithDeclaration) {
    // for-in 声明式：`for (var x in list)` → `for (var x of list)`。
    final name = parts.loopVariable.name.lexeme;
    scope.localVars.add(name);
    final it = exprToJs(parts.iterable, scope, classes);
    if (it == null) return null;
    header = 'for (let $name of $it)';
  } else if (parts is ForEachPartsWithIdentifier) {
    // for-in 复用已有变量：`for (x in list)` → `for (x of list)`。
    final it = exprToJs(parts.iterable, scope, classes);
    if (it == null) return null;
    header = 'for (${parts.identifier.name} of $it)';
  } else if (parts is ForParts) {
    // 三段式：`for (var i = 0; i < n; i++)` → 一比一。
    final inits = <String>[];
    if (parts is ForPartsWithDeclarations) {
      for (final v in parts.variables.variables) {
        final name = v.name.lexeme;
        scope.localVars.add(name);
        if (v.initializer == null) {
          inits.add('let $name');
          continue;
        }
        final rhs = rhsToJs(v.initializer!, scope, classes);
        if (rhs == null) return null;
        inits.add('let $name = $rhs');
      }
    } else if (parts is ForPartsWithExpression) {
      final init = parts.initialization;
      if (init != null) {
        final t = exprToJs(init, scope, classes);
        if (t == null) return null;
        inits.add(t);
      }
    } else {
      return null; // ForPartsWithPattern：Dart 3 模式 for 头
    }
    String? condJs;
    if (parts.condition != null) {
      condJs = exprToJs(parts.condition!, scope, classes);
      if (condJs == null) return null;
    }
    final upds = <String>[];
    for (final u in parts.updaters) {
      final t = exprToJs(u, scope, classes);
      if (t == null) return null;
      upds.add(t);
    }
    header = 'for (${inits.join(', ')}; ${condJs ?? ''}; ${upds.join(', ')})';
  } else {
    return null;
  }
  final ind = '  ' * depth;
  final bodyJs = translateStmtList(_bodyStmts(s.body), scope, classes, widgetCtx,
      depth: depth + 1, returnsWidget: returnsWidget);
  return '$ind$header {\n$bodyJs\n$ind}';
}

/// `try { ... } catch (e) { ... } finally { ... }` → JS 同构。
///
/// 当前支持范围（基础功能）：
///   - 无 `on` 类型的 `catch (e)` / `catch (e, s)`：完整翻译；`s` 绑定
///     `e.stack`（JS 没有独立的 StackTrace 对象）；
///   - `finally`：完整翻译；
///   - 带 `on Type` 或多个 catch 子句：按 catch-all 近似，并输出构建期告警
///     （不做类型过滤，避免没有类型解析时误判）。
///
/// 返回 null 表示结构非法（既无 catch 也无 finally），由调用方告警。
String? _tryStatementJs(
  TryStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  WidgetExprRenderer? widgetCtx,
  int depth,
  bool returnsWidget,
) {
  final ind = '  ' * depth;
  final catches = s.catchClauses;
  final finallyBlock = s.finallyBlock;
  if (catches.isEmpty && finallyBlock == null) return null;

  final bodyJs = translateStmtList(
    s.body.statements,
    scope,
    classes,
    widgetCtx,
    depth: depth + 1,
    returnsWidget: returnsWidget,
  );

  var catchPart = '';
  if (catches.isNotEmpty) {
    final clause = catches.first;
    if (catches.length > 1) {
      log.warning('[hot_patch_generator] try 含 ${catches.length} 个 catch '
          '子句，当前只翻译第一个，其余已跳过：${s.toSource()}');
    }
    if (clause.exceptionType != null) {
      log.warning('[hot_patch_generator] catch 的 on 类型过滤尚未实现，'
          '已按 catch-all 翻译：${clause.exceptionType!.toSource()}');
    }
    final exName = clause.exceptionParameter?.name.lexeme ?? '__error';
    final stackName = clause.stackTraceParameter?.name.lexeme;
    final catchScope = stackName == null
        ? scope.withParams([exName])
        : scope.withParams([exName, stackName]);
    var catchBody = translateStmtList(
      clause.body.statements,
      catchScope,
      classes,
      widgetCtx,
      depth: depth + 1,
      returnsWidget: returnsWidget,
    );
    if (stackName != null) {
      catchBody =
          '$ind  var $stackName = $exName && $exName.stack;\n$catchBody';
    }
    catchPart = ' catch ($exName) {\n$catchBody\n$ind}';
  }

  var finallyPart = '';
  if (finallyBlock != null) {
    final finBody = translateStmtList(
      finallyBlock.statements,
      scope,
      classes,
      widgetCtx,
      depth: depth + 1,
      returnsWidget: returnsWidget,
    );
    finallyPart = ' finally {\n$finBody\n$ind}';
  }

  return '${ind}try {\n$bodyJs\n$ind}$catchPart$finallyPart';
}

/// switch 语句 → JS switch。仅支持常量 case（analyzer 把常量 case 也解析为
/// SwitchPatternCase(ConstantPattern)）与 default：
///   - Dart 无贯穿语义：非空 case 体若不以 return / break / continue / throw
///     收尾，自动补 `break;`（空 case 体是显式贯穿，JS 天然同形）；
///   - guard / 解构 / 关系 / 逻辑或等模式、带 label 的 case 暂不支持，
///     返回 null 整体丢弃（调用方出声告警），避免产出半翻译的 switch。
String? _switchStatementJs(
  SwitchStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  WidgetExprRenderer? widgetCtx,
  int depth,
  bool returnsWidget,
) {
  final subj = exprToJs(s.expression, scope, classes);
  if (subj == null) return null;
  final ind = '  ' * depth;
  final caseInd = '  ' * (depth + 1);
  final lines = <String>['$ind' 'switch ($subj) {'];
  for (final member in s.members) {
    if (member.labels.isNotEmpty) return null; // 带标签的 break/continue 不支持
    String? label;
    if (member is SwitchDefault) {
      label = 'default:';
    } else if (member is SwitchPatternCase) {
      // Dart 3 解析形态：常量 case 也是 SwitchPatternCase(ConstantPattern)
      //（实测 analyzer 7 对 switch 语句不再产出旧 SwitchCase）。
      if (member.guardedPattern.whenClause != null) return null;
      final p = member.guardedPattern.pattern;
      if (p is WildcardPattern) {
        label = 'default:'; // `case _:` 等价 default
      } else if (p is ConstantPattern) {
        final v = exprToJs(p.expression, scope, classes);
        if (v == null) return null;
        label = 'case $v:';
      } else {
        return null; // 解构 / 关系 / 逻辑或等模式
      }
    } else if (member is SwitchCase) {
      // 旧解析形态兜底（常量 case 直接挂在 SwitchCase.expression 上）。
      final v = exprToJs(member.expression, scope, classes);
      if (v == null) return null;
      label = 'case $v:';
    } else {
      return null;
    }
    lines.add('$caseInd$label');
    for (final st in member.statements) {
      final js = translateStmtList([st], scope, classes, widgetCtx,
          depth: depth + 2, returnsWidget: returnsWidget);
      if (js.isEmpty) return null; // 某条语句翻译失败 → 整个 switch 丢弃
      lines.add(js);
    }
    if (member.statements.isNotEmpty) {
      final last = member.statements.last;
      final terminated = last is ReturnStatement ||
          last is BreakStatement ||
          last is ContinueStatement ||
          (last is ExpressionStatement && last.expression is ThrowExpression);
      if (!terminated) lines.add('$caseInd' 'break;');
    }
  }
  lines.add('$ind}');
  return lines.join('\n');
}

/// switch 表达式（Dart 3）→ JS IIFE：
///   `switch (x) { 0 => '零', _ => '多' }` →
///   `(() => { switch (x) { case 0: return "零"; default: return "多"; } })()`
/// 仅支持常量模式与 `_`（guard / 解构 / 关系 / 逻辑或模式返回 null，调用方
/// 出声告警）。case 值走普通表达式翻译，不支持返回 widget 的 case（widget
/// 渲染路径只认 return 语句/表达式位置的构造调用）。
String? _switchExpressionJs(
  SwitchExpression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final subj = exprToJs(e.expression, scope, classes);
  if (subj == null) return null;
  final arms = <String>[];
  for (final c in e.cases) {
    if (c.guardedPattern.whenClause != null) return null;
    final p = c.guardedPattern.pattern;
    String? label;
    if (p is WildcardPattern) {
      label = 'default:';
    } else if (p is ConstantPattern) {
      final v = exprToJs(p.expression, scope, classes);
      if (v == null) return null;
      label = 'case $v:';
    } else {
      return null;
    }
    final v = rhsToJs(c.expression, scope, classes);
    if (v == null) return null;
    arms.add('    $label return $v;');
  }
  if (arms.isEmpty) return null;
  return '(() => { switch ($subj) {\n${arms.join('\n')}\n} })()';
}

/// 一条表达式语句 → JS：`setState(...)` 展开为 `this.setState(() => {...})`，
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

/// `setState(() => _x++)` → `this.setState(() => { this._x += 1; });`
/// （回调体逐语句翻译，与 Dart 原封同构）。
///
/// 回调**必须是箭头函数**（与 [closureToJs] 的口径一致）：`this` 词法绑定到
/// 定义该回调的组件方法，也就是组件实例，正是 Dart 闭包捕获 `this` 的语义。
/// 若产出 `function(){}`，回调里的 `this` 就取决于调用方是否 `.call(this)`——
/// 运行时 `setState` 恰好会 `.call(this)` 兜住，但这是一层**隐式约定**：任何
/// 不走该入口的调用路径（被抽成实例方法后由宿主按别的形式调用等）都会让回调
/// 里的 `this._x` 变成 undefined，表现为「状态静默不更新」。
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
  // 回调体保持内联（`() => { ... }`），把多行折回单行。
  inner = inner.replaceAll('\n', ' ');
  return inner.isEmpty
      ? 'this.setState(() => {});'
      : 'this.setState(() => { $inner });';
}

/// 翻译一个类的方法体 → JS。**组件与普通类共用这一条**：字段表 = 类自身实例
/// 字段，返回 widget 的表达式走 widget 层渲染（与 build 无差别）。
///
/// [ClassMethod.nativeChannel] 非空（如 SnackBar → `nativeToast`）时整体译为
/// 宿主通道调用，不再走普通语句翻译。
String translateClassMethodBody(
  ClassInfo info,
  ClassMethod m,
  Map<String, ClassInfo> classes, {
  Map<String, Map<String, String>> hostMethods = const {},
  WidgetExprRenderer? widgetCtx,
  Set<String> globalConsts = const {},
  int depth = 2,
}) {
  final ind = '  ' * depth;
  final channel = m.nativeChannel;
  if (channel != null) {
    return '$ind'
        '_app_host_.invoke(${jsString(channel)}, '
        '{ message: ${m.nativeMessage ?? '""'} });';
  }
  final scope = FieldScope(
    instanceFields: info.instanceFieldNames,
    params: m.params.toSet(),
    methods: {
      ...info.methodNames,
      if (sdkBaseName(info) != null) 'notifyListeners',
    },
    hostMethods: hostMethods,
    globalConsts: globalConsts,
    superMap: m.superMap,
  );
  // 方法形参同步登记进 widget 层（方法体期间），使返回的 widget 树里
  // `Text(title)` 这类形参引用可解析；翻译结束即恢复，不污染同类其它方法。
  String run() => translateMethodBody(
        m.body,
        scope,
        classes,
        widgetCtx: widgetCtx,
        returnExpressionBody: !m.isVoid,
        returnsWidget: m.returnsWidget,
        depth: depth,
      );
  if (widgetCtx == null || m.params.isEmpty) return run();
  return widgetCtx.withMethodParams(m.params, run);
}

/// 是否为「widget 构造表达式」：`Text(...)` / `new Text(...)`。
///
/// [parseString] 只做语法解析（无符号解析），无 `new` 的类构造在 AST 上是
/// [MethodInvocation]（target 为 null），因此不能只认 [InstanceCreationExpression]。
/// 带 target 的调用（`this.x()` / `a.b()`）不是构造，返回 false。
bool _isWidgetCtorExpr(Expression e) =>
    e is InstanceCreationExpression ||
    (e is MethodInvocation && e.target == null);

/// 把一个 Widget 构造表达式（如 `Container(...)`）通过 [WidgetExprRenderer]
/// （widget2js 层的 WidgetTranslateContext）翻译成 JS 构造调用字符串。
/// 失败返回 null（回退到普通表达式翻译），并出声告警（不静默丢代码）。
///
/// [depth]：该表达式所在语句的缩进深度，widget 树的子节点按此对齐缩进。
String? _widgetExprToJs(WidgetExprRenderer? widgetCtx, Expression e, int depth) {
  if (widgetCtx == null) return null;
  try {
    // translate(Expression) → JSON Map / String；renderJs(json, depth) → JS
    return widgetCtx.renderJs(widgetCtx.translate(e), depth);
  } catch (err) {
    log.warning('[hot_patch_generator] widget 表达式无法翻译，已在 JS 产物中'
        '丢弃：${e.toSource()}（$err）');
    return null;
  }
}
