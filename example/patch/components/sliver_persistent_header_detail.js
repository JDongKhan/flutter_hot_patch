// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/sliver_persistent_header_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, AppBar, Colors, Column, Container, CustomScrollView, EdgeInsets, FontWeight, Icon, ListTile, Opacity, Padding, Scaffold, SizedBox, SliverList, SliverPersistentHeader, SliverToBoxAdapter, Text, TextStyle } from '../flutter.js';

// 组件 SliverPersistentHeaderDetail
export class SliverPersistentHeaderDetail {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new Scaffold({
      "appBar": new AppBar({
        "title": (this.__k0 || (this.__k0 = new Text({
          "data": "SliverPersistentHeader"
        })))
      }),
      "body": new CustomScrollView({
        "slivers": [
          new SliverPersistentHeader({
            "pinned": true,
            "delegate": (this.__k1 || (this.__k1 = new _PinnedDelegate({})))
          }),
          new SliverList({
            "delegate": {
              "__delegate": "builder",
              "builder": (context, index) => new ListTile({
                "leading": (this.__k2 || (this.__k2 = new Icon({
                  "color": Colors.deepPurple,
                  "icon": "list"
                }))),
                "title": new Text({
                  "data": "列表项 " + index
                }),
                "subtitle": (this.__k3 || (this.__k3 = new Text({
                  "data": "向上滚：pinned 头折叠并钉住"
                })))
              }),
              "childCount": 20
            }
          }),
          new SliverPersistentHeader({
            "floating": true,
            "delegate": (this.__k4 || (this.__k4 = new _FloatingDelegate({})))
          }),
          new SliverToBoxAdapter({
            "child": new Padding({
              "padding": (this.__k5 || (this.__k5 = EdgeInsets.all({
                "value": 16
              }))),
              "child": new Text({
                "style": (this.__k6 || (this.__k6 = new TextStyle({
                  "color": Colors.black54,
                  "fontSize": 13
                }))),
                "data": "floating 头下方的内容：先向下滚过它，再向上滚一点就会浮出"
              })
            })
          })
        ]
      })
    });
  }
}

// 组件 _FloatingDelegate
export class _FloatingDelegate {
  constructor(args) {
    this.props = args || {};
  }
  get minExtent() {
    return 48;
  }
  get maxExtent() {
    return 48;
  }
  build(context, shrinkOffset, overlapsContent) {
    return new Container({
      "color": Colors.teal,
      "alignment": Alignment.centerLeft,
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.symmetric({
        "horizontal": 16
      }))),
      "child": (this.__k1 || (this.__k1 = new Text({
        "data": "floating header（向上滚回时浮出）",
        "style": new TextStyle({
          "color": Colors.white,
          "fontSize": 13
        })
      })))
    });
  }
  shouldRebuild(oldDelegate) {
    return false;
  }
}

// 组件 _PinnedDelegate
export class _PinnedDelegate {
  constructor(args) {
    this.props = args || {};
  }
  get minExtent() {
    return 56;
  }
  get maxExtent() {
    return 120;
  }
  build(context, shrinkOffset, overlapsContent) {
    var t = ((shrinkOffset > 64) ? 1 : (shrinkOffset / 64));
    return new Container({
      "color": Colors.deepPurple,
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.fromLTRB({
        "bottom": 12,
        "left": 16,
        "right": 16,
        "top": 0
      }))),
      "alignment": Alignment.bottomLeft,
      "child": new Column({
        "mainAxisSize": "min",
        "crossAxisAlignment": "start",
        "children": [
          (this.__k1 || (this.__k1 = new Text({
            "data": "pinned header",
            "style": new TextStyle({
              "color": Colors.white,
              "fontSize": 16,
              "fontWeight": FontWeight.bold
            })
          }))),
          (this.__k2 || (this.__k2 = new SizedBox({
            "height": 2
          }))),
          new Opacity({
            "opacity": (1 - t),
            "child": new Text({
              "style": (this.__k3 || (this.__k3 = new TextStyle({
                "color": Colors.white70,
                "fontSize": 11
              }))),
              "data": "shrinkOffset = " + shrinkOffset.toStringAsFixed(1) + " · overlaps = " + overlapsContent
            })
          })
        ]
      })
    });
  }
  shouldRebuild(oldDelegate) {
    return true;
  }
}

