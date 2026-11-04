import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import '../app/model/app_models.dart';
import '../app/pages/detail_pages.dart';
import '../app/pages/orders_page.dart';
import '../app/service/app_service.dart';
import '../components/hero_target_page.dart';
import '../components/widget_showcase.dart';
import '../main.dart';

/// 宿主路由能力：`@PatchEntry` 首页的所有点击入口都走这里。
///
/// 设计要点（与 [Network] / [WebView] 同一套 @HostInjected 机制）：
/// - **原生直接可用**：这些就是普通 static 方法，首页原生渲染时同步执行；
/// - **JS 热更可用**：JS 产物里本类仍存在，只有被标注方法的方法体换成
///   `_app_host_.invoke(...)`；调用点与 Dart 一比一（`AppRouter.openSpot(id)`），
///   由宿主 `registerHostMethod` 回调本类，
///   经 [JsRuntimeManager.navigatorKey] 推入真实 Flutter 页面。
///
/// 一份代码、两条通路，首页无需知道当前跑在 Dart 还是 JS 上。
class AppRouter {
  const AppRouter._();

  /// 详情数据统一走 [AppService]（请求本地 mock 接口）；宿主侧是普通 Dart 调用，
  /// JS 页面的点击经 `@HostInjected` 通道回到这里执行同一条代码路径。
  static const AppService _service = AppService();

  static NavigatorState? get _navigator =>
      JsRuntimeManager.navigatorKey?.currentState;

  static void _push(Widget page) {
    _navigator?.push(MaterialPageRoute(builder: (_) => page));
  }

  /// 宿主路由的统一失败处理：请求/跳转失败时把异常原样 toast 出去，
  /// 避免点击后既没有页面也没有任何反馈。
  static Future<void> _guard(String action, Future<void> Function() body) async {
    try {
      await body();
    } catch (e) {
      print('$action失败: $e');
      await toast('$action失败：$e');
    }
  }

  /// 打开 Hero 演示的目标页。
  ///
  /// [tag] 必须是**来源页那一个 Hero 的 tag**：汉化版与原版各用独立 tag，
  /// 因为原生 / JS 两栏同处一个路由，同 tag 会触发 Flutter 重复 Hero 断言。
  @HostInjected()
  static void openHeroTarget(String tag, String label) {
    _push(HeroTargetPage(tag: tag, label: label));
  }

  /// 打开搜索页（热搜词 + 猜你想去随接口下发）。
  @HostInjected()
  static Future<void> openSearch() => _guard('打开搜索页', () async {
        final SearchFeed feed = await _service.fetchSearch();
        _push(SearchPage(hot: feed.hot, guesses: feed.guesses));
      });

  /// 打开景点详情页（按 id 定位，找不到时回退首个）。
  @HostInjected()
  static Future<void> openSpot(String id) => _guard('打开景点详情', () async {
        final Spot spot = await _service.fetchSpot(id);
        _push(SpotDetailPage(spot: spot));
      });

  /// 唤起城市选择器（底部面板），返回选中的城市名；用户直接关闭面板时返回 null。
  ///
  /// 面板是宿主侧 UI（`showModalBottomSheet` 在 JS 侧无等价物），JS 页面只拿
  /// 返回值：`await AppRouter.openCityPicker(current)` → `_app_host_.invoke(...)`。
  @HostInjected()
  static Future<String?> openCityPicker(String current) async {
    final ctx = JsRuntimeManager.navigatorKey?.currentContext;
    if (ctx == null) return null;
    return showModalBottomSheet<String>(
      context: ctx,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => CityPickerSheet(current: current),
    );
  }

  /// 打开九宫格频道详情页（门票 / 酒店 / 机票 …）。
  @HostInjected()
  static Future<void> openChannel(String title, String emoji) async {
    _push(ChannelDetailPage(title: title, emoji: emoji));
  }

  /// 打开通知列表页（消息中心，数据走 `/app/notifications`）。
  @HostInjected()
  static Future<void> openNotifications() => _guard('打开消息中心', () async {
        final List<AppNotice> notices = await _service.fetchNotifications();
        _push(NotificationsPage(notices: notices));
      });

  /// 打开帖子详情页。
  @HostInjected()
  static Future<void> openPost(String id) => _guard('打开帖子详情', () async {
        final Post post = await _service.fetchPost(id);
        _push(PostDetailPage(post: post));
      });

  /// 打开资源专题页（专题 + 相关推荐随接口下发）。
  @HostInjected()
  static Future<void> openResource(String id) => _guard('打开资源专题', () async {
        final ResourceFeed feed = await _service.fetchResource(id);
        _push(ResourceDetailPage(resource: feed.resource, related: feed.related));
      });

  /// 打开订单详情页。
  @HostInjected()
  static Future<void> openOrder(String no) => _guard('打开订单详情', () async {
        final Order order = await _service.fetchOrder(no);
        _push(OrderDetailPage(order: order));
      });

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
  ///
  /// 订单页自身只画内容（tab 形态要贴进 `AppShell` 的 body），独立成页时必须
  /// 自带 `Scaffold`：否则没有背景色、没有标题栏与返回键，整页黑底且文字失去
  /// Material 上下文（实测就是"从我的页进来很丑"的那一页）。
  @HostInjected()
  static Future<void> openOrders() async {
    _push(
      Scaffold(
        appBar: AppBar(title: const Text('我的订单')),
        body: const OrdersPage(),
      ),
    );
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
}