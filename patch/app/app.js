// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/app/app.dart 自动生成
// 重新生成：dart run build_runner build

import { HomePage } from 'pages/home_page.js';
import { CommunityPage } from 'pages/community_page.js';
import { OrdersPage } from 'pages/orders_page.js';
import { MinePage } from 'pages/mine_page.js';
import { __h } from '../flutter.js';

const _zip = "http://127.0.0.1:8765/patch/patch.zip";

// 组件 AppShell
export class AppShell {
  constructor() {
    this._index = 0;
  }
  _openTab(index) {
    this.setState(function(){ this._index = index; });
  }
  build() {
    return __h('Scaffold', {
        "body": __h('IndexedStack', {
            "index": this._index
          }, [
            __h(HomePage, {}),
            __h(CommunityPage, {}),
            __h(OrdersPage, {}),
            __h(MinePage, {})
          ]),
        "backgroundColor": '#fff4f5f7',
        "bottomNavigationBar": __h('BottomNavigationBar', {
            "currentIndex": this._index,
            "event": this.__bind("_openTab"),
            "selectedItemColor": '#ff0e7afb',
            "unselectedItemColor": '#ff98a0ac'
          }, [
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
          ])
      });
  }
}

