// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/color_filtered_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, BlendMode, BoxDecoration, ColorFilter, ColorFiltered, Colors, Column, Container, CrossAxisAlignment, FontWeight, LinearGradient, SizedBox, Text, TextStyle } from '../flutter.js';

// 组件 ColorFilteredDetail
export class ColorFilteredDetail {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "ColorFiltered",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "四块内容完全相同，只有 colorFilter 不同",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        (this.__k4 || (this.__k4 = new _Sample({
          "label": "① 原样（无滤镜）"
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 8
        }))),
        new ColorFiltered({
          "colorFilter": (this.__k6 || (this.__k6 = ColorFilter.mode({
            "blendMode": BlendMode.multiply,
            "color": Colors.deepOrange
          }))),
          "child": (this.__k7 || (this.__k7 = new _Sample({
            "label": "② mode · deepOrange × multiply"
          })))
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 8
        }))),
        new ColorFiltered({
          "colorFilter": (this.__k8 || (this.__k8 = ColorFilter.mode({
            "blendMode": BlendMode.modulate,
            "color": Colors.deepPurple
          }))),
          "child": (this.__k9 || (this.__k9 = new _Sample({
            "label": "③ mode · deepPurple × modulate"
          })))
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 8
        }))),
        new ColorFiltered({
          "colorFilter": (this.__k10 || (this.__k10 = ColorFilter.matrix({
            "matrix": [
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0
            ]
          }))),
          "child": (this.__k11 || (this.__k11 = new _Sample({
            "label": "④ matrix · 灰度（BT.709）"
          })))
        })
      ]
    });
  }
}

// 组件 _Sample
export class _Sample {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.label = (args && args.label !== undefined) ? args.label : '';
  }
  build(context) {
    return new Container({
      "height": 64,
      "alignment": Alignment.center,
      "decoration": (this.__k0 || (this.__k0 = new BoxDecoration({
        "gradient": new LinearGradient({
          "colors": [
            Colors.red,
            Colors.amber,
            Colors.green,
            Colors.blue
          ]
        })
      }))),
      "child": new Text({
        "style": (this.__k1 || (this.__k1 = new TextStyle({
          "color": Colors.white,
          "fontWeight": FontWeight.bold
        }))),
        "data": this.label
      })
    });
  }
}

