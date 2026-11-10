import 'package:flutter/services.dart';

/// 模拟第三方插件 A：设备信息（独立包 + 独立 channel）。
///
/// 被翻译成 JS 后，`MethodChannel` 由 `flutter.js` 的同名镜像承接，
/// 宿主再按 `(name, codec)` 转回真正的 Flutter MethodChannel。
class HotPluginDeviceInfo {
  static const MethodChannel _channel =
      MethodChannel('hot_patch/demo/device_info');

  static Future<String> platformVersion() async {
    final value = await _channel.invokeMethod('platformVersion');
    return value == null ? 'unknown' : value.toString();
  }

  static Future<String> deviceName() async {
    final value = await _channel.invokeMethod('deviceName');
    return value == null ? 'unknown' : value.toString();
  }
}
