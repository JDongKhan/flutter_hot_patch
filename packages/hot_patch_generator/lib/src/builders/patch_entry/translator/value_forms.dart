/// 值形态分派：把 widget 构造**实参的值**按表达式形态翻译成产物值。
///
/// 这是「统一翻译」的核心：判断依据是**值的类型/形态**（字面量 / 构造 /
/// 静态工厂 / 常量引用 / 列表 / 闭包 / 表达式），而**不是 widget 类型**。
/// 因此新增组件（含未识别的自定义 / 三方组件）零配置即可翻译，不需要为
/// 每种 widget 写一个翻译类。
///
/// 约定：
///   - 转换函数一律「翻译不出来返回 null」，由调用方过滤掉该键——运行时
///     （`js_widget_registry`）逐具名键取值，多余的键与缺失的键都是宽容的。
library;

import 'package:analyzer/dart/ast/ast.dart';

import '../../shared/ctor_signatures.dart';
import 'element2js.dart';

/// 去掉空值键（保序）：Dart `null` 与字符串 `'null'`（[TreeShape] 对 NullLiteral
/// 的产出）都算空。
///
/// 必须做：产物渲染把 Dart `null` 输出成裸 `null`（`element2js.dart` 的
/// `jsLiteral`），值为 null 的键会让渲染层把该键当成「实参缺省」处理。
Map<String, dynamic> nonNull(Map<String, Object?> raw) => {
      for (final e in raw.entries)
        if (e.value != null && e.value != 'null') e.key: e.value,
    };

/// 按值形态翻译一个实参值；翻译不出来返回 null（由 [nonNull] 丢弃该键）。
///
/// 分派顺序（形态判断，与 widget 类型无关）：
///   1. `NullLiteral` → 丢键；
///   2. 构造 / 静态工厂 → 构造统一翻译（`new X({...})` / `X.b({...})`），
///      值类由运行时同名类承接（翻译层不做「哪些类型要转成 JSON」的判别）；
///   3. 常量引用（`Owner.name`）→ 普通类原样引用 / enum 转成员名字符串；
///   4. `ListLiteral` → 元素列表（逐项交给调用方的结点翻译）；
///   5. 其余 → 表达式直通（[ElementTranslateContext.jsDataExpr]）。
Object? autoValue(Expression e, ElementTranslateContext ctx, {String? name}) {
  if (e is NullLiteral) return null;

  // sliver 子结点提供者：按**构造类型**识别（与参数名无关）。
  //   - `SliverChildListDelegate([...])` → 元素数组；
  //   - `SliverChildBuilderDelegate((c, i) => ..., childCount: n)` → 方法名 + 计数。
  // 产物不是元素（没有 `element: true` 标记），由元素工厂归入 children。
  final delegate = _delegateValue(e, ctx);
  if (delegate != null) return delegate;

  // 条件表达式：先按标量翻译；分支是 widget / widget 列表时改走元素翻译，
  // 产物是运行时求值的 JS 三元（`flag ? __h(...) : null`）。
  if (e is ConditionalExpression) {
    final cond = _jsExprOrNull(e.condition, ctx);
    if (cond == null) return null;
    final a = _branchJs(e.thenExpression, ctx);
    final b = _branchJs(e.elseExpression, ctx);
    if (a == null || b == null) return null;
    return '$cond ? $a : $b';
  }

  // 闭包：按**通用参数名约定**区分语义（约定与 widget 类型无关）——
  //   `builder` / `xxxBuilder`（返回 widget 的回调，如 ListView.builder 的
  //     itemBuilder、Builder 的 builder）→ 抽成组件方法，props 值 = 方法名，
  //     运行时按名调用；
  //   其余闭包（返回**值**，如 provider 的 `create: (_) => _modelA`）→
  //     内联闭包体的 JS 表达式；闭包体是**类构造**（`(_) => MyModel()`）时
  //     下发类引用（见 [_classRefOf]），由运行时决定何时 new 一次。
  if (e is FunctionExpression) {
    if (isBuilderArg(name)) {
      return builderClosureJs(ctx, e);
    }
    final body = e.body;
    if (body is ExpressionFunctionBody) {
      // 闭包体是**类构造**（`create: (_) => CounterVm()`）→ 下发**类引用**
      // （裸类名）：运行时按「可调用工厂」语义决定何时 `new` 一次
      // （provider 的 create 按 `typeof` 分流：类引用 → 构造并持有生命周期）。
      // 内联成 `new CounterVm()` 会退化成「每次 build 都新建一个实例」，
      // 语义与 Dart 的惰性创建不一致。
      final classRef = _classRefOf(body.expression, ctx);
      if (classRef != null) return classRef;
      return _jsExprOrNull(body.expression, ctx);
    }
    return null;
  }

  // 方法 tear-off / 回调透传：`resetFilter: _resetFilter`、
  // `toggleFilter: widget.toggleFilter`。Dart 里 tear-off 自带接收者；JS 裸
  // 方法引用会在子组件调用时丢 this（表现为：点遮罩调到的 toggleFilter 实际
  // 绑在子组件上，父级 `_filterOpen` 不变、弹框关不掉）。必须生成绑定闭包。
  if (e is Identifier) {
    final fn = ctx.functionJs(e);
    if (fn != null) return fn;
  }

  final (ctor, _) = ctx.ctorOf(e);
  if (ctor != null && !ctx.isConstruction(e)) {
    // `X.member(...)` 不是构造（如模型的静态方法 `Spot.fromJson(e)`、SDK 静态
    // 工厂 `Overlay.of(context)`）：按普通表达式翻译，绝不走元素属性管线——
    // 否则实参会被当成属性、产物变成 `Spot.fromJson({})`（数据整段丢失）。
    return _jsExprOrNull(e, ctx);
  }
  if (ctor != null) {
    // 构造统一按**构造翻译**处理（组件 / 值对象 / 控制器同一套）：
    // 先走属性管线（builder 闭包抽成方法、集合推导展开、delegate、位置实参
    // 按源码签名映射），再渲染成 `new X({...})` / `X.b({...})`。
    // 翻译器不判断它是组件还是普通类——同名 JS 类由运行时注入或包装类承接。
    // 翻译/渲染失败 → null（该键由 [nonNull] 丢弃），绝不产出占位值。
    final node = ctx.translate(e);
    if (node == null) return null;
    return ctx.renderValueOrNull(node, 0);
  } else {
    final owner = staticRefOwner(e);
    if (owner != null) {
      // 跨文件「普通类」的静态成员引用（`MyColors.background`）：产物已 import
      // 该类的 JS 模块，裸引用即可解析。
      // 其余 `Owner.name`：先查源码索引——owner 是**普通类**（`Colors.red` /
      // 静态常量类）时按 1:1 原样引用（运行时同名类 / 产物 import）；
      // 是 **enum** 时 Dart 枚举在 JS 侧没有等价物，产物协议用**成员名字符串**
      // 表示（运行时各 `xxxFromJson` 按名还原，如
      // `BottomNavigationBarType.fixed` → `"fixed"`）。
      final member = staticMemberOf(e);
      if (member != null && isClassName(owner) && !member.startsWith('_')) {
        final sigs = CtorSignatures.instance;
        // 项目普通类（含纯 static 类）：JS 侧是真实 class，静态成员挂在类上，
        // `Owner.member` 原样引用即可（产物已 import 该类的模块）。
        // 其余能确认是 class 的（源码索引），同样原样引用；
        // 只有 enum 走成员名字符串（JS 侧无枚举等价物）。
        final isProjectClass = ctx.isProjectClass(owner);
        if (isProjectClass ||
            (sigs != null && sigs.isClass(owner) && !sigs.isEnum(owner))) {
          return _jsExprOrNull(e, ctx);
        }
        return ctx.jsString(member);
      }
    }
  }

  // 列表字面量（`providers: [...]` / `actions: [...]` / `children: [...]`）：
  // 元素与任意值位置的构造**同一套语法翻译**（`new X({...})`）——翻译层不区分
  // widget 与普通类：宿主包装类的构造内部再 `return __h('X', props)`，值类
  // （`TextSpan` / `Duration` …）则保持普通对象。仅 if/for/spread 这类集合
  // 语法仍走元素数组展开（`...(cond ? [a] : [b])`）。
  if (e is ListLiteral) {
    final items = <Object?>[];
    for (final el in e.elements) {
      if (el is Expression) {
        // 单值翻译/渲染失败 → 该项不产出（不塞 null / 占位值占位）。
        final node = ctx.translate(el);
        if (node == null) continue;
        final js = ctx.renderValueOrNull(node, 0);
        if (js != null) items.add(js);
      } else {
        final t = ctx.translateElement(el);
        if (t != null) items.add(t);
      }
    }
    return items;
  }

  return _jsExprOrNull(e, ctx);
}

/// 表达式是「类构造」（`CounterVm()` / `CounterVm(5)`）→ 返回该类名（JS 裸引用，
/// 产物会 import 该类的模块）；不是类构造返回 null。
///
/// 用于「惰性工厂」值（provider 的 `create: (_) => MyModel()`）：产物要下发
/// 类引用而不是实例。构造里的实参不下发（运行时按默认构造）——与旧口径一致。
String? _classRefOf(Expression expr, ElementTranslateContext ctx) {
  final (ctor, _) = ctx.ctorOf(expr);
  if (ctor == null || !isClassName(ctor)) return null;
  // 登记依赖：确保该类（跨文件模型类）被翻译并 import 进本产物。
  ctx.collectDependency(ctor);
  return ctor;
}

/// sliver 子结点提供者：按**构造类型**识别，与实参名无关。
///
/// 产物形态（均不带 `element: true`，由 `__h` 归入 children 对象）：
///   - `{__delegate: 'list', children: [元素…]}`；
///   - `{__delegate: 'builder', builder: '<方法名>', childCount: <jsExpr>}`。
///
/// 两种都不匹配 → null（调用方按普通值形态继续翻译）。
Object? _delegateValue(Expression e, ElementTranslateContext ctx) {
  final (ctor, args) = ctx.ctorOf(e);

  if (ctor == 'SliverChildListDelegate') {
    final first = ctx.nonNamedArg(args);
    if (first is ListLiteral) {
      final children = <Object?>[];
      for (final el in first.elements) {
        final t = ctx.translateElement(el);
        if (t != null) children.add(t);
      }
      return {
        '__delegate': ctx.jsString('list'),
        'children': children,
      };
    }
    return null;
  }

  if (ctor == 'SliverChildBuilderDelegate') {
    final builderRaw = ctx.namedArg(args, 'builder') ?? ctx.nonNamedArg(args);
    final childCount = ctx.namedArg(args, 'childCount');
    if (builderRaw is! FunctionExpression || childCount == null) return null;
    final builderJs = builderClosureJs(ctx, builderRaw);
    if (builderJs == null) return null;
    return {
      '__delegate': ctx.jsString('builder'),
      'builder': builderJs,
      'childCount': ctx.jsDataExpr(childCount),
    };
  }

  return null;
}

/// 条件表达式单个分支 → JS 源码：widget 构造走元素渲染，列表逐项渲染，
/// 其余按标量直通。渲染不出来返回 null。
String? _branchJs(Expression e, ElementTranslateContext ctx) {
  if (e is NullLiteral) return 'null';
  if (e is ListLiteral) {
    final items = <String>[];
    for (final el in e.elements) {
      final v = ctx.translateElement(el);
      if (v == null) continue;
      final js = v is String ? v : ctx.renderJs(v, 0);
      if (js != null) items.add(js);
    }
    return '[${items.join(', ')}]';
  }
  // 其余分支与普通值同一条分派：构造 → `new X({...})`（组件由包装类产出元素），
  // 标量 / 枚举 / 常量引用 → 表达式。嵌套三目在 autoValue 里递归展开。
  final v = autoValue(e, ctx);
  if (v == null) return null;
  if (v is String) return v;
  // 结构化值（`EdgeInsets.only(...)` / `BorderRadius.zero` 等转成的 JSON 形态）
  // 在 props 里不能是 Map——props 的叶子只接受 JS 表达式字符串，Map 会在三目
  // 里被判为「不可翻译」整键丢弃（SafeArea.minimum 就是这样丢的）。这里把
  // 该 JSON 直接排成对象字面量：String 叶子本就是 JS 表达式（数字 / `this._x`
  // / 已带引号的字符串），原样嵌入。
  if (v is Map || v is List) return _valueSourceOf(v);
  return v.toString();
}

/// 结构化值 → JS 源码（Map → 对象字面量、List → 数组、String 叶子原样）。
String _valueSourceOf(Object? v) {
  if (v is Map) {
    if (v.isEmpty) return '{}';
    final entries = v.entries.map((e) => '"${e.key}": ${_valueSourceOf(e.value)}');
    return '{${entries.join(', ')}}';
  }
  if (v is List) {
    return '[${v.map(_valueSourceOf).join(', ')}]';
  }
  return v?.toString() ?? 'null';
}

/// 参数名是否是「builder 语义」的闭包（返回 widget 的回调）：`builder` /
/// `itemBuilder` / `separatorBuilder` / `pageBuilder` …
///
/// 这是**语言级翻译协议**（Flutter 全生态一致的命名约定），不是某个组件的
/// 特判：生成器只有语法树、没有类型解析，无法从闭包签名可靠判断返回类型，
/// 因此以命名约定区分「返回 widget 的回调」与「返回值/工厂的闭包」。所有
/// 组件（内建、自定义、三方）共用这一条规则，新增组件无需登记。
bool isBuilderArg(String? name) =>
    name != null && (name == 'builder' || name.endsWith('Builder'));

/// `Owner.name` 形态的 owner 名（`Colors.red` → `'Colors'`）；否则 null。
String? staticRefOwner(Expression e) {
  if (e is PrefixedIdentifier) return e.prefix.name;
  if (e is PropertyAccess && e.target is SimpleIdentifier) {
    return (e.target! as SimpleIdentifier).name;
  }
  return null;
}

/// `Owner.name` 形态的成员名（`Colors.red` → `'red'`）；否则 null。
String? staticMemberOf(Expression e) {
  if (e is PrefixedIdentifier) return e.identifier.name;
  if (e is PropertyAccess && e.target is SimpleIdentifier) {
    return e.propertyName.name;
  }
  return null;
}

/// 表达式直通；翻译失败或得到 `'null'` 都算「没有值」。
String? _jsExprOrNull(Expression e, ElementTranslateContext ctx) {
  try {
    final js = ctx.jsDataExpr(e);
    return js == 'null' ? null : js;
  } catch (_) {
    return null;
  }
}

/// builder 闭包 → **内联箭头闭包**（builder 协议唯一的形态）。
///
/// 不再「抽成实例方法 + 下发方法名」：方法名形态覆盖不了 `itemBuilder:
/// widget.builder` 这类来自**字段/变量**的函数，而闭包能覆盖全部来源（方法
/// tear-off 已在 [autoValue] 里包成绑定闭包）。产物里 builder 一律是函数，
/// 运行时直接调用；函数永不进宿主 props（由代理类摘除）。
///
/// - 形参：按名保留（context / index / 其余如 AnimatedList 的 `animation`），
///   并全部登记为 builder 局部名；
/// - 箭头体：表达式即子树；
/// - 块体：局部变量声明作为闭包前置语句，`return` 的表达式作子树。
String? builderClosureJs(
  ElementTranslateContext ctx,
  FunctionExpression builder,
) {
  final params = builder.parameters?.parameters ?? const <FormalParameter>[];
  if (params.isEmpty) return null;
  String nameAt(int i) {
    final n = params[i].name?.lexeme;
    if (n != null && n != '_') return n;
    return switch (i) {
      0 => 'context',
      1 => 'index',
      _ => 'arg$i',
    };
  }

  final names = [for (var i = 0; i < params.length; i++) nameAt(i)];
  for (final n in names) {
    ctx.addBuilderLocal(n);
  }
  Expression? retExpr;
  final preludes = <String>[];
  final body = builder.body;
  if (body is ExpressionFunctionBody) {
    retExpr = body.expression;
  } else if (body is BlockFunctionBody) {
    for (final st in body.block.statements) {
      if (st is ReturnStatement) {
        retExpr = st.expression;
        continue;
      }
      if (st is VariableDeclarationStatement) {
        for (final v in st.variables.variables) {
          ctx.addBuilderLocal(v.name.lexeme);
          final init = v.initializer;
          if (init == null) {
            preludes.add('var ${v.name.lexeme};');
            continue;
          }
          // `final model = context.watch<MyModel>()`：只登记为 builder 局部名。
          // 子树里若出现 `() => model.inc()`，事件句柄会因「引用了构建期局部名」
          // 改走**构建期闭包**，闭包与本闭包同作用域、直接捕获 `model`。
          ctx.warnCapturedLocals(init);
          preludes.add('var ${v.name.lexeme} = ${ctx.jsDataExpr(init)};');
        }
        continue;
      }
      // 其余语句（`if` / `for` / 多分支 `return` …）无法内联进「前置声明 + 单一
      // return」的形态：交给通用闭包翻译（语句级翻译 + 树里的 return 按组件渲染），
      // 与类方法体同一套语句翻译器，能力自动对齐。
      return ctx.functionJs(builder);
    }
  }
  if (retExpr == null) return null;
  ctx.warnCapturedLocals(retExpr);
  // 子树翻译/渲染失败 → 整个 builder 闭包不产出（调用方丢该键），绝不产出
  // `() => null` 之类的假闭包——那会让运行时以为拿到了 builder，实际每次
  // 调用返回空元素（与 SizedBox 占位同一类静默错误）。
  final node = ctx.translate(retExpr);
  if (node == null) return null;
  final js = ctx.renderJs(node, 0);
  if (js == null) return null;
  final head = '(${names.join(', ')})';
  if (body is ExpressionFunctionBody) return '$head => $js';
  return '$head => {\n${preludes.map((p) => '  $p\n').join()}  return $js;\n}';
}

