// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/sliver_fill_viewport_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { AppBar, Center, Column, Container, CustomScrollView, Expanded, OutlinedButton, Row, Scaffold, SizedBox, SliverFillViewport, Text } from '../flutter.js';

// 组件 SliverFillViewportDetail
export class SliverFillViewportDetail {
  constructor(args) {
    this.props = args || {};
    this._fraction = 1.0;
  }
  _setFraction(value) {
    this.setState(() => { this._fraction = value; });
  }
  build(context) {
    return new Scaffold({
      "appBar": new AppBar({
        "title": (this.__k0 || (this.__k0 = new Text({
          "data": "SliverFillViewport"
        })))
      }),
      "body": new Column({
        "children": [
          new Container({
            "padding": {
              "left": 12.0,
              "top": 10.0,
              "right": 12.0,
              "bottom": 10.0
            },
            "color": Colors.grey.shade100,
            "child": new Column({
              "crossAxisAlignment": "start",
              "children": [
                new Text({
                  "style": {
                    "fontSize": 14,
                    "fontWeight": "bold"
                  },
                  "data": "viewportFraction = " + this._fraction
                }),
                (this.__k1 || (this.__k1 = new SizedBox({
                  "height": 2
                }))),
                (this.__k2 || (this.__k2 = new Text({
                  "data": "每屏高度 = 视口高度 × fraction；滚动按屏翻页",
                  "style": {
                    "color": Colors.black54,
                    "fontSize": 12
                  }
                }))),
                (this.__k3 || (this.__k3 = new SizedBox({
                  "height": 8
                }))),
                new Row({
                  "children": [
                    new OutlinedButton({
                      "onPressed": this.__bindFn(0, [], () => this._setFraction(1.0)),
                      "child": (this.__k4 || (this.__k4 = new Text({
                        "data": "1.0 整屏"
                      })))
                    }),
                    (this.__k5 || (this.__k5 = new SizedBox({
                      "width": 8
                    }))),
                    new OutlinedButton({
                      "onPressed": this.__bindFn(1, [], () => this._setFraction(0.8)),
                      "child": (this.__k6 || (this.__k6 = new Text({
                        "data": "0.8"
                      })))
                    }),
                    (this.__k5 || (this.__k5 = new SizedBox({
                      "width": 8
                    }))),
                    new OutlinedButton({
                      "onPressed": this.__bindFn(2, [], () => this._setFraction(0.5)),
                      "child": (this.__k7 || (this.__k7 = new Text({
                        "data": "0.5"
                      })))
                    })
                  ]
                })
              ]
            })
          }),
          new Expanded({
            "child": new CustomScrollView({
              "slivers": [
                new SliverFillViewport({
                  "viewportFraction": this._fraction,
                  "padEnds": true,
                  "delegate": {
                    "__delegate": "builder",
                    "builder": (context, index) => new Container({
                      "margin": {
                        "left": 12.0,
                        "top": 12.0,
                        "right": 12.0,
                        "bottom": 12.0
                      },
                      "padding": {
                        "left": 16.0,
                        "top": 16.0,
                        "right": 16.0,
                        "bottom": 16.0
                      },
                      "decoration": {
                        "color": (((index % 2) == 0) ? Colors.teal.shade100 : Colors.orange.shade100),
                        "borderRadius": {
                          "radius": 16.0
                        }
                      },
                      "child": new Center({
                        "child": new Column({
                          "mainAxisSize": "min",
                          "children": [
                            new Text({
                              "style": {
                                "fontSize": 18,
                                "fontWeight": "bold"
                              },
                              "data": "第 " + index + " 屏 / 共 5 屏"
                            }),
                            (this.__k8 || (this.__k8 = new SizedBox({
                              "height": 4
                            }))),
                            new Text({
                              "style": {
                                "fontSize": 12,
                                "color": Colors.black54
                              },
                              "data": "SliverChildBuilderDelegate · fraction = " + this._fraction
                            })
                          ]
                        })
                      })
                    }),
                    "childCount": 5
                  }
                })
              ]
            })
          }),
          new Container({
            "padding": {
              "left": 12.0,
              "top": 6.0,
              "right": 12.0,
              "bottom": 6.0
            },
            "color": Colors.grey.shade200,
            "child": (this.__k9 || (this.__k9 = new Text({
              "data": "padEnds: false · fraction 0.5 · 3 项（首屏贴顶，不留白）",
              "style": {
                "color": Colors.black87,
                "fontSize": 12
              }
            })))
          }),
          new SizedBox({
            "height": 160,
            "child": new CustomScrollView({
              "slivers": [
                new SliverFillViewport({
                  "viewportFraction": 0.5,
                  "padEnds": false,
                  "delegate": {
                    "__delegate": "builder",
                    "builder": (context, index) => new Container({
                      "margin": {
                        "left": 12.0,
                        "top": 6.0,
                        "right": 12.0,
                        "bottom": 6.0
                      },
                      "alignment": "center",
                      "decoration": {
                        "color": Colors.deepPurple.shade100,
                        "borderRadius": {
                          "radius": 10.0
                        }
                      },
                      "child": new Text({
                        "style": {
                          "fontSize": 13
                        },
                        "data": "padEnds false 第 " + index + " 项"
                      })
                    }),
                    "childCount": 3
                  }
                })
              ]
            })
          })
        ]
      })
    });
  }
}

