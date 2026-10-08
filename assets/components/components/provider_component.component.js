// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/provider_component.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterModel } from '../model/counter_model.model.js';
import { __h } from '../../flutter/Node.js';
import { Button } from '../../flutter/Button.js';
import { Card } from '../../flutter/Card.js';
import { ChangeNotifierProvider } from '../../provider/ChangeNotifierProvider.js';
import { Column } from '../../flutter/Column.js';
import { Consumer } from '../../provider/Consumer.js';
import { MultiProvider } from '../../provider/MultiProvider.js';
import { Padding } from '../../flutter/Padding.js';
import { Row } from '../../flutter/Row.js';
import { SizedBox } from '../../flutter/SizedBox.js';
import { Text } from '../../flutter/Text.js';

class ProviderCardComponent {
  constructor() {
    this._modelA = new CounterModel({});
    this._modelB = new CounterModel({});
  }
  _incA() { this._modelA.inc(); }
  _resetA() { this._modelA.reset(); }
  _incB() { this._modelB.inc(); }
  _resetB() { this._modelB.reset(); }
  dispose() { this._modelB.dispose(); }
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
            MultiProvider({
                "providers": [
                  ChangeNotifierProvider({
                      "model": "CounterModel",
                      "create": this._modelA
                    }),
                  ChangeNotifierProvider({
                      "model": "CounterModel",
                      "value": this._modelB
                    })
                ],
                "child": Column({
                    "mainAxisSize": "min"
                  }, [
                    Text({
                        "data": "MultiProvider · 两个模型各自局部重建"
                      }),
                    SizedBox({
                        "height": 8
                      }),
                    Consumer({
                        "model": "CounterModel",
                        "builder": "_consumerBuilder0"
                      }),
                    Row({
                        "mainAxisAlignment": "center"
                      }, [
                        Button({
                            "kind": "elevated",
                            "label": "A +1",
                            "event": this.__bind("_incA")
                          }),
                        SizedBox({
                            "width": 12
                          }),
                        Button({
                            "kind": "elevated",
                            "label": "A Reset",
                            "event": this.__bind("_resetA")
                          })
                      ]),
                    SizedBox({
                        "height": 8
                      }),
                    Consumer({
                        "model": "CounterModel",
                        "builder": "_consumerBuilder1"
                      }),
                    Row({
                        "mainAxisAlignment": "center"
                      }, [
                        Button({
                            "kind": "elevated",
                            "label": "B +1",
                            "event": this.__bind("_incB")
                          }),
                        SizedBox({
                            "width": 12
                          }),
                        Button({
                            "kind": "elevated",
                            "label": "B Reset",
                            "event": this.__bind("_resetB")
                          })
                      ])
                  ])
              })
          ])
      ]);
  }
  _consumerBuilder0(value) {
      return Text({
        "data": "A = " + value.count,
        "style": {
          "fontSize": 22,
          "fontWeight": "bold",
          "color": '#2196F3'
        }
      });
  }
  _consumerBuilder1(value) {
      return Text({
        "data": "B = " + value.count,
        "style": {
          "fontSize": 22,
          "fontWeight": "bold",
          "color": '#4CAF50'
        }
      });
  }
}
export function ProviderCard(props, children) {
  return __h(ProviderCardComponent, props, children);
}

