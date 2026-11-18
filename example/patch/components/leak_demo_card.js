// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/leak_demo_card.dart 自动生成
// 重新生成：dart run build_runner build

import { Card, Colors, Column, CrossAxisAlignment, Duration, EdgeInsets, FontWeight, GlobalKey, MainAxisSize, Padding, SizedBox, StatefulWidget, Text, TextStyle, Timer } from '../flutter.js';

// 组件 LeakDemoCard
export class LeakDemoCard extends StatefulWidget {
  constructor(args) {
    super(args);
    this._leakedKeys = [];
    this._timer = null;
    this._count = 0;
  }
  initState() {
    super.initState();
    this._timer = Timer.periodic({duration: new Duration({milliseconds: 300}), callback: this._leakOne.bind(this)});
  }
  _leakOne(timer) {
    this._leakedKeys.add(new GlobalKey());
    if ((!!this.__unmounted)) {
      return;
    }
    this.setState(() => {
      this._count = this._leakedKeys.length;
    });
  }
  dispose() {
    this._timer?.cancel();
    super.dispose();
  }
  build(context) {
    return new Card({
      "child": new Padding({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
          "value": 16
        }))),
        "child": new Column({
          "mainAxisSize": MainAxisSize.min,
          "crossAxisAlignment": CrossAxisAlignment.start,
          "children": [
            (this.__k1 || (this.__k1 = new Text({
              "data": "验证异步归属 · Timer 里 new GlobalKey()",
              "style": new TextStyle({
                "fontSize": 16,
                "fontWeight": FontWeight.bold,
                "color": Colors.blue
              })
            }))),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            new Text({
              "style": (this.__k3 || (this.__k3 = new TextStyle({
                "fontSize": 13
              }))),
              "data": "本页已创建：" + this._count + " 个 GlobalKey"
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            (this.__k4 || (this.__k4 = new Text({
              "data": "每 300ms 在 Timer 回调里 new GlobalKey() 并持有。回调创建时捕获了本组件的归属，" + "退出本页应随实例释放；左侧原生版同样随 State 回收。",
              "style": new TextStyle({
                "fontSize": 12,
                "color": Colors.grey
              })
            }))),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            (this.__k5 || (this.__k5 = new Text({
              "data": "退出后看右侧日志：应为 leak-check … clean；若出现「多余（JS）：js:key/Global#…」即回归。",
              "style": new TextStyle({
                "fontSize": 12,
                "color": Colors.grey
              })
            })))
          ]
        })
      })
    });
  }
}

