// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/composite_component.dart 自动生成
// 重新生成：dart run build_runner build

import { BannerCard } from 'banner_component.js';
import { __h } from '../flutter.js';

// 组件 DashboardCard
export class DashboardCard {
  constructor() {
    this._ticks = 0;
  }
  tick() {
    this.setState(() => { this._ticks += 1; });
  }
  build(context) {
    return __h('Column', {}, [
        __h('Text', {
            "style": {
              "fontSize": 22,
              "fontWeight": "w600"
            },
            "$pos": [
              "Dashboard (JS)"
            ]
          }),
        __h('Text', {
            "$pos": [
              "ticks = " + this._ticks
            ]
          }),
        __h(BannerCard, {}),
        __h('SizedBox', {
            "height": 12
          }),
        __h('_LabeledDivider', {
            "text": "private widget"
          }),
        __h('SizedBox', {
            "height": 8
          }),
        __h(LabeledDivider, {
            "text": "public widget"
          }),
        __h('SizedBox', {
            "height": 12
          }),
        __h('ElevatedButton', {
            "onPressed": this.__bind("tick"),
            "style": {
              "backgroundColor": '#FF9800',
              "foregroundColor": '#FFFFFF'
            }
          }, [
            __h('Text', {
                "$pos": [
                  "Tick"
                ]
              })
          ])
      ]);
  }
}

// 组件 LabeledDivider
export class LabeledDivider {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.text = (args && args.text !== undefined) ? args.text : '';
  }
  build(context) {
    return __h('Text', {
        "style": {
          "fontSize": 12,
          "color": '#607D8B'
        },
        "$pos": [
          "★ " + this.text + " ★"
        ]
      });
  }
}

