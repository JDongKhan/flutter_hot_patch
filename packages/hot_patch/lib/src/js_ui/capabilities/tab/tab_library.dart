// ===== 能力：Tab 家族 =====
//
// 片段提供 JS 侧 TabController 代理类，通道登记 `ctrl/Tab` 句柄；宿主组件为
// DefaultTabController / TabBar / Tab / TabBarView（见 tab_bridge.dart）。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'tab_bridge.dart';
import 'tab_controller_js.dart';

/// Tab 家族能力接入声明。
class TabLibrary extends JsUiLibrary {
  const TabLibrary();

  @override
  String get id => 'tab';

  @override
  List<String> get jsFragments => const [tabControllerJsSource];

  @override
  void ensureChannels() => ensureTabControllerChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerTabWidgets(r);

  /// TabBarView 是 PageView：每个子页被 `SliverFillViewport` 强制成整屏，
  /// 零尺寸占位布局中性，故子页可延迟到宿主 inflate 时才挂载 —— 只有当前页
  /// 跑 initState（与 Flutter 一致）。名单在 Dart 侧声明，由
  /// [jsUiLazyChildHostRegistrations] 注入运行时。
  @override
  Map<String, List<String>> get lazyChildHostTypes => const {'TabBarView': []};
}
