// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/container_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, Border, BorderRadius, BorderSide, BoxDecoration, BoxShadow, Card, Clip, Color, Colors, Column, Container, CrossAxisAlignment, DecoratedBox, Divider, EdgeInsets, FontWeight, LinearGradient, Offset, Padding, Radius, RoundedRectangleBorder, SizedBox, Text, TextStyle } from '../flutter.js';

// 组件 ContainerDetail
export class ContainerDetail {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Container · 颜色/圆角/Padding",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new Container({
          "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
            "value": 16
          }))),
          "decoration": (this.__k2 || (this.__k2 = new BoxDecoration({
            "borderRadius": BorderRadius.all({
              "radius": Radius.circular({
                "radius": 12
              })
            }),
            "color": Colors.teal
          }))),
          "child": (this.__k3 || (this.__k3 = new Text({
            "data": "容器内容（teal 圆角）",
            "style": new TextStyle({
              "color": Colors.white
            })
          })))
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k5 || (this.__k5 = new Text({
          "data": "Container · 边框 + 阴影 + 渐变",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new Container({
          "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
            "value": 16
          }))),
          "decoration": new BoxDecoration({
            "gradient": (this.__k6 || (this.__k6 = new LinearGradient({
              "begin": Alignment.topLeft,
              "colors": [
                Colors.blue,
                Colors.purple
              ],
              "end": Alignment.bottomRight
            }))),
            "borderRadius": BorderRadius.circular({
              "radius": 16
            }),
            "border": Border.all({
              "color": Colors.white,
              "width": 2
            }),
            "boxShadow": [
              new BoxShadow({
                "color": new Color({
                  "value": 0x66000000
                }),
                "offset": new Offset({
                  "dx": 0,
                  "dy": 4
                }),
                "blurRadius": 12,
                "spreadRadius": 1
              })
            ]
          }),
          "child": (this.__k7 || (this.__k7 = new Text({
            "data": "渐变 + 边框 + 阴影",
            "style": new TextStyle({
              "color": Colors.white
            })
          })))
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k8 || (this.__k8 = new Text({
          "data": "DecoratedBox · 纯装饰",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new DecoratedBox({
          "decoration": new BoxDecoration({
            "color": Colors.amber.shade100,
            "border": Border.all({
              "color": Colors.amber,
              "width": 2
            }),
            "borderRadius": BorderRadius.circular({
              "radius": 8
            })
          }),
          "child": (this.__k9 || (this.__k9 = new Padding({
            "child": new Text({
              "data": "DecoratedBox 内容"
            }),
            "padding": EdgeInsets.all({
              "value": 12
            })
          })))
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k10 || (this.__k10 = new Text({
          "data": "Card · shape / clipBehavior",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new Card({
          "elevation": 4,
          "shadowColor": Colors.deepPurple,
          "shape": new RoundedRectangleBorder({
            "borderRadius": BorderRadius.circular({
              "radius": 16
            }),
            "side": (this.__k11 || (this.__k11 = new BorderSide({
              "color": Colors.deepPurple,
              "width": 1
            })))
          }),
          "clipBehavior": Clip.antiAlias,
          "child": (this.__k12 || (this.__k12 = new Padding({
            "child": new Text({
              "data": "圆角卡片 + 描边 + 阴影"
            }),
            "padding": EdgeInsets.all({
              "value": 16
            })
          })))
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k13 || (this.__k13 = new Divider({}))),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k14 || (this.__k14 = new Text({
          "data": "SizedBox · 尺寸约束",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new Container({
          "width": 120,
          "height": 48,
          "alignment": Alignment.center,
          "color": Colors.blueGrey.shade100,
          "child": (this.__k15 || (this.__k15 = new Text({
            "data": "固定 120×48"
          })))
        })
      ]
    });
  }
}

