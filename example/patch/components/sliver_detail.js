// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/sliver_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, BorderRadius, BouncingScrollPhysics, BoxDecoration, Center, Colors, Container, CustomScrollView, Divider, EdgeInsets, FloatingActionButton, FontWeight, GlobalKey, Icon, IconButton, Icons, ListTile, Scaffold, ScrollController, SliverAppBar, SliverFillRemaining, SliverFixedExtentList, SliverGrid, SliverGridDelegateWithMaxCrossAxisExtent, SliverList, SliverOpacity, SliverPadding, SliverSafeArea, SliverToBoxAdapter, StatefulWidget, Text, TextStyle } from '../flutter.js';

// 组件 SliverDetail
export class SliverDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._controller = new ScrollController();
    this._offset = 0;
    this._fixedKey = new GlobalKey();
    this._measureText = "未测量";
  }
  initState() {
    super.initState();
    this._controller.addListener(() => { this.setState(() => { this._offset = this._controller.offset; }); });
  }
  dispose() {
    this._controller.dispose();
    super.dispose();
  }
  _scrollToEnd() {
    this._controller.jumpTo(this._controller.position.maxScrollExtent);
  }
  _scrollToFixed() {
    var ctx = this._fixedKey.currentContext;
    if ((ctx == null)) {
      return;
    }
    var target = ctx.findRenderObject();
    if ((target == null)) {
      return;
    }
    target.showOnScreen();
  }
  async _measureFixed() {
    var ctx = this._fixedKey.currentContext;
    if ((ctx == null)) {
      return;
    }
    var box = ctx.findRenderObject();
    if ((box == null)) {
      return;
    }
    var rect = await box.measure();
    if ((rect == null)) {
      this.setState(() => { this._measureText = "量不到（未布局）"; });
      return;
    }
    this.setState(() => { this._measureText = "x=" + rect.dx.toStringAsFixed(1) + " y=" + rect.dy.toStringAsFixed(1) + " · " + rect.width.toStringAsFixed(0) + " × " + rect.height.toStringAsFixed(0); });
  }
  build(context) {
    return new Scaffold({
      "body": new CustomScrollView({
        "controller": this._controller,
        "physics": (this.__k0 || (this.__k0 = new BouncingScrollPhysics({}))),
        "slivers": [
          new SliverAppBar({
            "title": new Text({
              "data": "SliverAppBar 导航 · offset " + this._offset.toStringAsFixed(0)
            }),
            "backgroundColor": Colors.deepPurple,
            "foregroundColor": Colors.white,
            "pinned": true,
            "floating": true,
            "actions": [
              new IconButton({
                "icon": (this.__k1 || (this.__k1 = new Icon({
                  "icon": Icons.center_focus_strong
                }))),
                "tooltip": "定位到「固定高度」分区",
                "onPressed": () => this._scrollToFixed()
              }),
              new IconButton({
                "icon": (this.__k2 || (this.__k2 = new Icon({
                  "icon": Icons.straighten
                }))),
                "tooltip": "测量「固定高度」分区的位置与尺寸",
                "onPressed": () => this._measureFixed()
              })
            ]
          }),
          new SliverToBoxAdapter({
            "child": new Container({
              "margin": (this.__k3 || (this.__k3 = EdgeInsets.all({
                "value": 12
              }))),
              "padding": (this.__k4 || (this.__k4 = EdgeInsets.all({
                "value": 16
              }))),
              "decoration": new BoxDecoration({
                "color": Colors.deepPurple.shade50,
                "borderRadius": BorderRadius.circular({
                  "radius": 12
                })
              }),
              "child": (this.__k5 || (this.__k5 = new Text({
                "data": "CustomScrollView 整页 · SliverToBoxAdapter 盒子",
                "style": new TextStyle({
                  "fontSize": 14,
                  "fontWeight": FontWeight.bold
                })
              })))
            })
          }),
          new SliverToBoxAdapter({
            "child": new Container({
              "margin": (this.__k6 || (this.__k6 = EdgeInsets.fromLTRB({
                "bottom": 4,
                "left": 12,
                "right": 12,
                "top": 0
              }))),
              "padding": (this.__k7 || (this.__k7 = EdgeInsets.all({
                "value": 10
              }))),
              "decoration": new BoxDecoration({
                "color": Colors.teal.shade50,
                "borderRadius": BorderRadius.circular({
                  "radius": 8
                })
              }),
              "child": new Text({
                "style": (this.__k8 || (this.__k8 = new TextStyle({
                  "color": Colors.teal,
                  "fontSize": 13
                }))),
                "data": "GlobalKey 测量：「固定高度」分区 " + this._measureText
              })
            })
          }),
          new SliverPadding({
            "padding": (this.__k9 || (this.__k9 = EdgeInsets.symmetric({
              "horizontal": 12
            }))),
            "sliver": new SliverList({
              "delegate": {
                "__delegate": "list",
                "children": [
                  ...(() => { var out = []; for (let i = 1; (i <= 5); (i++)) { out.push.apply(out, [new ListTile({
                          "leading": (this.__k10 || (this.__k10 = new Icon({
                            "color": Colors.deepPurple,
                            "icon": Icons.list
                          }))),
                          "title": new Text({
                            "data": "SliverList item " + i
                          }),
                          "trailing": (this.__k11 || (this.__k11 = new Icon({
                            "icon": Icons.chevron_right
                          })))
                        })]); } return out; })()
                ]
              }
            })
          }),
          new SliverPadding({
            "padding": (this.__k12 || (this.__k12 = EdgeInsets.symmetric({
              "horizontal": 12,
              "vertical": 8
            }))),
            "sliver": new SliverToBoxAdapter({
              "child": new Text({
                "style": (this.__k13 || (this.__k13 = new TextStyle({
                  "fontSize": 14,
                  "fontWeight": FontWeight.bold
                }))),
                "data": "SliverList.builder · 懒构建列表"
              })
            })
          }),
          new SliverPadding({
            "padding": (this.__k9 || (this.__k9 = EdgeInsets.symmetric({
              "horizontal": 12
            }))),
            "sliver": SliverList.builder({
              "itemCount": 8,
              "itemBuilder": (context, index) => new ListTile({
                "leading": new Icon({
                  "color": Colors.orange.shade700,
                  "icon": Icons.build
                }),
                "title": new Text({
                  "data": "builder item " + index
                }),
                "subtitle": new Text({
                  "data": "index * 10 = " + (index * 10)
                })
              })
            })
          }),
          new SliverPadding({
            "padding": (this.__k12 || (this.__k12 = EdgeInsets.symmetric({
              "horizontal": 12,
              "vertical": 8
            }))),
            "sliver": new SliverToBoxAdapter({
              "child": new Text({
                "style": (this.__k13 || (this.__k13 = new TextStyle({
                  "fontSize": 14,
                  "fontWeight": FontWeight.bold
                }))),
                "data": "SliverList.separated · 分隔列表"
              })
            })
          }),
          new SliverPadding({
            "padding": (this.__k9 || (this.__k9 = EdgeInsets.symmetric({
              "horizontal": 12
            }))),
            "sliver": SliverList.separated({
              "itemCount": 5,
              "itemBuilder": (context, index) => new ListTile({
                "dense": true,
                "leading": (this.__k14 || (this.__k14 = new Icon({
                  "color": Colors.deepPurple,
                  "icon": Icons.arrow_right
                }))),
                "title": new Text({
                  "data": "separated item " + index
                })
              }),
              "separatorBuilder": (context, index) => (this.__k15 || (this.__k15 = new Divider({
                "height": 1
              })))
            })
          }),
          new SliverPadding({
            "padding": (this.__k12 || (this.__k12 = EdgeInsets.symmetric({
              "horizontal": 12,
              "vertical": 8
            }))),
            "sliver": new SliverToBoxAdapter({
              "child": new Container({
                "padding": (this.__k16 || (this.__k16 = EdgeInsets.symmetric({
                  "horizontal": 10,
                  "vertical": 8
                }))),
                "decoration": new BoxDecoration({
                  "color": Colors.teal.shade50,
                  "borderRadius": BorderRadius.circular({
                    "radius": 6
                  })
                }),
                "child": new Text({
                  "style": (this.__k13 || (this.__k13 = new TextStyle({
                    "fontSize": 14,
                    "fontWeight": FontWeight.bold
                  }))),
                  "data": "SliverFixedExtentList · 固定高度"
                }),
                "key": this._fixedKey
              })
            })
          }),
          new SliverPadding({
            "padding": (this.__k9 || (this.__k9 = EdgeInsets.symmetric({
              "horizontal": 12
            }))),
            "sliver": new SliverFixedExtentList({
              "itemExtent": 44,
              "delegate": {
                "__delegate": "builder",
                "builder": (context, index) => new ListTile({
                  "dense": true,
                  "leading": (this.__k17 || (this.__k17 = new Icon({
                    "color": Colors.teal,
                    "icon": Icons.height
                  }))),
                  "title": new Text({
                    "data": "fixed item " + index
                  })
                }),
                "childCount": 6
              }
            })
          }),
          new SliverPadding({
            "padding": (this.__k12 || (this.__k12 = EdgeInsets.symmetric({
              "horizontal": 12,
              "vertical": 8
            }))),
            "sliver": new SliverToBoxAdapter({
              "child": new Text({
                "style": (this.__k13 || (this.__k13 = new TextStyle({
                  "fontSize": 14,
                  "fontWeight": FontWeight.bold
                }))),
                "data": "SliverOpacity + SliverGrid.builder · MaxCrossAxisExtent 九宫格"
              })
            })
          }),
          new SliverOpacity({
            "opacity": 0.6,
            "sliver": new SliverPadding({
              "padding": (this.__k9 || (this.__k9 = EdgeInsets.symmetric({
                "horizontal": 12
              }))),
              "sliver": SliverGrid.builder({
                "gridDelegate": (this.__k18 || (this.__k18 = new SliverGridDelegateWithMaxCrossAxisExtent({
                  "childAspectRatio": 1,
                  "crossAxisSpacing": 8,
                  "mainAxisSpacing": 8,
                  "maxCrossAxisExtent": 140
                }))),
                "itemCount": 9,
                "itemBuilder": (context, index) => new Container({
                  "decoration": new BoxDecoration({
                    "color": Colors.teal.shade100,
                    "borderRadius": BorderRadius.circular({
                      "radius": 8
                    })
                  }),
                  "alignment": Alignment.center,
                  "child": new Text({
                    "style": (this.__k19 || (this.__k19 = new TextStyle({
                      "fontWeight": FontWeight.bold
                    }))),
                    "data": "格 " + index
                  })
                })
              })
            })
          }),
          new SliverSafeArea({
            "sliver": new SliverFillRemaining({
              "hasScrollBody": false,
              "child": new Center({
                "child": new Text({
                  "style": (this.__k20 || (this.__k20 = new TextStyle({
                    "color": Colors.grey
                  }))),
                  "data": "底部 · SliverSafeArea + SliverFillRemaining"
                })
              })
            })
          })
        ]
      }),
      "floatingActionButton": new FloatingActionButton({
        "onPressed": () => this._scrollToEnd(),
        "backgroundColor": Colors.deepPurple,
        "foregroundColor": Colors.white,
        "tooltip": "跳到底",
        "child": (this.__k21 || (this.__k21 = new Icon({
          "icon": Icons.arrow_downward
        })))
      })
    });
  }
}

