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

import '../../utils/hot_patch_log.dart';
import 'handle_registry.dart';
import 'provider_bridge.dart';
import 'vm_bridge.dart';

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
    onOp: (id, op, payload) => _resolveProviderOp(id, op, payload),
    onRelease: (id) {
      _ctxHandleNode.remove(id);
      _releaseCtxWatch(id);
    },
  ));
}

/// 一个「按类型订阅」的登记项：JS 侧 vm 镜像 + 它到该结点 element 的监听回调。
class _CtxWatch {
  _CtxWatch(this.vm, this.listener);

  final JsVm vm;
  final VoidCallback listener;
}

/// ctx 句柄 id → {type → 订阅项}。
///
/// **去重是必需的**：JS 侧 `context.watch<T>()` 写在 build 里，每次重建都会重发
/// 同名 op；不去重就会往同一个 vm 上叠无数监听器。
final Map<String, Map<String, _CtxWatch>> _ctxWatches = {};

/// JS 侧 `context.watch<T>()` / `context.read<T>()` 落到宿主**真值 BuildContext**
/// 上的权威查找：句柄 id → 结点 id → 该结点的真值 BuildContext → 沿真实 element
/// 树按 `jsType == T` 找 provider（[jsVmOfTypeAt]）。
///
/// **职责分工**：JS 侧的**取值**留在 JS 内（同步约束：build 里
/// `context.watch<T>().count` 与事件串的链式调用都是同步求值，而 JS→宿主只有
/// 异步桥），JS 的 `watch` 同步返回自己解析出的 vm；**订阅**则落在 Dart 侧——
/// `watch` op 让该位置的 `_JsNode` element 订阅（按类型精确匹配的那个镜像），
/// vm notify 时标脏重建，与 Dart `context.watch<T>()` 建立依赖的语义一致。
///
/// 查不到（或类型不匹配）说明 JS 侧解析越过了 provider 边界（消费点被放到了
/// provider 子树之外），按项目规则出运行时告警而非静默。
Object? _resolveProviderOp(String id, String op, Map payload) {
  if (op != 'watch' && op != 'read')  {
    HotPatchLog.log(
      '[jsui] 不支持context.$op()方法 ',
    );
    return null;
  }
  final type = payload['type'];
  if (type is! String || type.isEmpty) return null;
  final context = jsBuildContextOf(id);
  // 结点尚未登记 / 已卸载（构建时序或卸载竞态）：静默跳过。
  if (context == null) return null;
  final vm = jsVmOfTypeAt(context, type);
  if (vm == null) {
    // 只在**本端也没找到**时告警：否则是宿主侧本就没有该作用域的镜像
    // （将来 JS-only 的作用域族），属正常情形，不该报错。
    if (payload['found'] != true) {
      HotPatchLog.log(
        '[jsui] context.$op("$type") 在宿主真值 context 上找不到该类型的 provider'
        '（结点 $id；消费点可能在 provider 子树之外）',
      );
    }
    return null;
  }
  // read 不建依赖（对齐 Flutter/provider 语义：read 只取值、不随 notify 重建）。
  if (op == 'watch') _subscribeNode(id, type, vm);
  return null;
}

/// 让该位置（nodeId 对应的 `_JsNode` element）**按类型精确订阅** vm。
///
/// 订阅挂的是 [jsVmOfTypeAt] 按 `jsType == type` 解析出的那个镜像——不是「最近
/// 的 provider」（里层嵌套了别的类型时会订错），也不是 props 里顺手拿到的那个。
/// vm notify → 该 element 标脏 → 重建（重建时重新读 store，取到 JS 已补丁后的值）。
void _subscribeNode(String ctxId, String type, JsVm vm) {
  final subs = _ctxWatches[ctxId] ??= <String, _CtxWatch>{};
  if (subs.containsKey(type)) return;
  void listener() {
    final context = jsBuildContextOf(ctxId);
    if (context is Element && context.mounted) context.markNeedsBuild();
  }

  subs[type] = _CtxWatch(vm, listener);
  vm.addListener(listener);
}

/// ctx 句柄释放（组件卸载 / 页面销毁）：摘除该位置的全部订阅。
void _releaseCtxWatch(String ctxId) {
  final subs = _ctxWatches.remove(ctxId);
  if (subs == null) return;
  for (final watch in subs.values) {
    watch.vm.removeListener(watch.listener);
  }
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
