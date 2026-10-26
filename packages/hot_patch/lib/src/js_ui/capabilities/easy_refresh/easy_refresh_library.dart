// ===== 能力：EasyRefresh 下拉刷新 =====
//
// 三方包 flutter_easy_refresh 的接入声明：JS 片段（异步完成回程）+ 宿主通道
// （token 结算）+ 桥接组件注册，实现见 easy_refresh_bridge.dart / easy_refresh_js.dart。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'easy_refresh_bridge.dart';

/// EasyRefresh（下拉刷新 / 上拉加载容器）能力接入声明。
class EasyRefreshLibrary extends JsUiLibrary {
  const EasyRefreshLibrary();

  @override
  String get id => 'easy-refresh';

  @override
  void ensureChannels() => ensureEasyRefreshChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerEasyRefreshWidgets(r);
}
