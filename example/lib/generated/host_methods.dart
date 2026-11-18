// GENERATED CODE - DO NOT MODIFY BY HAND
//
// 由 dynamic_flutter_generator 的 hostRegisterBuilder 扫描全包
// `@HostInjected` 方法生成。用法（main() 里交给 initJsUi 统一装配）：
//
//   initJsUi(libraries: [...], hostMethods: hostMethods);
//
// 每项形状固定：{name: 通道名, handler: 宿主实现}。

import '../base/app_router.dart';
import '../base/canvas_image.dart';
import '../base/dio_bridge.dart';
import '../base/host_http.dart';
import '../base/platform_tools.dart';
import '../base/web_view.dart';
import 'package:hot_module_base/src/account_center.dart';
import 'package:hot_module_base/src/network.dart';

/// 本包全部 `@HostInjected` 宿主方法：`{name: 通道名, handler: 实现}`。
/// 交给 `initJsUi(hostMethods: hostMethods)` 一次注册。
List<Map<String, Object?>> get hostMethods => [
  {'name': 'openChannel', 'handler': AppRouter.openChannel},
  {'name': 'openCityPicker', 'handler': AppRouter.openCityPicker},
  {'name': 'openDemoList', 'handler': AppRouter.openDemoList},
  {'name': 'openHeroTarget', 'handler': AppRouter.openHeroTarget},
  {'name': 'openLogin', 'handler': AppRouter.openLogin},
  {'name': 'openNotifications', 'handler': AppRouter.openNotifications},
  {'name': 'openOrder', 'handler': AppRouter.openOrder},
  {'name': 'openOrders', 'handler': AppRouter.openOrders},
  {'name': 'openPost', 'handler': AppRouter.openPost},
  {'name': 'openResource', 'handler': AppRouter.openResource},
  {'name': 'openSpot', 'handler': AppRouter.openSpot},
  {'name': 'openUserCenter', 'handler': AppRouter.openUserCenter},
  {'name': 'openWidgetShowcase', 'handler': AppRouter.openWidgetShowcase},
  {'name': 'pop', 'handler': AppRouter.pop},
  {'name': 'pushNamed', 'handler': AppRouter.pushNamed},
  {'name': 'toast', 'handler': AppRouter.toast},
  {'name': 'loadCanvasImage', 'handler': CanvasImage.load},
  {'name': 'dioRequest', 'handler': DioBridge.request},
  {'name': 'httpGet', 'handler': HostHttp.get},
  {'name': 'appVersion', 'handler': PlatformTools.appVersion},
  {'name': 'documentsPath', 'handler': PlatformTools.documentsPath},
  {'name': 'photoPermissionStatus', 'handler': PlatformTools.photoPermissionStatus},
  {'name': 'requestPhotoPermission', 'handler': PlatformTools.requestPhotoPermission},
  {'name': 'tempPath', 'handler': PlatformTools.tempPath},
  {'name': 'open', 'handler': WebView.open},
  {'name': 'getUserName', 'handler': AccountCenter.getUserName},
  {'name': 'post', 'handler': Network.post},
];
