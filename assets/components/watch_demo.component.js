// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/watch_demo.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterModel } from '../model/counter_model.model.js';
import { __h } from '../flutter/Node.js';
import { Builder } from '../flutter/Builder.js';
import { Button } from '../flutter/Button.js';
import { Card } from '../flutter/Card.js';
import { ChangeNotifierProvider } from '../provider/ChangeNotifierProvider.js';
import { Column } from '../flutter/Column.js';
import { Padding } from '../flutter/Padding.js';
import { Row } from '../flutter/Row.js';
import { SizedBox } from '../flutter/SizedBox.js';
import { Text } from '../flutter/Text.js';

class WatchDemoComponent {
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
            ChangeNotifierProvider({
                "model": "CounterModel",
                "create": CounterModel,
                "child": Column({
                    "mainAxisSize": "min"
                  }, [
                    Builder({
                        "builder": "_builder0"
                      }),
                    SizedBox({
                        "height": 12
                      }),
                    WatchCountLabel({})
                  ])
              })
          ])
      ]);
  }
  _builder0() {
      var model = this.__watch("CounterModel");
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
                "event": this.__bind("this.__read(\"CounterModel\").inc()")
              }),
            SizedBox({
                "width": 12
              }),
            Button({
                "kind": "elevated",
                "label": "Reset",
                "event": this.__bind("this.__read(\"CounterModel\").reset()")
              })
          ])
      ]);
  }
}
export function WatchDemo(props, children) {
  return __h(WatchDemoComponent, props, children);
}

class WatchCountLabelComponent {
  constructor() {
  }
  build() {
    var model = this.__watch("CounterModel");
    return Text({
        "data": "another State: count = " + model.count,
        "style": {
          "fontSize": 16,
          "color": '#2196F3'
        }
      });
  }
}
export function WatchCountLabel(props, children) {
  return __h(WatchCountLabelComponent, props, children);
}

