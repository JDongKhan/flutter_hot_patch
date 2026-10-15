// ===== provider：`context.watch<T>()` / `context.read<T>()` 的宿主侧 =====
//
// 对齐 Flutter：`context.watch/read` 不是 BuildContext 的框架 API，而是 provider
// 的 `extension BuildContextX on BuildContext`。故这套语义**属于本库**，不属于
// 核心——JS 侧的方法补丁在 provider_js.dart，宿主侧的处理在本文件，经核心的
// 通用缝 `registerContextOp`（见 capabilities/build_context/build_context_bridge.dart）
// 注册进来。核心从此不认识 `watch` / `read`。
//
// **职责分工**（同步约束）：JS 侧的**取值**留在 JS 内（build 里
// `context.watch<T>().count` 与事件串的链式调用都是同步求值，而 JS→宿主只有
// 异步桥），JS 的 `watch` 同步返回自己沿作用域取到的值；**订阅**落在本文件——
// `watch` op 让该位置的 `_JsNode` element 订阅按类型解析出的那个 VM，它 notify
// 时标脏重建，与 Dart `context.watch<T>()` 建立依赖的语义一致。
import 'package:flutter/widgets.dart';

import '../../../utils/hot_patch_log.dart';
import '../build_context/build_context_bridge.dart';
import '../change_notifier/change_notifier_bridge.dart';
import 'provider_bridge.dart';

/// 一个「按类型订阅」的登记项：按类型解析出的可订阅对象 + 它到该结点 element
/// 的监听回调。
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

bool _contextOpsRegistered = false;

/// 把 provider 的 context op 注册进核心的分发缝（由 ProviderLibrary.ensureChannels 调用）。
///
/// op 名沿用 JS 侧的调用名（`context.watch<T>()` → `watch`）。
void ensureProviderContextOps() {
  if (_contextOpsRegistered) return;
  _contextOpsRegistered = true;
  registerContextOp(
    'watch',
    onOp: (ctxId, op, payload) => _resolveWatchOp(ctxId, op, payload),
    // 订阅挂在本文件，故句柄释放时要摘除（否则监听器悬空）。
    onRelease: _releaseCtxWatch,
  );
  // read 只取值、不建依赖（对齐 Flutter），无需释放清理。
  registerContextOp(
    'read',
    onOp: (ctxId, op, payload) => _resolveWatchOp(ctxId, op, payload),
  );
}

/// `context.watch<T>()` / `read<T>()` 落到宿主**真值 BuildContext** 上的权威查找：
/// 句柄 id → 结点 id → 该结点的真值 BuildContext → 按 `jsType == T` 精确解析出 VM。
///
/// 查不到（或类型不匹配）说明 JS 侧解析越过了提供者边界（消费点被放到了
/// provider 子树之外），按项目规则出运行时告警而非静默。
Object? _resolveWatchOp(String ctxId, String op, Map payload) {
  final type = payload['type'];
  if (type is! String || type.isEmpty) return null;
  final context = jsBuildContextOf(ctxId);
  // 结点尚未登记 / 已卸载（构建时序或卸载竞态）：静默跳过。
  if (context == null) return null;
  final target = jsChangeNotifierOfTypeAt(context, type);
  if (target == null) {
    // 只在**本端也没找到**时告警：否则是宿主侧本就没有该作用域的镜像
    // （将来 JS-only 的作用域族），属正常情形，不该报错。
    if (payload['found'] != true) {
      HotPatchLog.log(
        '[jsui] context.$op("$type") 在宿主真值 context 上找不到该类型的提供者'
        '（结点 $ctxId；消费点可能在 provider 子树之外）',
      );
    }
    return null;
  }
  // read 不建依赖（对齐 Flutter：read 只取值、不随 notify 重建）。
  if (op == 'watch') _subscribeNode(ctxId, type, target);
  return null;
}

/// 让该位置（ctx 句柄 id 对应的 `_JsNode` element）**按类型精确订阅**。
///
/// 订阅挂的是 [jsChangeNotifierOfTypeAt] 按类型解析出的那个 VM——不是「最近的那个
/// 提供者」（里层嵌套了别的类型时会订错），也不是 props 里顺手拿到的那个。被订阅者
/// notify → 该 element 标脏 → 重建（重建时重新读 JS 已补丁后的值）。
void _subscribeNode(String ctxId, String type, JsChangeNotifier target) {
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
