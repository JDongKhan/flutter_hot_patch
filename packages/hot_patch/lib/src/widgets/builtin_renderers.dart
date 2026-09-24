import 'package:flutter/material.dart';

import '../json/flutter_from_json.dart';
import 'widget_renderer.dart';

/// 内置渲染策略：把 codegen 生成的 JSON 节点渲染为常见 Flutter widget。
///
/// 新增内置 widget = 在这里加一个 renderer 类 + register 一行；
/// 自定义 widget = 业务方实现 WidgetRenderer 并通过
/// HotPatchWidget(rendererRegistry: ...) 注入，核心代码零改动。
void registerBuiltinRenderers(WidgetRendererRegistry registry) {
  registry
    ..register(const ColumnRenderer())
    ..register(const RowRenderer())
    ..register(const TextRenderer())
    ..register(const ButtonRenderer())
    ..register(const SizedBoxRenderer())
    // 布局
    ..register(const CenterRenderer())
    ..register(const PaddingRenderer())
    ..register(const AlignRenderer())
    ..register(const ExpandedRenderer())
    ..register(const FlexibleRenderer())
    ..register(const StackRenderer())
    ..register(const PositionedRenderer())
    ..register(const ContainerRenderer())
    ..register(const DividerRenderer())
    ..register(const CardRenderer())
    ..register(const ScaffoldRenderer())
    ..register(const AppBarRenderer())
    ..register(const ListViewRenderer())
    ..register(const SingleChildScrollViewRenderer())
    ..register(const WrapRenderer())
    // 内容
    ..register(const IconRenderer())
    ..register(const ImageRenderer())
    ..register(const CircleAvatarRenderer())
    // 交互
    ..register(const InkWellRenderer())
    ..register(const GestureDetectorRenderer())
    ..register(const SwitchRenderer())
    ..register(const CheckboxRenderer())
    ..register(const SliderRenderer());
}

/// Column / Row 共用逻辑：方向决定主轴 + 对齐 + children。
abstract class _AxisLayoutRenderer extends WidgetRenderer {
  const _AxisLayoutRenderer();

  /// 主轴方向：'Column' 垂直 / 'Row' 水平。
  Axis get axis;

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final children = [for (final c in node.children) ctx.render(c)];
    debugPrint(
      '[hot_patch] ${node.type} render children=${children.length} '
      'types=[${children.map((w) => w.runtimeType).join(',')}]',
    );
    // Flutter 中 Column / Row 的 mainAxisSize 默认都是 max，
    // 未显式翻译时保持与原生一致。
    final size = mainAxisSizeFromJson(node.props['mainAxisSize']) ??
        MainAxisSize.max;
    final main = mainAxisAlignmentFromJson(node.props['mainAxisAlignment']);
    final cross = crossAxisAlignmentFromJson(node.props['crossAxisAlignment']);
    if (axis == Axis.vertical) {
      return Column(
        mainAxisSize: size,
        mainAxisAlignment: main ?? MainAxisAlignment.start,
        crossAxisAlignment: cross ?? CrossAxisAlignment.center,
        children: children,
      );
    }
    return Row(
      mainAxisSize: size,
      mainAxisAlignment: main ?? MainAxisAlignment.start,
      crossAxisAlignment: cross ?? CrossAxisAlignment.center,
      children: children,
    );
  }
}

/// Column：垂直布局容器（单一 type）。
class ColumnRenderer extends _AxisLayoutRenderer {
  const ColumnRenderer();

  @override
  String get type => 'Column';

  @override
  Axis get axis => Axis.vertical;
}

/// Row：水平布局容器（单一 type）。
class RowRenderer extends _AxisLayoutRenderer {
  const RowRenderer();

  @override
  String get type => 'Row';

  @override
  Axis get axis => Axis.horizontal;
}

/// Text：文案 + 样式映射（title/hint/body）。
class TextRenderer extends WidgetRenderer {
  const TextRenderer();

  @override
  String get type => 'Text';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final w = Text(
      node.props['data']?.toString() ?? '',
      textAlign: TextAlign.center,
      style: textStyleFromJson(
        node.props['style'] is Map
            ? (node.props['style'] as Map).cast<String, dynamic>()
            : null,
      ),
    );
    debugPrint('[hot_patch] Text render "${node.props['data']}"');
    return w;
  }
}

/// Button：ElevatedButton，点击时把 props.event 上报给 JS 驱动逻辑。
class ButtonRenderer extends WidgetRenderer {
  const ButtonRenderer();

  @override
  String get type => 'Button';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    final style = buttonStyleFromJson(
      node.props['style'] is Map
          ? (node.props['style'] as Map).cast<String, dynamic>()
          : null,
    );
    final label = Text(node.props['label']?.toString() ?? '');
    void onPressed() => ctx.onEvent(event);
    final w = switch (node.props['kind']?.toString()) {
      'text' => TextButton(onPressed: onPressed, style: style, child: label),
      'outlined' =>
        OutlinedButton(onPressed: onPressed, style: style, child: label),
      _ => ElevatedButton(onPressed: onPressed, style: style, child: label),
    };
    debugPrint('[hot_patch] Button(${node.props['kind'] ?? 'elevated'}) '
        'render "${node.props['label']}"');
    return w;
  }
}


/// SizedBox：布局空隙，无 UI 内容（JS 树里翻译为占位尺寸）。
class SizedBoxRenderer extends WidgetRenderer {
  const SizedBoxRenderer();

  @override
  String get type => 'SizedBox';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final h = node.props['height'];
    final w = node.props['width'];
    return SizedBox(
      height: h is num ? h.toDouble() : (h == null ? null : double.tryParse('$h')),
      width: w is num ? w.toDouble() : (w == null ? null : double.tryParse('$w')),
    );
  }
}

// ===========================================================================
// 布局类
// ===========================================================================

/// Center：单子居中。
class CenterRenderer extends WidgetRenderer {
  const CenterRenderer();

  @override
  String get type => 'Center';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return Center(child: node.children.isEmpty ? null : ctx.render(node.children.first));
  }
}

/// Padding：padding（EdgeInsets JSON）+ 单子。
class PaddingRenderer extends WidgetRenderer {
  const PaddingRenderer();

  @override
  String get type => 'Padding';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return Padding(
      padding: edgeInsetsFromJson(
        node.props['padding'] is Map
            ? (node.props['padding'] as Map).cast<String, dynamic>()
            : null,
      ),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// Align：alignment + 单子。
class AlignRenderer extends WidgetRenderer {
  const AlignRenderer();

  @override
  String get type => 'Align';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return Align(
      alignment: alignmentFromJson(node.props['alignment']) ?? Alignment.center,
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// Expanded / Flexible 共用逻辑：flex + 单子（Row/Column 内）。
abstract class _FlexRenderer extends WidgetRenderer {
  const _FlexRenderer();

  /// Expanded 用 tight 撑满，Flexible 用 loose。
  FlexFit get fit;

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final child = node.children.isEmpty ? const SizedBox.shrink() : ctx.render(node.children.first);
    final flex = node.props['flex'];
    final flexInt = flex is num ? flex.toInt() : int.tryParse('$flex') ?? 1;
    return fit == FlexFit.tight
        ? Expanded(flex: flexInt, child: child)
        : Flexible(flex: flexInt, child: child);
  }
}

/// Expanded：Row/Column 内撑满剩余空间。
class ExpandedRenderer extends _FlexRenderer {
  const ExpandedRenderer();

  @override
  String get type => 'Expanded';

  @override
  FlexFit get fit => FlexFit.tight;
}

/// Flexible：Row/Column 内可伸缩（不强制撑满）。
class FlexibleRenderer extends _FlexRenderer {
  const FlexibleRenderer();

  @override
  String get type => 'Flexible';

  @override
  FlexFit get fit => FlexFit.loose;
}

/// Stack：children + alignment（children 内允许 Positioned 节点）。
class StackRenderer extends WidgetRenderer {
  const StackRenderer();

  @override
  String get type => 'Stack';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return Stack(
      alignment: alignmentFromJson(node.props['alignment']) ?? AlignmentDirectional.topStart,
      children: [for (final c in node.children) ctx.render(c)],
    );
  }
}

/// Positioned：Stack 内定位（left/top/right/bottom/width/height）。
class PositionedRenderer extends WidgetRenderer {
  const PositionedRenderer();

  @override
  String get type => 'Positioned';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    return Positioned(
      left: d(node.props['left']),
      top: d(node.props['top']),
      right: d(node.props['right']),
      bottom: d(node.props['bottom']),
      width: d(node.props['width']),
      height: d(node.props['height']),
      child: node.children.isEmpty
          ? const SizedBox.shrink()
          : ctx.render(node.children.first),
    );
  }
}

/// Container：width/height/color/padding/margin/alignment/decoration + 单子。
class ContainerRenderer extends WidgetRenderer {
  const ContainerRenderer();

  @override
  String get type => 'Container';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    final deco = boxDecorationFromJson(
      node.props['decoration'] is Map
          ? (node.props['decoration'] as Map).cast<String, dynamic>()
          : null,
    );
    final color = colorFromJson(node.props['color']);
    return Container(
      width: d(node.props['width']),
      height: d(node.props['height']),
      // color 与 decoration 同传会断言：decoration 优先（其内可含 color）。
      color: deco == null ? color : null,
      decoration: deco,
      padding: edgeInsetsFromJson(
        node.props['padding'] is Map
            ? (node.props['padding'] as Map).cast<String, dynamic>()
            : null,
      ),
      margin: edgeInsetsFromJson(
        node.props['margin'] is Map
            ? (node.props['margin'] as Map).cast<String, dynamic>()
            : null,
      ),
      alignment: alignmentFromJson(node.props['alignment']),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// Divider：height/thickness/color/indent/endIndent。
class DividerRenderer extends WidgetRenderer {
  const DividerRenderer();

  @override
  String get type => 'Divider';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    return Divider(
      height: d(node.props['height']),
      thickness: d(node.props['thickness']),
      indent: d(node.props['indent']),
      endIndent: d(node.props['endIndent']),
      color: colorFromJson(node.props['color']),
    );
  }
}

/// Card：child + elevation/margin/color。
class CardRenderer extends WidgetRenderer {
  const CardRenderer();

  @override
  String get type => 'Card';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final elevation = node.props['elevation'];
    return Card(
      elevation: elevation is num ? elevation.toDouble() : double.tryParse('$elevation'),
      margin: edgeInsetsFromJson(
        node.props['margin'] is Map
            ? (node.props['margin'] as Map).cast<String, dynamic>()
            : null,
      ),
      color: colorFromJson(node.props['color']),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// ListView：children 列表（shrinkWrap 适配内嵌场景）。
class ListViewRenderer extends WidgetRenderer {
  const ListViewRenderer();

  @override
  String get type => 'ListView';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return ListView(
      shrinkWrap: true,
      children: [for (final c in node.children) ctx.render(c)],
    );
  }
}

/// Scaffold：children = [AppBar, body]（生成器约定）。
class ScaffoldRenderer extends WidgetRenderer {
  const ScaffoldRenderer();

  @override
  String get type => 'Scaffold';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    PreferredSizeWidget? appBar;
    if (node.children.isNotEmpty && node.children.first.type == 'AppBar') {
      appBar = ctx.render(node.children.first) as PreferredSizeWidget?;
    }
    return Scaffold(
      backgroundColor: colorFromJson(node.props['backgroundColor']),
      appBar: appBar,
      body: node.children.length > 1 ? ctx.render(node.children[1]) : null,
    );
  }
}

/// AppBar：children[0] = title。
class AppBarRenderer extends WidgetRenderer {
  const AppBarRenderer();

  @override
  String get type => 'AppBar';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return AppBar(
      title: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// SingleChildScrollView：child + scrollDirection。
class SingleChildScrollViewRenderer extends WidgetRenderer {
  const SingleChildScrollViewRenderer();

  @override
  String get type => 'SingleChildScrollView';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return SingleChildScrollView(
      scrollDirection: axisFromJson(node.props['scrollDirection']) ?? Axis.vertical,
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// Wrap：children + spacing/runSpacing。
class WrapRenderer extends WidgetRenderer {
  const WrapRenderer();

  @override
  String get type => 'Wrap';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    return Wrap(
      spacing: d(node.props['spacing']) ?? 0,
      runSpacing: d(node.props['runSpacing']) ?? 0,
      children: [for (final c in node.children) ctx.render(c)],
    );
  }
}

// ===========================================================================
// 内容类
// ===========================================================================

/// Icon：icon 名 + size/color。
class IconRenderer extends WidgetRenderer {
  const IconRenderer();

  @override
  String get type => 'Icon';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final size = node.props['size'];
    return Icon(
      iconFromJson(node.props['icon']),
      size: size is num ? size.toDouble() : double.tryParse('$size'),
      color: colorFromJson(node.props['color']),
    );
  }
}

/// Image：asset/network 源 + width/height/fit。
class ImageRenderer extends WidgetRenderer {
  const ImageRenderer();

  @override
  String get type => 'Image';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final source = node.props['source']?.toString() ?? '';
    final width = node.props['width'];
    final height = node.props['height'];
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    final fit = boxFitFromJson(node.props['fit']);
    final image = source.startsWith('http')
        ? Image.network(source, width: d(width), height: d(height), fit: fit)
        : Image.asset(source, width: d(width), height: d(height), fit: fit);
    return image;
  }
}

/// CircleAvatar：radius/backgroundColor + 可选 child。
class CircleAvatarRenderer extends WidgetRenderer {
  const CircleAvatarRenderer();

  @override
  String get type => 'CircleAvatar';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final radius = node.props['radius'];
    return CircleAvatar(
      radius: radius is num ? radius.toDouble() : double.tryParse('$radius'),
      backgroundColor: colorFromJson(node.props['backgroundColor']),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

// ===========================================================================
// 交互类
// ===========================================================================

/// InkWell：onTap → 事件 + 单子。
class InkWellRenderer extends WidgetRenderer {
  const InkWellRenderer();

  @override
  String get type => 'InkWell';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    return InkWell(
      onTap: () => ctx.onEvent(event),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// GestureDetector：onTap → 事件 + 单子。
class GestureDetectorRenderer extends WidgetRenderer {
  const GestureDetectorRenderer();

  @override
  String get type => 'GestureDetector';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    return GestureDetector(
      onTap: () => ctx.onEvent(event),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// Switch：value + onChanged（带值事件 → JS 方法带参调用）。
class SwitchRenderer extends WidgetRenderer {
  const SwitchRenderer();

  @override
  String get type => 'Switch';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    return Switch(
      value: node.props['value'] == true,
      onChanged: (v) {
        final f = ctx.onEventValue;
        if (f != null) {
          f(event, v);
        } else {
          ctx.onEvent(event);
        }
      },
    );
  }
}

/// Checkbox：value + onChanged（带值事件 → JS 方法带参调用）。
class CheckboxRenderer extends WidgetRenderer {
  const CheckboxRenderer();

  @override
  String get type => 'Checkbox';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    return Checkbox(
      value: node.props['value'] == true,
      onChanged: (v) {
        final f = ctx.onEventValue;
        if (f != null) {
          f(event, v);
        } else {
          ctx.onEvent(event);
        }
      },
    );
  }
}

/// Slider：value + min/max + onChanged（带值事件 → JS 方法带参调用）。
class SliderRenderer extends WidgetRenderer {
  const SliderRenderer();

  @override
  String get type => 'Slider';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    final value = node.props['value'];
    final min = node.props['min'];
    final max = node.props['max'];
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    return Slider(
      value: d(value) ?? 0,
      min: d(min) ?? 0,
      max: d(max) ?? 1,
      onChanged: (v) {
        final f = ctx.onEventValue;
        if (f != null) {
          f(event, v);
        } else {
          ctx.onEvent(event);
        }
      },
    );
  }
}
