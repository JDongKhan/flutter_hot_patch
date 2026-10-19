// ===== 能力：CachedNetworkImage 磁盘缓存网络图 =====
//
// 三方包 cached_network_image 的接入声明：JS 片段（无）+ 宿主通道（无）+ 桥接
// 组件注册，实现见 cached_network_image_bridge.dart。属「纯宿主侧能力」——与
// NotificationListener 同类，位置不影响产物。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'cached_network_image_bridge.dart';

/// CachedNetworkImage（磁盘缓存网络图）能力接入声明。
class CachedNetworkImageLibrary extends JsUiLibrary {
  const CachedNetworkImageLibrary();

  @override
  String get id => 'cached-network-image';

  @override
  void registerWidgets(JsWidgetRegistry r) =>
      registerCachedNetworkImageWidgets(r);
}
