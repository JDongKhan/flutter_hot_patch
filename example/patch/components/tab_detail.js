// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/tab_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Align, Alignment, Center, Colors, Column, CrossAxisAlignment, DefaultTabController, Expanded, FontWeight, SizedBox, Tab, TabBar, TabBarView, TabController, Text, TextButton, TextStyle } from '../flutter.js';

// 组件 TabDetail
export class TabDetail {
  constructor(args) {
    this.props = args || {};
    this._controller = new TabController({length: 3, vsync: this});
    this._index = 0;
  }
  initState() {
    this._controller.addListener(() => { this.setState(() => { this._index = this._controller.index; }); });
  }
  dispose() {
    this._controller.dispose();
  }
  _next() {
    this._controller.animateTo((((this._index + 1)) % 3));
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "DefaultTabController · 官方惯用法（controller 由祖先提供）",
          "style": new TextStyle({
            "fontSize": 15,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 6
        }))),
        new SizedBox({
          "height": 180,
          "child": new DefaultTabController({
            "length": 3,
            "child": new Column({
              "children": [
                new TabBar({
                  "isScrollable": true,
                  "indicatorColor": Colors.deepPurple,
                  "labelColor": Colors.deepPurple,
                  "unselectedLabelColor": Colors.grey,
                  "tabs": [
                    new Tab({
                      "text": "广场"
                    }),
                    new Tab({
                      "text": "推荐"
                    }),
                    new Tab({
                      "text": "关注"
                    })
                  ]
                }),
                new Expanded({
                  "child": new TabBarView({
                    "children": [
                      new Center({
                        "child": new Text({
                          "data": "TabBarView · 广场"
                        })
                      }),
                      new Center({
                        "child": new Text({
                          "data": "TabBarView · 推荐"
                        })
                      }),
                      new Center({
                        "child": new Text({
                          "data": "TabBarView · 关注"
                        })
                      })
                    ]
                  })
                })
              ]
            })
          })
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 14
        }))),
        new Text({
          "style": (this.__k3 || (this.__k3 = new TextStyle({
            "fontSize": 15,
            "fontWeight": FontWeight.bold
          }))),
          "data": "显式 TabController · index = " + this._index
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 6
        }))),
        new SizedBox({
          "height": 170,
          "child": new Column({
            "children": [
              new TabBar({
                "controller": this._controller,
                "tabs": [
                  new Tab({
                    "text": "首页"
                  }),
                  new Tab({
                    "text": "社区"
                  }),
                  new Tab({
                    "text": "我的"
                  })
                ]
              }),
              new Expanded({
                "child": new TabBarView({
                  "controller": this._controller,
                  "children": [
                    new Center({
                      "child": new Text({
                        "data": "第 1 页（index 0）"
                      })
                    }),
                    new Center({
                      "child": new Text({
                        "data": "第 2 页（index 1）"
                      })
                    }),
                    new Center({
                      "child": new Text({
                        "data": "第 3 页（index 2）"
                      })
                    })
                  ]
                })
              })
            ]
          })
        }),
        new Align({
          "alignment": Alignment.centerLeft,
          "child": new TextButton({
            "onPressed": this.__bindFn(0, [], (...__a) => this._next(...__a)),
            "child": (this.__k4 || (this.__k4 = new Text({
              "data": "下一 tab · controller.animateTo"
            })))
          })
        })
      ]
    });
  }
}

