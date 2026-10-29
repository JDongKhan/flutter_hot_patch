// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/orientation_builder_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, Column, Container, LayoutBuilder, MediaQuery, Orientation, OrientationBuilder, Padding, Row, SizedBox, Text } from '../flutter.js';

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
      "alignment": "center",
      "child": new Text({
        "style": {
          "fontSize": 11,
          "color": Colors.white
        },
        "data": label
      })
    });
  }
  _line(s) {
    return new Padding({
      "padding": {
        "left": 0.0,
        "top": 0.0,
        "right": 0.0,
        "bottom": 2.0
      },
      "child": new Text({
        "style": {
          "fontSize": 12
        },
        "data": s
      })
    });
  }
  build(context) {
    var mq = MediaQuery.of(context);
    var isPortrait = (mq.orientation == Orientation.portrait);
    return new Column({
      "crossAxisAlignment": "start",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "OrientationBuilder",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "拉高窗口（高 > 宽）切到 portrait，压扁切回 landscape",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 10
        }))),
        this._line("orientation：" + (isPortrait ? "portrait" : "landscape")),
        this._line("size：" + mq.size.width.toStringAsFixed(0) + " x " + mq.size.height.toStringAsFixed(0)),
        this._line("devicePixelRatio：" + mq.devicePixelRatio.toStringAsFixed(2)),
        this._line("padding.top：" + mq.padding.top.toStringAsFixed(0)),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 10
        }))),
        (this.__k4 || (this.__k4 = new Text({
          "data": "② 方向 → 排列",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new Container({
          "padding": {
            "left": 8.0,
            "top": 8.0,
            "right": 8.0,
            "bottom": 8.0
          },
          "color": Colors.teal.shade50,
          "child": new OrientationBuilder({
            "builder": (context, o) => { var tiles = [this._tile("A", Colors.teal), this._tile("B", Colors.orange), this._tile("C", Colors.indigo)];
              if ((o == Orientation.portrait)) {
                return new Column({
                  "mainAxisSize": "min",
                  "children": tiles
                });
              }
              return new Row({
                "mainAxisSize": "min",
                "children": tiles
              }); }
          })
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 10
        }))),
        (this.__k6 || (this.__k6 = new Text({
          "data": "③ 方向 → 属性值",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new OrientationBuilder({
          "builder": (context, o) => { if ((o == Orientation.portrait)) {
              return new Container({
                "color": Colors.orange.shade50,
                "padding": {
                  "left": 16.0,
                  "top": 16.0,
                  "right": 16.0,
                  "bottom": 16.0
                },
                "child": (this.__k7 || (this.__k7 = new Text({
                  "data": "portrait：内边距 16"
                })))
              });
            }
            return new Container({
              "color": Colors.orange.shade50,
              "padding": {
                "left": 6.0,
                "top": 6.0,
                "right": 6.0,
                "bottom": 6.0
              },
              "child": (this.__k8 || (this.__k8 = new Text({
                "data": "landscape：内边距 6"
              })))
            }); }
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 10
        }))),
        (this.__k9 || (this.__k9 = new Text({
          "data": "④ LayoutBuilder → 父约束",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new LayoutBuilder({
          "builder": (context, c) => {
            var wide = (c.maxWidth > 420);
            var tiles = [this._tile("X", Colors.indigo), this._tile("Y", Colors.pink)];
            return new Container({
              "color": Colors.indigo.shade50,
              "padding": {
                "left": 8.0,
                "top": 8.0,
                "right": 8.0,
                "bottom": 8.0
              },
              "child": new Column({
                "crossAxisAlignment": "start",
                "children": [
                  new Text({
                    "style": {
                      "fontSize": 12
                    },
                    "data": "maxWidth：" + c.maxWidth.toStringAsFixed(0) + "   " + "maxHeight：" + c.maxHeight.toStringAsFixed(0)
                  }),
                  new Text({
                    "style": {
                      "fontSize": 12
                    },
                    "data": "hasBoundedWidth：" + c.hasBoundedWidth + "   " + "hasBoundedHeight：" + c.hasBoundedHeight
                  }),
                  new Text({
                    "style": {
                      "fontSize": 12
                    },
                    "data": "biggest：" + c.biggest.width.toStringAsFixed(0) + " x " + c.biggest.height.toStringAsFixed(0)
                  }),
                  (this.__k5 || (this.__k5 = new SizedBox({
                    "height": 6
                  }))),
                  (wide ? new Row({
                    "mainAxisSize": "min",
                    "children": tiles
                  }) : new Column({
                    "mainAxisSize": "min",
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

