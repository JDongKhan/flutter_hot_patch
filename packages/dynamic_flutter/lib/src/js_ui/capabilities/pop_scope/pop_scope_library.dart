// ===== 能力：PopScope =====
//
// 纯宿主侧能力：无句柄 kind、无 JS 片段（PopScope 的拦截语义全在 Flutter 的
// ModalRoute 里，JS 侧只提供一个回调闭包），只登记宿主组件映射。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'pop_scope_bridge.dart';

class PopScopeLibrary extends JsUiLibrary {
  const PopScopeLibrary();

  @override
  String get id => 'pop_scope';

  @override
  void registerWidgets(JsWidgetRegistry r) => registerPopScopeWidgets(r);
}
