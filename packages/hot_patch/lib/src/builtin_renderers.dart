import 'package:flutter/material.dart';

import 'flutter_from_json.dart';
import 'widget_renderer.dart';

/// 内置渲染策略：把 codegen 生成的 JSON 节点渲染为常见 Flutter widget。
///
/// 新增内置 widget = 在这里加一个 renderer 类 + register 一行；
/// 自定义 widget = 业务方实现 WidgetRenderer 并通过
/// HotPatchWidget(rendererRegistry: ...) 注入，核心代码零改动。
void registerBuiltinRenderers(WidgetRendererRegistry registry) {
  registry
    ..register(const LayoutRenderer())
    ..register(const TextRenderer())
    ..register(const ButtonRenderer())
    ..register(const SizedBoxRenderer());
}

/// Column / Row：布局容器，唯一策略是递归渲染 children。
class LayoutRenderer extends WidgetRenderer {
  const LayoutRenderer();

  @override
  Set<String> get types => const {'Column', 'Row'};

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final children = [for (final c in node.children) ctx.render(c)];
    debugPrint(
      '[hot_patch] ${node.type} render children=${children.length} '
      'types=[${children.map((w) => w.runtimeType).join(',')}]',
    );
    return node.type == 'Column'
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// Text：文案 + 样式映射（title/hint/body）。
class TextRenderer extends WidgetRenderer {
  const TextRenderer();

  @override
  Set<String> get types => const {'Text'};

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
  Set<String> get types => const {'Button'};

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final w = ElevatedButton(
      onPressed: () => ctx.onEvent(node.props['event']?.toString() ?? ''),
      style: buttonStyleFromJson(
        node.props['style'] is Map
            ? (node.props['style'] as Map).cast<String, dynamic>()
            : null,
      ),
      child: Text(node.props['label']?.toString() ?? ''),
    );
    debugPrint('[hot_patch] Button render "${node.props['label']}"');
    return w;
  }
}


/// SizedBox：布局空隙，无 UI 内容（JS 树里翻译为占位尺寸）。
class SizedBoxRenderer extends WidgetRenderer {
  const SizedBoxRenderer();

  @override
  Set<String> get types => const {'SizedBox'};

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
