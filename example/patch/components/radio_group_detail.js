// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/radio_group_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, Container, Radio, RadioGroup, Row, SizedBox, Text } from '../flutter.js';

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
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "子级 Radio 只声明 value，选中值与回调统一由上方 RadioGroup 提供",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
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
          "padding": {
            "left": 8.0,
            "top": 8.0,
            "right": 8.0,
            "bottom": 8.0
          },
          "decoration": {
            "color": Colors.grey.shade100,
            "borderRadius": {
              "radius": 6.0
            }
          },
          "child": new Text({
            "style": {
              "fontSize": 12
            },
            "data": "当前选中：" + this._selected
          })
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 8
        }))),
        (this.__k5 || (this.__k5 = new Text({
          "data": "① 点圆点切换选中项；② 焦点在组内时按方向键可上下切换；③ 选中值实时显示在下方。",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
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
        (this.__k6 || (this.__k6 = new SizedBox({
          "width": 4
        }))),
        new Text({
          "style": {
            "fontSize": 14
          },
          "data": label
        })
      ]
    });
  }
}

