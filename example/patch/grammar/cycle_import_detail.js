// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/grammar/cycle_import_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { CycleImportA } from 'cycle_import_a.js';
import { CycleImportB } from 'cycle_import_b.js';
import { Colors, Column, CrossAxisAlignment, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../flutter.js';

// 组件 CycleImportDetail
export class CycleImportDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "循环 import · A ↔ B",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "两个模块级互相 import，两侧都只在方法体里调用对方。",
          "style": new TextStyle({
            "fontSize": 13,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 4
        }))),
        (this.__k4 || (this.__k4 = new Text({
          "data": "加载时 A → B → A 形成环：告警一次并继续加载，B 的方法在 A 求值完成后" + "通过绑定回填拿到 A。",
          "style": new TextStyle({
            "fontSize": 13,
            "color": Colors.black54
          })
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        CycleImportA.card({}),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        CycleImportB.card({}),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        (this.__k6 || (this.__k6 = new Text({
          "data": "两张卡片分别调用 A.callB() / B.callA()，渲染时就已回填完成。",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black45
          })
        })))
      ]
    });
  }
}

