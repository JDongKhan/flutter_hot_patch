// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/method_channel_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { HotPluginDeviceInfo } from '../packages/hot_plugin_device_info/hot_plugin_device_info.js';
import { HotPluginCounter } from '../packages/hot_plugin_counter/hot_plugin_counter.js';
import { BasicMessageChannel, Card, Colors, Column, CrossAxisAlignment, EdgeInsets, ElevatedButton, EventChannel, FontWeight, OutlinedButton, Padding, SizedBox, StatefulWidget, Text, TextStyle, Wrap } from '../flutter.js';

// 组件 MethodChannelDetail
export class MethodChannelDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._deviceInfo = "未调用";
    this._counter = "未调用";
    this._handlerResult = "未调用";
    this._messageResult = "未调用";
    this._tickState = "未订阅";
    this._tick = 0;
    this._tickSub = null;
    this._busy = false;
  }
  dispose() {
    this._tickSub?.cancel();
    super.dispose();
  }
  _startTicks() {
    this._tickSub?.cancel();
    this.setState(() => {
      this._tickState = "订阅中（每 500ms）";
    });
    this._tickSub = HotPluginDeviceInfo.ticks().listen((event) => { if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._tick = ((Number.isInteger(event)) ? event : 0);
      }); });
  }
  _stopTicks() {
    this._tickSub?.cancel();
    this._tickSub = null;
    this.setState(() => {
      this._tickState = "已取消";
    });
  }
  async _readDeviceInfo() {
    this.setState(() => {
      this._busy = true;
      this._deviceInfo = "调用中…";
    });
    try {
      const version = await HotPluginDeviceInfo.platformVersion();
      const name = await HotPluginDeviceInfo.deviceName();
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._deviceInfo = ((version + " · ") + name);
        this._busy = false;
      });
    } catch (__e) {
      const e = __e;
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._deviceInfo = ("调用失败：" + e.toString());
        this._busy = false;
      });
    }
  }
  async _increment(step) {
    this.setState(() => {
      this._busy = true;
    });
    try {
      const value = await HotPluginCounter.increment(step);
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._counter = ("原生计数：" + value.toString());
        this._busy = false;
      });
    } catch (__e) {
      const e = __e;
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._counter = ("调用失败：" + e.toString());
        this._busy = false;
      });
    }
  }
  async _resetCounter() {
    this.setState(() => {
      this._busy = true;
    });
    try {
      const value = await HotPluginCounter.reset();
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._counter = ("原生计数：" + value.toString());
        this._busy = false;
      });
    } catch (__e) {
      const e = __e;
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._counter = ("调用失败：" + e.toString());
        this._busy = false;
      });
    }
  }
  async _pingFromNative() {
    this.setState(() => {
      this._busy = true;
      this._handlerResult = "调用中…";
    });
    try {
      const value = await HotPluginCounter.pingFromNative();
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._handlerResult = value;
        this._busy = false;
      });
    } catch (__e) {
      const e = __e;
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._handlerResult = ("调用失败：" + e.toString());
        this._busy = false;
      });
    }
  }
  async _echoMessage() {
    this.setState(() => {
      this._busy = true;
      this._messageResult = "调用中…";
    });
    try {
      const value = await HotPluginDeviceInfo.echoMessage("hello");
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._messageResult = value;
        this._busy = false;
      });
    } catch (__e) {
      const e = __e;
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._messageResult = ("调用失败：" + e.toString());
        this._busy = false;
      });
    }
  }
  async _reverseMessage() {
    this.setState(() => {
      this._busy = true;
      this._messageResult = "调用中…";
    });
    try {
      const value = await HotPluginDeviceInfo.reverseMessage();
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._messageResult = value;
        this._busy = false;
      });
    } catch (__e) {
      const e = __e;
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._messageResult = ("调用失败：" + e.toString());
        this._busy = false;
      });
    }
  }
  _card(__o) {
    let title = (__o && __o.title !== undefined) ? __o.title : null;
    let channel = (__o && __o.channel !== undefined) ? __o.channel : null;
    let result = (__o && __o.result !== undefined) ? __o.result : null;
    let actions = (__o && __o.actions !== undefined) ? __o.actions : null;
    return new Card({
      "margin": (this.__k0 || (this.__k0 = EdgeInsets.only({
        "bottom": 12
      }))),
      "child": new Padding({
        "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
          "value": 16
        }))),
        "child": new Column({
          "crossAxisAlignment": CrossAxisAlignment.start,
          "children": [
            new Text({
              "style": (this.__k2 || (this.__k2 = new TextStyle({
                "fontWeight": FontWeight.bold
              }))),
              "data": title
            }),
            (this.__k3 || (this.__k3 = new SizedBox({
              "height": 4
            }))),
            new Text({
              "style": (this.__k4 || (this.__k4 = new TextStyle({
                "color": Colors.grey,
                "fontSize": 12
              }))),
              "data": ("channel: " + channel)
            }),
            (this.__k5 || (this.__k5 = new SizedBox({
              "height": 10
            }))),
            new Text({
              "data": result
            }),
            (this.__k5 || (this.__k5 = new SizedBox({
              "height": 10
            }))),
            new Wrap({
              "spacing": 8,
              "children": actions
            })
          ]
        })
      })
    });
  }
  build(context) {
    return new Padding({
      "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
        "value": 16
      }))),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.start,
        "children": [
          (this.__k6 || (this.__k6 = new Text({
            "data": "同一页面同时调用两个独立三方库的 channel；" + "原生模式与 JS 热更模式会分别走各自链路，结果一致。",
            "style": new TextStyle({
              "color": Colors.grey
            })
          }))),
          (this.__k7 || (this.__k7 = new SizedBox({
            "height": 16
          }))),
          this._card({ "title": "插件 A · hot_plugin_device_info", "channel": "hot_patch/demo/device_info", "result": this._deviceInfo, "actions": [new ElevatedButton({
                "onPressed": () => { if (this._busy) {
                    return;
                  }
                  this._readDeviceInfo(); },
                "child": (this.__k8 || (this.__k8 = new Text({
                  "data": "读取设备信息"
                })))
              })] }),
          this._card({ "title": "插件 A · BasicMessageChannel", "channel": "hot_patch/demo/device_info_msg（send / setMessageHandler）", "result": this._messageResult, "actions": [new ElevatedButton({
                "onPressed": () => { if (this._busy) {
                    return;
                  }
                  this._echoMessage(); },
                "child": (this.__k9 || (this.__k9 = new Text({
                  "data": "send echo"
                })))
              }), new OutlinedButton({
                "onPressed": () => { if (this._busy) {
                    return;
                  }
                  this._reverseMessage(); },
                "child": (this.__k10 || (this.__k10 = new Text({
                  "data": "原生回调 JS"
                })))
              })] }),
          this._card({ "title": "插件 A · EventChannel", "channel": "hot_patch/demo/device_info_events（原生推送）", "result": ((this._tickState + " · tick=") + this._tick.toString()), "actions": [new ElevatedButton({
                "onPressed": () => { this._startTicks(); },
                "child": (this.__k11 || (this.__k11 = new Text({
                  "data": "订阅"
                })))
              }), new OutlinedButton({
                "onPressed": () => { this._stopTicks(); },
                "child": (this.__k12 || (this.__k12 = new Text({
                  "data": "取消"
                })))
              })] }),
          this._card({ "title": "插件 B · hot_plugin_counter", "channel": "hot_patch/demo/counter", "result": this._counter, "actions": [new ElevatedButton({
                "onPressed": () => { if (this._busy) {
                    return;
                  }
                  this._increment(1); },
                "child": (this.__k13 || (this.__k13 = new Text({
                  "data": "+1"
                })))
              }), new ElevatedButton({
                "onPressed": () => { if (this._busy) {
                    return;
                  }
                  this._increment(5); },
                "child": (this.__k14 || (this.__k14 = new Text({
                  "data": "+5"
                })))
              }), new OutlinedButton({
                "onPressed": () => { if (this._busy) {
                    return;
                  }
                  this._resetCounter(); },
                "child": (this.__k15 || (this.__k15 = new Text({
                  "data": "重置"
                })))
              })] }),
          this._card({ "title": "插件 B · setMethodCallHandler", "channel": "原生 → Flutter → JS（同一 channel 反向调用）", "result": this._handlerResult, "actions": [new ElevatedButton({
                "onPressed": () => { if (this._busy) {
                    return;
                  }
                  this._pingFromNative(); },
                "child": (this.__k10 || (this.__k10 = new Text({
                  "data": "原生回调 JS"
                })))
              })] })
        ]
      })
    });
  }
}

