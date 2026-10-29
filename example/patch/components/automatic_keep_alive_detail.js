// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/automatic_keep_alive_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, Column, DefaultTabController, EdgeInsets, ElevatedButton, Expanded, FontWeight, Padding, SizedBox, Tab, TabBar, TabBarView, Text, TextStyle } from '../flutter.js';

// 组件 AutomaticKeepAliveDetail
export class AutomaticKeepAliveDetail {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new DefaultTabController({
      "length": 2,
      "child": new SizedBox({
        "height": 320,
        "child": new Column({
          "crossAxisAlignment": "stretch",
          "children": [
            (this.__k0 || (this.__k0 = new Text({
              "data": "先点「+1」再看：切到另一页，然后切回来对比计数",
              "style": new TextStyle({
                "fontSize": 13,
                "color": Colors.black54
              })
            }))),
            (this.__k1 || (this.__k1 = new SizedBox({
              "height": 8
            }))),
            new TabBar({
              "tabs": [
                (this.__k2 || (this.__k2 = new Tab({
                  "text": "保活页"
                }))),
                (this.__k3 || (this.__k3 = new Tab({
                  "text": "不保活页"
                })))
              ]
            }),
            new Expanded({
              "child": new TabBarView({
                "children": [
                  (this.__k4 || (this.__k4 = new _KeepAlivePage({}))),
                  (this.__k5 || (this.__k5 = new _PlainPage({})))
                ]
              })
            })
          ]
        })
      })
    });
  }
}

// 组件 _PlainPage
export class _PlainPage {
  constructor(args) {
    this.props = args || {};
    this._count = 0;
  }
  build(context) {
    return new Padding({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
        "value": 12
      }))),
      "child": new Column({
        "crossAxisAlignment": "start",
        "children": [
          (this.__k1 || (this.__k1 = new Text({
            "data": "不保活页 · 未声明 wantKeepAlive",
            "style": new TextStyle({
              "fontWeight": FontWeight.bold
            })
          }))),
          (this.__k2 || (this.__k2 = new SizedBox({
            "height": 4
          }))),
          (this.__k3 || (this.__k3 = new Text({
            "data": "切走再回来：计数归零",
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.black54
            })
          }))),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 12
          }))),
          new Text({
            "style": (this.__k5 || (this.__k5 = new TextStyle({
              "fontSize": 20
            }))),
            "data": "当前计数：" + this._count
          }),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          new ElevatedButton({
            "onPressed": this.__bindFn(0, [], () => this.setState(() => {
              this._count += 1;
            })),
            "child": (this.__k7 || (this.__k7 = new Text({
              "data": "+1"
            })))
          })
        ]
      })
    });
  }
}

// 组件 _KeepAlivePage
export class _KeepAlivePage {
  constructor(args) {
    this.props = args || {};
    this._count = 0;
  }
  get wantKeepAlive() {
    return true;
  }
  build(context) {
    return new Padding({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
        "value": 12
      }))),
      "child": new Column({
        "crossAxisAlignment": "start",
        "children": [
          (this.__k1 || (this.__k1 = new Text({
            "data": "保活页 · wantKeepAlive = true",
            "style": new TextStyle({
              "fontWeight": FontWeight.bold
            })
          }))),
          (this.__k2 || (this.__k2 = new SizedBox({
            "height": 4
          }))),
          (this.__k3 || (this.__k3 = new Text({
            "data": "切走再回来：计数保留",
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.black54
            })
          }))),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 12
          }))),
          new Text({
            "style": (this.__k5 || (this.__k5 = new TextStyle({
              "fontSize": 20
            }))),
            "data": "当前计数：" + this._count
          }),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          new ElevatedButton({
            "onPressed": this.__bindFn(0, [], () => this.setState(() => {
              this._count += 1;
            })),
            "child": (this.__k7 || (this.__k7 = new Text({
              "data": "+1"
            })))
          })
        ]
      })
    });
  }
}

