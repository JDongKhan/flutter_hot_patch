import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';

import 'components/banner_component.dart';
import 'components/composite_component.dart';
import 'components/hello_component.dart';
import 'components/listenable_demo.dart';
import 'components/notifier_component.dart';
import 'components/provider_component.dart';
import 'components/stateless_component.dart';
import 'components/widget_showcase.dart';

void main() => runApp(const HotDemoApp());

/// Demo 列表：展示「正常组件 ↔ JS 热更版本」的各个场景。
///
/// 每个组件都先是一个**完全正常的 Flutter StatefulWidget**（原生可直接用）；
/// 线上出 bug 时，运行时切换到对应的 JS 补丁（HotPatchWidget 加载
/// build_runner 静态翻译出的 .component.js）即可热修复，无需发版。
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
        js: HotPatchWidget(
          jsAsset: 'assets/components/components/hello_component.component.js',
          component: 'HelloCard',
        ),
      ),
    ),
    _DemoEntry(
      'HelloPanel · 原生 vs JS 热更',
      '单文件多组件：与 HelloCard 同文件、同产物（taps 状态）',
      _CompareTest(
        native: HelloPanel(),
        js: HotPatchWidget(
          jsAsset: 'assets/components/components/hello_component.component.js',
          component: 'HelloPanel',
        ),
      ),
    ),
    _DemoEntry(
      'StatelessCard · 原生 vs JS 热更',
      'StatelessWidget：无 State，build 在 widget 类自身，props 走构造参数',
      _CompareTest(
        native: StatelessCard(
          title: 'Hello Stateless',
          subtitle: '原生直接渲染，无需 State',
          badge: 'FLUTTER',
        ),
        js: HotPatchWidget(
          jsAsset: 'assets/components/components/stateless_component.component.js',
          component: 'StatelessCard',
          componentArgs: {
            'title': 'Hello Stateless 1',
            'subtitle': 'JS 热更版本，无 State 也能渲染',
            'badge': 'JS',
          },
        ),
      ),
    ),
    _DemoEntry(
      'BannerCard · 原生 vs JS 热更',
      '多文件多组件：banner_component.dart 独立产物（views 状态）',
      _CompareTest(
        native: BannerCard(),
        js: HotPatchWidget(
          jsAsset: 'assets/components/components/banner_component.component.js',
          component: 'BannerCard',
        ),
      ),
    ),
    _DemoEntry(
      'DashboardCard · 原生 vs JS 热更',
      '复合组件：内嵌 BannerCard（注解）+ 私有/非私有自定义 widget 双路径',
      _CompareTest(
        native: DashboardCard(),
        js: HotPatchWidget(
          jsAsset: 'assets/components/components/composite_component.component.js',
          component: 'DashboardCard',
          // 嵌套组件（BannerCard）由生成器在 Component 节点产出 import，
          // 运行时自动递归加载，使用方无需声明依赖。
          // 非私有组件（LabeledDivider）运行时注入原生 widget：
          // hot_patch 包不 import 业务类，由业务方在这里注册
          nativeComponents: {'LabeledDivider': (args) => LabeledDivider(text: args['text'] as String? ?? '')},
        ),
      ),
    ),
    _DemoEntry(
      'ProviderCard · 原生 vs JS 热更',
      'MultiProvider：providers 平级数组一一对应转换，Consumer 局部重建',
      _CompareTest(
        native: ProviderCard(),
        js: HotPatchWidget(
          jsAsset: 'assets/components/components/provider_component.component.js',
          component: 'ProviderCard',
        ),
      ),
    ),
    _DemoEntry(
      'ListenableDemo · 原生 vs JS 热更',
      'ChangeNotifier + ListenableBuilder 局部重建（同文件共享模型）',
      _CompareTest(
        native: ListenableDemo(),
        js: HotPatchWidget(
          jsAsset: 'assets/components/components/listenable_demo.component.js',
          component: 'ListenableDemo',
        ),
      ),
    ),
    _DemoEntry(
      'NotifierCard · 原生 vs JS 热更',
      'ChangeNotifier + ListenableBuilder：模型逻辑热更，notify 局部重建',
      _CompareTest(
        native: NotifierCard(),
        js: HotPatchWidget(
          jsAsset: 'assets/components/components/notifier_component.component.js',
          component: 'NotifierCard',
        ),
      ),
    ),
    _DemoEntry(
      'Scaffold · 页面骨架',
      'Scaffold / AppBar / Center / SingleChildScrollView 组件演示（页面级，仅 JS 热更版）',
      // 页面级组件无法与原生同屏比对，直接展示 JS 热更版
      HotPatchWidget(jsAsset: 'assets/components/components/scaffold_demo.component.js', component: 'ScaffoldDemo'),
    ),
    _DemoEntry(
      'HelloCard · JS 双实例隔离',
      '同屏两个 HotPatchWidget 实例：各自 new 独立实例，状态互不共享',
      _TwinTest(
        jsAsset: 'assets/components/components/hello_component.component.js',
        component: 'HelloCard',
        label: 'HelloCard',
      ),
    ),
    _DemoEntry(
      'BannerCard · JS 双实例隔离',
      '两个实例 initState 都生效（views=5），点 Bump 只影响被点的那个',
      _TwinTest(
        jsAsset: 'assets/components/components/banner_component.component.js',
        component: 'BannerCard',
        label: 'BannerCard',
      ),
    ),
    _DemoEntry('BannerCard · 多 runtime 分组', '两组 HotPatchWidget 各自使用业务方创建的独立 runtime，点按钮互不影响', _RuntimeGroupTest()),
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
        Text('JS 热更（HotPatchWidget）', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        js,
      ],
    );
  }
}

/// 多 runtime 分组测试：两组 HotPatchWidget 各自使用业务方创建的独立
/// runtime（等价于两个 RuntimeManager 分组的场景）。iOS/JavaScriptCore 的
/// sendMessage 桥是库级 static 的（消息路由到最后创建的 runtime 通道表），
/// 本测试验证：即便两个 runtime 共存，setState 消息仍按实例 key 全局分发，
/// 点 A 组的按钮不会影响 B 组（反之亦然）。
class _RuntimeGroupTest extends StatelessWidget {
  const _RuntimeGroupTest();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('runtime 组 A（业务方创建 #1）', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        HotPatchWidget(
          jsAsset: 'assets/components/components/banner_component.component.js',
          component: 'BannerCard',
          sharedManager: _managerA,
        ),
        const Divider(height: 32),
        Text('runtime 组 B（业务方创建 #2）', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        HotPatchWidget(
          jsAsset: 'assets/components/components/banner_component.component.js',
          component: 'BannerCard',
          sharedManager: _managerB,
        ),
      ],
    );
  }
}

/// 业务方创建的两个独立 JsRuntimeManager（每组与 JavascriptRuntime 一对一，
/// runtime 在 manager 内部消化）：两组 HotPatchWidget 各自共享一个 manager，
/// 组间 JS 状态隔离。handler 表是 static 全局共享的，跨组消息按实例 key
/// 分发，互不串台。
final JsRuntimeManager _managerA = JsRuntimeManager();
final JsRuntimeManager _managerB = JsRuntimeManager();

/// 双实例隔离测试：同屏渲染两个相同组件（HotPatchWidget 各持独立 JS 实例）。
/// 验证：点其中一个的按钮，另一个的状态不受影响（__instances[key] 隔离）。
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
        HotPatchWidget(jsAsset: jsAsset, component: component),
        const Divider(height: 32),
        Text('$label #2', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        HotPatchWidget(jsAsset: jsAsset, component: component),
      ],
    );
  }
}
