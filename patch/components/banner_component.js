// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/banner_component.dart 自动生成
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
    this.setState(function(){ this._views += 1; });
  }
  build() {
    return __h('Column', {}, [
        __h('Text', {
            "data": "Banner from another file",
            "style": {
              "fontSize": 20,
              "color": PanelColors.background
            }
          }),
        __h('Text', {
            "data": "views = " + this._views
          }),
        __h('Button', {
            "kind": "elevated",
            "label": "Bump",
            "event": this.__bind("bump")
          })
      ]);
  }
}

