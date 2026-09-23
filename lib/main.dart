import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';

import 'components/banner_component.dart';
import 'components/composite_component.dart';
import 'components/hello_component.dart';

void main() => runApp(const HotDemoApp());

/// Demo 列表：展示「正常组件 ↔ JS 热更版本」的各个场景。
///
/// 每个组件都先是一个**完全正常的 Flutter StatefulWidget**（原生可直接用）；
/// 线上出 bug 时，运行时切换到对应的 JS 补丁（HotPatchWidget 加载
/// build_runner 静态翻译出的 .component.js）即可热修复，无需发版。
///
/// 场景覆盖：
///   - 单组件：HelloCard（原生 / JS）
///   - 单文件多组件：HelloPanel 与 HelloCard 同文件同产物（原生 / JS）
///   - 多文件多组件：BannerCard 独立产物（原生 / JS）
class HotDemoApp extends StatelessWidget {
  const HotDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '注解组件 → JS 热修复',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
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
      'HelloCard · 原生组件',
      '正常 StatefulWidget，直接使用（与注解无关）',
      HelloCard(),
    ),
    _DemoEntry(
      'HelloCard · JS 热更',
      'HotPatchWidget 加载 hello_component.component.js，JS 驱动渲染与逻辑',
      HotPatchWidget(
        jsAsset: 'assets/components/components/hello_component.component.js',
        component: 'HelloCard',
      ),
    ),
    _DemoEntry(
      'HelloPanel · 原生组件',
      '单文件多组件：与 HelloCard 同文件、同产物',
      HelloPanel(),
    ),
    _DemoEntry(
      'HelloPanel · JS 热更',
      '同一产物注册的第二个组件（taps 状态）',
      HotPatchWidget(
        jsAsset: 'assets/components/components/hello_component.component.js',
        component: 'HelloPanel',
      ),
    ),
    _DemoEntry(
      'BannerCard · 原生组件',
      '多文件多组件：banner_component.dart 独立产物',
      BannerCard(),
    ),
    _DemoEntry(
      'BannerCard · JS 热更',
      '独立产物 banner_component.component.js（views 状态）',
      HotPatchWidget(
        jsAsset: 'assets/components/components/banner_component.component.js',
        component: 'BannerCard',
      ),
    ),
    _DemoEntry(
      'DashboardCard · 原生组件',
      '复合组件：build 内嵌 BannerCard（注解组件）+ 无注解自定义 widget',
      DashboardCard(),
    ),
    _DemoEntry(
      'DashboardCard · JS 热更',
      '私有组件转 JS 递归渲染 + 事件回流；非私有组件 nativeComponents 注入',
      HotPatchWidget(
        jsAsset: 'assets/components/components/composite_component.component.js',
        component: 'DashboardCard',
        requiredAssets: [
          'assets/components/components/banner_component.component.js',
        ],
        // 非私有组件（LabeledDivider）运行时注入原生 widget：
        // hot_patch 包不 import 业务类，由业务方在这里注册
        nativeComponents: {
          'LabeledDivider': (args) =>
              LabeledDivider(text: args['text'] as String? ?? ''),
        },
      ),
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
                  builder: (_) => DemoPage(title: d.title, child: d.child),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 双实例隔离测试：同屏渲染两个相同组件（HotPatchWidget 各持独立 JS 实例）。
/// 验证：点其中一个的按钮，另一个的状态不受影响（__instances[key] 隔离）。
class _TwinTest extends StatelessWidget {
  const _TwinTest({
    required this.jsAsset,
    required this.component,
    required this.label,
  });

  final String jsAsset;
  final String component;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$label #1',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        HotPatchWidget(jsAsset: jsAsset, component: component),
        const Divider(height: 32),
        Text(
          '$label #2',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        HotPatchWidget(jsAsset: jsAsset, component: component),
      ],
    );
  }
}

/// 单个场景页：居中展示组件，方便看效果。
class DemoPage extends StatelessWidget {
  const DemoPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
