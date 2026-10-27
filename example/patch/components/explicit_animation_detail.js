// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/explicit_animation_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { AnimatedBuilder, Center, Column, Container, Divider, Expanded, FadeTransition, LinearProgressIndicator, RotationTransition, Row, ScaleTransition, SizedBox, Text, TextButton } from '../flutter.js';

// 组件 ExplicitAnimationDetail
export class ExplicitAnimationDetail {
  constructor(args) {
    this.props = args || {};
    this._controller = new AnimationController({vsync: this, duration: new Duration({milliseconds: 900})});
  }
  dispose() {
    this._controller.dispose();
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "AnimationController.value 驱动 AnimatedBuilder",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 10
        }))),
        new AnimatedBuilder({
          "animation": this._controller,
          "builder": "_builder0"
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 10
        }))),
        new Row({
          "children": [
            new Expanded({
              "child": new TextButton({
                "onPressed": this.__bindFn(0, [], () => this._controller.forward()),
                "child": (this.__k2 || (this.__k2 = new Text({
                  "data": "forward"
                })))
              })
            }),
            new Expanded({
              "child": new TextButton({
                "onPressed": this.__bindFn(1, [], () => this._controller.reverse()),
                "child": (this.__k3 || (this.__k3 = new Text({
                  "data": "reverse"
                })))
              })
            }),
            new Expanded({
              "child": new TextButton({
                "onPressed": this.__bindFn(2, [], () => this._controller.repeat(true)),
                "child": (this.__k4 || (this.__k4 = new Text({
                  "data": "repeat"
                })))
              })
            }),
            new Expanded({
              "child": new TextButton({
                "onPressed": this.__bindFn(3, [], () => this._controller.stop()),
                "child": (this.__k5 || (this.__k5 = new Text({
                  "data": "stop"
                })))
              })
            }),
            new Expanded({
              "child": new TextButton({
                "onPressed": this.__bindFn(4, [], () => this._controller.reset()),
                "child": (this.__k6 || (this.__k6 = new Text({
                  "data": "reset"
                })))
              })
            })
          ]
        }),
        (this.__k7 || (this.__k7 = new Divider({}))),
        (this.__k8 || (this.__k8 = new Text({
          "data": "*Transition · 由 CurvedAnimation 驱动",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 10
        }))),
        new SizedBox({
          "height": 90,
          "child": new FadeTransition({
            "opacity": new CurvedAnimation({
              "parent": this._controller,
              "curve": Curves.easeOut
            }),
            "child": new ScaleTransition({
              "scale": new CurvedAnimation({
                "parent": this._controller,
                "curve": Curves.easeOut
              }),
              "child": new Center({
                "child": new Container({
                  "width": 120,
                  "height": 60,
                  "alignment": "center",
                  "decoration": {
                    "color": Colors.orange,
                    "borderRadius": {
                      "radius": 12.0
                    }
                  },
                  "child": (this.__k9 || (this.__k9 = new Text({
                    "data": "Fade + Scale",
                    "style": {
                      "color": Colors.white
                    }
                  })))
                })
              })
            })
          })
        }),
        (this.__k10 || (this.__k10 = new SizedBox({
          "height": 6
        }))),
        new SizedBox({
          "height": 90,
          "child": new RotationTransition({
            "turns": new CurvedAnimation({
              "parent": this._controller,
              "curve": Curves.easeInOut
            }),
            "child": new Center({
              "child": new Container({
                "width": 130,
                "height": 60,
                "alignment": "center",
                "decoration": {
                  "color": Colors.indigo,
                  "borderRadius": {
                    "radius": 12.0
                  }
                },
                "child": (this.__k11 || (this.__k11 = new Text({
                  "data": "Rotation",
                  "style": {
                    "color": Colors.white
                  }
                })))
              })
            })
          })
        })
      ]
    });
  }
  _builder0(context, child) {
    return new Column({
      "children": [
        new Container({
          "height": 120,
          "alignment": "center",
          "decoration": {
            "color": ((this._controller.value < 0.5) ? Colors.teal : Colors.deepPurple),
            "borderRadius": {
              "radius": 16.0
            }
          },
          "child": new Text({
            "style": {
              "color": Colors.white,
              "fontSize": 20,
              "fontWeight": "w700"
            },
            "data": (this._controller.value < 0.5) ? "前半程" : "后半程"
          })
        }),
        new LinearProgressIndicator({
          "value": this._controller.value
        })
      ]
    });
  }
}

