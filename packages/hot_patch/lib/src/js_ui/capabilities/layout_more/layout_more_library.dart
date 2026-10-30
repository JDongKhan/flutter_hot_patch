// ===== 能力：布局 / 交互补充 =====
//
// 一批纯映射的单子包装组件（Tooltip / IgnorePointer / AbsorbPointer /
// RepaintBoundary / Baseline / FittedBox / RotatedBox / IntrinsicWidth /
// IntrinsicHeight / LimitedBox / InteractiveViewer），不新增跨语言通道。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'layout_more_bridge.dart';

/// 布局 / 交互补充能力接入声明。
class LayoutMoreLibrary extends JsUiLibrary {
  const LayoutMoreLibrary();

  @override
  String get id => 'layout_more';

  @override
  void registerWidgets(JsWidgetRegistry r) => registerLayoutMoreWidgets(r);
}
