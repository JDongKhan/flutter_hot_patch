// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/overlay_portal_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { GuideBubbleWidget } from '../hot_module_base.js';
import { Align, Alignment, Chip, Color, Column, CrossAxisAlignment, Duration, FilledButton, FontWeight, OutlinedButton, Row, SingleChildScrollView, SizedBox, Text, TextStyle, ValueKey, Wrap } from '../flutter.js';

// 组件 OverlayPortalDetail
export class OverlayPortalDetail {
  constructor(args) {
    this.props = args || {};
    this._alignment = "right";
    this._round = 0;
  }
  _replay() {
    this.setState(() => { this._round += 1; });
  }
  _switchAlignment(value) {
    this.setState(() => { this._alignment = value; this._round += 1; });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.start,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "OverlayPortal / CompositedTransform",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k2 || (this.__k2 = new TextStyle({
            "fontSize": 12
          }))),
          "data": "对齐方式：" + this._alignment
        }),
        new Row({
          "children": [
            new FilledButton({
              "onPressed": this.__bindFn(0, [], () => this._switchAlignment("left")),
              "child": (this.__k3 || (this.__k3 = new Text({
                "data": "left"
              })))
            }),
            (this.__k4 || (this.__k4 = new SizedBox({
              "width": 8
            }))),
            new FilledButton({
              "onPressed": this.__bindFn(1, [], () => this._switchAlignment("center")),
              "child": (this.__k5 || (this.__k5 = new Text({
                "data": "center"
              })))
            }),
            (this.__k4 || (this.__k4 = new SizedBox({
              "width": 8
            }))),
            new FilledButton({
              "onPressed": this.__bindFn(2, [], () => this._switchAlignment("right")),
              "child": (this.__k6 || (this.__k6 = new Text({
                "data": "right"
              })))
            })
          ]
        }),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 16
        }))),
        new Wrap({
          "spacing": 12,
          "runSpacing": 12,
          "children": [
            new GuideBubbleWidget({
              "text": "点这里开始",
              "alignment": this._alignment,
              "duration": (this.__k8 || (this.__k8 = new Duration({
                "seconds": 3
              }))),
              "child": new OutlinedButton({
                "onPressed": this.__bindFn(3, [], (...__a) => this._replay(...__a)),
                "child": (this.__k9 || (this.__k9 = new Text({
                  "data": "目标 A"
                })))
              }),
              "key": new ValueKey({value: "b1-" + this._round})
            }),
            new GuideBubbleWidget({
              "text": "这是第二个锚点，气泡会自动跟随它",
              "alignment": this._alignment,
              "duration": (this.__k8 || (this.__k8 = new Duration({
                "seconds": 3
              }))),
              "gap": 12,
              "backgroundColor": (this.__k10 || (this.__k10 = new Color({
                "value": 0xE6307AF0
              }))),
              "child": new OutlinedButton({
                "onPressed": this.__bindFn(4, [], (...__a) => this._replay(...__a)),
                "child": (this.__k11 || (this.__k11 = new Text({
                  "data": "目标 B"
                })))
              }),
              "key": new ValueKey({value: "b2-" + this._round})
            })
          ]
        }),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 16
        }))),
        new SizedBox({
          "height": 180,
          "child": new SingleChildScrollView({
            "child": new Column({
              "children": [
                (this.__k12 || (this.__k12 = new SizedBox({
                  "height": 60
                }))),
                new Align({
                  "alignment": Alignment.centerLeft,
                  "child": new GuideBubbleWidget({
                    "text": "我在滚动区里，滚一下看我跟着走",
                    "alignment": this._alignment,
                    "duration": (this.__k8 || (this.__k8 = new Duration({
                      "seconds": 3
                    }))),
                    "child": (this.__k13 || (this.__k13 = new Chip({
                      "label": new Text({
                        "data": "滚动里的锚点"
                      })
                    }))),
                    "key": new ValueKey({value: "b3-" + this._round})
                  })
                }),
                (this.__k14 || (this.__k14 = new SizedBox({
                  "height": 300
                })))
              ]
            })
          })
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k2 || (this.__k2 = new TextStyle({
            "fontSize": 12
          }))),
          "data": "第 " + this._round + " 次播放"
        })
      ]
    });
  }
}

