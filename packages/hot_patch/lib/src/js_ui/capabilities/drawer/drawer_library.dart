// ===== 能力：Drawer 家族 =====
//
// 纯宿主侧能力：没有句柄通道、没有 JS 片段，只有桥接组件注册（Drawer /
// DrawerHeader + 抽屉关闭作用域）。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'drawer_bridge.dart';

/// Drawer 家族能力接入声明。
class DrawerLibrary extends JsUiLibrary {
  const DrawerLibrary();

  @override
  String get id => 'drawer';

  @override
  void registerWidgets(JsWidgetRegistry r) => registerDrawerWidgets(r);
}
