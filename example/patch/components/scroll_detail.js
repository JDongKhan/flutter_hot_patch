// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/scroll_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Align, Alignment, Axis, Chip, ClampingScrollPhysics, Colors, Column, CrossAxisAlignment, EdgeInsets, FontWeight, Padding, Row, ScrollController, SingleChildScrollView, SizedBox, StatefulWidget, Text, TextButton, TextStyle } from '../flutter.js';

// 组件 ScrollDetail
export class ScrollDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._ctrlOffset = 0;
    this._scrollController = new ScrollController();
  }
  initState() {
    super.initState();
    this._scrollController.addListener(() => { this.setState(() => {
        this._ctrlOffset = this._scrollController.offset;
      }); });
  }
  dispose() {
    this._scrollController.dispose();
    super.dispose();
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
          "data": "SingleChildScrollView · 横向滚动（ctrl offset: " + this._ctrlOffset.toStringAsFixed(1) + "）"
        }),
        new SingleChildScrollView({
          "controller": this._scrollController,
          "scrollDirection": Axis.horizontal,
          "physics": (this.__k1 || (this.__k1 = new ClampingScrollPhysics({}))),
          "child": new Row({
            "children": [
              ...(() => { var out = []; for (let i = 1; (i <= 12); (i++)) { out.push.apply(out, [new Padding({
                      "padding": (this.__k2 || (this.__k2 = EdgeInsets.all({
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
            "onPressed": () => this._scrollToEnd(),
            "child": (this.__k3 || (this.__k3 = new Text({
              "data": "横向 · 跳到底"
            })))
          })
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 16
        }))),
        (this.__k5 || (this.__k5 = new Padding({
          "child": new Text({
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.grey
            }),
            "data": "ListView 的各种用法（children / builder / separated / itemExtent 懒加载）" + "已集中到「ListView」demo。"
          }),
          "padding": EdgeInsets.symmetric({
            "horizontal": 12
          })
        })))
      ]
    });
  }
}

