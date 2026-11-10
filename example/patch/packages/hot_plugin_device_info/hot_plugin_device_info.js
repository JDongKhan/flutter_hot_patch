// GENERATED CODE - DO NOT EDIT
// 跨包产物（package: hot_plugin_device_info）：由 hot_patch_generator 生成
// 源文件：package:hot_plugin_device_info/hot_plugin_device_info.dart（一个源文件一份产物）

import { MethodChannel } from '../../flutter.js';

// 模型 HotPluginDeviceInfo
export class HotPluginDeviceInfo {
  static _channel = new MethodChannel({name: "hot_patch/demo/device_info"});
  constructor() {
  }
  static async platformVersion() {
    const value = await HotPluginDeviceInfo._channel.invokeMethod("platformVersion");
    return ((__nn(value) == null) ? "unknown" : value.toString());
  }
  static async deviceName() {
    const value = await HotPluginDeviceInfo._channel.invokeMethod("deviceName");
    return ((__nn(value) == null) ? "unknown" : value.toString());
  }
}
