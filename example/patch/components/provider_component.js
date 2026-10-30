// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/provider_component.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { NetworkVm } from '../model/network_vm.js';
import { Card, Colors, Column, EdgeInsets, ElevatedButton, FontWeight, MainAxisAlignment, MainAxisSize, Padding, Row, SizedBox, Text, TextStyle } from '../flutter.js';
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
    this._modelB.loadUserInfo({ "params": {"h": 1} });
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
              "create": this._modelA,
              "model": "CounterVm"
            }),
            ChangeNotifierProvider.value({
              "value": this._modelB,
              "model": "NetworkVm"
            })
          ],
          "child": new Column({
            "mainAxisSize": MainAxisSize.min,
            "children": [
              this._buildText(),
              this._modelA.buildText(),
              new Consumer({
                "builder": (context, value, child) => this._buildBadge(),
                "model": "CounterVm"
              }),
              (this.__k1 || (this.__k1 = new Text({
                "data": "MultiProvider · 两个模型各自局部重建"
              }))),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 8
              }))),
              new Consumer({
                "builder": (context, value, child) => new Text({
                  "style": (this.__k3 || (this.__k3 = new TextStyle({
                    "color": Colors.blue,
                    "fontSize": 22,
                    "fontWeight": FontWeight.bold
                  }))),
                  "data": "加载用户信息："
                }),
                "model": "NetworkVm"
              }),
              new Row({
                "mainAxisAlignment": MainAxisAlignment.center,
                "children": [
                  new ElevatedButton({
                    "onPressed": this.__bindFn(0, [], (...__a) => this._loadUser(...__a)),
                    "child": (this.__k4 || (this.__k4 = new Text({
                      "data": "加载用户信息"
                    })))
                  })
                ]
              }),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 8
              }))),
              new Consumer({
                "builder": (context, value, child) => new Text({
                  "style": (this.__k5 || (this.__k5 = new TextStyle({
                    "color": Colors.green,
                    "fontSize": 22,
                    "fontWeight": FontWeight.bold
                  }))),
                  "data": "B = " + value.count
                }),
                "model": "CounterVm"
              }),
              new Row({
                "mainAxisAlignment": MainAxisAlignment.center,
                "children": [
                  new ElevatedButton({
                    "onPressed": this.__bindFn(1, [], (...__a) => this._incA(...__a)),
                    "child": (this.__k6 || (this.__k6 = new Text({
                      "data": "B +1"
                    })))
                  }),
                  (this.__k7 || (this.__k7 = new SizedBox({
                    "width": 12
                  }))),
                  new ElevatedButton({
                    "onPressed": this.__bindFn(2, [], (...__a) => this._resetA(...__a)),
                    "child": (this.__k8 || (this.__k8 = new Text({
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
}

