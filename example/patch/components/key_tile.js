// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/key_tile.dart 自动生成
// 重新生成：dart run build_runner build

import { Border, BorderRadius, BoxDecoration, Colors, Container, EdgeInsets, Expanded, Row, StatefulWidget, Text, TextButton, TextStyle } from '../flutter.js';

// 组件 KeyTile
export class KeyTile extends StatefulWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this._count = 0;
  }
  __applyProps(args) {
    this.index = (args && args.index !== undefined) ? args.index : 0;
    this.label = (args && args.label !== undefined) ? args.label : '';
  }
  bump() {
    this.setState(() => { this._count += 1; });
  }
  build(context) {
    var label = this.label;
    var caption = label + " · 计数 " + this._count;
    return new Container({
      "margin": (this.__k0 || (this.__k0 = EdgeInsets.symmetric({
        "vertical": 2
      }))),
      "padding": (this.__k1 || (this.__k1 = EdgeInsets.symmetric({
        "horizontal": 10,
        "vertical": 2
      }))),
      "decoration": new BoxDecoration({
        "color": Colors.white,
        "borderRadius": BorderRadius.circular({
          "radius": 6
        }),
        "border": Border.all({
          "color": Colors.grey.shade300
        })
      }),
      "child": new Row({
        "children": [
          new Expanded({
            "child": new Text({
              "style": (this.__k2 || (this.__k2 = new TextStyle({
                "fontSize": 13
              }))),
              "data": caption
            })
          }),
          new TextButton({
            "onPressed": () => this.bump(),
            "child": (this.__k3 || (this.__k3 = new Text({
              "data": "+1"
            })))
          })
        ]
      })
    });
  }
}

