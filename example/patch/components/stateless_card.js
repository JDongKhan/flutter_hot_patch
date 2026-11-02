// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/stateless_card.dart 自动生成
// 重新生成：dart run build_runner build

import { Card, Colors, Column, CrossAxisAlignment, Divider, EdgeInsets, Expanded, FontWeight, Icon, Icons, MainAxisSize, Padding, Row, SizedBox, StatelessWidget, Text, TextStyle } from '../flutter.js';

// 组件 StatelessCard
export class StatelessCard extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.subtitle = (args && args.subtitle !== undefined) ? args.subtitle : "";
    this.badge = (args && args.badge !== undefined) ? args.badge : "NEW";
  }
  build(context) {
    return new Card({
      "margin": (this.__k0 || (this.__k0 = EdgeInsets.all({
        "value": 12
      }))),
      "child": new Padding({
        "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
          "value": 16
        }))),
        "child": new Column({
          "mainAxisSize": MainAxisSize.min,
          "crossAxisAlignment": CrossAxisAlignment.start,
          "children": [
            new Row({
              "children": [
                (this.__k2 || (this.__k2 = new Icon({
                  "color": Colors.teal,
                  "icon": Icons.article
                }))),
                (this.__k3 || (this.__k3 = new SizedBox({
                  "width": 8
                }))),
                new Expanded({
                  "child": new Text({
                    "style": (this.__k4 || (this.__k4 = new TextStyle({
                      "fontSize": 18,
                      "fontWeight": FontWeight.bold
                    }))),
                    "data": this.badge + " · " + this.title
                  })
                })
              ]
            }),
            (this.__k5 || (this.__k5 = new Divider({
              "height": 24
            }))),
            new Text({
              "style": (this.__k6 || (this.__k6 = new TextStyle({
                "color": Colors.grey,
                "fontSize": 14
              }))),
              "data": this.subtitle
            })
          ]
        })
      })
    });
  }
}

