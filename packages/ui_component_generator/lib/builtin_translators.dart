import 'package:analyzer/dart/ast/ast.dart';

import 'style_translators.dart';
import 'widget_translator.dart';

/// 内置 widget 策略：把常见 Flutter widget 注册进 [WidgetTranslatorRegistry]。
///
/// 新增内置 widget = 在这里加一个 translator 类 + register 一行；
/// 自定义 widget = 在业务代码里实现 WidgetTranslator 并 register，
/// ComponentBuilder 核心逻辑无需改动。
///
/// 值约定：toJson 的 props 叶子值一律是 **JS 表达式字符串**（字符串字面量
/// 用 `ctx.jsString()` 带引号、数字/布尔/表达式原样），由渲染层统一输出为
/// JS 构造调用形态。
void registerBuiltinTranslators(WidgetTranslatorRegistry registry) {
  registry
    ..register(const ColumnTranslator())
    ..register(const RowTranslator())
    ..register(const TextTranslator())
    ..register(const ElevatedButtonTranslator())
    ..register(const TextButtonTranslator())
    ..register(const OutlinedButtonTranslator())
    ..register(const SizedBoxTranslator())
    ..register(const SpacerTranslator())
    ..register(const ChipTranslator())
    ..register(const ListTileTranslator())
    ..register(const ClipRRectTranslator())
    // 布局
    ..register(const ScaffoldTranslator())
    ..register(const AppBarTranslator())
    ..register(const CenterTranslator())
    ..register(const PaddingTranslator())
    ..register(const AlignTranslator())
    ..register(const ExpandedTranslator())
    ..register(const FlexibleTranslator())
    ..register(const StackTranslator())
    ..register(const PositionedTranslator())
    ..register(const ContainerTranslator())
    ..register(const DividerTranslator())
    ..register(const CardTranslator())
    ..register(const ListViewTranslator())
    ..register(const NotificationListenerTranslator())
    ..register(const SingleChildScrollViewTranslator())
    // 滚动视图 + sliver 家族（CustomScrollView 及其 sliver 子组件）
    ..register(const CustomScrollViewTranslator())
    ..register(const SliverListTranslator())
    ..register(const SliverGridTranslator())
    ..register(const SliverAppBarTranslator())
    ..register(const SliverPaddingTranslator())
    ..register(const SliverToBoxAdapterTranslator())
    ..register(const SliverFillRemainingTranslator())
    ..register(const SliverFixedExtentListTranslator())
    ..register(const SliverFillViewportTranslator())
    ..register(const SliverOpacityTranslator())
    ..register(const SliverOffstageTranslator())
    ..register(const SliverSafeAreaTranslator())
    ..register(const SliverIgnorePointerTranslator())
    ..register(const SliverVisibilityTranslator())
    ..register(const WrapTranslator())
    ..register(const SafeAreaTranslator())
    ..register(const OpacityTranslator())
    ..register(const ConstrainedBoxTranslator())
    ..register(const AspectRatioTranslator())
    ..register(const FractionallySizedBoxTranslator())
    ..register(const DecoratedBoxTranslator())
    // 内容
    ..register(const IconTranslator())
    ..register(const ImageTranslator())
    ..register(const CircleAvatarTranslator())
    ..register(const CircularProgressIndicatorTranslator())
    ..register(const LinearProgressIndicatorTranslator())
    // 交互
    ..register(const InkWellTranslator())
    ..register(const GestureDetectorTranslator())
    ..register(const SwitchTranslator())
    ..register(const CheckboxTranslator())
    ..register(const SliderTranslator())
    ..register(const TextFieldTranslator())
    ..register(const IconButtonTranslator())
    ..register(const FloatingActionButtonTranslator())
    ..register(const BottomNavigationBarTranslator())
    ..register(const BottomNavigationBarItemTranslator())
    ..register(const RadioTranslator())
    ..register(const DropdownButtonTranslator())
    ..register(const DropdownMenuItemTranslator())
    // 响应式（SDK 类，见 class_translator.sdkSuperClassMap 配套的 ChangeNotifier）
    ..register(const ListenableBuilderTranslator())
    // Builder：多一层 context 作用域（闭包内 context.watch/read 可用）
    ..register(const BuilderTranslator())
    // provider 包：ChangeNotifierProvider / Consumer / MultiProvider
    ..register(const ChangeNotifierProviderTranslator())
    ..register(const ConsumerTranslator())
    ..register(const MultiProviderTranslator());
  // 嵌套组件兜底：build 树里未注册的自定义 widget → Component 节点
  // （不参与 Map 注册，由 registry.fallback 持有；组件需 UpperCamel 才兜底）
  registry.registerFallback(const ComponentTranslator());
}

/// Column / Row 共用逻辑：容器节点，递归翻译 children + 对齐参数。
abstract class _AxisLayoutTranslator extends WidgetTranslator {
  const _AxisLayoutTranslator();

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = ctx.listArg(node.args, 'children', node.type);
    final props = <String, dynamic>{};
    final size = mainAxisSizeToJson(ctx.namedArg(node.args, 'mainAxisSize'));
    if (size != null) props['mainAxisSize'] = size;
    final main = mainAxisAlignmentToJson(ctx.namedArg(node.args, 'mainAxisAlignment'));
    if (main != null) props['mainAxisAlignment'] = main;
    final cross = crossAxisAlignmentToJson(ctx.namedArg(node.args, 'crossAxisAlignment'));
    if (cross != null) props['crossAxisAlignment'] = cross;
    return {
      'type': ctx.jsString(node.type),
      if (props.isNotEmpty) 'props': props,
      'children': [
        for (final c in children) ctx.translateElement(c),
      ],
    };
  }
}

/// Column：垂直布局容器（单一 type，一个实现）。
class ColumnTranslator extends _AxisLayoutTranslator {
  const ColumnTranslator();

  @override
  String get type => 'Column';
}

/// Row：水平布局容器（单一 type，一个实现）。
class RowTranslator extends _AxisLayoutTranslator {
  const RowTranslator();

  @override
  String get type => 'Row';
}

/// Text：文案（支持状态插值）+ TextStyle → 结构化 style JSON。
class TextTranslator extends WidgetTranslator {
  const TextTranslator();

  @override
  String get type => 'Text';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final dataExpr =
        ctx.namedArg(node.args, 'data') ?? ctx.nonNamedArg(node.args);
    if (dataExpr == null) {
      throw FormatException('Text 缺少内容');
    }
    final props = <String, dynamic>{
      'data': ctx.jsDataExpr(dataExpr),
    };
    // TextStyle(...) → JSON（运行时 textStyleFromJson 还原）
    final style = textStyleToJson(ctx.namedArg(node.args, 'style'), ctx);
    if (style != null) props['style'] = style;
    _numProp(ctx, node, props, 'maxLines');
    // textScaleFactor 已废弃（Flutter 3.16+ 用 textScaler），不支持废弃 API
    final scaler = ctx.namedArg(node.args, 'textScaler');
    if (scaler != null) {
      final t = textScalerToJson(scaler);
      if (t != null) props['textScaler'] = t;
    }
    _enumProp(ctx, node, props, 'overflow', 'TextOverflow');
    _enumProp(ctx, node, props, 'textAlign', 'TextAlign');
    _enumProp(ctx, node, props, 'textDirection', 'TextDirection');
    final softWrap = ctx.namedArg(node.args, 'softWrap');
    if (softWrap != null) {
      final js = ctx.jsDataExpr(softWrap);
      if (js != 'null') props['softWrap'] = js;
    }
    final semanticsLabel = ctx.namedArg(node.args, 'semanticsLabel');
    if (semanticsLabel is SimpleStringLiteral) {
      props['semanticsLabel'] = ctx.jsString(semanticsLabel.value);
    }
    return {'type': ctx.jsString('Text'), 'props': props};
  }

  /// 数字属性（maxLines）：字面量或状态字段表达式。
  static void _numProp(WidgetTranslateContext ctx, WidgetNode node,
      Map<String, dynamic> props, String name) {
    final a = ctx.namedArg(node.args, name);
    if (a == null) return;
    final js = ctx.jsDataExpr(a);
    if (js == 'null') return;
    props[name] = js;
  }

  /// 枚举属性（overflow/textAlign/textDirection）：`TextOverflow.ellipsis` → 字符串。
  static void _enumProp(WidgetTranslateContext ctx, WidgetNode node,
      Map<String, dynamic> props, String name, String owner) {
    final a = ctx.namedArg(node.args, name);
    if (a == null) return;
    final n = enumName(a, owner);
    if (n != null) props[name] = ctx.jsString(n);
  }
}

/// 三种按钮共用逻辑：onPressed → 事件名，child Text → label，
/// style（styleFrom / ButtonStyle）→ JSON；产物节点统一叫 'Button'。
abstract class _ButtonTranslator extends WidgetTranslator {
  const _ButtonTranslator();

  /// 产物节点统一叫 'Button'（运行时 ButtonRenderer 识别名）。
  @override
  Set<String> get jsonTypes => const {'Button'};

  /// 产物 kind：'elevated' / 'text' / 'outlined'（运行时按 kind 选按钮）。
  String get kind;

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final onPressed = ctx.namedArg(node.args, 'onPressed');
    final child = ctx.namedArg(node.args, 'child');
    if (onPressed == null) {
      throw FormatException('${node.type} 缺少 onPressed');
    }
    final props = <String, dynamic>{
      'kind': ctx.jsString(kind),
      'label': _labelFrom(child, ctx),
    };
    // onPressed: null → 禁用（省略 event）；否则构建期绑定句柄。
    if (onPressed is! NullLiteral) props['event'] = ctx.eventHandle(onPressed);
    // ElevatedButton.styleFrom(...) / ButtonStyle(...) → JSON
    final style = buttonStyleToJson(ctx.namedArg(node.args, 'style'), ctx);
    if (style != null) props['style'] = style;
    return {'type': ctx.jsString('Button'), 'props': props};
  }

  static String _labelFrom(Expression? child, WidgetTranslateContext ctx) {
    if (child == null) throw FormatException('按钮缺少 child');
    final (ctor, args) = ctx.ctorOf(child);
    if (ctor != 'Text') throw FormatException('按钮的 child 需要是 Text');
    final data = ctx.namedArg(args, 'data') ?? ctx.positionalArg(args, 0);
    if (data is SimpleStringLiteral) return ctx.jsString(data.value);
    throw FormatException('按钮文案需要是纯字符串字面量');
  }
}

/// ElevatedButton：默认实心按钮。
class ElevatedButtonTranslator extends _ButtonTranslator {
  const ElevatedButtonTranslator();

  @override
  String get type => 'ElevatedButton';

  @override
  String get kind => 'elevated';
}

/// TextButton：无背景文字按钮。
class TextButtonTranslator extends _ButtonTranslator {
  const TextButtonTranslator();

  @override
  String get type => 'TextButton';

  @override
  String get kind => 'text';
}

/// OutlinedButton：描边按钮。
class OutlinedButtonTranslator extends _ButtonTranslator {
  const OutlinedButtonTranslator();

  @override
  String get type => 'OutlinedButton';

  @override
  String get kind => 'outlined';
}

/// Chip：标签（label + avatar/backgroundColor/labelStyle/padding/side/shape/
/// elevation/deleteIcon/onDeleted）。
class ChipTranslator extends WidgetTranslator {
  const ChipTranslator();

  @override
  String get type => 'Chip';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    final label = ctx.namedArg(node.args, 'label');
    if (label != null) {
      final (ctor, args) = ctx.ctorOf(label);
      if (ctor == 'Text') {
        final data = ctx.namedArg(args, 'data') ?? ctx.positionalArg(args, 0);
        if (data != null) props['label'] = ctx.jsDataExpr(data);
      }
    }
    final bg = ctx.namedArg(node.args, 'backgroundColor');
    if (bg != null) {
      final c = translateColor(bg, ctx);
      if (c != null) props['backgroundColor'] = c;
    }
    final avatar = ctx.namedArg(node.args, 'avatar');
    if (avatar != null) props['avatar'] = ctx.translate(avatar);
    final deleteIcon = ctx.namedArg(node.args, 'deleteIcon');
    if (deleteIcon != null) props['deleteIcon'] = ctx.translate(deleteIcon);
    final onDeleted = ctx.namedArg(node.args, 'onDeleted');
    if (onDeleted != null) props['onDeleted'] = ctx.eventHandle(onDeleted);
    final labelStyle =
        textStyleToJson(ctx.namedArg(node.args, 'labelStyle'), ctx);
    if (labelStyle != null) props['labelStyle'] = labelStyle;
    final pad = edgeInsetsToJson(ctx.namedArg(node.args, 'padding'), ctx);
    if (pad != null) props['padding'] = pad;
    final sideExpr = ctx.namedArg(node.args, 'side');
    if (sideExpr != null) {
      final sd = borderSideToJson(sideExpr, ctx);
      if (sd != null) props['side'] = sd;
    }
    final shape = shapeToJson(ctx.namedArg(node.args, 'shape'), ctx);
    if (shape != null) props['shape'] = shape;
    final elevation = _numOf(ctx.namedArg(node.args, 'elevation'));
    if (elevation != null) props['elevation'] = elevation;
    return {'type': ctx.jsString('Chip'), 'props': props};
  }
}

/// ListTile：列表条目（leading/title/subtitle/trailing/onTap/onLongPress/
/// tileColor/contentPadding/dense/shape/iconColor/textColor）。
class ListTileTranslator extends WidgetTranslator {
  const ListTileTranslator();

  @override
  String get type => 'ListTile';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    for (final name in ['title', 'subtitle']) {
      final a = ctx.namedArg(node.args, name);
      if (a == null) continue;
      final (ctor, args) = ctx.ctorOf(a);
      if (ctor == 'Text') {
        final data = ctx.namedArg(args, 'data') ?? ctx.positionalArg(args, 0);
        if (data != null) props[name] = ctx.jsDataExpr(data);
      }
    }
    final leading = ctx.namedArg(node.args, 'leading');
    if (leading != null) props['leading'] = ctx.translate(leading);
    final trailing = ctx.namedArg(node.args, 'trailing');
    if (trailing != null) props['trailing'] = ctx.translate(trailing);
    final onTap = ctx.namedArg(node.args, 'onTap');
    if (onTap != null) {
      props['event'] = ctx.eventHandle(onTap);
    }
    final onLongPress = ctx.namedArg(node.args, 'onLongPress');
    if (onLongPress != null) {
      props['onLongPress'] = ctx.eventHandle(onLongPress);
    }
    final tileColor = colorToJson(ctx.namedArg(node.args, 'tileColor'), ctx);
    if (tileColor != null) props['tileColor'] = tileColor;
    final iconColor = colorToJson(ctx.namedArg(node.args, 'iconColor'), ctx);
    if (iconColor != null) props['iconColor'] = iconColor;
    final textColor = colorToJson(ctx.namedArg(node.args, 'textColor'), ctx);
    if (textColor != null) props['textColor'] = textColor;
    final padding =
        edgeInsetsToJson(ctx.namedArg(node.args, 'contentPadding'), ctx);
    if (padding != null) props['contentPadding'] = padding;
    final dense = _boolOf(ctx.namedArg(node.args, 'dense'));
    if (dense != null) props['dense'] = dense;
    final shape = shapeToJson(ctx.namedArg(node.args, 'shape'), ctx);
    if (shape != null) props['shape'] = shape;
    return {'type': ctx.jsString('ListTile'), 'props': props};
  }
}

/// ClipRRect：圆角裁剪（borderRadius + clipBehavior + child）。
class ClipRRectTranslator extends WidgetTranslator {
  const ClipRRectTranslator();

  @override
  String get type => 'ClipRRect';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    final radius = ctx.namedArg(node.args, 'borderRadius');
    if (radius != null) {
      final r = ctx.borderRadiusExpr(radius);
      if (r != null) props['borderRadius'] = r;
    }
    final clip = clipBehaviorToJson(ctx.namedArg(node.args, 'clipBehavior'));
    if (clip != null) props['clipBehavior'] = clip;
    final child = ctx.namedArg(node.args, 'child');
    if (child != null) props['child'] = ctx.translate(child);
    return {'type': ctx.jsString('ClipRRect'), 'props': props};
  }
}

/// SizedBox：布局空隙（height/width），无 UI 内容。
class SizedBoxTranslator extends WidgetTranslator {
  const SizedBoxTranslator();

  @override
  String get type => 'SizedBox';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    final h = _numLiteral(ctx.namedArg(node.args, 'height'));
    final w = _numLiteral(ctx.namedArg(node.args, 'width'));
    if (h != null) props['height'] = h;
    if (w != null) props['width'] = w;
    // SizedBox(height:.., width:.., child:..)：child 进 children，运行时渲染
    final child = ctx.namedArg(node.args, 'child');
    final children = <Object?>[
      if (child != null) ctx.translate(child),
    ];
    return {
      'type': ctx.jsString('SizedBox'),
      'props': props,
      if (children.isNotEmpty) 'children': children,
    };
  }

  static String? _numLiteral(Expression? e) {
    if (e is IntegerLiteral) {
      final v = e.value;
      return v == null ? null : '$v';
    }
    if (e is DoubleLiteral) {
      return '${e.value}';
    }
    return null;
  }
}

// ===========================================================================
// 页面骨架
// ===========================================================================

/// Scaffold：页面骨架（appBar / body / backgroundColor /
/// floatingActionButton / bottomNavigationBar）。
///
/// 产物把 appBar 与 body 依次放 children（children[0]=AppBar、children[1]=body），
/// floatingActionButton / bottomNavigationBar 作为「值为 element 的 prop」
/// 下发（运行时按 prop 名挂载），运行时 JsWidgetRegistry 按序取用。
class ScaffoldTranslator extends WidgetTranslator {
  const ScaffoldTranslator();

  @override
  String get type => 'Scaffold';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = <Object?>[];
    final appBar = ctx.namedArg(node.args, 'appBar');
    if (appBar != null) children.add(ctx.translate(appBar));
    final body = ctx.namedArg(node.args, 'body');
    if (body != null) children.add(ctx.translate(body));
    final props = <String, dynamic>{};
    final bg = colorToJson(ctx.namedArg(node.args, 'backgroundColor'), ctx);
    if (bg != null) props['backgroundColor'] = bg;
    final fab = ctx.namedArg(node.args, 'floatingActionButton');
    if (fab != null) props['floatingActionButton'] = ctx.translate(fab);
    final bottomNav = ctx.namedArg(node.args, 'bottomNavigationBar');
    if (bottomNav != null) {
      props['bottomNavigationBar'] = ctx.translate(bottomNav);
    }
    return {
      'type': ctx.jsString('Scaffold'),
      if (props.isNotEmpty) 'props': props,
      'children': children,
    };
  }
}

/// AppBar：title / leading（element prop）+ actions（children）
/// + backgroundColor/elevation/centerTitle/toolbarHeight/titleTextStyle。
///
/// title 走「值为 element 的 prop」而非 children[0]：actions 进 children，
/// 避免「无 title 时 children[0] 是 title 还是第一个 action」的歧义。
class AppBarTranslator extends WidgetTranslator {
  const AppBarTranslator();

  @override
  String get type => 'AppBar';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = <Object?>[];
    final actions = ctx.namedArg(node.args, 'actions');
    if (actions is ListLiteral) {
      for (final a in actions.elements) {
        children.add(ctx.translateElement(a));
      }
    }
    final props = <String, dynamic>{};
    final title = ctx.namedArg(node.args, 'title');
    if (title != null) props['title'] = ctx.translate(title);
    final leading = ctx.namedArg(node.args, 'leading');
    if (leading != null) props['leading'] = ctx.translate(leading);
    final bg = colorToJson(ctx.namedArg(node.args, 'backgroundColor'), ctx);
    if (bg != null) props['backgroundColor'] = bg;
    final fg = colorToJson(ctx.namedArg(node.args, 'foregroundColor'), ctx);
    if (fg != null) props['foregroundColor'] = fg;
    final elevation = _numOf(ctx.namedArg(node.args, 'elevation'));
    if (elevation != null) props['elevation'] = elevation;
    final toolbarHeight = _numOf(ctx.namedArg(node.args, 'toolbarHeight'));
    if (toolbarHeight != null) props['toolbarHeight'] = toolbarHeight;
    final centerTitle = _boolOf(ctx.namedArg(node.args, 'centerTitle'));
    if (centerTitle != null) props['centerTitle'] = centerTitle;
    final titleStyle =
        textStyleToJson(ctx.namedArg(node.args, 'titleTextStyle'), ctx);
    if (titleStyle != null) props['titleTextStyle'] = titleStyle;
    return {
      'type': ctx.jsString('AppBar'),
      if (props.isNotEmpty) 'props': props,
      'children': children,
    };
  }
}

// ===========================================================================
// 布局类
// ===========================================================================

/// Center：单子居中。
class CenterTranslator extends WidgetTranslator {
  const CenterTranslator();

  @override
  String get type => 'Center';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('Center 缺少 child');
    return {'type': ctx.jsString('Center'), 'children': [ctx.translate(child)]};
  }
}

/// Padding：EdgeInsets.padding → JSON，单子。
class PaddingTranslator extends WidgetTranslator {
  const PaddingTranslator();

  @override
  String get type => 'Padding';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('Padding 缺少 child');
    final pad = edgeInsetsToJson(ctx.namedArg(node.args, 'padding'), ctx);
    final props = <String, dynamic>{};
    if (pad != null) props['padding'] = pad;
    return {
      'type': ctx.jsString('Padding'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// Align：alignment → JSON，单子。
class AlignTranslator extends WidgetTranslator {
  const AlignTranslator();

  @override
  String get type => 'Align';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('Align 缺少 child');
    final props = <String, dynamic>{};
    final align = alignmentToJson(ctx.namedArg(node.args, 'alignment'), ctx);
    if (align != null) props['alignment'] = align;
    return {
      'type': ctx.jsString('Align'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// Expanded / Flexible 共用逻辑：flex + 单子（Row/Column 内）。
abstract class _FlexTranslator extends WidgetTranslator {
  const _FlexTranslator();

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('${node.type} 缺少 child');
    final props = <String, dynamic>{};
    final flex = ctx.namedArg(node.args, 'flex');
    if (flex is IntegerLiteral && flex.value != null) props['flex'] = '${flex.value}';
    return {
      'type': ctx.jsString(node.type),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// Expanded：Row/Column 内撑满剩余空间。
class ExpandedTranslator extends _FlexTranslator {
  const ExpandedTranslator();

  @override
  String get type => 'Expanded';
}

/// Flexible：Row/Column 内可伸缩（不强制撑满）。
class FlexibleTranslator extends _FlexTranslator {
  const FlexibleTranslator();

  @override
  String get type => 'Flexible';
}

/// Stack：children + alignment/fit/clipBehavior。
class StackTranslator extends WidgetTranslator {
  const StackTranslator();

  @override
  String get type => 'Stack';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = ctx.listArg(node.args, 'children', node.type);
    final props = <String, dynamic>{};
    final align = alignmentToJson(ctx.namedArg(node.args, 'alignment'), ctx);
    if (align != null) props['alignment'] = align;
    final fit = stackFitToJson(ctx.namedArg(node.args, 'fit'));
    if (fit != null) props['fit'] = fit;
    final clip = clipBehaviorToJson(ctx.namedArg(node.args, 'clipBehavior'));
    if (clip != null) props['clipBehavior'] = clip;
    return {
      'type': ctx.jsString('Stack'),
      if (props.isNotEmpty) 'props': props,
      'children': [for (final c in children) ctx.translateElement(c)],
    };
  }
}

/// Positioned：Stack 内定位（left/top/right/bottom/width/height）。
class PositionedTranslator extends WidgetTranslator {
  const PositionedTranslator();

  @override
  String get type => 'Positioned';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('Positioned 缺少 child');
    final props = <String, dynamic>{};
    if (node.factory == 'fill') {
      // Positioned.fill({left=0, top=0, right=0, bottom=0})：四边默认全 0
      // 撑满 Stack，显式参数覆盖；展开后与普通 Positioned 等效（运行时零改动）。
      for (final name in ['left', 'top', 'right', 'bottom']) {
        final v = ctx.namedArg(node.args, name);
        if (v is IntegerLiteral && v.value != null) {
          props[name] = '${v.value}';
        } else if (v is DoubleLiteral) {
          props[name] = '${v.value}';
        } else {
          props[name] = '0';
        }
      }
    } else {
      for (final name in ['left', 'top', 'right', 'bottom', 'width', 'height']) {
        final v = ctx.namedArg(node.args, name);
        if (v is IntegerLiteral && v.value != null) {
          props[name] = '${v.value}';
        } else if (v is DoubleLiteral) {
          props[name] = '${v.value}';
        }
      }
    }
    return {
      'type': ctx.jsString('Positioned'),
      'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// Container：width/height/color/padding/margin/alignment/decoration/
/// constraints/clipBehavior + 单子。
class ContainerTranslator extends WidgetTranslator {
  const ContainerTranslator();

  @override
  String get type => 'Container';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    final w = _numOf(ctx.namedArg(node.args, 'width'));
    final h = _numOf(ctx.namedArg(node.args, 'height'));
    if (w != null) props['width'] = w;
    if (h != null) props['height'] = h;
    final color = colorToJson(ctx.namedArg(node.args, 'color'), ctx);
    if (color != null) props['color'] = color;
    final pad = edgeInsetsToJson(ctx.namedArg(node.args, 'padding'), ctx);
    if (pad != null) props['padding'] = pad;
    final margin = edgeInsetsToJson(ctx.namedArg(node.args, 'margin'), ctx);
    if (margin != null) props['margin'] = margin;
    final align = alignmentToJson(ctx.namedArg(node.args, 'alignment'), ctx);
    if (align != null) props['alignment'] = align;
    final deco = boxDecorationToJson(ctx.namedArg(node.args, 'decoration'), ctx);
    if (deco != null) props['decoration'] = deco;
    final constraints =
        boxConstraintsToJson(ctx.namedArg(node.args, 'constraints'), ctx);
    if (constraints != null) props['constraints'] = constraints;
    final clip = clipBehaviorToJson(ctx.namedArg(node.args, 'clipBehavior'));
    if (clip != null) props['clipBehavior'] = clip;
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    return {
      'type': ctx.jsString('Container'),
      if (props.isNotEmpty) 'props': props,
      if (child != null) 'children': [ctx.translate(child)],
    };
  }
}

/// Divider：height/thickness/indent/endIndent/color。
class DividerTranslator extends WidgetTranslator {
  const DividerTranslator();

  @override
  String get type => 'Divider';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    for (final name in ['height', 'thickness', 'indent', 'endIndent']) {
      final v = _numOf(ctx.namedArg(node.args, name));
      if (v != null) props[name] = v;
    }
    final color = colorToJson(ctx.namedArg(node.args, 'color'), ctx);
    if (color != null) props['color'] = color;
    return {
      'type': ctx.jsString('Divider'),
      if (props.isNotEmpty) 'props': props,
    };
  }
}

/// Card：child + elevation/margin/color/shape/clipBehavior/shadowColor。
class CardTranslator extends WidgetTranslator {
  const CardTranslator();

  @override
  String get type => 'Card';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('Card 缺少 child');
    final props = <String, dynamic>{};
    final e = _numOf(ctx.namedArg(node.args, 'elevation'));
    if (e != null) props['elevation'] = e;
    final margin = edgeInsetsToJson(ctx.namedArg(node.args, 'margin'), ctx);
    if (margin != null) props['margin'] = margin;
    final color = colorToJson(ctx.namedArg(node.args, 'color'), ctx);
    if (color != null) props['color'] = color;
    final shape = shapeToJson(ctx.namedArg(node.args, 'shape'), ctx);
    if (shape != null) props['shape'] = shape;
    final clip = clipBehaviorToJson(ctx.namedArg(node.args, 'clipBehavior'));
    if (clip != null) props['clipBehavior'] = clip;
    final shadow = colorToJson(ctx.namedArg(node.args, 'shadowColor'), ctx);
    if (shadow != null) props['shadowColor'] = shadow;
    return {
      'type': ctx.jsString('Card'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// ListView：children + scrollDirection/padding/shrinkWrap/physics/itemExtent。
/// controller 参数（Dart 侧 ScrollController）与 SingleChildScrollView 同款
/// 透传：JS 产物引用 `this._scrollController`，跨桥序列化为
/// `{__jsuiScrollController: id}`，宿主按 id 绑定真实 controller。
class ListViewTranslator extends WidgetTranslator {
  const ListViewTranslator();

  @override
  String get type => 'ListView';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = ctx.listArg(node.args, 'children', node.type);
    final props = <String, dynamic>{};
    final ctrl = ctx.namedArg(node.args, 'controller');
    if (ctrl != null) props['controller'] = ctx.jsDataExpr(ctrl);
    final axis = axisToJson(ctx.namedArg(node.args, 'scrollDirection'));
    if (axis != null) props['scrollDirection'] = axis;
    final padding = edgeInsetsToJson(ctx.namedArg(node.args, 'padding'), ctx);
    if (padding != null) props['padding'] = padding;
    final shrinkWrap = _boolOf(ctx.namedArg(node.args, 'shrinkWrap'));
    if (shrinkWrap != null) props['shrinkWrap'] = shrinkWrap;
    final physics = scrollPhysicsToJson(ctx.namedArg(node.args, 'physics'));
    if (physics != null) props['physics'] = physics;
    final itemExtent = _numOf(ctx.namedArg(node.args, 'itemExtent'));
    if (itemExtent != null) props['itemExtent'] = itemExtent;
    return {
      'type': ctx.jsString('ListView'),
      if (props.isNotEmpty) 'props': props,
      'children': [for (final c in children) ctx.translateElement(c)],
    };
  }
}

// ===========================================================================
// 滚动视图 + sliver 家族（CustomScrollView 及其 sliver 子组件）
// ===========================================================================

/// 从表达式里提取「构造名 + 位置/命名参数列表」，兼容两种 AST 形态：
/// `Foo(...)`（InvocationExpression）与 `const Foo(...)`（
/// InstanceCreationExpression）。非构造调用返回 (null, null)。
(String?, List<Expression>?) _ctorCall(Expression? e) {
  if (e is InstanceCreationExpression) {
    return (e.constructorName.type.name2.lexeme, e.argumentList.arguments);
  }
  if (e is InvocationExpression) {
    final fn = e.function;
    if (fn is Identifier) return (fn.name, e.argumentList.arguments);
  }
  return (null, null);
}

/// 解析 `SliverChildListDelegate(children)` 中的 children 列表（ListDelegate
/// 形态）。builder delegate（SliverChildBuilderDelegate）走
/// [_sliverBuilderDelegateChildren]。
List<CollectionElement>? _sliverListDelegateChildren(Expression? delegate) {
  final (name, args) = _ctorCall(delegate);
  if (name == 'SliverChildListDelegate' && args != null) {
    for (final a in args) {
      if (a is ListLiteral) return a.elements;
    }
  }
  return null;
}

/// 解析 `SliverChildBuilderDelegate((context, index) => widget, childCount: n)`
/// 的 builder 形态：把闭包抽成组件方法 `_sliverBuilderN(index)`（沿用
/// builderTrees 机制；childCount 支持任意表达式），产物 children 返回
/// **JS 展开表达式字符串**（for 循环调用该方法 i 次收集子树，`.call(this)`
/// 保证 this 指向组件实例）。返回 null = 形态不支持。
List<Object?>? _sliverBuilderDelegateChildren(
    Expression? delegate, WidgetTranslateContext ctx) {
  final (name, args) = _ctorCall(delegate);
  if (name != 'SliverChildBuilderDelegate' || args == null) return null;
  // builder 是第一个**位置**参数（Flutter 必填），childCount 是命名参数。
  final builderRaw = ctx.namedArg(args, 'builder') ?? ctx.nonNamedArg(args);
  final childCount = ctx.namedArg(args, 'childCount');
  if (builderRaw is! FunctionExpression || childCount == null) return null;
  final params = builderRaw.parameters?.parameters ?? const <FormalParameter>[];
  // (context, index[, child]) —— index 是第二个参数（Consumer 同款约定）。
  final indexName = params.length >= 2 ? params[1].name?.lexeme : null;
  if (indexName == null) return null;
  final inner = ctx.functionInner(builderRaw);
  if (inner == null) return null;
  ctx.addLocal(indexName);
  final subtree = ctx.translate(inner);
  ctx.builderTrees.add(subtree);
  final idx = ctx.builderTrees.length - 1;
  ctx.builderNames.add('_sliverBuilder$idx');
  ctx.builderParams.add(indexName);
  final countJs = ctx.jsDataExpr(childCount);
  // children 为 spread 展开表达式：`...` 把数组展开为子节点列表；
  // `.call(this)` 返回数组并保证 IIFE 内 this 指向组件实例。
  return [
    '...(function(){ var out = []; for (var i = 0; i < ($countJs); i++) '
        '{ out.push(this._sliverBuilder$idx(i)); } return out; }).call(this)'
  ];
}

/// 统一的 sliver delegate → children 翻译：ListDelegate 直接展开 children；
/// BuilderDelegate 抽方法并返回展开表达式字符串。两者都不支持 → null。
List<Object?>? _sliverDelegateToChildren(
    Expression? delegate, WidgetTranslateContext ctx) {
  final listChildren = _sliverListDelegateChildren(delegate);
  if (listChildren != null) {
    return [for (final c in listChildren) ctx.translateElement(c)];
  }
  return _sliverBuilderDelegateChildren(delegate, ctx);
}

/// 解析 grid delegate 的数值参数，支持两种形态：
/// - `SliverGridDelegateWithFixedCrossAxisCount(...)`：crossAxisCount/
///   mainAxisSpacing/crossAxisSpacing/childAspectRatio/mainAxisExtent
/// - `SliverGridDelegateWithMaxCrossAxisExtent(...)`：maxCrossAxisExtent/
///   mainAxisSpacing/crossAxisSpacing/childAspectRatio/mainAxisExtent
/// 非支持形态返回 null。
Map<String, dynamic>? _gridDelegateToJson(
    Expression? e, WidgetTranslateContext ctx) {
  final (name, args) = _ctorCall(e);
  if (args == null) return null;
  final fixed = name == 'SliverGridDelegateWithFixedCrossAxisCount';
  final max = name == 'SliverGridDelegateWithMaxCrossAxisExtent';
  if (!fixed && !max) return null;
  final props = <String, dynamic>{};
  for (final n in [
    'crossAxisCount',
    'maxCrossAxisExtent',
    'mainAxisSpacing',
    'crossAxisSpacing',
    'childAspectRatio',
    'mainAxisExtent',
  ]) {
    final v = _numOf(ctx.namedArg(args, n));
    if (v != null) props[n] = v;
  }
  if (props.isNotEmpty) return props;
  return null;
}

/// CustomScrollView：slivers（命名参数）列表 + controller/scrollDirection/
/// padding/physics/reverse/shrinkWrap。controller 透传与 SingleChildScrollView/
/// ListView 同款（`this._scrollController` → `{__jsuiScrollController: id}`）。
class CustomScrollViewTranslator extends WidgetTranslator {
  const CustomScrollViewTranslator();

  @override
  String get type => 'CustomScrollView';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final slivers = ctx.listArg(node.args, 'slivers', node.type);
    final props = <String, dynamic>{};
    final ctrl = ctx.namedArg(node.args, 'controller');
    if (ctrl != null) props['controller'] = ctx.jsDataExpr(ctrl);
    final axis = axisToJson(ctx.namedArg(node.args, 'scrollDirection'));
    if (axis != null) props['scrollDirection'] = axis;
    final physics = scrollPhysicsToJson(ctx.namedArg(node.args, 'physics'));
    if (physics != null) props['physics'] = physics;
    final reverse = _boolOf(ctx.namedArg(node.args, 'reverse'));
    if (reverse != null) props['reverse'] = reverse;
    final shrinkWrap = _boolOf(ctx.namedArg(node.args, 'shrinkWrap'));
    if (shrinkWrap != null) props['shrinkWrap'] = shrinkWrap;
    return {
      'type': ctx.jsString('CustomScrollView'),
      if (props.isNotEmpty) 'props': props,
      'children': [for (final s in slivers) ctx.translateElement(s)],
    };
  }
}

/// SliverList：delegate 支持两种形态——`SliverChildListDelegate([...])`
/// （children 展开为子节点，宿主侧补回 delegate）与
/// `SliverChildBuilderDelegate((context, index) => widget, childCount: n)`
/// （闭包抽成 `_sliverBuilderN(index)` 方法，产物以 for 展开表达式填充
/// children）。JS 写法与 ListView 一致。
class SliverListTranslator extends WidgetTranslator {
  const SliverListTranslator();

  @override
  String get type => 'SliverList';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children =
        _sliverDelegateToChildren(ctx.namedArg(node.args, 'delegate'), ctx);
    if (children == null) {
      throw FormatException(
          'SliverList 仅支持 delegate: SliverChildListDelegate([...]) 或 '
          'SliverChildBuilderDelegate(...)');
    }
    return {
      'type': ctx.jsString('SliverList'),
      'children': children,
    };
  }
}

/// SliverGrid：delegate 同 SliverList（List/Build 双形态）；gridDelegate 支持
/// SliverGridDelegateWithFixedCrossAxisCount（crossAxisCount 等）与
/// SliverGridDelegateWithMaxCrossAxisExtent（maxCrossAxisExtent 等），
/// 数值参数进 props，宿主侧还原为真实 gridDelegate。
class SliverGridTranslator extends WidgetTranslator {
  const SliverGridTranslator();

  @override
  String get type => 'SliverGrid';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children =
        _sliverDelegateToChildren(ctx.namedArg(node.args, 'delegate'), ctx);
    if (children == null) {
      throw FormatException(
          'SliverGrid 仅支持 delegate: SliverChildListDelegate([...]) 或 '
          'SliverChildBuilderDelegate(...)');
    }
    final grid = _gridDelegateToJson(ctx.namedArg(node.args, 'gridDelegate'), ctx);
    if (grid == null) {
      throw FormatException(
          'SliverGrid 仅支持 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(...) '
          '或 SliverGridDelegateWithMaxCrossAxisExtent(...)');
    }
    return {
      'type': ctx.jsString('SliverGrid'),
      'props': grid,
      'children': children,
    };
  }
}

/// SliverAppBar：与 AppBar 同款（title/leading 是 element-prop、actions 进
/// children），另加 sliver 专属 pinned/floating/snap/expandedHeight。
class SliverAppBarTranslator extends WidgetTranslator {
  const SliverAppBarTranslator();

  @override
  String get type => 'SliverAppBar';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = <Object?>[];
    final actions = ctx.namedArg(node.args, 'actions');
    if (actions is ListLiteral) {
      for (final a in actions.elements) {
        children.add(ctx.translateElement(a));
      }
    }
    final props = <String, dynamic>{};
    final title = ctx.namedArg(node.args, 'title');
    if (title != null) props['title'] = ctx.translate(title);
    final leading = ctx.namedArg(node.args, 'leading');
    if (leading != null) props['leading'] = ctx.translate(leading);
    final bg = colorToJson(ctx.namedArg(node.args, 'backgroundColor'), ctx);
    if (bg != null) props['backgroundColor'] = bg;
    final fg = colorToJson(ctx.namedArg(node.args, 'foregroundColor'), ctx);
    if (fg != null) props['foregroundColor'] = fg;
    final elevation = _numOf(ctx.namedArg(node.args, 'elevation'));
    if (elevation != null) props['elevation'] = elevation;
    final toolbarHeight = _numOf(ctx.namedArg(node.args, 'toolbarHeight'));
    if (toolbarHeight != null) props['toolbarHeight'] = toolbarHeight;
    final centerTitle = _boolOf(ctx.namedArg(node.args, 'centerTitle'));
    if (centerTitle != null) props['centerTitle'] = centerTitle;
    final titleStyle =
        textStyleToJson(ctx.namedArg(node.args, 'titleTextStyle'), ctx);
    if (titleStyle != null) props['titleTextStyle'] = titleStyle;
    final pinned = _boolOf(ctx.namedArg(node.args, 'pinned'));
    if (pinned != null) props['pinned'] = pinned;
    final floating = _boolOf(ctx.namedArg(node.args, 'floating'));
    if (floating != null) props['floating'] = floating;
    final snap = _boolOf(ctx.namedArg(node.args, 'snap'));
    if (snap != null) props['snap'] = snap;
    final expandedHeight = _numOf(ctx.namedArg(node.args, 'expandedHeight'));
    if (expandedHeight != null) props['expandedHeight'] = expandedHeight;
    return {
      'type': ctx.jsString('SliverAppBar'),
      if (props.isNotEmpty) 'props': props,
      'children': children,
    };
  }
}

/// SliverPadding：padding + 单个 sliver 子树（命名参数 sliver）。
class SliverPaddingTranslator extends WidgetTranslator {
  const SliverPaddingTranslator();

  @override
  String get type => 'SliverPadding';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final sliver = ctx.namedArg(node.args, 'sliver') ?? ctx.nonNamedArg(node.args);
    if (sliver == null) throw FormatException('SliverPadding 缺少 sliver');
    final props = <String, dynamic>{};
    final padding = edgeInsetsToJson(ctx.namedArg(node.args, 'padding'), ctx);
    if (padding != null) props['padding'] = padding;
    return {
      'type': ctx.jsString('SliverPadding'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translateElement(sliver)],
    };
  }
}

/// SliverToBoxAdapter：单个普通 widget 包装成 sliver。
class SliverToBoxAdapterTranslator extends WidgetTranslator {
  const SliverToBoxAdapterTranslator();

  @override
  String get type => 'SliverToBoxAdapter';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('SliverToBoxAdapter 缺少 child');
    return {
      'type': ctx.jsString('SliverToBoxAdapter'),
      'children': [ctx.translateElement(child)],
    };
  }
}

/// SliverFillRemaining：child + hasScrollBody/fillOverscroll。
class SliverFillRemainingTranslator extends WidgetTranslator {
  const SliverFillRemainingTranslator();

  @override
  String get type => 'SliverFillRemaining';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('SliverFillRemaining 缺少 child');
    final props = <String, dynamic>{};
    final hasScrollBody = _boolOf(ctx.namedArg(node.args, 'hasScrollBody'));
    if (hasScrollBody != null) props['hasScrollBody'] = hasScrollBody;
    final fillOverscroll = _boolOf(ctx.namedArg(node.args, 'fillOverscroll'));
    if (fillOverscroll != null) props['fillOverscroll'] = fillOverscroll;
    return {
      'type': ctx.jsString('SliverFillRemaining'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translateElement(child)],
    };
  }
}

/// SliverFixedExtentList：delegate（List/Build 双形态）+ itemExtent（必填）。
class SliverFixedExtentListTranslator extends WidgetTranslator {
  const SliverFixedExtentListTranslator();

  @override
  String get type => 'SliverFixedExtentList';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children =
        _sliverDelegateToChildren(ctx.namedArg(node.args, 'delegate'), ctx);
    if (children == null) {
      throw FormatException(
          'SliverFixedExtentList 仅支持 delegate: SliverChildListDelegate([...]) '
          '或 SliverChildBuilderDelegate(...)');
    }
    final props = <String, dynamic>{};
    final itemExtent = _numOf(ctx.namedArg(node.args, 'itemExtent'));
    if (itemExtent == null) {
      throw FormatException('SliverFixedExtentList 缺少 itemExtent');
    }
    props['itemExtent'] = itemExtent;
    return {
      'type': ctx.jsString('SliverFixedExtentList'),
      'props': props,
      'children': children,
    };
  }
}

/// SliverFillViewport：delegate（List/Build 双形态）+ viewportFraction。
class SliverFillViewportTranslator extends WidgetTranslator {
  const SliverFillViewportTranslator();

  @override
  String get type => 'SliverFillViewport';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children =
        _sliverDelegateToChildren(ctx.namedArg(node.args, 'delegate'), ctx);
    if (children == null) {
      throw FormatException(
          'SliverFillViewport 仅支持 delegate: SliverChildListDelegate([...]) '
          '或 SliverChildBuilderDelegate(...)');
    }
    final props = <String, dynamic>{};
    final fraction = _numOf(ctx.namedArg(node.args, 'viewportFraction'));
    if (fraction != null) props['viewportFraction'] = fraction;
    return {
      'type': ctx.jsString('SliverFillViewport'),
      if (props.isNotEmpty) 'props': props,
      'children': children,
    };
  }
}

/// SliverOpacity：opacity + 单个 sliver（透明度的 sliver 版）。
class SliverOpacityTranslator extends WidgetTranslator {
  const SliverOpacityTranslator();

  @override
  String get type => 'SliverOpacity';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final sliver = ctx.namedArg(node.args, 'sliver') ?? ctx.nonNamedArg(node.args);
    if (sliver == null) throw FormatException('SliverOpacity 缺少 sliver');
    final props = <String, dynamic>{};
    final opacity = _numOf(ctx.namedArg(node.args, 'opacity'));
    if (opacity == null) throw FormatException('SliverOpacity 缺少 opacity');
    props['opacity'] = opacity;
    return {
      'type': ctx.jsString('SliverOpacity'),
      'props': props,
      'children': [ctx.translateElement(sliver)],
    };
  }
}

/// SliverOffstage：offstage + 单个 sliver（离屏但保留状态的 sliver 版）。
class SliverOffstageTranslator extends WidgetTranslator {
  const SliverOffstageTranslator();

  @override
  String get type => 'SliverOffstage';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final sliver = ctx.namedArg(node.args, 'sliver') ?? ctx.nonNamedArg(node.args);
    if (sliver == null) throw FormatException('SliverOffstage 缺少 sliver');
    final props = <String, dynamic>{};
    final offstage = _boolOf(ctx.namedArg(node.args, 'offstage'));
    if (offstage == null) throw FormatException('SliverOffstage 缺少 offstage');
    props['offstage'] = offstage;
    return {
      'type': ctx.jsString('SliverOffstage'),
      'props': props,
      'children': [ctx.translateElement(sliver)],
    };
  }
}

/// SliverSafeArea：left/top/right/bottom + 单个 sliver。
class SliverSafeAreaTranslator extends WidgetTranslator {
  const SliverSafeAreaTranslator();

  @override
  String get type => 'SliverSafeArea';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final sliver = ctx.namedArg(node.args, 'sliver') ?? ctx.nonNamedArg(node.args);
    if (sliver == null) throw FormatException('SliverSafeArea 缺少 sliver');
    final props = <String, dynamic>{};
    for (final n in ['left', 'top', 'right', 'bottom']) {
      final v = _boolOf(ctx.namedArg(node.args, n));
      if (v != null) props[n] = v;
    }
    return {
      'type': ctx.jsString('SliverSafeArea'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translateElement(sliver)],
    };
  }
}

/// SliverIgnorePointer：ignoring + 单个 sliver。
class SliverIgnorePointerTranslator extends WidgetTranslator {
  const SliverIgnorePointerTranslator();

  @override
  String get type => 'SliverIgnorePointer';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final sliver = ctx.namedArg(node.args, 'sliver') ?? ctx.nonNamedArg(node.args);
    if (sliver == null) throw FormatException('SliverIgnorePointer 缺少 sliver');
    final props = <String, dynamic>{};
    final ignoring = _boolOf(ctx.namedArg(node.args, 'ignoring'));
    if (ignoring == null) throw FormatException('SliverIgnorePointer 缺少 ignoring');
    props['ignoring'] = ignoring;
    return {
      'type': ctx.jsString('SliverIgnorePointer'),
      'props': props,
      'children': [ctx.translateElement(sliver)],
    };
  }
}

/// SliverVisibility：visible + 单个 sliver（SliverVisibility 形态）。
class SliverVisibilityTranslator extends WidgetTranslator {
  const SliverVisibilityTranslator();

  @override
  String get type => 'SliverVisibility';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final sliver = ctx.namedArg(node.args, 'sliver') ?? ctx.nonNamedArg(node.args);
    if (sliver == null) throw FormatException('SliverVisibility 缺少 sliver');
    final props = <String, dynamic>{};
    final visible = _boolOf(ctx.namedArg(node.args, 'visible'));
    if (visible != null) props['visible'] = visible;
    final maintain = _boolOf(ctx.namedArg(node.args, 'maintainState'));
    if (maintain != null) props['maintainState'] = maintain;
    return {
      'type': ctx.jsString('SliverVisibility'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translateElement(sliver)],
    };
  }
}

/// NotificationListener：滚动/尺寸通知监听（Flutter 官方 widget）。
///
/// 只翻译两件事：
///   - onNotification：事件句柄（`onNotification: _onScroll` →
///     `this.__bind("_onScroll")`，宿主滚动时 invoke 回传 metrics 快照）；
///   - child：被监听的单子树。
/// 泛型参数（`NotificationListener<ScrollNotification>`）不参与产物。
class NotificationListenerTranslator extends WidgetTranslator {
  const NotificationListenerTranslator();

  @override
  String get type => 'NotificationListener';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('NotificationListener 缺少 child');
    final props = <String, dynamic>{};
    final onNotif = ctx.namedArg(node.args, 'onNotification');
    if (onNotif != null) props['onNotification'] = ctx.eventHandle(onNotif);
    return {
      'type': ctx.jsString('NotificationListener'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translateElement(child)],
    };
  }
}

/// SingleChildScrollView：child + scrollDirection/padding/physics/reverse。
///
/// controller 参数（Dart 侧 ScrollController）在 JS 侧对应同名代理类
/// `ScrollController`（见 JS 运行时）：产物透传实例引用 `this._scrollController`，
/// 跨桥序列化时实例经 toJSON 输出 `{__jsuiScrollController: id}`，宿主注册表
/// 按 id 绑定真实 controller（滚动回传 metrics、jumpTo 走实例级 host 通道）。
class SingleChildScrollViewTranslator extends WidgetTranslator {
  const SingleChildScrollViewTranslator();

  @override
  String get type => 'SingleChildScrollView';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('SingleChildScrollView 缺少 child');
    final props = <String, dynamic>{};
    final ctrl = ctx.namedArg(node.args, 'controller');
    if (ctrl != null) props['controller'] = ctx.jsDataExpr(ctrl);
    final axis = axisToJson(ctx.namedArg(node.args, 'scrollDirection'));
    if (axis != null) props['scrollDirection'] = axis;
    final padding = edgeInsetsToJson(ctx.namedArg(node.args, 'padding'), ctx);
    if (padding != null) props['padding'] = padding;
    final physics = scrollPhysicsToJson(ctx.namedArg(node.args, 'physics'));
    if (physics != null) props['physics'] = physics;
    final reverse = _boolOf(ctx.namedArg(node.args, 'reverse'));
    if (reverse != null) props['reverse'] = reverse;
    return {
      'type': ctx.jsString('SingleChildScrollView'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// Wrap：children + spacing/runSpacing/direction/alignment/runAlignment/
/// crossAxisAlignment。
class WrapTranslator extends WidgetTranslator {
  const WrapTranslator();

  @override
  String get type => 'Wrap';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = ctx.listArg(node.args, 'children', node.type);
    final props = <String, dynamic>{};
    for (final name in ['spacing', 'runSpacing']) {
      final v = _numOf(ctx.namedArg(node.args, name));
      if (v != null) props[name] = v;
    }
    final direction = axisToJson(ctx.namedArg(node.args, 'direction'));
    if (direction != null) props['direction'] = direction;
    final alignment = wrapAlignmentToJson(ctx.namedArg(node.args, 'alignment'));
    if (alignment != null) props['alignment'] = alignment;
    final runAlignment =
        wrapAlignmentToJson(ctx.namedArg(node.args, 'runAlignment'));
    if (runAlignment != null) props['runAlignment'] = runAlignment;
    final cross =
        wrapCrossAlignmentToJson(ctx.namedArg(node.args, 'crossAxisAlignment'));
    if (cross != null) props['crossAxisAlignment'] = cross;
    return {
      'type': ctx.jsString('Wrap'),
      if (props.isNotEmpty) 'props': props,
      'children': [for (final c in children) ctx.translateElement(c)],
    };
  }
}

// ===========================================================================
// 内容类
// ===========================================================================

/// Icon：Icons.xxx → icon 名，+ size/color。
class IconTranslator extends WidgetTranslator {
  const IconTranslator();

  @override
  String get type => 'Icon';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final iconExpr = ctx.namedArg(node.args, 'icon') ?? ctx.nonNamedArg(node.args);
    final icon = iconDataToJson(iconExpr);
    if (icon == null) throw FormatException('Icon 需要 Icons.xxx');
    final props = <String, dynamic>{'icon': icon};
    final size = _numOf(ctx.namedArg(node.args, 'size'));
    if (size != null) props['size'] = size;
    final color = colorToJson(ctx.namedArg(node.args, 'color'), ctx);
    if (color != null) props['color'] = color;
    return {'type': ctx.jsString('Icon'), 'props': props};
  }
}

/// Image：Image.asset / Image.network → source + width/height/fit/color/
/// colorBlendMode/alignment/repeat。
class ImageTranslator extends WidgetTranslator {
  const ImageTranslator();

  @override
  String get type => 'Image';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    // Image.asset('x') / Image.network('url')：MethodInvocation（ctor=asset/network）
    final source = imageSourceToJson(
      ctx.namedArg(node.args, 'image') ?? ctx.nonNamedArg(node.args),
      ctx,
    );
    if (source == null) throw FormatException('Image 需要 asset/network 源');
    final props = <String, dynamic>{'source': source};
    for (final name in ['width', 'height']) {
      final v = _numOf(ctx.namedArg(node.args, name));
      if (v != null) props[name] = v;
    }
    final fit = boxFitToJson(ctx.namedArg(node.args, 'fit'));
    if (fit != null) props['fit'] = fit;
    final color = colorToJson(ctx.namedArg(node.args, 'color'), ctx);
    if (color != null) props['color'] = color;
    final blend = blendModeToJson(ctx.namedArg(node.args, 'colorBlendMode'));
    if (blend != null) props['colorBlendMode'] = blend;
    final align = alignmentToJson(ctx.namedArg(node.args, 'alignment'), ctx);
    if (align != null) props['alignment'] = align;
    final repeat = imageRepeatToJson(ctx.namedArg(node.args, 'repeat'));
    if (repeat != null) props['repeat'] = repeat;
    return {'type': ctx.jsString('Image'), 'props': props};
  }
}

/// CircleAvatar：radius/backgroundColor/foregroundColor/backgroundImage/
/// minRadius/maxRadius + 可选 child。
class CircleAvatarTranslator extends WidgetTranslator {
  const CircleAvatarTranslator();

  @override
  String get type => 'CircleAvatar';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    for (final name in ['radius', 'minRadius', 'maxRadius']) {
      final v = _numOf(ctx.namedArg(node.args, name));
      if (v != null) props[name] = v;
    }
    final color = colorToJson(ctx.namedArg(node.args, 'backgroundColor'), ctx);
    if (color != null) props['backgroundColor'] = color;
    final fg = colorToJson(ctx.namedArg(node.args, 'foregroundColor'), ctx);
    if (fg != null) props['foregroundColor'] = fg;
    final bgImage = imageSourceToJson(
        ctx.namedArg(node.args, 'backgroundImage'), ctx);
    if (bgImage != null) props['backgroundImage'] = bgImage;
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    return {
      'type': ctx.jsString('CircleAvatar'),
      if (props.isNotEmpty) 'props': props,
      if (child != null) 'children': [ctx.translate(child)],
    };
  }
}

// ===========================================================================
// 交互类
// ===========================================================================

/// InkWell：onTap/onLongPress/onDoubleTap → 事件 + 圆角/水波纹颜色 + 单子。
class InkWellTranslator extends WidgetTranslator {
  const InkWellTranslator();

  @override
  String get type => 'InkWell';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final onTap = ctx.namedArg(node.args, 'onTap');
    final onLongPress = ctx.namedArg(node.args, 'onLongPress');
    final onDoubleTap = ctx.namedArg(node.args, 'onDoubleTap');
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('InkWell 需要 child');
    final props = <String, dynamic>{};
    if (onTap != null) props['event'] = ctx.eventHandle(onTap);
    if (onLongPress != null) props['onLongPress'] = ctx.eventHandle(onLongPress);
    if (onDoubleTap != null) props['onDoubleTap'] = ctx.eventHandle(onDoubleTap);
    if (props.isEmpty) throw FormatException('InkWell 需要至少一个事件');
    final brExpr = ctx.namedArg(node.args, 'borderRadius');
    if (brExpr != null) {
      final r = ctx.borderRadiusExpr(brExpr);
      if (r != null) props['borderRadius'] = r;
    }
    final splash = colorToJson(ctx.namedArg(node.args, 'splashColor'), ctx);
    if (splash != null) props['splashColor'] = splash;
    final highlight =
        colorToJson(ctx.namedArg(node.args, 'highlightColor'), ctx);
    if (highlight != null) props['highlightColor'] = highlight;
    return {
      'type': ctx.jsString('InkWell'),
      'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// GestureDetector：onTap/onLongPress/onDoubleTap + behavior + 单子。
class GestureDetectorTranslator extends WidgetTranslator {
  const GestureDetectorTranslator();

  @override
  String get type => 'GestureDetector';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final onTap = ctx.namedArg(node.args, 'onTap');
    final onLongPress = ctx.namedArg(node.args, 'onLongPress');
    final onDoubleTap = ctx.namedArg(node.args, 'onDoubleTap');
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('GestureDetector 需要 child');
    final props = <String, dynamic>{};
    if (onTap != null) props['event'] = ctx.eventHandle(onTap);
    if (onLongPress != null) props['onLongPress'] = ctx.eventHandle(onLongPress);
    if (onDoubleTap != null) props['onDoubleTap'] = ctx.eventHandle(onDoubleTap);
    if (props.isEmpty) {
      throw FormatException('GestureDetector 需要至少一个事件');
    }
    final behavior = hitTestBehaviorToJson(ctx.namedArg(node.args, 'behavior'));
    if (behavior != null) props['behavior'] = behavior;
    return {
      'type': ctx.jsString('GestureDetector'),
      'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// Switch：value（状态字段/字面量）+ onChanged（带值事件）+ 轨道/滑块颜色。
class SwitchTranslator extends WidgetTranslator {
  const SwitchTranslator();

  @override
  String get type => 'Switch';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final value = ctx.namedArg(node.args, 'value');
    final onChanged = ctx.namedArg(node.args, 'onChanged');
    if (value == null || onChanged == null) {
      throw FormatException('Switch 需要 value + onChanged');
    }
    final props = <String, dynamic>{
      'value': ctx.propExpr(value),
      'event': ctx.eventHandle(onChanged),
    };
    for (final name in [
      'activeColor',
      'activeTrackColor',
      'inactiveThumbColor',
      'inactiveTrackColor',
    ]) {
      final c = colorToJson(ctx.namedArg(node.args, name), ctx);
      if (c != null) props[name] = c;
    }
    return {'type': ctx.jsString('Switch'), 'props': props};
  }
}

/// Checkbox：value + onChanged（带值事件）+ activeColor/checkColor/tristate。
class CheckboxTranslator extends WidgetTranslator {
  const CheckboxTranslator();

  @override
  String get type => 'Checkbox';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final value = ctx.namedArg(node.args, 'value');
    final onChanged = ctx.namedArg(node.args, 'onChanged');
    if (value == null || onChanged == null) {
      throw FormatException('Checkbox 需要 value + onChanged');
    }
    final props = <String, dynamic>{
      'value': ctx.propExpr(value),
      'event': ctx.eventHandle(onChanged),
    };
    final active = colorToJson(ctx.namedArg(node.args, 'activeColor'), ctx);
    if (active != null) props['activeColor'] = active;
    final check = colorToJson(ctx.namedArg(node.args, 'checkColor'), ctx);
    if (check != null) props['checkColor'] = check;
    final tristate = _boolOf(ctx.namedArg(node.args, 'tristate'));
    if (tristate != null) props['tristate'] = tristate;
    return {'type': ctx.jsString('Checkbox'), 'props': props};
  }
}

/// Slider：value + min/max + divisions/label/颜色 + onChanged（带值事件）。
class SliderTranslator extends WidgetTranslator {
  const SliderTranslator();

  @override
  String get type => 'Slider';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final value = ctx.namedArg(node.args, 'value');
    final onChanged = ctx.namedArg(node.args, 'onChanged');
    if (value == null || onChanged == null) {
      throw FormatException('Slider 需要 value + onChanged');
    }
    final props = <String, dynamic>{
      'value': ctx.propExpr(value),
      'event': ctx.eventHandle(onChanged),
    };
    for (final name in ['min', 'max']) {
      final v = _numOf(ctx.namedArg(node.args, name));
      if (v != null) props[name] = v;
    }
    final divisions = _numOf(ctx.namedArg(node.args, 'divisions'));
    if (divisions != null) props['divisions'] = divisions;
    final label = ctx.namedArg(node.args, 'label');
    if (label is SimpleStringLiteral) props['label'] = ctx.jsString(label.value);
    final active = colorToJson(ctx.namedArg(node.args, 'activeColor'), ctx);
    if (active != null) props['activeColor'] = active;
    final inactive = colorToJson(ctx.namedArg(node.args, 'inactiveColor'), ctx);
    if (inactive != null) props['inactiveColor'] = inactive;
    return {'type': ctx.jsString('Slider'), 'props': props};
  }
}

// ---------------------------------------------------------------------------
// 响应式：ListenableBuilder（与 ChangeNotifier 配套，见 sdkSuperClassMap）
// ---------------------------------------------------------------------------

/// ListenableBuilder：`ListenableBuilder(listenable: _model, builder: (c,_) => Text(...))`。
///
/// 闭包返回的子树抽到组件方法 `_lbBuilderN()`（ctx.builderTrees 收集），节点
/// props 只引用 `listenable`（模型成员名）与 `builder`（方法名）。运行时把
/// builder 包装为 Flutter ListenableBuilder，模型 notify 后重新调用
/// `_lbBuilderN()` 拿到最新子树，做「仅此节点」的局部重建（不全量 setState）。
class ListenableBuilderTranslator extends WidgetTranslator {
  const ListenableBuilderTranslator();

  @override
  String get type => 'ListenableBuilder';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final listenable = ctx.namedArg(node.args, 'listenable');
    final builderFn = ctx.namedArg(node.args, 'builder');
    if (listenable == null || builderFn == null) {
      throw FormatException('ListenableBuilder 需要 listenable 与 builder');
    }
    Expression? inner;
    if (builderFn is FunctionExpression) inner = ctx.functionInner(builderFn);
    if (inner == null) {
      throw FormatException('ListenableBuilder.builder 需为返回 widget 的闭包');
    }
    // 目前 listenable 限定为模型状态字段（如 `_model`），运行时取成员名。
    if (listenable is! Identifier) {
      throw FormatException('ListenableBuilder.listenable 需为模型状态字段（如 _model）');
    }
    final listenableRef = ctx.propOf(listenable);
    // 闭包返回的子树翻译并登记，序号即方法名后缀。
    final subtree = ctx.translate(inner);
    ctx.builderTrees.add(subtree);
    final idx = ctx.builderTrees.length - 1;
    ctx.builderNames.add('_lbBuilder$idx');
    ctx.builderParams.add(null);
    return {
      'type': ctx.jsString('ListenableBuilder'),
      'props': {
        'listenable': ctx.jsString(listenableRef),
        'builder': ctx.jsString('_lbBuilder$idx'),
      },
    };
  }
}

/// Builder：`Builder(builder: (context) => ...)` —— 多一层 context 作用域，
/// 闭包内 `context.watch<T>()` / `context.read<T>()` 可用（翻译成
/// `this.__watch('T')` / `this.__read('T')`，运行时挂载在实例上）。
///
/// 闭包返回的子树抽到组件方法 `_builderN()`（与 ListenableBuilder 同机制，
/// 但无订阅——Builder 本身无 listenable；watch 订阅由 __watch 内部处理）。
/// 块体闭包支持：return 前允许局部变量声明（`final model = ...` → 方法体
/// 前置 `var model = ...;`）与日志语句（debugPrint/print → console 方法）。
class BuilderTranslator extends WidgetTranslator {
  const BuilderTranslator();

  @override
  String get type => 'Builder';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final builderFn = ctx.namedArg(node.args, 'builder');
    if (builderFn is! FunctionExpression) {
      throw FormatException('Builder 需要 builder 闭包');
    }
    final body = builderFn.body;
    Expression? retExpr;
    final preludes = <String>[];
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
            ctx.addLocal(v.name.lexeme);
            // `final model = context.watch<T>()`：登记局部 → 模型类型，
            // 事件表达式（`() => model.inc()`）据此翻译成 this.__read('T')。
            final mt = _contextModelTypeOf(v.initializer);
            if (mt != null) ctx.addLocalModel(v.name.lexeme, mt);
            final js = v.initializer == null
                ? 'undefined'
                : ctx.jsDataExpr(v.initializer!);
            preludes.add('var ${v.name.lexeme} = $js;');
          }
        } else if (st is ExpressionStatement) {
          final ex = st.expression;
          if (ex is MethodInvocation && ex.target == null) {
            final name = ex.methodName.name;
            if (name == 'debugPrint' || name == 'print') {
              final args = ex.argumentList.arguments;
              final argJs = args.isEmpty ? '""' : ctx.jsDataExpr(args.first);
              preludes.add(
                  'console.${name == 'debugPrint' ? 'debug' : 'log'}($argJs);');
            }
          }
        }
      }
    }
    if (retExpr == null) {
      throw FormatException('Builder.builder 需返回 widget 树');
    }
    final subtree = ctx.translate(retExpr);
    ctx.builderTrees.add(subtree);
    final idx = ctx.builderTrees.length - 1;
    ctx.builderNames.add('_builder$idx');
    ctx.builderParams.add(null);
    ctx.builderPreludes.add(preludes.isEmpty ? '' : preludes.join(' '));
    return {
      'type': ctx.jsString('Builder'),
      'props': {'builder': ctx.jsString('_builder$idx')},
    };
  }
}

// ---------------------------------------------------------------------------
// provider 包：ChangeNotifierProvider / Consumer（与 ListenableBuilder 同机制）
// ---------------------------------------------------------------------------

/// ChangeNotifierProvider：`ChangeNotifierProvider\<MyModel\>(
///   create: (_) => _model, child: ...)`。
///
/// 节点 `{type:'ChangeNotifierProvider', props:{model:'MyModel',
/// create:{ref|construct}, child:子树}}`。模型实例由运行时按 create 语义
/// 提供：ref = 复用状态字段实例（与 ListenableBuilder 的 listenable 同语义，
/// 方法 _inc/_reset 操作同一实例）；construct = JS 侧 new 模型类。
/// child 子树由运行时在 Provider 作用域（`__providers[key][model]`）下渲染。
class ChangeNotifierProviderTranslator extends WidgetTranslator {
  const ChangeNotifierProviderTranslator();

  @override
  String get type => 'ChangeNotifierProvider';

  /// provider 包：模块产物落到 assets/provider.js。
  @override
  String get packageName => 'provider';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final modelType = _providerTypeArg(node.expr);
    if (modelType == null) {
      throw FormatException(
          'ChangeNotifierProvider 需要类型参数，如 ChangeNotifierProvider<MyModel>');
    }
    final childExpr =
        ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    // 命名构造 `ChangeNotifierProvider.value(value: _model, child: ...)`：
    // value 复用既有实例、生命周期归调用方 → 与 create 的 ref 同语义
    // （运行时标 __dispose:false，不随 renderer 释放）。
    final ctorName = _constructorNameOf(node.expr);
    if (ctorName == 'value') {
      final value = ctx.namedArg(node.args, 'value');
      if (value == null || childExpr == null) {
        throw FormatException(
            'ChangeNotifierProvider.value 需要 value 与 child');
      }
      return _providerNodeOf(
        modelType: modelType,
        createExpr: value,
        child: ctx.translate(childExpr),
        ctx: ctx,
        sourceKey: 'value',
      );
    }
    final create = ctx.namedArg(node.args, 'create');
    if (create == null || childExpr == null) {
      throw FormatException('ChangeNotifierProvider 需要 create 与 child');
    }
    final child = ctx.translate(childExpr);
    return _providerNodeOf(
      modelType: modelType,
      createExpr: create,
      child: child,
      ctx: ctx,
    );
  }
}

/// 取命名构造函数名（`.value` 等）：
/// - `InstanceCreationExpression`：`constructorName.name`（命名构造名）；
/// - 无 const 的 `Foo.bar(...)` 调用可能被解析为 `MethodInvocation`，
///   `methodName` 即后缀部分（`.bar`）。
/// 注意 `WidgetNode.expr` 是 `Expression?`，而 `constructorName` 只定义在
/// `InstanceCreationExpression` 上，不能直接 `node.expr.constructorName`。
String? _constructorNameOf(Expression? e) {
  if (e is InstanceCreationExpression) {
    return e.constructorName.name?.name;
  }
  if (e is MethodInvocation) return e.methodName.name;
  return null;
}

/// 解析一个 `ChangeNotifierProvider<T>(create: ...)` → provider 节点 Map
/// （不含 child，由调用方拼装）。ChangeNotifierProvider / MultiProvider 共用。
///
/// 产出的 props 值直接是**运行时可见的 JS 值**（不是 ID/名称字符串）：
///   - create = 模型**类引用**（裸标识符，如 `MyModel`）：provider 内
///     `new` 一次，生命周期归 provider（卸载 dispose）；
///   - create = 模型**实例**（状态字段 `this._modelA`）：复用，归调用方；
///   - value  = 模型实例：复用、不释放（与原生 .value 语义一致）。
/// provider JS 组件按 `typeof create === 'function'` 区分「类」与「实例」。
Map<String, dynamic> _providerNodeOf({
  required String modelType,
  required Expression createExpr,
  required Object? child,
  required WidgetTranslateContext ctx,
  String sourceKey = 'create',
}) {
  final inner = createExpr is FunctionExpression
      ? ctx.functionInner(createExpr)
      : createExpr;
  final Object createJs;
  if (inner is Identifier) {
    // `create: (_) => _modelA`：复用状态字段实例（this._modelA）。
    createJs = ctx.jsDataExpr(inner);
  } else if (inner is InstanceCreationExpression) {
    createJs = inner.constructorName.type.name2.lexeme;
  } else if (inner is MethodInvocation && inner.target == null) {
    // 无 const 的 `ModelClass()` 在 parseString 下是 MethodInvocation。
    createJs = inner.methodName.name;
  } else {
    throw FormatException(
        'ChangeNotifierProvider.create 仅支持返回状态字段或模型构造');
  }
  final props = <String, Object?>{
    'model': ctx.jsString(modelType),
    sourceKey: createJs,
  };
  if (child != null) props['child'] = child;
  return {
    'type': ctx.jsString('ChangeNotifierProvider'),
    'props': props,
  };
}

/// Consumer：`Consumer\<MyModel\>(builder: (context, value, child) =>
///   Text('count = ${value.count}'))`。
///
/// builder 闭包返回的子树抽到实例方法 `_consumerBuilderN(value)`（闭包参数
/// value 注册为局部变量，子树里 `value.count` 原样翻译），运行时从
/// `__providers[key][model]` 取模型实例传入，挂监听后 notify →
/// lbNotify → 仅该节点局部重建（与 ListenableBuilder 同一回调表）。
class ConsumerTranslator extends WidgetTranslator {
  const ConsumerTranslator();

  @override
  String get type => 'Consumer';

  /// provider 包：模块产物落到 assets/provider.js。
  @override
  String get packageName => 'provider';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final modelType = _providerTypeArg(node.expr);
    if (modelType == null) {
      throw FormatException('Consumer 需要类型参数，如 Consumer<MyModel>');
    }
    final builderRaw = ctx.namedArg(node.args, 'builder');
    if (builderRaw is! FunctionExpression) {
      throw FormatException('Consumer.builder 需为返回 widget 的闭包');
    }
    final params = builderRaw.parameters?.parameters ?? const <FormalParameter>[];
    final valueName = params.length >= 2 ? params[1].name?.lexeme : null;
    if (valueName == null) {
      throw FormatException(
          'Consumer.builder 需要 (context, value[, child]) 参数');
    }
    final inner = ctx.functionInner(builderRaw);
    if (inner == null) {
      throw FormatException('Consumer.builder 闭包需返回 widget');
    }
    // value 闭包参数注册为局部变量：子树里 value.count 原样翻译
    ctx.addLocal(valueName);
    final subtree = ctx.translate(inner);
    ctx.builderTrees.add(subtree);
    final idx = ctx.builderTrees.length - 1;
    ctx.builderNames.add('_consumerBuilder$idx');
    ctx.builderParams.add(valueName);
    return {
      'type': ctx.jsString(type),
      'props': {
        'model': ctx.jsString(modelType),
        'builder': ctx.jsString('_consumerBuilder$idx'),
      },
    };
  }
}

/// MultiProvider：`MultiProvider(providers: [ChangeNotifierProvider\<A\>(create:
/// ...), ChangeNotifierProvider\<B\>(create: ...)], child: ...)`。
///
/// **一一对应生成一个 `MultiProvider` 节点**：providers 保持平级数组
/// （与 Dart 源码结构一致），每个条目是一个 ChangeNotifierProvider 节点
/// （仅 model + create，无 child）。运行时 MultiProviderRenderer 把所有
/// 条目模型按 key 登记进 `__providerChain`（栈），Consumer 按「最近」取
/// 实例（与原生 MultiProvider 的嵌套 Provider.of 语义一致）。
/// 新增 provider 类型（Provider/ListenableProvider 等）只需扩展该解析。
class MultiProviderTranslator extends WidgetTranslator {
  const MultiProviderTranslator();

  @override
  String get type => 'MultiProvider';

  /// provider 包：模块产物落到 assets/provider.js。
  @override
  String get packageName => 'provider';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final providersArg = ctx.namedArg(node.args, 'providers');
    final childExpr =
        ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (providersArg is! ListLiteral || childExpr == null) {
      throw FormatException('MultiProvider 需要 providers 列表与 child');
    }
    final childNode = ctx.translate(childExpr);
    final providers = <Object>[
      for (final raw in providersArg.elements) _providerEntryOf(raw, ctx),
    ];
    return {
      'type': ctx.jsString(type),
      'props': {
        'providers': providers,
        'child': childNode,
      },
    };
  }
}

/// MultiProvider 条目 → ChangeNotifierProvider 节点（model + create，无
/// child；条目在 providers 数组中保持平级）。
Map<String, dynamic> _providerEntryOf(
    CollectionElement raw, WidgetTranslateContext ctx) {
  final Expression element;
  if (raw is InstanceCreationExpression || raw is MethodInvocation) {
    element = raw as Expression;
  } else {
    throw FormatException(
        'MultiProvider.providers 仅支持 ChangeNotifierProvider 条目');
  }
  final modelType = _providerTypeArg(element);
  if (modelType == null) {
    throw FormatException('MultiProvider 条目需要类型参数，如 <MyModel>');
  }
  // 条目为 `ChangeNotifierProvider.value(value: x)`：value 复用实例、
  // 生命周期归调用方 → 与 create 的 ref 同语义（不释放）。
  final ctorName = _constructorNameOf(element);
  if (ctorName == 'value') {
    final value = _namedOf(_callArgs(element), 'value');
    if (value == null) {
      throw FormatException('ChangeNotifierProvider.value 需要 value');
    }
    return _providerNodeOf(
      modelType: modelType,
      createExpr: value,
      child: null,
      ctx: ctx,
      sourceKey: 'value',
    );
  }
  final create = _namedOf(_callArgs(element), 'create');
  if (create == null) {
    throw FormatException('ChangeNotifierProvider 需要 create');
  }
  return _providerNodeOf(
    modelType: modelType,
    createExpr: create,
    child: null,
    ctx: ctx,
  );
}

/// 构造调用参数列表（InstanceCreationExpression / MethodInvocation 共用）。
List<Expression> _callArgs(Expression e) {
  if (e is InstanceCreationExpression) return e.argumentList.arguments.toList();
  if (e is MethodInvocation) return e.argumentList.arguments.toList();
  return const [];
}

/// 从参数列表取具名参数表达式（entry 解析用，等价 ctx.namedArg）。
Expression? _namedOf(List<Expression> args, String name) {
  for (final a in args) {
    if (a is NamedExpression && a.name.label.name == name) {
      final e = a.expression;
      return e is ParenthesizedExpression ? e.unParenthesized : e;
    }
  }
  return null;
}

/// `context.watch\<T\>()` / `context.read\<T\>()` 的类型参数类名
/// （如 `MyModel`；null = 非此形态）。
String? _contextModelTypeOf(Expression? e) {
  if (e is! MethodInvocation) return null;
  final tgt = e.target;
  if (tgt is! Identifier || tgt.name != 'context') return null;
  final name = e.methodName.name;
  if (name != 'watch' && name != 'read') return null;
  final ta = e.typeArguments?.arguments;
  if (ta != null && ta.length == 1 && ta.first is NamedType) {
    return (ta.first as NamedType).name2.lexeme;
  }
  return null;
}

/// `ChangeNotifierProvider\<T\>` / `Consumer\<T\>` 的类型参数 T 类名
/// （如 `MyModel`；null = 未提供类型参数）。
String? _providerTypeArg(Expression? e) {
  // 有 new：InstanceCreationExpression；无 new 的泛型类构造（如
  // `Consumer<MyModel>(...)` / `ChangeNotifierProvider<MyModel>(...)`）
  // 在 analyzer 里是 MethodInvocation —— 两者的类型参数都要处理。
  final TypeArgumentList? ta;
  if (e is InstanceCreationExpression) {
    ta = e.constructorName.type.typeArguments;
  } else if (e is MethodInvocation) {
    ta = e.typeArguments;
  } else {
    return null;
  }
  if (ta != null && ta.arguments.isNotEmpty) {
    final t = ta.arguments.first;
    if (t is NamedType) return t.name2.lexeme;
  }
  return null;
}

/// 数字字面量 → JS 数字表达式（'12' / '1.5'）；非字面量返回 null。
String? _numOf(Expression? e) {
  if (e is IntegerLiteral && e.value != null) return '${e.value}';
  if (e is DoubleLiteral) return '${e.value}';
  return null;
}

/// bool 字面量 → 'true' / 'false'。
String? _boolOf(Expression? e) {
  if (e is BooleanLiteral) return e.value ? 'true' : 'false';
  return null;
}

// ===========================================================================
// 补齐组件：布局 / 装饰 / 指示器 / 输入 / 导航
// ===========================================================================

/// Spacer：Row/Column 内弹性空隙（flex）。
class SpacerTranslator extends WidgetTranslator {
  const SpacerTranslator();

  @override
  String get type => 'Spacer';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    final flex = _numOf(ctx.namedArg(node.args, 'flex'));
    if (flex != null) props['flex'] = flex;
    return {
      'type': ctx.jsString('Spacer'),
      if (props.isNotEmpty) 'props': props,
    };
  }
}

/// SafeArea：单子 + 四边开关。
class SafeAreaTranslator extends WidgetTranslator {
  const SafeAreaTranslator();

  @override
  String get type => 'SafeArea';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('SafeArea 缺少 child');
    final props = <String, dynamic>{};
    for (final name in ['left', 'top', 'right', 'bottom']) {
      final b = _boolOf(ctx.namedArg(node.args, name));
      if (b != null) props[name] = b;
    }
    return {
      'type': ctx.jsString('SafeArea'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// Opacity：透明度 + 单子。
class OpacityTranslator extends WidgetTranslator {
  const OpacityTranslator();

  @override
  String get type => 'Opacity';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('Opacity 缺少 child');
    final opacity = _numOf(ctx.namedArg(node.args, 'opacity'));
    if (opacity == null) throw FormatException('Opacity 需要 opacity 字面量');
    return {
      'type': ctx.jsString('Opacity'),
      'props': {'opacity': opacity},
      'children': [ctx.translate(child)],
    };
  }
}

/// ConstrainedBox：constraints + 单子。
class ConstrainedBoxTranslator extends WidgetTranslator {
  const ConstrainedBoxTranslator();

  @override
  String get type => 'ConstrainedBox';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('ConstrainedBox 缺少 child');
    final constraints =
        boxConstraintsToJson(ctx.namedArg(node.args, 'constraints'), ctx);
    if (constraints == null) {
      throw FormatException('ConstrainedBox 需要 constraints');
    }
    return {
      'type': ctx.jsString('ConstrainedBox'),
      'props': {'constraints': constraints},
      'children': [ctx.translate(child)],
    };
  }
}

/// AspectRatio：宽高比 + 单子。
class AspectRatioTranslator extends WidgetTranslator {
  const AspectRatioTranslator();

  @override
  String get type => 'AspectRatio';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('AspectRatio 缺少 child');
    final ratio = _numOf(ctx.namedArg(node.args, 'aspectRatio'));
    if (ratio == null) {
      throw FormatException('AspectRatio 需要 aspectRatio 字面量');
    }
    return {
      'type': ctx.jsString('AspectRatio'),
      'props': {'aspectRatio': ratio},
      'children': [ctx.translate(child)],
    };
  }
}

/// FractionallySizedBox：宽高因子 + alignment + 单子。
class FractionallySizedBoxTranslator extends WidgetTranslator {
  const FractionallySizedBoxTranslator();

  @override
  String get type => 'FractionallySizedBox';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) {
      throw FormatException('FractionallySizedBox 缺少 child');
    }
    final props = <String, dynamic>{};
    final wf = _numOf(ctx.namedArg(node.args, 'widthFactor'));
    if (wf != null) props['widthFactor'] = wf;
    final hf = _numOf(ctx.namedArg(node.args, 'heightFactor'));
    if (hf != null) props['heightFactor'] = hf;
    final align = alignmentToJson(ctx.namedArg(node.args, 'alignment'), ctx);
    if (align != null) props['alignment'] = align;
    return {
      'type': ctx.jsString('FractionallySizedBox'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// DecoratedBox：decoration + 单子（无尺寸/内边距逻辑的纯装饰容器）。
class DecoratedBoxTranslator extends WidgetTranslator {
  const DecoratedBoxTranslator();

  @override
  String get type => 'DecoratedBox';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('DecoratedBox 缺少 child');
    final deco =
        boxDecorationToJson(ctx.namedArg(node.args, 'decoration'), ctx);
    if (deco == null) throw FormatException('DecoratedBox 需要 decoration');
    return {
      'type': ctx.jsString('DecoratedBox'),
      'props': {'decoration': deco},
      'children': [ctx.translate(child)],
    };
  }
}

/// CircularProgressIndicator：value/color/backgroundColor/strokeWidth。
class CircularProgressIndicatorTranslator extends WidgetTranslator {
  const CircularProgressIndicatorTranslator();

  @override
  String get type => 'CircularProgressIndicator';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    final v = _numOf(ctx.namedArg(node.args, 'value'));
    if (v != null) props['value'] = v;
    final c = colorToJson(ctx.namedArg(node.args, 'color'), ctx);
    if (c != null) props['color'] = c;
    final bg = colorToJson(ctx.namedArg(node.args, 'backgroundColor'), ctx);
    if (bg != null) props['backgroundColor'] = bg;
    final sw = _numOf(ctx.namedArg(node.args, 'strokeWidth'));
    if (sw != null) props['strokeWidth'] = sw;
    return {
      'type': ctx.jsString('CircularProgressIndicator'),
      if (props.isNotEmpty) 'props': props,
    };
  }
}

/// LinearProgressIndicator：value/color/backgroundColor/minHeight。
class LinearProgressIndicatorTranslator extends WidgetTranslator {
  const LinearProgressIndicatorTranslator();

  @override
  String get type => 'LinearProgressIndicator';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    final v = _numOf(ctx.namedArg(node.args, 'value'));
    if (v != null) props['value'] = v;
    final c = colorToJson(ctx.namedArg(node.args, 'color'), ctx);
    if (c != null) props['color'] = c;
    final bg = colorToJson(ctx.namedArg(node.args, 'backgroundColor'), ctx);
    if (bg != null) props['backgroundColor'] = bg;
    final mh = _numOf(ctx.namedArg(node.args, 'minHeight'));
    if (mh != null) props['minHeight'] = mh;
    return {
      'type': ctx.jsString('LinearProgressIndicator'),
      if (props.isNotEmpty) 'props': props,
    };
  }
}

/// TextField：受控输入（value 状态字段 + onChanged 带值事件）+
/// hintText/labelText/obscureText/keyboardType/maxLines/enabled/style/textAlign。
///
/// 产物无 controller（JS 侧不持有 TextEditingController），运行时
/// _JsTextField 内部受控封装：value 变化同步 controller，onChanged 回传文本。
class TextFieldTranslator extends WidgetTranslator {
  const TextFieldTranslator();

  @override
  String get type => 'TextField';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final onChanged = ctx.namedArg(node.args, 'onChanged');
    if (onChanged == null) {
      throw FormatException('TextField 需要 onChanged');
    }
    final props = <String, dynamic>{
      'event': ctx.eventHandle(onChanged),
    };
    final value = ctx.namedArg(node.args, 'value');
    if (value != null) props['value'] = ctx.propExpr(value);
    // hintText/labelText：支持顶层直传与 decoration: InputDecoration(...) 两种形态。
    String? decName(String name) {
      final direct = ctx.namedArg(node.args, name);
      if (direct is SimpleStringLiteral) return direct.value;
      final deco = ctx.namedArg(node.args, 'decoration');
      if (deco != null) {
        final (ctor, dArgs) = ctx.ctorOf(deco);
        if (ctor == 'InputDecoration') {
          final v = ctx.namedArg(dArgs, name);
          if (v is SimpleStringLiteral) return v.value;
        }
      }
      return null;
    }

    for (final name in ['hintText', 'labelText']) {
      final v = decName(name);
      if (v != null) props[name] = ctx.jsString(v);
    }
    final obscure = _boolOf(ctx.namedArg(node.args, 'obscureText'));
    if (obscure != null) props['obscureText'] = obscure;
    final enabled = _boolOf(ctx.namedArg(node.args, 'enabled'));
    if (enabled != null) props['enabled'] = enabled;
    final keyboard =
        textInputTypeToJson(ctx.namedArg(node.args, 'keyboardType'));
    if (keyboard != null) props['keyboardType'] = keyboard;
    final maxLines = _numOf(ctx.namedArg(node.args, 'maxLines'));
    if (maxLines != null) props['maxLines'] = maxLines;
    final style = textStyleToJson(ctx.namedArg(node.args, 'style'), ctx);
    if (style != null) props['style'] = style;
    final alignExpr = ctx.namedArg(node.args, 'textAlign');
    if (alignExpr != null) {
      final align = enumName(alignExpr, 'TextAlign');
      if (align != null) props['textAlign'] = ctx.jsString(align);
    }
    return {'type': ctx.jsString('TextField'), 'props': props};
  }
}

/// IconButton：icon（element prop）+ onPressed + color/iconSize/tooltip。
class IconButtonTranslator extends WidgetTranslator {
  const IconButtonTranslator();

  @override
  String get type => 'IconButton';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final onPressed = ctx.namedArg(node.args, 'onPressed');
    final icon = ctx.namedArg(node.args, 'icon');
    if (icon == null) throw FormatException('IconButton 需要 icon');
    final props = <String, dynamic>{'icon': ctx.translate(icon)};
    // onPressed: null → 禁用（省略 event）
    if (onPressed != null && onPressed is! NullLiteral) {
      props['event'] = ctx.eventHandle(onPressed);
    }
    final color = colorToJson(ctx.namedArg(node.args, 'color'), ctx);
    if (color != null) props['color'] = color;
    final size = _numOf(ctx.namedArg(node.args, 'iconSize'));
    if (size != null) props['iconSize'] = size;
    final tooltip = ctx.namedArg(node.args, 'tooltip');
    if (tooltip is SimpleStringLiteral) {
      props['tooltip'] = ctx.jsString(tooltip.value);
    }
    return {'type': ctx.jsString('IconButton'), 'props': props};
  }
}

/// FloatingActionButton：child（element prop）+ onPressed +
/// backgroundColor/foregroundColor/mini/tooltip/elevation。
class FloatingActionButtonTranslator extends WidgetTranslator {
  const FloatingActionButtonTranslator();

  @override
  String get type => 'FloatingActionButton';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final onPressed = ctx.namedArg(node.args, 'onPressed');
    final child = ctx.namedArg(node.args, 'child');
    final props = <String, dynamic>{};
    if (child != null) props['child'] = ctx.translate(child);
    if (onPressed != null && onPressed is! NullLiteral) {
      props['event'] = ctx.eventHandle(onPressed);
    }
    final bg = colorToJson(ctx.namedArg(node.args, 'backgroundColor'), ctx);
    if (bg != null) props['backgroundColor'] = bg;
    final fg = colorToJson(ctx.namedArg(node.args, 'foregroundColor'), ctx);
    if (fg != null) props['foregroundColor'] = fg;
    final mini = _boolOf(ctx.namedArg(node.args, 'mini'));
    if (mini != null) props['mini'] = mini;
    final tooltip = ctx.namedArg(node.args, 'tooltip');
    if (tooltip is SimpleStringLiteral) {
      props['tooltip'] = ctx.jsString(tooltip.value);
    }
    final elevation = _numOf(ctx.namedArg(node.args, 'elevation'));
    if (elevation != null) props['elevation'] = elevation;
    return {'type': ctx.jsString('FloatingActionButton'), 'props': props};
  }
}

/// BottomNavigationBar：items（BottomNavigationBarItem 列表）→ children +
/// currentIndex（状态字段）+ onTap（带 index 值事件）+ 选中/未选中颜色。
class BottomNavigationBarTranslator extends WidgetTranslator {
  const BottomNavigationBarTranslator();

  @override
  String get type => 'BottomNavigationBar';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final items = ctx.namedArg(node.args, 'items');
    if (items is! ListLiteral) {
      throw FormatException('BottomNavigationBar 需要 items 列表');
    }
    final children = <Object?>[
      for (final el in items.elements) ctx.translateElement(el),
    ];
    final props = <String, dynamic>{};
    final currentIndex = ctx.namedArg(node.args, 'currentIndex');
    if (currentIndex != null) props['currentIndex'] = ctx.propExpr(currentIndex);
    final onTap = ctx.namedArg(node.args, 'onTap');
    if (onTap != null) props['event'] = ctx.eventHandle(onTap);
    final selected =
        colorToJson(ctx.namedArg(node.args, 'selectedItemColor'), ctx);
    if (selected != null) props['selectedItemColor'] = selected;
    final unselected =
        colorToJson(ctx.namedArg(node.args, 'unselectedItemColor'), ctx);
    if (unselected != null) props['unselectedItemColor'] = unselected;
    return {
      'type': ctx.jsString('BottomNavigationBar'),
      if (props.isNotEmpty) 'props': props,
      'children': children,
    };
  }
}

/// BottomNavigationBarItem：icon（element prop）+ label。
class BottomNavigationBarItemTranslator extends WidgetTranslator {
  const BottomNavigationBarItemTranslator();

  @override
  String get type => 'BottomNavigationBarItem';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final icon = ctx.namedArg(node.args, 'icon');
    if (icon == null) {
      throw FormatException('BottomNavigationBarItem 需要 icon');
    }
    final props = <String, dynamic>{'icon': ctx.translate(icon)};
    final label = ctx.namedArg(node.args, 'label');
    if (label is SimpleStringLiteral) props['label'] = ctx.jsString(label.value);
    return {'type': ctx.jsString('BottomNavigationBarItem'), 'props': props};
  }
}

/// Radio：value + groupValue（状态字段）+ onChanged（带值事件）+ activeColor。
class RadioTranslator extends WidgetTranslator {
  const RadioTranslator();

  @override
  String get type => 'Radio';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final value = ctx.namedArg(node.args, 'value');
    final groupValue = ctx.namedArg(node.args, 'groupValue');
    final onChanged = ctx.namedArg(node.args, 'onChanged');
    if (value == null || groupValue == null || onChanged == null) {
      throw FormatException('Radio 需要 value + groupValue + onChanged');
    }
    final props = <String, dynamic>{
      'value': ctx.propExpr(value),
      'groupValue': ctx.propExpr(groupValue),
      'event': ctx.eventHandle(onChanged),
    };
    final active = colorToJson(ctx.namedArg(node.args, 'activeColor'), ctx);
    if (active != null) props['activeColor'] = active;
    return {'type': ctx.jsString('Radio'), 'props': props};
  }
}

/// DropdownButton：value（状态字段）+ items（DropdownMenuItem 列表）→ children
/// + onChanged（带值事件）+ hint/isExpanded。
class DropdownButtonTranslator extends WidgetTranslator {
  const DropdownButtonTranslator();

  @override
  String get type => 'DropdownButton';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final value = ctx.namedArg(node.args, 'value');
    final items = ctx.namedArg(node.args, 'items');
    final onChanged = ctx.namedArg(node.args, 'onChanged');
    if (value == null || items is! ListLiteral || onChanged == null) {
      throw FormatException('DropdownButton 需要 value + items + onChanged');
    }
    final children = <Object?>[
      for (final el in items.elements) ctx.translateElement(el),
    ];
    final props = <String, dynamic>{
      'value': ctx.propExpr(value),
      'event': ctx.eventHandle(onChanged),
    };
    final hint = ctx.namedArg(node.args, 'hint');
    if (hint is SimpleStringLiteral) props['hint'] = ctx.jsString(hint.value);
    final isExpanded = _boolOf(ctx.namedArg(node.args, 'isExpanded'));
    if (isExpanded != null) props['isExpanded'] = isExpanded;
    return {
      'type': ctx.jsString('DropdownButton'),
      'props': props,
      'children': children,
    };
  }
}

/// DropdownMenuItem：value + child（Text）。
class DropdownMenuItemTranslator extends WidgetTranslator {
  const DropdownMenuItemTranslator();

  @override
  String get type => 'DropdownMenuItem';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final value = ctx.namedArg(node.args, 'value');
    final child = ctx.namedArg(node.args, 'child');
    if (value == null || child == null) {
      throw FormatException('DropdownMenuItem 需要 value 与 child');
    }
    final props = <String, dynamic>{'value': ctx.propExpr(value)};
    // child 限定 Text：提取纯文案
    final (ctor, args) = ctx.ctorOf(child);
    if (ctor == 'Text') {
      final data = ctx.namedArg(args, 'data') ?? ctx.positionalArg(args, 0);
      if (data != null) props['label'] = ctx.jsDataExpr(data);
    }
    return {'type': ctx.jsString('DropdownMenuItem'), 'props': props};
  }
}
