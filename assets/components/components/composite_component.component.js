// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/composite_component.dart 自动生成
// 重新生成：dart run build_runner build

import { BannerCard } from 'banner_component.component.js';
import { __h } from '../../flutter/Node.js';
import { Button } from '../../flutter/Button.js';
import { Column } from '../../flutter/Column.js';
import { SizedBox } from '../../flutter/SizedBox.js';
import { Text } from '../../flutter/Text.js';

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
        __h("Component", {
            "component": "_LabeledDivider",
            "args": {
              "text": "private widget"
            }
          }, null),
        SizedBox({
            "height": 8
          }),
        __h("Component", {
            "component": "LabeledDivider",
            "args": {
              "text": "public widget"
            }
          }, null),
        SizedBox({
            "height": 12
          }),
        Button({
            "kind": "elevated",
            "label": "Tick",
            "event": this.__bind("tick"),
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

