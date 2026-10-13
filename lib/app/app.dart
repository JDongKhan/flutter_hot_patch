import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';
import 'package:ui_component/ui_component.dart';

import 'pages/community_page.dart';
import 'pages/home_page.dart';
import 'pages/mine_page.dart';
import 'pages/orders_page.dart';

/// App 四 tab 外壳（对应 docs/app-prototype.html 的整体框架）——**热更载体**。
///
/// 本类标了 `@UIComponent()`，会被翻译成 `patch/app/app.js`：整壳（tab 切换状态
/// `_index`、[IndexedStack]、[BottomNavigationBar]）都跑在 JS 运行时里，出问题
/// 直接下发补丁即可热修整壳布局。
///
/// 依赖的 widget 类会**连带翻译**：`HomePage`（及其同文件的
/// HomeHeader/BannerSlide/GridCell/SpotCard/PromoCard）已是 `patch/app/pages/
/// home_page.js` 里的 JS 类，外壳产物直接 `import` 后 `new` 出来。
/// 其余三个 tab 页用了翻译器覆盖不到的构造，标了 `@UIComponentIgnore()`
/// 显式退出翻译 → 在外壳产物里保持 `Component` 占位结点，由宿主经
/// `JsUiWidget.nativeComponents` 原生注入（见 [AppShellJsPage]）。
@UIComponent()
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _openTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      // IndexedStack 保留各 tab 状态（滚动位置、筛选面板等）。
      body: IndexedStack(
        index: _index,
        children: [
          // 首页：有 JS 产物（连带翻译），外壳产物里是类引用，由 JS 运行时直接
          // new 出来；数据用构造参数的默认值（app_data.dart 的顶层 const）。
          const HomePage(),
          const CommunityPage(),
          const OrdersPage(),
          // 三个 tab 页均有 JS 产物（连带翻译）。
          const MinePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _openTab,
        // type / backgroundColor / selectedFontSize / activeIcon 在 JS 侧无
        // 对应翻译（宿主只还原 index、事件与颜色），故这里只用白名单内的图标。
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0E7AFB),
        unselectedItemColor: const Color(0xFF98A0AC),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: '社区'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '订单'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

/// 「完整 App · JS 热更」入口：整个四 tab 外壳由 JS 补丁渲染。
///
/// 外壳（`patch/app/app.js`）里 [HomePage] 是**类引用**（有 JS 产物，JS 运行时
/// 直接 new）；其余三个 tab 页标了 `@UIComponentIgnore`、没有 JS 产物，翻译器
/// 把它们产出为 `Component` 占位结点 → 这里用 [nativeComponents] 把同名原生页面
/// 注进去。
class AppShellJsPage extends StatelessWidget {
  const AppShellJsPage({super.key});

  /// 本地 patch 服务（start_patch_server.sh）暴露的 zip 包。
  static const String _zip = 'http://127.0.0.1:8765/patch/patch.zip';

  /// 补丁 URL：组件名 + 入口路径都走 query（与 DemoListPage 的写法一致）。
  static final String _jsAsset =
      '$_zip?component=AppShell&entry=${Uri.encodeComponent('app/app.js')}';

  @override
  Widget build(BuildContext context) {
    return JsUiWidget(
      jsAsset: _jsAsset,
      // nativeComponents: {
      //   // 三个 @UIComponentIgnore 的 tab 页：原生注入（HomePage 有 JS 产物，
      //   // 不需要在这里注册）。
      //   'CommunityPage': (args) => const CommunityPage(),
      //   'OrdersPage': (args) => const OrdersPage(),
      //   // JS 侧拿不到 _openTab（构建期已告警跳过），这里注入默认形态。
      //   'MinePage': (args) => const MinePage(),
      // },
    );
  }
}
