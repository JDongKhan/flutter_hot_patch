// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/image_filtered_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, Container, ImageFiltered, Padding, SizedBox, Text } from '../flutter.js';

const _gradient = new LinearGradient({begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.deepPurple, Colors.pinkAccent, Colors.orangeAccent]});

// 组件 ImageFilteredDetail
export class ImageFilteredDetail {
  constructor(args) {
    this.props = args || {};
  }
  _panel(label) {
    return new Container({
      "width": 210,
      "height": 100,
      "alignment": "center",
      "decoration": (this.__k0 || (this.__k0 = new BoxDecoration({
        "gradient": _gradient
      }))),
      "child": new Text({
        "style": {
          "color": Colors.white,
          "fontSize": 22,
          "fontWeight": "bold"
        },
        "data": label
      })
    });
  }
  _row(title, filtered) {
    return new Padding({
      "padding": {
        "left": 0.0,
        "top": 0.0,
        "right": 0.0,
        "bottom": 10.0
      },
      "child": new Column({
        "crossAxisAlignment": "start",
        "children": [
          new Text({
            "style": {
              "fontSize": 12,
              "color": Colors.black54
            },
            "data": title
          }),
          (this.__k1 || (this.__k1 = new SizedBox({
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
        (this.__k2 || (this.__k2 = new Text({
          "data": "ImageFiltered",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k3 || (this.__k3 = new Text({
          "data": "整棵子树作为图片处理：模糊 / 膨胀 / 矩阵 / 组合",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 10
        }))),
        this._row("① 原样", this._panel("A")),
        this._row("② blur(sigmaX: 3, sigmaY: 3)", new ImageFiltered({
          "imageFilter": {
            "kind": "blur",
            "sigmaX": 3.0,
            "sigmaY": 3.0
          },
          "child": this._panel("B")
        })),
        this._row("③ dilate(radiusX: 3, radiusY: 3)", new ImageFiltered({
          "imageFilter": {
            "kind": "dilate",
            "radiusX": 3.0,
            "radiusY": 3.0
          },
          "child": this._panel("C")
        })),
        this._row("④ compose(outer: blur(2), inner: matrix(旋转 20°))", new ImageFiltered({
          "imageFilter": {
            "kind": "compose",
            "outer": {
              "kind": "blur",
              "sigmaX": 2.0,
              "sigmaY": 2.0
            },
            "inner": {
              "kind": "matrix",
              "matrix": [
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
            }
          },
          "child": this._panel("D")
        }))
      ]
    });
  }
}

