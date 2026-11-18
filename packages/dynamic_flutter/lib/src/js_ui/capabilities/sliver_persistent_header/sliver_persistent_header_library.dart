// ===== 能力：SliverPersistentHeader =====
//
// 纯宿主侧能力：无句柄通道、无 JS 片段（JS 侧类随运行时产物发布，见生成器
// widget_module_builder 的 jsSliverPersistentHeaderComponent），只登记宿主组件
// 映射——结点 → 真实 `SliverPersistentHeader` + delegate.build 回传。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'sliver_persistent_header_bridge.dart';

/// SliverPersistentHeader 能力接入声明。
class SliverPersistentHeaderLibrary extends JsUiLibrary {
  const SliverPersistentHeaderLibrary();

  @override
  String get id => 'sliver_persistent_header';

  @override
  void registerWidgets(JsWidgetRegistry r) =>
      registerSliverPersistentHeaderWidgets(r);
}
