// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/provider_component.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { NetworkVm } from '../model/network_vm.js';
import { Builder, Card, Colors, Column, EdgeInsets, ElevatedButton, FontWeight, MainAxisAlignment, MainAxisSize, Padding, Row, SizedBox, StatefulWidget, Text, TextStyle, Wrap, WrapAlignment } from '../flutter.js';
import { ChangeNotifierProvider, Consumer, MultiProvider, Selector } from '../packages/provider.js';

// 组件 ProviderCard
export class ProviderCard extends StatefulWidget {
  constructor(args) {
    super(args);
    this._counter = new CounterVm();
    this._network = new NetworkVm();
    this._consumerBuilds = 0;
    this._selectorBuilds = 0;
  }
  _loadUser() {
    this._network.loadUserInfo({ "params": new Map([["h", 1]]) });
  }
  build(context) {
    return new Card({
      "child": new Padding({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
          "value": 16
        }))),
        "child": new MultiProvider({
          "providers": [
            new ChangeNotifierProvider({
              "create": (_) => { return this._counter; },
              "typeArguments": {"T": "CounterVm"}
            }),
            ChangeNotifierProvider.value({
              "value": this._network,
              "typeArguments": {"T": "NetworkVm"}
            })
          ],
          "child": new Column({
            "mainAxisSize": MainAxisSize.min,
            "children": [
              new Builder({
                "builder": (context) => {
                  var model = context.watch({ typeArguments: {"T": "CounterVm"} });
                  return new Column({
                    "mainAxisSize": MainAxisSize.min,
                    "children": [
                      new Text({
                        "style": (this.__k1 || (this.__k1 = new TextStyle({
                          "color": Colors.orange,
                          "fontSize": 20,
                          "fontWeight": FontWeight.bold
                        }))),
                        "data": "context.watch：count = " + model.count
                      }),
                      new Wrap({
                        "alignment": WrapAlignment.center,
                        "spacing": 12,
                        "runSpacing": 8,
                        "children": [
                          new ElevatedButton({
                            "onPressed": () => { return model.inc(); },
                            "child": (this.__k2 || (this.__k2 = new Text({
                              "data": "+1"
                            })))
                          }),
                          new ElevatedButton({
                            "onPressed": () => { context.read({ typeArguments: {"T": "CounterVm"} }).reset(); },
                            "child": (this.__k3 || (this.__k3 = new Text({
                              "data": "Reset"
                            })))
                          })
                        ]
                      })
                    ]
                  });
                }
              }),
              (this.__k4 || (this.__k4 = new SizedBox({
                "height": 12
              }))),
              new Consumer({
                "builder": (context, model, child) => { this._consumerBuilds++;
                  return new Text({
                    "style": (this.__k5 || (this.__k5 = new TextStyle({
                      "color": Colors.green,
                      "fontSize": 20,
                      "fontWeight": FontWeight.bold
                    }))),
                    "data": "Consumer：builder 执行 " + this._consumerBuilds + " 次" + "（count = " + model.count + "）"
                  }); },
                "typeArguments": {"T": "CounterVm"}
              }),
              (this.__k4 || (this.__k4 = new SizedBox({
                "height": 12
              }))),
              new Selector({
                "selector": (_, model) => { return (model.count >= 5); },
                "child": (this.__k6 || (this.__k6 = new Text({
                  "data": "child：跨重建复用的固定子树",
                  "style": new TextStyle({
                    "fontSize": 12,
                    "color": Colors.grey
                  })
                }))),
                "builder": (context, isHigh, child) => { this._selectorBuilds++;
                  return new Column({
                    "mainAxisSize": MainAxisSize.min,
                    "children": [
                      new Text({
                        "style": (this.__k5 || (this.__k5 = new TextStyle({
                          "color": Colors.green,
                          "fontSize": 20,
                          "fontWeight": FontWeight.bold
                        }))),
                        "data": "Selector：builder 执行 " + this._selectorBuilds + " 次" + "（count ≥ 5 为 " + (isHigh ? "true" : "false") + "）"
                      }),
                      (child ?? (this.__k7 || (this.__k7 = new SizedBox({}))))
                    ]
                  }); },
                "typeArguments": {"A": "CounterVm", "S": "bool"}
              }),
              (this.__k4 || (this.__k4 = new SizedBox({
                "height": 12
              }))),
              new Consumer({
                "builder": (context, model, child) => (this.__k8 || (this.__k8 = new Text({
                  "data": "NetworkVm：ChangeNotifierProvider.value 由 State 手动 dispose",
                  "style": new TextStyle({
                    "fontSize": 14,
                    "color": Colors.blue
                  })
                }))),
                "typeArguments": {"T": "NetworkVm"}
              }),
              (this.__k9 || (this.__k9 = new SizedBox({
                "height": 8
              }))),
              new Row({
                "mainAxisAlignment": MainAxisAlignment.center,
                "children": [
                  new ElevatedButton({
                    "onPressed": () => this._loadUser(),
                    "child": (this.__k10 || (this.__k10 = new Text({
                      "data": "加载用户信息"
                    })))
                  })
                ]
              })
            ]
          })
        })
      })
    });
  }
  dispose() {
    this._network.dispose();
    super.dispose();
  }
}

