// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/provider_component.dart 自动生成
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
  _incA() { this._modelA.inc(); }
  _resetA() { this._modelA.reset(); }
  _loadUser() { this._modelB.loadUserInfo({"h": 1}); }
  _buildText() {  }
  dispose() { this._modelB.dispose(); }
  build() {
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
                      "model": "CounterVm",
                      "create": this._modelA
                    }),
                  __h(ChangeNotifierProvider, {
                      "model": "NetworkVm",
                      "value": this._modelB
                    })
                ],
                "child": __h('Column', {
                    "mainAxisSize": "min"
                  }, [
                    __h('Text', {
                        "data": "MultiProvider · 两个模型各自局部重建"
                      }),
                    __h('SizedBox', {
                        "height": 8
                      }),
                    __h(Consumer, {
                        "model": "NetworkVm",
                        "builder": "_consumerBuilder0"
                      }),
                    __h('Row', {
                        "mainAxisAlignment": "center"
                      }, [
                        __h('Button', {
                            "kind": "elevated",
                            "label": "加载用户信息",
                            "event": this.__bind("_loadUser")
                          })
                      ]),
                    __h('SizedBox', {
                        "height": 8
                      }),
                    __h(Consumer, {
                        "model": "CounterVm",
                        "builder": "_consumerBuilder1"
                      }),
                    __h('Row', {
                        "mainAxisAlignment": "center"
                      }, [
                        __h('Button', {
                            "kind": "elevated",
                            "label": "B +1",
                            "event": this.__bind("_incA")
                          }),
                        __h('SizedBox', {
                            "width": 12
                          }),
                        __h('Button', {
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
      return __h('Text', {
        "data": "加载用户信息：",
        "style": {
          "fontSize": 22,
          "fontWeight": "bold",
          "color": '#2196F3'
        }
      });
  }
  _consumerBuilder1(value) {
      return __h('Text', {
        "data": "B = " + value.count,
        "style": {
          "fontSize": 22,
          "fontWeight": "bold",
          "color": '#4CAF50'
        }
      });
  }
}

