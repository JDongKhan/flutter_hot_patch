// 能力接入：OverlayPortal 三件套（宿主渲染 + 两个跨语言对象句柄）。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'overlay_portal_bridge.dart';

class OverlayPortalLibrary extends JsUiLibrary {
  const OverlayPortalLibrary();

  @override
  String get id => 'overlay_portal';

  @override
  void ensureChannels() => ensureOverlayPortalChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerOverlayPortalWidgets(r);
}
