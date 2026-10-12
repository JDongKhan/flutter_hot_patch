// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/provider_component.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { NetworkVm } from '../model/network_vm.js';
import { Button, Card, Column, Padding, Row, SizedBox, Text, __h } from '../flutter.js';
import { ChangeNotifierProviderFactory, ConsumerFactory, MultiProviderFactory } from '../provider.js';

class ProviderCard {
  constructor() {
    this._modelA = new CounterVm({});
    this._modelB = new NetworkVm({});
  }
  _incA() { this._modelA.inc(); }
  _resetA() { this._modelA.reset(); }
  _loadUser() { this._modelB.loadUserInfo({"h": 1}); }
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
            MultiProviderFactory({
                "providers": [
                  ChangeNotifierProviderFactory({
                      "model": "CounterVm",
                      "create": this._modelA
                    }),
                  ChangeNotifierProviderFactory({
                      "model": "NetworkVm",
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
                    ConsumerFactory({
                        "model": "NetworkVm",
                        "builder": "_consumerBuilder0"
                      }),
                    Row({
                        "mainAxisAlignment": "center"
                      }, [
                        Button({
                            "kind": "elevated",
                            "label": "加载用户信息",
                            "event": this.__bind("_loadUser")
                          })
                      ]),
                    SizedBox({
                        "height": 8
                      }),
                    ConsumerFactory({
                        "model": "CounterVm",
                        "builder": "_consumerBuilder1"
                      }),
                    Row({
                        "mainAxisAlignment": "center"
                      }, [
                        Button({
                            "kind": "elevated",
                            "label": "B +1",
                            "event": this.__bind("_incA")
                          }),
                        SizedBox({
                            "width": 12
                          }),
                        Button({
                            "kind": "elevated",
                            "label": "B Reset",
                            "event": this.__bind("_resetA")
                          })
                      ])
                  ])
              })
          ])
      ]);
  }
  _consumerBuilder0(value) {
      return Text({
        "data": "加载用户信息：",
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
export function ProviderCardFactory(props, children) {
  return __h(ProviderCard, props, children);
}

