// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/notifier_card.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { Card, Column, EdgeInsets, ElevatedButton, FontWeight, ListenableBuilder, MainAxisSize, Padding, SizedBox, StatefulWidget, Text, TextStyle, Wrap, WrapAlignment } from '../flutter.js';

// 组件 NotifierCard
export class NotifierCard extends StatefulWidget {
  constructor(args) {
    super(args);
    this._model = new CounterVm();
  }
  _inc() {
    this._model.inc();
  }
  _reset() {
    this._model.reset();
  }
  build(context) {
    return new Card({
      "child": new Padding({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
          "value": 16
        }))),
        "child": new Column({
          "mainAxisSize": MainAxisSize.min,
          "children": [
            new ListenableBuilder({
              "listenable": this._model,
              "builder": (context, index) => new Text({
                "style": (this.__k1 || (this.__k1 = new TextStyle({
                  "fontSize": 24,
                  "fontWeight": FontWeight.bold
                }))),
                "data": "count = " + this._model.count
              })
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 12
            }))),
            new Wrap({
              "alignment": WrapAlignment.center,
              "spacing": 12,
              "runSpacing": 8,
              "children": [
                new ElevatedButton({
                  "onPressed": () => this._inc(),
                  "child": (this.__k3 || (this.__k3 = new Text({
                    "data": "+1"
                  })))
                }),
                new ElevatedButton({
                  "onPressed": () => this._reset(),
                  "child": (this.__k4 || (this.__k4 = new Text({
                    "data": "Reset"
                  })))
                })
              ]
            })
          ]
        })
      })
    });
  }
  dispose() {
    this._model.dispose();
    super.dispose();
  }
}

