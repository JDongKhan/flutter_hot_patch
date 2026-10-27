// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/watch_demo.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { Builder, Card, Column, ElevatedButton, Padding, Row, SizedBox, Text } from '../flutter.js';
import { ChangeNotifierProvider } from '../provider.js';

// 组件 WatchDemo
export class WatchDemo {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new Card({
        "child": new Padding({
          "padding": {
            "left": 16.0,
            "top": 16.0,
            "right": 16.0,
            "bottom": 16.0
          },
          "child": new ChangeNotifierProvider({
            "create": CounterVm,
            "child": new Column({
              "mainAxisSize": "min",
              "children": [
                new Builder({
                    "builder": "_builder0"
                  }),
                (this.__k2 || (this.__k2 = new SizedBox({
                    "height": 12
                  }))),
                (this.__k3 || (this.__k3 = new WatchCountLabel({})))
              ]
            }),
            "model": "CounterVm"
          })
        })
      });
  }
  _builder0(context) {
      var model = context.watch("CounterVm");
      return new Column({
        "mainAxisSize": "min",
        "children": [
          (this.__k4 || (this.__k4 = new Text({
              "data": "context.watch<CounterModel>"
            }))),
          new Text({
              "style": {
                "fontSize": 22,
                "fontWeight": "bold",
                "color": Colors.deepOrange
              },
              "data": "count = " + model.count
            }),
          (this.__k5 || (this.__k5 = new SizedBox({
              "height": 8
            }))),
          new Row({
              "mainAxisAlignment": "center",
              "children": [
                new ElevatedButton({
                    "onPressed": this.__bindFn(0, [model], () => model.inc()),
                    "child": (this.__k0 || (this.__k0 = new Text({
                      "data": "+1"
                    })))
                  }),
                (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 12
                  }))),
                new ElevatedButton({
                    "onPressed": this.__bindFn(1, [], () => { this.context.read("CounterVm").reset(); }),
                    "child": (this.__k1 || (this.__k1 = new Text({
                      "data": "Reset"
                    })))
                  })
              ]
            })
        ]
      });
  }
}

// 组件 WatchCountLabel
export class WatchCountLabel {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    var model = context.watch("CounterVm");
    return new Text({
        "style": {
          "fontSize": 16,
          "color": Colors.blue
        },
        "data": "another State: count = " + model.count
      });
  }
}

