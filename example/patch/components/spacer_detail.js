// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/spacer_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, Container, ElevatedButton, OutlinedButton, Row, SizedBox, Spacer, Text } from '../flutter.js';

// 组件 SpacerDetail
export class SpacerDetail {
  constructor(args) {
    this.props = args || {};
    this._flex = 1;
  }
  build(context) {
    return new Column({
      "mainAxisSize": "min",
      "crossAxisAlignment": "stretch",
      "children": [
        new Container({
          "color": Colors.grey.shade100,
          "padding": {
            "left": 12.0,
            "top": 12.0,
            "right": 12.0,
            "bottom": 12.0
          },
          "child": new Column({
            "crossAxisAlignment": "start",
            "children": [
              new Text({
                "style": {
                  "fontSize": 13,
                  "fontWeight": "bold"
                },
                "data": "Row：Spacer(flex: " + this._flex + ") 在中间，右侧 1 份"
              }),
              (this.__k0 || (this.__k0 = new SizedBox({
                "height": 8
              }))),
              new Row({
                "children": [
                  new Container({
                    "width": 40,
                    "height": 40,
                    "color": Colors.indigo,
                    "alignment": "center",
                    "child": (this.__k1 || (this.__k1 = new Text({
                      "data": "A",
                      "style": {
                        "color": Colors.white
                      }
                    })))
                  }),
                  new Spacer({
                    "flex": this._flex
                  }),
                  new Container({
                    "width": 40,
                    "height": 40,
                    "color": Colors.teal,
                    "alignment": "center",
                    "child": (this.__k2 || (this.__k2 = new Text({
                      "data": "B",
                      "style": {
                        "color": Colors.white
                      }
                    })))
                  }),
                  (this.__k3 || (this.__k3 = new Spacer({}))),
                  new Container({
                    "width": 40,
                    "height": 40,
                    "color": Colors.orange,
                    "alignment": "center",
                    "child": (this.__k4 || (this.__k4 = new Text({
                      "data": "C",
                      "style": {
                        "color": Colors.white
                      }
                    })))
                  })
                ]
              }),
              (this.__k0 || (this.__k0 = new SizedBox({
                "height": 8
              }))),
              new Row({
                "children": [
                  new OutlinedButton({
                    "onPressed": this.__bindFn(0, [], () => this.setState(() => {
                      this._flex = 1;
                    })),
                    "child": (this.__k5 || (this.__k5 = new Text({
                      "data": "flex 1"
                    })))
                  }),
                  (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 8
                  }))),
                  new OutlinedButton({
                    "onPressed": this.__bindFn(1, [], () => this.setState(() => {
                      this._flex = 2;
                    })),
                    "child": (this.__k7 || (this.__k7 = new Text({
                      "data": "flex 2"
                    })))
                  }),
                  (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 8
                  }))),
                  new OutlinedButton({
                    "onPressed": this.__bindFn(2, [], () => this.setState(() => {
                      this._flex = 3;
                    })),
                    "child": (this.__k8 || (this.__k8 = new Text({
                      "data": "flex 3"
                    })))
                  })
                ]
              })
            ]
          })
        }),
        (this.__k9 || (this.__k9 = new SizedBox({
          "height": 12
        }))),
        new SizedBox({
          "height": 220,
          "child": new Container({
            "padding": {
              "left": 12.0,
              "top": 12.0,
              "right": 12.0,
              "bottom": 12.0
            },
            "decoration": {
              "border": {
                "all": {
                  "color": Colors.grey.shade300
                }
              },
              "borderRadius": {
                "radius": 12.0
              }
            },
            "child": new Column({
              "crossAxisAlignment": "stretch",
              "children": [
                (this.__k10 || (this.__k10 = new Text({
                  "data": "Column：中间一个 Spacer()，底部按钮被顶到底",
                  "style": {
                    "color": Colors.black54,
                    "fontSize": 13
                  }
                }))),
                (this.__k3 || (this.__k3 = new Spacer({}))),
                new ElevatedButton({
                  "onPressed": this.__bindFn(3, [], () => {}),
                  "child": (this.__k11 || (this.__k11 = new Text({
                    "data": "贴底按钮（由 Spacer 顶下来）"
                  })))
                })
              ]
            })
          })
        })
      ]
    });
  }
}

