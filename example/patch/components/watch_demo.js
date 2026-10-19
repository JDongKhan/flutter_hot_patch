// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/watch_demo.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { Builder, __h } from '../flutter.js';
import { ChangeNotifierProvider } from '../provider.js';

// 组件 WatchDemo
export class WatchDemo {
  constructor() {
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
            __h(ChangeNotifierProvider, {
                "model": "CounterVm",
                "create": CounterVm,
                "child": __h('Column', {
                    "mainAxisSize": "min"
                  }, [
                    __h(Builder, {
                        "builder": "_builder0"
                      }),
                    __h('SizedBox', {
                        "height": 12
                      }),
                    __h(WatchCountLabel, {})
                  ])
              })
          ])
      ]);
  }
  _builder0(context) {
      var model = context.watch("CounterVm");
      return __h('Column', {
        "mainAxisSize": "min"
      }, [
        __h('Text', {
            "data": "context.watch<CounterModel>"
          }),
        __h('Text', {
            "data": "count = " + model.count,
            "style": {
              "fontSize": 22,
              "fontWeight": "bold",
              "color": '#FF5722'
            }
          }),
        __h('SizedBox', {
            "height": 8
          }),
        __h('Row', {
            "mainAxisAlignment": "center"
          }, [
            __h('Button', {
                "kind": "elevated",
                "label": "+1",
                "event": this.__bind("this.context.read(\"CounterVm\").inc()")
              }),
            __h('SizedBox', {
                "width": 12
              }),
            __h('Button', {
                "kind": "elevated",
                "label": "Reset",
                "event": this.__bind("this.context.read(\"CounterVm\").reset()")
              })
          ])
      ]);
  }
}

// 组件 WatchCountLabel
export class WatchCountLabel {
  constructor() {
  }
  build(context) {
    var model = context.watch("CounterVm");
    return __h('Text', {
        "data": "another State: count = " + model.count,
        "style": {
          "fontSize": 16,
          "color": '#2196F3'
        }
      });
  }
}

