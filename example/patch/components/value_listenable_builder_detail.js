// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/value_listenable_builder_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, Column, Container, Expanded, OutlinedButton, Row, SizedBox, Text, ValueListenableBuilder, ValueNotifier } from '../flutter.js';

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
      "padding": {
        "left": 12.0,
        "top": 12.0,
        "right": 12.0,
        "bottom": 12.0
      },
      "color": Colors.grey.shade100,
      "child": new Column({
        "mainAxisSize": "min",
        "crossAxisAlignment": "stretch",
        "children": [
          new Text({
            "style": {
              "fontSize": 13,
              "fontWeight": "bold"
            },
            "data": this._useA ? "订阅：_a（初值 0）" : "订阅：_b（初值 100）"
          }),
          (this.__k0 || (this.__k0 = new SizedBox({
            "height": 10
          }))),
          new ValueListenableBuilder({
            "valueListenable": this._active,
            "builder": (context, value, child) => { this._builds += 1;
              return new Column({
                "crossAxisAlignment": "stretch",
                "children": [
                  new Row({
                    "crossAxisAlignment": "center",
                    "children": [
                      new Container({
                        "width": 64,
                        "height": 44,
                        "alignment": "center",
                        "decoration": {
                          "color": Colors.indigo,
                          "borderRadius": {
                            "radius": 6.0
                          }
                        },
                        "child": new Text({
                          "style": {
                            "color": Colors.white,
                            "fontSize": 18,
                            "fontWeight": "bold"
                          },
                          "data": value
                        })
                      }),
                      (this.__k1 || (this.__k1 = new SizedBox({
                        "width": 12
                      }))),
                      new Expanded({
                        "child": new Text({
                          "style": {
                            "fontSize": 12
                          },
                          "data": "builder 已执行 " + this._builds + " 次"
                        })
                      })
                    ]
                  }),
                  (this.__k2 || (this.__k2 = new SizedBox({
                    "height": 6
                  }))),
                  (child ?? SizedBox.shrink())
                ]
              }); },
            "child": (this.__k3 || (this.__k3 = new Text({
              "data": "child 插槽：值变化时不重建这段子树",
              "style": {
                "color": Colors.black54,
                "fontSize": 12
              }
            }))),
            "model": "int"
          }),
          (this.__k0 || (this.__k0 = new SizedBox({
            "height": 10
          }))),
          new Row({
            "children": [
              new OutlinedButton({
                "onPressed": this.__bindFn(0, [], (...__a) => this._dec(...__a)),
                "child": (this.__k4 || (this.__k4 = new Text({
                  "data": "-1"
                })))
              }),
              (this.__k5 || (this.__k5 = new SizedBox({
                "width": 8
              }))),
              new OutlinedButton({
                "onPressed": this.__bindFn(1, [], (...__a) => this._inc(...__a)),
                "child": (this.__k6 || (this.__k6 = new Text({
                  "data": "+1"
                })))
              }),
              (this.__k5 || (this.__k5 = new SizedBox({
                "width": 8
              }))),
              new OutlinedButton({
                "onPressed": this.__bindFn(2, [], (...__a) => this._same(...__a)),
                "child": (this.__k7 || (this.__k7 = new Text({
                  "data": "赋相同值"
                })))
              })
            ]
          }),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 4
          }))),
          new Row({
            "children": [
              new OutlinedButton({
                "onPressed": this.__bindFn(3, [], (...__a) => this._toggle(...__a)),
                "child": (this.__k9 || (this.__k9 = new Text({
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

