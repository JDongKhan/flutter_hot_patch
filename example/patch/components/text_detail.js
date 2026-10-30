// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/text_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Color, Colors, Column, CrossAxisAlignment, FontWeight, SizedBox, Text, TextAlign, TextButton, TextDecoration, TextDecorationStyle, TextOverflow, TextScaler, TextStyle } from '../flutter.js';

// 组件 TextDetail
export class TextDetail {
  constructor(args) {
    this.props = args || {};
    this._count = 0;
  }
  bump() {
    this.setState(() => { this._count += 1; });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "基础文案 + TextStyle",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new Text({
          "style": (this.__k1 || (this.__k1 = new TextStyle({
            "color": Colors.blue,
            "fontSize": 16
          }))),
          "data": "普通文本，count = " + this._count + "（状态插值）"
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "maxLines": 1,
          "overflow": TextOverflow.ellipsis,
          "data": "maxLines+overflow 测试：这是一段很长的文字会被截断成省略号显示"
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "textScaler": TextScaler.linear({
            "textScaleFactor": 1.6
          }),
          "data": "textScaler.linear(1.6) 放大"
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "textAlign": TextAlign.center,
          "style": (this.__k3 || (this.__k3 = new TextStyle({
            "decoration": TextDecoration.underline,
            "decorationColor": Colors.orange,
            "decorationStyle": TextDecorationStyle.wavy
          }))),
          "data": "textAlign 居中,He said \"hi\""
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "softWrap": false,
          "style": (this.__k4 || (this.__k4 = new TextStyle({
            "backgroundColor": new Color({
              "value": 0xFFFFE082
            }),
            "color": Colors.grey,
            "fontSize": 12,
            "letterSpacing": 1,
            "wordSpacing": 2
          }))),
          "data": "softWrap=false 不换行测试"
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 6
        }))),
        new TextButton({
          "onPressed": this.__bindFn(0, [], (...__a) => this.bump(...__a)),
          "child": (this.__k5 || (this.__k5 = new Text({
            "data": "Bump count"
          })))
        })
      ]
    });
  }
}

