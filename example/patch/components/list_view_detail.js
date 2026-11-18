// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/list_view_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, Axis, Colors, Column, Container, CrossAxisAlignment, Divider, EdgeInsets, ElevatedButton, FontWeight, InkWell, ListView, MainAxisAlignment, NotificationListener, Padding, SizedBox, StatefulWidget, Text, TextStyle } from '../flutter.js';

// 组件 ListViewDetail
export class ListViewDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._lazyOffset = 0;
    this._listBuilds = 0;
    this._rows = [...(() => {
        const __r = [];
        for (let i = 0; (i < 20); (i++)) {
          __r.push(...["row-" + i]);
        }
        return __r;
      })()];
    this._apiTick = 0;
  }
  _onLazyScroll(n) {
    this.setState(() => {
      this._lazyOffset = n.metrics.pixels;
    });
    return false;
  }
  _refreshFromApi() {
    this._apiTick += 1;
    this.setState(() => {
      for (let i = 0; (i < this._rows.length); (i++)) {
        this._rows[i] = "接口 v" + this._apiTick + " · 行 " + i;
      }
    });
    print("[ListView] api refresh v" + this._apiTick + "（条目数 " + this._rows.length + " 未变）");
  }
  _onRowTap(index) {
    this.setState(() => {
      this._rows[index] = "已点击 · 行 " + index + " · v" + this._apiTick;
    });
    print("[ListView] model change #" + index + " -> \"" + this._rows[index] + "\"");
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
          "child": new Column({
            "crossAxisAlignment": CrossAxisAlignment.start,
            "children": [
              new Text({
                "style": (this.__k1 || (this.__k1 = new TextStyle({
                  "fontSize": 12
                }))),
                "data": "父级 build 次数：" + this._listBuilds + "（item 长按刷新时不应变化）。" + "日志：initState = 首次挂载，dispose = 滚出缓存被回收。"
              }),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 6
              }))),
              new ElevatedButton({
                "onPressed": () => this._refreshFromApi(),
                "child": (this.__k3 || (this.__k3 = new Text({
                  "data": "模拟接口刷新（条目数不变，只换内容）"
                })))
              })
            ]
          })
        }),
        this._section("ListView.builder + itemExtent：懒加载（offset: " + this._lazyOffset.toStringAsFixed(1) + "）", "只构建可见项；滚动时逐项 initState，离屏回收 dispose。"),
        new SizedBox({
          "height": 180,
          "child": new NotificationListener({
            "onNotification": (__a0) => this._onLazyScroll(__a0),
            "child": ListView.builder({
              "padding": (this.__k4 || (this.__k4 = EdgeInsets.symmetric({
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
        this._section("ListView.builder（无 itemExtent）：同样懒 · 接模型数据", "短按改父级模型（滚走再滚回应显示新值）；长按只刷新自身。"),
        new SizedBox({
          "height": 150,
          "child": ListView.builder({
            "padding": (this.__k4 || (this.__k4 = EdgeInsets.symmetric({
              "horizontal": 8
            }))),
            "itemCount": this._rows.length,
            "itemBuilder": (context, index) => new _ListProbeItem({
              "tag": "auto",
              "index": index,
              "label": this._rows[index],
              "onTap": () => { return this._onRowTap(index); }
            })
          })
        }),
        this._section("ListView.separated：同样懒", "item / separator 分槽拉取；separator 只在对应项进入视口时才构造。"),
        new SizedBox({
          "height": 140,
          "child": ListView.separated({
            "padding": (this.__k4 || (this.__k4 = EdgeInsets.symmetric({
              "horizontal": 8
            }))),
            "itemCount": 22,
            "separatorBuilder": (context, index) => (this.__k5 || (this.__k5 = new Divider({
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
            "padding": (this.__k4 || (this.__k4 = EdgeInsets.symmetric({
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
            "padding": (this.__k4 || (this.__k4 = EdgeInsets.symmetric({
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
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 12
        })))
      ]
    });
  }
  _section(title, desc) {
    return new Padding({
      "padding": (this.__k7 || (this.__k7 = EdgeInsets.fromLTRB({
        "bottom": 6,
        "left": 12,
        "right": 12,
        "top": 14
      }))),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.start,
        "children": [
          new Text({
            "style": (this.__k8 || (this.__k8 = new TextStyle({
              "fontSize": 14,
              "fontWeight": FontWeight.bold
            }))),
            "data": title
          }),
          (this.__k9 || (this.__k9 = new SizedBox({
            "height": 2
          }))),
          new Text({
            "style": (this.__k10 || (this.__k10 = new TextStyle({
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
    this.label = (args && args.label !== undefined) ? args.label : null;
    this.onTap = (args && args.onTap !== undefined) ? args.onTap : null;
  }
  initState() {
    super.initState();
    print("[ListView][" + this.tag + "] initState #" + this.index);
  }
  dispose() {
    print("[ListView][" + this.tag + "] dispose #" + this.index);
    super.dispose();
  }
  _localRefresh() {
    this.setState(() => {
      this._refreshes += 1;
    });
    print("[ListView][" + this.tag + "] local refresh #" + this.index + " " + "(refreshes=" + this._refreshes + ", builds=" + (this._builds + 1) + ")");
  }
  _handleTap() {
    const onTap = this.onTap;
    if ((__nn(onTap) != null)) {
      onTap();
    } else {
      this._localRefresh();
    }
  }
  build(context) {
    this._builds += 1;
    return new InkWell({
      "onTap": () => this._handleTap(),
      "onLongPress": () => this._localRefresh(),
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
              "data": (this.label ?? this.tag + " #" + this.index)
            }),
            new Text({
              "style": (this.__k2 || (this.__k2 = new TextStyle({
                "color": Colors.grey,
                "fontSize": 11
              }))),
              "data": "build " + this._builds + " · 长按刷新 " + this._refreshes
            })
          ]
        })
      })
    });
  }
}

