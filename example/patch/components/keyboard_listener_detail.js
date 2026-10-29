// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/keyboard_listener_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, Column, Container, FocusNode, KeyDownEvent, KeyRepeatEvent, KeyboardListener, LogicalKeyboardKey, OutlinedButton, Row, SizedBox, Text } from '../flutter.js';

// 组件 KeyboardListenerDetail
export class KeyboardListenerDetail {
  constructor(args) {
    this.props = args || {};
    this._node = new FocusNode({debugLabel: "keyboard-listener-demo"});
    this._row = 1;
    this._col = 1;
    this._lit = false;
    this._down = 0;
    this._up = 0;
    this._repeat = 0;
    this._last = "（还没有按键：点一下面板再按方向键）";
    this._char = "（无）";
    this._phys = "（无）";
  }
  dispose() {
    this._node.dispose();
  }
  _onKey(event) {
    var key = event.logicalKey;
    if ((event instanceof KeyDownEvent)) {
      this.setState(() => { this._down += 1; this._last = "KeyDown  " + key.keyLabel; this._char = (event.character ?? "（无）"); this._phys = (event.physicalKey.debugName ?? "（无）"); if ((key == LogicalKeyboardKey.arrowUp)) {   this._row = (((this._row + 2)) % 3); } if ((key == LogicalKeyboardKey.arrowDown)) {   this._row = (((this._row + 1)) % 3); } if ((key == LogicalKeyboardKey.arrowLeft)) {   this._col = (((this._col + 2)) % 3); } if ((key == LogicalKeyboardKey.arrowRight)) {   this._col = (((this._col + 1)) % 3); } if ((key == LogicalKeyboardKey.space)) {   this._lit = (!this._lit); } if ((key == LogicalKeyboardKey.escape)) {   this._row = 1;   this._col = 1;   this._lit = false; } });
      return;
    }
    if ((event instanceof KeyRepeatEvent)) {
      this.setState(() => { this._repeat += 1; });
      return;
    }
    this.setState(() => { this._up += 1; this._last = "KeyUp  " + key.keyLabel; });
  }
  _cell(r, c) {
    var active = ((r == this._row) && (c == this._col));
    return new Container({
      "width": 36,
      "height": 36,
      "margin": {
        "left": 3.0,
        "top": 3.0,
        "right": 3.0,
        "bottom": 3.0
      },
      "alignment": "center",
      "decoration": {
        "color": (active ? ((this._lit ? Colors.amber : Colors.deepPurple)) : Colors.grey.shade200),
        "borderRadius": {
          "radius": 4.0
        }
      },
      "child": new Text({
        "style": {
          "color": Colors.white,
          "fontSize": 12
        },
        "data": active ? "●" : ""
      })
    });
  }
  _gridRow(r) {
    return new Row({
      "mainAxisSize": "min",
      "children": [
        this._cell(r, 0),
        this._cell(r, 1),
        this._cell(r, 2)
      ]
    });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "start",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "KeyboardListener",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "方向键移动方块，空格切换颜色，Esc 复位；KeyDown / KeyRepeat / KeyUp 分别计数",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 10
        }))),
        new KeyboardListener({
          "focusNode": this._node,
          "autofocus": true,
          "onKeyEvent": this.__bindFn(0, [], (...__a) => this._onKey(...__a)),
          "child": new Container({
            "padding": {
              "left": 10.0,
              "top": 10.0,
              "right": 10.0,
              "bottom": 10.0
            },
            "decoration": {
              "border": {
                "all": {
                  "color": Colors.grey.shade300
                }
              },
              "borderRadius": {
                "radius": 8.0
              }
            },
            "child": new Column({
              "crossAxisAlignment": "start",
              "children": [
                new Column({
                  "mainAxisSize": "min",
                  "children": [
                    this._gridRow(0),
                    this._gridRow(1),
                    this._gridRow(2)
                  ]
                }),
                (this.__k4 || (this.__k4 = new SizedBox({
                  "height": 8
                }))),
                new Text({
                  "style": {
                    "fontSize": 12
                  },
                  "data": "最近事件：" + this._last
                }),
                new Text({
                  "style": {
                    "fontSize": 12
                  },
                  "data": "字符 character：" + this._char
                }),
                new Text({
                  "style": {
                    "fontSize": 12
                  },
                  "data": "物理键：" + this._phys
                }),
                new Text({
                  "style": {
                    "fontSize": 12,
                    "color": Colors.black54
                  },
                  "data": "KeyDown " + this._down + " · KeyRepeat " + this._repeat + " · KeyUp " + this._up
                })
              ]
            })
          })
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 10
        }))),
        new Row({
          "children": [
            new OutlinedButton({
              "onPressed": this.__bindFn(1, [], () => this._node.requestFocus()),
              "child": (this.__k5 || (this.__k5 = new Text({
                "data": "让面板获得焦点"
              })))
            }),
            (this.__k6 || (this.__k6 = new SizedBox({
              "width": 8
            }))),
            new OutlinedButton({
              "onPressed": this.__bindFn(2, [], () => { this.setState(() => { this._row = 1; this._col = 1; this._lit = false; }); }),
              "child": (this.__k7 || (this.__k7 = new Text({
                "data": "复位方块"
              })))
            })
          ]
        })
      ]
    });
  }
}

