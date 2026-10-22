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
                      new SizedBox({
                          "height": 12
                        }),
                      new WatchCountLabel({})
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
          new Text({
              "data": "context.watch<CounterModel>"
            }),
          new Text({
              "style": {
                "fontSize": 22,
                "fontWeight": "bold",
                "color": '#FF5722'
              },
              "data": "count = " + model.count
            }),
          new SizedBox({
              "height": 8
            }),
          new Row({
              "mainAxisAlignment": "center",
              "children": [
                new ElevatedButton({
                    "onPressed": this.__bindFn(0, [model], () => model.inc()),
                    "child": new Text({
                        "data": "+1"
                      })
                  }),
                new SizedBox({
                    "width": 12
                  }),
                new ElevatedButton({
                    "onPressed": this.__bindFn(1, [], () => { this.context.read("CounterVm").reset(); }),
                    "child": new Text({
                        "data": "Reset"
                      })
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
          "color": '#2196F3'
        },
        "data": "another State: count = " + model.count
      });
  }
}

