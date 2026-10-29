// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar_details.dart 自动生成
// 重新生成：dart run build_runner build

import { TestString1 } from 'extension/e_string.js';
import { StringLogExtension } from '../extensions/hot_module_base.js';
import { Column, ElevatedButton, SizedBox, Text } from '../flutter.js';

// 组件 MixinDetail
export class MixinDetail {
  constructor(args) {
    this.props = args || {};
    this._count = 0;
  }
  _bump() {
    this.setState(() => { this._count += 1; });
    this.logState("计数变为 " + this._count);
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "State 混入 StateLogMixin（跨包 mixin）",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "点击按钮后 setState + 调用 mixin 提供的 logState，控制台输出 [StateLogMixin] ...",
          "style": {
            "color": Colors.black54,
            "fontSize": 13
          }
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": {
            "fontSize": 20
          },
          "data": "当前计数：" + this._count
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new ElevatedButton({
          "onPressed": this.__bindFn(0, [], (...__a) => this._bump(...__a)),
          "child": (this.__k4 || (this.__k4 = new Text({
            "data": "+1 并打日志"
          })))
        })
      ]
    });
  }
  // ---- mixin StateLogMixin ----
  logState(message) {
    console.log("[StateLogMixin] " + __str(message));
  }
}

// 组件 ExtensionDetail
export class ExtensionDetail {
  constructor(args) {
    this.props = args || {};
  }
  _log() {
    "扩展方法打印的日志".logText("ExtensionDetail");
    "test".log1();
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "String 扩展 logText（跨包 extension）",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "调用 '扩展方法打印的日志'.logText('ExtensionDetail')，控制台输出 [ExtensionDetail] ...",
          "style": {
            "color": Colors.black54,
            "fontSize": 13
          }
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new ElevatedButton({
          "onPressed": this.__bindFn(0, [], (...__a) => this._log(...__a)),
          "child": (this.__k4 || (this.__k4 = new Text({
            "data": "调用 String.logText()"
          })))
        })
      ]
    });
  }
}

