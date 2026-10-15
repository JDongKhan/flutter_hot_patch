// ===== 能力：TabController / Drawer =====
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'tab_controller_js.dart';
import 'tab_drawer_bridge.dart';

/// TabController 能力接入声明（含 TabBar/TabBarView/Drawer 等宿主组件）。
class TabDrawerLibrary extends JsUiLibrary {
  const TabDrawerLibrary();

  @override
  String get id => 'tab-drawer';

  @override
  List<String> get jsFragments => const [tabControllerJsSource];

  @override
  void ensureChannels() => ensureTabControllerChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerTabDrawerWidgets(r);
}
