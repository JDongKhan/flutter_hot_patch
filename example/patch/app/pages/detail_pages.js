// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/detail_pages.dart 自动生成
// 重新生成：dart run build_runner build

import { Container, GestureDetector, Text } from '../../flutter.js';

const _avatarImg = "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop&q=80";
const _bannerImg = "https://images.unsplash.com/photo-1519046904884-53103b34b206?w=1200&h=675&fit=crop&q=80";
export const kBrand = new Color({value: 0xFF0E7AFB});
export const kPrice = new Color({value: 0xFFFF5A36});
const _steps = ["提交订单", "支付成功", "商家发货", "已完成"];

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
          "padding": {
            "left": 14.0,
            "top": 0.0,
            "right": 14.0,
            "bottom": 0.0
          },
          "height": 32,
          "alignment": "center",
          "decoration": {
            "color": (this.primary ? kBrand : Colors.white),
            "borderRadius": {
              "radius": 14.0
            },
            "border": {
              "all": {
                "color": (this.primary ? kBrand : new Color({value: 0xFFDFE4EC}))
              }
            }
          },
          "child": new Text({
            "style": {
              "fontSize": 12,
              "color": (this.primary ? Colors.white : new Color({value: 0xFF4D5462}))
            },
            "data": this.label
          })
        })
      });
  }
}

