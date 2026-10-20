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
/// 切页用 [TabBarView]：宿主侧天然只有当前页会被 inflate；但 JS 侧（MiniReact）
/// 的挂载是**一次性递归整棵 children**（`mount` 会构造实例并跑 initState/build），
/// 所以四个 tab 页的 initState 与请求在首帧仍会全跑。JS 侧的懒加载需要基座的
/// 「延迟挂载」能力（宿主 `_JsNode` 被 inflate 时反向驱动 JS 按需挂载），
/// 本壳不再用业务层占位去模拟。
///
/// 依赖的 widget 类会**连带翻译**：四个 tab 页（及 HomePage 同文件的
/// HomeHeader/BannerSlide/GridCell/SpotCard/PromoCard 等）都是各自
/// `patch/app/pages/*.js` 里的 JS 类，外壳产物直接 `import` 后 `new` 出来。
///
/// 若某个 tab 页标了 `@PatchIgnore()` 显式退出翻译，它在产物里保留**其类型名**
/// 作元素 type（未注册 → 运行时走默认 builder），需由业务方在 `main()` 里用全局的
/// `registerNativeComponent(名字, 构造)` 注入原生实现——不随 `JsUiWidget`
/// 实例透传（见 [AppShellJsPage]）。
@PatchEntry()
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    return AppSubContent();
  }
}

class AppSubContent extends StatefulWidget {
  const AppSubContent({super.key});

  @override
  State<AppSubContent> createState() => _AppSubContentState();
}

class _AppSubContentState extends State<AppSubContent> with SingleTickerProviderStateMixin {
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
      // 禁用左右滑动，保持「只由底部导航切 tab」的原语义，避免与页内横向滚动
      //（首页 banner）抢手势。
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
/// 外壳（`patch/app/app.js`）里四个 tab 页都是**类引用**（各有 JS 产物，JS 运行时
/// 直接 new），无需宿主注入任何原生组件。若某页改用 `@PatchIgnore` 退出翻译，
/// 翻译器会把它产出为**保留其类型名**的结点（未注册），此时在 `main()` 里用全局的
/// `registerNativeComponent('XxxPage', (args) => ...)` 注入原生实现即可。
@PatchIgnore()
class AppShellJsPage extends StatelessWidget {
  const AppShellJsPage({super.key});

  /// 本地 patch 服务（start_patch_server.sh）暴露的 zip 包。
  static const String _zip = 'http://127.0.0.1:8765/patch/patch.zip';

  /// 补丁 URL：组件名 + 入口路径都走 query（与 DemoListPage 的写法一致）。
  static final String _jsAsset = '$_zip?component=AppShell&entry=${Uri.encodeComponent('app/app.js')}';

  @override
  Widget build(BuildContext context) {
    return JsUiWidget(
      jsAsset: _jsAsset,
      // 右上角显示补丁打包时间（来自 patch/manifest.json，纯展示、不吃手势）。
      showBuildTime: true,
    );
  }
}
