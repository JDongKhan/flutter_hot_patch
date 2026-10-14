// ===== Tab 家族 + Drawer 家族 能力域 =====
//
// 一个能力 = 桥接表 + 通道 + 桥接组件 + 组件注册，全部内聚在本文件
// （见 js_ui_capabilities.dart 的能力文件规范）。
//
// 本能力做什么：
//   - DefaultTabController / TabBar / Tab / TabBarView：全部还原为**真实**
//     Flutter widget。controller 有两种来源：
//       1) 不传 → 由祖先 DefaultTabController 提供（官方惯用法
//          `DefaultTabController(length:n, child: Column([TabBar, Expanded(TabBarView)]))`）；
//       2) 显式传 TabController → 走本文件的 TabController 句柄桥（与
//          ScrollController 同款，通用层见 capabilities/handle_registry.dart）：
//          JS 实例跨桥序列化为 `{__handle: id, length, initialIndex}`，宿主按 id
//          取/建真实 TabController 并挂到 TabBar / TabBarView；用户点 tab 经
//          invoke 回传页码给 JS 实例，JS 侧 `index= / animateTo()` 走通用 op
//          下发驱动宿主。
//   - Drawer / DrawerHeader：还原为真实 Drawer。Scaffold.drawer 接进真实
//     Scaffold 后 AppBar 自动出现汉堡按钮，开启抽屉原生可用。
//   - 抽屉关闭：Drawer 是 Scaffold 的后代，其子树内 `Scaffold.maybeOf(context)`
//     即拿得到 ScaffoldState。抽屉**打开时** DrawerController 才构建 Drawer
//     内容（关闭态只返回拖拽热区）→ 作用域登记 closer；关闭后内容被移除 →
//     dispose 注销。故「登记表非空 ⟺ 有抽屉打开」。业务侧 @HostInjected 方法
//     转调 [closeOpenDrawer] 即可关闭当前抽屉。
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'
    show Ticker, TickerCallback, TickerProvider;

import '../../json/flutter_from_json.dart';
import '../js_widget_registry.dart';
import 'handle_registry.dart';

// ---------------------------------------------------------------------------
// TabController 句柄桥
// （JS 侧代理类见 capabilities/tab_controller_js.dart，与 ScrollController 同构）
// ---------------------------------------------------------------------------

final Map<String, TabController> _jsTabControllers = {};
final Map<String, Object?> _jsTabIndexHandles = {};
final Set<String> _jsTabAttached = {};

bool _tabKindRegistered = false;

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

/// 幂等注册 TabController 句柄 kind（由 js_ui_capabilities.ensureJsUiCapabilities
/// 聚合调用）。
void ensureTabControllerChannels() {
  if (_tabKindRegistered) return;
  _tabKindRegistered = true;
  registerHandleKind('ctrl/Tab', JsHandleKind(
    onCreate: (id, meta) {
      _jsTabIndexHandles[id] = meta is Map ? meta['fn'] : null;
    },
    onOp: (id, op, payload) {
      final c = _jsTabControllers[id];
      if (c == null) return null;
      if (op == 'set' && payload['name'] == 'index') {
        final v = payload['value'];
        if (v is num) c.index = v.toInt();
      } else if (op == 'call' && payload['method'] == 'animateTo') {
        final args = payload['args'] is List ? payload['args'] as List : const [];
        if (args.isNotEmpty && args[0] is num) c.animateTo((args[0] as num).toInt());
      }
      return null;
    },
    onRelease: (id) {
      _jsTabControllers.remove(id)?.dispose();
      _jsTabIndexHandles.remove(id);
      _jsTabAttached.remove(id);
    },
  ));
}

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

/// TabController 桥接包装器：按 id 取/建真实 TabController（用 JS 句柄下发的
/// length/initialIndex 构造，vsync 用常驻 provider），首次 attach 挂 index
/// 转发（宿主 index 变化 → invoke 回传 JS 实例）；具体 widget 由调用方闭包用
/// 绑定好的 controller 构建（TabBar / TabBarView 共用同一套）。
class _JsTabControllerHost extends StatefulWidget {
  const _JsTabControllerHost({
    required this.handle,
    required this.invoke,
    required this.buildChild,
  });

  /// JS 侧 TabController 实例的句柄 id（如 'js:ctrl/Tab#5'）+ 构造参数。
  final TabControllerHandle handle;

  /// 宿主 → JS 事件回传（js_ui_widget.dart 的 _invoke）。
  final void Function(Object? handler, [List<Object?> args]) invoke;

  final Widget Function(TabController controller) buildChild;

  @override
  State<_JsTabControllerHost> createState() => _JsTabControllerHostState();
}

class _JsTabControllerHostState extends State<_JsTabControllerHost> {
  late final TabController _controller = _jsTabControllers.putIfAbsent(
    widget.handle.id,
    () => TabController(
      length: widget.handle.length,
      initialIndex: widget.handle.initialIndex,
      vsync: _detachedTickerProvider,
    ),
  );

  @override
  void initState() {
    super.initState();
    // 同一 id 只挂一次转发（TabBar 与 TabBarView 共享同一 controller）。
    final indexFn = _jsTabIndexHandles[widget.handle.id];
    if (indexFn != null && _jsTabAttached.add(widget.handle.id)) {
      _controller.addListener(_forwardIndex);
      // 首次 attach 即回传一次初始 index：JS 镜像（index/length）不依赖
      // 「先切换才更新」，构造后立即准确。
      WidgetsBinding.instance.addPostFrameCallback((_) => _forwardIndex());
    }
  }

  void _forwardIndex() {
    final handler = _jsTabIndexHandles[widget.handle.id];
    if (handler == null) return;
    widget.invoke(handler, [_controller.index]);
  }

  @override
  void dispose() {
    // 真实 controller 生命周期由 JS 侧句柄释放驱动（jsHandle release →
    // ctrl/Tab onRelease）；页面卸载时 JS 组件 dispose 同样触发，这里不重复。
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.buildChild(_controller);
}

// ---------------------------------------------------------------------------
// 抽屉关闭作用域
// ---------------------------------------------------------------------------

/// 当前已打开的抽屉关闭回调（抽屉内容不构建即被移出，故集合非空 ⟺ 有抽屉
/// 打开）。
final Set<VoidCallback> _openDrawerClosers = {};

/// 关闭当前打开的抽屉（drawer / endDrawer 均可）；无打开抽屉时 no-op。
/// 供业务侧 @HostInjected 方法转调（JS 侧 `__jsui.host('closeDrawer')`）。
void closeOpenDrawer() {
  for (final closer in _openDrawerClosers.toList()) {
    closer();
  }
}

/// Drawer 作用域：登记「关闭当前抽屉」的回调。
///
/// 只在抽屉内容被构建（= 抽屉打开）期间存在，卸载即注销。
class _JsDrawerScope extends StatefulWidget {
  const _JsDrawerScope({required this.child});

  final Widget child;

  @override
  State<_JsDrawerScope> createState() => _JsDrawerScopeState();
}

class _JsDrawerScopeState extends State<_JsDrawerScope> {
  ScaffoldState? _scaffold;

  /// 稳定的闭包实例（同一实例 add/remove，Set 身份可靠）。
  late final VoidCallback _closer = _close;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Drawer 由 Scaffold 的 DrawerController 构建 → 沿祖先链取 ScaffoldState。
    _scaffold = Scaffold.maybeOf(context);
    _openDrawerClosers.add(_closer);
  }

  void _close() {
    final s = _scaffold;
    if (s == null || !s.mounted) return;
    if (s.isDrawerOpen) {
      s.closeDrawer();
    } else if (s.isEndDrawerOpen) {
      s.closeEndDrawer();
    }
  }

  @override
  void dispose() {
    _openDrawerClosers.remove(_closer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Tab 家族 + Drawer 家族的宿主注册。
void registerTabDrawerWidgets(JsWidgetRegistry r) {
  // DefaultTabController：为子树提供 TabController（length 缺省退回子节点数）。
  r.register('DefaultTabController', (c) => DefaultTabController(
        length: c.int_('length') ?? c.children.length,
        initialIndex: c.int_('initialIndex') ?? 0,
        child: c.childOrEmpty,
      ));

  // TabBar：tabs 进 children（Tab 已注册为宿主 widget）。controller 是 JS
  // TabController 句柄时走 id-bridge 包装器；否则传 null（由祖先
  // DefaultTabController 提供，官方惯用法）。
  r.register('TabBar', (c) {
    Widget build(TabController? controller) => TabBar(
          controller: controller,
          tabs: c.children,
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
          onTap: c.on1<int>('event'),
        );
    final handle = tabControllerHandleOf(c.props['controller']);
    if (handle == null) return build(null);
    return _JsTabControllerHost(
      handle: handle,
      invoke: c.invoke,
      buildChild: build,
    );
  });

  // Tab：child 优先，其次 icon+text，最后 text（三者至少其一，生成器已保证）。
  r.register('Tab', (c) {
    final child = c.propChild('child');
    if (child != null) return Tab(child: child);
    final icon = c.propChild('icon');
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
          children: c.children,
        );
    final handle = tabControllerHandleOf(c.props['controller']);
    if (handle == null) return build(null);
    return _JsTabControllerHost(
      handle: handle,
      invoke: c.invoke,
      buildChild: build,
    );
  });

  // Drawer：真实 Drawer + 关闭作用域包装。
  r.register('Drawer', (c) => _JsDrawerScope(
        child: Drawer(
          backgroundColor: colorFromJson(c.props['backgroundColor']),
          elevation: c.num_('elevation'),
          shape: shapeFromJson(c.props['shape']),
          width: c.num_('width'),
          child: c.child(),
        ),
      ));

  // DrawerHeader：decoration / padding / margin + child（缺省 padding/margin
  // 与 Flutter 默认一致）。
  r.register('DrawerHeader', (c) => DrawerHeader(
        decoration: boxDecorationFromJson(c.map('decoration')),
        padding: nullableEdgeInsets(c.map('padding')) ??
            const EdgeInsets.fromLTRB(16, 16, 16, 8),
        margin: nullableEdgeInsets(c.map('margin')) ??
            const EdgeInsets.only(bottom: 8),
        child: c.child() ?? const SizedBox.shrink(),
      ));
}