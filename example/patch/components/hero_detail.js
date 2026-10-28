// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/hero_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Center, Column, GestureDetector, Hero, Material, SizedBox, Text } from '../flutter.js';

// 组件 HeroDetail
export class HeroDetail {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.tag = (args && args.tag !== undefined) ? args.tag : "hero-native";
    this.label = (args && args.label !== undefined) ? args.label : "原生 Hero";
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Hero",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "点卡片跳转 → 卡片飞到目标页；返回时飞回",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new GestureDetector({
          "onTap": this.__bindFn(0, [], () => _app_host_.invoke("openHeroTarget", [this.tag, this.label])),
          "child": new Hero({
            "tag": this.tag,
            "transitionOnUserGestures": true,
            "child": new Material({
              "color": Colors.deepPurple,
              "borderRadius": {
                "radius": 12.0
              },
              "child": new SizedBox({
                "width": 160,
                "height": 90,
                "child": new Center({
                  "child": new Text({
                    "style": {
                      "color": Colors.white,
                      "fontWeight": "bold"
                    },
                    "data": this.label
                  })
                })
              })
            })
          })
        })
      ]
    });
  }
}

