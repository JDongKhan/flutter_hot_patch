// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/overlay_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { BorderRadius, BoxDecoration, Builder, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, FontWeight, MainAxisAlignment, OutlinedButton, Overlay, OverlayEntry, Padding, Positioned, Radius, Row, SizedBox, Text, TextStyle } from '../flutter.js';

// 组件 OverlayDetail
export class OverlayDetail {
  constructor(args) {
    this.props = args || {};
    this._count = 0;
    this._log = "（暂无操作）";
    this._entries = [];
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Overlay",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "灰底区域就是 Overlay：第 1 条由 initialEntries 声明，" + "按钮通过 Overlay.of(context).insert / entry.remove 增删浮层",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new SizedBox({
          "height": 260,
          "child": new Overlay({
            "initialEntries": [
              new OverlayEntry({
                "builder": (context) => new Container({
                  "color": Colors.grey.shade100,
                  "child": new Builder({
                    "builder": (context) => new Column({
                      "children": [
                        (this.__k4 || (this.__k4 = new Padding({
                          "child": new Text({
                            "style": new TextStyle({
                              "fontSize": 12
                            }),
                            "data": "第 1 条：initialEntries（声明式，铺满整个 Overlay）"
                          }),
                          "padding": EdgeInsets.all({
                            "value": 10
                          })
                        }))),
                        new Row({
                          "mainAxisAlignment": MainAxisAlignment.center,
                          "children": [
                            new OutlinedButton({
                              "onPressed": this.__bindFn(0, [], () => { this.setState(() => { this._count = (this._count + 1); });
                                var entry = new OverlayEntry({
                                  "builder": (context) => new Positioned({
                                    "left": 12,
                                    "right": 12,
                                    "bottom": 12,
                                    "child": new Container({
                                      "padding": (this.__k5 || (this.__k5 = EdgeInsets.all({
                                        "value": 10
                                      }))),
                                      "decoration": new BoxDecoration({
                                        "color": Colors.black87,
                                        "borderRadius": BorderRadius.all({
                                          "radius": Radius.circular({
                                            "radius": 8
                                          })
                                        })
                                      }),
                                      "child": new Text({
                                        "style": (this.__k6 || (this.__k6 = new TextStyle({
                                          "color": Colors.white,
                                          "fontSize": 12
                                        }))),
                                        "data": "浮层 #" + this._count + "：叠在内容之上的 OverlayEntry"
                                      })
                                    })
                                  })
                                });
                                this._entries.add(entry);
                                Overlay.of(this.context).insert(entry);
                                this.setState(() => { this._log = "插入第 " + this._count + " 条浮层"; }); }),
                              "child": (this.__k7 || (this.__k7 = new Text({
                                "data": "插入浮层"
                              })))
                            }),
                            (this.__k8 || (this.__k8 = new SizedBox({
                              "width": 8
                            }))),
                            new OutlinedButton({
                              "onPressed": this.__bindFn(1, [], () => { var entry = (this._entries.isNotEmpty ? this._entries.removeLast() : null);
                                if ((entry != null)) {
                                  entry.remove();
                                }
                                this.setState(() => { this._log = "移除浮层（剩余 " + this._entries.length + " 层）"; }); }),
                              "child": (this.__k9 || (this.__k9 = new Text({
                                "data": "移除浮层"
                              })))
                            })
                          ]
                        })
                      ]
                    })
                  })
                })
              })
            ]
          })
        }),
        (this.__k10 || (this.__k10 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k11 || (this.__k11 = new TextStyle({
            "color": Colors.black54,
            "fontSize": 12
          }))),
          "data": "操作日志：" + this._log
        })
      ]
    });
  }
}

