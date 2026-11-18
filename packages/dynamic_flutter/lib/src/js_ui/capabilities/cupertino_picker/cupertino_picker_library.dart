// ===== 能力：CupertinoPicker + FixedExtentScrollController =====
//
// 与 capabilities/cupertino_picker/ 的桥接表同一能力域：宿主组件
// （CupertinoPicker）走 [registerWidgets]，控制器句柄通道走 [ensureChannels]。
// JS 侧代理类（FixedExtentScrollController）随 `patch/flutter.js` 发布
// （生成器 builders/core_js_builder/js/flutter/scroll_controller_js.dart）。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'cupertino_picker_bridge.dart';

/// CupertinoPicker 能力接入声明。
class CupertinoPickerLibrary extends JsUiLibrary {
  const CupertinoPickerLibrary();

  @override
  String get id => 'cupertino-picker';

  @override
  void ensureChannels() => ensureCupertinoPickerChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerCupertinoPickerWidgets(r);
}
