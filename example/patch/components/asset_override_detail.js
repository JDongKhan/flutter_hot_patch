// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/asset_override_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { BorderRadius, BoxDecoration, BoxFit, ClipRRect, Color, Column, Container, CrossAxisAlignment, EdgeInsets, FontWeight, Image, SizedBox, StatefulWidget, Text, TextStyle, rootBundle } from '../flutter.js';

// 组件 AssetOverrideDetail
export class AssetOverrideDetail extends StatefulWidget {
  static _imageAsset = "assets/images/photo-1519681393784-d120267933ba.jpg";
  static _jsonAsset = "assets/data/asset_override_demo.json";
  constructor(args) {
    super(args);
    this._jsonText = "加载中…";
  }
  initState() {
    super.initState();
    this._loadJson();
  }
  async _loadJson() {
    try {
      const text = await rootBundle.loadString(AssetOverrideDetail._jsonAsset);
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._jsonText = text;
      });
    } catch (__e) {
      const e = __e;
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._jsonText = "读取失败：" + e;
      });
    }
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "assets 图片 · 补丁包同名优先",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new ClipRRect({
          "borderRadius": BorderRadius.circular({
            "radius": 12
          }),
          "child": Image.asset({
            "height": 160,
            "fit": BoxFit.cover,
            "name": AssetOverrideDetail._imageAsset
          })
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k2 || (this.__k2 = new TextStyle({
            "color": new Color({
              "value": 0xFF888888
            }),
            "fontSize": 12
          }))),
          "data": AssetOverrideDetail._imageAsset
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 16
        }))),
        (this.__k4 || (this.__k4 = new Text({
          "data": "assets JSON · 补丁包同名优先",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Container({
          "padding": (this.__k5 || (this.__k5 = EdgeInsets.all({
            "value": 12
          }))),
          "decoration": new BoxDecoration({
            "color": (this.__k6 || (this.__k6 = new Color({
              "value": 0xFFF5F5F5
            }))),
            "borderRadius": BorderRadius.circular({
              "radius": 12
            })
          }),
          "child": new Text({
            "style": (this.__k7 || (this.__k7 = new TextStyle({
              "fontSize": 13,
              "height": 1.5
            }))),
            "data": this._jsonText
          })
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k2 || (this.__k2 = new TextStyle({
            "color": new Color({
              "value": 0xFF888888
            }),
            "fontSize": 12
          }))),
          "data": AssetOverrideDetail._jsonAsset
        })
      ]
    });
  }
}

