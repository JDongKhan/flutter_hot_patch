// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/composite_component.dart 自动生成
// 重新生成：dart run build_runner build

import { BannerCard } from 'banner_component.js';
import { Column, ElevatedButton, SizedBox, Text } from '../flutter.js';

// 组件 DashboardCard
export class DashboardCard {
  constructor(args) {
    this.props = args || {};
    this._ticks = 0;
  }
  tick() {
    this.setState(() => { this._ticks += 1; });
  }
  build(context) {
    return new Column({
      "children": [
        new Text({
          "style": {
            "fontSize": 22,
            "fontWeight": "w600"
          },
          "data": "Dashboard (JS)"
        }),
        new Text({
          "data": "ticks = " + this._ticks
        }),
        (this.__k0 || (this.__k0 = new BannerCard({}))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 12
        }))),
        (this.__k2 || (this.__k2 = new _LabeledDivider({
          "child": new Text({
            "data": "native child slot"
          }),
          "text": "private widget"
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 8
        }))),
        (this.__k4 || (this.__k4 = new LabeledDivider({
          "text": "public widget"
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 12
        }))),
        new ElevatedButton({
          "onPressed": this.__bindFn(0, [], (...__a) => this.tick(...__a)),
          "style": {
            "backgroundColor": Colors.orange,
            "foregroundColor": Colors.white
          },
          "child": (this.__k5 || (this.__k5 = new Text({
            "data": "Tick"
          })))
        })
      ]
    });
  }
}

// 组件 LabeledDivider
export class LabeledDivider {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.text = (args && args.text !== undefined) ? args.text : '';
    this.child = (args && args.child !== undefined) ? args.child : null;
  }
  build(context) {
    return new Column({
      "mainAxisSize": "min",
      "children": [
        new Text({
          "style": {
            "fontSize": 12,
            "color": Colors.blueGrey
          },
          "data": "★ " + this.text + " ★"
        }),
        ...((this.child != null) ? [this.child] : [])
      ]
    });
  }
}

