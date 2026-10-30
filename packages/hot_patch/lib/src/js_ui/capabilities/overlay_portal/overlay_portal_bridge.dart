// ===== 能力：OverlayPortal 三件套 =====
//
//   OverlayPortal / CompositedTransformTarget / CompositedTransformFollower
//
// 三者都是**纯宿主渲染**组件，JS 侧没有额外逻辑：
//   - OverlayPortal：JS 已把 `overlayChildBuilder` 的返回值展开成 `overlayChild`
//     插槽（见 flutter.js 的 OverlayPortal 组件类），宿主只做「挂到 Overlay 上，
//     controller 要求时显示」；
//   - Target / Follower：两端共享同一个 `LayerLink` 锚点（句柄 id），几何计算全在
//     Flutter 的图层合成里完成。
//
// 两个跨语言对象各占一个句柄 kind（通用句柄层 + 控制器桥），随组件实例释放：
//   - `layer/Link`：LayerLink()（无方法，只做身份对齐）；
//   - `overlay/Portal`：OverlayPortalController()，show/hide/toggle 命令由 JS
//     `handleOp` 发来（'call' + method），isShowing 由 JS 侧镜像，不查宿主。
import 'package:flutter/widgets.dart';

import '../../js_widget_registry.dart';
import '../../ui_fallback.dart';
import '../core/controller_bridge.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';

/// LayerLink 句柄桥：JS 的 `LayerLink` 实例 ↔ 宿主真实 `LayerLink()`。
final JsControllerBridge<LayerLink> _linkBridge = JsControllerBridge<LayerLink>(
  kind: 'layer/Link',
  create: (id, meta) => LayerLink(),
  onOp: (link, op, payload) => null,
);

/// OverlayPortalController 句柄桥：show/hide 由 JS 命令驱动。
final JsControllerBridge<OverlayPortalController> _portalBridge =
    JsControllerBridge<OverlayPortalController>(
  kind: 'overlay/Portal',
  create: (id, meta) => OverlayPortalController(
    debugLabel: meta is Map && meta['debugLabel'] is String
        ? meta['debugLabel'] as String
        : null,
  ),
  onOp: (controller, op, payload) {
    if (op == 'call') {
      switch (payload['method']) {
        case 'show':
          controller.show();
        case 'hide':
          controller.hide();
        case 'toggle':
          controller.isShowing ? controller.hide() : controller.show();
      }
    }
    return null;
  },
);

void ensureOverlayPortalChannels() {
  _linkBridge.ensure();
  _portalBridge.ensure();
}

void registerOverlayPortalWidgets(JsWidgetRegistry r) {
  r.register('OverlayPortal', (c) {
    final controller = _controllerOf(c.props['controller']);
    if (controller == null) {
      return uiFallback('OverlayPortal.controller 缺失');
    }
    final overlayChild = c.children['overlayChild'] as Widget?;
    return OverlayPortal(
      controller: controller,
      overlayLocation: _locationOf(c.props['overlayLocation']),
      overlayChildBuilder: (context) =>
          overlayChild ?? uiFallback('OverlayPortal.overlayChild 缺失'),
      child: c.children['child'] as Widget?,
    );
  });

  r.register('CompositedTransformTarget', (c) {
    final link = _linkOf(c.props['link']);
    if (link == null) return uiFallback('CompositedTransformTarget.link 缺失');
    return CompositedTransformTarget(
      link: link,
      child: c.children['child'] as Widget?,
    );
  });

  r.register('CompositedTransformFollower', (c) {
    final link = _linkOf(c.props['link']);
    if (link == null) return uiFallback('CompositedTransformFollower.link 缺失');
    return CompositedTransformFollower(
      link: link,
      showWhenUnlinked: c.bool_('showWhenUnlinked') ?? true,
      offset: offsetFromJson(c.props['offset']) ?? Offset.zero,
      targetAnchor:
          alignmentFromJson(c.props['targetAnchor']) ?? Alignment.topLeft,
      followerAnchor:
          alignmentFromJson(c.props['followerAnchor']) ?? Alignment.topLeft,
      child: c.children['child'] as Widget?,
    );
  });
}

/// props 里的 `{__handle:id}` → 宿主真实 LayerLink（缺 link 返回 null，由调用方
/// 兜底出声）。
///
/// 用 `controllerOf`（putIfAbsent 兜底创建）而不是 `controllerAt`：句柄 create
/// 消息与首帧渲染到达顺序不定，两端必须落到**同一个实例**（锚点是身份语义）。
LayerLink? _linkOf(Object? prop) {
  final id = JsControllerBridge.idOf(prop);
  if (id == null) return null;
  return _linkBridge.controllerOf(id, LayerLink.new);
}

OverlayPortalController? _controllerOf(Object? prop) {
  final id = JsControllerBridge.idOf(prop);
  if (id == null) return null;
  return _portalBridge.controllerOf(id, OverlayPortalController.new);
}

/// `OverlayChildLocation.*` 在 JS 侧是枚举名字符串（与其它 SDK 枚举同一形态）。
OverlayChildLocation _locationOf(Object? raw) =>
    raw == 'rootOverlay' ? OverlayChildLocation.rootOverlay : OverlayChildLocation.nearestOverlay;
