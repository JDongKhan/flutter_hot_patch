// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/sliver_fill_remaining_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Align, AppBar, Center, Column, Container, CustomScrollView, Expanded, OutlinedButton, Row, Scaffold, SizedBox, SliverFillRemaining, SliverToBoxAdapter, Switch, Text } from '../flutter.js';

// 组件 SliverFillRemainingDetail
export class SliverFillRemainingDetail {
  constructor(args) {
    this.props = args || {};
    this._hasScrollBody = true;
    this._fillOverscroll = false;
    this._tallHeader = false;
  }
  build(context) {
    return new Scaffold({
      "appBar": new AppBar({
        "title": (this.__k0 || (this.__k0 = new Text({
          "data": "SliverFillRemaining"
        })))
      }),
      "body": new CustomScrollView({
        "physics": "BouncingScrollPhysics",
        "slivers": [
          new SliverToBoxAdapter({
            "child": new Container({
              "padding": {
                "left": 12.0,
                "top": 12.0,
                "right": 12.0,
                "bottom": 12.0
              },
              "color": Colors.grey.shade100,
              "child": new Column({
                "crossAxisAlignment": "start",
                "children": [
                  (this.__k1 || (this.__k1 = new Text({
                    "data": "child 填满视口剩余高度，贴底元素始终贴底",
                    "style": {
                      "fontSize": 14,
                      "fontWeight": "bold"
                    }
                  }))),
                  (this.__k2 || (this.__k2 = new SizedBox({
                    "height": 2
                  }))),
                  (this.__k3 || (this.__k3 = new Text({
                    "data": "触底回弹：fillOverscroll=true 子级拉伸填满回弹区；false 整块位移",
                    "style": {
                      "color": Colors.black54,
                      "fontSize": 12
                    }
                  }))),
                  (this.__k4 || (this.__k4 = new SizedBox({
                    "height": 6
                  }))),
                  new Row({
                    "children": [
                      (this.__k5 || (this.__k5 = new Expanded({
                        "child": new Text({
                          "style": {
                            "fontSize": 12
                          },
                          "data": "hasScrollBody（缺省 true）"
                        })
                      }))),
                      new Switch({
                        "value": this._hasScrollBody,
                        "onChanged": this.__bindFn(0, [], (v) => this.setState(() => {
                          this._hasScrollBody = v;
                        }))
                      })
                    ]
                  }),
                  new Row({
                    "children": [
                      (this.__k6 || (this.__k6 = new Expanded({
                        "child": new Text({
                          "style": {
                            "fontSize": 12
                          },
                          "data": "fillOverscroll（缺省 false）"
                        })
                      }))),
                      new Switch({
                        "value": this._fillOverscroll,
                        "onChanged": this.__bindFn(1, [], (v) => this.setState(() => {
                          this._fillOverscroll = v;
                        }))
                      })
                    ]
                  }),
                  new Row({
                    "children": [
                      (this.__k7 || (this.__k7 = new Expanded({
                        "child": new Text({
                          "style": {
                            "fontSize": 12
                          },
                          "data": "加高头部（观察剩余高度变化）"
                        })
                      }))),
                      new Switch({
                        "value": this._tallHeader,
                        "onChanged": this.__bindFn(2, [], (v) => this.setState(() => {
                          this._tallHeader = v;
                        }))
                      })
                    ]
                  }),
                  new SizedBox({
                    "height": this._tallHeader ? 120 : 0
                  })
                ]
              })
            })
          }),
          new SliverFillRemaining({
            "hasScrollBody": this._hasScrollBody,
            "fillOverscroll": this._fillOverscroll,
            "child": new Container({
              "color": Colors.teal.shade50,
              "padding": {
                "left": 20.0,
                "top": 20.0,
                "right": 20.0,
                "bottom": 20.0
              },
              "child": new Column({
                "mainAxisAlignment": "spaceBetween",
                "crossAxisAlignment": "start",
                "children": [
                  new Column({
                    "crossAxisAlignment": "start",
                    "children": [
                      (this.__k8 || (this.__k8 = new Text({
                        "data": "剩余空间区域",
                        "style": {
                          "color": Colors.teal,
                          "fontSize": 16,
                          "fontWeight": "bold"
                        }
                      }))),
                      (this.__k9 || (this.__k9 = new SizedBox({
                        "height": 4
                      }))),
                      new Text({
                        "style": {
                          "fontSize": 12,
                          "color": Colors.black54
                        },
                        "data": "hasScrollBody = " + this._hasScrollBody + " · fillOverscroll = " + this._fillOverscroll
                      })
                    ]
                  }),
                  (this.__k10 || (this.__k10 = new Center({
                    "child": new Text({
                      "textAlign": "center",
                      "style": {
                        "fontSize": 13,
                        "color": Colors.black87
                      },
                      "data": "整块绿色区域由 SliverFillRemaining 撑满\n改变窗口高度或切「加高头部」看它跟随变化"
                    })
                  }))),
                  new Align({
                    "alignment": "bottomLeft",
                    "child": new OutlinedButton({
                      "onPressed": this.__bindFn(3, [], () => {}),
                      "child": (this.__k11 || (this.__k11 = new Text({
                        "data": "贴底按钮"
                      })))
                    })
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

