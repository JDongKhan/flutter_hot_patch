import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';

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
  runApp(const HotDemoApp());
}

/// Demo 列表：展示「正常组件 ↔ JS 热更版本」的各个场景。
///
/// 每个组件都先是一个**完全正常的 Flutter StatefulWidget**（原生可直接用）；
/// 线上出 bug 时，运行时切换到对应的 JS 补丁（JsUiWidget 加载
/// build_runner 静态翻译出的同名 .js）即可热修复，无需发版。
class HotDemoApp extends StatelessWidget {
  const HotDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '注解组件 → JS 热修复',
      debugShowCheckedModeBanner: false,
      // 全局导航 key：热更包全局级服务（toast 等）用它定位 ScaffoldMessenger
      navigatorKey: JsRuntimeManager.navigatorKey = GlobalKey<NavigatorState>(),
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const DemoListPage(),
    );
  }
}

/// 一个 Demo 场景条目。
class _DemoEntry {
  final String title;
  final String subtitle;
  final Widget child;

  const _DemoEntry(this.title, this.subtitle, this.child);
}

/// Demo 场景列表页。
class DemoListPage extends StatelessWidget {
  const DemoListPage({super.key});

  static final _demos = <_DemoEntry>[
    _DemoEntry(
      'HelloCard · 原生 vs JS 热更',
      '同屏对比：正常组件与 JS 补丁的渲染与逻辑',
      _CompareTest(
        native: HelloCard(),
        js: JsUiWidget(
          jsAsset: 'assets/components/hello_component.js',
          component: 'HelloCard',
        ),
      ),
    ),
    _DemoEntry(
      'DashboardCard · 原生 vs JS 热更',
      '复合组件：内嵌 BannerCard（注解）+ 私有/非私有自定义 widget 双路径',
      _CompareTest(
        native: DashboardCard(),
        js: JsUiWidget(
          jsAsset: 'assets/components/composite_component.js',
          component: 'DashboardCard',
          // 嵌套组件（BannerCard）由生成器在 Component 节点产出 JS 工厂调用，
          // 运行时自动递归挂载，使用方无需声明依赖。
          // 非私有组件（LabeledDivider）运行时注入原生 widget：
          // hot_patch 包不 import 业务类，由业务方在这里注册
          nativeComponents: {
            'LabeledDivider': (args) => LabeledDivider(text: args['text'] as String? ?? ''),
            // 标了 @UIComponentIgnore 的私有组件同样走原生注入
            //（私有类跨库不可见，注册等价的原生实现）：
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
        js: JsUiWidget(
          jsAsset: 'assets/components/provider_component.js',
          component: 'ProviderCard',
        ),
      ),
    ),
    _DemoEntry(
      'WatchDemo · 原生 vs JS 热更',
      'context.watch（订阅局部刷新）/ context.read（仅取实例）',
      _CompareTest(
        native: WatchDemo(),
        // context.watch/read 的订阅与 provider 链全在 JS 侧（新运行时）。
        js: JsUiWidget(
          jsAsset: 'assets/components/watch_demo.js',
          component: 'WatchDemo',
        ),
      ),
    ),
    _DemoEntry(
      'HelloCard · 网络 zip 加载',
      'jsAsset 为 http(s):// zip：下载解压到 document 后走与 asset 一致的加载逻辑',
      _CompareTest(
        native: HelloCard(),
        js: JsUiWidget(
          jsAsset: 'http://127.0.0.1:8765/patch/multi_components.zip',
          // entryPath 直达 zip 内入口（也可不传，按 component 反查）
          entryPath: 'components/hello_component.js',
          component: 'HelloCard',
        ),
      ),
    ),
    _DemoEntry(
      'HelloCard · JS 双实例隔离',
      '同屏两个 JsUiWidget 实例：单 runtime 内按 pageKey 隔离，状态互不共享',
      _TwinTest(
        jsAsset: 'assets/components/hello_component.js',
        component: 'HelloCard',
        label: 'HelloCard',
      ),
    ),
    _DemoEntry(
      '常用组件 · 列表',
      '分组列出 Flutter 常用组件，点击进入详情页（原生 vs JS 热更）',
      const WidgetShowcase(),
    ),
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
                  builder: (_) => _SimpleDemoPage(title: d.title, child: d.child),
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
  const _SimpleDemoPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
  const _TwinTest({required this.jsAsset, required this.component, required this.label});

  final String jsAsset;
  final String component;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$label #1', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        JsUiWidget(jsAsset: jsAsset, component: component),
        const Divider(height: 32),
        Text('$label #2', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        JsUiWidget(jsAsset: jsAsset, component: component),
      ],
    );
  }
}
