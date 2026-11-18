// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/base/app_router.dart 自动生成
// 重新生成：dart run build_runner build

import '../flutter.js';

// 模型 AppRoutes
export class AppRoutes {
  constructor() {
  }
  // 命名构造 AppRoutes._
  static _(args) {
    const __o = new AppRoutes(args);
    return __o;
  }
}
AppRoutes.demoList = "/demo-list";
AppRoutes.heroTarget = "/hero-target";
AppRoutes.search = "/search";
AppRoutes.spot = "/spot";
AppRoutes.post = "/post";
AppRoutes.resource = "/resource";
AppRoutes.order = "/order";
AppRoutes.channel = "/channel";
AppRoutes.notifications = "/notifications";
AppRoutes.orders = "/orders";
AppRoutes.widgetShowcase = "/widget-showcase";
AppRoutes.userCenter = "/user-center";
AppRoutes.login = "/login";

// 模型 AppRouter
export class AppRouter {
  constructor() {
  }
  static pushNamed(name, routeArgs) {
    return _app_host_.invoke("pushNamed", Array.prototype.slice.call(arguments));
  }
  static openHeroTarget(tag, label) {
    return _app_host_.invoke("openHeroTarget", Array.prototype.slice.call(arguments));
  }
  static openSpot(id) {
    return _app_host_.invoke("openSpot", Array.prototype.slice.call(arguments));
  }
  static async openCityPicker(current) {
    return _app_host_.invoke("openCityPicker", Array.prototype.slice.call(arguments));
  }
  static async openChannel(title, emoji) {
    return _app_host_.invoke("openChannel", Array.prototype.slice.call(arguments));
  }
  static openNotifications() {
    return _app_host_.invoke("openNotifications", Array.prototype.slice.call(arguments));
  }
  static openPost(id) {
    return _app_host_.invoke("openPost", Array.prototype.slice.call(arguments));
  }
  static openResource(id) {
    return _app_host_.invoke("openResource", Array.prototype.slice.call(arguments));
  }
  static openOrder(no) {
    return _app_host_.invoke("openOrder", Array.prototype.slice.call(arguments));
  }
  static async pop() {
    return _app_host_.invoke("pop", Array.prototype.slice.call(arguments));
  }
  static async openLogin() {
    return _app_host_.invoke("openLogin", Array.prototype.slice.call(arguments));
  }
  static async openUserCenter() {
    return _app_host_.invoke("openUserCenter", Array.prototype.slice.call(arguments));
  }
  static async openOrders() {
    return _app_host_.invoke("openOrders", Array.prototype.slice.call(arguments));
  }
  static async openWidgetShowcase() {
    return _app_host_.invoke("openWidgetShowcase", Array.prototype.slice.call(arguments));
  }
  static async openDemoList() {
    return _app_host_.invoke("openDemoList", Array.prototype.slice.call(arguments));
  }
  static async toast(msg) {
    return _app_host_.invoke("toast", Array.prototype.slice.call(arguments));
  }
}

