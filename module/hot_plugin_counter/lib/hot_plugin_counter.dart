import 'package:flutter/services.dart';

/// 模拟第三方插件 B：原生计数器（另一个独立 channel）。
///
/// 与插件 A 同时存在于同一页面，用于验证「多个三方库、多个 channel」共用
/// 同一个 JS MethodChannel 镜像与同一个宿主入口。
class HotPluginCounter {
  static const MethodChannel _channel =
      MethodChannel('hot_patch/demo/counter');

  /// handler 只绑定一次（与 Dart 侧「同名 channel 一个 handler」一致）。
  static bool _bound = false;

  static void _bindHandler() {
    if (_bound) return;
    _bound = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNativeEvent') {
        final value = call.arguments;
        return 'ack:' + (value == null ? '' : value.toString());
      }
      return null;
    });
  }

  static Future<int> increment(int step) async {
    final value = await _channel.invokeMethod('increment', {'step': step});
    return value is int ? value : 0;
  }

  static Future<int> reset() async {
    final value = await _channel.invokeMethod('reset');
    return value is int ? value : 0;
  }

  /// 验证反向通道：Dart/JS 先发 `pingFromNative`，原生收到后立刻通过同一个
  /// channel 反向调用 `onNativeEvent`；handler 的返回值再作为本次调用的结果。
  static Future<String> pingFromNative() async {
    _bindHandler();
    final value = await _channel.invokeMethod('pingFromNative');
    return value == null ? '' : value.toString();
  }
}
