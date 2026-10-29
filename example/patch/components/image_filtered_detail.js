// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/image_filtered_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, BoxDecoration, Colors, Column, Container, EdgeInsets, Float64List, FontWeight, ImageFilter, ImageFiltered, LinearGradient, Padding, SizedBox, Text, TextStyle } from '../flutter.js';

// 组件 ImageFilteredDetail
export class ImageFilteredDetail {
  static _gradient = new LinearGradient({begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.deepPurple, Colors.pinkAccent, Colors.orangeAccent]});
  constructor(args) {
    this.props = args || {};
  }
  _panel(label) {
    return new Container({
      "width": 210,
      "height": 100,
      "alignment": Alignment.center,
      "decoration": (this.__k0 || (this.__k0 = new BoxDecoration({
        "gradient": ImageFilteredDetail._gradient
      }))),
      "child": new Text({
        "style": (this.__k1 || (this.__k1 = new TextStyle({
          "color": Colors.white,
          "fontSize": 22,
          "fontWeight": FontWeight.bold
        }))),
        "data": label
      })
    });
  }
  _row(title, filtered) {
    return new Padding({
      "padding": (this.__k2 || (this.__k2 = EdgeInsets.only({
        "bottom": 10
      }))),
      "child": new Column({
        "crossAxisAlignment": "start",
        "children": [
          new Text({
            "style": (this.__k3 || (this.__k3 = new TextStyle({
              "color": Colors.black54,
              "fontSize": 12
            }))),
            "data": title
          }),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 4
          }))),
          filtered
        ]
      })
    });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "start",
      "children": [
        (this.__k5 || (this.__k5 = new Text({
          "data": "ImageFiltered",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 4
        }))),
        (this.__k6 || (this.__k6 = new Text({
          "data": "整棵子树作为图片处理：模糊 / 膨胀 / 矩阵 / 组合",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 10
        }))),
        this._row("① 原样", this._panel("A")),
        this._row("② blur(sigmaX: 3, sigmaY: 3)", new ImageFiltered({
          "imageFilter": ImageFilter.blur({
            "sigmaX": 3,
            "sigmaY": 3
          }),
          "child": this._panel("B")
        })),
        this._row("③ dilate(radiusX: 3, radiusY: 3)", new ImageFiltered({
          "imageFilter": ImageFilter.dilate({
            "radiusX": 3,
            "radiusY": 3
          }),
          "child": this._panel("C")
        })),
        this._row("④ compose(outer: blur(2), inner: matrix(旋转 20°))", new ImageFiltered({
          "imageFilter": ImageFilter.compose({
            "outer": ImageFilter.blur({
              "sigmaX": 2,
              "sigmaY": 2
            }),
            "inner": ImageFilter.matrix({
              "matrix4": Float64List.fromList({
                "elements": [
                  0.9397,
                  0.342,
                  0.0,
                  0.0,
                  (-0.342),
                  0.9397,
                  0.0,
                  0.0,
                  0.0,
                  0.0,
                  1.0,
                  0.0,
                  0.0,
                  0.0,
                  0.0,
                  1.0
                ]
              })
            })
          }),
          "child": this._panel("D")
        }))
      ]
    });
  }
}

