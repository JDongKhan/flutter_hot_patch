// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/async_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, Completer, CrossAxisAlignment, Duration, ElevatedButton, FontWeight, Future, OutlinedButton, Row, SizedBox, StateError, StatefulWidget, Text, TextStyle, int } from '../flutter.js';

// 组件 AsyncDetail
export class AsyncDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._status = "未启动";
    this._error = "未触发";
    this._busy = false;
  }
  async _run() {
    if (this._busy) {
      return;
    }
    this.setState(() => {
      this._busy = true;
      this._status = "等待 complete…";
    });
    const completer = new Completer({typeArguments: {"T": "int"}});
    Future.delayed(new Duration({milliseconds: 300}), () => { return completer.complete(42); });
    const value = await completer.future;
    this.setState(() => {
      this._status = "收到 " + value + "，isCompleted=" + completer.isCompleted;
      this._busy = false;
    });
  }
  async _runError() {
    const completer = new Completer({typeArguments: {"T": "int"}});
    Future.delayed(new Duration({milliseconds: 200}), () => { return completer.completeError(new StateError({message: "演示错误"})); });
    try {
      await completer.future;
    } catch (__e) {
      if (__e instanceof StateError) {
        const e = __e;
        this.setState(() => {
          this._error = "捕获：" + e;
        });
      }
      else {
        throw __e;
      }
    }
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "异步：Future / await / Completer",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "状态：" + this._status
        }),
        new Text({
          "data": "异常分支：" + this._error
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        new Row({
          "children": [
            new ElevatedButton({
              "onPressed": () => this._run(),
              "child": (this.__k3 || (this.__k3 = new Text({
                "data": "complete(42)"
              })))
            }),
            (this.__k4 || (this.__k4 = new SizedBox({
              "width": 12
            }))),
            new OutlinedButton({
              "onPressed": () => this._runError(),
              "child": (this.__k5 || (this.__k5 = new Text({
                "data": "completeError"
              })))
            })
          ]
        })
      ]
    });
  }
}

