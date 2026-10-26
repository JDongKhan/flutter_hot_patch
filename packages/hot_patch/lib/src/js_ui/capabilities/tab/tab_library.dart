// ===== 能力：Tab 家族 =====
//
// 片段提供 JS 侧 TabController 代理类，通道登记 `ctrl/Tab` 句柄；宿主组件为
// DefaultTabController / TabBar / Tab / TabBarView（见 tab_bridge.dart）。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'tab_bridge.dart';

/// Tab 家族能力接入声明。
class TabLibrary extends JsUiLibrary {
  const TabLibrary();

  @override
  String get id => 'tab';

  @override
  void ensureChannels() => ensureTabControllerChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerTabWidgets(r);
}
