// ===== 自定义能力：EasyRefresh 下拉刷新（三方包 easy_refresh）=====
//
// 三方包不是运行时内建能力：宿主桥接放在本工程 `lib/custom/` 下，由
// `registerCustomCapabilities()` 在 `runApp` 之前注册，hot_patch 包零改动。
// JS 侧类（EasyRefresh / EasyRefreshController）见工程根 `js/easy_refresh.js`，
// 构建时拷贝为 `patch/packages/easy_refresh.js`。
import 'package:hot_patch/hot_patch.dart';

import 'easy_refresh_bridge.dart';

/// EasyRefresh（下拉刷新 / 上拉加载容器）能力接入声明。
class CustomEasyRefreshLibrary extends JsUiLibrary {
  const CustomEasyRefreshLibrary();

  @override
  String get id => 'easy_refresh';

  @override
  void ensureChannels() => ensureEasyRefreshChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerEasyRefreshWidgets(r);
}
