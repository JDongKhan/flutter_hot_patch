import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';
import 'package:provider/provider.dart';

import 'pages/community_page.dart';
import 'pages/home_page.dart';
import 'pages/mine_page.dart';
import 'pages/orders_page.dart';
import 'vm/app_shell_vm.dart';
import 'widgets/load_error_view.dart';

/// App 四 tab 外壳（对应 docs/app-prototype.html 的整体框架）——**热更载体**。
///
/// 本类标了 `@PatchEntry()`，会被翻译成 `patch/app/app.js`：整壳（tab 切页状态、
/// [TabBarView]、[BottomNavigationBar]）都跑在 JS 运行时里，出问题直接下发补丁
/// 即可热修整壳布局。
///
/// **底部导航由接口下发**：外壳通过 [AppShellVm] 请求 `/app/tabs`，按返回的
/// 顺序 / 文案 / 图标装配 [BottomNavigationBar]，并按 `screen` 装配对应页面。
///
/// 切页用 [TabBarView]：[TabBarView] / [PageView] 在基座里登记为「懒容器」，JS
/// 侧先为每个子页下发零尺寸占位结点，宿主真正 inflate 到某个子页的占位时
/// 再经通道回调 JS 挂载它（构造 + initState + build）。因此只有当前 tab 的
/// initState / 请求会随首帧执行，与 Flutter 原生行为一致。
@PatchEntry()
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppShellVm>(
      create: (_) => AppShellVm()..load(),
      child: const AppShellView(),
    );
  }
}

/// 外壳视图：订阅 [AppShellVm]，按接口配置装配 tab 与页面。
class AppShellView extends StatefulWidget {
  const AppShellView({super.key});

  @override
  State<AppShellView> createState() => _AppShellViewState();
}

class _AppShellViewState extends State<AppShellView>
    with SingleTickerProviderStateMixin {
  /// tab 控制器：等接口配置回来后按 tab 数量创建；数量不变时复用。
  TabController? _tab;

  /// 当前页镜像（由 controller 监听同步），供 [BottomNavigationBar] 高亮。
  int _index = 0;

  @override
  void dispose() {
    final tab = _tab;
    if (tab != null) {
      tab.dispose();
    }
    super.dispose();
  }

  /// 取当前长度的 controller：首次按接口下发的 tab 数创建。
  TabController _controllerFor(int length) {
    final current = _tab;
    if (current != null && current.length == length) {
      return current;
    }
    final controller = TabController(length: length, vsync: this);
    controller.addListener(() {
      setState(() => _index = controller.index);
    });
    _tab = controller;
    _index = 0;
    return controller;
  }

  void _openTab(int index) {
    setState(() => _index = index);
    final tab = _tab;
    if (tab != null) {
      tab.animateTo(index);
    }
  }

  Future<void> _retry() async {
    await context.read<AppShellVm>().load();
  }

  /// 图标标识 → IconData。新增图标标识只需在这里补一个分支。
  IconData _iconOf(String icon) {
    switch (icon) {
      case 'home':
        return Icons.home;
      case 'article':
        return Icons.article;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'person':
        return Icons.person;
    }
    return Icons.apps;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppShellVm>();
    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = vm.error;
    if (error != null) {
      return LoadErrorView(message: error, onRetry: _retry);
    }
    if (vm.tabs.isEmpty) {
      return LoadErrorView(message: '底部配置为空', onRetry: _retry);
    }
    final tab = _controllerFor(vm.tabs.length);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      // 禁用左右滑动，保持「只由底部导航切 tab」的原语义，避免与页内横向滚动
      //（首页 banner）抢手势。
      body: TabBarView(
        controller: tab,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final t in vm.tabs) TabPageSlot(screen: t.screen),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _openTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0E7AFB),
        unselectedItemColor: const Color(0xFF98A0AC),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          for (final t in vm.tabs)
            BottomNavigationBarItem(
              icon: Icon(_iconOf(t.icon)),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

/// 单个 tab 的页面装配点：按接口下发的 screen 装配页面。
///
/// 独立成组件（而不是外壳 build 里的方法）是为了让页面构造发生在自己的
/// build 里：每个 tab 的真实页面只在自己的槽位被挂载时创建。
class TabPageSlot extends StatelessWidget {
  const TabPageSlot({super.key, required this.screen});

  final String screen;

  @override
  Widget build(BuildContext context) {
    if (screen == 'home') return const HomePage();
    if (screen == 'community') return const CommunityPage();
    if (screen == 'orders') return const OrdersPage();
    if (screen == 'mine') return const MinePage();
    // 未知 screen 不静默丢弃：输出明确日志并显示可见提示。
    print('TabPageSlot 未知 tab 页面：$screen');
    return Text('未知页面：$screen');
  }
}

/// 「完整 App · JS 热更」入口：整个四 tab 外壳由 JS 补丁渲染。
///
/// 外壳（`patch/app/app.js`）里各 tab 页都是**类引用**（各有 JS 产物，JS 运行时
/// 直接 new），无需宿主注入任何原生组件。若某页改用 `@PatchIgnore` 退出翻译，
/// 翻译器会把它产出为**保留其类型名**的结点（未注册），此时在 `main()` 里用全局的
/// `registerNativeComponent('XxxPage', (c) => ...)` 注入原生实现即可。
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
