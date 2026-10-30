// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/layout_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Align, Alignment, AspectRatio, Axis, BoxConstraints, Center, Chip, Clip, Colors, Column, ConstrainedBox, Container, CrossAxisAlignment, EdgeInsets, Expanded, FontWeight, FractionallySizedBox, Opacity, Padding, Positioned, Row, SizedBox, Spacer, Stack, StackFit, Text, TextAlign, TextStyle, Wrap, WrapAlignment, WrapCrossAlignment } from '../flutter.js';

// 组件 LayoutDetail
export class LayoutDetail {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Row + Expanded / Flexible / Spacer",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new Row({
          "children": [
            new Expanded({
              "flex": 1,
              "child": new Container({
                "color": Colors.blue.shade100,
                "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
                  "value": 8
                }))),
                "child": (this.__k2 || (this.__k2 = new Text({
                  "data": "A",
                  "textAlign": TextAlign.center
                })))
              })
            }),
            (this.__k3 || (this.__k3 = new Spacer({
              "flex": 1
            }))),
            new Expanded({
              "flex": 2,
              "child": new Container({
                "color": Colors.green.shade100,
                "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
                  "value": 8
                }))),
                "child": (this.__k4 || (this.__k4 = new Text({
                  "data": "B（flex=2）",
                  "textAlign": TextAlign.center
                })))
              })
            })
          ]
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        (this.__k6 || (this.__k6 = new Text({
          "data": "Center / Align / Padding / SizedBox",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new Center({
          "child": new Container({
            "color": Colors.amber.shade100,
            "padding": (this.__k7 || (this.__k7 = EdgeInsets.all({
              "value": 12
            }))),
            "child": (this.__k8 || (this.__k8 = new Text({
              "data": "Center 居中"
            })))
          })
        }),
        (this.__k9 || (this.__k9 = new SizedBox({
          "height": 8
        }))),
        new Align({
          "alignment": Alignment.centerLeft,
          "child": new Container({
            "color": Colors.purple.shade50,
            "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
              "value": 8
            }))),
            "child": (this.__k10 || (this.__k10 = new Text({
              "data": "Align centerLeft"
            })))
          })
        }),
        (this.__k9 || (this.__k9 = new SizedBox({
          "height": 8
        }))),
        new Padding({
          "padding": (this.__k11 || (this.__k11 = EdgeInsets.symmetric({
            "horizontal": 8,
            "vertical": 4
          }))),
          "child": (this.__k12 || (this.__k12 = new Text({
            "data": "Padding 包裹文案"
          })))
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        (this.__k13 || (this.__k13 = new Text({
          "data": "Stack + Positioned",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new SizedBox({
          "height": 100,
          "child": new Stack({
            "fit": StackFit.expand,
            "clipBehavior": Clip.hardEdge,
            "children": [
              new Container({
                "color": Colors.grey.shade200
              }),
              Positioned.fill({
                "child": new Center({
                  "child": new Text({
                    "style": new TextStyle({
                      "color": Colors.white,
                      "fontWeight": FontWeight.bold
                    }),
                    "data": "FILL"
                  })
                })
              }),
              (this.__k14 || (this.__k14 = new Positioned({
                "child": new Text({
                  "data": "TL"
                }),
                "left": 12,
                "top": 12
              }))),
              (this.__k15 || (this.__k15 = new Positioned({
                "bottom": 12,
                "child": new Text({
                  "data": "BR"
                }),
                "right": 12
              })))
            ]
          })
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        (this.__k16 || (this.__k16 = new Text({
          "data": "Wrap · 自动换行",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new Wrap({
          "direction": Axis.horizontal,
          "spacing": 8,
          "runSpacing": 8,
          "alignment": WrapAlignment.start,
          "runAlignment": WrapAlignment.center,
          "crossAxisAlignment": WrapCrossAlignment.center,
          "children": [
            ...(() => { var out = []; for (let i = 1; (i <= 5); (i++)) { out.push.apply(out, [new Chip({
                    "label": new Text({
                      "data": "chip " + i
                    }),
                    "backgroundColor": Colors.teal.shade50
                  })]); } return out; })()
          ]
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        (this.__k17 || (this.__k17 = new Text({
          "data": "Opacity / ConstrainedBox / AspectRatio / FractionallySizedBox",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new Opacity({
          "opacity": 0.5,
          "child": new Container({
            "color": Colors.red,
            "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
              "value": 8
            }))),
            "child": (this.__k18 || (this.__k18 = new Text({
              "data": "50% 透明"
            })))
          })
        }),
        (this.__k9 || (this.__k9 = new SizedBox({
          "height": 8
        }))),
        new ConstrainedBox({
          "constraints": (this.__k19 || (this.__k19 = new BoxConstraints({
            "maxWidth": 200,
            "minWidth": 120
          }))),
          "child": new Container({
            "color": Colors.orange.shade100,
            "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
              "value": 8
            }))),
            "child": (this.__k20 || (this.__k20 = new Text({
              "data": "ConstrainedBox 宽度 120-200"
            })))
          })
        }),
        (this.__k9 || (this.__k9 = new SizedBox({
          "height": 8
        }))),
        new AspectRatio({
          "aspectRatio": 1.78,
          "child": new Container({
            "color": Colors.indigo.shade100,
            "alignment": Alignment.center,
            "child": (this.__k21 || (this.__k21 = new Text({
              "data": "16:9 比例"
            })))
          })
        }),
        (this.__k9 || (this.__k9 = new SizedBox({
          "height": 8
        }))),
        new FractionallySizedBox({
          "widthFactor": 0.6,
          "alignment": Alignment.center,
          "child": new Container({
            "color": Colors.pink.shade100,
            "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
              "value": 8
            }))),
            "child": (this.__k22 || (this.__k22 = new Text({
              "data": "60% 宽度",
              "textAlign": TextAlign.center
            })))
          })
        })
      ]
    });
  }
}

