import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dynamic_flutter/dynamic_flutter.dart';
import 'package:hot_module_base/hot_module_base.dart';

import 'app/app.dart';
import 'base/app_log_console.dart';
import 'base/app_routes.dart';
import 'base/dev_server.dart';
import 'base/patch_config.dart';
import 'components/compare_pane.dart';
import 'components/composite_component.dart';
import 'components/hello_component.dart';
import 'components/inherited_widget_demo.dart';
import 'components/leak_demo_card.dart';
import 'components/perf_list_page.dart';
import 'components/stateless_card.dart';
import 'components/widget_showcase.dart';
import 'components/test_widget.dart';
import 'custom/custom_capabilities.dart';
import 'custom_component.dart';
import 'generated/host_methods.dart';
import 'grammar/grammar_showcase.dart';
import 'third_party/third_party_showcase.dart';

void main() {
  // 日志捕获：print / debugPrint（含 Flutter 框架与 dynamic_flutter 的 JsLog，
  // JS 侧 print 最终也走这里）全部收进 AppLogCenter，供右侧日志控制台展示。
  installLogCapture();
  runZoned(() {
    // binding 与 runApp 必须在同一个 zone 内初始化（否则触发 Zone mismatch）。
    WidgetsFlutterBinding.ensureInitialized();
    // 本地服务地址统一从 base/dev_server.dart 取：mock 接口与补丁 zip 共用一处。
    Network.baseUrl = devServerBaseUrl;
    // UI 能力装配唯一入口，一次完成四件事：
    //   1. 注册自定义能力（lib/custom/**，清单见 custom_capabilities.dart：
    //      VisibilityDetector / EasyRefresh / WaterfallFlow）；
    //   2. 就位全部能力通道、建宿主组件表、注册内建宿主方法；
    //   3. 注册 @HostInjected 宿主方法（JS 侧方法体换成 `_app_host_.invoke(...)`，
    //      调用点与 Dart 一比一；清单由 build_runner 扫描注解生成到
    //      lib/generated/host_methods.dart，`hostMethods` 直接传进来即可）。
    // 必须在任何 JsUiWidget 渲染之前调用（JsUiWidget 只校验、不代劳）。
    initJsUi(
      libraries: customJsUiLibraries,
      hostMethods: hostMethods,
    );
    // 生命周期验证期间临时打开双端句柄进出日志（验证后恢复注释）。
    // JsRuntimeManager.setVerboseCacheTrace(true);
    // 无 JS 产物的组件（产物里的 `Component` 占位结点）的原生实现：**全局一次注册**
    // （进程内共用一张表，不随 JsUiWidget 实例透传），位置与 initJsUi 同段——
    // runApp 之前。重复注册同名会覆盖（覆盖时告警），故不要放进 build()。
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
      // 全部二级页走命名路由：页面构造只维护在 base/app_routes.dart 一张表里。
      onGenerateRoute: appOnGenerateRoute,
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

/// 一个 Demo 场景条目。
///
/// [right] 为 null 表示该入口只有一页实现（导航列表页等），按单页打开；
/// 否则左右两侧成对打开 [ComparePane]（宽屏双栏 / 窄屏切换）。
class _DemoEntry {
  final String title;
  final String subtitle;

  /// 左栏（原生组件）；单页入口时它是唯一内容。
  final Widget left;

  /// 右栏（JS 热更）；null = 该入口没有对照实现。
  final Widget? right;

  final String leftLabel;
  final String rightLabel;

  /// 窄屏默认显示右栏。
  final bool initialShowRight;

  /// 两侧内容自带滚动 / Scaffold 的整页 demo。
  final bool fillPane;

  /// 两侧内容各自带 AppBar（如「完整 App」）。
  final bool innerAppBar;

  const _DemoEntry(
    this.title,
    this.subtitle, {
    required this.left,
    this.right,
    this.leftLabel = '原生组件',
    this.rightLabel = 'JS 热更（JsUiWidget）',
    this.initialShowRight = true,
    this.fillPane = false,
    this.innerAppBar = false,
  });
}

/// Demo 场景列表页。
class DemoListPage extends StatelessWidget {
  const DemoListPage({super.key});

  static final _demos = <_DemoEntry>[
    _DemoEntry(
      '完整 App · 原生',
      '四 tab 外壳（AppShell）原生渲染：首页 / 社区 / 订单 / 我的；宽屏左侧为原生、右侧为 JS',
      left: const AppShell(),
      right: AppShellJsPage(jsAsset: patchUrl('AppShell', 'app/app.js')),
      fillPane: true,
      innerAppBar: true,
      initialShowRight: false,
    ),
    _DemoEntry(
      '完整 App · JS 热更',
      'AppShell 整壳由 JS 补丁渲染，四个 tab 页面也是 JS 产物（连带翻译）',
      left: const AppShell(),
      right: AppShellJsPage(jsAsset: patchUrl('AppShell', 'app/app.js')),
      fillPane: true,
      innerAppBar: true,
    ),
    _DemoEntry(
      'HelloCard · 原生 vs JS 热更',
      '同屏对比：正常组件与 JS 补丁的渲染与逻辑',
      left: HelloCard(),
      right: JsUiWidget(jsAsset: patchUrl('HelloCard', 'components/hello_component.js')),
    ),
    _DemoEntry(
      'DashboardCard · 原生 vs JS 热更',
      '复合组件：内嵌 BannerCard（注解）+ 私有/非私有自定义 widget 双路径',
      left: DashboardCard(),
      // 嵌套组件（BannerCard）与公开 widget（LabeledDivider）都由生成器连带
      // 翻译进同一产物（JS 类引用），运行时直接 new，使用方无需声明依赖。
      // 只有标了 @PatchIgnore 的私有组件走宿主注册（私有类跨库不可见），
      // 其等价实现见 main() 里的 jsWidgetRegistry.register。
      right: JsUiWidget(jsAsset: patchUrl('DashboardCard', 'components/composite_component.js')),
    ),
    _DemoEntry(
      '三方库 · 列表',
      'provider / getx 状态管理 + path_provider / permission_handler / dio 工具类 + uuid 同名类',
      left: const ThirdPartyShowcase(),
    ),
    _DemoEntry(
      'InheritedCard · 原生 vs JS 热更',
      'InheritedWidget：祖先数据共享，updateShouldNotify 精确重建依赖者',
      left: InheritedCard(),
      right: JsUiWidget(jsAsset: patchUrl('InheritedCard', 'components/inherited_widget_demo.js')),
    ),
    _DemoEntry(
      'HelloCard · JS 双实例隔离',
      '同屏两个 JsUiWidget 实例：单 runtime 内按 pageKey 隔离，状态互不共享',
      left: JsUiWidget(jsAsset: patchUrl('HelloCard', 'components/hello_component.js')),
      right: JsUiWidget(jsAsset: patchUrl('RichTextDetail', 'components/rich_text_detail.js')),
      leftLabel: 'JS 实例 #1（HelloCard）',
      rightLabel: 'JS 实例 #2（RichTextDetail）',
      initialShowRight: false,
    ),
    _DemoEntry(
      'Props 更新 · JS 热更',
      '宿主重建 JsUiWidget 并传入新 props：JS 侧 __applyProps + 重建（左右各一套按钮）',
      left: _PropsUpdateDemo(nativeSide: true),
      right: _PropsUpdateDemo(),
      leftLabel: '原生 StatelessCard',
      rightLabel: 'JS 热更（StatelessCard）',
      fillPane: true,
    ),
    _DemoEntry(
      'TestWidget · 局部 widget 变量',
      'Text text = Text(); final items = [Text(), Text()]; 局部变量与列表按元素翻译',
      left: const TestWidget(),
      right: JsUiWidget(jsAsset: patchUrl('TestWidget', 'components/test_widget.js')),
    ),
    _DemoEntry(
      '异步归属 · JS 热更',
      'Timer 回调里创建 GlobalKey：验证随组件释放，退出后 leak-check 应为 clean',
      left: const LeakDemoCard(),
      right: JsUiWidget(jsAsset: patchUrl('LeakDemoCard', 'components/leak_demo_card.js')),
    ),
    _DemoEntry(
      '生命周期 · 挂载失败回滚',
      'initState 注册持久帧回调后抛错：验证 __abortRoot 广播 rootClose，回调随根丢弃（退出后 leak-check 应为 clean）',
      left: const _MountFailDemo(),
    ),
    _DemoEntry(
      '基础语法 · 列表',
      'Dart mixin / extension：State 扩展日志、String 扩展打印（原生 vs JS 热更）',
      left: const GrammarShowcase(),
    ),
    _DemoEntry(
      '性能 · 大图长列表',
      '单个 ListView.builder：200 项通栏大图 + 每项隐式动画，宽屏左右同时跑原生与 JS',
      left: const PerfListPage(),
      right: JsUiWidget(jsAsset: patchUrl('PerfListPage', 'components/perf_list_page.js')),
      fillPane: true,
    ),
    _DemoEntry(
      '常用组件 · 列表',
      '分组列出 Flutter 常用组件，点击进入详情页（原生 vs JS 热更）',
      left: const WidgetShowcase(),
    ),
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
                  builder: (_) => d.right == null
                      ? _SingleDemoPage(title: d.title, child: d.left)
                      : ComparePane(
                          title: d.title,
                          left: d.left,
                          right: d.right!,
                          leftLabel: d.leftLabel,
                          rightLabel: d.rightLabel,
                          initialShowRight: d.initialShowRight,
                          fillPane: d.fillPane,
                          innerAppBar: d.innerAppBar,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 单个场景页的简洁外壳（仅用于只有一页实现的入口）。
/// 对比类入口统一走 [ComparePane]。
class _SingleDemoPage extends StatelessWidget {
  const _SingleDemoPage({required this.title, required this.child});

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

/// props 更新演示（单侧实例）：宿主 State 每次重建都会给子组件传新 props。
/// JS 侧由 `__jsui.updateProps` 更新根实例 props、重跑 `__applyProps` 并重建；
/// 原生侧直接构造新的 StatelessCard 对照。左右各放一个由 [ComparePane] 装配。
class _PropsUpdateDemo extends StatefulWidget {
  const _PropsUpdateDemo({this.nativeSide = false});

  /// true = 原生 StatelessCard；false = JS 热更。
  final bool nativeSide;

  @override
  State<_PropsUpdateDemo> createState() => _PropsUpdateDemoState();
}

class _PropsUpdateDemoState extends State<_PropsUpdateDemo> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    final title = 'Props 更新 #$_revision';
    final subtitle = widget.nativeSide
        ? '原生 StatelessCard：重建即拿到新 props'
        : '宿主重建 JsUiWidget，新 props 已下发到 JS';
    final badge = 'R$_revision';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _revision++),
                child: Text('更新 props（第 $_revision 次）'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.nativeSide ? '原生侧：直接重建 StatelessCard' : 'JS 侧：__applyProps + 重建',
                ),
              ),
            ],
          ),
        ),
        // 两侧用同一层约束：都放进 SingleChildScrollView，卡片按内容高度收缩，
        // 避免 JS 侧被 Expanded 铺满、原生侧缩成小卡片导致左右不一致。
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: widget.nativeSide
                ? StatelessCard(
                    title: title,
                    subtitle: subtitle,
                    badge: badge,
                  )
                : JsUiWidget(
                    jsAsset: patchUrl('StatelessCard', 'components/stateless_card.js'),
                    params: {
                      'title': title,
                      'subtitle': subtitle,
                      'badge': badge,
                    },
                  ),
          ),
        ),
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
        jsAsset: patchUrl('MountFailCard', 'components/mount_fail_card.js'),
      );
}
