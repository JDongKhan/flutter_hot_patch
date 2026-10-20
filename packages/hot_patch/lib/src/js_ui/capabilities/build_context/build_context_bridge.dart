// ===== 能力：BuildContext 代理桥 =====
//
// 与 capabilities/build_context/build_context_js.dart **对称**：JS 组件的 `this.context` 是
// 一个代理，真实 BuildContext 只存在于宿主。
//
// 两端靠 **nodeId** 对齐：JS 侧代理记「最近宿主祖先结点 id」，宿主侧
// `_JsNodeState` 在 build 期间登记 `nodeId -> BuildContext`、dispose 时注销。
// 句柄（kind=ctx/BuildContext）只是让「句柄 id → nodeId」可查——即
// [jsBuildContextOf]。
//
// **本能力只提供机制，不提供任何库的 API 语义**：`context.watch<T>()` /
// `read<T>()` 是 provider 那类 `extension BuildContextX on BuildContext` 的东西，
// 不是框架 API。故：
//   - JS 侧的方法补丁写在**各库自己的片段**里（见
//     capabilities/provider/provider_js.dart）；
//   - 宿主侧的处理经 [registerContextOp] 注册进来（见
//     capabilities/provider/context_ops.dart）。
// 核心只做三件事：代理/句柄、nodeId ↔ 真值 context 的登记、把 op 分发给注册者
// （未注册的 op 沿用「不支持 context.$op()」告警）。
//
// 为什么 JS 侧不自己做：BuildContext 是纯宿主端概念（Theme / MediaQuery /
// Navigator / 三方 context 扩展全都要真值），而 JS→宿主只有异步桥，取值语义
// 无法在 JS 内闭环。因此这类调用走 **@HostInjected 编译期类型化适配**：
// 编译期知道 T 是什么，运行时按本文件的映射取宿主真值。
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../utils/hot_patch_log.dart';
import '../core/handle_registry.dart';

/// 页面锚点的结点键：JS 侧根组件（COMP 之上没有宿主结点）的 `this.context`
/// 代理用它反查页面级 BuildContext（两端必须一致）。
String jsBuildContextPageAnchor(String pageKey) => 'page:$pageKey';

/// nodeId → 该宿主结点 build 期间的 BuildContext。
///
/// 由 _JsNodeState 在 build / didChangeDependencies 登记、dispose 注销；同一
/// 结点重建时覆盖为新的 BuildContext（Element 复用则其实同一个对象）。
final Map<String, BuildContext> _jsBuildContexts = {};

/// debug：nodeId → 所属页面（极小的泄漏观测归属表，与 [_jsBuildContexts] 同增
/// 同减）。结点 id 是全局唯一的，不带页面信息；同屏多实例时只有按归属过滤才能
/// 把「本页结点销毁后仍留在表里」与「兄弟页面的活结点」区分开。
final Map<String, String> _ctxNodePage = {};

/// 句柄 id → nodeId（JS 侧代理登记时下发）。
final Map<String, String> _ctxHandleNode = {};

/// 一个 `context.<op>(...)` 的宿主处理器（由各库注册，核心只负责分发）。
///
/// [onRelease] 在该 ctx 句柄释放（组件卸载 / 页面销毁）时被调用，供注册者清理
/// 自己挂在这个位置上的资源（如订阅）；不提供则会漏。
class JsContextOp {
  const JsContextOp({required this.onOp, this.onRelease});

  final Object? Function(String ctxId, String op, Map payload) onOp;
  final void Function(String ctxId)? onRelease;
}

/// op 名 → 处理器（同名后注册者覆盖）。
final Map<String, JsContextOp> _contextOps = {};

/// 注册一个 `context.<op>(...)` 的宿主处理——本能力对**各库**开放的扩展缝。
///
/// 库在自己的 `ensureChannels()` 里注册；核心从此不认识任何具体 op 名
/// （`watch` / `read` 由 provider 注册，见 provider/context_ops.dart）。
void registerContextOp(
  String op, {
  required Object? Function(String ctxId, String op, Map payload) onOp,
  void Function(String ctxId)? onRelease,
}) {
  _contextOps[op] = JsContextOp(onOp: onOp, onRelease: onRelease);
}

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
    onOp: (id, op, payload) => _dispatchContextOp(id, op, payload),
    onRelease: (id) {
      _ctxHandleNode.remove(id);
      // 扇出给各库，清理它们在这个位置上挂的资源（如 provider 的订阅）。
      for (final handler in _contextOps.values) {
        handler.onRelease?.call(id);
      }
    },
  ));
  // 泄漏观测探针（仅 debug 登记；见 js_leak_snapshot.dart）。nodeContexts
  // 持有宿主 Element 树引用，泄漏即整棵子树无法回收，重点观测——按 nodeId 归属
  // 过滤，只数本页登记过的结点（兄弟实例的活结点不参与统计）。
  if (kDebugMode) {
    dartHandleTableProbes['ctx/BuildContext.handles'] =
        (pageKey) => debugPageOwnedCount(_ctxHandleNode.keys, pageKey);
    dartHandleTableProbes['ctx/BuildContext.nodeContexts'] = (pageKey) =>
        _jsBuildContexts.keys.where((n) => _ctxNodePage[n] == pageKey).length;
  }
}

/// 把 `context.<op>(...)` 分发给注册者；未注册的 op 按项目规则告警而非静默。
Object? _dispatchContextOp(String id, String op, Map payload) {
  final handler = _contextOps[op];
  if (handler == null) {
    HotPatchLog.log('[jsui] 不支持context.$op()方法 ');
    return null;
  }
  return handler.onOp(id, op, payload);
}

/// 登记/更新某个宿主结点的 BuildContext（_JsNodeState 在 build 期间调用）。
///
/// [pageKey] 只用于 debug 泄漏观测的归属登记（探针按页统计，见
/// js_leak_snapshot.dart）；release 下不写入任何额外状态。
void registerJsBuildContext(String nodeId, BuildContext context, String pageKey) {
  _jsBuildContexts[nodeId] = context;
  if (kDebugMode) _ctxNodePage[nodeId] = pageKey;
}

/// 注销某个宿主结点（_JsNodeState.dispose）。
void unregisterJsBuildContext(String nodeId) {
  _jsBuildContexts.remove(nodeId);
  _ctxNodePage.remove(nodeId);
}

/// 按结点 id 取宿主真值 BuildContext（结点已卸载返回 null）。
BuildContext? jsBuildContextOfNode(String nodeId) => _jsBuildContexts[nodeId];

/// 按 JS 侧 `this.context` 代理的句柄 id 取宿主真值 BuildContext。
BuildContext? jsBuildContextOf(String handleId) {
  final node = _ctxHandleNode[handleId];
  return node == null ? null : _jsBuildContexts[node];
}
