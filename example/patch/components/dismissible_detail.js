// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/dismissible_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Align, Colors, Column, Container, DismissDirection, Dismissible, Icon, ListTile, OutlinedButton, SizedBox, Text, ValueKey } from '../flutter.js';

// 组件 DismissibleDetail
export class DismissibleDetail {
  constructor(args) {
    this.props = args || {};
    this._items = ["第一条：左滑删除，右滑弹回", "第二条：试试右滑，会被拒绝", "第三条：删光后点「重置」"];
    this._last = "还没有条目被删除";
  }
  async _confirm(direction) {
    return (direction == DismissDirection.endToStart);
  }
  _reset() {
    this.setState(() => { this._items = ["第一条：左滑删除，右滑弹回", "第二条：试试右滑，会被拒绝", "第三条：删光后点「重置」"]; this._last = "还没有条目被删除"; });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Dismissible",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "左滑删除；右滑被 confirmDismiss 拒绝后弹回",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        ...(() => { var out = []; for (let item of this._items) { out.push.apply(out, [new Dismissible({
                "direction": "horizontal",
                "confirmDismiss": this.__bindFn(0, [], (...__a) => this._confirm(...__a)),
                "background": new Container({
                  "color": Colors.red,
                  "alignment": "centerLeft",
                  "padding": {
                    "left": 20.0,
                    "top": 0.0,
                    "right": 20.0,
                    "bottom": 0.0
                  },
                  "child": (this.__k4 || (this.__k4 = new Icon({
                    "color": Colors.white,
                    "icon": "delete_outline"
                  })))
                }),
                "secondaryBackground": new Container({
                  "color": Colors.blueGrey,
                  "alignment": "centerRight",
                  "padding": {
                    "left": 20.0,
                    "top": 0.0,
                    "right": 20.0,
                    "bottom": 0.0
                  },
                  "child": (this.__k5 || (this.__k5 = new Icon({
                    "color": Colors.white,
                    "icon": "block"
                  })))
                }),
                "onDismissed": this.__bindFn(1, [item], (direction) => { this.setState(() => { this._items.remove(item); this._last = "已删除：" + item; }); }),
                "child": new Container({
                  "color": Colors.white,
                  "child": new ListTile({
                    "title": new Text({
                      "data": item
                    })
                  })
                }),
                "key": new ValueKey({value: item, typeArguments: ['String']})
              })]); } return out; })(),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": {
            "fontSize": 12,
            "color": Colors.black54
          },
          "data": this._last
        }),
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 8
        }))),
        new Align({
          "alignment": "centerLeft",
          "child": new OutlinedButton({
            "onPressed": this.__bindFn(2, [], (...__a) => this._reset(...__a)),
            "child": (this.__k7 || (this.__k7 = new Text({
              "data": "重置"
            })))
          })
        })
      ]
    });
  }
}

