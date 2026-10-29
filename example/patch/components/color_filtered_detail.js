// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/color_filtered_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { ColorFiltered, Colors, Column, Container, SizedBox, Text } from '../flutter.js';

// 组件 ColorFilteredDetail
export class ColorFilteredDetail {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "ColorFiltered",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "四块内容完全相同，只有 colorFilter 不同",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
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
          "colorFilter": {
            "kind": "mode",
            "color": Colors.deepOrange,
            "blendMode": "multiply"
          },
          "child": (this.__k6 || (this.__k6 = new _Sample({
            "label": "② mode · deepOrange × multiply"
          })))
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 8
        }))),
        new ColorFiltered({
          "colorFilter": {
            "kind": "mode",
            "color": Colors.deepPurple,
            "blendMode": "modulate"
          },
          "child": (this.__k7 || (this.__k7 = new _Sample({
            "label": "③ mode · deepPurple × modulate"
          })))
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 8
        }))),
        new ColorFiltered({
          "colorFilter": {
            "kind": "matrix",
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
          },
          "child": (this.__k8 || (this.__k8 = new _Sample({
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
      "alignment": "center",
      "decoration": {
        "gradient": {
          "kind": "linear",
          "colors": [
            Colors.red,
            Colors.amber,
            Colors.green,
            Colors.blue
          ]
        }
      },
      "child": new Text({
        "style": {
          "color": Colors.white,
          "fontWeight": "bold"
        },
        "data": this.label
      })
    });
  }
}

