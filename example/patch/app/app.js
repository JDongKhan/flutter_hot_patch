// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/app.dart 自动生成
// 重新生成：dart run build_runner build

import { HomePage } from 'pages/home_page.js';
import { CommunityPage } from 'pages/community_page.js';
import { OrdersPage } from 'pages/orders_page.js';
import { MinePage } from 'pages/mine_page.js';
import { __h } from '../flutter.js';

// 组件 AppShell
export class AppShell {
  constructor() {
  }
  build(context) {
    return __h(AppSubContent, {});
  }
}

// 组件 AppSubContent
export class AppSubContent {
  constructor() {
    this._tab = new TabController({length: 4, vsync: this});
    this._index = 0;
  }
  initState() {
    this._tab.addListener(() => { this.setState(() => { this._index = this._tab.index; }); });
  }
  dispose() {
    this._tab.dispose();
  }
  _openTab(index) {
    this.setState(() => { this._index = index; });
    this._tab.animateTo(index);
  }
  build(context) {
    return __h('Scaffold', {
        "backgroundColor": '#fff4f5f7',
        "body": __h('TabBarView', {
            "controller": this._tab,
            "physics": "NeverScrollableScrollPhysics"
          }, [
            __h(HomePage, {}),
            __h(CommunityPage, {}),
            __h(OrdersPage, {}),
            __h(MinePage, {})
          ]),
        "bottomNavigationBar": __h('BottomNavigationBar', {
            "currentIndex": this._index,
            "onTap": this.__bindFn(0, [], (...__a) => this._openTab(...__a)),
            "type": "fixed",
            "backgroundColor": '#FFFFFF',
            "selectedItemColor": '#ff0e7afb',
            "unselectedItemColor": '#ff98a0ac',
            "selectedFontSize": 11,
            "unselectedFontSize": 11,
            "items": [
              __h('BottomNavigationBarItem', {
                  "icon": __h('Icon', {
                      "icon": "home"
                    }),
                  "label": "首页"
                }),
              __h('BottomNavigationBarItem', {
                  "icon": __h('Icon', {
                      "icon": "article"
                    }),
                  "label": "社区"
                }),
              __h('BottomNavigationBarItem', {
                  "icon": __h('Icon', {
                      "icon": "shopping_cart"
                    }),
                  "label": "订单"
                }),
              __h('BottomNavigationBarItem', {
                  "icon": __h('Icon', {
                      "icon": "person"
                    }),
                  "label": "我的"
                })
            ]
          })
      });
  }
}

