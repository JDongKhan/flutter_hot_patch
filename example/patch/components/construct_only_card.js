// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/construct_only_card.dart 自动生成
// 重新生成：dart run build_runner build

import { Card, Colors, Column, CrossAxisAlignment, EdgeInsets, ElevatedButton, FontWeight, MainAxisSize, Padding, SizedBox, StatefulWidget, Text, TextStyle, Wrap } from '../flutter.js';
import { Uuid } from '../packages/uuid.js';

// 组件 ConstructOnlyCard
export class ConstructOnlyCard extends StatefulWidget {
  constructor(args) {
    super(args);
    this._uuid = new Uuid();
    this._uuidText = "未生成";
  }
  _newUuid() {
    this.setState(() => {
      this._uuidText = this._uuid.v4();
    });
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
              "data": "final id = Uuid();  id.v4()",
              "style": new TextStyle({
                "fontSize": 16,
                "fontWeight": FontWeight.bold,
                "color": Colors.purple
              })
            }))),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            new Text({
              "style": (this.__k3 || (this.__k3 = new TextStyle({
                "fontSize": 13
              }))),
              "data": "uuid：" + this._uuidText
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            new Wrap({
              "spacing": 8,
              "runSpacing": 8,
              "children": [
                new ElevatedButton({
                  "onPressed": () => this._newUuid(),
                  "child": (this.__k4 || (this.__k4 = new Text({
                    "data": "Uuid.v4 生成"
                  })))
                })
              ]
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            (this.__k5 || (this.__k5 = new Text({
              "data": "JS 侧由 js/uuid.js 提供同名类：构造、方法调用与 Dart 一比一",
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

