// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/alias_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { moduleBaseHigh, moduleBaseLabel, moduleBaseLevelText, moduleBaseTag } from '../packages/hot_module_base/src/module_symbols.js';
import { moduleHiddenTag, modulePublicTag } from '../packages/hot_module_base/src/module_internal.js';
import { Colors, Column, CrossAxisAlignment, ElevatedButton, FontWeight, Row, SizedBox, StatelessWidget, Text, TextStyle } from '../flutter.js';
import * as base from '../packages/hot_module_base/hot_module_base.js';
import * as p from '../packages/provider.js';
import * as vm from '../model/counter_vm.js';

// 模型 User
export class User {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.tag = (args && args.tag !== undefined) ? args.tag : '';
  }
  describe() {
    return "本地 User(" + this.tag + ")";
  }
}

// 组件 AliasDetail
export class AliasDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const counter = new vm.CounterVm({});
    const local = new User({
      "tag": "local"
    });
    const remote = new base.User({
      "name": "base",
      "age": 3
    });
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "import 前缀别名（as）",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "同名类与包模块类都靠前缀区分：User / base.User、" + "p.ChangeNotifierProvider / p.Consumer。",
          "style": new TextStyle({
            "fontSize": 13,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "data": "本地同名类 → " + local.describe()
        }),
        new Text({
          "data": "包前缀的同名类 → " + remote.name + " / " + remote.age
        }),
        new Text({
          "data": "包前缀的顶层符号 → " + moduleBaseTag + " / " + moduleBaseLabel() + " / " + moduleBaseLevelText()
        }),
        new Text({
          "data": "barrel 组合子 → show 保留 " + modulePublicTag + " / " + "hide 挡掉 " + moduleHiddenTag + " / show 外 " + moduleBaseHigh
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        p.ChangeNotifierProvider.value({
          "value": counter,
          "child": new p.Consumer({
            "builder": (ctx, value, child) => new Row({
              "children": [
                new Text({
                  "data": "count = " + value.count
                }),
                (this.__k4 || (this.__k4 = new SizedBox({
                  "width": 12
                }))),
                new ElevatedButton({
                  "onPressed": (...__a) => value.inc(...__a),
                  "child": (this.__k5 || (this.__k5 = new Text({
                    "data": "inc（经别名取到的 Consumer）"
                  })))
                })
              ]
            }),
            "typeArguments": {"T": "CounterVm"}
          }),
          "typeArguments": {"T": "CounterVm"}
        })
      ]
    });
  }
}

