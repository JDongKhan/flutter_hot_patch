// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/banner_component.dart 自动生成
// 重新生成：dart run build_runner build

import { PanelColors } from 'hello_component.js';
import { Column, ElevatedButton, Text } from '../flutter.js';

// 组件 BannerCard
export class BannerCard {
  constructor(args) {
    this.props = args || {};
    this._views = 0;
  }
  initState() {
    this._views = 5;
  }
  bump() {
    this.setState(() => { this._views += 1; });
  }
  build(context) {
    return new Column({
        "children": [
          new Text({
              "style": {
                "fontSize": 20,
                "color": PanelColors.background
              },
              "data": "Banner from another file"
            }),
          new Text({
              "data": "views = " + this._views
            }),
          new ElevatedButton({
              "onPressed": this.__bindFn(0, [], (...__a) => this.bump(...__a)),
              "child": (this.__k0 || (this.__k0 = new Text({
                  "data": "Bump"
                })))
            })
        ]
      });
  }
}

