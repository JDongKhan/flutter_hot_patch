// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/preferred_size_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, Colors, Container, EdgeInsets, FontWeight, ListView, PreferredSize, SafeArea, Scaffold, Size, SizedBox, Slider, Text, TextStyle } from '../flutter.js';

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
          "height": this._height,
          "color": Colors.deepPurple,
          "alignment": Alignment.centerLeft,
          "padding": (this.__k0 || (this.__k0 = EdgeInsets.symmetric({
            "horizontal": 16
          }))),
          "child": new SafeArea({
            "child": new Text({
              "style": (this.__k1 || (this.__k1 = new TextStyle({
                "color": Colors.white,
                "fontSize": 16
              }))),
              "data": "自定义顶栏 · 高度 " + label
            })
          })
        })
      }),
      "body": new ListView({
        "padding": (this.__k2 || (this.__k2 = EdgeInsets.all({
          "value": 16
        }))),
        "children": [
          (this.__k3 || (this.__k3 = new Text({
            "data": "PreferredSize",
            "style": new TextStyle({
              "fontWeight": FontWeight.bold
            })
          }))),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 4
          }))),
          (this.__k5 || (this.__k5 = new Text({
            "data": "Scaffold.appBar 只接受 PreferredSizeWidget；preferredSize 是**最大高度上限**，容器自身也要占满该高度。拖滑块，顶栏高度随之变化。",
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.black54
            })
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 12
          }))),
          new Text({
            "style": (this.__k7 || (this.__k7 = new TextStyle({
              "fontSize": 12
            }))),
            "data": "preferredSize: Size(∞, " + label + ")"
          }),
          new Slider({
            "value": this._height,
            "min": 40,
            "max": 120,
            "divisions": 8,
            "label": label,
            "onChanged": this.__bindFn(0, [], (v) => this.setState(() => {
              this._height = v;
            }))
          }),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          (this.__k9 || (this.__k9 = new Text({
            "data": "① 高度 40~120 之间变化；② 内容区始终紧贴顶栏下方（Scaffold 按 preferredSize.height 占位）。",
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.black54
            })
          })))
        ]
      })
    });
  }
}

