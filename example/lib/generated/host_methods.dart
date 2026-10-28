// GENERATED CODE - DO NOT MODIFY BY HAND
//
// 由 hot_patch_generator 的 hostRegisterBuilder 扫描全包
// `@HostInjected` 方法生成。用法（main() 里调用一次）：
//
//   registerHostMethods();
//
// 注册目标默认指向配套运行时（package:hot_patch/hot_patch.dart），
// 需要换运行时实现时用 build.yaml 的 register_import / register_call 覆盖。

import 'package:hot_patch/hot_patch.dart';

import '../base/app_router.dart';
import '../base/web_view.dart';
import 'package:hot_module_base/src/account_center.dart';
import 'package:hot_module_base/src/network.dart';

/// 注册本包全部 `@HostInjected` 宿主方法（无注解时为空实现）。
void registerHostMethods() {
  JsRuntimeManager.registerHostMethod('openChannel', AppRouter.openChannel);
  JsRuntimeManager.registerHostMethod('openCityPicker', AppRouter.openCityPicker);
  JsRuntimeManager.registerHostMethod('openDemoList', AppRouter.openDemoList);
  JsRuntimeManager.registerHostMethod('openHeroTarget', AppRouter.openHeroTarget);
  JsRuntimeManager.registerHostMethod('openLogin', AppRouter.openLogin);
  JsRuntimeManager.registerHostMethod('openNotifications', AppRouter.openNotifications);
  JsRuntimeManager.registerHostMethod('openOrder', AppRouter.openOrder);
  JsRuntimeManager.registerHostMethod('openOrders', AppRouter.openOrders);
  JsRuntimeManager.registerHostMethod('openPost', AppRouter.openPost);
  JsRuntimeManager.registerHostMethod('openResource', AppRouter.openResource);
  JsRuntimeManager.registerHostMethod('openSearch', AppRouter.openSearch);
  JsRuntimeManager.registerHostMethod('openSpot', AppRouter.openSpot);
  JsRuntimeManager.registerHostMethod('openWidgetShowcase', AppRouter.openWidgetShowcase);
  JsRuntimeManager.registerHostMethod('pop', AppRouter.pop);
  JsRuntimeManager.registerHostMethod('toast', AppRouter.toast);
  JsRuntimeManager.registerHostMethod('open', WebView.open);
  JsRuntimeManager.registerHostMethod('getUserName', AccountCenter.getUserName);
  JsRuntimeManager.registerHostMethod('post', Network.post);
}
