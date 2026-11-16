// ===== Tab 家族 能力域 =====
//
// 一个能力 = 桥接表 + 通道 + 桥接组件 + 组件注册，全部内聚在本文件
// （见 js_ui_capabilities.dart 的能力文件规范）。Drawer 家族是**另一个能力**，
// 见 capabilities/drawer/。
//
// 本能力做什么：
//   - DefaultTabController / TabBar / Tab / TabBarView：全部还原为**真实**
//     Flutter widget。controller 有两种来源：
//       1) 不传 → 由祖先 DefaultTabController 提供（官方惯用法
//          `DefaultTabController(length:n, child: Column([TabBar, Expanded(TabBarView)]))`）；
//       2) 显式传 TabController → 走本文件的 TabController 句柄桥（与
//          ScrollController 同款，通用层见 capabilities/core/handle_registry.dart）：
//          JS 实例跨桥序列化为 `{__handle: id}`，宿主按 id 取 onCreate 阶段建好
//          的真实 TabController 并挂到 TabBar / TabBarView；用户点 tab 经
//          invoke 回传页码给 JS 实例，JS 侧 `index= / animateTo()` 走通用 op
//          下发驱动宿主。
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'
    show Ticker, TickerCallback, TickerProvider;

import '../../js_widget_registry.dart';
import '../base_widget/text_from_json.dart';
import '../core/object_bridge.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';
import '../core/from_json/widget_enum_from_json.dart';
import 'tab_from_json.dart';

// ---------------------------------------------------------------------------
// TabController 句柄桥（通用层见 capabilities/core/object_bridge.dart；
// JS 侧代理类见 capabilities/tab/tab_controller_js.dart，与 ScrollController 同构）
// ---------------------------------------------------------------------------

/// 脱离 State 生命周期的 TickerProvider：真实 TabController 的生命周期由 JS 侧
/// dispose 通道管理（不随某次 widget 卸载而失效），故不能用某个 State 的
/// TickerProviderStateMixin 当 vsync——承载它的 State 一旦卸载 ticker 即失效。
/// 裸 Ticker 直接挂 SchedulerBinding（与 flutter_test 的 TestVSync 同理），
/// 代价是不受 TickerMode 静音——对 TabController 的索引动画无感。
class _DetachedTickerProvider implements TickerProvider {
  const _DetachedTickerProvider();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

const TickerProvider _detachedTickerProvider = _DetachedTickerProvider();

/// TabController 句柄桥：真实 controller 在 **onCreate 阶段**创建（length /
/// initialIndex 由 JS 侧随 meta 下发，与 AnimationController 同一形态），因此
/// JS 构造后立即 `index =` / `animateTo()` 也能落到真实实例；渲染 TabBar /
/// TabBarView 时按 id 取同一个实例（见 [_tabControllerHost] 的 controllerOf）。
final JsObjectBridge<TabController> _tabBridge =
    JsObjectBridge<TabController>(
      kind: 'ctrl/Tab',
      create: (id, meta) {
        final m = meta is Map ? meta : const {};
        final rawLength = m['length'];
        final rawInitial = m['initialIndex'];
        // length 缺省 / 非正时兜底 1：TabController 的 `initialIndex < length`
        // 断言在 length=0 时会直接失败，宁可退化成单页也不要让页面 boot 失败。
        final length = (rawLength is num && rawLength.toInt() > 0)
            ? rawLength.toInt()
            : 1;
        final initialIndex =
            (rawInitial is num && rawInitial.toInt() >= 0 && rawInitial.toInt() < length)
                ? rawInitial.toInt()
                : 0;
        return TabController(
          length: length,
          initialIndex: initialIndex,
          vsync: _detachedTickerProvider,
        );
      },
      onOp: (c, op, payload) {
        if (op == 'set' && payload['name'] == 'index') {
          final v = payload['value'];
          if (v is num) c.index = v.toInt();
        } else if (op == 'call' && payload['method'] == 'animateTo') {
          final args = payload['args'] is List
              ? payload['args'] as List
              : const [];
          if (args.isNotEmpty && args[0] is num) {
            c.animateTo((args[0] as num).toInt());
          }
        }
        return null;
      },
    );

/// 幂等注册 TabController 句柄 kind（由 js_ui_capabilities.ensureJsUiCapabilities
/// 聚合调用）。
void ensureTabControllerChannels() => _tabBridge.ensure();

/// TabController 桥接 Host（TabBar / TabBarView 共用）：按句柄 id 取**已由
/// onCreate 建好**的真实 controller（不再带参兜底创建），首次 attach 挂 index
/// 转发（宿主 index 变化 → invoke 回传 JS 实例镜像）。
Widget _tabControllerHost(
  JsRenderContext c,
  String id,
  Widget Function(TabController controller) build, {
  Key? key,
}) => JsControllerHost<TabController>(
  key: key,
  bridge: _tabBridge,
  id: id,
  forward: (controller, handler) => c.invoke(handler, [controller.index]),
  buildChild: build,
);

/// Tab 家族的宿主注册。
void registerTabWidgets(JsWidgetRegistry r) {
  // DefaultTabController：为子树提供 TabController（length 缺省退回子节点数）。
  r.register(
    'DefaultTabController',
    (c) => DefaultTabController(
      key: c.key,
      length: c.int_('length') ?? 1,
      initialIndex: c.int_('initialIndex') ?? 0,
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  // TabBar：tabs 进 children（Tab 已注册为宿主 widget）。controller 是 JS
  // TabController 句柄时走 id-bridge 包装器；否则传 null（由祖先
  // DefaultTabController 提供，官方惯用法）。`.secondary` 是命名构造（次要
  // 指示器样式），按 factory 还原。
  r.register('TabBar', (c) {
    final tabs = (c.children['tabs'] as List<Widget>?) ?? const <Widget>[];
    final isScrollable = c.bool_('isScrollable') ?? false;
    final padding = c.edgeInsets('padding');
    final indicatorColor = c.color('indicatorColor');
    final indicatorWeight = c.double_('indicatorWeight') ?? 2.0;
    final indicatorSize = c.tabBarIndicatorSize('indicatorSize');
    final dividerColor = c.color('dividerColor');
    final dividerHeight = c.double_('dividerHeight');
    final labelColor = c.color('labelColor');
    final labelStyle = c.textStyle('labelStyle');
    final labelPadding = c.edgeInsets('labelPadding');
    final unselectedLabelColor = c.color('unselectedLabelColor');
    final unselectedLabelStyle = c.textStyle('unselectedLabelStyle');
    final tabAlignment = c.tabAlignment('tabAlignment');
    final physics = c.scrollPhysics('physics');
    final onTap = c.on1<int>('onTap');

    Widget build(TabController? controller, {Key? key}) {
      if (c.str('factory') == 'secondary') {
        return TabBar.secondary(
          key: key,
          controller: controller,
          tabs: tabs,
          isScrollable: isScrollable,
          padding: padding,
          indicatorColor: indicatorColor,
          indicatorWeight: indicatorWeight,
          indicatorSize: indicatorSize,
          dividerColor: dividerColor,
          dividerHeight: dividerHeight,
          labelColor: labelColor,
          labelStyle: labelStyle,
          labelPadding: labelPadding,
          unselectedLabelColor: unselectedLabelColor,
          unselectedLabelStyle: unselectedLabelStyle,
          tabAlignment: tabAlignment,
          physics: physics,
          onTap: onTap,
        );
      }
      return TabBar(
        key: key,
        controller: controller,
        tabs: tabs,
        isScrollable: isScrollable,
        padding: padding,
        indicatorColor: indicatorColor,
        indicatorWeight: indicatorWeight,
        indicatorSize: indicatorSize,
        dividerColor: dividerColor,
        dividerHeight: dividerHeight,
        labelColor: labelColor,
        labelStyle: labelStyle,
        labelPadding: labelPadding,
        unselectedLabelColor: unselectedLabelColor,
        unselectedLabelStyle: unselectedLabelStyle,
        tabAlignment: tabAlignment,
        physics: physics,
        onTap: onTap,
      );
    }

    final id = JsObjectBridge.idOf(c.props['controller']);
    if (id == null) return build(null, key: c.key);
    return _tabControllerHost(c, id, build, key: c.key);
  });

  // Tab：child 优先，其次 icon+text，最后 text（三者至少其一，生成器已保证）。
  r.register('Tab', (c) {
    // `child:` 是子结点参数 → 进 children；props 里的 child 兜底兼容。
    final child = (c.children['child'] as Widget?);
    if (child != null) return Tab(key: c.key, child: child);
    final icon = (c.children['icon'] as Widget?);
    final text = c.str('text');
    if (icon != null) return Tab(key: c.key, icon: icon, text: text);
    return Tab(key: c.key, text: text);
  });

  // TabBarView：每 tab 一页；controller 同 TabBar（句柄 → 同一 id-bridge，
  // 与 TabBar 共享同一真实 TabController；否则由祖先 DefaultTabController 提供）。
  r.register('TabBarView', (c) {
    Widget build(TabController? controller, {Key? key}) => TabBarView(
      key: key,
      controller: controller,
      physics: c.scrollPhysics('physics'),
      viewportFraction: c.double_('viewportFraction') ?? 1.0,
      children: ((c.children['children'] as List<Widget>?) ?? const []),
    );
    final id = JsObjectBridge.idOf(c.props['controller']);
    if (id == null) return build(null, key: c.key);
    return _tabControllerHost(c, id, build, key: c.key);
  });
}
