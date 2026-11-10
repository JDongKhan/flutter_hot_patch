import 'package:flutter/services.dart';

/// 模拟第三方插件 A：设备信息（独立包 + 独立 channel）。
///
/// 被翻译成 JS 后，`MethodChannel` 由 `flutter.js` 的同名镜像承接，
/// 宿主再按 `(name, codec)` 转回真正的 Flutter MethodChannel。
class HotPluginDeviceInfo {
  static const MethodChannel _channel =
      MethodChannel('hot_patch/demo/device_info');

  /// 同一插件里的第二种通道：BasicMessageChannel（独立名字，互不影响）。
  static const BasicMessageChannel<dynamic> _messageChannel =
      BasicMessageChannel<dynamic>(
    'hot_patch/demo/device_info_msg',
    StandardMessageCodec(),
  );

  /// 第三种通道：EventChannel（原生主动推送的事件流）。
  ///
  /// [tag] 是 channel 名后缀：同名平台通道只能有一个活跃流，同一进程里原生 /
  /// JS 两栏对比时各传一个 tag，避免两个实例互相顶掉订阅。
  static Stream<dynamic> ticks(String tag) =>
      EventChannel('hot_patch/demo/device_info_events' + tag)
          .receiveBroadcastStream();

  static bool _messageBound = false;

  static void _bindMessageHandler() {
    if (_messageBound) return;
    _messageBound = true;
    _messageChannel.setMessageHandler((message) async {
      if (message == 'ping') return 'dart:pong';
      return null;
    });
  }

  static Future<String> platformVersion() async {
    final value = await _channel.invokeMethod('platformVersion');
    return value == null ? 'unknown' : value.toString();
  }

  static Future<String> deviceName() async {
    final value = await _channel.invokeMethod('deviceName');
    return value == null ? 'unknown' : value.toString();
  }

  /// BasicMessageChannel 正向：JS/Dart send → 原生 reply。
  static Future<String> echoMessage(String text) async {
    final reply = await _messageChannel.send('echo:' + text);
    return reply == null ? '' : reply.toString();
  }

  /// BasicMessageChannel 反向：原生 send → JS/Dart handler → reply 回原生，
  /// 回执再作为本次 send 的 reply。
  static Future<String> reverseMessage() async {
    _bindMessageHandler();
    final reply = await _messageChannel.send('reverse');
    return reply == null ? '' : reply.toString();
  }
}
