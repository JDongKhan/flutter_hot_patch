// ===== 能力：LayoutBuilder =====
//
// 纯宿主侧能力：无句柄通道、无 JS 片段（JS 侧片段随运行时产物发布，见生成器
// layout_builder_js.dart），只登记宿主组件映射——LayoutBuilder 结点 → 真实
// `LayoutBuilder` + 父约束回传。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'layout_builder_bridge.dart';

/// LayoutBuilder 能力接入声明。
class LayoutBuilderLibrary extends JsUiLibrary {
  const LayoutBuilderLibrary();

  @override
  String get id => 'layout_builder';

  @override
  void registerWidgets(JsWidgetRegistry r) => registerLayoutBuilderWidgets(r);
}
