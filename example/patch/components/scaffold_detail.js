// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/scaffold_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { AppBar, BottomNavigationBar, BottomNavigationBarItem, Center, Colors, Column, FloatingActionButton, Icon, Icons, MainAxisAlignment, SafeArea, Scaffold, SizedBox, StatefulWidget, Text } from '../flutter.js';

// 组件 ScaffoldDetail
export class ScaffoldDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._navIndex = 0;
  }
  _onNavTap(index) {
    this.setState(() => {
      this._navIndex = index;
    });
  }
  _onFab() {
  }
  build(context) {
    return new Scaffold({
      "backgroundColor": Colors.grey.shade50,
      "appBar": new AppBar({
        "leading": (this.__k0 || (this.__k0 = new Icon({
          "icon": Icons.menu
        }))),
        "title": (this.__k1 || (this.__k1 = new Text({
          "data": "Scaffold / AppBar / FAB / BottomNav"
        }))),
        "backgroundColor": Colors.deepPurple,
        "foregroundColor": Colors.white,
        "elevation": 4,
        "centerTitle": true,
        "toolbarHeight": 56,
        "actions": [
          new Icon({
            "color": Colors.white,
            "icon": Icons.search
          }),
          new SizedBox({
            "width": 16
          })
        ]
      }),
      "body": new SafeArea({
        "child": new Center({
          "child": new Column({
            "mainAxisAlignment": MainAxisAlignment.center,
            "children": [
              (this.__k2 || (this.__k2 = new Icon({
                "color": Colors.deepPurple,
                "icon": Icons.extension,
                "size": 48
              }))),
              (this.__k3 || (this.__k3 = new SizedBox({
                "height": 12
              }))),
              (this.__k4 || (this.__k4 = new Text({
                "data": "页面骨架组件演示"
              }))),
              new Text({
                "data": "BottomNav 选中：" + this._navIndex
              })
            ]
          })
        })
      }),
      "floatingActionButton": new FloatingActionButton({
        "onPressed": () => this._onFab(),
        "backgroundColor": Colors.deepPurple,
        "foregroundColor": Colors.white,
        "tooltip": "添加",
        "child": (this.__k5 || (this.__k5 = new Icon({
          "icon": Icons.add
        })))
      }),
      "bottomNavigationBar": new BottomNavigationBar({
        "currentIndex": this._navIndex,
        "onTap": (__a0) => this._onNavTap(__a0),
        "selectedItemColor": Colors.deepPurple,
        "unselectedItemColor": Colors.grey,
        "items": [
          new BottomNavigationBarItem({
            "icon": new Icon({
              "icon": Icons.home
            }),
            "label": "首页"
          }),
          new BottomNavigationBarItem({
            "icon": new Icon({
              "icon": Icons.search
            }),
            "label": "搜索"
          }),
          new BottomNavigationBarItem({
            "icon": new Icon({
              "icon": Icons.person
            }),
            "label": "我的"
          })
        ]
      })
    });
  }
}

