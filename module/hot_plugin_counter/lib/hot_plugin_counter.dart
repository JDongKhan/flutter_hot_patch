import 'package:flutter/services.dart';

/// 模拟第三方插件 B：原生计数器（另一个独立 channel）。
///
/// 与插件 A 同时存在于同一页面，用于验证「多个三方库、多个 channel」共用
/// 同一个 JS MethodChannel 镜像与同一个宿主入口。
class HotPluginCounter {
  static const MethodChannel _channel =
      MethodChannel('hot_patch/demo/counter');

  static Future<int> increment(int step) async {
    final value = await _channel.invokeMethod('increment', {'step': step});
    return value is int ? value : 0;
  }

  static Future<int> reset() async {
    final value = await _channel.invokeMethod('reset');
    return value is int ? value : 0;
  }
}
