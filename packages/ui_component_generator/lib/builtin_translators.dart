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
    ..register(const SingleChildScrollViewTranslator())
    ..register(const WrapTranslator())
    // 内容
    ..register(const IconTranslator())
    ..register(const ImageTranslator())
    ..register(const CircleAvatarTranslator())
    // 交互
    ..register(const InkWellTranslator())
    ..register(const GestureDetectorTranslator())
    ..register(const SwitchTranslator())
    ..register(const CheckboxTranslator())
    ..register(const SliderTranslator())
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

/// Chip：标签（label + backgroundColor），无交互。
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
    return {'type': ctx.jsString('Chip'), 'props': props};
  }
}

/// ListTile：列表条目（leading/title/subtitle/trailing/onTap）。
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
    return {'type': ctx.jsString('ListTile'), 'props': props};
  }
}

/// ClipRRect：圆角裁剪（borderRadius + child）。
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

/// Scaffold：页面骨架（appBar / body）。
///
/// 产物把 appBar 与 body 依次放 children（children[0]=AppBar、children[1]=body），
/// 运行时 JsWidgetRegistry 按序取用，避免 props 里出现嵌套节点对象。
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
    return {'type': ctx.jsString('Scaffold'), 'children': children};
  }
}

/// AppBar：顶栏（title 单子）。
class AppBarTranslator extends WidgetTranslator {
  const AppBarTranslator();

  @override
  String get type => 'AppBar';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = <Object?>[];
    final title = ctx.namedArg(node.args, 'title');
    if (title != null) children.add(ctx.translate(title));
    return {'type': ctx.jsString('AppBar'), 'children': children};
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

/// Stack：children + alignment。
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

/// Container：width/height/color/padding/margin/alignment/decoration + 单子。
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

/// Card：child + elevation/margin/color。
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
    return {
      'type': ctx.jsString('Card'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// ListView：children 列表。
class ListViewTranslator extends WidgetTranslator {
  const ListViewTranslator();

  @override
  String get type => 'ListView';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = ctx.listArg(node.args, 'children', node.type);
    return {
      'type': ctx.jsString('ListView'),
      'children': [for (final c in children) ctx.translateElement(c)],
    };
  }
}

/// SingleChildScrollView：child + scrollDirection。
class SingleChildScrollViewTranslator extends WidgetTranslator {
  const SingleChildScrollViewTranslator();

  @override
  String get type => 'SingleChildScrollView';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (child == null) throw FormatException('SingleChildScrollView 缺少 child');
    final props = <String, dynamic>{};
    final axis = axisToJson(ctx.namedArg(node.args, 'scrollDirection'));
    if (axis != null) props['scrollDirection'] = axis;
    final padding = edgeInsetsToJson(ctx.namedArg(node.args, 'padding'), ctx);
    if (padding != null) props['padding'] = padding;
    return {
      'type': ctx.jsString('SingleChildScrollView'),
      if (props.isNotEmpty) 'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// Wrap：children + spacing/runSpacing。
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

/// Image：Image.asset / Image.network → source + width/height/fit。
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
    return {'type': ctx.jsString('Image'), 'props': props};
  }
}

/// CircleAvatar：radius/backgroundColor + 可选 child。
class CircleAvatarTranslator extends WidgetTranslator {
  const CircleAvatarTranslator();

  @override
  String get type => 'CircleAvatar';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    final r = _numOf(ctx.namedArg(node.args, 'radius'));
    if (r != null) props['radius'] = r;
    final color = colorToJson(ctx.namedArg(node.args, 'backgroundColor'), ctx);
    if (color != null) props['backgroundColor'] = color;
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

/// InkWell：onTap → 事件 + 单子。
class InkWellTranslator extends WidgetTranslator {
  const InkWellTranslator();

  @override
  String get type => 'InkWell';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final onTap = ctx.namedArg(node.args, 'onTap');
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (onTap == null || child == null) throw FormatException('InkWell 需要 onTap + child');
    final props = <String, dynamic>{'event': ctx.eventHandle(onTap)};
    return {
      'type': ctx.jsString('InkWell'),
      'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// GestureDetector：onTap → 事件 + 单子。
class GestureDetectorTranslator extends WidgetTranslator {
  const GestureDetectorTranslator();

  @override
  String get type => 'GestureDetector';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final onTap = ctx.namedArg(node.args, 'onTap');
    final child = ctx.namedArg(node.args, 'child') ?? ctx.nonNamedArg(node.args);
    if (onTap == null || child == null) {
      throw FormatException('GestureDetector 需要 onTap + child');
    }
    final props = <String, dynamic>{'event': ctx.eventHandle(onTap)};
    return {
      'type': ctx.jsString('GestureDetector'),
      'props': props,
      'children': [ctx.translate(child)],
    };
  }
}

/// Switch：value（状态字段/字面量）+ onChanged（带值事件）。
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
    return {'type': ctx.jsString('Switch'), 'props': props};
  }
}

/// Checkbox：value + onChanged（带值事件）。
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
    return {'type': ctx.jsString('Checkbox'), 'props': props};
  }
}

/// Slider：value + min/max + onChanged（带值事件）。
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
