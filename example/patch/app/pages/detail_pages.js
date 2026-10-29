// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/detail_pages.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, Border, BorderRadius, BoxDecoration, Color, Colors, Container, EdgeInsets, FontWeight, GestureDetector, Text, TextStyle } from '../../flutter.js';

const _avatarImg = "assets/images/photo-1494790108377-be9c29b29330.jpg";
const _bannerImg = "assets/images/photo-1519046904884-53103b34b206.jpg";
export const kBrand = new Color({value: 0xFF0E7AFB});
export const kPrice = new Color({value: 0xFFFF5A36});

// 组件 MiniButton
export class MiniButton {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.label = (args && args.label !== undefined) ? args.label : '';
    this.primary = (args && args.primary !== undefined) ? args.primary : false;
    this.onTap = (args && args.onTap !== undefined) ? args.onTap : null;
  }
  build(context) {
    return new GestureDetector({
      "onTap": this.__bindFn(0, [], (...__a) => this.onTap(...__a)),
      "child": new Container({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.symmetric({
          "horizontal": 14,
          "vertical": 0
        }))),
        "height": 32,
        "alignment": Alignment.center,
        "decoration": new BoxDecoration({
          "color": this.primary ? kBrand : Colors.white,
          "borderRadius": BorderRadius.circular({
            "radius": 14
          }),
          "border": Border.all({
            "color": this.primary ? kBrand : (this.__k1 || (this.__k1 = new Color({
              "value": 0xFFDFE4EC
            })))
          })
        }),
        "child": new Text({
          "style": new TextStyle({
            "fontSize": 12,
            "fontWeight": this.primary ? FontWeight.w600 : FontWeight.w500,
            "color": this.primary ? Colors.white : (this.__k2 || (this.__k2 = new Color({
              "value": 0xFF4D5462
            })))
          }),
          "data": this.label
        })
      })
    });
  }
}

