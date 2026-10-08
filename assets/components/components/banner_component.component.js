// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/banner_component.dart 自动生成
// 重新生成：dart run build_runner build

import { PanelColors } from 'hello_component.component.js';
import { Button } from '../flutter/Button.js';
import { Column } from '../flutter/Column.js';
import { Text } from '../flutter/Text.js';
// 节点工厂：归一化 props/children，形状与 widget 模块一致。
function __h(type, props, children) {
  return {
    type: type,
    props: props || {},
    children: children == null
        ? []
        : (Array.isArray(children) ? children : [children]),
  };
}

class BannerCardComponent {
  constructor() {
    this._views = 0;
  }
  initState() { this._views = 5; }
  bump() { this.setState(function(){ this._views += 1; }); }
  build() {
    return Column({}, [
        Text({
            "data": "Banner from another file",
            "style": {
              "fontSize": 20,
              "color": PanelColors.background
            }
          }),
        Text({
            "data": "views = " + this._views
          }),
        Button({
            "kind": "elevated",
            "label": "Bump",
            "event": this.__bind("bump")
          })
      ]);
  }
}
export function BannerCard(props, children) {
  return __h(BannerCardComponent, props, children);
}

