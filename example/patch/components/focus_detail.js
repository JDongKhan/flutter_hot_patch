// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/focus_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, Container, Focus, GestureDetector, OutlinedButton, Row, SizedBox, Text } from '../flutter.js';

// 组件 FocusDetail
export class FocusDetail {
  constructor(args) {
    this.props = args || {};
    this._a = new FocusNode({debugLabel: "node-a"});
    this._b = new FocusNode({debugLabel: "node-b"});
    this._log = "（暂无焦点变化）";
  }
  initState() {
    this._a.addListener((...args) => this._refresh(...args));
    this._b.addListener((...args) => this._refresh(...args));
  }
  dispose() {
    this._a.removeListener((...args) => this._refresh(...args));
    this._b.removeListener((...args) => this._refresh(...args));
    this._a.dispose();
    this._b.dispose();
  }
  _refresh() {
    this.setState(() => {});
  }
  _record(label, hasFocus) {
    this.setState(() => { this._log = (hasFocus ? label + " 获得焦点" : label + " 失去焦点"); });
  }
  get _current() {
    if (this._a.hasFocus) {
      return "A";
    }
    if (this._b.hasFocus) {
      return "B";
    }
    return "无";
  }
  _box(label, node) {
    return new Focus({
      "focusNode": node,
      "onFocusChange": this.__bindFn(0, [label], (v) => this._record(label, v)),
      "child": new GestureDetector({
        "onTap": this.__bindFn(1, [node], () => node.requestFocus()),
        "child": new Container({
          "width": 80,
          "height": 56,
          "alignment": "center",
          "decoration": {
            "color": (node.hasFocus ? Colors.deepPurple : Colors.grey.shade200),
            "borderRadius": {
              "radius": 8.0
            }
          },
          "child": new Text({
            "style": {
              "color": (node.hasFocus ? Colors.white : Colors.black87),
              "fontWeight": "bold"
            },
            "data": label
          })
        })
      })
    });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Focus / FocusNode",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "点块或按钮切换焦点；C 声明 canRequestFocus: false，点了不聚焦",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Row({
          "children": [
            this._box("A", this._a),
            (this.__k4 || (this.__k4 = new SizedBox({
              "width": 12
            }))),
            this._box("B", this._b),
            (this.__k4 || (this.__k4 = new SizedBox({
              "width": 12
            }))),
            new Focus({
              "canRequestFocus": false,
              "child": new Container({
                "width": 80,
                "height": 56,
                "alignment": "center",
                "decoration": {
                  "color": Colors.grey.shade100,
                  "borderRadius": {
                    "radius": 8.0
                  },
                  "border": {
                    "all": {
                      "color": Colors.grey.shade400
                    }
                  }
                },
                "child": (this.__k5 || (this.__k5 = new Text({
                  "data": "C\n(不可聚焦)",
                  "style": {
                    "fontSize": 11
                  },
                  "textAlign": "center"
                })))
              })
            })
          ]
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": {
            "fontSize": 13
          },
          "data": "当前聚焦：" + this._current
        }),
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "style": {
            "fontSize": 12,
            "color": Colors.black54
          },
          "data": "变化日志：" + this._log
        }),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 8
        }))),
        new Row({
          "children": [
            new OutlinedButton({
              "onPressed": this.__bindFn(2, [], () => this._a.requestFocus()),
              "child": (this.__k8 || (this.__k8 = new Text({
                "data": "聚焦 A"
              })))
            }),
            (this.__k9 || (this.__k9 = new SizedBox({
              "width": 8
            }))),
            new OutlinedButton({
              "onPressed": this.__bindFn(3, [], () => this._b.requestFocus()),
              "child": (this.__k10 || (this.__k10 = new Text({
                "data": "聚焦 B"
              })))
            }),
            (this.__k9 || (this.__k9 = new SizedBox({
              "width": 8
            }))),
            new OutlinedButton({
              "onPressed": this.__bindFn(4, [], () => this._a.unfocus()),
              "child": (this.__k11 || (this.__k11 = new Text({
                "data": "失焦"
              })))
            })
          ]
        })
      ]
    });
  }
}

