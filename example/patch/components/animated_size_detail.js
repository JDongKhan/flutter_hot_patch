// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/animated_size_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { AnimatedSize, Center, Column, Container, Expanded, Row, SizedBox, Text, TextButton } from '../flutter.js';

// 组件 AnimatedSizeDetail
export class AnimatedSizeDetail {
  constructor(args) {
    this.props = args || {};
    this._expanded = false;
    this._slow = false;
  }
  build(context) {
    var duration = new Duration({milliseconds: (this._slow ? 1200 : 300)});
    return new Column({
        "crossAxisAlignment": "stretch",
        "children": [
          (this.__k0 || (this.__k0 = new Text({
              "data": "AnimatedSize · 尺寸自动补间",
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              }
            }))),
          (this.__k1 || (this.__k1 = new SizedBox({
              "height": 12
            }))),
          new Center({
              "child": new Container({
                "padding": {
                  "left": 12.0,
                  "top": 12.0,
                  "right": 12.0,
                  "bottom": 12.0
                },
                "decoration": {
                  "color": Colors.blueGrey.shade50,
                  "borderRadius": {
                    "radius": 16.0
                  },
                  "border": {
                    "all": {
                      "color": Colors.blueGrey.shade200
                    }
                  }
                },
                "child": new AnimatedSize({
                  "duration": duration,
                  "curve": Curves.easeInOut,
                  "alignment": "center",
                  "child": new Container({
                    "width": this._expanded ? 240 : 120,
                    "height": this._expanded ? 120 : 56,
                    "alignment": "center",
                    "decoration": {
                      "color": (this._expanded ? Colors.deepPurple : Colors.teal),
                      "borderRadius": {
                        "radius": 14.0
                      }
                    },
                    "child": new Text({
                      "style": {
                        "color": Colors.white,
                        "fontWeight": "w600"
                      },
                      "data": this._expanded ? "已展开" : "已收起"
                    })
                  })
                })
              })
            }),
          (this.__k1 || (this.__k1 = new SizedBox({
              "height": 12
            }))),
          new Row({
              "children": [
                new Expanded({
                    "child": new TextButton({
                      "onPressed": this.__bindFn(0, [], () => this.setState(() => {
                        this._expanded = (!this._expanded);
                      })),
                      "child": new Text({
                        "data": this._expanded ? "收起尺寸" : "展开尺寸"
                      })
                    })
                  }),
                new Expanded({
                    "child": new TextButton({
                      "onPressed": this.__bindFn(1, [], () => this.setState(() => {
                        this._slow = (!this._slow);
                      })),
                      "child": new Text({
                        "data": this._slow ? "切回 300ms" : "切到 1200ms"
                      })
                    })
                  })
              ]
            }),
          (this.__k2 || (this.__k2 = new SizedBox({
              "height": 4
            }))),
          new Text({
              "textAlign": "center",
              "style": {
                "color": Colors.grey,
                "fontSize": 12
              },
              "data": "当前时长：" + duration.inMilliseconds + "ms"
            })
        ]
      });
  }
}

