// ===== 能力：BuildContext 代理桥 =====
//
// 与 capabilities/build_context/build_context_js.dart **对称**：JS 组件的 `this.context` 是
// 一个代理，真实 BuildContext 只存在于宿主。
//
// 两端靠 **nodeId** 对齐：JS 侧代理记「最近宿主祖先结点 id」，宿主侧
// `_JsNodeState` 在 build 期间登记 `nodeId -> BuildContext`、element 卸载时注销。
// 该映射存在**绑定缓存**的 [JsBindingBuckets.ctxNode] 桶里且是**弱引用**：
// BuildContext 本体就是那个 Element——由 `State.context` 指向，State 由 Element
// 持有，Element 又由 element tree 的父→子引用链强持有（根 element 由 BuildOwner
// 持有），故真实持有者在框架、缓存只是索引，不该钉住子树（详见下方桶注释）。
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
import 'package:flutter/widgets.dart';

import '../../../utils/hot_patch_log.dart';
import '../core/binding_cache.dart';
import '../core/handle_registry.dart';

/// 页面锚点的结点键：JS 侧根组件（COMP 之上没有宿主结点）的 `this.context`
/// 代理用它反查页面级 BuildContext（两端必须一致）。
String jsBuildContextPageAnchor(String pageKey) => 'page:$pageKey';

/// 本能力的两类绑定都存在**绑定缓存**里（见 binding_cache.dart），各占一个桶：
///
///   - [JsBindingBuckets.ctxHandle]：ctx 句柄 id → 结点 id。**纯映射值、强引用**
///     （没有任何 widget 持有它，只有本缓存持有——见缓存文件头的判定 2）。
///   - [JsBindingBuckets.ctxNode]：结点 id → 当前 BuildContext。**弱引用**：真实
///     所有权在框架（Element 由 element tree 的父→子强持有），这里只是「结点 id
///     → 当前 context」的查表索引。若为强引用，一次漏掉的注销就会把**整棵 Element
///     子树**钉住无法回收；弱引用把漏删的后果降级为一条死键（几十字节字符串），
///     子树照常回收。结点挂在树上时 deref 必然拿得到，语义不变。
///
/// 一个 element 的**每个历史结点 id 都要登记**：JS 侧代理缓存的是它建立时的那个
/// id，同 key 下结点 id 变化时旧 id 仍要能查到同一个 element，故只能在 element
/// 卸载时按整段历史统一注销（见 _JsNodeState 的 `_anchorIds`），不能在 id 变化时清。
///
/// 条目自带 pageKey（登记时给出），故泄漏观测不需要任何额外的归属表。
const String _ctxKind = 'ctx/BuildContext';

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
  registerHandleKind(_ctxKind, JsHandleKind(
    onCreate: (id, meta, pageKey) {
      final node = meta is Map ? meta['node'] : null;
      if (node is String && node.isNotEmpty) {
        // 纯映射值（句柄 id → 结点 id）：没有任何 widget 持有它，只有本缓存持有
        // → 强引用（见文件头）。
        JsBindingCache.instance.put<String>(
          bucket: JsBindingBuckets.ctxHandle,
          id: id,
          kind: _ctxKind,
          value: node,
          weak: false,
          pageKey: pageKey,
          owner: 'ctx/BuildContext.onCreate',
        );
      }
    },
    onOp: (id, op, payload) => _dispatchContextOp(id, op, payload),
    onRelease: (id) {
      JsBindingCache.instance.remove(JsBindingBuckets.ctxHandle, id);
      // 扇出给各库，清理它们在这个位置上挂的资源（如 provider 的订阅）。
      for (final handler in _contextOps.values) {
        handler.onRelease?.call(id);
      }
    },
  ));
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
/// 弱引用（见文件头）+ 就地覆盖：同一结点重建时刷新为新的 BuildContext（Element
/// 复用则其实同一个对象）。[type] 是结点类型，[owner] 是登记来源——两者只进条目
/// 的元数据，供 [JsBindingCache.dump] 与泄漏明细把这一条说人话（否则只看到一个
/// `StatefulElement`，认不出是哪个结点）。
///
/// **静音**：这是「每页每结点一条、无跨页风险」的索引类条目，登记/释放都不打逐条
/// 日志（否则一页几十行刷屏）；本页登记与残留的总数仍由页面退出时的汇总给出。
void registerJsBuildContext(
  String nodeId,
  BuildContext context,
  String pageKey, {
  required String type,
  String owner = '_JsNodeState.build',
}) {
  JsBindingCache.instance.put<BuildContext>(
    bucket: JsBindingBuckets.ctxNode,
    id: nodeId,
    kind: _ctxKind,
    value: context,
    weak: true,
    quiet: true,
    pageKey: pageKey,
    owner: owner,
    meta: {'type': type},
  );
}

/// 注销某个宿主结点（_JsNodeState.dispose）。
///
/// 注销后 deref 只会拿到已回收的目标（返回 null）；即便漏了一次注销，被钉住的
/// 也只是这条簿记键，不再是整棵 Element 子树。
void unregisterJsBuildContext(String nodeId) {
  JsBindingCache.instance.remove(JsBindingBuckets.ctxNode, nodeId);
}

/// 按结点 id 取宿主真值 BuildContext（结点未登记 / 已卸载 / 目标已被回收返回 null）。
BuildContext? jsBuildContextOfNode(String nodeId) =>
    JsBindingCache.instance.target<BuildContext>(JsBindingBuckets.ctxNode, nodeId);

/// 按 JS 侧 `this.context` 代理的句柄 id 取宿主真值 BuildContext。
BuildContext? jsBuildContextOf(String handleId) {
  final node =
      JsBindingCache.instance.target<String>(JsBindingBuckets.ctxHandle, handleId);
  return node == null ? null : jsBuildContextOfNode(node);
}
