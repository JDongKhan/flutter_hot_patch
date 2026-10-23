// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/detail_pages.dart 自动生成
// 重新生成：dart run build_runner build

import { Container, GestureDetector, Text } from '../../flutter.js';

const _avatarImg = "https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=portrait%20of%20a%20smiling%20young%20woman%20traveler%20avatar&image_size=square";
const _bannerImg = "https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=aerial%20view%20of%20tropical%20island%20beach%20turquoise%20water%20travel%20photography&image_size=landscape_16_9";
export const kBrand = '#ff0e7afb';
export const kPrice = '#ffff5a36';
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
              "color": (this.primary ? kBrand : '#FFFFFF'),
              "borderRadius": {
                "radius": 14.0
              },
              "border": {
                "all": {
                  "color": (this.primary ? kBrand : '#ffdfe4ec')
                }
              }
            },
            "child": new Text({
                "style": {
                  "fontSize": 12,
                  "color": (this.primary ? '#FFFFFF' : '#ff4d5462')
                },
                "data": this.label
              })
          })
      });
  }
}

