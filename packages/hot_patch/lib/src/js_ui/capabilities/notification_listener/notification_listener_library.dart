// ===== 能力：NotificationListener（滚动通知回传）=====
//
// 纯宿主侧能力：没有句柄通道、没有 JS 片段，只有桥接组件注册（把宿主
// ScrollNotification 的 metrics 快照经 invoke 回传 JS 事件方法）。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'notification_listener_bridge.dart';

/// NotificationListener 能力接入声明。
class NotificationListenerLibrary extends JsUiLibrary {
  const NotificationListenerLibrary();

  @override
  String get id => 'notification-listener';

  @override
  void registerWidgets(JsWidgetRegistry r) => registerNotificationWidgets(r);
}
