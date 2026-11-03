// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/page_view_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, BoxDecoration, BoxShape, Color, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, FontWeight, MainAxisAlignment, PageController, PageView, Row, SizedBox, StatefulWidget, Text, TextButton, TextStyle } from '../flutter.js';

// 组件 PageViewDetail
export class PageViewDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._page = 0;
    this._pageController = new PageController({initialPage: 0});
  }
  _onPageChanged(index) {
    this.setState(() => { this._page = index; });
  }
  _prevPage() {
    if ((this._page > 0)) {
      this._pageController.jumpToPage((this._page - 1));
    }
  }
  _nextPage() {
    if ((this._page < 2)) {
      this._pageController.jumpToPage((this._page + 1));
    }
  }
  _jumpToLast() {
    this._pageController.jumpToPage(2);
  }
  dispose() {
    this._pageController.dispose();
    super.dispose();
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        new Text({
          "style": (this.__k0 || (this.__k0 = new TextStyle({
            "fontSize": 15,
            "fontWeight": FontWeight.bold
          }))),
          "data": "PageView · 当前第 " + (this._page + 1) + " / 3 页"
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 6
        }))),
        new SizedBox({
          "height": 150,
          "child": new PageView({
            "controller": this._pageController,
            "onPageChanged": (__a0) => this._onPageChanged(__a0),
            "children": [
              new Container({
                "color": Colors.deepPurple.shade100,
                "alignment": Alignment.center,
                "child": (this.__k2 || (this.__k2 = new Text({
                  "data": "第 1 页"
                })))
              }),
              new Container({
                "color": Colors.teal.shade100,
                "alignment": Alignment.center,
                "child": (this.__k3 || (this.__k3 = new Text({
                  "data": "第 2 页"
                })))
              }),
              new Container({
                "color": Colors.orange.shade100,
                "alignment": Alignment.center,
                "child": (this.__k4 || (this.__k4 = new Text({
                  "data": "第 3 页"
                })))
              })
            ]
          })
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 10
        }))),
        new Row({
          "mainAxisAlignment": MainAxisAlignment.center,
          "children": [
            ...(() => { var out = []; for (let i = 0; (i < 3); (i++)) { out.push.apply(out, [new Container({
                    "width": 9,
                    "height": 9,
                    "margin": (this.__k6 || (this.__k6 = EdgeInsets.all({
                      "value": 4
                    }))),
                    "decoration": new BoxDecoration({
                      "shape": BoxShape.circle,
                      "color": (i == this._page) ? Colors.deepPurple : (this.__k7 || (this.__k7 = new Color({
                        "value": 0xFFBDBDBD
                      })))
                    })
                  })]); } return out; })()
          ]
        }),
        (this.__k8 || (this.__k8 = new SizedBox({
          "height": 8
        }))),
        new Row({
          "mainAxisAlignment": MainAxisAlignment.center,
          "children": [
            new TextButton({
              "onPressed": () => this._prevPage(),
              "child": (this.__k9 || (this.__k9 = new Text({
                "data": "上一页"
              })))
            }),
            new TextButton({
              "onPressed": () => this._nextPage(),
              "child": (this.__k10 || (this.__k10 = new Text({
                "data": "下一页"
              })))
            }),
            new TextButton({
              "onPressed": () => this._jumpToLast(),
              "child": (this.__k11 || (this.__k11 = new Text({
                "data": "跳到第 3 页"
              })))
            })
          ]
        })
      ]
    });
  }
}

