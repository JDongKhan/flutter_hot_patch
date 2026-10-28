// ===== 能力：Dismissible（滑动删除）=====
//
// 宿主组件注册 + confirmDismiss 异步回程通道，实现见 dismissible_bridge.dart；
// JS 片段（`__jsuiAwaitValue`）随运行时产物发布，见生成器 dismissible_js.dart。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'dismissible_bridge.dart';

/// Dismissible 滑动删除能力接入声明。
class DismissibleLibrary extends JsUiLibrary {
  const DismissibleLibrary();

  @override
  String get id => 'dismissible';

  @override
  void ensureChannels() => ensureDismissibleChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerDismissibleWidgets(r);
}
