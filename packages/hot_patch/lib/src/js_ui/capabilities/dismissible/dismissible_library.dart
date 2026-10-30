// ===== 能力：Dismissible（滑动删除）=====
//
// 宿主组件注册，实现见 dismissible_bridge.dart。confirmDismiss 的异步结果走
// 通用入口 `JsRuntimeManager.invokeAwait`，本能力没有专属宿主通道，也不再有
// 独立 JS 片段。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'dismissible_bridge.dart';

/// Dismissible 滑动删除能力接入声明。
class DismissibleLibrary extends JsUiLibrary {
  const DismissibleLibrary();

  @override
  String get id => 'dismissible';

  @override
  void registerWidgets(JsWidgetRegistry r) => registerDismissibleWidgets(r);
}
