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
//          JS 实例跨桥序列化为 `{__handle: id, length, initialIndex}`，宿主按 id
//          取/建真实 TabController 并挂到 TabBar / TabBarView；用户点 tab 经
//          invoke 回传页码给 JS 实例，JS 侧 `index= / animateTo()` 走通用 op
//          下发驱动宿主。
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'
    show Ticker, TickerCallback, TickerProvider;

import '../../../json/flutter_from_json.dart';
import '../../js_widget_registry.dart';
import '../core/controller_bridge.dart';

// ---------------------------------------------------------------------------
// TabController 句柄桥（通用层见 capabilities/core/controller_bridge.dart；
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

/// TabController 句柄桥：onCreate 阶段拿不到构造参数（length/initialIndex
/// 随 `__handle` 下发而非 meta），真实 controller 由 Host 带参创建，onCreate
/// 只登记 index 回传句柄；这里只留 index setter / animateTo 的 op 分派。
final JsControllerBridge<TabController> _tabBridge =
    JsControllerBridge<TabController>(
  kind: 'ctrl/Tab',
  onOp: (c, op, payload) {
    if (op == 'set' && payload['name'] == 'index') {
      final v = payload['value'];
      if (v is num) c.index = v.toInt();
    } else if (op == 'call' && payload['method'] == 'animateTo') {
      final args = payload['args'] is List ? payload['args'] as List : const [];
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

/// JS TabController 句柄：`{__handle: id, length, initialIndex}`。
typedef TabControllerHandle = ({String id, int length, int initialIndex});

/// 从 props 的 controller 取值里解析 JS TabController 句柄；非句柄（缺省/null）
/// → null，即「由祖先 DefaultTabController 提供」。
TabControllerHandle? tabControllerHandleOf(Object? prop) {
  if (prop is! Map) return null;
  final id = prop['__handle'];
  if (id is! String) return null;
  final length = prop['length'];
  final initialIndex = prop['initialIndex'];
  return (
    id: id,
    length: length is num ? length.toInt() : 1,
    initialIndex: initialIndex is num ? initialIndex.toInt() : 0,
  );
}

/// TabController 桥接 Host（TabBar / TabBarView 共用）：按句柄携带的
/// length/initialIndex 取/建真实 controller（vsync 用常驻 provider），首次
/// attach 挂 index 转发（宿主 index 变化 → invoke 回传 JS 实例镜像）。
Widget _tabControllerHost(
  JsRenderContext c,
  TabControllerHandle handle,
  Widget Function(TabController controller) build,
) =>
    JsControllerHost<TabController>(
      bridge: _tabBridge,
      id: handle.id,
      create: () => TabController(
        length: handle.length,
        initialIndex: handle.initialIndex,
        vsync: _detachedTickerProvider,
      ),
      forward: (controller, handler) => c.invoke(handler, [controller.index]),
      buildChild: build,
    );

/// Tab 家族的宿主注册。
void registerTabWidgets(JsWidgetRegistry r) {
  // DefaultTabController：为子树提供 TabController（length 缺省退回子节点数）。
  r.register('DefaultTabController', (c) => DefaultTabController(
        length: c.int_('length') ?? 1,
        initialIndex: c.int_('initialIndex') ?? 0,
        child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
      ));

  // TabBar：tabs 进 children（Tab 已注册为宿主 widget）。controller 是 JS
  // TabController 句柄时走 id-bridge 包装器；否则传 null（由祖先
  // DefaultTabController 提供，官方惯用法）。
  r.register('TabBar', (c) {
    Widget build(TabController? controller) => TabBar(
          controller: controller,
          tabs: ((c.children['tabs'] as List<Widget>?) ?? const []),
          isScrollable: c.bool_('isScrollable') ?? false,
          padding: nullableEdgeInsets(c.map('padding')),
          indicatorColor: colorFromJson(c.props['indicatorColor']),
          indicatorWeight: c.num_('indicatorWeight') ?? 2.0,
          indicatorSize: tabBarIndicatorSizeFromJson(c.props['indicatorSize']),
          dividerColor: colorFromJson(c.props['dividerColor']),
          dividerHeight: c.num_('dividerHeight'),
          labelColor: colorFromJson(c.props['labelColor']),
          labelStyle: textStyleFromJson(c.map('labelStyle')),
          labelPadding: nullableEdgeInsets(c.map('labelPadding')),
          unselectedLabelColor: colorFromJson(c.props['unselectedLabelColor']),
          unselectedLabelStyle: textStyleFromJson(c.map('unselectedLabelStyle')),
          tabAlignment: tabAlignmentFromJson(c.props['tabAlignment']),
          physics: scrollPhysicsFromJson(c.props['physics']),
          onTap: c.on1<int>('onTap'),
        );
    final handle = tabControllerHandleOf(c.props['controller']);
    if (handle == null) return build(null);
    return _tabControllerHost(c, handle, build);
  });

  // Tab：child 优先，其次 icon+text，最后 text（三者至少其一，生成器已保证）。
  r.register('Tab', (c) {
    // `child:` 是子结点参数 → 进 children；props 里的 child 兜底兼容。
    final child = (c.children['child'] as Widget?);
    if (child != null) return Tab(child: child);
    final icon = (c.children['icon'] as Widget?);
    final text = c.str('text');
    if (icon != null) return Tab(icon: icon, text: text);
    return Tab(text: text);
  });

  // TabBarView：每 tab 一页；controller 同 TabBar（句柄 → 同一 id-bridge，
  // 与 TabBar 共享同一真实 TabController；否则由祖先 DefaultTabController 提供）。
  r.register('TabBarView', (c) {
    Widget build(TabController? controller) => TabBarView(
          controller: controller,
          physics: scrollPhysicsFromJson(c.props['physics']),
          viewportFraction: c.num_('viewportFraction') ?? 1.0,
          children: ((c.children['children'] as List<Widget>?) ?? const []),
        );
    final handle = tabControllerHandleOf(c.props['controller']);
    if (handle == null) return build(null);
    return _tabControllerHost(c, handle, build);
  });
}