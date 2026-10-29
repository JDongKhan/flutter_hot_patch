// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/radio_group_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { BorderRadius, BoxDecoration, Colors, Column, Container, EdgeInsets, FontWeight, Radio, RadioGroup, Radius, Row, SizedBox, Text, TextStyle } from '../flutter.js';

// 组件 RadioGroupDetail
export class RadioGroupDetail {
  constructor(args) {
    this.props = args || {};
    this._selected = 1;
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "start",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "RadioGroup",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "子级 Radio 只声明 value，选中值与回调统一由上方 RadioGroup 提供",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 10
        }))),
        new RadioGroup({
          "groupValue": this._selected,
          "onChanged": this.__bindFn(0, [], (v) => this.setState(() => {
            this._selected = (v ?? this._selected);
          })),
          "child": new Column({
            "crossAxisAlignment": "start",
            "children": [
              this._option(0, "选项 A"),
              this._option(1, "选项 B"),
              this._option(2, "选项 C")
            ]
          }),
          "model": "int"
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 10
        }))),
        new Container({
          "padding": (this.__k4 || (this.__k4 = EdgeInsets.all({
            "value": 8
          }))),
          "decoration": new BoxDecoration({
            "color": Colors.grey.shade100,
            "borderRadius": (this.__k5 || (this.__k5 = BorderRadius.all({
              "radius": Radius.circular({
                "radius": 6
              })
            })))
          }),
          "child": new Text({
            "style": (this.__k6 || (this.__k6 = new TextStyle({
              "fontSize": 12
            }))),
            "data": "当前选中：" + this._selected
          })
        }),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 8
        }))),
        (this.__k8 || (this.__k8 = new Text({
          "data": "① 点圆点切换选中项；② 焦点在组内时按方向键可上下切换；③ 选中值实时显示在下方。",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        })))
      ]
    });
  }
  _option(value, label) {
    return new Row({
      "mainAxisSize": "min",
      "children": [
        new Radio({
          "value": value,
          "model": "int"
        }),
        (this.__k9 || (this.__k9 = new SizedBox({
          "width": 4
        }))),
        new Text({
          "style": (this.__k10 || (this.__k10 = new TextStyle({
            "fontSize": 14
          }))),
          "data": label
        })
      ]
    });
  }
}

