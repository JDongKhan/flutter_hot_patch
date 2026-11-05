// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/app.dart 自动生成
// 重新生成：dart run build_runner build

import { AppShellVm } from 'vm/app_shell_vm.js';
import { LoadErrorView } from 'widgets/load_error_view.js';
import { HomePage } from 'pages/home_page.js';
import { CommunityPage } from 'pages/community_page.js';
import { OrdersPage } from 'pages/orders_page.js';
import { MinePage } from 'pages/mine_page.js';
import { BottomNavigationBar, BottomNavigationBarItem, BottomNavigationBarType, Center, CircularProgressIndicator, Color, Colors, Icon, Icons, NeverScrollableScrollPhysics, Scaffold, StatefulWidget, StatelessWidget, TabBarView, TabController, Text } from '../flutter.js';
import { ChangeNotifierProvider } from '../provider.js';

// 组件 AppShell
export class AppShell extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    return new ChangeNotifierProvider({
      "create": (_) => { return (() => { const _t = new AppShellVm(); _t.load(); return _t; })(); },
      "child": (this.__k0 || (this.__k0 = new AppShellView({}))),
      "typeArguments": {"T": "AppShellVm"}
    });
  }
}

// 组件 AppShellView
export class AppShellView extends StatefulWidget {
  constructor(args) {
    super(args);
    this._tab = null;
    this._index = 0;
  }
  dispose() {
    const tab = this._tab;
    if ((tab != null)) {
      tab.dispose();
    }
    super.dispose();
  }
  _controllerFor(length) {
    const current = this._tab;
    if (((current != null) && (__nn(current.length) === length))) {
      return current;
    }
    const controller = new TabController({length: length, vsync: this});
    controller.addListener(() => { this.setState(() => {
        this._index = controller.index;
      }); });
    this._tab = controller;
    this._index = 0;
    return controller;
  }
  _openTab(index) {
    this.setState(() => {
      this._index = index;
    });
    const tab = this._tab;
    if ((tab != null)) {
      tab.animateTo(index);
    }
  }
  async _retry() {
    await this.context.read({ typeArguments: {"T": "AppShellVm"} }).load();
  }
  _iconOf(icon) {
    switch (icon) {
      case "home":
      return Icons.home;
      case "article":
      return Icons.article;
      case "shopping_cart":
      return Icons.shopping_cart;
      case "person":
      return Icons.person;
    }
    return Icons.apps;
  }
  build(context) {
    const vm = context.watch({ typeArguments: {"T": "AppShellVm"} });
    if (vm.loading) {
      return (this.__k0 || (this.__k0 = new Center({
        "child": new CircularProgressIndicator({})
      })));
    }
    const error = vm.error;
    if ((__nn(error) != null)) {
      return new LoadErrorView({
        "message": error,
        "onRetry": () => this._retry()
      });
    }
    if (vm.tabs.isEmpty) {
      return new LoadErrorView({
        "message": "底部配置为空",
        "onRetry": () => this._retry()
      });
    }
    const tab = this._controllerFor(vm.tabs.length);
    return new Scaffold({
      "backgroundColor": (this.__k1 || (this.__k1 = new Color({
        "value": 0xFFF4F5F7
      }))),
      "body": new TabBarView({
        "controller": this._tab,
        "physics": (this.__k2 || (this.__k2 = new NeverScrollableScrollPhysics({}))),
        "children": [
          ...(() => { var out = []; for (let t of vm.tabs) { out.push.apply(out, [new TabPageSlot({
                  "screen": t.screen
                })]); } return out; })()
        ]
      }),
      "bottomNavigationBar": new BottomNavigationBar({
        "currentIndex": this._index,
        "onTap": (__a0) => this._openTab(__a0),
        "type": BottomNavigationBarType.fixed,
        "backgroundColor": Colors.white,
        "selectedItemColor": (this.__k3 || (this.__k3 = new Color({
          "value": 0xFF0E7AFB
        }))),
        "unselectedItemColor": (this.__k4 || (this.__k4 = new Color({
          "value": 0xFF98A0AC
        }))),
        "selectedFontSize": 11,
        "unselectedFontSize": 11,
        "items": [
          ...(() => { var out = []; for (let t of vm.tabs) { out.push.apply(out, [new BottomNavigationBarItem({
                  "icon": new Icon({
                    "icon": this._iconOf(t.icon)
                  }),
                  "label": t.label
                })]); } return out; })()
        ]
      })
    });
  }
}

// 组件 TabPageSlot
export class TabPageSlot extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.screen = (args && args.screen !== undefined) ? args.screen : '';
  }
  build(context) {
    if ((this.screen === "home")) {
      return (this.__k0 || (this.__k0 = new HomePage({})));
    }
    if ((this.screen === "community")) {
      return (this.__k1 || (this.__k1 = new CommunityPage({})));
    }
    if ((this.screen === "orders")) {
      return (this.__k2 || (this.__k2 = new OrdersPage({})));
    }
    if ((this.screen === "mine")) {
      return (this.__k3 || (this.__k3 = new MinePage({})));
    }
    print("TabPageSlot 未知 tab 页面：" + this.screen);
    return new Text({
      "data": "未知页面：" + this.screen
    });
  }
}

