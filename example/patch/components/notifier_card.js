// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/notifier_card.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { Card, Column, EdgeInsets, ElevatedButton, FontWeight, ListenableBuilder, MainAxisAlignment, MainAxisSize, Padding, Row, SizedBox, StatefulWidget, Text, TextStyle } from '../flutter.js';

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
            new Row({
              "mainAxisAlignment": MainAxisAlignment.center,
              "children": [
                new ElevatedButton({
                  "onPressed": (...__a) => this._inc(...__a),
                  "child": (this.__k3 || (this.__k3 = new Text({
                    "data": "+1"
                  })))
                }),
                (this.__k4 || (this.__k4 = new SizedBox({
                  "width": 12
                }))),
                new ElevatedButton({
                  "onPressed": (...__a) => this._reset(...__a),
                  "child": (this.__k5 || (this.__k5 = new Text({
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

