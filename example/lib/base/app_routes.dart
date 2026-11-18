import 'package:flutter/material.dart';
import 'package:dynamic_flutter/dynamic_flutter.dart';

import '../app/model/app_models.dart';
import '../app/pages/detail_pages.dart';
import '../app/pages/orders_page.dart';
import '../app/pages/user_center_page.dart';
import '../components/hero_target_page.dart';
import '../components/widget_showcase.dart';
import '../main.dart';
import 'app_router.dart';
import 'patch_config.dart';

/// 全部命名路由的**唯一**路由表（由 `HotDemoApp` 的 `MaterialApp.onGenerateRoute` 挂载）。
///
/// 分工：
/// - 页面构造只在这里（`AppRouter` 只负责取数据 + `pushNamed(name, arguments)`）；
/// - 参数一律走 `RouteSettings.arguments`（宿主侧对象原样传递，不经 JSON）；
/// - 路由参数带 `component`（可选 `entry`）时优先渲染对应 JS 版页面，与具体
///   路由无关，新增页面共用同一套参数；
/// - 路由名常量在 `base/app_router.dart` 的 [AppRoutes]（必须与宿主路由能力同文件，
///   否则会被翻译成不存在的 JS 模块引用）。
///
/// 本文件**不参与翻译**（没有 `@PatchEntry` 类），因此可以自由引用宿主专用的
/// `base/patch_config.dart` 与页面实现。
Route<dynamic>? appOnGenerateRoute(RouteSettings settings) {
  final args = settings.arguments;
  final map = args is Map ? args : const <String, dynamic>{};

  // 通用 JS 版页面：路由参数带 component 就按补丁入口渲染，与具体路由无关，
  // 后续新增页面直接用同一套参数即可走 JS 版。
  final component = map['component'];
  if (component is String) {
    final entry = map['entry'];
    return _route(
      _jsPage(component, entry is String ? entry : null),
      settings,
    );
  }

  switch (settings.name) {
    case AppRoutes.demoList:
      return _route(const DemoListPage(), settings);

    case AppRoutes.heroTarget:
      final tag = map['tag'];
      final label = map['label'];
      if (tag is! String || label is! String) {
        return _badArgs(settings, 'tag / label');
      }
      return _route(HeroTargetPage(tag: tag, label: label), settings);

    case AppRoutes.search:
      return _route(const SearchPage(), settings);

    case AppRoutes.spot:
      final spot = map['spot'];
      if (spot is! Spot) return _badArgs(settings, 'spot');
      return _route(SpotDetailPage(spot: spot), settings);

    case AppRoutes.post:
      final post = map['post'];
      if (post is! Post) return _badArgs(settings, 'post');
      return _route(PostDetailPage(post: post), settings);

    case AppRoutes.resource:
      final resource = map['resource'];
      final related = map['related'];
      if (resource is! Resource || related is! List<Post>) {
        return _badArgs(settings, 'resource / related');
      }
      return _route(
        ResourceDetailPage(resource: resource, related: related),
        settings,
      );

    case AppRoutes.order:
      final order = map['order'];
      if (order is! Order) return _badArgs(settings, 'order');
      return _route(OrderDetailPage(order: order), settings);

    case AppRoutes.channel:
      final title = map['title'];
      final emoji = map['emoji'];
      if (title is! String || emoji is! String) {
        return _badArgs(settings, 'title / emoji');
      }
      return _route(ChannelDetailPage(title: title, emoji: emoji), settings);

    case AppRoutes.notifications:
      final notices = map['notices'];
      if (notices is! List<AppNotice>) return _badArgs(settings, 'notices');
      return _route(NotificationsPage(notices: notices), settings);

    case AppRoutes.orders:
      // 订单页自身只画内容（tab 形态贴进 AppShell）；独立成页时补 Scaffold。
      return _route(
        Scaffold(
          appBar: AppBar(
            title: const Text('我的订单'),
            backgroundColor: Colors.white,
          ),
          body: const OrdersPage(),
        ),
        settings,
      );

    case AppRoutes.widgetShowcase:
      return _route(
        Scaffold(
          appBar: AppBar(
            title: const Text('组件案例'),
            backgroundColor: Colors.white,
          ),
          body: const WidgetShowcase(),
        ),
        settings,
      );

    case AppRoutes.userCenter:
      return _route(const UserCenterPage(), settings);

    case AppRoutes.login:
      return _route(const LoginPage(), settings);
  }

  // 未知路由不静默：日志 + 可见提示页。
  debugPrint('未知路由：${settings.name}');
  return _route(_RouteErrorPage(message: '未知路由：${settings.name}'), settings);
}

MaterialPageRoute<void> _route(Widget child, RouteSettings settings) =>
    MaterialPageRoute<void>(builder: (_) => child, settings: settings);

/// 参数缺失/类型不符：这类错误只可能来自代码写错，不能静默给个空页面。
MaterialPageRoute<void> _badArgs(RouteSettings settings, String keys) {
  print(
    '路由 ${settings.name} 缺少/非法参数：$keys（actual=${settings.arguments.runtimeType}）',
  );
  return _route(
    _RouteErrorPage(message: '路由 ${settings.name} 缺少/非法参数：$keys'),
    settings,
  );
}

/// 通用 JS 版页面：component / entry 全部来自路由参数 map。
///
/// 产物按**源文件**聚合 —— 例如 SearchPage 与同级页面同住 `detail_pages.dart`，
/// 所以入口是 `app/pages/detail_pages.js`，组件名才是 `SearchPage`。
///
/// 页面自己请求数据（JS 侧 `AppService` → Network 桥），故不需要 `params`；
/// 与原生版同签名、同布局，用于验证「同一页面在原生与 JS 两侧行为一致」。
Widget _jsPage(String component, String? entry) => JsUiWidget(
  jsAsset: patchUrl(component, entry),
  showBuildTime: true,
);

/// 路由异常时的可见兜底（只用于代码写错的场景）。
class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('路由错误')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4D5462)),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
