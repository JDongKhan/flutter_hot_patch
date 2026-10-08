// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/notifier_component.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterModel } from '../model/counter_model.model.js';
import { __h } from '../flutter/Node.js';
import { Button } from '../flutter/Button.js';
import { Card } from '../flutter/Card.js';
import { Column } from '../flutter/Column.js';
import { ListenableBuilder } from '../flutter/ListenableBuilder.js';
import { Padding } from '../flutter/Padding.js';
import { Row } from '../flutter/Row.js';
import { SizedBox } from '../flutter/SizedBox.js';
import { Text } from '../flutter/Text.js';

class NotifierCardComponent {
  constructor() {
    this._model = new CounterModel({});
  }
  _inc() { this._model.inc(); }
  _reset() { this._model.reset(); }
  dispose() { this._model.dispose(); }
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
            Column({
                "mainAxisSize": "min"
              }, [
                ListenableBuilder({
                    "listenable": "_model",
                    "builder": "_lbBuilder0"
                  }),
                SizedBox({
                    "height": 12
                  }),
                Row({
                    "mainAxisAlignment": "center"
                  }, [
                    Button({
                        "kind": "elevated",
                        "label": "+1",
                        "event": this.__bind("_inc")
                      }),
                    SizedBox({
                        "width": 12
                      }),
                    Button({
                        "kind": "elevated",
                        "label": "Reset",
                        "event": this.__bind("_reset")
                      })
                  ])
              ])
          ])
      ]);
  }
  _lbBuilder0() {
      return Text({
        "data": "count = " + this._model.count,
        "style": {
          "fontSize": 24,
          "fontWeight": "bold"
        }
      });
  }
}
export function NotifierCard(props, children) {
  return __h(NotifierCardComponent, props, children);
}

