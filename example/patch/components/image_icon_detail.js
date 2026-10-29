// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/image_icon_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Center, Colors, Column, Icon, ImageIcon, Padding, Row, SizedBox, Text } from '../flutter.js';

// 组件 ImageIconDetail
export class ImageIconDetail {
  constructor(args) {
    this.props = args || {};
  }
  _cell(label, icon) {
    return new SizedBox({
      "width": 96,
      "child": new Column({
        "children": [
          new SizedBox({
            "height": 64,
            "child": new Center({
              "child": icon
            })
          }),
          (this.__k0 || (this.__k0 = new SizedBox({
            "height": 6
          }))),
          new Text({
            "textAlign": "center",
            "style": {
              "fontSize": 11,
              "color": Colors.black54
            },
            "data": label
          })
        ]
      })
    });
  }
  _section(title, content) {
    return new Padding({
      "padding": {
        "left": 0.0,
        "top": 0.0,
        "right": 0.0,
        "bottom": 12.0
      },
      "child": new Column({
        "crossAxisAlignment": "start",
        "children": [
          new Text({
            "style": {
              "fontSize": 12,
              "color": Colors.black54
            },
            "data": title
          }),
          (this.__k0 || (this.__k0 = new SizedBox({
            "height": 6
          }))),
          content
        ]
      })
    });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "start",
      "children": [
        (this.__k1 || (this.__k1 = new Text({
          "data": "ImageIcon",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 4
        }))),
        (this.__k3 || (this.__k3 = new Text({
          "data": "图片作为图标：尺寸 / 颜色（srcIn 染色）/ 与 Icon 对照",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        this._section("① size：24 / 36 / 48（颜色继承 IconTheme）", new Row({
          "crossAxisAlignment": "end",
          "children": [
            this._cell("size 24", (this.__k5 || (this.__k5 = new ImageIcon({
              "image": "assets/images/photo-1494790108377-be9c29b29330.jpg",
              "size": 24
            })))),
            this._cell("size 36", (this.__k6 || (this.__k6 = new ImageIcon({
              "image": "assets/images/photo-1494790108377-be9c29b29330.jpg",
              "size": 36
            })))),
            this._cell("size 48", (this.__k7 || (this.__k7 = new ImageIcon({
              "image": "assets/images/photo-1494790108377-be9c29b29330.jpg",
              "size": 48
            }))))
          ]
        })),
        this._section("② color：srcIn 染色（同一张图 → 同色剪影）", new Row({
          "children": [
            this._cell("teal", (this.__k8 || (this.__k8 = new ImageIcon({
              "color": Colors.teal,
              "image": "assets/images/photo-1494790108377-be9c29b29330.jpg",
              "size": 40
            })))),
            this._cell("deepOrange", (this.__k9 || (this.__k9 = new ImageIcon({
              "color": Colors.deepOrange,
              "image": "assets/images/photo-1494790108377-be9c29b29330.jpg",
              "size": 40
            })))),
            this._cell("indigo", (this.__k10 || (this.__k10 = new ImageIcon({
              "color": Colors.indigo,
              "image": "assets/images/photo-1494790108377-be9c29b29330.jpg",
              "size": 40
            }))))
          ]
        })),
        this._section("③ 与 Icon 并排（同尺寸同色，字形 vs 图片）", new Row({
          "children": [
            this._cell("ImageIcon", (this.__k11 || (this.__k11 = new ImageIcon({
              "color": Colors.deepPurple,
              "image": "assets/images/photo-1448375240586-882707db888b.jpg",
              "size": 40
            })))),
            this._cell("Icon", (this.__k12 || (this.__k12 = new Icon({
              "color": Colors.deepPurple,
              "icon": "park",
              "size": 40
            }))))
          ]
        })),
        this._section("④ 实际用法：徽标 + 文案（semanticLabel 只影响无障碍朗读）", new Row({
          "children": [
            (this.__k13 || (this.__k13 = new ImageIcon({
              "color": Colors.teal,
              "image": "assets/images/photo-1501785888041-af3ef285b470.jpg",
              "semanticLabel": "风景徽标",
              "size": 28
            }))),
            (this.__k14 || (this.__k14 = new SizedBox({
              "width": 8
            }))),
            (this.__k15 || (this.__k15 = new Text({
              "data": "图片图标可直接用在 Row / ListTile.leading 里"
            })))
          ]
        }))
      ]
    });
  }
}

