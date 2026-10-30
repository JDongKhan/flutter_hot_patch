// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/layout_more_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, BorderRadius, BoxDecoration, BoxFit, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, Expanded, FilledButton, FittedBox, FontWeight, IgnorePointer, InteractiveViewer, IntrinsicHeight, Positioned, Radius, RepaintBoundary, RotatedBox, Row, SizedBox, Stack, Text, TextBaseline, TextStyle, Tooltip } from '../flutter.js';

// 组件 LayoutMoreDetail
export class LayoutMoreDetail {
  constructor(args) {
    this.props = args || {};
    this._scale = 1;
    this._lastTap = "（没点过）";
  }
  _tap(who) {
    this.setState(() => { this._lastTap = who; });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.start,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "布局 / 交互补充",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Tooltip({
          "message": "这是 Tooltip 的提示文字",
          "child": new Container({
            "padding": (this.__k2 || (this.__k2 = EdgeInsets.symmetric({
              "horizontal": 12,
              "vertical": 8
            }))),
            "decoration": new BoxDecoration({
              "color": Colors.blue.shade100,
              "borderRadius": (this.__k3 || (this.__k3 = BorderRadius.all({
                "radius": Radius.circular({
                  "radius": 6
                })
              })))
            }),
            "child": (this.__k4 || (this.__k4 = new Text({
              "data": "长按 / 悬停看提示"
            })))
          })
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        (this.__k6 || (this.__k6 = new Text({
          "data": "FittedBox（100x40 内放整行文字）",
          "style": new TextStyle({
            "fontSize": 12
          })
        }))),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 4
        }))),
        new SizedBox({
          "width": 100,
          "height": 40,
          "child": new FittedBox({
            "fit": BoxFit.contain,
            "child": new Text({
              "style": new TextStyle({
                "fontSize": 24,
                "color": Colors.deepPurple.shade300
              }),
              "data": "ABCDEFGHIJKLMN"
            })
          })
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        new Row({
          "children": [
            new RotatedBox({
              "quarterTurns": 1,
              "child": new Container({
                "width": 60,
                "height": 24,
                "color": Colors.orange.shade200,
                "alignment": Alignment.center,
                "child": (this.__k8 || (this.__k8 = new Text({
                  "data": "旋转 90°",
                  "style": new TextStyle({
                    "fontSize": 11
                  })
                })))
              })
            }),
            (this.__k9 || (this.__k9 = new SizedBox({
              "width": 12
            }))),
            (this.__k10 || (this.__k10 = new Text({
              "data": "RotatedBox 参与布局",
              "style": new TextStyle({
                "fontSize": 12
              })
            })))
          ]
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        new IntrinsicHeight({
          "child": new Row({
            "crossAxisAlignment": CrossAxisAlignment.stretch,
            "children": [
              new Expanded({
                "child": new Container({
                  "padding": (this.__k11 || (this.__k11 = EdgeInsets.all({
                    "value": 8
                  }))),
                  "color": Colors.green.shade50,
                  "child": (this.__k12 || (this.__k12 = new Text({
                    "data": "短文本"
                  })))
                })
              }),
              (this.__k13 || (this.__k13 = new SizedBox({
                "width": 8
              }))),
              new Expanded({
                "child": new Container({
                  "padding": (this.__k11 || (this.__k11 = EdgeInsets.all({
                    "value": 8
                  }))),
                  "color": Colors.green.shade100,
                  "child": (this.__k14 || (this.__k14 = new Text({
                    "data": "长文本\n两行\n三行"
                  })))
                })
              })
            ]
          })
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        new Row({
          "crossAxisAlignment": CrossAxisAlignment.baseline,
          "textBaseline": TextBaseline.alphabetic,
          "children": [
            (this.__k15 || (this.__k15 = new Text({
              "data": "大字",
              "style": new TextStyle({
                "fontSize": 26
              })
            }))),
            (this.__k13 || (this.__k13 = new SizedBox({
              "width": 8
            }))),
            (this.__k16 || (this.__k16 = new Text({
              "data": "小字",
              "style": new TextStyle({
                "fontSize": 12
              })
            })))
          ]
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        new Stack({
          "children": [
            new FilledButton({
              "onPressed": this.__bindFn(0, [], () => this._tap("可点按钮")),
              "child": (this.__k17 || (this.__k17 = new Text({
                "data": "可点击"
              })))
            }),
            Positioned.fill({
              "child": new IgnorePointer({
                "child": new Container({
                  "color": Colors.transparent
                })
              })
            })
          ]
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k18 || (this.__k18 = new TextStyle({
            "fontSize": 12
          }))),
          "data": "最近点击：" + this._lastTap
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        new RepaintBoundary({
          "child": new Container({
            "padding": (this.__k11 || (this.__k11 = EdgeInsets.all({
              "value": 8
            }))),
            "color": Colors.grey.shade100,
            "child": new Text({
              "style": (this.__k18 || (this.__k18 = new TextStyle({
                "fontSize": 12
              }))),
              "data": "当前缩放：" + this._scale
            })
          })
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new SizedBox({
          "height": 160,
          "child": new InteractiveViewer({
            "minScale": 0.5,
            "maxScale": 3,
            "boundaryMargin": (this.__k19 || (this.__k19 = EdgeInsets.all({
              "value": 20
            }))),
            "onInteractionUpdate": this.__bindFn(1, [], (details) => this.setState(() => {
              this._scale = details.scale;
            })),
            "child": new Container({
              "width": 320,
              "height": 160,
              "alignment": Alignment.center,
              "decoration": new BoxDecoration({
                "color": Colors.indigo.shade50,
                "borderRadius": (this.__k20 || (this.__k20 = BorderRadius.all({
                  "radius": Radius.circular({
                    "radius": 10
                  })
                })))
              }),
              "child": (this.__k21 || (this.__k21 = new Text({
                "data": "缩放 / 拖动我"
              })))
            })
          })
        })
      ]
    });
  }
}

