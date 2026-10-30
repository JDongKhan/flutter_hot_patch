// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/tween_animation_builder_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, BorderRadius, ClipRRect, Colors, Column, Container, CrossAxisAlignment, Curves, Duration, EdgeInsets, FontWeight, FractionallySizedBox, MainAxisSize, OutlinedButton, Row, SizedBox, Text, TextStyle, Tween, TweenAnimationBuilder } from '../flutter.js';

// 组件 TweenAnimationBuilderDetail
export class TweenAnimationBuilderDetail {
  constructor(args) {
    this.props = args || {};
    this._target = 1;
    this._ms = 800;
    this._ease = true;
    this._ended = 0;
  }
  _onEnd() {
    this.setState(() => { this._ended += 1; });
  }
  build(context) {
    return new Column({
      "mainAxisSize": MainAxisSize.min,
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        new Container({
          "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
            "value": 12
          }))),
          "color": Colors.grey.shade100,
          "child": new Column({
            "crossAxisAlignment": CrossAxisAlignment.stretch,
            "children": [
              (this.__k1 || (this.__k1 = new Text({
                "data": "Tween<double>(begin: 0, end: _target) → 进度条",
                "style": new TextStyle({
                  "fontSize": 13,
                  "fontWeight": FontWeight.bold
                })
              }))),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 10
              }))),
              new TweenAnimationBuilder({
                "tween": new Tween({
                  "begin": 0.0,
                  "end": this._target
                }),
                "duration": new Duration({
                  "milliseconds": this._ms
                }),
                "curve": this._ease ? Curves.easeInOut : Curves.linear,
                "onEnd": (...__a) => this._onEnd(...__a),
                "builder": (context, value, child) => {
                  return new Column({
                    "crossAxisAlignment": CrossAxisAlignment.stretch,
                    "children": [
                      new ClipRRect({
                        "borderRadius": BorderRadius.circular({
                          "radius": 6
                        }),
                        "child": new Container({
                          "height": 22,
                          "color": Colors.grey.shade300,
                          "alignment": Alignment.centerLeft,
                          "child": new FractionallySizedBox({
                            "widthFactor": value,
                            "heightFactor": 1,
                            "child": new Container({
                              "color": Colors.indigo
                            })
                          })
                        })
                      }),
                      (this.__k3 || (this.__k3 = new SizedBox({
                        "height": 6
                      }))),
                      new Text({
                        "style": (this.__k4 || (this.__k4 = new TextStyle({
                          "color": Colors.black54,
                          "fontSize": 12
                        }))),
                        "data": "value = " + value.toStringAsFixed(3) + "   ·   onEnd 触发 " + this._ended + " 次"
                      })
                    ]
                  });
                },
                "model": "double"
              }),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 10
              }))),
              new Row({
                "children": [
                  new OutlinedButton({
                    "onPressed": this.__bindFn(0, [], () => this.setState(() => {
                      this._target = 0;
                    })),
                    "child": (this.__k5 || (this.__k5 = new Text({
                      "data": "→ 0"
                    })))
                  }),
                  (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 8
                  }))),
                  new OutlinedButton({
                    "onPressed": this.__bindFn(1, [], () => this.setState(() => {
                      this._target = 0.4;
                    })),
                    "child": (this.__k7 || (this.__k7 = new Text({
                      "data": "→ 0.4"
                    })))
                  }),
                  (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 8
                  }))),
                  new OutlinedButton({
                    "onPressed": this.__bindFn(2, [], () => this.setState(() => {
                      this._target = 1;
                    })),
                    "child": (this.__k8 || (this.__k8 = new Text({
                      "data": "→ 1"
                    })))
                  })
                ]
              }),
              (this.__k9 || (this.__k9 = new SizedBox({
                "height": 4
              }))),
              new Row({
                "children": [
                  new OutlinedButton({
                    "onPressed": this.__bindFn(3, [], () => this.setState(() => {
                      this._ms = 300;
                    })),
                    "child": (this.__k10 || (this.__k10 = new Text({
                      "data": "300ms"
                    })))
                  }),
                  (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 8
                  }))),
                  new OutlinedButton({
                    "onPressed": this.__bindFn(4, [], () => this.setState(() => {
                      this._ms = 1500;
                    })),
                    "child": (this.__k11 || (this.__k11 = new Text({
                      "data": "1500ms"
                    })))
                  }),
                  (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 8
                  }))),
                  new OutlinedButton({
                    "onPressed": this.__bindFn(5, [], () => this.setState(() => {
                      this._ease = (!this._ease);
                    })),
                    "child": new Text({
                      "data": this._ease ? "曲线：easeInOut" : "曲线：linear"
                    })
                  })
                ]
              })
            ]
          })
        })
      ]
    });
  }
}

