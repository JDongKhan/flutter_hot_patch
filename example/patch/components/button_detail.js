// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/button_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { BorderRadius, BorderSide, Colors, Column, CrossAxisAlignment, EdgeInsets, ElevatedButton, FontWeight, OutlinedButton, Radius, RoundedRectangleBorder, Size, SizedBox, StatefulWidget, Text, TextButton, TextStyle } from '../flutter.js';

// 组件 ButtonDetail
export class ButtonDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._pressed = 0;
  }
  onTap() {
    this.setState(() => { this._pressed += 1; });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        new Text({
          "style": (this.__k0 || (this.__k0 = new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          }))),
          "data": "点击次数 = " + this._pressed
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new ElevatedButton({
          "onPressed": () => this.onTap(),
          "style": ElevatedButton.styleFrom({ "minimumSize": new Size({width: 180, height: 48}), "maximumSize": new Size({width: 240, height: 56}), "padding": EdgeInsets.symmetric({horizontal: 24, vertical: 12}), "elevation": 6, "shadowColor": Colors.deepPurple, "textStyle": new TextStyle({fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2}), "backgroundColor": Colors.teal, "foregroundColor": Colors.white }),
          "child": (this.__k2 || (this.__k2 = new Text({
            "data": "Elevated · Styled"
          })))
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new TextButton({
          "onPressed": () => this.onTap(),
          "style": TextButton.styleFrom({ "minimumSize": new Size({width: 120, height: 40}), "padding": EdgeInsets.symmetric({horizontal: 16}), "textStyle": new TextStyle({fontSize: 14, letterSpacing: 1}), "foregroundColor": Colors.indigo }),
          "child": (this.__k3 || (this.__k3 = new Text({
            "data": "TextButton"
          })))
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new OutlinedButton({
          "onPressed": () => this.onTap(),
          "style": OutlinedButton.styleFrom({ "side": new BorderSide({color: Colors.orange, width: 2}), "minimumSize": new Size({width: 120, height: 40}), "shape": new RoundedRectangleBorder({borderRadius: BorderRadius.all({radius: Radius.circular({radius: 20})})}), "foregroundColor": Colors.deepOrange }),
          "child": (this.__k4 || (this.__k4 = new Text({
            "data": "OutlinedButton"
          })))
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k5 || (this.__k5 = new ElevatedButton({
          "child": new Text({
            "data": "Disabled"
          })
        })))
      ]
    });
  }
}

