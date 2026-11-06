// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/stream_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, CrossAxisAlignment, Duration, ElevatedButton, FontWeight, Future, OutlinedButton, SizedBox, StatefulWidget, Stream, StreamController, Text, TextStyle, Wrap, int } from '../flutter.js';

// 组件 StreamDetail
export class StreamDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._listen = "未订阅";
    this._controller = "未启动";
    this._broadcast = "未启动";
    this._awaitFor = "未启动";
    this._transformed = "未启动";
    this._sub = null;
  }
  _ticks(count) {
    return Stream.fromAsyncGenerator((async function* () {
      for (let i = 1; (i <= count); (i++)) {
        await Future.delayed({duration: new Duration({milliseconds: 150})});
        yield i;
      }
    }).bind(this)());
  }
  _startListen() {
    this._sub?.cancel();
    const values = [];
    this.setState(() => {
      this._listen = "订阅中…";
    });
    this._sub = this._ticks(3).listen((v) => { values.add(v);
      this.setState(() => {
        this._listen = "收到 " + values._join(",");
      }); }, { "onError": (e) => { this.setState(() => {
          this._listen = "错误：" + e;
        }); }, "onDone": () => { this.setState(() => {
          this._listen = "完成：" + values._join(",");
        }); } });
  }
  async _pauseResume() {
    this._sub?.cancel();
    const values = [];
    const sub = this._ticks(3).listen((v) => { values.add(v);
      this.setState(() => {
        this._listen = "缓冲中：" + values._join(",");
      }); });
    this._sub = sub;
    sub.pause();
    await Future.delayed({duration: new Duration({milliseconds: 650})});
    sub.resume();
    await Future.delayed({duration: new Duration({milliseconds: 250})});
    this.setState(() => {
      this._listen = "resume：" + values._join(",");
    });
  }
  async _runController() {
    const controller = new StreamController({typeArguments: {"T": "int"}});
    const answer = controller.stream.map((v) => { return (v * 2); }).toList();
    controller.add(10);
    controller.add(20);
    await controller.close();
    const values = await answer;
    this.setState(() => {
      this._controller = values.join(",") + " / isClosed=" + controller.isClosed;
    });
  }
  async _runBroadcast() {
    const controller = StreamController.broadcast({typeArguments: {"T": "int"}});
    const a = [];
    const b = [];
    controller.stream.listen((v) => { return a.add(v); });
    controller.stream.listen((v) => { return b.add(v); });
    controller.add(1);
    controller.add(2);
    await controller.close();
    this.setState(() => {
      this._broadcast = "A=" + a._join(",") + " / B=" + b._join(",");
    });
  }
  async _runAwaitFor() {
    const parts = [];
    for await (let v of this._ticks(3)) {
      parts.add("#" + v);
    }
    this.setState(() => {
      this._awaitFor = parts._join(" ");
    });
  }
  async _runTransformed() {
    const list = await Stream.fromIterable([1, 2, 3, 4]).where((v) => { return v.isEven; }).map((v) => { return (v * 10); }).toList();
    const first = await Stream.value(7).first;
    this.setState(() => {
      this._transformed = "list=" + list.join(",") + " / first=" + first;
    });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Stream：async* / listen / await for / Controller",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "listen / pause / resume：" + this._listen
        }),
        new Text({
          "data": "controller：" + this._controller
        }),
        new Text({
          "data": "broadcast：" + this._broadcast
        }),
        new Text({
          "data": "await for：" + this._awaitFor
        }),
        new Text({
          "data": "转换：" + this._transformed
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        new Wrap({
          "spacing": 8,
          "runSpacing": 8,
          "children": [
            new ElevatedButton({
              "onPressed": () => this._startListen(),
              "child": (this.__k3 || (this.__k3 = new Text({
                "data": "listen"
              })))
            }),
            new OutlinedButton({
              "onPressed": () => this._pauseResume(),
              "child": (this.__k4 || (this.__k4 = new Text({
                "data": "pause/resume"
              })))
            }),
            new ElevatedButton({
              "onPressed": () => this._runController(),
              "child": (this.__k5 || (this.__k5 = new Text({
                "data": "Controller"
              })))
            }),
            new OutlinedButton({
              "onPressed": () => this._runBroadcast(),
              "child": (this.__k6 || (this.__k6 = new Text({
                "data": "broadcast"
              })))
            }),
            new ElevatedButton({
              "onPressed": () => this._runAwaitFor(),
              "child": (this.__k7 || (this.__k7 = new Text({
                "data": "await for"
              })))
            }),
            new OutlinedButton({
              "onPressed": () => this._runTransformed(),
              "child": (this.__k8 || (this.__k8 = new Text({
                "data": "转换/终止"
              })))
            })
          ]
        })
      ]
    });
  }
}

