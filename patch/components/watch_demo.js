// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/watch_demo.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { BuilderFactory, Button, Card, Column, Padding, Row, SizedBox, Text, __h } from '../flutter.js';
import { ChangeNotifierProviderFactory } from '../provider.js';

class WatchDemo {
  constructor() {
  }
  build() {
    return Card({}, [
        Padding({
            "padding": {
              "left": 16.0,
              "top": 16.0,
              "right": 16.0,
              "bottom": 16.0
            }
          }, [
            ChangeNotifierProviderFactory({
                "model": "CounterVm",
                "create": CounterVm,
                "child": Column({
                    "mainAxisSize": "min"
                  }, [
                    BuilderFactory({
                        "builder": "_builder0"
                      }),
                    SizedBox({
                        "height": 12
                      }),
                    WatchCountLabelFactory({})
                  ])
              })
          ])
      ]);
  }
  _builder0() {
      var model = this.__watch("CounterVm");
      return Column({
        "mainAxisSize": "min"
      }, [
        Text({
            "data": "context.watch<CounterModel>"
          }),
        Text({
            "data": "count = " + model.count,
            "style": {
              "fontSize": 22,
              "fontWeight": "bold",
              "color": '#FF5722'
            }
          }),
        SizedBox({
            "height": 8
          }),
        Row({
            "mainAxisAlignment": "center"
          }, [
            Button({
                "kind": "elevated",
                "label": "+1",
                "event": this.__bind("this.__read(\"CounterVm\").inc()")
              }),
            SizedBox({
                "width": 12
              }),
            Button({
                "kind": "elevated",
                "label": "Reset",
                "event": this.__bind("this.__read(\"CounterVm\").reset()")
              })
          ])
      ]);
  }
}
export function WatchDemoFactory(props, children) {
  return __h(WatchDemo, props, children);
}

class WatchCountLabel {
  constructor() {
  }
  build() {
    var model = this.__watch("CounterVm");
    return Text({
        "data": "another State: count = " + model.count,
        "style": {
          "fontSize": 16,
          "color": '#2196F3'
        }
      });
  }
}
export function WatchCountLabelFactory(props, children) {
  return __h(WatchCountLabel, props, children);
}

