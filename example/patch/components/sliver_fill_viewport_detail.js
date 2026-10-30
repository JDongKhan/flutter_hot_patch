// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/sliver_fill_viewport_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, AppBar, BorderRadius, BoxDecoration, Center, Colors, Column, Container, CrossAxisAlignment, CustomScrollView, EdgeInsets, Expanded, FontWeight, MainAxisSize, OutlinedButton, Row, Scaffold, SizedBox, SliverFillViewport, Text, TextStyle } from '../flutter.js';

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
            "padding": (this.__k1 || (this.__k1 = EdgeInsets.fromLTRB({
              "bottom": 10,
              "left": 12,
              "right": 12,
              "top": 10
            }))),
            "color": Colors.grey.shade100,
            "child": new Column({
              "crossAxisAlignment": CrossAxisAlignment.start,
              "children": [
                new Text({
                  "style": (this.__k2 || (this.__k2 = new TextStyle({
                    "fontSize": 14,
                    "fontWeight": FontWeight.bold
                  }))),
                  "data": "viewportFraction = " + this._fraction
                }),
                (this.__k3 || (this.__k3 = new SizedBox({
                  "height": 2
                }))),
                (this.__k4 || (this.__k4 = new Text({
                  "data": "每屏高度 = 视口高度 × fraction；滚动按屏翻页",
                  "style": new TextStyle({
                    "fontSize": 12,
                    "color": Colors.black54
                  })
                }))),
                (this.__k5 || (this.__k5 = new SizedBox({
                  "height": 8
                }))),
                new Row({
                  "children": [
                    new OutlinedButton({
                      "onPressed": this.__bindFn(0, [], () => this._setFraction(1.0)),
                      "child": (this.__k6 || (this.__k6 = new Text({
                        "data": "1.0 整屏"
                      })))
                    }),
                    (this.__k7 || (this.__k7 = new SizedBox({
                      "width": 8
                    }))),
                    new OutlinedButton({
                      "onPressed": this.__bindFn(1, [], () => this._setFraction(0.8)),
                      "child": (this.__k8 || (this.__k8 = new Text({
                        "data": "0.8"
                      })))
                    }),
                    (this.__k7 || (this.__k7 = new SizedBox({
                      "width": 8
                    }))),
                    new OutlinedButton({
                      "onPressed": this.__bindFn(2, [], () => this._setFraction(0.5)),
                      "child": (this.__k9 || (this.__k9 = new Text({
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
                      "margin": (this.__k10 || (this.__k10 = EdgeInsets.all({
                        "value": 12
                      }))),
                      "padding": (this.__k11 || (this.__k11 = EdgeInsets.all({
                        "value": 16
                      }))),
                      "decoration": new BoxDecoration({
                        "color": ((index % 2) == 0) ? Colors.teal.shade100 : Colors.orange.shade100,
                        "borderRadius": BorderRadius.circular({
                          "radius": 16
                        })
                      }),
                      "child": new Center({
                        "child": new Column({
                          "mainAxisSize": MainAxisSize.min,
                          "children": [
                            new Text({
                              "style": (this.__k12 || (this.__k12 = new TextStyle({
                                "fontSize": 18,
                                "fontWeight": FontWeight.bold
                              }))),
                              "data": "第 " + index + " 屏 / 共 5 屏"
                            }),
                            (this.__k13 || (this.__k13 = new SizedBox({
                              "height": 4
                            }))),
                            new Text({
                              "style": (this.__k14 || (this.__k14 = new TextStyle({
                                "color": Colors.black54,
                                "fontSize": 12
                              }))),
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
            "padding": (this.__k15 || (this.__k15 = EdgeInsets.symmetric({
              "horizontal": 12,
              "vertical": 6
            }))),
            "color": Colors.grey.shade200,
            "child": (this.__k16 || (this.__k16 = new Text({
              "data": "padEnds: false · fraction 0.5 · 3 项（首屏贴顶，不留白）",
              "style": new TextStyle({
                "fontSize": 12,
                "color": Colors.black87
              })
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
                      "margin": (this.__k17 || (this.__k17 = EdgeInsets.fromLTRB({
                        "bottom": 6,
                        "left": 12,
                        "right": 12,
                        "top": 6
                      }))),
                      "alignment": Alignment.center,
                      "decoration": new BoxDecoration({
                        "color": Colors.deepPurple.shade100,
                        "borderRadius": BorderRadius.circular({
                          "radius": 10
                        })
                      }),
                      "child": new Text({
                        "style": (this.__k18 || (this.__k18 = new TextStyle({
                          "fontSize": 13
                        }))),
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

