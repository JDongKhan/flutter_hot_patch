// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/pop_scope_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, Column, Container, PopScope, Row, SizedBox, Switch, Text } from '../flutter.js';

// 组件 PopScopeDetail
export class PopScopeDetail {
  constructor(args) {
    this.props = args || {};
    this._canPop = true;
    this._invoked = 0;
    this._lastDidPop = true;
    this._lastResult = "（无）";
  }
  _onPopInvoked(didPop, result) {
    this.setState(() => { this._invoked += 1; this._lastDidPop = didPop; this._lastResult = ((result == null) ? "（无）" : result); });
  }
  build(context) {
    return new PopScope({
      "canPop": this._canPop,
      "onPopInvokedWithResult": this.__bindFn(0, [], (...__a) => this._onPopInvoked(...__a)),
      "child": new Column({
        "crossAxisAlignment": "start",
        "children": [
          (this.__k0 || (this.__k0 = new Text({
            "data": "PopScope",
            "style": {
              "fontWeight": "bold"
            }
          }))),
          (this.__k1 || (this.__k1 = new SizedBox({
            "height": 4
          }))),
          (this.__k2 || (this.__k2 = new Text({
            "data": "点左上角返回箭头：开关打开（canPop=false）时页面不会退出，回调 didPop=false",
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
                "data": "拦截返回（canPop = false）",
                "style": {
                  "fontSize": 12
                }
              }))),
              new Switch({
                "value": (!this._canPop),
                "onChanged": this.__bindFn(1, [], (v) => this.setState(() => {
                  this._canPop = (!v);
                }))
              }),
              new Text({
                "style": {
                  "fontSize": 12,
                  "color": Colors.black54
                },
                "data": this._canPop ? "canPop: true" : "canPop: false"
              })
            ]
          }),
          (this.__k5 || (this.__k5 = new SizedBox({
            "height": 6
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
                  "data": "回调次数：" + this._invoked
                }),
                new Text({
                  "style": {
                    "fontSize": 12
                  },
                  "data": "最近 didPop：" + this._lastDidPop
                }),
                new Text({
                  "style": {
                    "fontSize": 12
                  },
                  "data": "最近 result：" + this._lastResult
                })
              ]
            })
          })
        ]
      })
    });
  }
}

