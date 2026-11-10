// GENERATED CODE - DO NOT EDIT
// 跨包产物（package: hot_plugin_device_info）：由 hot_patch_generator 生成
// 源文件：package:hot_plugin_device_info/hot_plugin_device_info.dart（一个源文件一份产物）

import { BasicMessageChannel, EventChannel, MethodChannel, StandardMessageCodec } from '../../flutter.js';

// 模型 HotPluginDeviceInfo
export class HotPluginDeviceInfo {
  static _channel = new MethodChannel({name: "hot_patch/demo/device_info"});
  static _messageChannel = new BasicMessageChannel({name: "hot_patch/demo/device_info_msg", codec: new StandardMessageCodec(), typeArguments: {"T": "dynamic"}});
  static _eventChannel = new EventChannel({name: "hot_patch/demo/device_info_events"});
  static _messageBound = false;
  constructor() {
  }
  static ticks() {
    return HotPluginDeviceInfo._eventChannel.receiveBroadcastStream();
  }
  static _bindMessageHandler() {
    if (HotPluginDeviceInfo._messageBound) {
      return;
    }
    HotPluginDeviceInfo._messageBound = true;
    HotPluginDeviceInfo._messageChannel.setMessageHandler(async (message) => { if ((message === "ping")) {
        return "dart:pong";
      }
      return null; });
  }
  static async platformVersion() {
    const value = await HotPluginDeviceInfo._channel.invokeMethod("platformVersion");
    return ((__nn(value) == null) ? "unknown" : value.toString());
  }
  static async deviceName() {
    const value = await HotPluginDeviceInfo._channel.invokeMethod("deviceName");
    return ((__nn(value) == null) ? "unknown" : value.toString());
  }
  static async echoMessage(text) {
    const reply = await HotPluginDeviceInfo._messageChannel.send(("echo:" + text));
    return ((__nn(reply) == null) ? "" : reply.toString());
  }
  static async reverseMessage() {
    HotPluginDeviceInfo._bindMessageHandler();
    const reply = await HotPluginDeviceInfo._messageChannel.send("reverse");
    return ((__nn(reply) == null) ? "" : reply.toString());
  }
}
