// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/orientation_builder_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, FontWeight, LayoutBuilder, MainAxisSize, MediaQuery, Orientation, OrientationBuilder, Padding, Row, SizedBox, Text, TextStyle } from '../flutter.js';

// 组件 OrientationBuilderDetail
export class OrientationBuilderDetail {
  constructor(args) {
    this.props = args || {};
  }
  _tile(label, color) {
    return new Container({
      "width": 52,
      "height": 52,
      "color": color,
      "alignment": Alignment.center,
      "child": new Text({
        "style": (this.__k0 || (this.__k0 = new TextStyle({
          "color": Colors.white,
          "fontSize": 11
        }))),
        "data": label
      })
    });
  }
  _line(s) {
    return new Padding({
      "padding": (this.__k1 || (this.__k1 = EdgeInsets.only({
        "bottom": 2
      }))),
      "child": new Text({
        "style": (this.__k2 || (this.__k2 = new TextStyle({
          "fontSize": 12
        }))),
        "data": s
      })
    });
  }
  build(context) {
    var mq = MediaQuery.of(context);
    var isPortrait = (mq.orientation == Orientation.portrait);
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.start,
      "children": [
        (this.__k3 || (this.__k3 = new Text({
          "data": "OrientationBuilder",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 4
        }))),
        (this.__k5 || (this.__k5 = new Text({
          "data": "拉高窗口（高 > 宽）切到 portrait，压扁切回 landscape",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 10
        }))),
        this._line("orientation：" + (isPortrait ? "portrait" : "landscape")),
        this._line("size：" + mq.size.width.toStringAsFixed(0) + " x " + mq.size.height.toStringAsFixed(0)),
        this._line("devicePixelRatio：" + mq.devicePixelRatio.toStringAsFixed(2)),
        this._line("padding.top：" + mq.padding.top.toStringAsFixed(0)),
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 10
        }))),
        (this.__k7 || (this.__k7 = new Text({
          "data": "② 方向 → 排列",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k8 || (this.__k8 = new SizedBox({
          "height": 6
        }))),
        new Container({
          "padding": (this.__k9 || (this.__k9 = EdgeInsets.all({
            "value": 8
          }))),
          "color": Colors.teal.shade50,
          "child": new OrientationBuilder({
            "builder": (context, o) => { var tiles = [this._tile("A", Colors.teal), this._tile("B", Colors.orange), this._tile("C", Colors.indigo)];
              if ((o == Orientation.portrait)) {
                return new Column({
                  "mainAxisSize": MainAxisSize.min,
                  "children": tiles
                });
              }
              return new Row({
                "mainAxisSize": MainAxisSize.min,
                "children": tiles
              }); }
          })
        }),
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 10
        }))),
        (this.__k10 || (this.__k10 = new Text({
          "data": "③ 方向 → 属性值",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k8 || (this.__k8 = new SizedBox({
          "height": 6
        }))),
        new OrientationBuilder({
          "builder": (context, o) => { if ((o == Orientation.portrait)) {
              return new Container({
                "color": Colors.orange.shade50,
                "padding": (this.__k11 || (this.__k11 = EdgeInsets.all({
                  "value": 16
                }))),
                "child": (this.__k12 || (this.__k12 = new Text({
                  "data": "portrait：内边距 16"
                })))
              });
            }
            return new Container({
              "color": Colors.orange.shade50,
              "padding": (this.__k13 || (this.__k13 = EdgeInsets.all({
                "value": 6
              }))),
              "child": (this.__k14 || (this.__k14 = new Text({
                "data": "landscape：内边距 6"
              })))
            }); }
        }),
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 10
        }))),
        (this.__k15 || (this.__k15 = new Text({
          "data": "④ LayoutBuilder → 父约束",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k8 || (this.__k8 = new SizedBox({
          "height": 6
        }))),
        new LayoutBuilder({
          "builder": (context, c) => {
            var wide = (c.maxWidth > 420);
            var tiles = [this._tile("X", Colors.indigo), this._tile("Y", Colors.pink)];
            return new Container({
              "color": Colors.indigo.shade50,
              "padding": (this.__k9 || (this.__k9 = EdgeInsets.all({
                "value": 8
              }))),
              "child": new Column({
                "crossAxisAlignment": CrossAxisAlignment.start,
                "children": [
                  new Text({
                    "style": (this.__k2 || (this.__k2 = new TextStyle({
                      "fontSize": 12
                    }))),
                    "data": "maxWidth：" + c.maxWidth.toStringAsFixed(0) + "   " + "maxHeight：" + c.maxHeight.toStringAsFixed(0)
                  }),
                  new Text({
                    "style": (this.__k2 || (this.__k2 = new TextStyle({
                      "fontSize": 12
                    }))),
                    "data": "hasBoundedWidth：" + c.hasBoundedWidth + "   " + "hasBoundedHeight：" + c.hasBoundedHeight
                  }),
                  new Text({
                    "style": (this.__k2 || (this.__k2 = new TextStyle({
                      "fontSize": 12
                    }))),
                    "data": "biggest：" + c.biggest.width.toStringAsFixed(0) + " x " + c.biggest.height.toStringAsFixed(0)
                  }),
                  (this.__k8 || (this.__k8 = new SizedBox({
                    "height": 6
                  }))),
                  (wide ? new Row({
                    "mainAxisSize": MainAxisSize.min,
                    "children": tiles
                  }) : new Column({
                    "mainAxisSize": MainAxisSize.min,
                    "children": tiles
                  }))
                ]
              })
            });
          }
        })
      ]
    });
  }
}

