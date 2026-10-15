// ===== 能力：BuildContext 代理桥 =====
//
// 与 capabilities/build_context_js.dart **对称**：JS 组件的 `this.context` 是
// 一个代理，真实 BuildContext 只存在于宿主。
//
// 两端靠 **nodeId** 对齐：JS 侧代理记「最近宿主祖先结点 id」，宿主侧
// `_JsNodeState` 在 build 期间登记 `nodeId -> BuildContext`、dispose 时注销。
// 句柄（kind=ctx/BuildContext）只是让「句柄 id → nodeId」可查——即
// [jsBuildContextOf]。
//
// 为什么 JS 侧不自己做：BuildContext 是纯宿主端概念（Theme / MediaQuery /
// Navigator / 三方 context 扩展全都要真值），而 JS→宿主只有异步桥，取值语义
// 无法在 JS 内闭环。因此这类调用走 **@HostInjected 编译期类型化适配**：
// 编译期知道 T 是什么，运行时按本文件的映射取宿主真值。
import 'package:flutter/widgets.dart';

import 'handle_registry.dart';

/// 页面锚点的结点键：JS 侧根组件（COMP 之上没有宿主结点）的 `this.context`
/// 代理用它反查页面级 BuildContext（两端必须一致）。
String jsBuildContextPageAnchor(String pageKey) => 'page:$pageKey';

/// nodeId → 该宿主结点 build 期间的 BuildContext。
///
/// 由 _JsNodeState 在 build / didChangeDependencies 登记、dispose 注销；同一
/// 结点重建时覆盖为新的 BuildContext（Element 复用则其实同一个对象）。
final Map<String, BuildContext> _jsBuildContexts = {};

/// 句柄 id → nodeId（JS 侧代理登记时下发）。
final Map<String, String> _ctxHandleNode = {};

bool _ctxKindRegistered = false;

/// 幂等注册 BuildContext 句柄 kind（由 js_ui_capabilities.ensureJsUiCapabilities 聚合调用）。
void ensureBuildContextChannels() {
  if (_ctxKindRegistered) return;
  _ctxKindRegistered = true;
  registerHandleKind('ctx/BuildContext', JsHandleKind(
    onCreate: (id, meta) {
      final node = meta is Map ? meta['node'] : null;
      if (node is String && node.isNotEmpty) _ctxHandleNode[id] = node;
    },
    onRelease: (id) => _ctxHandleNode.remove(id),
  ));
}

/// 登记/更新某个宿主结点的 BuildContext（_JsNodeState 在 build 期间调用）。
void registerJsBuildContext(String nodeId, BuildContext context) {
  _jsBuildContexts[nodeId] = context;
}

/// 注销某个宿主结点（_JsNodeState.dispose）。
void unregisterJsBuildContext(String nodeId) {
  _jsBuildContexts.remove(nodeId);
}

/// 按结点 id 取宿主真值 BuildContext（结点已卸载返回 null）。
BuildContext? jsBuildContextOfNode(String nodeId) => _jsBuildContexts[nodeId];

/// 按 JS 侧 `this.context` 代理的句柄 id 取宿主真值 BuildContext。
BuildContext? jsBuildContextOf(String handleId) {
  final node = _ctxHandleNode[handleId];
  return node == null ? null : _jsBuildContexts[node];
}
