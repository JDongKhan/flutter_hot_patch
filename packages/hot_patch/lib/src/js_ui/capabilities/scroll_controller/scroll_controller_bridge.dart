// ===== 能力：ScrollController 句柄桥 + 滚动视图/sliver 组件注册 =====
//
// 一个能力 = 描述符 + 通道 + 桥接组件 + 组件注册，全部内聚在本文件。
//
// 句柄桥（通用层，见 capabilities/core/controller_bridge.dart）：
//   JS 侧 `new ScrollController()` 经 `reg(obj, 'ctrl/Scroll', {meta:{fn}})` 登记，
//   通用通道 `jsHandle` 的 create 落到本桥的 `ctrl/Scroll` 描述符 → 创建宿主
//   真实 ScrollController 并登记 metrics 转发句柄；渲染 SingleChildScrollView /
//   ListView / CustomScrollView / GridView（controller: {__handle: id}）时按 id
//   取真实 controller 并挂转发（滚动 → invoke 句柄 → JS 实例更新镜像 → 触发
//   listeners）。jumpTo / animateTo 走通用 op（call）；dispose 走通用 release。
import 'package:flutter/material.dart';

import '../../../json/flutter_from_json.dart';
import '../../js_widget_registry.dart';
import '../core/controller_bridge.dart';

/// ScrollController 句柄桥：创建/回传句柄登记/释放全走通用层（见
/// controller_bridge.dart），这里只留 jumpTo/animateTo 的 op 分派。
final JsControllerBridge<ScrollController>
_scrollBridge = JsControllerBridge<ScrollController>(
  kind: 'ctrl/Scroll',
  create: (_, _) => ScrollController(),
  onOp: (c, op, payload) {
    if (op == 'call') {
      final method = payload['method']?.toString() ?? '';
      final args = payload['args'] is List ? payload['args'] as List : const [];
      if (method == 'jumpTo') {
        c.jumpTo(
          args.isNotEmpty && args[0] is num ? (args[0] as num).toDouble() : 0,
        );
      } else if (method == 'animateTo') {
        final offset = args.isNotEmpty && args[0] is num
            ? (args[0] as num).toDouble()
            : 0.0;
        final ms = args.length > 1 && args[1] is num
            ? (args[1] as num).toInt()
            : 300;
        final name = args.length > 2 ? args[2]?.toString() : null;
        const curves = <String, Curve>{
          'linear': Curves.linear,
          'easeOut': Curves.easeOut,
          'easeIn': Curves.easeIn,
          'easeInOut': Curves.easeInOut,
        };
        c.animateTo(
          offset,
          duration: Duration(milliseconds: ms),
          curve: curves[name] ?? Curves.easeOut,
        );
      }
    }
    return null;
  },
);

/// 幂等注册 ScrollController 句柄 kind（由 js_ui_capabilities.ensureJsUiCapabilities
/// 聚合调用）。
void ensureScrollControllerChannels() => _scrollBridge.ensure();

/// controller 句柄 → 桥接 Host（ListView / GridView / CustomScrollView /
/// SingleChildScrollView 共用）：按 id 取/建真实 controller，滚动经 invoke
/// 回传 metrics 镜像到 JS 实例（__onMetrics 更新镜像 → 触发其 listeners——
/// 匿名 addListener 闭包由 JS 侧直接持有，天然支持）；首次 attach 回传初始
/// metrics：JS 镜像不依赖「先滚动才更新」，构造后立即准确——否则用户不滚动
/// 直接点「跳到底」会读到镜像 maxScrollExtent=0，jumpTo(0) 完全无效。
Widget _scrollControllerHost(
  JsRenderContext c,
  String id,
  Widget Function(ScrollController controller) build,
) => JsControllerHost<ScrollController>(
  bridge: _scrollBridge,
  id: id,
  create: ScrollController.new,
  forward: (controller, handler) {
    if (!controller.hasClients) return;
    c.invoke(handler, [
      {
        'pixels': controller.offset,
        'maxScrollExtent': controller.position.maxScrollExtent,
        'viewportDimension': controller.position.viewportDimension,
        'extentAfter': controller.position.extentAfter,
      },
    ]);
  },
  buildChild: build,
);

/// 从 props 还原 SliverGridDelegate：含 `maxCrossAxisExtent` →
/// SliverGridDelegateWithMaxCrossAxisExtent，否则
/// SliverGridDelegateWithFixedCrossAxisCount（crossAxisCount 缺省 1 兜底；
/// 间距 0/比例 1.0 即 Flutter 默认）。SliverGrid 与 GridView 共用。
///
/// 参数两种来源，都要读：`gridDelegate:` 构造（统一翻译产出 JSON 值 →
/// `props.gridDelegate`），或直接平铺在 props 上（`GridView.count` / `.extent`
/// 这类命名构造把 crossAxisCount / maxCrossAxisExtent 当自己的参数）。
SliverGridDelegate _gridDelegateFromJson(JsRenderContext c) {
  final g = c.map('gridDelegate') ?? const <String, dynamic>{};
  double? numOf(String key) {
    final v = c.num_(key) ?? (g[key] is num ? g[key] as num : null);
    return v?.toDouble();
  }

  int? intOf(String key) {
    final v = c.num_(key) ?? (g[key] is num ? g[key] as num : null);
    return v?.toInt();
  }

  final maxExtent = numOf('maxCrossAxisExtent');
  if (maxExtent != null) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxExtent,
      mainAxisSpacing: numOf('mainAxisSpacing') ?? 0,
      crossAxisSpacing: numOf('crossAxisSpacing') ?? 0,
      childAspectRatio: numOf('childAspectRatio') ?? 1,
      mainAxisExtent: numOf('mainAxisExtent'),
    );
  }
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: intOf('crossAxisCount') ?? 1,
    mainAxisSpacing: numOf('mainAxisSpacing') ?? 0,
    crossAxisSpacing: numOf('crossAxisSpacing') ?? 0,
    childAspectRatio: numOf('childAspectRatio') ?? 1,
    mainAxisExtent: numOf('mainAxisExtent'),
  );
}

/// builder 形态的方法名：统一翻译**按 Dart 形参名**下发道具——命名构造
/// `.builder` / `.separated` 的回调是 `itemBuilder`；`delegate:
/// SliverChildBuilderDelegate(...)` 形态的是 `builder`。
String? _builderMethod(JsRenderContext c) {
  final direct = c.str('itemBuilder') ?? c.str('builder');
  if (direct != null) return direct;
  // delegate 形态：builder 方法名在 children['delegate'] 的描述里。
  final del = c.children['delegate'];
  if (del is Map) {
    final b = del['builder'];
    if (b != null) return '$b';
  }
  return null;
}

/// `.separated` 形态：产物协议以命名构造名（`props.factory === 'separated'`）为准，
/// 兼容旧产物/兜底看「是否带了分隔项回调 `separatorBuilder`」。
bool _isSeparated(JsRenderContext c) =>
    c.str('factory') == 'separated' || c.str('separatorBuilder') != null;

/// sliver delegate 还原（**delegate 形态**：`SliverChildBuilderDelegate` 源写法）：
/// 有 `childCount` → `SliverChildBuilderDelegate`（代理类已按 childCount 展开
/// children）；否则 → `SliverChildListDelegate`。四个 sliver 组件共用。
SliverChildDelegate _sliverDelegate(JsRenderContext c) {
  final del = c.children['delegate'];
  // ListDelegate 形态：delegate 的列表在 children['delegate']。
  if (del is List<Widget>) {
    return SliverChildListDelegate(del);
  }
  final children = _flatChildren(c, 'children');
  // BuilderDelegate 形态：childCount 在 delegate 描述里，展开结果在 __items。
  final count = _builderCount(c, children.length);
  if (_builderMethod(c) != null) {
    return SliverChildBuilderDelegate(
      (_, i) => _childAt(children, i),
      childCount: count,
    );
  }
  return SliverChildListDelegate(children);
}

/// builder 形态的计数：命名构造（`.builder`/`.separated`）用 `itemCount`，
/// delegate 形态用 `childCount`；都缺省时退回已展开的子节点数。
int _builderCount(JsRenderContext c, int fallback) {
  final direct = c.int_('itemCount') ?? c.int_('childCount');
  if (direct != null) return direct;
  final del = c.children['delegate'];
  if (del is Map) {
    final n = del['childCount'];
    if (n is num) return n.toInt();
  }
  return fallback;
}

/// 第 [i] 个子节点（越界给占位，避免宿主在 JS 补丁未到齐时越界崩溃）。
Widget _childAt(List<Widget> children, int i) =>
    i < children.length ? children[i] : const SizedBox.shrink();

/// 普通 children 形态读 Dart 形参名（`children` / `slivers`）；builder 代理
/// 展开结果走内部键 `__items`。两者只有一个非空，按优先级合并。
List<Widget> _flatChildren(JsRenderContext c, String key) {
  final expanded = c.children['__items'];
  if (expanded is List<Widget> && expanded.isNotEmpty) return expanded;
  final own = c.children[key];
  return own is List<Widget> ? own : const [];
}

/// `.separated` 形态：代理类已按 `[item, sep, item, sep, ...]` 交替展开，
/// 宿主按奇偶拆回 items / separators 两组，分别喂给原生 `.separated` 的两个
/// builder（满足 Flutter「itemCount 为 item 数」的语义）。
({List<Widget> items, List<Widget> separators}) _splitSeparated(
  List<Widget> children,
) {
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
    // controller 是 JS ScrollController 句柄时走 _scrollControllerHost 桥接
    // （与 SingleChildScrollView 同一套 controller 绑定/metrics 回传）。
    // 三种形态：普通 children / `.builder`（props 带 itemBuilder+itemCount）/
    // `.separated`（额外带 separatorBuilder，且 factory='separated'）——builder
    // 形态一律还原 Flutter 原生命名构造，不用 `ListView(children: [...])` 顶替。
    final children = _flatChildren(c, 'children');
    final builder = _builderMethod(c);
    final isSeparated = _isSeparated(c);

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
      if (isSeparated) {
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

    final scId = JsControllerBridge.idOf(c.props['controller']);
    if (scId != null) return _scrollControllerHost(c, scId, build);
    return build(null);
  });

  // ReorderableListView：长按拖拽重排。事件 onReorder 是**双参**回调
  // `(int oldIndex, int newIndex)`，用 `on2` 还原——宿主把 `[oldIndex, newIndex]`
  // 参数数组回传，JS 侧 __bindFn 的 wrapper 摊开成位置实参（多参事件 ABI）。
  // children 为 JS 运行时下发的子结点，各自自带 ValueKey，满足 key 断言。
  //
  // 形态与其他滚动视图一致：
  //   - 普通构造：children 直接进 children；
  //   - `.builder`：代理类已按 itemCount 展开子结点，宿主还原
  //     `ReorderableListView.builder`（itemBuilder 按下标取已展开的结点）；
  //   - controller：Flutter 的形参名是 `scrollController`（不是 ListView 的
  //     `controller`），走与 ListView 同一套 `_scrollControllerHost` 桥接。
  r.register('ReorderableListView', (c) {
    final isBuilder = _builderMethod(c) != null;
    final children = _flatChildren(c, 'children');

    Widget build(ScrollController? controller) {
      // onReorder 非空：无句柄时给空实现，避免拖拽结束抛断言。
      final onReorder = c.on2<int, int>('onReorder') ?? (_, _) {};
      final scrollDirection =
          axisFromJson(c.props['scrollDirection']) ?? Axis.vertical;
      final padding = nullableEdgeInsets(c.map('padding'));
      final shrinkWrap = c.bool_('shrinkWrap') ?? false;
      final physics = scrollPhysicsFromJson(c.props['physics']);
      if (isBuilder) {
        return ReorderableListView.builder(
          scrollController: controller,
          onReorder: onReorder,
          itemCount: _builderCount(c, children.length),
          itemBuilder: (_, i) => _childAt(children, i),
          scrollDirection: scrollDirection,
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
        );
      }
      return ReorderableListView(
        scrollController: controller,
        onReorder: onReorder,
        scrollDirection: scrollDirection,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        children: children,
      );
    }

    final scId = JsControllerBridge.idOf(c.props['scrollController']);
    if (scId != null) return _scrollControllerHost(c, scId, build);
    return build(null);
  });

  // GridView：普通构造 / .builder（懒加载）/ .count / .extent。gridDelegate 按
  // props 还原（crossAxisCount / maxCrossAxisExtent 双形态）；controller 与
  // ListView 同款走 _scrollControllerHost 桥接。
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
    final children = _flatChildren(c, 'children');
    final isBuilder = _builderMethod(c) != null;
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

    final scId = JsControllerBridge.idOf(c.props['controller']);
    if (scId != null) return _scrollControllerHost(c, scId, build);
    return build(null);
  });

  // CustomScrollView：slivers 按原名进 props，元素工厂抽成有序 children
  // （宿主侧 SliverList/SliverAppBar 等已注册为 widget）；controller 与
  // ListView 同款分流 _scrollControllerHost 桥接。
  r.register('CustomScrollView', (c) {
    final scId = JsControllerBridge.idOf(c.props['controller']);
    if (scId != null) {
      final scrollDirection =
          axisFromJson(c.props['scrollDirection']) ?? Axis.vertical;
      final physics = scrollPhysicsFromJson(c.props['physics']);
      final reverse = c.bool_('reverse') ?? false;
      final shrinkWrap = c.bool_('shrinkWrap') ?? false;
      final slivers = _flatChildren(c, 'slivers');
      return _scrollControllerHost(
        c,
        scId,
        (controller) => CustomScrollView(
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
      scrollDirection:
          axisFromJson(c.props['scrollDirection']) ?? Axis.vertical,
      physics: scrollPhysicsFromJson(c.props['physics']),
      reverse: c.bool_('reverse') ?? false,
      shrinkWrap: c.bool_('shrinkWrap') ?? false,
      slivers: _flatChildren(c, 'slivers'),
    );
  });

  // SliverList：`.builder`/`.separated` 命名构造还原 Flutter 同名原生构造；
  // `SliverChildBuilderDelegate` 形态（只有 childCount）还原
  // `SliverChildBuilderDelegate`；ListDelegate 形态还原 `SliverChildListDelegate`。
  r.register('SliverList', (c) {
    final builder = _builderMethod(c);
    if (builder == null) return SliverList(delegate: _sliverDelegate(c));
    final children = ((c.children['__items'] as List<Widget>?) ?? const []);
    if (_isSeparated(c)) {
      final split = _splitSeparated(children);
      return SliverList.separated(
        itemCount: _builderCount(c, split.items.length),
        itemBuilder: (_, i) => _childAt(split.items, i),
        separatorBuilder: (_, i) => _childAt(split.separators, i),
      );
    }
    // 命名构造 `.builder`（产物带 factory='builder'，且有 itemCount）才还原
    // `SliverList.builder`；delegate 形态回到 SliverChildBuilderDelegate。
    if (c.str('factory') == 'builder' || c.int_('itemCount') != null) {
      return SliverList.builder(
        itemCount: _builderCount(c, children.length),
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
    if (_builderMethod(c) != null && c.int_('itemCount') != null) {
      return SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemCount: c.int_('itemCount'),
        itemBuilder: (_, i) => _childAt(((c.children['__items'] as List<Widget>?) ?? const []), i),
      );
    }
    return SliverGrid(gridDelegate: gridDelegate, delegate: _sliverDelegate(c));
  });

  // SliverAppBar：与 AppBar 同款（title/leading/flexibleSpace 是 element-prop、
  // actions 是 props 里的结点数组）+ sliver 专属 pinned/floating/snap/expandedHeight
  // （缺省 false/false/false/null，即 Flutter 默认）。
  r.register('SliverAppBar', (c) {
    final actions =
        (c.children['actions'] as List<Widget>?) ?? const <Widget>[];
    return SliverAppBar(
      leading: (c.children['leading'] as Widget?),
      title: (c.children['title'] as Widget?),
      flexibleSpace: (c.children['flexibleSpace'] as Widget?),
      actions: actions.isEmpty ? null : actions,
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
    );
  });

  // SliverPadding：padding + 单个 sliver（命名参数 sliver 翻译为子节点）。
  r.register(
    'SliverPadding',
    (c) => SliverPadding(
      padding: edgeInsetsFromJson(c.map('padding')),
      sliver: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  // SliverToBoxAdapter：普通 widget 包装成 sliver。
  r.register(
    'SliverToBoxAdapter',
    (c) => SliverToBoxAdapter(child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink())),
  );

  // SliverFillRemaining：child + hasScrollBody（缺省 true）/fillOverscroll
  // （缺省 false），即 Flutter 默认。
  r.register(
    'SliverFillRemaining',
    (c) => SliverFillRemaining(
      hasScrollBody: c.bool_('hasScrollBody') ?? true,
      fillOverscroll: c.bool_('fillOverscroll') ?? false,
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  // SliverFixedExtentList：delegate（.builder → 原生 SliverChildBuilderDelegate，
  // 否则 SliverChildListDelegate）+ itemExtent（必填，缺失按 0 兜底暴露问题）。
  r.register(
    'SliverFixedExtentList',
    (c) => SliverFixedExtentList(
      delegate: _sliverDelegate(c),
      itemExtent: c.num_('itemExtent') ?? 0,
    ),
  );

  // SliverFillViewport：delegate（同上分流）+ viewportFraction（缺省 1.0，
  // Flutter 默认）。
  r.register(
    'SliverFillViewport',
    (c) => SliverFillViewport(
      delegate: _sliverDelegate(c),
      viewportFraction: c.num_('viewportFraction') ?? 1,
    ),
  );

  // SliverOpacity / SliverOffstage / SliverIgnorePointer：必填属性缺省按
  // Flutter 组件同名默认兜底（opacity 1 / offstage false / ignoring false）。
  r.register(
    'SliverOpacity',
    (c) =>
        SliverOpacity(opacity: c.num_('opacity') ?? 1, sliver: ((c.children['child'] as Widget?) ?? const SizedBox.shrink())),
  );

  r.register(
    'SliverOffstage',
    (c) => SliverOffstage(
      offstage: c.bool_('offstage') ?? false,
      sliver: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register(
    'SliverIgnorePointer',
    (c) => SliverIgnorePointer(
      ignoring: c.bool_('ignoring') ?? false,
      sliver: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  // SliverSafeArea：left/top/right/bottom 缺省 true（Flutter 默认）。
  r.register(
    'SliverSafeArea',
    (c) => SliverSafeArea(
      left: c.bool_('left') ?? true,
      top: c.bool_('top') ?? true,
      right: c.bool_('right') ?? true,
      bottom: c.bool_('bottom') ?? true,
      sliver: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  // SliverVisibility：visible 缺省 true（与 Visibility 同默认），
  // maintainState 缺省 false（Flutter 默认）。
  r.register(
    'SliverVisibility',
    (c) => SliverVisibility(
      visible: c.bool_('visible') ?? true,
      maintainState: c.bool_('maintainState') ?? false,
      sliver: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  // SingleChildScrollView：controller 是 JS ScrollController 实例的序列化句柄
  // （{__handle: 'js:ctrl/Scroll#N'}）时走 _scrollControllerHost 桥接（按 id
  // 绑定真实 controller，滚动经 invoke 回传 metrics 镜像到 JS 实例）；
  // 无 controller → 原样 SingleChildScrollView。
  r.register('SingleChildScrollView', (c) {
    final scId = JsControllerBridge.idOf(c.props['controller']);
    if (scId != null) {
      final scrollDirection =
          axisFromJson(c.props['scrollDirection']) ?? Axis.vertical;
      final physics = scrollPhysicsFromJson(c.props['physics']);
      final reverse = c.bool_('reverse') ?? false;
      final child = (c.children['child'] as Widget?);
      return _scrollControllerHost(
        c,
        scId,
        (controller) => SingleChildScrollView(
          controller: controller,
          scrollDirection: scrollDirection,
          physics: physics,
          reverse: reverse,
          child: child,
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection:
          axisFromJson(c.props['scrollDirection']) ?? Axis.vertical,
      padding: nullableEdgeInsets(c.map('padding')),
      physics: scrollPhysicsFromJson(c.props['physics']),
      reverse: c.bool_('reverse') ?? false,
      child: (c.children['child'] as Widget?),
    );
  });

  // PageView：`controller` 传 null（译者不下发显式 controller，无需 PageController
  // 桥）→ PageView 内部自建 PageController。页切换经 onPageChanged 回传
  // 页码（值事件），JS 侧据此更新指示点。
  r.register(
    'PageView',
    (c) => PageView(
      scrollDirection:
          axisFromJson(c.props['scrollDirection']) ?? Axis.horizontal,
      reverse: c.bool_('reverse') ?? false,
      pageSnapping: c.bool_('pageSnapping') ?? true,
      physics: scrollPhysicsFromJson(c.props['physics']),
      onPageChanged: c.on1<int>('onPageChanged'),
      children: ((c.children['__items'] as List<Widget>?) ?? const []),
    ),
  );
}
