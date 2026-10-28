// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/fade_in_image_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Align, ClipRRect, Column, FadeInImage, OutlinedButton, SizedBox, Text } from '../flutter.js';

// 组件 FadeInImageDetail
export class FadeInImageDetail {
  constructor(args) {
    this.props = args || {};
    this._seed = 0;
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "FadeInImage",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "占位图 → 目标图淡入；点「重新加载」可反复观察",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        (this.__k4 || (this.__k4 = new Text({
          "data": "① assetNetwork（资源占位 + 网络图）",
          "style": {
            "fontSize": 12
          }
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new ClipRRect({
          "borderRadius": {
            "radius": 10.0
          },
          "child": FadeInImage.assetNetwork({
            "placeholder": "assets/images/photo-1448375240586-882707db888b.jpg",
            "image": "https://picsum.photos/seed/fade" + this._seed + "/600/300",
            "width": 600,
            "height": 150,
            "fit": "cover",
            "fadeInDuration": (this.__k6 || (this.__k6 = new Duration({
              "milliseconds": 900
            }))),
            "fadeOutDuration": (this.__k7 || (this.__k7 = new Duration({
              "milliseconds": 300
            })))
          })
        }),
        (this.__k8 || (this.__k8 = new SizedBox({
          "height": 8
        }))),
        new Align({
          "alignment": "centerLeft",
          "child": new OutlinedButton({
            "onPressed": this.__bindFn(0, [], () => this.setState(() => {
              this._seed += 1;
            })),
            "child": (this.__k9 || (this.__k9 = new Text({
              "data": "重新加载"
            })))
          })
        }),
        (this.__k8 || (this.__k8 = new SizedBox({
          "height": 8
        }))),
        (this.__k10 || (this.__k10 = new Text({
          "data": "② 普通构造（AssetImage 占位 + NetworkImage）",
          "style": {
            "fontSize": 12
          }
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new ClipRRect({
          "borderRadius": {
            "radius": 10.0
          },
          "child": new FadeInImage({
            "placeholder": "assets/images/photo-1448375240586-882707db888b.jpg",
            "image": "https://picsum.photos/seed/fadeplain/600/300",
            "width": 600,
            "height": 120,
            "fit": "cover",
            "fadeInDuration": (this.__k11 || (this.__k11 = new Duration({
              "milliseconds": 600
            })))
          })
        })
      ]
    });
  }
}

