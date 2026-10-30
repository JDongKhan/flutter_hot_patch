// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/image_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { BorderRadius, BoxFit, CachedNetworkImage, CircleAvatar, ClipRRect, Colors, Column, CrossAxisAlignment, FontWeight, Icon, Icons, Image, Row, SizedBox, Text, TextStyle } from '../flutter.js';

// 组件 ImageDetail
export class ImageDetail {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Image · 网络图片",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new ClipRRect({
          "borderRadius": BorderRadius.circular({
            "radius": 12
          }),
          "child": Image.network({
            "height": 120,
            "fit": BoxFit.cover,
            "src": "https://picsum.photos/seed/hotpatch/400/160"
          })
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 12
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "CachedNetworkImage · 磁盘缓存网络图",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new ClipRRect({
          "borderRadius": BorderRadius.circular({
            "radius": 12
          }),
          "child": new CachedNetworkImage({
            "imageUrl": "https://picsum.photos/seed/hotpatchcache/400/160",
            "height": 120,
            "fit": BoxFit.cover
          })
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 12
        }))),
        (this.__k3 || (this.__k3 = new Text({
          "data": "Icon / CircleAvatar",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new Row({
          "children": [
            (this.__k4 || (this.__k4 = new Icon({
              "color": Colors.amber,
              "icon": Icons.star,
              "size": 28
            }))),
            (this.__k5 || (this.__k5 = new SizedBox({
              "width": 12
            }))),
            (this.__k6 || (this.__k6 = new Icon({
              "color": Colors.blue,
              "icon": Icons.home,
              "size": 28
            }))),
            (this.__k5 || (this.__k5 = new SizedBox({
              "width": 12
            }))),
            (this.__k7 || (this.__k7 = new Icon({
              "color": Colors.red,
              "icon": Icons.favorite,
              "size": 28
            }))),
            (this.__k5 || (this.__k5 = new SizedBox({
              "width": 12
            }))),
            new CircleAvatar({
              "radius": 20,
              "backgroundColor": Colors.teal,
              "child": new Text({
                "style": new TextStyle({
                  "color": Colors.white
                }),
                "data": "AV"
              })
            })
          ]
        })
      ]
    });
  }
}

