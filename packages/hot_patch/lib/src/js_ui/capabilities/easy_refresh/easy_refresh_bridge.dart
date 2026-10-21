// ===== 能力：EasyRefresh 下拉刷新（通道 + 桥接组件 + 组件注册）=====
//
// 一个能力 = 通道 + 桥接组件 + 组件注册，全部内聚在本文件。
//
// EasyRefresh（三方包 flutter_easy_refresh）的**手势 / 物理 / 指示器**全在宿主
// 侧，回调 onRefresh / onLoad 由 JS 补丁实现，所以需要一次「宿主发起 → JS 异步
// 完成」的往返：
//   1. 宿主 → JS：用户下拉后按事件句柄触发 [jsFragments] 里的 `__jsuiAwaitRun`
//      （见 easy_refresh_js.dart）；
//   2. JS → 宿主：JS 侧 await 完任务后经宿主通道 [awaitDoneChannel] 回传 token；
//   3. 本文件把 token ↔ Completer，交给 EasyRefresh 的 onRefresh/onLoad，
//      指示器在 JS 任务**真正结束**时才收起。
//
// 为什么不直接复用 [JsUiWidgetState._invoke]：它是单向的——宿主调完 JS 即返回，
// 而 JS 的 Promise 在 iOS/JavaScriptCore 上无法回传 Dart，拿不到完成信号，
// 指示器会瞬间消失（用户看不到任何加载反馈）。
import 'dart:async';
import 'dart:convert';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/widgets.dart';

import '../../../services/js_runtime_manager.dart';
import '../../js_widget_registry.dart';

/// 完成信号通道：JS 侧 await 完事件后回传 token（见 easy_refresh_js.dart）。
const String awaitDoneChannel = 'jsuiAwaitDone';

/// token → 等待中的刷新/加载任务；JS 回传后结算并摘除（避免条目滞留）。
final Map<String, Completer<void>> _pendingTasks = {};

int _tokenSeq = 0;

bool _channelsRegistered = false;

/// 幂等登记本能力的宿主通道（由 js_ui_capabilities 聚合调用）。
void ensureEasyRefreshChannels() {
  if (_channelsRegistered) return;
  _channelsRegistered = true;
  JsRuntimeManager.registerHostMethod(awaitDoneChannel, (String token) {
    _pendingTasks.remove(token)?.complete();
  });
}

/// 宿主发起一次「JS 侧异步事件」，返回等待其完成的 Future。
///
/// [handler] 是 JS 侧事件句柄（`{'__fn': id}`，由生成器在构建期产出）。
/// 句柄缺失 / 形态不对时立即完成：等价于「无事可做」，不阻塞指示器收起。
Future<void> _runAwaitableEvent(Object? handler) {
  final id = handler is Map ? handler['__fn'] : null;
  if (id is! String) return Future<void>.value();
  final token = 'er${++_tokenSeq}';
  final completer = Completer<void>();
  _pendingTasks[token] = completer;
  JsRuntimeManager.instance.evaluate(
    '__jsuiAwaitRun(${jsonEncode(id)}, ${jsonEncode(token)});',
  );
  // 兜底超时：JS 运行时被销毁 / 句柄在任务中释放时回传永不到达，指示器不能
  // 永远转圈，也不能让条目滞留在 _pendingTasks。
  return completer.future.timeout(
    const Duration(seconds: 30),
    onTimeout: () => _pendingTasks.remove(token),
  );
}

/// EasyRefresh 桥接组件（对应注册 key 'EasyRefresh'）。
///
/// JS 侧写法：
/// ```js
/// __h('EasyRefresh', { onRefresh: this.__bindFn(3, [], () => this._load()), child: __h('CustomScrollView', ...) })
/// ```
/// 用户下拉 → 宿主触发 JS `_load()` → JS 侧 await 其 Promise → 回传完成 →
/// 指示器收起。onRefresh / onLoad 为 null 时对应方向禁用（包的
/// NotRefreshHeader / NotLoadFooter 语义）。
///
/// 指示器样式统一用包内默认（ClassicHeader / ClassicFooter）：样式对象
/// （Header/Footer / EasyRefreshController）在 JS 侧没有等价物，且属「视觉
/// 细节」而非页面逻辑，不做翻译。
class _JsEasyRefresh extends StatelessWidget {
  const _JsEasyRefresh({
    required this.onRefresh,
    required this.onLoad,
    required this.refreshOnStart,
    required this.child,
  });

  /// JS 侧事件句柄（`{'__fn': id}`）；null = 该方向禁用。
  final Object? onRefresh;
  final Object? onLoad;

  /// 挂载即触发一次刷新（对应 Dart 的 `refreshOnStart: true`）。
  final bool refreshOnStart;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      onRefresh: onRefresh == null ? null : () => _runAwaitableEvent(onRefresh),
      onLoad: onLoad == null ? null : () => _runAwaitableEvent(onLoad),
      refreshOnStart: refreshOnStart,
      child: child,
    );
  }
}

/// EasyRefresh 能力域组件注册。
void registerEasyRefreshWidgets(JsWidgetRegistry r) {
  r.register(
    'EasyRefresh',
    (c) => _JsEasyRefresh(
      onRefresh: c.props['onRefresh'],
      onLoad: c.props['onLoad'],
      refreshOnStart: c.bool_('refreshOnStart') ?? false,
      // `child:` 统一进 children（生成器的子结点约定）→ 取第一个子结点。
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );
}
