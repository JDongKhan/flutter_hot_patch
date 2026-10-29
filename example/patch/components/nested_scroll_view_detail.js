// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/nested_scroll_view_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { CircleAvatar, Colors, Column, Container, ListTile, ListView, NestedScrollView, Padding, SizedBox, SliverAppBar, SliverToBoxAdapter, Text } from '../flutter.js';

// 组件 NestedScrollViewDetail
export class NestedScrollViewDetail {
  constructor(args) {
    this.props = args || {};
  }
  _title(s) {
    return new Text({
      "style": {
        "fontSize": 12,
        "color": Colors.black54
      },
      "data": s
    });
  }
  _innerList(tag, color) {
    return ListView.builder({
      "itemCount": 12,
      "itemBuilder": (context, index) => new ListTile({
        "dense": true,
        "leading": new CircleAvatar({
          "radius": 12,
          "backgroundColor": color,
          "child": new Text({
            "style": {
              "fontSize": 10,
              "color": Colors.white
            },
            "data": (index + 1)
          })
        }),
        "title": new Text({
          "data": tag + " 内层第 " + (index + 1) + " 行"
        })
      })
    });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "start",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "NestedScrollView",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "头部 slivers 与内层 body 联动：先折叠头部，再滚内层",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 10
        }))),
        this._title("① pinned 折叠头部（expandedHeight 120）"),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 6
        }))),
        new SizedBox({
          "height": 240,
          "child": new NestedScrollView({
            "headerSliverBuilder": (context, innerBoxIsScrolled) => [new SliverAppBar({
                "pinned": true,
                "expandedHeight": 120,
                "title": (this.__k5 || (this.__k5 = new Text({
                  "data": "pinned 头部"
                }))),
                "flexibleSpace": new Container({
                  "color": Colors.teal.shade300,
                  "alignment": "bottomLeft",
                  "padding": {
                    "left": 12.0,
                    "top": 12.0,
                    "right": 12.0,
                    "bottom": 12.0
                  },
                  "child": (this.__k6 || (this.__k6 = new Text({
                    "data": "折叠区（flexibleSpace）",
                    "style": {
                      "color": Colors.white,
                      "fontSize": 11
                    }
                  })))
                })
              }), (this.__k7 || (this.__k7 = new SliverToBoxAdapter({
                "child": new Padding({
                  "padding": {
                    "left": 8.0,
                    "top": 8.0,
                    "right": 8.0,
                    "bottom": 8.0
                  },
                  "child": new Text({
                    "data": "这段文字属于外层头部 sliver，随外层一起滚走"
                  })
                })
              })))],
            "body": this._innerList("①", Colors.teal)
          })
        }),
        (this.__k8 || (this.__k8 = new SizedBox({
          "height": 12
        }))),
        this._title("② floating + floatHeaderSlivers（内层滑回顶部时头部浮出）"),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 6
        }))),
        new SizedBox({
          "height": 240,
          "child": new NestedScrollView({
            "floatHeaderSlivers": true,
            "headerSliverBuilder": (context, innerBoxIsScrolled) => [new SliverAppBar({
                "floating": true,
                "snap": true,
                "title": (this.__k9 || (this.__k9 = new Text({
                  "data": "floating 头部"
                }))),
                "backgroundColor": Colors.deepOrange.shade300
              })],
            "body": this._innerList("②", Colors.deepOrange)
          })
        })
      ]
    });
  }
}

