// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/scroll_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { CommonListItem } from 'list_item.js';
import { Align, Alignment, Axis, BouncingScrollPhysics, Chip, ClampingScrollPhysics, Colors, Column, CrossAxisAlignment, Divider, EdgeInsets, FontWeight, Icon, Icons, ListTile, ListView, NotificationListener, Padding, Row, ScrollController, SingleChildScrollView, SizedBox, StatefulWidget, Text, TextButton, TextStyle } from '../flutter.js';

// 组件 ScrollDetail
export class ScrollDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._offset = 0;
    this._ctrlOffset = 0;
    this._scrollController = new ScrollController();
    this._listSalt = 0;
  }
  initState() {
    super.initState();
    this._scrollController.addListener(() => { this.setState(() => { this._ctrlOffset = this._scrollController.offset; }); });
  }
  dispose() {
    this._scrollController.dispose();
    super.dispose();
  }
  _onListScroll(n) {
    this.setState(() => { this._offset = n.metrics.pixels; });
    return false;
  }
  _scrollToEnd() {
    this._scrollController.jumpTo(this._scrollController.position.maxScrollExtent);
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        new Text({
          "style": (this.__k0 || (this.__k0 = new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          }))),
          "data": "ListView.builder · 懒构建列表（offset: " + this._offset + "）"
        }),
        new NotificationListener({
          "onNotification": this.__bindFn(0, [], (...__a) => this._onListScroll(...__a)),
          "child": new SizedBox({
            "height": 160,
            "child": ListView.builder({
              "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
                "value": 8
              }))),
              "itemExtent": 56,
              "physics": (this.__k2 || (this.__k2 = new BouncingScrollPhysics({}))),
              "itemCount": 20,
              "itemBuilder": (context, index) => new ListTile({
                "leading": (this.__k3 || (this.__k3 = new Icon({
                  "icon": Icons.list
                }))),
                "title": new CommonListItem({
                  "index": index,
                  "salt": this._listSalt
                })
              })
            })
          }),
          "model": "ScrollNotification"
        }),
        new Align({
          "alignment": Alignment.centerLeft,
          "child": new TextButton({
            "onPressed": this.__bindFn(1, [], () => this.setState(() => {
              this._listSalt += 1;
            })),
            "child": (this.__k4 || (this.__k4 = new Text({
              "data": "列表换色（真实更新）"
            })))
          })
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": (this.__k0 || (this.__k0 = new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          }))),
          "data": "ListView.separated · 分隔列表"
        }),
        new SizedBox({
          "height": 140,
          "child": ListView.separated({
            "padding": (this.__k1 || (this.__k1 = EdgeInsets.all({
              "value": 8
            }))),
            "itemCount": 6,
            "separatorBuilder": (context, index) => (this.__k6 || (this.__k6 = new Divider({
              "height": 1
            }))),
            "itemBuilder": (context, index) => new ListTile({
              "dense": true,
              "leading": new Icon({
                "color": Colors.teal.shade300,
                "icon": Icons.arrow_right
              }),
              "title": new Text({
                "data": "separated item " + index
              })
            })
          })
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": (this.__k0 || (this.__k0 = new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          }))),
          "data": "SingleChildScrollView · 长内容滚动（ctrl offset: " + this._ctrlOffset + "）"
        }),
        new SingleChildScrollView({
          "controller": this._scrollController,
          "scrollDirection": Axis.horizontal,
          "physics": (this.__k7 || (this.__k7 = new ClampingScrollPhysics({}))),
          "child": new Row({
            "children": [
              ...(() => { var out = []; for (let i = 1; (i <= 8); (i++)) { out.push.apply(out, [new Padding({
                      "padding": (this.__k8 || (this.__k8 = EdgeInsets.all({
                        "value": 4
                      }))),
                      "child": new Chip({
                        "label": new Text({
                          "data": "横向 " + i
                        })
                      })
                    })]); } return out; })()
            ]
          })
        }),
        new Align({
          "alignment": Alignment.centerLeft,
          "child": new TextButton({
            "onPressed": this.__bindFn(2, [], (...__a) => this._scrollToEnd(...__a)),
            "child": (this.__k9 || (this.__k9 = new Text({
              "data": "横向 · 跳到底"
            })))
          })
        })
      ]
    });
  }
}

