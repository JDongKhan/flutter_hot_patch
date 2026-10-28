// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/preferred_size_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Container, ListView, PreferredSize, SafeArea, Scaffold, SizedBox, Slider, Text } from '../flutter.js';

// 组件 PreferredSizeDetail
export class PreferredSizeDetail {
  constructor(args) {
    this.props = args || {};
    this._height = 64;
  }
  build(context) {
    var label = this._height.toStringAsFixed(0);
    return new Scaffold({
      "appBar": new PreferredSize({
        "preferredSize": Size.fromHeight({
          "height": this._height
        }),
        "child": new Container({
          "color": Colors.deepPurple,
          "alignment": "centerLeft",
          "padding": {
            "left": 16.0,
            "top": 0.0,
            "right": 16.0,
            "bottom": 0.0
          },
          "child": new SafeArea({
            "child": new Text({
              "style": {
                "color": Colors.white,
                "fontSize": 16
              },
              "data": "自定义顶栏 · 高度 " + this._height.toStringAsFixed(0)
            })
          })
        })
      }),
      "body": new ListView({
        "padding": {
          "left": 16.0,
          "top": 16.0,
          "right": 16.0,
          "bottom": 16.0
        },
        "children": [
          (this.__k0 || (this.__k0 = new Text({
            "data": "PreferredSize",
            "style": {
              "fontWeight": "bold"
            }
          }))),
          (this.__k1 || (this.__k1 = new SizedBox({
            "height": 4
          }))),
          (this.__k2 || (this.__k2 = new Text({
            "data": "Scaffold.appBar 只接受 PreferredSizeWidget；套一层 PreferredSize 就能让任意子树占用指定高度。拖下面的滑块，顶栏高度随之变化。",
            "style": {
              "color": Colors.black54,
              "fontSize": 12
            }
          }))),
          (this.__k3 || (this.__k3 = new SizedBox({
            "height": 12
          }))),
          new Text({
            "style": {
              "fontSize": 12
            },
            "data": "preferredSize: Size(∞, " + this._height.toStringAsFixed(0) + ")"
          }),
          new Slider({
            "value": this._height,
            "min": 40,
            "max": 120,
            "divisions": 8,
            "label": this._height.toStringAsFixed(0),
            "onChanged": this.__bindFn(0, [], (v) => this.setState(() => {
              this._height = v;
            }))
          }),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 8
          }))),
          (this.__k5 || (this.__k5 = new Text({
            "data": "① 高度 40~120 之间变化；② 内容区始终紧贴顶栏下方（Scaffold 按 preferredSize.height 占位）。",
            "style": {
              "color": Colors.black54,
              "fontSize": 12
            }
          })))
        ]
      })
    });
  }
}

