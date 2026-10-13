import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';
import 'package:ui_component/ui_component.dart';

import '../app/model/app_data.dart';
import '../app/model/app_models.dart';
import '../app/pages/detail_pages.dart';
import '../app/pages/orders_page.dart';
import '../components/widget_showcase.dart';
import '../main.dart';

/// 宿主路由能力：`@UIComponent` 首页的所有点击入口都走这里。
///
/// 设计要点（与 [Network] / [WebView] 同一套 @HostInjected 机制）：
/// - **原生直接可用**：这些就是普通 static 方法，首页原生渲染时同步执行；
/// - **JS 热更可用**：标注后生成器把组件里的调用点整段替换为
///   `__jsui.host('openSpot', [id])`，由宿主 `registerHostMethod` 回调本类，
///   经 [JsRuntimeManager.navigatorKey] 推入真实 Flutter 页面。
///
/// 一份代码、两条通路，首页无需知道当前跑在 Dart 还是 JS 上。
class AppRouter {
  const AppRouter._();

  static NavigatorState? get _navigator =>
      JsRuntimeManager.navigatorKey?.currentState;

  static void _push(Widget page) {
    _navigator?.push(MaterialPageRoute(builder: (_) => page));
  }

  /// 打开搜索页。
  @HostInjected()
  static Future<void> openSearch() async {
    _push(const SearchPage());
  }

  /// 打开景点详情页（按 id 定位，找不到时回退首个）。
  @HostInjected()
  static Future<void> openSpot(String id) async {
    _push(SpotDetailPage(spot: _spotOf(id)));
  }

  /// 打开帖子详情页。
  @HostInjected()
  static Future<void> openPost(String id) async {
    _push(PostDetailPage(post: _postOf(id)));
  }

  /// 打开资源专题页。
  @HostInjected()
  static Future<void> openResource(String id) async {
    _push(ResourceDetailPage(resource: _resourceOf(id)));
  }

  /// 打开订单详情页。
  @HostInjected()
  static Future<void> openOrder(String no) async {
    _push(OrderDetailPage(order: _orderOf(no)));
  }

  /// 返回上一页。
  @HostInjected()
  static Future<void> pop() async {
    _navigator?.maybePop();
  }

  /// 打开登录页。
  @HostInjected()
  static Future<void> openLogin() async {
    _push(const LoginPage());
  }

  /// 打开订单 tab 对应的页面（「我的」页统计项/菜单入口）。
  @HostInjected()
  static Future<void> openOrders() async {
    _push(const OrdersPage());
  }

  /// 打开「组件案例」页。
  @HostInjected()
  static Future<void> openWidgetShowcase() async {
    _push(const WidgetShowcase());
  }

  /// 打开「热更 Demo 列表」页。
  @HostInjected()
  static Future<void> openDemoList() async {
    _push(const DemoListPage());
  }

  /// 轻提示（原生与 JS 组件共用；JS 侧 `AppRouter.toast('...')` 走同一通道）。
  @HostInjected()
  static Future<void> toast(String msg) async {
    final ctx = JsRuntimeManager.navigatorKey?.currentContext;
    if (ctx != null) appToast(ctx, msg);
  }

  static Spot _spotOf(String id) {
    for (final s in kSpots) {
      if (s.id == id) return s;
    }
    return kSpots.first;
  }

  static Post _postOf(String id) {
    for (final p in kPosts) {
      if (p.id == id) return p;
    }
    return kPosts.first;
  }

  static Resource _resourceOf(String id) {
    for (final r in kResources) {
      if (r.id == id) return r;
    }
    return kResources.first;
  }

  static Order _orderOf(String no) {
    for (final o in kOrders) {
      if (o.no == no) return o;
    }
    return kOrders.first;
  }
}