// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/composite_component.dart 自动生成
// 重新生成：dart run build_runner build

import { BannerCard } from 'banner_component.component.js';
import { Button } from '../flutter/Button.js';
import { Column } from '../flutter/Column.js';
import { SizedBox } from '../flutter/SizedBox.js';
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

class DashboardCardComponent {
  constructor() {
    this._ticks = 0;
  }
  tick() { this.setState(function(){ this._ticks += 1; }); }
  build() {
    return Column({}, [
        Text({
            "data": "Dashboard (JS)",
            "style": {
              "fontSize": 22,
              "fontWeight": "w600"
            }
          }),
        Text({
            "data": "ticks = " + this._ticks
          }),
        BannerCard({}),
        SizedBox({
            "height": 12
          }),
        {
          "type": "Component",
          "props": {
            "component": "_LabeledDivider",
            "args": {
              "text": "private widget"
            }
          },
          "children": []
        },
        SizedBox({
            "height": 8
          }),
        {
          "type": "Component",
          "props": {
            "component": "LabeledDivider",
            "args": {
              "text": "public widget"
            }
          },
          "children": []
        },
        SizedBox({
            "height": 12
          }),
        Button({
            "kind": "elevated",
            "label": "Tick",
            "event": "tick",
            "style": {
              "backgroundColor": '#FF9800',
              "foregroundColor": '#FFFFFF'
            }
          })
      ]);
  }
}
export function DashboardCard(props, children) {
  return __h(DashboardCardComponent, props, children);
}

