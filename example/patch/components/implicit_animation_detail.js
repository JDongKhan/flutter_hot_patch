// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/implicit_animation_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { AnimatedContainer, AnimatedCrossFade, AnimatedOpacity, AnimatedRotation, AnimatedScale, AnimatedSlide, Center, Column, Container, Divider, Expanded, Row, SizedBox, Text, TextButton } from '../flutter.js';

// 组件 ImplicitAnimationDetail
export class ImplicitAnimationDetail {
  constructor(args) {
    this.props = args || {};
    this._big = false;
    this._visible = true;
    this._moved = false;
  }
  build(context) {
    return new Column({
        "crossAxisAlignment": "stretch",
        "children": [
          (this.__k0 || (this.__k0 = new Text({
              "data": "AnimatedContainer · 尺寸 / 颜色 / 圆角",
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              }
            }))),
          (this.__k1 || (this.__k1 = new SizedBox({
              "height": 10
            }))),
          new Center({
              "child": new AnimatedContainer({
                  "duration": new Duration({milliseconds: 500}),
                  "curve": "easeInOut",
                  "width": this._big ? 220 : 110,
                  "height": this._big ? 120 : 56,
                  "alignment": "center",
                  "decoration": {
                    "color": (this._big ? '#673AB7' : '#009688'),
                    "borderRadius": {
                      "radius": 20.0
                    }
                  },
                  "child": new Text({
                      "style": {
                        "color": '#FFFFFF',
                        "fontWeight": "w700"
                      },
                      "data": this._big ? "BIG" : "small"
                    })
                })
            }),
          (this.__k1 || (this.__k1 = new SizedBox({
              "height": 10
            }))),
          new TextButton({
              "onPressed": this.__bindFn(0, [], () => this.setState(() => { this._big = (!this._big); })),
              "child": new Text({
                  "data": this._big ? "收缩到 small" : "放大到 BIG"
                })
            }),
          (this.__k2 || (this.__k2 = new Divider({}))),
          (this.__k3 || (this.__k3 = new Text({
              "data": "AnimatedOpacity · AnimatedScale · AnimatedRotation · AnimatedSlide",
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              }
            }))),
          (this.__k1 || (this.__k1 = new SizedBox({
              "height": 10
            }))),
          new Row({
              "mainAxisAlignment": "spaceAround",
              "children": [
                new AnimatedOpacity({
                    "opacity": this._visible ? 1.0 : 0.2,
                    "duration": new Duration({milliseconds: 400}),
                    "curve": "easeOut",
                    "child": new Container({
                        "width": 56,
                        "height": 56,
                        "alignment": "center",
                        "decoration": {
                          "color": '#FF9800',
                          "borderRadius": {
                            "radius": 12.0
                          }
                        },
                        "child": (this.__k4 || (this.__k4 = new Text({
                            "data": "透明度",
                            "style": {
                              "color": '#FFFFFF',
                              "fontSize": 11
                            }
                          })))
                      })
                  }),
                new AnimatedScale({
                    "scale": this._big ? 1.3 : 1.0,
                    "duration": new Duration({milliseconds: 400}),
                    "curve": "easeInOut",
                    "child": new Container({
                        "width": 56,
                        "height": 56,
                        "alignment": "center",
                        "decoration": {
                          "color": '#3F51B5',
                          "borderRadius": {
                            "radius": 12.0
                          }
                        },
                        "child": (this.__k5 || (this.__k5 = new Text({
                            "data": "缩放",
                            "style": {
                              "color": '#FFFFFF',
                              "fontSize": 11
                            }
                          })))
                      })
                  }),
                new AnimatedRotation({
                    "turns": this._moved ? 0.25 : 0.0,
                    "duration": new Duration({milliseconds: 400}),
                    "curve": "easeInOut",
                    "child": new Container({
                        "width": 56,
                        "height": 56,
                        "alignment": "center",
                        "decoration": {
                          "color": '#E91E63',
                          "borderRadius": {
                            "radius": 12.0
                          }
                        },
                        "child": (this.__k6 || (this.__k6 = new Text({
                            "data": "旋转",
                            "style": {
                              "color": '#FFFFFF',
                              "fontSize": 11
                            }
                          })))
                      })
                  }),
                new AnimatedSlide({
                    "offset": this._moved ? new Offset(0.25, 0) : new Offset(0, 0),
                    "duration": new Duration({milliseconds: 400}),
                    "curve": "easeInOut",
                    "child": new Container({
                        "width": 56,
                        "height": 56,
                        "alignment": "center",
                        "decoration": {
                          "color": '#795548',
                          "borderRadius": {
                            "radius": 12.0
                          }
                        },
                        "child": (this.__k7 || (this.__k7 = new Text({
                            "data": "位移",
                            "style": {
                              "color": '#FFFFFF',
                              "fontSize": 11
                            }
                          })))
                      })
                  })
              ]
            }),
          (this.__k1 || (this.__k1 = new SizedBox({
              "height": 10
            }))),
          new Row({
              "children": [
                new Expanded({
                    "child": new TextButton({
                        "onPressed": this.__bindFn(1, [], () => this.setState(() => { this._visible = (!this._visible); })),
                        "child": new Text({
                            "data": this._visible ? "暗下来" : "亮起来"
                          })
                      })
                  }),
                new Expanded({
                    "child": new TextButton({
                        "onPressed": this.__bindFn(2, [], () => this.setState(() => { this._moved = (!this._moved); })),
                        "child": new Text({
                            "data": this._moved ? "回到原位" : "旋转 + 位移"
                          })
                      })
                  })
              ]
            }),
          (this.__k2 || (this.__k2 = new Divider({}))),
          (this.__k8 || (this.__k8 = new Text({
              "data": "AnimatedCrossFade · 两子树交叉淡入淡出",
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              }
            }))),
          (this.__k1 || (this.__k1 = new SizedBox({
              "height": 10
            }))),
          new AnimatedCrossFade({
              "duration": new Duration({milliseconds: 450}),
              "crossFadeState": this._visible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              "firstCurve": "easeOut",
              "secondCurve": "easeIn",
              "alignment": "center",
              "firstChild": new Container({
                  "width": 80,
                  "height": 80,
                  "alignment": "center",
                  "decoration": {
                    "color": '#4CAF50',
                    "borderRadius": {
                      "radius": 12.0
                    }
                  },
                  "child": (this.__k9 || (this.__k9 = new Text({
                      "data": "A",
                      "style": {
                        "color": '#FFFFFF'
                      }
                    })))
                }),
              "secondChild": new Container({
                  "width": 80,
                  "height": 80,
                  "alignment": "center",
                  "decoration": {
                    "color": '#F44336',
                    "borderRadius": {
                      "radius": 12.0
                    }
                  },
                  "child": (this.__k10 || (this.__k10 = new Text({
                      "data": "B",
                      "style": {
                        "color": '#FFFFFF'
                      }
                    })))
                })
            }),
          new TextButton({
              "onPressed": this.__bindFn(3, [], () => this.setState(() => { this._visible = (!this._visible); })),
              "child": new Text({
                  "data": this._visible ? "切到 B" : "切回 A"
                })
            })
        ]
      });
  }
}

