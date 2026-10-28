// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/safe_area_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, Container, Row, SafeArea, SizedBox, Switch, Text } from '../flutter.js';

// 组件 SafeAreaDetail
export class SafeAreaDetail {
  constructor(args) {
    this.props = args || {};
    this._enabled = true;
  }
  build(context) {
    var padding = MediaQuery.paddingOf(context);
    return new Column({
      "crossAxisAlignment": "start",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "SafeArea",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "系统安全区 padding 全为 0 时 SafeArea 默认无可见间距；用 minimum 强制留白即可验证生效",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 10
        }))),
        new Row({
          "children": [
            (this.__k4 || (this.__k4 = new Text({
              "data": "minimum 留白",
              "style": {
                "fontSize": 12
              }
            }))),
            new Switch({
              "value": this._enabled,
              "onChanged": this.__bindFn(0, [], (v) => this.setState(() => {
                this._enabled = v;
              }))
            })
          ]
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new Container({
          "color": Colors.grey.shade300,
          "child": new SafeArea({
            "left": true,
            "top": true,
            "right": true,
            "bottom": true,
            "minimum": this._enabled ? {"left": 12.0, "top": 12.0, "right": 12.0, "bottom": 12.0} : {"left": 0, "top": 0, "right": 0, "bottom": 0},
            "maintainBottomViewPadding": false,
            "child": new Container({
              "height": 56,
              "color": Colors.teal,
              "alignment": "center",
              "child": (this.__k6 || (this.__k6 = new Text({
                "data": "SafeArea 内区域",
                "style": {
                  "color": Colors.white,
                  "fontSize": 13
                }
              })))
            })
          })
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
          "child": new Column({
            "crossAxisAlignment": "start",
            "children": [
              new Text({
                "style": {
                  "fontSize": 12
                },
                "data": "padding: L" + padding.left.toStringAsFixed(0) + " T" + padding.top.toStringAsFixed(0) + " " + "R" + padding.right.toStringAsFixed(0) + " B" + padding.bottom.toStringAsFixed(0)
              }),
              (this.__k7 || (this.__k7 = new SizedBox({
                "height": 2
              }))),
              new Text({
                "style": {
                  "fontSize": 12,
                  "color": Colors.black54
                },
                "data": this._enabled ? "minimum: 每边 12（灰色即为留白）" : "minimum: 0（本机系统 padding 为 0，故无留白）"
              })
            ]
          })
        })
      ]
    });
  }
}

