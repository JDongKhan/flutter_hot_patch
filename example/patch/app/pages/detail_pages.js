// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/detail_pages.dart 自动生成
// 重新生成：dart run build_runner build

import { kAvatarImg, kBanners } from '../service/app_data.js';
import { __h } from '../../flutter.js';

export const kBrand = '#ff0e7afb';
export const kPrice = '#ffff5a36';
const _steps = ["提交订单", "支付成功", "商家发货", "已完成"];

// 组件 MiniButton
export class MiniButton {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.label = (args && args.label !== undefined) ? args.label : '';
    this.primary = (args && args.primary !== undefined) ? args.primary : false;
    this.onTap = (args && args.onTap !== undefined) ? args.onTap : null;
  }
  build(context) {
    return __h('GestureDetector', {
        "onTap": this.__bindFn(0, [], (...__a) => this.onTap(...__a)),
        "child": __h('Container', {
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
            "child": __h('Text', {
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

