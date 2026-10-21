// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/provider_component.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { NetworkVm } from '../model/network_vm.js';
import { ChangeNotifierProvider, Consumer, MultiProvider } from '../provider.js';
import { __h } from '../flutter.js';

// 组件 ProviderCard
export class ProviderCard {
  constructor() {
    this._modelA = new CounterVm({});
    this._modelB = new NetworkVm({});
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
    return __h('Card', {}, [
        __h('Padding', {
            "padding": {
              "left": 16.0,
              "top": 16.0,
              "right": 16.0,
              "bottom": 16.0
            }
          }, [
            __h(MultiProvider, {
                "providers": [
                  __h(ChangeNotifierProvider, {
                      "create": this._modelA,
                      "model": "CounterVm"
                    }),
                  __h(ChangeNotifierProvider, {
                      "value": this._modelB,
                      "factory": "value",
                      "model": "NetworkVm"
                    })
                ]
              }, [
                __h('Column', {
                    "mainAxisSize": "min"
                  }, [
                    this._buildText(),
                    this._modelA.buildText(),
                    __h(Consumer, {
                        "builder": "_builder0",
                        "model": "CounterVm"
                      }),
                    __h('Text', {
                        "data": "MultiProvider · 两个模型各自局部重建"
                      }),
                    __h('SizedBox', {
                        "height": 8
                      }),
                    __h(Consumer, {
                        "builder": "_builder1",
                        "model": "NetworkVm"
                      }),
                    __h('Row', {
                        "mainAxisAlignment": "center"
                      }, [
                        __h('ElevatedButton', {
                            "onPressed": this.__bindFn(0, [], (...__a) => this._loadUser(...__a))
                          }, [
                            __h('Text', {
                                "data": "加载用户信息"
                              })
                          ])
                      ]),
                    __h('SizedBox', {
                        "height": 8
                      }),
                    __h(Consumer, {
                        "builder": "_builder2",
                        "model": "CounterVm"
                      }),
                    __h('Row', {
                        "mainAxisAlignment": "center"
                      }, [
                        __h('ElevatedButton', {
                            "onPressed": this.__bindFn(1, [], (...__a) => this._incA(...__a))
                          }, [
                            __h('Text', {
                                "data": "B +1"
                              })
                          ]),
                        __h('SizedBox', {
                            "width": 12
                          }),
                        __h('ElevatedButton', {
                            "onPressed": this.__bindFn(2, [], (...__a) => this._resetA(...__a))
                          }, [
                            __h('Text', {
                                "data": "B Reset"
                              })
                          ])
                      ])
                  ])
              ])
          ])
      ]);
  }
  _buildText() {
    return __h('Text', {
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
    return __h('Text', {
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
      return __h('Text', {
        "style": {
          "fontSize": 22,
          "fontWeight": "bold",
          "color": '#2196F3'
        },
        "data": "加载用户信息："
      });
  }
  _builder2(context, value) {
      return __h('Text', {
        "style": {
          "fontSize": 22,
          "fontWeight": "bold",
          "color": '#4CAF50'
        },
        "data": "B = " + value.count
      });
  }
}

