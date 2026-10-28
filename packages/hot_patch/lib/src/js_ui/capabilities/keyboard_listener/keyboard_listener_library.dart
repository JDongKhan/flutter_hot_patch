// ===== 能力：KeyboardListener（按键事件）=====
//
// 宿主组件注册 + KeyEvent 派发，实现见 keyboard_listener_bridge.dart；JS 片段
// （KeyEvent / LogicalKeyboardKey 镜像与 `__jsuiKeyEvent`）随运行时产物发布，
// 见生成器 keyboard_listener_js.dart。FocusNode 句柄复用 focus 能力的句柄桥，
// 本能力不额外登记 kind。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'keyboard_listener_bridge.dart';

/// KeyboardListener 能力接入声明。
class KeyboardListenerLibrary extends JsUiLibrary {
  const KeyboardListenerLibrary();

  @override
  String get id => 'keyboard_listener';

  @override
  void registerWidgets(JsWidgetRegistry r) =>
      registerKeyboardListenerWidgets(r);
}
