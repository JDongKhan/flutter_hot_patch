// ===== 能力：ScrollController id-bridge + 滚动视图/sliver 组件注册 =====
//
// 一个能力 = 桥接表 + 通道 + 桥接组件 + 组件注册，全部内聚在本文件。
// 未来新增滚动域能力（如 ScrollbarController、PageController）时新建
// capabilities/xxx_bridge.dart，不碰核心文件（js_widget_registry /
// js_ui_widget / runtime_source 的骨架部分）。
//
// 本能力做什么：
//   - JS 侧 `new ScrollController()` 经 scrollControllerRegister 通道登记
//     metrics 转发句柄；宿主渲染 SingleChildScrollView / ListView /
//     CustomScrollView / GridView（controller: {__jsuiScrollController: id}）
//     时按 id 取/建真实 controller 并挂转发（滚动 → invoke 句柄 → JS 实例
//     更新镜像 → 触发其 listeners）。
//   - jumpTo/animateTo/dispose 走实例级通道。
//   - sliver 家族（SliverList/SliverAppBar/SliverPadding/...）与四个滚动视图
//     的注册一并收敛于此（滚动能力域）。
import 'package:flutter/material.dart';

import '../../json/flutter_from_json.dart';
import '../../services/js_runtime_manager.dart';
import '../js_widget_registry.dart';

final Map<String, ScrollController> _jsScrollControllers = {};
final Map<String, Object?> _jsScrollMetricsHandles = {};
final Set<String> _jsScrollAttached = {};

bool _scrollControllerChannelsRegistered = false;

/// 幂等注册 ScrollController 桥接通道（由 js_ui_capabilities.ensureJsUiCapabilities
/// 聚合调用；registerHostMethod 全局表 + 断言防重复，故用标志位兜底）。
void ensureScrollControllerChannels() {
  if (_scrollControllerChannelsRegistered) return;
  _scrollControllerChannelsRegistered = true;
  JsRuntimeManager.registerHostMethod('scrollControllerRegister',
      (Object? id, Object? metricsFn) {
    if (id is String) _jsScrollMetricsHandles[id] = metricsFn;
  });
  JsRuntimeManager.registerHostMethod('scrollControllerJumpTo',
      (Object? id, Object? offset) {
    final c = id is String ? _jsScrollControllers[id] : null;
    if (c != null) c.jumpTo(offset is num ? offset.toDouble() : 0);
  });
  JsRuntimeManager.registerHostMethod('scrollControllerAnimateTo',
      (Object? id, Object? offset, Object? ms, Object? curve) {
    final c = id is String ? _jsScrollControllers[id] : null;
    if (c == null) return;
    final name = curve?.toString();
    final curves = <String, Curve>{
      'linear': Curves.linear,
      'easeOut': Curves.easeOut,
      'easeIn': Curves.easeIn,
      'easeInOut': Curves.easeInOut,
    };
    c.animateTo(
      offset is num ? offset.toDouble() : 0,
      duration: Duration(milliseconds: (ms is num ? ms : 300).toInt()),
      curve: curves[name] ?? Curves.easeOut,
    );
  });
  JsRuntimeManager.registerHostMethod('scrollControllerDispose', (Object? id) {
    if (id is! String) return;
    _jsScrollControllers.remove(id)?.dispose();
    _jsScrollMetricsHandles.remove(id);
    _jsScrollAttached.remove(id);
  });
}

/// 从 props 的 controller 取值里解析 JS ScrollController id。
/// JS 侧实例跨桥经 toJSON 序列化为 `{__jsuiScrollController: 'sc#N'}`。
String? scrollControllerIdOf(Object? prop) {
  if (prop is Map) {
    final id = prop['__jsuiScrollController'];
    if (id is String) return id;
  }
  return null;
}

/// ScrollController 桥接的通用包装器：任何 ScrollView 子类
/// （SingleChildScrollView / ListView / CustomScrollView / GridView）把各自的
/// 构建逻辑放进 [buildScrollView] 闭包即可复用同一套桥接——按 controllerId
/// 取/建真实 controller、滚动经 invoke 回传 metrics 镜像到 JS 实例
/// （__onMetrics 更新镜像 → 触发其 listeners——匿名 addListener 闭包由 JS 侧
/// 直接持有，天然支持）、首次 attach 回传初始 metrics、jumpTo/animateTo/
/// dispose 走实例级 host 通道。不再需要为每个 scrollview 重复实现。
class _JsScrollControllerView extends StatefulWidget {
  const _JsScrollControllerView({
    required this.controllerId,
    required this.invoke,
    required this.buildScrollView,
  });

  /// JS 侧 ScrollController 实例的 id（nextId('sc')，如 'sc#5'）。
  final String controllerId;

  /// 宿主 → JS 事件回传（js_ui_widget.dart 的 _invoke）。
  final void Function(Object? handler, [List<Object?> args]) invoke;

  /// 用（按 id 绑定好的）真实 controller 构建具体滚动组件
  /// （SingleChildScrollView / ListView / CustomScrollView 等）；
  /// 其它 props（scrollDirection/physics/children…）由调用方闭包捕获。
  final Widget Function(ScrollController controller) buildScrollView;

  @override
  State<_JsScrollControllerView> createState() => _JsScrollControllerViewState();
}

class _JsScrollControllerViewState extends State<_JsScrollControllerView> {
  late final ScrollController _controller = _jsScrollControllers.putIfAbsent(
    widget.controllerId,
    () => ScrollController(),
  );

  @override
  void initState() {
    super.initState();
    // 同一 id 只挂一次转发（多视图共享同一 controller 时不重复回传）。
    final metricsFn = _jsScrollMetricsHandles[widget.controllerId];
    if (metricsFn != null && _jsScrollAttached.add(widget.controllerId)) {
      _controller.addListener(_forwardMetrics);
      // 首次 attach 即回传一次初始 metrics：JS 镜像（offset/position/
      // maxScrollExtent）不依赖「先滚动才更新」，构造后立即准确——否则
      // 用户不滚动直接点「跳到底」会读到镜像 maxScrollExtent=0，
      // jumpTo(0) 完全无效。
      WidgetsBinding.instance.addPostFrameCallback((_) => _forwardMetrics());
    }
  }

  void _forwardMetrics() {
    if (!_controller.hasClients) return;
    final handler = _jsScrollMetricsHandles[widget.controllerId];
    if (handler == null) return;
    widget.invoke(handler, [{
      'pixels': _controller.offset,
      'maxScrollExtent': _controller.position.maxScrollExtent,
      'viewportDimension': _controller.position.viewportDimension,
      'extentAfter': _controller.position.extentAfter,
    }]);
  }

  @override
  void dispose() {
    // 真实 controller 生命周期由 JS 侧 dispose()（scrollControllerDispose
    // 通道）管理；页面卸载时 JS 组件 dispose 同样触发，这里不重复释放。
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.buildScrollView(_controller);
  }
}

/// 从 props 还原 SliverGridDelegate：含 `maxCrossAxisExtent` →
/// SliverGridDelegateWithMaxCrossAxisExtent，否则
/// SliverGridDelegateWithFixedCrossAxisCount（crossAxisCount 缺省 1 兜底；
/// 间距 0/比例 1.0 即 Flutter 默认）。SliverGrid 与 GridView 共用。
SliverGridDelegate _gridDelegateFromJson(JsBuildContext c) {
  final maxExtent = c.num_('maxCrossAxisExtent');
  if (maxExtent != null) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxExtent,
      mainAxisSpacing: c.num_('mainAxisSpacing') ?? 0,
      crossAxisSpacing: c.num_('crossAxisSpacing') ?? 0,
      childAspectRatio: c.num_('childAspectRatio') ?? 1,
      mainAxisExtent: c.num_('mainAxisExtent'),
    );
  }
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: c.int_('crossAxisCount') ?? 1,
    mainAxisSpacing: c.num_('mainAxisSpacing') ?? 0,
    crossAxisSpacing: c.num_('crossAxisSpacing') ?? 0,
    childAspectRatio: c.num_('childAspectRatio') ?? 1,
    mainAxisExtent: c.num_('mainAxisExtent'),
  );
}

/// sliver delegate 还原（**delegate 形态**：`SliverChildBuilderDelegate` 源写法）：
/// 有 `childCount` → `SliverChildBuilderDelegate`（代理类已按 childCount 展开
/// children）；否则 → `SliverChildListDelegate`。四个 sliver 组件共用。
SliverChildDelegate _sliverDelegate(JsBuildContext c) {
  final count = c.int_('childCount');
  if (c.str('builder') == null || count == null) {
    return SliverChildListDelegate(c.children);
  }
  final children = c.children;
  return SliverChildBuilderDelegate(
    (_, i) => _childAt(children, i),
    childCount: count,
  );
}

/// builder 形态的计数：命名构造（`.builder`/`.separated`）用 `itemCount`，
/// delegate 形态用 `childCount`；都缺省时退回已展开的子节点数。
int _builderCount(JsBuildContext c, int fallback) =>
    c.int_('itemCount') ?? c.int_('childCount') ?? fallback;

/// 第 [i] 个子节点（越界给占位，避免宿主在 JS 补丁未到齐时越界崩溃）。
Widget _childAt(List<Widget> children, int i) =>
    i < children.length ? children[i] : const SizedBox.shrink();

/// `.separated` 形态：代理类已按 `[item, sep, item, sep, ...]` 交替展开，
/// 宿主按奇偶拆回 items / separators 两组，分别喂给原生 `.separated` 的两个
/// builder（满足 Flutter「itemCount 为 item 数」的语义）。
({List<Widget> items, List<Widget> separators}) _splitSeparated(
    List<Widget> children) {
  final items = <Widget>[];
  final separators = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    (i.isEven ? items : separators).add(children[i]);
  }
  return (items: items, separators: separators);
}

/// 滚动能力域组件注册（滚动视图 + sliver 家族）。
void registerScrollWidgets(JsWidgetRegistry r) {
  r.register('ListView', (c) {
    // controller 是 JS ScrollController 句柄时走通用桥接包装器（与
    // SingleChildScrollView 同一套 controller 绑定/metrics 回传）。
    // 三种形态：普通 children / `.builder`（props 带 builder+itemCount）/
    // `.separated`（另带 separatorBuilder）——builder 形态一律还原 Flutter
    // 原生命名构造，不用 `ListView(children: [...])` 顶替。
    final children = c.children;
    final builder = c.str('builder');
    final separator = c.str('separatorBuilder');

    Widget build(ScrollController? controller) {
      final shrinkWrap = c.bool_('shrinkWrap') ?? false;
      final scrollDirection =
          axisFromJson(c.props['scrollDirection']) ?? Axis.vertical;
      final padding = nullableEdgeInsets(c.map('padding'));
      final physics = scrollPhysicsFromJson(c.props['physics']);
      final itemExtent = c.num_('itemExtent');
      if (builder == null) {
        return ListView(
          controller: controller,
          // shrinkWrap 缺省保持 Flutter 默认（false）——与原生渲染一致。
          shrinkWrap: shrinkWrap,
          scrollDirection: scrollDirection,
          padding: padding,
          physics: physics,
          itemExtent: itemExtent,
          children: children,
        );
      }
      if (separator != null) {
        // `.separated` 形态：还原 Flutter 原生 `ListView.separated`（代理类已
        // 展开 [item, sep, ...]，按奇偶拆回两组；itemCount 是 item 数）。
        final split = _splitSeparated(children);
        return ListView.separated(
          controller: controller,
          shrinkWrap: shrinkWrap,
          scrollDirection: scrollDirection,
          padding: padding,
          physics: physics,
          itemCount: _builderCount(c, split.items.length),
          itemBuilder: (_, i) => _childAt(split.items, i),
          separatorBuilder: (_, i) => _childAt(split.separators, i),
        );
      }
      // `.builder` 形态：还原 Flutter 原生 `ListView.builder`。
      return ListView.builder(
        controller: controller,
        shrinkWrap: shrinkWrap,
        scrollDirection: scrollDirection,
        padding: padding,
        physics: physics,
        itemExtent: itemExtent,
        itemCount: _builderCount(c, children.length),
        itemBuilder: (_, i) => _childAt(children, i),
      );
    }

    final scId = scrollControllerIdOf(c.props['controller']);
    if (scId != null) {
      return _JsScrollControllerView(
        controllerId: scId,
        invoke: c.invoke,
        buildScrollView: build,
      );
    }
    return build(null);
  });

  // GridView：普通构造 / .builder（懒加载）/ .count / .extent。gridDelegate 按
  // props 还原（crossAxisCount / maxCrossAxisExtent 双形态）；controller 与
  // ListView 同款走 _JsScrollControllerView 桥接。
  //
  // `.builder` 形态（props 带 `builder` 方法名）还原 Flutter 原生
  // `GridView.builder`，不用 `GridView(children: [...])` 顶替。
  r.register('GridView', (c) {
    final gridDelegate = _gridDelegateFromJson(c);
    final scrollDirection =
        axisFromJson(c.props['scrollDirection']) ?? Axis.vertical;
    final padding = nullableEdgeInsets(c.map('padding'));
    final shrinkWrap = c.bool_('shrinkWrap') ?? false;
    final physics = scrollPhysicsFromJson(c.props['physics']);
    final children = c.children;
    final isBuilder = c.str('builder') != null;
    final itemCount = _builderCount(c, children.length);

    Widget build(ScrollController? controller) => isBuilder
        ? GridView.builder(
            controller: controller,
            gridDelegate: gridDelegate,
            scrollDirection: scrollDirection,
            padding: padding,
            shrinkWrap: shrinkWrap,
            physics: physics,
            itemCount: itemCount,
            itemBuilder: (_, i) => _childAt(children, i),
          )
        : GridView(
            controller: controller,
            gridDelegate: gridDelegate,
            scrollDirection: scrollDirection,
            padding: padding,
            shrinkWrap: shrinkWrap,
            physics: physics,
            children: children,
          );

    final scId = scrollControllerIdOf(c.props['controller']);
    if (scId != null) {
      return _JsScrollControllerView(
        controllerId: scId,
        invoke: c.invoke,
        buildScrollView: build,
      );
    }
    return build(null);
  });

  // CustomScrollView：slivers 是 children（宿主侧 SliverList/SliverAppBar 等
  // 已注册为 widget，直接进 slivers 列表）；controller 与 ListView 同款
  // 分流通用 _JsScrollControllerView 包装器。
  r.register('CustomScrollView', (c) {
    final scId = scrollControllerIdOf(c.props['controller']);
    if (scId != null) {
      final scrollDirection =
          axisFromJson(c.props['scrollDirection']) ?? Axis.vertical;
      final physics = scrollPhysicsFromJson(c.props['physics']);
      final reverse = c.bool_('reverse') ?? false;
      final shrinkWrap = c.bool_('shrinkWrap') ?? false;
      final slivers = c.children;
      return _JsScrollControllerView(
        controllerId: scId,
        invoke: c.invoke,
        buildScrollView: (controller) => CustomScrollView(
          controller: controller,
          scrollDirection: scrollDirection,
          physics: physics,
          reverse: reverse,
          shrinkWrap: shrinkWrap,
          slivers: slivers,
        ),
      );
    }
    return CustomScrollView(
      scrollDirection: axisFromJson(c.props['scrollDirection']) ?? Axis.vertical,
      physics: scrollPhysicsFromJson(c.props['physics']),
      reverse: c.bool_('reverse') ?? false,
      shrinkWrap: c.bool_('shrinkWrap') ?? false,
      slivers: c.children,
    );
  });

  // SliverList：`.builder`/`.separated` 命名构造还原 Flutter 同名原生构造；
  // `SliverChildBuilderDelegate` 形态（只有 childCount）还原
  // `SliverChildBuilderDelegate`；ListDelegate 形态还原 `SliverChildListDelegate`。
  r.register('SliverList', (c) {
    final builder = c.str('builder');
    if (builder == null) return SliverList(delegate: _sliverDelegate(c));
    final children = c.children;
    final separator = c.str('separatorBuilder');
    if (separator != null) {
      final split = _splitSeparated(children);
      return SliverList.separated(
        itemCount: _builderCount(c, split.items.length),
        itemBuilder: (_, i) => _childAt(split.items, i),
        separatorBuilder: (_, i) => _childAt(split.separators, i),
      );
    }
    // 命名构造 `.builder`（带 itemCount）才还原 `SliverList.builder`；delegate
    // 形态回到 SliverChildBuilderDelegate（保持源写法）。
    if (c.int_('itemCount') != null) {
      return SliverList.builder(
        itemCount: c.int_('itemCount'),
        itemBuilder: (_, i) => _childAt(children, i),
      );
    }
    return SliverList(delegate: _sliverDelegate(c));
  });

  // SliverGrid：gridDelegate 支持两种——
  // SliverGridDelegateWithFixedCrossAxisCount（crossAxisCount）与
  // SliverGridDelegateWithMaxCrossAxisExtent（maxCrossAxisExtent），
  // 按 props 是否含 maxCrossAxisExtent 分流；缺省间距 0/比例 1.0 即 Flutter 默认。
  // `.builder` 命名构造还原 `SliverGrid.builder`，其余走 delegate 还原。
  r.register('SliverGrid', (c) {
    final gridDelegate = _gridDelegateFromJson(c);
    if (c.str('builder') != null && c.int_('itemCount') != null) {
      return SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemCount: c.int_('itemCount'),
        itemBuilder: (_, i) => _childAt(c.children, i),
      );
    }
    return SliverGrid(gridDelegate: gridDelegate, delegate: _sliverDelegate(c));
  });

  // SliverAppBar：与 AppBar 同款（title/leading 是 element-prop、actions 是
  // children）+ sliver 专属 pinned/floating/snap/expandedHeight
  // （缺省 false/false/false/null，即 Flutter 默认）。
  r.register('SliverAppBar', (c) => SliverAppBar(
        leading: c.propChild('leading'),
        title: c.propChild('title'),
        actions: c.children.isEmpty ? null : c.children,
        backgroundColor: colorFromJson(c.props['backgroundColor']),
        foregroundColor: colorFromJson(c.props['foregroundColor']),
        elevation: c.num_('elevation'),
        // toolbarHeight 缺省为 Flutter 默认 kToolbarHeight（SDK 非空参数）。
        toolbarHeight: c.num_('toolbarHeight') ?? kToolbarHeight,
        centerTitle: c.bool_('centerTitle'),
        titleTextStyle: textStyleFromJson(c.map('titleTextStyle')),
        pinned: c.bool_('pinned') ?? false,
        floating: c.bool_('floating') ?? false,
        snap: c.bool_('snap') ?? false,
        expandedHeight: c.num_('expandedHeight'),
      ));

  // SliverPadding：padding + 单个 sliver（命名参数 sliver 翻译为子节点）。
  r.register('SliverPadding', (c) => SliverPadding(
        padding: edgeInsetsFromJson(c.map('padding')),
        sliver: c.childOrEmpty,
      ));

  // SliverToBoxAdapter：普通 widget 包装成 sliver。
  r.register('SliverToBoxAdapter', (c) => SliverToBoxAdapter(
        child: c.childOrEmpty,
      ));

  // SliverFillRemaining：child + hasScrollBody（缺省 true）/fillOverscroll
  // （缺省 false），即 Flutter 默认。
  r.register('SliverFillRemaining', (c) => SliverFillRemaining(
        hasScrollBody: c.bool_('hasScrollBody') ?? true,
        fillOverscroll: c.bool_('fillOverscroll') ?? false,
        child: c.childOrEmpty,
      ));

  // SliverFixedExtentList：delegate（.builder → 原生 SliverChildBuilderDelegate，
  // 否则 SliverChildListDelegate）+ itemExtent（必填，缺失按 0 兜底暴露问题）。
  r.register('SliverFixedExtentList', (c) => SliverFixedExtentList(
        delegate: _sliverDelegate(c),
        itemExtent: c.num_('itemExtent') ?? 0,
      ));

  // SliverFillViewport：delegate（同上分流）+ viewportFraction（缺省 1.0，
  // Flutter 默认）。
  r.register('SliverFillViewport', (c) => SliverFillViewport(
        delegate: _sliverDelegate(c),
        viewportFraction: c.num_('viewportFraction') ?? 1,
      ));

  // SliverOpacity / SliverOffstage / SliverIgnorePointer：必填属性缺省按
  // Flutter 组件同名默认兜底（opacity 1 / offstage false / ignoring false）。
  r.register('SliverOpacity', (c) => SliverOpacity(
        opacity: c.num_('opacity') ?? 1,
        sliver: c.childOrEmpty,
      ));

  r.register('SliverOffstage', (c) => SliverOffstage(
        offstage: c.bool_('offstage') ?? false,
        sliver: c.childOrEmpty,
      ));

  r.register('SliverIgnorePointer', (c) => SliverIgnorePointer(
        ignoring: c.bool_('ignoring') ?? false,
        sliver: c.childOrEmpty,
      ));

  // SliverSafeArea：left/top/right/bottom 缺省 true（Flutter 默认）。
  r.register('SliverSafeArea', (c) => SliverSafeArea(
        left: c.bool_('left') ?? true,
        top: c.bool_('top') ?? true,
        right: c.bool_('right') ?? true,
        bottom: c.bool_('bottom') ?? true,
        sliver: c.childOrEmpty,
      ));

  // SliverVisibility：visible 缺省 true（与 Visibility 同默认），
  // maintainState 缺省 false（Flutter 默认）。
  r.register('SliverVisibility', (c) => SliverVisibility(
        visible: c.bool_('visible') ?? true,
        maintainState: c.bool_('maintainState') ?? false,
        sliver: c.childOrEmpty,
      ));

  // SingleChildScrollView：controller 是 JS ScrollController 实例的序列化句柄
  // （{__jsuiScrollController: id}）时，返回 _JsScrollControllerView（按 id
  // 绑定真实 controller，滚动经 invoke 回传 metrics 镜像到 JS 实例）；
  // 无 controller → 原样 SingleChildScrollView（存量 JS 兼容）。
  r.register('SingleChildScrollView', (c) {
    final scId = scrollControllerIdOf(c.props['controller']);
    if (scId != null) {
      final scrollDirection =
          axisFromJson(c.props['scrollDirection']) ?? Axis.vertical;
      final physics = scrollPhysicsFromJson(c.props['physics']);
      final reverse = c.bool_('reverse') ?? false;
      final child = c.child();
      return _JsScrollControllerView(
        controllerId: scId,
        invoke: c.invoke,
        buildScrollView: (controller) => SingleChildScrollView(
          controller: controller,
          scrollDirection: scrollDirection,
          physics: physics,
          reverse: reverse,
          child: child,
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: axisFromJson(c.props['scrollDirection']) ?? Axis.vertical,
      padding: nullableEdgeInsets(c.map('padding')),
      physics: scrollPhysicsFromJson(c.props['physics']),
      reverse: c.bool_('reverse') ?? false,
      child: c.child(),
    );
  });

  // PageView：`controller` 传 null（译者不下发显式 controller，无需 PageController
  // 桥）→ PageView 内部自建 PageController。页切换经 onPageChanged 回传
  // 页码（值事件），JS 侧据此更新指示点。
  r.register('PageView', (c) => PageView(
        scrollDirection:
            axisFromJson(c.props['scrollDirection']) ?? Axis.horizontal,
        reverse: c.bool_('reverse') ?? false,
        pageSnapping: c.bool_('pageSnapping') ?? true,
        physics: scrollPhysicsFromJson(c.props['physics']),
        onPageChanged: c.on1<int>('event'),
        children: c.children,
      ));
}
