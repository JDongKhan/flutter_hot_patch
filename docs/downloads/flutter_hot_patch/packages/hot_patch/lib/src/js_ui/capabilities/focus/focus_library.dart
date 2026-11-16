// ===== 能力：Focus（焦点控制）=====
//
// 宿主组件注册 + FocusNode 句柄通道，实现见 focus_bridge.dart；JS 片段
// （FocusNode 代理类）随运行时产物发布，见生成器 focus_js.dart。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'focus_bridge.dart';

/// Focus 焦点控制能力接入声明。
class FocusLibrary extends JsUiLibrary {
  const FocusLibrary();

  @override
  String get id => 'focus';

  @override
  void ensureChannels() => ensureFocusChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerFocusWidgets(r);
}
