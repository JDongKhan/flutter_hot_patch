// ===== 能力：ScrollController 代理 =====
//
// 与 capabilities/scroll_controller/ 的桥接表同一能力域：JS 片段（代理类）走
// [jsFragments]，句柄通道走 [ensureChannels]，宿主组件（ListView / GridView /
// SingleChildScrollView 等）走 [registerWidgets]。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'scroll_controller_bridge.dart';
import 'scroll_controller_js.dart';

/// ScrollController 能力接入声明。
class ScrollControllerLibrary extends JsUiLibrary {
  const ScrollControllerLibrary();

  @override
  String get id => 'scroll-controller';

  @override
  List<String> get jsFragments => const [scrollControllerJsSource];

  @override
  void ensureChannels() => ensureScrollControllerChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerScrollWidgets(r);
}
