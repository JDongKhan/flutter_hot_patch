import 'dart:async';

import 'package:flutter/services.dart';

import '../../js_ui/js_widget_registry.dart';
import 'builtin_host_method_group.dart';
import 'channel_shared.dart';

/// JS 侧 `EventChannel`：receiveBroadcastStream 的订阅与取消。
final class EventChannelHostMethods extends BuiltinHostMethodGroup {
  /// 活跃的 EventChannel 订阅：subId（JS 侧租约）→ Dart 侧 StreamSubscription。
  final Map<String, StreamSubscription<dynamic>> _subs = {};

  @override
  Map<String, Function> get methods => {
    'eventChannelListen': _listen,
    'eventChannelCancel': _cancel,
  };

  /// `eventChannelListen`：JS 侧 `receiveBroadcastStream()` 首个订阅者出现时注册。
  ///
  /// 宿主把原生事件按参数数组回传 JS：`['data', v]` / `['error', msg]` /
  /// `['done']`（见 `event_channel_js.dart` 的回调包装）。
  Future<Object?> _listen(
    String subId,
    String name,
    String codec,
    Object? arguments,
    String handlerId,
  ) async {
    _subs.remove(subId)?.cancel();
    final channel = EventChannel(name, codecOf(codec));
    _subs[subId] = channel
        .receiveBroadcastStream(arguments)
        .listen(
          (value) => invokeJsHandler({'__fn': handlerId}, ['data', value]),
          onError: (Object e, StackTrace st) =>
              invokeJsHandler({'__fn': handlerId}, ['error', '$e']),
          onDone: () => invokeJsHandler({'__fn': handlerId}, ['done']),
        );
    return null;
  }

  /// `eventChannelCancel`：JS 侧订阅者归零 / 页面销毁时取消宿主订阅。
  Future<Object?> _cancel(String subId) async {
    _subs.remove(subId)?.cancel();
    return null;
  }
}
