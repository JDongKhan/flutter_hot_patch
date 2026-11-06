// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/callable_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, CrossAxisAlignment, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../../flutter.js';

// 模型 Adder
export class Adder {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.delta = (args && args.delta !== undefined) ? args.delta : 0;
  }
  invoke(v) {
    return (v + this.delta);
  }
}

// 组件 CallableDetail
export class CallableDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  _callText() {
    const add = new Adder({
      "delta": 3
    });
    return "call：add(1)=" + add.invoke(1) + " / add.call(2)=" + add.invoke(2);
  }
  _functionCallText() {
    const twice = (v) => { return (v * 2); };
    const fn = twice;
    const typed = twice;
    return "Function.call：fn.call(3)=" + fn(3) + " " + "/ typed.call(2)=" + typed(2) + " " + "/ fn(4)=" + fn(4);
  }
  _fnValueCallText() {
    const twice = (v) => { return (v * 2); };
    const quad = ((v) => { return (v * 2); })(3);
    const picked = ((twice ?? ((v) => { return v; })))(5);
    return "函数值调用：" + quad + "/" + picked;
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "callable 对象 · Function.call · 函数值调用",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": this._callText()
        }),
        new Text({
          "data": this._functionCallText()
        }),
        new Text({
          "data": this._fnValueCallText()
        })
      ]
    });
  }
}

