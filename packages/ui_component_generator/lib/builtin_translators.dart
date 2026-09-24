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
/// 用 `ctx.jsString()` 带引号、数字/布尔/表达式原样），默认 renderJs
/// 由基类把 toJson 产物序列化为 JS 对象字面量。
void registerBuiltinTranslators(WidgetTranslatorRegistry registry) {
  registry
    ..register(const ColumnTranslator())
    ..register(const RowTranslator())
    ..register(const TextTranslator())
    ..register(const ElevatedButtonTranslator())
    ..register(const TextButtonTranslator())
    ..register(const OutlinedButtonTranslator())
    ..register(const SizedBoxTranslator())
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
    ..register(const SliderTranslator());
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
        for (final c in children) ctx.translate(c),
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
    return {'type': ctx.jsString('Text'), 'props': props};
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
      'event': ctx.jsString(_eventFrom(onPressed, ctx)),
    };
    // ElevatedButton.styleFrom(...) / ButtonStyle(...) → JSON
    final style = buttonStyleToJson(ctx.namedArg(node.args, 'style'), ctx);
    if (style != null) props['style'] = style;
    return {'type': ctx.jsString('Button'), 'props': props};
  }

  static String _eventFrom(Expression onPressed, WidgetTranslateContext ctx) {
    // 形式一：onPressed: _inc（方法 tear-off）
    if (onPressed is Identifier) {
      return ctx.eventOf(onPressed.name);
    }
    // 形式二：onPressed: () => _inc() 或 () { _inc(); }
    if (onPressed is FunctionExpression) {
      final inner = ctx.functionInner(onPressed);
      if (inner is MethodInvocation) {
        return ctx.eventOf(inner.methodName.name);
      }
    }
    throw FormatException('onPressed 需要直接引用组件方法（如 () => _inc()）');
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
    return {'type': ctx.jsString('SizedBox'), 'props': props};
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
/// 运行时 ScaffoldRenderer 按序取用，避免 props 里出现嵌套节点对象。
class ScaffoldTranslator extends WidgetTranslator {
  const ScaffoldTranslator();

  @override
  String get type => 'Scaffold';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = <Map<String, dynamic>>[];
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
    final children = <Map<String, dynamic>>[];
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
      'children': [for (final c in children) ctx.translate(c)],
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
    for (final name in ['left', 'top', 'right', 'bottom', 'width', 'height']) {
      final v = ctx.namedArg(node.args, name);
      if (v is IntegerLiteral && v.value != null) {
        props[name] = '${v.value}';
      } else if (v is DoubleLiteral) {
        props[name] = '${v.value}';
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
      'children': [for (final c in children) ctx.translate(c)],
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
      'children': [for (final c in children) ctx.translate(c)],
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
    final props = <String, dynamic>{'event': ctx.jsString(ctx.eventExpr(onTap))};
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
    final props = <String, dynamic>{'event': ctx.jsString(ctx.eventExpr(onTap))};
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
      'event': ctx.jsString(ctx.eventExpr(onChanged)),
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
      'event': ctx.jsString(ctx.eventExpr(onChanged)),
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
      'event': ctx.jsString(ctx.eventExpr(onChanged)),
    };
    for (final name in ['min', 'max']) {
      final v = _numOf(ctx.namedArg(node.args, name));
      if (v != null) props[name] = v;
    }
    return {'type': ctx.jsString('Slider'), 'props': props};
  }
}

// ---------------------------------------------------------------------------
// 本地小工具
// ---------------------------------------------------------------------------

/// 数字字面量 → JS 数字表达式（'12' / '1.5'）；非字面量返回 null。
String? _numOf(Expression? e) {
  if (e is IntegerLiteral && e.value != null) return '${e.value}';
  if (e is DoubleLiteral) return '${e.value}';
  return null;
}
