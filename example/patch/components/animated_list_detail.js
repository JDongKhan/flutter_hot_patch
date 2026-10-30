// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/animated_list_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { AnimatedList, Card, CircleAvatar, Colors, Column, CrossAxisAlignment, Duration, EdgeInsets, Expanded, FontWeight, GlobalKey, ListTile, Row, SizedBox, Text, TextButton, TextStyle } from '../flutter.js';

// 组件 AnimatedListDetail
export class AnimatedListDetail {
  static _insertDuration = new Duration({milliseconds: 350});
  static _removeDuration = new Duration({milliseconds: 300});
  constructor(args) {
    this.props = args || {};
    this._listKey = new GlobalKey({typeArguments: ['AnimatedListState']});
    this._seq = 3;
    this._items = ["条目 1", "条目 2", "条目 3"];
  }
  _itemBuilder(context, index, animation) {
    if (((index < 0) || (index >= this._items.length))) {
      return (this.__k0 || (this.__k0 = SizedBox.shrink({})));
    }
    return new Card({
      "margin": (this.__k1 || (this.__k1 = EdgeInsets.symmetric({
        "vertical": 4
      }))),
      "color": Colors.indigo.shade50,
      "child": new ListTile({
        "dense": true,
        "leading": new CircleAvatar({
          "radius": 12,
          "backgroundColor": Colors.indigo,
          "child": new Text({
            "style": (this.__k2 || (this.__k2 = new TextStyle({
              "color": Colors.white,
              "fontSize": 11
            }))),
            "data": (index + 1)
          })
        }),
        "title": new Text({
          "data": this._items[index]
        })
      })
    });
  }
  _insert() {
    var index = this._items.length;
    this.setState(() => { this._items.add("条目 " + (++this._seq)); });
    var state = this._listKey.currentState;
    state.insertItem(index, { "duration": AnimatedListDetail._insertDuration });
  }
  _removeFirst() {
    if (this._items.isEmpty) {
      return;
    }
    var removed = this._items.removeAt(0);
    this.setState(() => {});
    var state = this._listKey.currentState;
    state.removeItem(0, (context, animation) => { return new Card({
        "margin": (this.__k1 || (this.__k1 = EdgeInsets.symmetric({
          "vertical": 4
        }))),
        "color": Colors.indigo.shade50,
        "child": new ListTile({
          "dense": true,
          "leading": new CircleAvatar({
            "radius": 12,
            "backgroundColor": Colors.indigo,
            "child": new Text({
              "style": (this.__k2 || (this.__k2 = new TextStyle({
                "color": Colors.white,
                "fontSize": 11
              }))),
              "data": "1"
            })
          }),
          "title": new Text({
            "data": removed
          })
        })
      }); }, { "duration": AnimatedListDetail._removeDuration });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k3 || (this.__k3 = new Text({
          "data": "AnimatedList · 增删补间（GlobalKey.currentState）",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 8
        }))),
        new SizedBox({
          "height": 260,
          "child": new AnimatedList({
            "initialItemCount": this._items.length,
            "itemBuilder": (...__a) => this._itemBuilder(...__a),
            "key": this._listKey
          })
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 8
        }))),
        new Row({
          "children": [
            new Expanded({
              "child": new TextButton({
                "onPressed": this.__bindFn(0, [], (...__a) => this._insert(...__a)),
                "child": (this.__k5 || (this.__k5 = new Text({
                  "data": "插入末尾（350ms）"
                })))
              })
            }),
            new Expanded({
              "child": new TextButton({
                "onPressed": this.__bindFn(1, [], (...__a) => this._removeFirst(...__a)),
                "child": (this.__k6 || (this.__k6 = new Text({
                  "data": "移除第一项（300ms）"
                })))
              })
            })
          ]
        })
      ]
    });
  }
}

