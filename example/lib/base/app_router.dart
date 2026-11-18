import 'package:flutter/material.dart';
import 'package:dynamic_flutter/dynamic_flutter.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

import '../app/model/app_models.dart';
import '../app/pages/city_picker_sheet.dart';
import '../app/service/app_service.dart';

/// 全部页面路由名（`MaterialApp.onGenerateRoute` 的路由表见
/// `base/app_routes.dart`，与本表一一对应）。
///
/// 与 [AppRouter] 同文件：路由名只在 `@HostInjected` 方法体里使用，而方法体
/// 不参与翻译（整体换成 `_app_host_.invoke(...)`），因此这些常量不需要独立的
/// JS 产物；放在一起改一处即可，避免再开一个「没有可翻译类」的宿主文件。
class AppRoutes {
  const AppRoutes._();

  static const String demoList = '/demo-list';
  static const String heroTarget = '/hero-target';
  static const String search = '/search';
  static const String spot = '/spot';
  static const String post = '/post';
  static const String resource = '/resource';
  static const String order = '/order';
  static const String channel = '/channel';
  static const String notifications = '/notifications';
  static const String orders = '/orders';
  static const String widgetShowcase = '/widget-showcase';
  static const String userCenter = '/user-center';
  static const String login = '/login';
}

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

  /// 通用命名路由跳转：路由名与参数完全由调用方决定。
  /// 原生侧直接执行；JS 侧经 `@HostInjected` 通道回到宿主执行同一份逻辑。
  /// 例如调用方按 `kInJsRuntime` 决定是否在参数里带上 `component` / `entry`，
  /// 路由表据此渲染 JS 版页面或原生页面。
  @HostInjected()
  static void pushNamed(String name, [Object? routeArgs]) {
    assert(_navigator != null, 'Navigator 未初始化');
    _navigator?.pushNamed(name, arguments: routeArgs);
  }

  /// 宿主路由的统一失败处理：请求/跳转失败时把异常原样 toast 出去，
  /// 避免点击后既没有页面也没有任何反馈。
  static Future<void> _guard(
    String action,
    Future<void> Function() body,
  ) async {
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
    pushNamed(AppRoutes.heroTarget, <String, dynamic>{
      'tag': tag,
      'label': label,
    });
  }

  /// 打开景点详情页（按 id 定位，找不到时回退首个）。
  @HostInjected()
  static Future<void> openSpot(String id) => _guard('打开景点详情', () async {
    final Spot spot = await _service.fetchSpot(id);
    pushNamed(AppRoutes.spot, <String, dynamic>{'spot': spot});
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
    pushNamed(AppRoutes.channel, <String, dynamic>{
      'title': title,
      'emoji': emoji,
    });
  }

  /// 打开通知列表页（消息中心，数据走 `/app/notifications`）。
  @HostInjected()
  static Future<void> openNotifications() => _guard('打开消息中心', () async {
    final List<AppNotice> notices = await _service.fetchNotifications();
    pushNamed(AppRoutes.notifications, <String, dynamic>{'notices': notices});
  });

  /// 打开帖子详情页。
  @HostInjected()
  static Future<void> openPost(String id) => _guard('打开帖子详情', () async {
    final Post post = await _service.fetchPost(id);
    pushNamed(AppRoutes.post, <String, dynamic>{'post': post});
  });

  /// 打开资源专题页（专题 + 相关推荐随接口下发）。
  @HostInjected()
  static Future<void> openResource(String id) => _guard('打开资源专题', () async {
    final ResourceFeed feed = await _service.fetchResource(id);
    pushNamed(AppRoutes.resource, <String, dynamic>{
      'resource': feed.resource,
      'related': feed.related,
    });
  });

  /// 打开订单详情页。
  @HostInjected()
  static Future<void> openOrder(String no) => _guard('打开订单详情', () async {
    final Order order = await _service.fetchOrder(no);
    pushNamed(AppRoutes.order, <String, dynamic>{'order': order});
  });

  /// 返回上一页。
  @HostInjected()
  static Future<void> pop() async {
    assert(_navigator != null, 'Navigator 未初始化');
    _navigator?.maybePop();
  }

  /// 打开登录页。
  @HostInjected()
  static Future<void> openLogin() async {
    pushNamed(AppRoutes.login);
  }

  /// 打开用户中心（「我的」页点击个人信息进入）。
  ///
  /// 页面自带 `Scaffold` 与返回入口（头部渐变块里 `AppRouter.pop()`），
  /// 这里只负责推入，数据请求由页面自己的 `UserCenterVm` 发起。
  @HostInjected()
  static Future<void> openUserCenter() async {
    pushNamed(AppRoutes.userCenter);
  }

  /// 打开订单 tab 对应的页面（「我的」页统计项/菜单入口）。
  ///
  /// 订单页自身只画内容（tab 形态要贴进 `AppShell` 的 body），独立成页时必须
  /// 自带 `Scaffold`：否则没有背景色、没有标题栏与返回键，整页黑底且文字失去
  /// Material 上下文（实测就是"从我的页进来很丑"的那一页）。
  @HostInjected()
  static Future<void> openOrders() async {
    pushNamed(AppRoutes.orders);
  }

  /// 打开「组件案例」页。
  @HostInjected()
  static Future<void> openWidgetShowcase() async {
    pushNamed(AppRoutes.widgetShowcase);
  }

  /// 打开「热更 Demo 列表」页。
  @HostInjected()
  static Future<void> openDemoList() async {
    pushNamed(AppRoutes.demoList);
  }

  /// 轻提示（原生与 JS 组件共用；JS 侧 `AppRouter.toast('...')` 走同一通道）。
  @HostInjected()
  static Future<void> toast(String msg) async {
    final ctx = JsRuntimeManager.navigatorKey?.currentContext;
    if (ctx != null) appToast(ctx, msg);
  }
}

/// 统一轻提示（宿主实现）。
///
/// 定义在这里而不是页面文件里，是为了让路由能力的产物 `base/app_router.js`
/// **不依赖页面产物**：页面本来就要 import `AppRouter`，若本类反过来 import
/// `detail_pages.js` 就会形成模块环 —— 例子的模块加载是「先依赖后自身」，
/// 环上的两个模块会各自等对方的 inflight completer，页面永远拿不到首帧
/// （症状：JS 页面一直转圈、日志停在 `remote bundle loaded`）。
void appToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(40, 0, 40, 110),
      ),
    );
}
