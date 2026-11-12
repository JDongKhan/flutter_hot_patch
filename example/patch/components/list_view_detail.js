// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/list_view_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, Axis, Colors, Column, Container, CrossAxisAlignment, Divider, EdgeInsets, FontWeight, InkWell, ListView, MainAxisAlignment, NotificationListener, Padding, SizedBox, StatefulWidget, Text, TextStyle } from '../flutter.js';

// 组件 ListViewDetail
export class ListViewDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._lazyOffset = 0;
    this._listBuilds = 0;
  }
  _onLazyScroll(n) {
    this.setState(() => {
      this._lazyOffset = n.metrics.pixels;
    });
    return false;
  }
  build(context) {
    this._listBuilds += 1;
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        new Container({
          "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
            "value": 12
          }))),
          "color": Colors.amber.shade50,
          "child": new Text({
            "style": (this.__k1 || (this.__k1 = new TextStyle({
              "fontSize": 12
            }))),
            "data": "父级 build 次数：" + this._listBuilds + "（点击 item 刷新时不应变化）。" + "日志：initState = 首次挂载，dispose = 滚出缓存被回收。" + "现在 builder / separated 无论有没有 itemExtent 都是懒的。"
          })
        }),
        this._section("ListView.builder + itemExtent：懒加载（offset: " + this._lazyOffset.toStringAsFixed(1) + "）", "只构建可见项；滚动时逐项 initState，离屏回收 dispose。"),
        new SizedBox({
          "height": 180,
          "child": new NotificationListener({
            "onNotification": (__a0) => this._onLazyScroll(__a0),
            "child": ListView.builder({
              "padding": (this.__k2 || (this.__k2 = EdgeInsets.symmetric({
                "horizontal": 8
              }))),
              "itemExtent": 64,
              "itemCount": 40,
              "itemBuilder": (context, index) => new _ListProbeItem({
                "tag": "lazy",
                "index": index
              })
            }),
            "typeArguments": {"T": "ScrollNotification"}
          })
        }),
        this._section("ListView.builder（无 itemExtent）：同样懒", "宿主布局到该项时才向 JS 拉取；进入页面只构建可见的几条。"),
        new SizedBox({
          "height": 150,
          "child": ListView.builder({
            "padding": (this.__k2 || (this.__k2 = EdgeInsets.symmetric({
              "horizontal": 8
            }))),
            "itemCount": 20,
            "itemBuilder": (context, index) => new _ListProbeItem({
              "tag": "auto",
              "index": index
            })
          })
        }),
        this._section("ListView.separated：同样懒", "item / separator 分槽拉取；separator 只在对应项进入视口时才构造。"),
        new SizedBox({
          "height": 140,
          "child": ListView.separated({
            "padding": (this.__k2 || (this.__k2 = EdgeInsets.symmetric({
              "horizontal": 8
            }))),
            "itemCount": 22,
            "separatorBuilder": (context, index) => (this.__k3 || (this.__k3 = new Divider({
              "height": 1
            }))),
            "itemBuilder": (context, index) => new _ListProbeItem({
              "tag": "separated",
              "index": index
            })
          })
        }),
        this._section("ListView(children: …)：静态子项", "子项在 build 时已确定，原生与 JS 都一次性构建全部 18 项。"),
        new SizedBox({
          "height": 140,
          "child": new ListView({
            "padding": (this.__k2 || (this.__k2 = EdgeInsets.symmetric({
              "horizontal": 8
            }))),
            "children": [
              ...(() => { var out = []; for (let i = 0; (i < 18); (i++)) { out.push.apply(out, [new _ListProbeItem({
                      "tag": "static",
                      "index": i
                    })]); } return out; })()
            ]
          })
        }),
        this._section("横向 ListView.builder + itemExtent：懒加载", "横向滚动同样只构建可见项。"),
        new SizedBox({
          "height": 76,
          "child": ListView.builder({
            "scrollDirection": Axis.horizontal,
            "padding": (this.__k2 || (this.__k2 = EdgeInsets.symmetric({
              "horizontal": 8
            }))),
            "itemExtent": 132,
            "itemCount": 26,
            "itemBuilder": (context, index) => new _ListProbeItem({
              "tag": "h-lazy",
              "index": index
            })
          })
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        })))
      ]
    });
  }
  _section(title, desc) {
    return new Padding({
      "padding": (this.__k5 || (this.__k5 = EdgeInsets.fromLTRB({
        "bottom": 6,
        "left": 12,
        "right": 12,
        "top": 14
      }))),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.start,
        "children": [
          new Text({
            "style": (this.__k6 || (this.__k6 = new TextStyle({
              "fontSize": 14,
              "fontWeight": FontWeight.bold
            }))),
            "data": title
          }),
          (this.__k7 || (this.__k7 = new SizedBox({
            "height": 2
          }))),
          new Text({
            "style": (this.__k8 || (this.__k8 = new TextStyle({
              "color": Colors.grey,
              "fontSize": 12
            }))),
            "data": desc
          })
        ]
      })
    });
  }
}

// 组件 _ListProbeItem
export class _ListProbeItem extends StatefulWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this._builds = 0;
    this._refreshes = 0;
  }
  __applyProps(args) {
    this.tag = (args && args.tag !== undefined) ? args.tag : '';
    this.index = (args && args.index !== undefined) ? args.index : 0;
  }
  initState() {
    super.initState();
    print("[ListView][" + this.tag + "] initState #" + this.index);
  }
  dispose() {
    print("[ListView][" + this.tag + "] dispose #" + this.index);
    super.dispose();
  }
  _refresh() {
    this.setState(() => {
      this._refreshes += 1;
    });
    print("[ListView][" + this.tag + "] item refresh #" + this.index + " " + "(refreshes=" + this._refreshes + ", builds=" + (this._builds + 1) + ")");
  }
  build(context) {
    this._builds += 1;
    return new InkWell({
      "onTap": () => this._refresh(),
      "child": new Container({
        "alignment": Alignment.centerLeft,
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.symmetric({
          "horizontal": 12,
          "vertical": 6
        }))),
        "child": new Column({
          "mainAxisAlignment": MainAxisAlignment.center,
          "crossAxisAlignment": CrossAxisAlignment.start,
          "children": [
            new Text({
              "style": (this.__k1 || (this.__k1 = new TextStyle({
                "fontSize": 13,
                "fontWeight": FontWeight.w600
              }))),
              "data": this.tag + " #" + this.index
            }),
            new Text({
              "style": (this.__k2 || (this.__k2 = new TextStyle({
                "color": Colors.grey,
                "fontSize": 11
              }))),
              "data": "build " + this._builds + " · 点击刷新 " + this._refreshes
            })
          ]
        })
      })
    });
  }
}

