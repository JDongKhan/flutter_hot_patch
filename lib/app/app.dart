import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'pages/community_page.dart';
import 'pages/home_page.dart';
import 'pages/mine_page.dart';
import 'pages/orders_page.dart';

/// App 四 tab 外壳（对应 docs/app-prototype.html 的整体框架）——**热更载体**。
///
/// 本类标了 `@PatchEntry()`，会被翻译成 `patch/app/app.js`：整壳（[TabController]
/// 驱动的切页状态、[TabBarView]、[BottomNavigationBar]）都跑在 JS 运行时里，出问题
/// 直接下发补丁即可热修整壳布局。
///
/// 切页用 [TabBarView]（PageView 的懒加载语义）：只构建当前 tab，没进入过的
/// tab 不会 build —— 这正是替代 [IndexedStack] 的原因，后者一次性建满四页。
/// 代价是切走再回来会重建（页面状态不保留），由各 tab 页自己的数据请求承担。
///
/// 依赖的 widget 类会**连带翻译**：`HomePage`（及其同文件的
/// HomeHeader/BannerSlide/GridCell/SpotCard/PromoCard）已是 `patch/app/pages/
/// home_page.js` 里的 JS 类，外壳产物直接 `import` 后 `new` 出来。
/// 其余三个 tab 页用了翻译器覆盖不到的构造，标了 `@PatchIgnore()`
/// 显式退出翻译 → 在外壳产物里保持 `Component` 占位结点，由宿主经
/// `JsUiWidget.nativeComponents` 原生注入（见 [AppShellJsPage]）。
@PatchEntry()
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  /// 四 tab 的 TabController：JS 侧代理类忽略 vsync，length 随句柄下发宿主建
  /// 真实 controller（见 capabilities/tab），[TabBarView] 与底部导航共用同一个。
  late final TabController _tab = TabController(length: 4, vsync: this);

  /// 当前页镜像（由 controller 监听同步），供 [BottomNavigationBar] 高亮。
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tab.addListener(() {
      setState(() => _index = _tab.index);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _openTab(int index) {
    setState(() => _index = index);
    _tab.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      // TabBarView 只构建当前 tab（懒加载）；禁用左右滑动，保持「只由底部
      // 导航切 tab」的原语义，避免与页内横向滚动（首页 banner）抢手势。
      body: TabBarView(
        controller: _tab,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 首页：有 JS 产物（连带翻译），外壳产物里是类引用，由 JS 运行时直接
          // new 出来；数据由 HomePage 自己经 AppService 模拟网络请求取回。
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
/// 直接 new）；其余三个 tab 页标了 `@PatchIgnore`、没有 JS 产物，翻译器
/// 把它们产出为 `Component` 占位结点 → 这里用 [nativeComponents] 把同名原生页面
/// 注进去。
@PatchIgnore()
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
      // 右上角显示补丁打包时间（来自 patch/manifest.json，纯展示、不吃手势）。
      showBuildTime: true,
      // nativeComponents: {
      //   // 三个 @PatchIgnore 的 tab 页：原生注入（HomePage 有 JS 产物，
      //   // 不需要在这里注册）。
      //   'CommunityPage': (args) => const CommunityPage(),
      //   'OrdersPage': (args) => const OrdersPage(),
      //   // JS 侧拿不到 _openTab（构建期已告警跳过），这里注入默认形态。
      //   'MinePage': (args) => const MinePage(),
      // },
    );
  }
}
