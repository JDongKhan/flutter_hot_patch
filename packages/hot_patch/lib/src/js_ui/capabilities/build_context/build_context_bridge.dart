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
// 为什么 JS 侧不自己做：BuildContext 是纯宿主端概念（Theme / MediaQuery /
// Navigator / 三方 context 扩展全都要真值），而 JS→宿主只有异步桥，取值语义
// 无法在 JS 内闭环。因此这类调用走 **@HostInjected 编译期类型化适配**：
// 编译期知道 T 是什么，运行时按本文件的映射取宿主真值。
import 'package:flutter/widgets.dart';

import '../../../utils/hot_patch_log.dart';
import '../handle_registry.dart';
import '../js_ui_library.dart';

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
    onOp: (id, op, payload) => _resolveContextOp(id, op, payload),
    onRelease: (id) {
      _ctxHandleNode.remove(id);
      _releaseCtxWatch(id);
    },
  ));
}

/// 一个「按类型订阅」的登记项：宿主侧解析出的可订阅对象 + 它到该结点 element
/// 的监听回调。
///
/// 类型是 [Listenable] 而非某个具体库的类型——核心只负责「订阅它、变更时标脏
/// 重建」，与「它是谁」无关（见 [JsUiLibrary.resolveWatchTarget]）。
class _CtxWatch {
  _CtxWatch(this.listenable, this.listener);

  final Listenable listenable;
  final VoidCallback listener;
}

/// ctx 句柄 id → {type → 订阅项}。
///
/// **去重是必需的**：JS 侧 `context.watch<T>()` 写在 build 里，每次重建都会重发
/// 同名 op；不去重就会往同一个对象上叠无数监听器。
final Map<String, Map<String, _CtxWatch>> _ctxWatches = {};

/// JS 侧 `context.watch<T>()` / `context.read<T>()` 落到宿主**真值 BuildContext**
/// 上的权威查找：句柄 id → 结点 id → 该结点的真值 BuildContext → 交给各已注册
/// 三方库的 [JsUiLibrary.resolveWatchTarget] 按类型名解析（先注册者优先）。
///
/// **职责分工**：JS 侧的**取值**留在 JS 内（同步约束：build 里
/// `context.watch<T>().count` 与事件串的链式调用都是同步求值，而 JS→宿主只有
/// 异步桥），JS 的 `watch` 同步返回自己解析出的值；**订阅**则落在 Dart 侧——
/// `watch` op 让该位置的 `_JsNode` element 订阅（按类型解析出的那个对象），
/// 它变更时标脏重建，与 Dart `context.watch<T>()` 建立依赖的语义一致。
///
/// 查不到（或类型不匹配）说明 JS 侧解析越过了提供者边界（消费点被放到了
/// provider 子树之外），按项目规则出运行时告警而非静默。
Object? _resolveContextOp(String id, String op, Map payload) {
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
  final target = resolveWatchTarget(context, type);
  if (target == null) {
    // 只在**本端也没找到**时告警：否则是宿主侧本就没有该作用域的镜像
    // （将来 JS-only 的作用域族），属正常情形，不该报错。
    if (payload['found'] != true) {
      HotPatchLog.log(
        '[jsui] context.$op("$type") 在宿主真值 context 上找不到该类型的提供者'
        '（结点 $id；消费点可能在 provider 子树之外）',
      );
    }
    return null;
  }
  // read 不建依赖（对齐 Flutter：read 只取值、不随 notify 重建）。
  if (op == 'watch') _subscribeNode(id, type, target);
  return null;
}

/// 让该位置（ctx 句柄 id 对应的 `_JsNode` element）**按类型精确订阅**。
///
/// 订阅挂的是 [JsUiLibrary.resolveWatchTarget] 按类型解析出的那个对象——不是
/// 「最近的那个提供者」（里层嵌套了别的类型时会订错），也不是 props 里顺手
/// 拿到的那个。被订阅者 notify → 该 element 标脏 → 重建（重建时重新读 JS
/// 已补丁后的值）。
void _subscribeNode(String ctxId, String type, Listenable target) {
  final subs = _ctxWatches[ctxId] ??= <String, _CtxWatch>{};
  // 同一类型已订阅同一个对象：重建重发 op，直接返回（不叠监听器）。
  if (subs[type]?.listenable == target) return;
  // 解析结果变了（如提供者结点被替换）：先摘旧订阅再挂新的，避免悬空监听。
  _unsubscribeOne(subs, type);
  void listener() {
    final context = jsBuildContextOf(ctxId);
    if (context is Element && context.mounted) context.markNeedsBuild();
  }

  subs[type] = _CtxWatch(target, listener);
  target.addListener(listener);
}

/// 摘除某类型在当前位置的订阅（无则空操作）。
void _unsubscribeOne(Map<String, _CtxWatch> subs, String type) {
  final old = subs.remove(type);
  if (old == null) return;
  old.listenable.removeListener(old.listener);
}

/// ctx 句柄释放（组件卸载 / 页面销毁）：摘除该位置的全部订阅。
void _releaseCtxWatch(String ctxId) {
  final subs = _ctxWatches.remove(ctxId);
  if (subs == null) return;
  for (final watch in subs.values) {
    watch.listenable.removeListener(watch.listener);
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
