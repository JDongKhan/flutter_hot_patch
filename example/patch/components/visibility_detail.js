// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/visibility_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, Center, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, ElevatedButton, FontWeight, MainAxisSize, Offstage, OutlinedButton, Row, SizedBox, Text, TextStyle, Visibility } from '../flutter.js';

// 组件 VisibilityDetail
export class VisibilityDetail {
  constructor(args) {
    this.props = args || {};
    this._visible = true;
    this._maintainSize = false;
    this._maintainSemantics = false;
    this._maintainInteractivity = false;
    this._offstage = false;
    this._taps = 0;
  }
  _show() {
    this.setState(() => { this._visible = true; this._maintainSize = false; this._maintainSemantics = false; this._maintainInteractivity = false; });
  }
  _hideTight() {
    this.setState(() => { this._visible = false; this._maintainSize = false; this._maintainSemantics = false; this._maintainInteractivity = false; });
  }
  _hideKeepSpace() {
    this.setState(() => { this._visible = false; this._maintainSize = true; this._maintainSemantics = false; this._maintainInteractivity = false; });
  }
  _hideKeepTap() {
    this.setState(() => { this._visible = false; this._maintainSize = true; this._maintainSemantics = true; this._maintainInteractivity = true; });
  }
  _toggleOffstage() {
    this.setState(() => { this._offstage = (!this._offstage); });
  }
  _onTap() {
    this.setState(() => { this._taps += 1; });
  }
  build(context) {
    return new Column({
      "mainAxisSize": MainAxisSize.min,
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        new Container({
          "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
            "value": 12
          }))),
          "color": Colors.grey.shade100,
          "child": new Column({
            "mainAxisSize": MainAxisSize.min,
            "crossAxisAlignment": CrossAxisAlignment.stretch,
            "children": [
              new Text({
                "style": (this.__k1 || (this.__k1 = new TextStyle({
                  "fontSize": 13,
                  "fontWeight": FontWeight.bold
                }))),
                "data": "Visibility（visible=" + this._visible + "，maintainSize=" + this._maintainSize + "）"
              }),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 8
              }))),
              new Visibility({
                "visible": this._visible,
                "maintainState": this._maintainSize,
                "maintainAnimation": this._maintainSize,
                "maintainSize": this._maintainSize,
                "maintainSemantics": this._maintainSemantics,
                "maintainInteractivity": this._maintainInteractivity,
                "replacement": (this.__k3 || (this.__k3 = new Center({
                  "child": new Text({
                    "style": new TextStyle({
                      "fontSize": 12
                    }),
                    "data": "replacement 顶替显示"
                  })
                }))),
                "child": new Container({
                  "height": 64,
                  "color": Colors.teal.shade100,
                  "alignment": Alignment.center,
                  "child": new ElevatedButton({
                    "onPressed": this.__bindFn(0, [], (...__a) => this._onTap(...__a)),
                    "child": new Text({
                      "data": "点我（已点 " + this._taps + " 次）"
                    })
                  })
                })
              }),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 8
              }))),
              (this.__k4 || (this.__k4 = new Text({
                "data": "↓ 下面这行用来观察是否仍占位",
                "style": new TextStyle({
                  "fontSize": 12,
                  "color": Colors.black54
                })
              }))),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 8
              }))),
              new Row({
                "children": [
                  new OutlinedButton({
                    "onPressed": this.__bindFn(1, [], (...__a) => this._show(...__a)),
                    "child": (this.__k5 || (this.__k5 = new Text({
                      "data": "显示"
                    })))
                  }),
                  (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 6
                  }))),
                  new OutlinedButton({
                    "onPressed": this.__bindFn(2, [], (...__a) => this._hideTight(...__a)),
                    "child": (this.__k7 || (this.__k7 = new Text({
                      "data": "隐藏·不占位"
                    })))
                  }),
                  (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 6
                  }))),
                  new OutlinedButton({
                    "onPressed": this.__bindFn(3, [], (...__a) => this._hideKeepSpace(...__a)),
                    "child": (this.__k8 || (this.__k8 = new Text({
                      "data": "隐藏·占位"
                    })))
                  }),
                  (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 6
                  }))),
                  new OutlinedButton({
                    "onPressed": this.__bindFn(4, [], (...__a) => this._hideKeepTap(...__a)),
                    "child": (this.__k9 || (this.__k9 = new Text({
                      "data": "隐藏·仍可点"
                    })))
                  })
                ]
              })
            ]
          })
        }),
        (this.__k10 || (this.__k10 = new SizedBox({
          "height": 12
        }))),
        new Container({
          "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
            "value": 12
          }))),
          "color": Colors.grey.shade100,
          "child": new Column({
            "mainAxisSize": MainAxisSize.min,
            "crossAxisAlignment": CrossAxisAlignment.stretch,
            "children": [
              new Text({
                "style": (this.__k1 || (this.__k1 = new TextStyle({
                  "fontSize": 13,
                  "fontWeight": FontWeight.bold
                }))),
                "data": "Offstage（offstage=" + this._offstage + "）"
              }),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 8
              }))),
              new Offstage({
                "offstage": this._offstage,
                "child": new Container({
                  "height": 56,
                  "color": Colors.orange.shade100,
                  "alignment": Alignment.center,
                  "child": new Text({
                    "data": "Offstage 内容（点我 " + this._taps + " 次）"
                  })
                })
              }),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 8
              }))),
              (this.__k11 || (this.__k11 = new Text({
                "data": "↑ offstage 时不占位、不绘制、不响应点击（State 仍保留）",
                "style": new TextStyle({
                  "fontSize": 12,
                  "color": Colors.black54
                })
              }))),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 8
              }))),
              new Row({
                "children": [
                  new OutlinedButton({
                    "onPressed": this.__bindFn(5, [], (...__a) => this._toggleOffstage(...__a)),
                    "child": new Text({
                      "data": this._offstage ? "关闭 offstage" : "打开 offstage"
                    })
                  })
                ]
              })
            ]
          })
        })
      ]
    });
  }
}

