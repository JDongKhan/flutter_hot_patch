import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';

import 'app/app.dart';
import 'components/composite_component.dart';
import 'components/hello_component.dart';
import 'components/watch_demo.dart';
import 'components/provider_component.dart';
import 'components/widget_showcase.dart';
import 'generated/host_methods.dart';

void main() {
  // @HostInjected 宿主方法：JS 侧调用点被翻译为 `__jsui.host('getUserName', [])`。
  // 注册清单由 build_runner 扫描注解生成（lib/generated/host_methods.dart），
  // 调一次即可，无需手写每条通道。
  registerHostMethods();
  // 入口是 Demo 列表页，其中的两条「完整 App」入口分别渲染**原生外壳**与
  // **JS 热更外壳**（AppShell，见 lib/app/app.dart）。
  runApp(const HotDemoApp());
}

/// Demo 列表的外壳（App）：整体 App 结构在 lib/app/app.dart 的 [AppShell] 里，
/// 这里只提供 Demo 列表所需的 MaterialApp 与全局 Navigator。
class HotDemoApp extends StatelessWidget {
  const HotDemoApp({super.key});

  /// 全局导航 key：热更包全局级服务（toast / AppRouter 推页）靠它定位
  /// Navigator 与 ScaffoldMessenger。用 static final 保证重建时 key 稳定。
  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '旅行 App · 注解组件热更示例',
      debugShowCheckedModeBanner: false,
      navigatorKey: JsRuntimeManager.navigatorKey = navKey,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7AFB))),
      home: const DemoListPage(),
    );
  }
}

/// 本地 patch 服务（start_patch_server.sh 启动）暴露的 zip 包。
/// demo 全部从这里加载：散 .js 与 zip 同目录，改完产物重启服务即可。
const String _patchZipUrl = 'http://127.0.0.1:8765/patch/patch.zip';

/// 拼接补丁 URL：组件名与入口路径都走 query 参数（运营可直接改 URL 配置）。
///   ?component=HelloCard&entry=components/hello_component.js
String _patchUrl(String component, [String? entry]) {
  final q = StringBuffer('component=$component');
  if (entry != null) q.write('&entry=${Uri.encodeComponent(entry)}');
  return '$_patchZipUrl?$q';
}

/// 一个 Demo 场景条目。
class _DemoEntry {
  final String title;
  final String subtitle;
  final Widget child;
  final bool hasAppBar;

  const _DemoEntry(this.title, this.subtitle, this.child, {this.hasAppBar = true});
}

/// Demo 场景列表页。
class DemoListPage extends StatelessWidget {
  const DemoListPage({super.key});

  static final _demos = <_DemoEntry>[
    _DemoEntry('完整 App · 原生', '四 tab 外壳（AppShell）原生渲染：首页 / 社区 / 订单 / 我的', const AppShell(), hasAppBar: false),
    _DemoEntry(
      '完整 App · JS 热更',
      'AppShell 由 JS 补丁渲染，四个 tab 页面由宿主 nativeComponents 原生注入',
      const AppShellJsPage(),
      hasAppBar: false,
    ),
    _DemoEntry(
      'HelloCard · 原生 vs JS 热更',
      '同屏对比：正常组件与 JS 补丁的渲染与逻辑',
      _CompareTest(
        native: HelloCard(),
        js: JsUiWidget(jsAsset: _patchUrl('HelloCard', 'components/hello_component.js')),
      ),
    ),
    _DemoEntry(
      'DashboardCard · 原生 vs JS 热更',
      '复合组件：内嵌 BannerCard（注解）+ 私有/非私有自定义 widget 双路径',
      _CompareTest(
        native: DashboardCard(),
        js: JsUiWidget(
          jsAsset: _patchUrl('DashboardCard', 'components/composite_component.js'),
          // 嵌套组件（BannerCard）与公开 widget（LabeledDivider）都由生成器
          // 连带翻译进同一产物（JS 类引用），运行时直接 new，使用方无需声明依赖。
          // 只有标了 @UIComponentIgnore 的私有组件走原生注入：
          //（私有类跨库不可见，注册等价的原生实现）：
          nativeComponents: {
            '_LabeledDivider': (args) => LabeledDivider(text: args['text'] as String? ?? ''),
          },
        ),
      ),
    ),
    _DemoEntry(
      'ProviderCard · 原生 vs JS 热更',
      'MultiProvider：providers 平级数组一一对应转换，Consumer 局部重建',
      _CompareTest(
        native: ProviderCard(),
        // provider 状态处理在 JS 侧（assets/provider.js）：
        // 经 JsUiWidget 新运行时渲染，宿主不实现任何 provider 语义。
        js: JsUiWidget(jsAsset: _patchUrl('ProviderCard', 'components/provider_component.js')),
      ),
    ),
    _DemoEntry(
      'WatchDemo · 原生 vs JS 热更',
      'context.watch（订阅局部刷新）/ context.read（仅取实例）',
      _CompareTest(
        native: WatchDemo(),
        // context.watch/read 的订阅与 provider 链全在 JS 侧（新运行时）。
        js: JsUiWidget(jsAsset: _patchUrl('WatchDemo', 'components/watch_demo.js')),
      ),
    ),
    _DemoEntry(
      'HelloCard · JS 双实例隔离',
      '同屏两个 JsUiWidget 实例：单 runtime 内按 pageKey 隔离，状态互不共享',
      _TwinTest(jsAsset: _patchUrl('HelloCard', 'components/hello_component.js'), label: 'HelloCard'),
    ),
    _DemoEntry('常用组件 · 列表', '分组列出 Flutter 常用组件，点击进入详情页（原生 vs JS 热更）', const WidgetShowcase()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注解组件 → JS 热修复 Demo')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _demos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final d = _demos[index];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(
                index.isEven ? Icons.widgets_outlined : Icons.bolt_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(d.title),
              subtitle: Text(d.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _SimpleDemoPage(title: d.title, hasAppBar: d.hasAppBar, child: d.child),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 单个场景页的简洁外壳：只提供返回栏与正文区域。
/// 不使用 Center / SingleChildScrollView（这两个组件由
/// ScaffoldDemo 注解组件专门演示，避免 main 里重复）。
class _SimpleDemoPage extends StatelessWidget {
  const _SimpleDemoPage({required this.title, required this.child, this.hasAppBar = true});

  final String title;
  final Widget child;
  final bool hasAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: hasAppBar ? AppBar(title: Text(title)) : null,
      body: child,
    );
  }
}

/// 原生 vs JS 热更同屏对比：一页上下两块，方便肉眼对照。
class _CompareTest extends StatelessWidget {
  const _CompareTest({required this.native, required this.js});

  final Widget native;
  final Widget js;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('原生组件', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        native,
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        Text('JS 热更（JsUiWidget）', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        js,
      ],
    );
  }
}

/// 双实例隔离测试：同屏渲染两个相同组件（单 runtime 内按 pageKey 隔离）。
/// 验证：点其中一个的按钮，另一个的状态不受影响（roots[pageKey] 隔离）。
class _TwinTest extends StatelessWidget {
  const _TwinTest({required this.jsAsset, required this.label});

  final String jsAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$label #1', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        JsUiWidget(jsAsset: jsAsset),
        const Divider(height: 32),
        Text('$label #2', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        JsUiWidget(jsAsset: jsAsset),
      ],
    );
  }
}
