// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/reorder_list_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Card, Colors, Column, EdgeInsets, ElevatedButton, Expanded, Icon, Icons, ListTile, MainAxisSize, Padding, ReorderableListView, Row, ScrollController, SizedBox, StatefulWidget, Text, TextStyle, ValueKey } from '../flutter.js';

// 组件 ReorderListDetail
export class ReorderListDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._items = ["北京", "上海", "广州", "深圳", "杭州", "成都"];
    this._controller = new ScrollController();
  }
  _onReorder(oldIndex, newIndex) {
    print(oldIndex + " - " + newIndex);
    this.setState(() => {
      var item = this._items.removeAt(oldIndex);
      var target = ((newIndex > oldIndex) ? (newIndex - 1) : newIndex);
      this._items.insert(target, item);
    });
  }
  _add() {
    this.setState(() => {
      this._items.add("城市 " + (this._items.length + 1));
    });
  }
  build(context) {
    return new Column({
      "mainAxisSize": MainAxisSize.min,
      "children": [
        new Padding({
          "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
            "value": 12
          }))),
          "child": new Row({
            "children": [
              (this.__k1 || (this.__k1 = new Expanded({
                "child": new Text({
                  "style": new TextStyle({
                    "fontSize": 13,
                    "color": Colors.grey
                  }),
                  "data": "长按拖拽调整顺序（onReorder 双参事件）"
                })
              }))),
              new ElevatedButton({
                "onPressed": () => this._add(),
                "child": (this.__k2 || (this.__k2 = new Text({
                  "data": "添加"
                })))
              })
            ]
          })
        }),
        new SizedBox({
          "height": 320,
          "child": ReorderableListView.builder({
            "scrollController": this._controller,
            "onReorder": (__a0, __a1) => this._onReorder(__a0, __a1),
            "padding": (this.__k3 || (this.__k3 = EdgeInsets.symmetric({
              "horizontal": 12
            }))),
            "itemCount": this._items.length,
            "itemBuilder": (context, index) => {
              var item = this._items[index];
              return new Card({
                "child": new ListTile({
                  "leading": (this.__k4 || (this.__k4 = new Icon({
                    "icon": Icons.drag_handle
                  }))),
                  "title": new Text({
                    "data": item
                  })
                }),
                "key": new ValueKey({value: item})
              });
            }
          })
        })
      ]
    });
  }
  dispose() {
    this._controller.dispose();
    super.dispose();
  }
}

