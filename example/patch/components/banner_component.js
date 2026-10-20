// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/banner_component.dart 自动生成
// 重新生成：dart run build_runner build

import { PanelColors } from 'hello_component.js';
import { __h } from '../flutter.js';

// 组件 BannerCard
export class BannerCard {
  constructor() {
    this._views = 0;
  }
  initState() {
    this._views = 5;
  }
  bump() {
    this.setState(() => { this._views += 1; });
  }
  build(context) {
    return __h('Column', {}, [
        __h('Text', {
            "style": {
              "fontSize": 20,
              "color": PanelColors.background
            },
            "data": "Banner from another file"
          }),
        __h('Text', {
            "data": "views = " + this._views
          }),
        __h('ElevatedButton', {
            "onPressed": this.__bind("bump")
          }, [
            __h('Text', {
                "data": "Bump"
              })
          ])
      ]);
  }
}

