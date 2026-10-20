/// 值形态分派：把 widget 构造**实参的值**按表达式形态翻译成产物值。
///
/// 这是「统一翻译」的核心：判断依据是**值的类型/形态**（字面量 / 构造 /
/// 静态工厂 / 常量引用 / 列表 / 闭包 / 表达式），而**不是 widget 类型**。
/// 因此新增组件（含未识别的自定义 / 三方组件）零配置即可翻译，不需要为
/// 每种 widget 写一个翻译类。
///
/// 约定：
///   - 转换函数一律「翻译不出来返回 null」，由调用方过滤掉该键——运行时
///     （`js_widget_registry`）逐具名键取值，多余的键与缺失的键都是宽容的；
///   - 但**不允许静默**：真正结构化、看起来该被翻译的值翻译不出来时出声
///     （见 [_warnUnsupported]），便于补齐分派表。
library;

import 'package:analyzer/dart/ast/ast.dart';

import 'style_translators.dart';
import 'widget2js.dart';

/// 值形态转换器：`值表达式 + 上下文` → 产物值（JS 表达式字符串 / JSON map）。
typedef ValueConverter = Object? Function(Expression e, WidgetTranslateContext ctx);

/// 去掉空值键（保序）：Dart `null` 与字符串 `'null'`（[TreeShape] 对 NullLiteral
/// 的产出）都算空。
///
/// 必须做：产物渲染把 Dart `null` 输出成裸 `null`（`widget2js.dart` 的
/// `jsLiteral`），且 `usesJsClass` 用 `props.containsKey('builder')` 判定结点
/// 形态——一个「值为 null 的 builder 键」会让结点从类引用 `__h(ListView,…)`
/// 变成字符串 `__h('ListView',…)`。
Map<String, dynamic> nonNull(Map<String, Object?> raw) => {
      for (final e in raw.entries)
        if (e.value != null && e.value != 'null') e.key: e.value,
    };

/// 构造 / 静态工厂名 → 结构化样式转换器。
///
/// 键是**类型名**：`ctx.ctorOf` 把 `EdgeInsets.all(8)`（命名构造 / 静态工厂）
/// 与 `const EdgeInsets(...)`（直接构造）都归一成 `'EdgeInsets'`；命名构造的
/// 细节（all / symmetric / only / circular / all / fromLTRB）由各转换函数内部处理。
final Map<String, ValueConverter> _ctorConverters = {
  // 内边距 / 尺寸 / 约束
  'EdgeInsets': (e, c) => edgeInsetsToJson(e, c),
  'BoxConstraints': (e, c) => boxConstraintsToJson(e, c),
  'Offset': (e, c) => offsetExprToJson(e),
  // 装饰
  'BoxDecoration': (e, c) => boxDecorationToJson(e, c),
  'Border': (e, c) => borderToJson(e, c),
  'BorderSide': (e, c) => borderSideToJson(e, c),
  'BorderRadius': (e, c) => borderRadiusToJson(e, c),
  'BoxShadow': (e, c) => boxShadowToJson(e, c),
  'LinearGradient': (e, c) => gradientToJson(e, c),
  'RadialGradient': (e, c) => gradientToJson(e, c),
  'SweepGradient': (e, c) => gradientToJson(e, c),
  'DecorationImage': (e, c) => decorationImageToJson(e, c),
  // 形状
  'RoundedRectangleBorder': (e, c) => shapeToJson(e, c),
  'CircleBorder': (e, c) => shapeToJson(e, c),
  'StadiumBorder': (e, c) => shapeToJson(e, c),
  'BeveledRectangleBorder': (e, c) => shapeToJson(e, c),
  'ContinuousRectangleBorder': (e, c) => shapeToJson(e, c),
  // 文本 / 按钮样式
  'TextStyle': (e, c) => textStyleToJson(e, c),
  'ButtonStyle': (e, c) => buttonStyleToJson(e, c),
  'TextScaler': (e, c) => textScalerToJson(e),
  // 网格代理（`gridDelegate:` 的值形态）→ JSON 值，运行时读 crossAxisCount /
  // maxCrossAxisExtent；不转就会变成结点，网格退化成单列。
  'SliverGridDelegateWithFixedCrossAxisCount': (e, c) =>
      gridDelegateToJson(e, c),
  'SliverGridDelegateWithMaxCrossAxisExtent': (e, c) =>
      gridDelegateToJson(e, c),
  // 颜色：`Color(0xFF...)` / `Color.fromARGB(...)` → '#rrggbb'。
  // 必须走结构化转换：否则会落进「类名构造 → 子结点」分支，产物变成
  // `__h('Color', …)` 结点，运行时 `colorFromJson` 只认字符串 → 颜色整条丢失。
  'Color': (e, c) => colorToJson(e, c),
  // 滚动物理（含子类构造，如 `NeverScrollableScrollPhysics()`）
  'NeverScrollableScrollPhysics': (e, c) => scrollPhysicsToJson(e),
  'AlwaysScrollableScrollPhysics': (e, c) => scrollPhysicsToJson(e),
  'BouncingScrollPhysics': (e, c) => scrollPhysicsToJson(e),
  'ClampingScrollPhysics': (e, c) => scrollPhysicsToJson(e),
  // 图片源（`AssetImage('x')` / `NetworkImage('url')`）
  'AssetImage': (e, c) => imageSourceToJson(e, c),
  'NetworkImage': (e, c) => imageSourceToJson(e, c),
};

/// 常量引用 owner 名 → 转换器（枚举 / 颜色 / 图标 / 零值常量）。
///
/// 键是 `Owner.name` 里的 `Owner`（`Colors.red` → `'Colors'`）。
final Map<String, ValueConverter> _constRefConverters = {
  // 颜色 / 图标
  'Colors': (e, c) => colorToJson(e, c),
  'Color': (e, c) => colorToJson(e, c),
  'Icons': (e, c) => iconDataToJson(e),
  // 对齐 / 布局枚举
  'Alignment': (e, c) => alignmentToJson(e, c),
  'AlignmentDirectional': (e, c) => _enum(e, c, 'AlignmentDirectional'),
  'MainAxisAlignment': (e, c) => mainAxisAlignmentToJson(e),
  'CrossAxisAlignment': (e, c) => crossAxisAlignmentToJson(e),
  'MainAxisSize': (e, c) => mainAxisSizeToJson(e),
  'Axis': (e, c) => axisToJson(e),
  'WrapAlignment': (e, c) => wrapAlignmentToJson(e),
  'WrapCrossAlignment': (e, c) => wrapCrossAlignmentToJson(e),
  'StackFit': (e, c) => stackFitToJson(e),
  // 视觉 / 交互枚举
  'BoxFit': (e, c) => boxFitToJson(e),
  'Clip': (e, c) => clipBehaviorToJson(e),
  'HitTestBehavior': (e, c) => hitTestBehaviorToJson(e),
  'ImageRepeat': (e, c) => imageRepeatToJson(e),
  'BlendMode': (e, c) => blendModeToJson(e),
  'ScrollPhysics': (e, c) => scrollPhysicsToJson(e),
  // 文本枚举 / 样式枚举
  'TextOverflow': (e, c) => _enum(e, c, 'TextOverflow'),
  'TextAlign': (e, c) => _enum(e, c, 'TextAlign'),
  'TextDirection': (e, c) => _enum(e, c, 'TextDirection'),
  'TextDecoration': (e, c) => _enum(e, c, 'TextDecoration'),
  'TextInputType': (e, c) => textInputTypeToJson(e),
  'BorderStyle': (e, c) => _enum(e, c, 'BorderStyle'),
  'FontWeight': (e, c) => _enum(e, c, 'FontWeight'),
  'FontStyle': (e, c) => _enum(e, c, 'FontStyle'),
  // 导航 / Tab 枚举
  'TabBarIndicatorSize': (e, c) => tabBarIndicatorSizeToJson(e),
  'TabAlignment': (e, c) => tabAlignmentToJson(e),
  // 零值常量（结构化，运行时按同一套 fromJson 还原）
  'EdgeInsets': (e, c) => _zeroInsets(e, c, r'EdgeInsets.zero'),
  'BorderRadius': (e, c) => _zeroRadius(e, c, r'BorderRadius.zero'),
};

/// 枚举 / 常量引用的兜底：`Owner.value` 里 owner 与 name 都匹配才产出（带引号）。
Object? _enum(Expression e, WidgetTranslateContext c, String owner) {
  final name = enumName(e, owner);
  return name == null ? null : c.jsString(name);
}

/// `EdgeInsets.zero` → `{left/top/right/bottom: '0'}`（与 [edgeInsetsToJson] 同格式）。
Object? _zeroInsets(Expression e, WidgetTranslateContext c, String source) {
  if (e.toSource() != source) return null;
  return {
    'left': '0',
    'top': '0',
    'right': '0',
    'bottom': '0',
  };
}

/// `BorderRadius.zero` → `{radius: '0'}`（与 [borderRadiusToJson] 统一圆角同格式）。
Object? _zeroRadius(Expression e, WidgetTranslateContext c, String source) {
  if (e.toSource() != source) return null;
  return {'radius': '0'};
}

/// 按值形态翻译一个实参值；翻译不出来返回 null（由 [nonNull] 丢弃该键）。
///
/// 分派顺序（形态判断，与 widget 类型无关）：
///   1. `NullLiteral` → 丢键；
///   2. 构造 / 静态工厂（`ctorOf` 归一）→ [_ctorConverters]；
///   3. 常量引用（`Owner.name`）→ [_constRefConverters]；
///   4. `ListLiteral` → 元素列表（逐项交给调用方的结点翻译）；
///   5. 其余 → 表达式直通（[WidgetTranslateContext.jsDataExpr]）。
Object? autoValue(Expression e, WidgetTranslateContext ctx, {String? name}) {
  if (e is NullLiteral) return null;

  // 闭包：按**通用参数名约定**区分语义（约定与 widget 类型无关）——
  //   `builder` / `xxxBuilder`（返回 widget 的回调，如 ListView.builder 的
  //     itemBuilder、Builder 的 builder）→ 抽成组件方法，props 值 = 方法名，
  //     运行时按名调用；
  //   其余闭包（返回**值**，如 provider 的 `create: (_) => _modelA`）→
  //     内联闭包体的 JS 表达式；闭包体是**类构造**（`(_) => MyModel()`）时
  //     下发类引用（见 [_classRefOf]），由运行时决定何时 new 一次。
  if (e is FunctionExpression) {
    if (_isBuilderArg(name)) {
      final m = extractBuilderMethod(ctx, e, '_$name');
      return m == null ? null : ctx.jsString(m);
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

  // 静态工厂（`ElevatedButton.styleFrom(...)` 等）：按**方法名**识别——它们的
  // 构造名被归一成 receiver 类名（'ElevatedButton'），无法据此判断是样式值。
  if (e is MethodInvocation) {
    final f = _factoryConverters[e.methodName.name];
    if (f != null) {
      final r = f(e, ctx);
      if (r != null) return r;
    }
  }

  final (ctor, _) = ctx.ctorOf(e);
  if (ctor != null) {
    final conv = _ctorConverters[ctor];
    if (conv != null) {
      final r = conv(e, ctx);
      if (r != null) return r;
      // 命中了表但转换失败：多半是值的写法超出该转换函数的支持范围，出声。
      _warnUnsupported('$ctor(${e.toSource()})');
    } else if (_valueCtors.contains(ctor)) {
      // 数据对象构造（Size / Duration / Controller / Notifier…）→ 构造调用表达式。
      return _jsExprOrNull(e, ctx);
    } else if (_isClassName(ctor)) {
      // 构造名是**类名**且不属于已知值类型 → 值是**子结点**（`leading: Icon(...)`、
      // `title: Text(...)`、`sliver: SliverList(...)`、嵌套组件 `_OrderCard(...)`）
      // → 交结点翻译。是否被运行时当作结点消费由运行时决定（`propChild`）。
      return ctx.translate(e);
    }
  } else {
    final owner = staticRefOwner(e);
    if (owner != null) {
      final conv = _constRefConverters[owner];
      if (conv != null) {
        final r = conv(e, ctx);
        if (r != null) return r;
        _warnUnsupported('$e');
      }
      // 跨文件「静态单例类」的字段引用（`MyColors.background`）：产物已 import
      // 该类的 JS 模块，裸引用即可解析（与 style_translators.translateColor 同口径）。
      final singleton = ctx.singletons?.staticRef(e);
      if (singleton != null) return singleton;
      // 其余 `Owner.name`：Dart **枚举**（内建或业务自定义）在 JS 侧没有等价物，
      // 产物协议用**成员名字符串**表示（运行时各 `xxxFromJson` 按名还原，
      // 如 `BottomNavigationBarType.fixed` → `"fixed"`）。不转就是裸标识符
      // `Owner.name` → 运行时 ReferenceError，整个组件挂载失败、页面只剩
      // 「加载失败」占位。
      final member = staticMemberOf(e);
      if (member != null && _isClassName(owner) && !member.startsWith('_')) {
        return ctx.jsString(member);
      }
    }
  }

  // 列表字面量（`providers: [...]` / `actions: [...]` / `items: [...]`）：
  // 逐项翻译（元素是 widget 构造则成品结点），整体作为 props 数组下发。
  if (e is ListLiteral) {
    return [for (final el in e.elements) ctx.translateElement(el)];
  }

  return _jsExprOrNull(e, ctx);
}

/// 表达式是「类构造」（`CounterVm()` / `CounterVm(5)`）→ 返回该类名（JS 裸引用，
/// 产物会 import 该类的模块）；不是类构造返回 null。
///
/// 用于「惰性工厂」值（provider 的 `create: (_) => MyModel()`）：产物要下发
/// 类引用而不是实例。构造里的实参不下发（运行时按默认构造）——与旧口径一致。
String? _classRefOf(Expression expr, WidgetTranslateContext ctx) {
  final (ctor, _) = ctx.ctorOf(expr);
  if (ctor == null || !_isClassName(ctor)) return null;
  // 登记依赖：确保该类（跨文件模型类）被翻译并 import 进本产物。
  ctx.collectDependency(ctor);
  return ctor;
}

/// 参数名是否是「builder 语义」的闭包（返回 widget 的回调）：`builder` /
/// `itemBuilder` / `separatorBuilder` / `delegate` 等。这是通用约定，
/// 与 widget 类型无关。
bool _isBuilderArg(String? name) =>
    name != null && (name == 'builder' || name.endsWith('Builder'));

/// 静态工厂方法名 → 结构化样式转换器（`Xxx.styleFrom(...)` 这类：值是样式对象，
/// 不能按「类名构造 → 子结点」处理）。
final Map<String, ValueConverter> _factoryConverters = {
  'styleFrom': (e, c) => buttonStyleToJson(e, c),
};

/// 「数据对象」构造名：值是普通对象（原样产出构造调用表达式），不是子结点。
/// 与样式表 [_ctorConverters] 互补——表里是**结构化样式**（转 JSON 结构，
/// 运行时按 `xxxFromJson` 还原），这里是**普通对象**（JS 侧直接 `new`）。
const Set<String> _valueCtors = {
  'Size',
  'Offset',
  'Duration',
  'Radius',
  'IconData',
  'TextEditingController',
  'FocusNode',
  'ScrollController',
  'PageController',
  'TabController',
  'AnimationController',
  'ValueNotifier',
  'GlobalKey',
  'ValueKey',
  'ObjectKey',
  'UniqueKey',
};

/// 名字是否形如**类名**：跳过前导下划线后首字母大写（`Icon` / `_OrderCard`
/// 是类名；`_model` / `context` 是实例成员）。
bool _isClassName(String name) {
  var n = name;
  while (n.startsWith('_')) {
    n = n.substring(1);
  }
  return n.isNotEmpty && n[0] == n[0].toUpperCase();
}

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
String? _jsExprOrNull(Expression e, WidgetTranslateContext ctx) {
  try {
    final js = ctx.jsDataExpr(e);
    return js == 'null' ? null : js;
  } catch (_) {
    return null;
  }
}

/// 把 builder 闭包抽成**组件方法**（沿用 `builderTrees` 机制），返回方法名；
/// 形态不支持返回 null（调用方丢弃该键并出声）。
///
/// - 形参必须是 `(context, index[, child])`（context 为首参，与 Dart 闭包一致）；
/// - 箭头体 `(context, i) => _Card(...)`：表达式即子树；
/// - 块体 `(context, i) { final o = xs[i]; return _Card(...); }`：局部变量声明
///   抽成方法前置语句，`return` 的表达式作子树。
///
/// 前缀由**参数名**给出（`itemBuilder` → `_itemBuilder0`），不依赖 widget 类型。
String? extractBuilderMethod(
  WidgetTranslateContext ctx,
  FunctionExpression builder,
  String prefix,
) {
  final params = builder.parameters?.parameters ?? const <FormalParameter>[];
  final rawCtxName = params.isEmpty ? null : params[0].name?.lexeme;
  final contextName =
      (rawCtxName == null || rawCtxName == '_') ? 'context' : rawCtxName;
  final indexName = params.length >= 2 ? params[1].name?.lexeme : null;
  // 只要求「至少一个上下文形参」：`builder: (context) => ...`（Builder）与
  // `itemBuilder: (context, index) => ...`（ListView.builder）都是合法 builder。
  if (params.isEmpty) return null;
  ctx.addBuilderLocal(contextName);
  if (indexName != null) ctx.addBuilderLocal(indexName);
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
          ctx.warnCapturedLocals(init);
          preludes.add('var ${v.name.lexeme} = ${ctx.jsDataExpr(init)};');
        }
        continue;
      }
      // 其余语句无法作为「抽取方法」的一部分，整体放弃（保持构建期告警）。
      return null;
    }
  }
  if (retExpr == null) return null;
  // 构建期抽查：闭包捕获了折算不成字段引用的局部变量/循环变量时出声告警——
  // 抽取成实例方法后它们是未定义自由变量（见 warnCapturedLocals）。
  ctx.warnCapturedLocals(retExpr);
  final subtree = ctx.translate(retExpr);
  ctx.builderTrees.add(subtree);
  final idx = ctx.builderTrees.length - 1;
  ctx.builderNames.add('$prefix$idx');
  ctx.builderParams.add(
      [contextName, if (indexName != null) indexName].join(', '));
  ctx.builderPreludes.add(preludes.isEmpty ? '' : preludes.join(' '));
  return '$prefix$idx';
}

/// 构建期告警（不静默）：结构化值没被分派表覆盖时出声，便于补齐分派表。
void _warnUnsupported(String source) {
  // ignore: avoid_print - 构建期日志
  print('[hot_patch_generator] 值形态未覆盖，该键已丢弃：$source');
}
