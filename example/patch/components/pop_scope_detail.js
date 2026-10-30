// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/pop_scope_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { BorderRadius, BoxDecoration, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, FontWeight, PopScope, Radius, Row, SizedBox, Switch, Text, TextStyle } from '../flutter.js';

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
        "crossAxisAlignment": CrossAxisAlignment.start,
        "children": [
          (this.__k0 || (this.__k0 = new Text({
            "data": "PopScope",
            "style": new TextStyle({
              "fontWeight": FontWeight.bold
            })
          }))),
          (this.__k1 || (this.__k1 = new SizedBox({
            "height": 4
          }))),
          (this.__k2 || (this.__k2 = new Text({
            "data": "点左上角返回箭头：开关打开（canPop=false）时页面不会退出，回调 didPop=false",
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.black54
            })
          }))),
          (this.__k3 || (this.__k3 = new SizedBox({
            "height": 10
          }))),
          new Row({
            "children": [
              (this.__k4 || (this.__k4 = new Text({
                "data": "拦截返回（canPop = false）",
                "style": new TextStyle({
                  "fontSize": 12
                })
              }))),
              new Switch({
                "value": (!this._canPop),
                "onChanged": this.__bindFn(1, [], (v) => this.setState(() => {
                  this._canPop = (!v);
                }))
              }),
              new Text({
                "style": (this.__k5 || (this.__k5 = new TextStyle({
                  "color": Colors.black54,
                  "fontSize": 12
                }))),
                "data": this._canPop ? "canPop: true" : "canPop: false"
              })
            ]
          }),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 6
          }))),
          new Container({
            "padding": (this.__k7 || (this.__k7 = EdgeInsets.all({
              "value": 8
            }))),
            "decoration": new BoxDecoration({
              "color": Colors.grey.shade100,
              "borderRadius": (this.__k8 || (this.__k8 = BorderRadius.all({
                "radius": Radius.circular({
                  "radius": 6
                })
              })))
            }),
            "child": new Column({
              "crossAxisAlignment": CrossAxisAlignment.start,
              "children": [
                new Text({
                  "style": (this.__k9 || (this.__k9 = new TextStyle({
                    "fontSize": 12
                  }))),
                  "data": "回调次数：" + this._invoked
                }),
                new Text({
                  "style": (this.__k9 || (this.__k9 = new TextStyle({
                    "fontSize": 12
                  }))),
                  "data": "最近 didPop：" + this._lastDidPop
                }),
                new Text({
                  "style": (this.__k9 || (this.__k9 = new TextStyle({
                    "fontSize": 12
                  }))),
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

