// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/value_listenable_builder_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, BorderRadius, BoxDecoration, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, Expanded, FontWeight, MainAxisSize, OutlinedButton, Row, SizedBox, Text, TextStyle, ValueListenableBuilder, ValueNotifier } from '../flutter.js';

// 组件 ValueListenableBuilderDetail
export class ValueListenableBuilderDetail {
  constructor(args) {
    this.props = args || {};
    this._a = new ValueNotifier({_value: 0, typeArguments: ['int']});
    this._b = new ValueNotifier({_value: 100, typeArguments: ['int']});
    this._useA = true;
    this._builds = 0;
  }
  get _active() {
    return (this._useA ? this._a : this._b);
  }
  dispose() {
    this._a.dispose();
    this._b.dispose();
  }
  _inc() {
    var n = this._active;
    n.value = (n.value + 1);
  }
  _dec() {
    var n = this._active;
    n.value = (n.value - 1);
  }
  _same() {
    var n = this._active;
    n.value = n.value;
  }
  _toggle() {
    this.setState(() => { this._useA = (!this._useA); });
  }
  build(context) {
    return new Container({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
        "value": 12
      }))),
      "color": Colors.grey.shade100,
      "child": new Column({
        "mainAxisSize": MainAxisSize.min,
        "crossAxisAlignment": CrossAxisAlignment.stretch,
        "children": [
          new Text({
            "style": (this.__k1 || (this.__k1 = new TextStyle({
              "fontSize": 13,
              "fontWeight": FontWeight.bold
            }))),
            "data": this._useA ? "订阅：_a（初值 0）" : "订阅：_b（初值 100）"
          }),
          (this.__k2 || (this.__k2 = new SizedBox({
            "height": 10
          }))),
          new ValueListenableBuilder({
            "valueListenable": this._active,
            "builder": (context, value, child) => { this._builds += 1;
              return new Column({
                "crossAxisAlignment": CrossAxisAlignment.stretch,
                "children": [
                  new Row({
                    "crossAxisAlignment": CrossAxisAlignment.center,
                    "children": [
                      new Container({
                        "width": 64,
                        "height": 44,
                        "alignment": Alignment.center,
                        "decoration": new BoxDecoration({
                          "color": Colors.indigo,
                          "borderRadius": BorderRadius.circular({
                            "radius": 6
                          })
                        }),
                        "child": new Text({
                          "style": (this.__k3 || (this.__k3 = new TextStyle({
                            "color": Colors.white,
                            "fontSize": 18,
                            "fontWeight": FontWeight.bold
                          }))),
                          "data": value
                        })
                      }),
                      (this.__k4 || (this.__k4 = new SizedBox({
                        "width": 12
                      }))),
                      new Expanded({
                        "child": new Text({
                          "style": (this.__k5 || (this.__k5 = new TextStyle({
                            "fontSize": 12
                          }))),
                          "data": "builder 已执行 " + this._builds + " 次"
                        })
                      })
                    ]
                  }),
                  (this.__k6 || (this.__k6 = new SizedBox({
                    "height": 6
                  }))),
                  (child ?? SizedBox.shrink())
                ]
              }); },
            "child": (this.__k7 || (this.__k7 = new Text({
              "data": "child 插槽：值变化时不重建这段子树",
              "style": new TextStyle({
                "fontSize": 12,
                "color": Colors.black54
              })
            }))),
            "model": "int"
          }),
          (this.__k2 || (this.__k2 = new SizedBox({
            "height": 10
          }))),
          new Row({
            "children": [
              new OutlinedButton({
                "onPressed": this.__bindFn(0, [], (...__a) => this._dec(...__a)),
                "child": (this.__k8 || (this.__k8 = new Text({
                  "data": "-1"
                })))
              }),
              (this.__k9 || (this.__k9 = new SizedBox({
                "width": 8
              }))),
              new OutlinedButton({
                "onPressed": this.__bindFn(1, [], (...__a) => this._inc(...__a)),
                "child": (this.__k10 || (this.__k10 = new Text({
                  "data": "+1"
                })))
              }),
              (this.__k9 || (this.__k9 = new SizedBox({
                "width": 8
              }))),
              new OutlinedButton({
                "onPressed": this.__bindFn(2, [], (...__a) => this._same(...__a)),
                "child": (this.__k11 || (this.__k11 = new Text({
                  "data": "赋相同值"
                })))
              })
            ]
          }),
          (this.__k12 || (this.__k12 = new SizedBox({
            "height": 4
          }))),
          new Row({
            "children": [
              new OutlinedButton({
                "onPressed": this.__bindFn(3, [], (...__a) => this._toggle(...__a)),
                "child": (this.__k13 || (this.__k13 = new Text({
                  "data": "切换订阅对象"
                })))
              })
            ]
          })
        ]
      })
    });
  }
}

