// GENERATED CODE - DO NOT EDIT
// 跨包产物（package: hot_plugin_counter）：由 hot_patch_generator 生成
// 源文件：package:hot_plugin_counter/hot_plugin_counter.dart（一个源文件一份产物）

import { MethodChannel } from '../../flutter.js';

// 模型 HotPluginCounter
export class HotPluginCounter {
  static _channel = new MethodChannel({name: "hot_patch/demo/counter"});
  constructor() {
  }
  static async increment(step) {
    const value = await HotPluginCounter._channel.invokeMethod("increment", new Map([["step", step]]));
    return ((Number.isInteger(value)) ? value : 0);
  }
  static async reset() {
    const value = await HotPluginCounter._channel.invokeMethod("reset");
    return ((Number.isInteger(value)) ? value : 0);
  }
}
