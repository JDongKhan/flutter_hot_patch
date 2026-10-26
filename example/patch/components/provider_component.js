// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/provider_component.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { NetworkVm } from '../model/network_vm.js';
import { Card, Column, ElevatedButton, Padding, Row, SizedBox, Text } from '../flutter.js';
import { ChangeNotifierProvider, Consumer, MultiProvider } from '../provider.js';

// 组件 ProviderCard
export class ProviderCard {
  constructor(args) {
    this.props = args || {};
    this._modelA = new CounterVm();
    this._modelB = new NetworkVm();
  }
  _incA() {
    this._modelA.inc();
  }
  _resetA() {
    this._modelA.reset();
  }
  _loadUser() {
    this._modelB.loadUserInfo({"h": 1});
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
            "child": new MultiProvider({
                "providers": [
                  new ChangeNotifierProvider({
                      "create": this._modelA,
                      "model": "CounterVm"
                    }),
                  ChangeNotifierProvider.value({
                      "value": this._modelB,
                      "model": "NetworkVm"
                    })
                ],
                "child": new Column({
                    "mainAxisSize": "min",
                    "children": [
                      this._buildText(),
                      this._modelA.buildText(),
                      new Consumer({
                          "builder": "_builder0",
                          "model": "CounterVm"
                        }),
                      (this.__k0 || (this.__k0 = new Text({
                          "data": "MultiProvider · 两个模型各自局部重建"
                        }))),
                      (this.__k1 || (this.__k1 = new SizedBox({
                          "height": 8
                        }))),
                      new Consumer({
                          "builder": "_builder1",
                          "model": "NetworkVm"
                        }),
                      new Row({
                          "mainAxisAlignment": "center",
                          "children": [
                            new ElevatedButton({
                                "onPressed": this.__bindFn(0, [], (...__a) => this._loadUser(...__a)),
                                "child": (this.__k2 || (this.__k2 = new Text({
                                    "data": "加载用户信息"
                                  })))
                              })
                          ]
                        }),
                      (this.__k1 || (this.__k1 = new SizedBox({
                          "height": 8
                        }))),
                      new Consumer({
                          "builder": "_builder2",
                          "model": "CounterVm"
                        }),
                      new Row({
                          "mainAxisAlignment": "center",
                          "children": [
                            new ElevatedButton({
                                "onPressed": this.__bindFn(1, [], (...__a) => this._incA(...__a)),
                                "child": (this.__k3 || (this.__k3 = new Text({
                                    "data": "B +1"
                                  })))
                              }),
                            (this.__k4 || (this.__k4 = new SizedBox({
                                "width": 12
                              }))),
                            new ElevatedButton({
                                "onPressed": this.__bindFn(2, [], (...__a) => this._resetA(...__a)),
                                "child": (this.__k5 || (this.__k5 = new Text({
                                    "data": "B Reset"
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
  _buildText() {
    return new Text({
        "data": "test 1"
      });
  }
  _buildBadge() {
    var label = "";
    switch (this._modelA.count) {
      case 0:
        label = "B·零";
        break;
      case 1:
      case 2:
        label = "B·少";
        break;
      case 3:
      case 4:
        label = "B·多";
        break;
      default:
        label = "B·爆表";
      break;
    }
    var dots = "";
    for (let i = 0; (i < this._modelA.count); (i++)) {
      dots = dots + "·";
    }
    return new Text({
        "data": label + dots
      });
  }
  dispose() {
    this._modelB.dispose();
  }
  _builder0(context, value) {
      return this._buildBadge();
  }
  _builder1(context, value) {
      return new Text({
        "style": {
          "fontSize": 22,
          "fontWeight": "bold",
          "color": Colors.blue
        },
        "data": "加载用户信息："
      });
  }
  _builder2(context, value) {
      return new Text({
        "style": {
          "fontSize": 22,
          "fontWeight": "bold",
          "color": Colors.green
        },
        "data": "B = " + value.count
      });
  }
}

