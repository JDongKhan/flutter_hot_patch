// ===== 能力：拖拽（Draggable / LongPressDraggable / DragTarget）=====
//
// 宿主组件注册见 drag_bridge.dart；JS 侧的身份表与事件详情还原随运行时产物
// 发布（生成器 runtime/js/drag_js.dart）。本能力不新增跨语言句柄 kind。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'drag_bridge.dart';

/// 拖拽能力接入声明。
class DragLibrary extends JsUiLibrary {
  const DragLibrary();

  @override
  String get id => 'drag';

  @override
  void registerWidgets(JsWidgetRegistry r) => registerDragWidgets(r);
}
