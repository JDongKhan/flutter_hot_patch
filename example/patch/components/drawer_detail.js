// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/drawer_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Align, Alignment, AppBar, BoxDecoration, Center, Colors, Column, Drawer, DrawerHeader, Icon, Icons, ListTile, ListView, MainAxisAlignment, Scaffold, SizedBox, StatefulWidget, Text, TextStyle } from '../flutter.js';

// 组件 DrawerDetail
export class DrawerDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._picked = (-1);
  }
  _pickOrders() {
    this.setState(() => { this._picked = 0; });
  }
  _pickFavorites() {
    this.setState(() => { this._picked = 1; });
  }
  _pickSettings() {
    this.setState(() => { this._picked = 2; });
  }
  _pickHelp() {
    this.setState(() => { this._picked = 3; });
  }
  build(context) {
    return new Scaffold({
      "backgroundColor": Colors.grey.shade50,
      "appBar": new AppBar({
        "title": (this.__k0 || (this.__k0 = new Text({
          "data": "Drawer / endDrawer"
        }))),
        "backgroundColor": Colors.indigo,
        "foregroundColor": Colors.white
      }),
      "drawer": new Drawer({
        "child": new ListView({
          "children": [
            new DrawerHeader({
              "decoration": (this.__k1 || (this.__k1 = new BoxDecoration({
                "color": Colors.indigo
              }))),
              "child": (this.__k2 || (this.__k2 = new Align({
                "alignment": Alignment.bottomLeft,
                "child": new Text({
                  "style": new TextStyle({
                    "color": Colors.white,
                    "fontSize": 20
                  }),
                  "data": "左侧抽屉"
                })
              })))
            }),
            new ListTile({
              "leading": (this.__k3 || (this.__k3 = new Icon({
                "icon": Icons.receipt_long
              }))),
              "title": (this.__k4 || (this.__k4 = new Text({
                "data": "我的订单"
              }))),
              "onTap": this.__bindFn(0, [], (...__a) => this._pickOrders(...__a))
            }),
            new ListTile({
              "leading": (this.__k5 || (this.__k5 = new Icon({
                "icon": Icons.favorite_border
              }))),
              "title": (this.__k6 || (this.__k6 = new Text({
                "data": "我的收藏"
              }))),
              "onTap": this.__bindFn(1, [], (...__a) => this._pickFavorites(...__a))
            })
          ]
        })
      }),
      "endDrawer": new Drawer({
        "child": new ListView({
          "children": [
            new DrawerHeader({
              "decoration": (this.__k7 || (this.__k7 = new BoxDecoration({
                "color": Colors.teal
              }))),
              "child": (this.__k8 || (this.__k8 = new Align({
                "alignment": Alignment.bottomLeft,
                "child": new Text({
                  "style": new TextStyle({
                    "color": Colors.white,
                    "fontSize": 20
                  }),
                  "data": "右侧抽屉"
                })
              })))
            }),
            new ListTile({
              "leading": (this.__k9 || (this.__k9 = new Icon({
                "icon": Icons.settings
              }))),
              "title": (this.__k10 || (this.__k10 = new Text({
                "data": "设置"
              }))),
              "onTap": this.__bindFn(2, [], (...__a) => this._pickSettings(...__a))
            }),
            new ListTile({
              "leading": (this.__k11 || (this.__k11 = new Icon({
                "icon": Icons.help_outline
              }))),
              "title": (this.__k12 || (this.__k12 = new Text({
                "data": "帮助与关于"
              }))),
              "onTap": this.__bindFn(3, [], (...__a) => this._pickHelp(...__a))
            })
          ]
        })
      }),
      "body": new Center({
        "child": new Column({
          "mainAxisAlignment": MainAxisAlignment.center,
          "children": [
            (this.__k13 || (this.__k13 = new Icon({
              "color": Colors.indigo,
              "icon": Icons.menu_open,
              "size": 48
            }))),
            (this.__k14 || (this.__k14 = new SizedBox({
              "height": 12
            }))),
            (this.__k15 || (this.__k15 = new Text({
              "data": "AppBar 左侧为汉堡按钮，右侧为 endDrawer 入口"
            }))),
            (this.__k16 || (this.__k16 = new SizedBox({
              "height": 8
            }))),
            new Text({
              "data": (this._picked < 0) ? "尚未选择菜单项" : "选中菜单项 #" + this._picked
            })
          ]
        })
      })
    });
  }
}

