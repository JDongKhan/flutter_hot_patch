import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';

import 'app/app.dart';
import 'base/app_log_console.dart';
import 'components/compare_test.dart';
import 'components/composite_component.dart';
import 'components/hello_component.dart';
import 'components/inherited_widget_demo.dart';
import 'components/leak_demo_card.dart';
import 'components/list_view_detail.dart';
import 'components/widget_showcase.dart';
import 'components/test_widget.dart';
import 'custom/custom_capabilities.dart';
import 'custom_component.dart';
import 'generated/host_methods.dart';
import 'grammar/grammar_showcase.dart';
import 'third_party/third_party_showcase.dart';

void main() {
  // 日志捕获：print / debugPrint（含 Flutter 框架与 hot_patch 的 JsLog，
  // JS 侧 print 最终也走这里）全部收进 AppLogCenter，供右侧日志控制台展示。
  installLogCapture();
  runZoned(() {
    // binding 与 runApp 必须在同一个 zone 内初始化（否则触发 Zone mismatch）。
    WidgetsFlutterBinding.ensureInitialized();
    // @HostInjected 宿主方法：JS 侧类与方法照常产出，只有方法体换成
    // `_app_host_.invoke(...)`（调用点与 Dart 一比一）。
    // 注册清单由 build_runner 扫描注解生成（lib/generated/host_methods.dart），
    // 调一次即可，无需手写每条通道。
    registerHostMethods();
    // 开发者自定义能力（lib/custom/**）：与内建能力同一套 `JsUiLibrary` 扩展点，
    // 在 runApp 之前注册即可，hot_patch 包本身零改动。当前示例是
    // VisibilityDetector（曝光/可见性检测）。
    registerCustomCapabilities();
    // 生命周期验证期间临时打开双端句柄进出日志（验证后恢复注释）。
    // JsRuntimeManager.setVerboseCacheTrace(true);
    // 无 JS 产物的组件（产物里的 `Component` 占位结点）的原生实现：**全局一次注册**
    // （进程内共用一张表，不随 JsUiWidget 实例透传），位置与 registerHostMethods
    // 一致——runApp 之前。重复注册同名会覆盖（覆盖时告警），故不要放进 build()。
    //   DashboardCard 产物里 `_LabeledDivider` 私有类跨库不可见，注册公开的同名实现。
    //   回调收到完整 JsRenderContext：props + children slot + invoke。
    registerAllNativeComponent();
    // 入口是 Demo 列表页，其中的两条「完整 App」入口分别渲染**原生外壳**与
    // **JS 热更外壳**（AppShell，见 lib/app/app.dart）。
    runApp(const HotDemoApp());
  }, zoneSpecification: appLogZoneSpecification);
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
      // 宽屏（逻辑宽度 > 1200）时在右侧固定挂一条 300 宽的日志控制台；
      // 通过 builder 包在 Navigator 外层，所有页面（含 JS 热更外壳）都能看到。
      builder: (context, child) {
        final content = child ?? const SizedBox();
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= 800) return content;
            return Row(
              children: [
                Expanded(flex: 2,child: content),
                Expanded(flex: 1, child: AppLogConsole()),
              ],
            );
          },
        );
      },
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
      'AppShell 整壳由 JS 补丁渲染，四个 tab 页面也是 JS 产物（连带翻译）',
      const AppShellJsPage(),
      hasAppBar: false,
    ),
    _DemoEntry(
      'HelloCard · 原生 vs JS 热更',
      '同屏对比：正常组件与 JS 补丁的渲染与逻辑',
      CompareTest(
        native: HelloCard(),
        js: JsUiWidget(jsAsset: _patchUrl('HelloCard', 'components/hello_component.js')),
      ),
    ),
    _DemoEntry(
      'DashboardCard · 原生 vs JS 热更',
      '复合组件：内嵌 BannerCard（注解）+ 私有/非私有自定义 widget 双路径',
      CompareTest(
        native: DashboardCard(),
        js: JsUiWidget(
          jsAsset: _patchUrl('DashboardCard', 'components/composite_component.js'),
          // 嵌套组件（BannerCard）与公开 widget（LabeledDivider）都由生成器
          // 连带翻译进同一产物（JS 类引用），运行时直接 new，使用方无需声明依赖。
          // 只有标了 @PatchIgnore 的私有组件走宿主注册（私有类跨库不可见），
          // 其等价实现见 main() 里的 jsWidgetRegistry.register。
        ),
      ),
    ),
    _DemoEntry(
      '三方库 · 列表',
      'provider / getx 状态管理 + path_provider / permission_handler / dio 工具类 + uuid 同名类',
      const ThirdPartyShowcase(),
    ),
    _DemoEntry(
      'InheritedCard · 原生 vs JS 热更',
      'InheritedWidget：祖先数据共享，updateShouldNotify 精确重建依赖者',
      CompareTest(
        native: InheritedCard(),
        js: JsUiWidget(jsAsset: _patchUrl('InheritedCard', 'components/inherited_widget_demo.js')),
      ),
    ),
    _DemoEntry(
      'HelloCard · JS 双实例隔离',
      '同屏两个 JsUiWidget 实例：单 runtime 内按 pageKey 隔离，状态互不共享',
      _TwinTest(label: 'HelloCard'),
    ),
    _DemoEntry(
      'Props 更新 · JS 热更',
      '宿主重建 JsUiWidget 并传入新 props：JS 侧 __applyProps + 重建',
      _PropsUpdateDemo(),
    ),
    _DemoEntry(
      'TestWidget · 局部 widget 变量',
      'Text text = Text(); final items = [Text(), Text()]; 局部变量与列表按元素翻译',
      CompareTest(
        native: const TestWidget(),
        js: JsUiWidget(
          jsAsset: _patchUrl('TestWidget', 'components/test_widget.js'),
        ),
      ),
    ),
    _DemoEntry(
      '异步归属 · JS 热更',
      'Timer 回调里创建 GlobalKey：验证随组件释放，退出后 leak-check 应为 clean',
      CompareTest(
        native: const LeakDemoCard(),
        js: JsUiWidget(
          jsAsset: _patchUrl('LeakDemoCard', 'components/leak_demo_card.js'),
        ),
      ),
    ),
    _DemoEntry(
      '生命周期 · 挂载失败回滚',
      'initState 注册持久帧回调后抛错：验证 __abortRoot 广播 rootClose，回调随根丢弃（退出后 leak-check 应为 clean）',
      const _MountFailDemo(),
    ),
    _DemoEntry('基础语法 · 列表', 'Dart mixin / extension：State 扩展日志、String 扩展打印（原生 vs JS 热更）', const GrammarShowcase()),
    _DemoEntry(
      'ListView · 懒加载日志',
      '原生 vs JS：children / builder / separated / itemExtent，对照 initState / dispose 日志',
      CompareTest(
        native: const ListViewDetail(),
        js: JsUiWidget(
          jsAsset: _patchUrl('ListViewDetail', 'components/list_view_detail.js'),
        ),
      ),
    ),
    _DemoEntry('常用组件 · 列表', '分组列出 Flutter 常用组件，点击进入详情页（原生 vs JS 热更）', const WidgetShowcase()),
  ];

  /// 清除补丁缓存（调试入口）：删本地解压产物 + 重置运行时模块缓存。
  /// 清完重新进入热更页面即拉取最新产物（见 [JsRuntimeManager.clearCache]）。
  Future<void> _clearCache(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await JsRuntimeManager.clearCache();
    messenger.showSnackBar(
      const SnackBar(content: Text('已清除补丁缓存，重新进入热更页面即拉取最新产物')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('注解组件 → JS 热修复 Demo'),
        actions: [
          IconButton(
            tooltip: '清除补丁缓存',
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () => _clearCache(context),
          ),
        ],
      ),
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

/// props 更新演示：宿主 State 每次重建都会给 JsUiWidget 传新的 props。
/// JS 侧由 `__jsui.updateProps` 更新根实例 props、重跑 `__applyProps` 并重建。
class _PropsUpdateDemo extends StatefulWidget {
  const _PropsUpdateDemo();

  @override
  State<_PropsUpdateDemo> createState() => _PropsUpdateDemoState();
}

class _PropsUpdateDemoState extends State<_PropsUpdateDemo> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _revision++),
                child: Text('宿主更新 props（第 $_revision 次）'),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('点击后 JsUiWidget 收到新 props，JS 侧更新字段并重建'),
              ),
            ],
          ),
        ),
        Expanded(
          child: JsUiWidget(
            jsAsset: _patchUrl('StatelessCard', 'components/stateless_card.js'),
            params: {
              'title': 'Props 更新 #$_revision',
              'subtitle': '宿主重建 JsUiWidget，新 props 已下发到 JS',
              'badge': 'R$_revision',
            },
          ),
        ),
      ],
    );
  }
}

/// 双实例隔离测试：同屏渲染两个相同组件（单 runtime 内按 pageKey 隔离）。
/// 验证：点其中一个的按钮，另一个的状态不受影响（roots[pageKey] 隔离）。
class _TwinTest extends StatelessWidget {
  const _TwinTest({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$label #1', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        JsUiWidget(jsAsset: _patchUrl('HelloCard', 'components/hello_component.js')),
        const Divider(height: 32),
        Text('$label #2', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        JsUiWidget(jsAsset: _patchUrl('RichTextDetail', 'components/rich_text_detail.js')),
      ],
    );
  }
}

/// 挂载失败回滚演示：JS 侧 `initState` 抛错，验证 `__abortRoot` 也广播
/// `onRootClose`（持久帧回调随根丢弃）。页面会停在 boot 失败态，返回列表即可。
class _MountFailDemo extends StatelessWidget {
  const _MountFailDemo();

  @override
  Widget build(BuildContext context) => JsUiWidget(
        jsAsset: _patchUrl('MountFailCard', 'components/mount_fail_card.js'),
      );
}
