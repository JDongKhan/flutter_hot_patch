// ===== 能力：TextEditingController 代理 =====
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'text_editing_controller_bridge.dart';

/// TextEditingController 能力接入声明。
class TextEditingControllerLibrary extends JsUiLibrary {
  const TextEditingControllerLibrary();

  @override
  String get id => 'text-editing-controller';

  @override
  void ensureChannels() => ensureTextEditingControllerChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerTextWidgets(r);
}
