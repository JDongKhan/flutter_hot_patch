// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/spacer_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { AppBar, Column, Container, ElevatedButton, Expanded, OutlinedButton, Row, Scaffold, SizedBox, Spacer, Text } from '../flutter.js';

// 组件 SpacerDetail
export class SpacerDetail {
  constructor(args) {
    this.props = args || {};
    this._flex = 1;
  }
  build(context) {
    return new Scaffold({
      "appBar": new AppBar({
        "title": (this.__k0 || (this.__k0 = new Text({
          "data": "Spacer"
        })))
      }),
      "body": new Column({
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
                    "fontSize": 14,
                    "fontWeight": "bold"
                  },
                  "data": "Row：Spacer(flex: " + this._flex + ") 在中间，两侧各 1 份"
                }),
                (this.__k1 || (this.__k1 = new SizedBox({
                  "height": 8
                }))),
                new Row({
                  "children": [
                    new Container({
                      "width": 44,
                      "height": 44,
                      "color": Colors.indigo,
                      "alignment": "center",
                      "child": (this.__k2 || (this.__k2 = new Text({
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
                      "width": 44,
                      "height": 44,
                      "color": Colors.teal,
                      "alignment": "center",
                      "child": (this.__k3 || (this.__k3 = new Text({
                        "data": "B",
                        "style": {
                          "color": Colors.white
                        }
                      })))
                    }),
                    (this.__k4 || (this.__k4 = new Spacer({}))),
                    new Container({
                      "width": 44,
                      "height": 44,
                      "color": Colors.orange,
                      "alignment": "center",
                      "child": (this.__k5 || (this.__k5 = new Text({
                        "data": "C",
                        "style": {
                          "color": Colors.white
                        }
                      })))
                    })
                  ]
                }),
                (this.__k1 || (this.__k1 = new SizedBox({
                  "height": 8
                }))),
                new Row({
                  "children": [
                    new OutlinedButton({
                      "onPressed": this.__bindFn(0, [], () => this.setState(() => {
                        this._flex = 1;
                      })),
                      "child": (this.__k6 || (this.__k6 = new Text({
                        "data": "flex 1"
                      })))
                    }),
                    (this.__k7 || (this.__k7 = new SizedBox({
                      "width": 8
                    }))),
                    new OutlinedButton({
                      "onPressed": this.__bindFn(1, [], () => this.setState(() => {
                        this._flex = 2;
                      })),
                      "child": (this.__k8 || (this.__k8 = new Text({
                        "data": "flex 2"
                      })))
                    }),
                    (this.__k7 || (this.__k7 = new SizedBox({
                      "width": 8
                    }))),
                    new OutlinedButton({
                      "onPressed": this.__bindFn(2, [], () => this.setState(() => {
                        this._flex = 3;
                      })),
                      "child": (this.__k9 || (this.__k9 = new Text({
                        "data": "flex 3"
                      })))
                    })
                  ]
                })
              ]
            })
          }),
          new Expanded({
            "child": new Container({
              "margin": {
                "left": 12.0,
                "top": 12.0,
                "right": 12.0,
                "bottom": 12.0
              },
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
                  (this.__k4 || (this.__k4 = new Spacer({}))),
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
      })
    });
  }
}

