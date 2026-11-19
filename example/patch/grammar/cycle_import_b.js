// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/grammar/cycle_import_b.dart 自动生成
// 重新生成：dart run build_runner build

import { CycleImportA } from 'cycle_import_a.js';
import { Card, Colors, Column, CrossAxisAlignment, EdgeInsets, FontWeight, Padding, SizedBox, Text, TextStyle } from '../flutter.js';

// 模型 CycleImportB
export class CycleImportB {
  constructor() {
  }
  static name() {
    return "模块 B";
  }
  static callA() {
    return CycleImportA.name();
  }
  static card() {
    return new Card({
      "margin": EdgeInsets.zero,
      "child": new Padding({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
          "value": 12
        }))),
        "child": new Column({
          "crossAxisAlignment": CrossAxisAlignment.start,
          "children": [
            (this.__k1 || (this.__k1 = new Text({
              "data": "B · cycle_import_b.js",
              "style": new TextStyle({
                "fontWeight": FontWeight.bold
              })
            }))),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 6
            }))),
            (this.__k3 || (this.__k3 = new Text({
              "data": "B.callA() →"
            }))),
            new Text({
              "style": (this.__k4 || (this.__k4 = new TextStyle({
                "color": Colors.green
              }))),
              "data": CycleImportB.callA()
            })
          ]
        })
      })
    });
  }
  // 命名构造 CycleImportB._
  static _(args) {
    const __o = new CycleImportB(args);
    return __o;
  }
}

