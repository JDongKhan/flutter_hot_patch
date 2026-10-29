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

import '../../js_widget_registry.dart';
import '../../ui_fallback.dart';
import '../base_widget/text_from_json.dart';
import '../core/controller_bridge.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';
import '../core/from_json/widget_enum_from_json.dart';

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

/// PageController 句柄桥：与 ScrollController 同一套通用层，只多
/// jumpToPage / animateToPage / nextPage / previousPage 的方法分派。
final JsControllerBridge<PageController> _pageBridge =
    JsControllerBridge<PageController>(
  kind: 'ctrl/Page',
  // 真实 PageController 由 Host 带 initialPage / viewportFraction 创建
  // （与 TabController 同模式）；此处不能预创建默认实例，否则 Host 的
  // putIfAbsent 会复用它而丢掉构造参数。
  onOp: (c, op, payload) {
    if (op == 'call') {
      final method = payload['method']?.toString() ?? '';
      final args = payload['args'] is List ? payload['args'] as List : const [];
      const curves = <String, Curve>{
        'linear': Curves.linear,
        'easeOut': Curves.easeOut,
        'easeIn': Curves.easeIn,
        'easeInOut': Curves.easeInOut,
      };
      // 实参位置按方法各自的口径取：animateToPage = [page, ms, curve]，
      // nextPage / previousPage = [ms, curve]（切换页不需要 page）。
      final isPageTurn = method == 'nextPage' || method == 'previousPage';
      int msAt(int i) => args.length > i && args[i] is num
          ? (args[i] as num).toInt()
          : 300;
      Curve curveAt(int i) => args.length > i
          ? curves[args[i]?.toString()] ?? Curves.easeOut
          : Curves.easeOut;
      final ms = msAt(isPageTurn ? 0 : 1);
      final curve = curveAt(isPageTurn ? 1 : 2);
      final page = args.isNotEmpty && args[0] is num
          ? (args[0] as num).toInt()
          : 0;
      if (method == 'jumpToPage') {
        c.jumpToPage(page);
      } else if (method == 'animateToPage') {
        c.animateToPage(
          page,
          duration: Duration(milliseconds: ms),
          curve: curve,
        );
      } else if (method == 'nextPage') {
        c.nextPage(duration: Duration(milliseconds: ms), curve: curve);
      } else if (method == 'previousPage') {
        c.previousPage(duration: Duration(milliseconds: ms), curve: curve);
      }
    }
    return null;
  },
);

/// 幂等注册 ScrollController 句柄 kind（由 js_ui_capabilities.ensureJsUiCapabilities
/// 聚合调用）。
void ensureScrollControllerChannels() {
  _scrollBridge.ensure();
  _pageBridge.ensure();
}

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

Widget _pageControllerHost(
  JsRenderContext c,
  String id,
  int initialPage,
  double viewportFraction,
  Widget Function(PageController controller) build,
) =>
    JsControllerHost<PageController>(
      bridge: _pageBridge,
      id: id,
      create: () => PageController(
        initialPage: initialPage,
        viewportFraction: viewportFraction,
      ),
      forward: (controller, handler) {
        if (!controller.hasClients) return;
        final page = controller.page;
        if (page == null) return;
        c.invoke(handler, [
          {'page': page, 'initialPage': initialPage},
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

/// 命名构造 builder 形态：`props.factory`（`builder` / `separated`，由产物里
/// `ListView.builder` / `.separated` 的静态方法写下）。
/// 回调名 / 计数只由 Flutter 该命名构造自己的形参约定决定，不做跨类型猜测。
bool _isNamedBuilderForm(JsRenderContext c) {
  final f = c.str('factory');
  return f == 'builder' || f == 'separated';
}

/// delegate builder 形态：生成器把 `SliverChildBuilderDelegate(...)` 译成
/// `children.delegate = {__delegate: 'builder', builder, childCount}`。
bool _isDelegateBuilderForm(JsRenderContext c) {
  final del = c.children['delegate'];
  return del is Map && del['__delegate'] == 'builder';
}

/// `.separated` 形态：命名构造名即协议（`props.factory === 'separated'`）。
bool _isSeparated(JsRenderContext c) => c.str('factory') == 'separated';

/// sliver delegate 还原：delegate 描述里的 builder 形态 →
/// `SliverChildBuilderDelegate`（子结点已按 childCount 展开）；否则 →
/// `SliverChildListDelegate`。四个 sliver 组件共用。
SliverChildDelegate _sliverDelegate(JsRenderContext c) {
  final del = c.children['delegate'];
  // ListDelegate 形态：delegate 的列表在 children['delegate']。
  if (del is List<Widget>) {
    return SliverChildListDelegate(del);
  }
  final children = _flatChildren(c, 'children');
  if (_isDelegateBuilderForm(c)) {
    return SliverChildBuilderDelegate(
      (_, i) => _childAt(children, i),
      childCount: _builderCount(c, children.length),
    );
  }
  return SliverChildListDelegate(children);
}

/// builder 形态的计数：delegate 描述的 `childCount` 优先；命名构造用
/// `itemCount`；都缺省时退回已展开的子节点数。
int _builderCount(JsRenderContext c, int fallback) {
  final del = c.children['delegate'];
  if (del is Map && del['childCount'] is num) {
    return (del['childCount'] as num).toInt();
  }
  return c.int_('itemCount') ?? fallback;
}

/// 第 [i] 个子节点（越界给兜底占位，避免宿主在 JS 补丁未到齐时越界崩溃）。
Widget _childAt(List<Widget> children, int i) => i < children.length
    ? children[i]
    : uiFallback('列表下标 $i 越界（当前 ${children.length} 项）');

/// 普通 children 形态读 Dart 形参名（`children` / `slivers`）；builder 代理
/// 展开结果走内部键 `__items`。`__items` 存在即权威（0 项也是合法的展开结果，
/// 不能因为为空就回退到普通 children）。
List<Widget> _flatChildren(JsRenderContext c, String key) {
  final expanded = c.children['__items'];
  if (expanded is List<Widget>) return expanded;
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
    final builder = _isNamedBuilderForm(c);
    final isSeparated = _isSeparated(c);

    Widget build(ScrollController? controller) {
      final shrinkWrap = c.bool_('shrinkWrap') ?? false;
      final scrollDirection =
          axisFromJson(c.props['scrollDirection']) ?? Axis.vertical;
      final padding = nullableEdgeInsets(c.map('padding'));
      final physics = scrollPhysicsFromJson(c.props['physics']);
      final itemExtent = c.num_('itemExtent');
      if (!builder) {
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
    final isBuilder = _isNamedBuilderForm(c);
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
    final isBuilder = _isNamedBuilderForm(c);
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

  // NestedScrollView：头部 slivers 由 JS 侧组件调用 `headerSliverBuilder`
  // 展开后经 `headerSlivers` 插槽下发（宿主不感知 builder），`body` 同插槽。
  // controller 与其它滚动视图同款分流 _scrollControllerHost。
  r.register('NestedScrollView', (c) {
    final headers = _flatChildren(c, 'headerSlivers');
    final body = (c.children['body'] as Widget?) ?? const SizedBox.shrink();
    final reverse = c.bool_('reverse') ?? false;
    final floatHeaderSlivers = c.bool_('floatHeaderSlivers') ?? false;
    final scrollDirection =
        axisFromJson(c.props['scrollDirection']) ?? Axis.vertical;
    final physics = scrollPhysicsFromJson(c.props['physics']);
    final clipBehavior = clipBehaviorFromJson(c.props['clipBehavior']);
    Widget buildWith(ScrollController? controller) => NestedScrollView(
          controller: controller,
          body: body,
          headerSliverBuilder: (_, _) => headers,
          reverse: reverse,
          floatHeaderSlivers: floatHeaderSlivers,
          scrollDirection: scrollDirection,
          physics: physics,
          clipBehavior: clipBehavior ?? Clip.hardEdge,
        );
    final scId = JsControllerBridge.idOf(c.props['controller']);
    if (scId == null) return buildWith(null);
    return _scrollControllerHost(c, scId, buildWith);
  });

  // SliverList：`.builder`/`.separated` 命名构造还原 Flutter 同名原生构造；
  // `SliverChildBuilderDelegate` 形态（只有 childCount）还原
  // `SliverChildBuilderDelegate`；ListDelegate 形态还原 `SliverChildListDelegate`。
  r.register('SliverList', (c) {
    // 非命名构造（delegate 形态）直接还原 delegate：BuilderDelegate 由
    // `children.delegate` 描述还原，ListDelegate 由 delegate 列表还原。
    if (!_isNamedBuilderForm(c)) return SliverList(delegate: _sliverDelegate(c));
    final children = (c.children['__items'] as List<Widget>?) ?? const [];
    if (_isSeparated(c)) {
      final split = _splitSeparated(children);
      return SliverList.separated(
        itemCount: _builderCount(c, split.items.length),
        itemBuilder: (_, i) => _childAt(split.items, i),
        separatorBuilder: (_, i) => _childAt(split.separators, i),
      );
    }
    return SliverList.builder(
      itemCount: _builderCount(c, children.length),
      itemBuilder: (_, i) => _childAt(children, i),
    );
  });

  // SliverGrid：gridDelegate 支持两种——
  // SliverGridDelegateWithFixedCrossAxisCount（crossAxisCount）与
  // SliverGridDelegateWithMaxCrossAxisExtent（maxCrossAxisExtent），
  // 按 props 是否含 maxCrossAxisExtent 分流；缺省间距 0/比例 1.0 即 Flutter 默认。
  // 命名构造按 `factory` 还原：`.builder` / `.separated`（代理类展开，sep 项
  // 交替排列）与 `.count` / `.extent` / `.list`（平铺 gridDelegate 参数 + children）。
  r.register('SliverGrid', (c) {
    final gridDelegate = _gridDelegateFromJson(c);
    if (_isNamedBuilderForm(c)) {
      final children = _flatChildren(c, 'children');
      if (_isSeparated(c)) {
        // SliverGrid 本身没有 `.separated`（Flutter 只在 GridView 上提供）：
        // 分隔件作为网格项交替插入，与 GridView.separated 的原生实现相同。
        final split = _splitSeparated(children);
        final list = <Widget>[];
        for (var i = 0; i < split.items.length; i++) {
          list.add(split.items[i]);
          if (i < split.separators.length) list.add(split.separators[i]);
        }
        return SliverGrid(
          gridDelegate: gridDelegate,
          delegate: SliverChildListDelegate(list),
        );
      }
      return SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemCount: _builderCount(c, children.length),
        itemBuilder: (_, i) => _childAt(children, i),
      );
    }
    // `.count` / `.extent`：crossAxisCount / maxCrossAxisExtent 等平铺在 props，
    // `_gridDelegateFromJson` 已读完；子项就是 `children` 列表。
    // `.list` 与普通构造：delegate 描述还原（list / builder 两种）。
    final factory = c.str('factory');
    if (factory == 'count' || factory == 'extent') {
      return SliverGrid(
        gridDelegate: gridDelegate,
        delegate: SliverChildListDelegate(_flatChildren(c, 'children')),
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
    final leading = (c.children['leading'] as Widget?);
    final title = (c.children['title'] as Widget?);
    final flexibleSpace = (c.children['flexibleSpace'] as Widget?);
    final backgroundColor = colorFromJson(c.props['backgroundColor']);
    final foregroundColor = colorFromJson(c.props['foregroundColor']);
    final elevation = c.num_('elevation');
    // toolbarHeight 缺省为 Flutter 默认 kToolbarHeight（SDK 非空参数）。
    final toolbarHeight = c.num_('toolbarHeight') ?? kToolbarHeight;
    final centerTitle = c.bool_('centerTitle');
    final titleTextStyle = textStyleFromJson(c.map('titleTextStyle'));
    final pinned = c.bool_('pinned') ?? false;
    final floating = c.bool_('floating') ?? false;
    final snap = c.bool_('snap') ?? false;
    final expandedHeight = c.num_('expandedHeight');
    // `.large` / `.medium` 是命名构造：固定 expandedHeight 与 pinned/floating
    // 默认值，宿主按 factory 还原原生构造。
    switch (c.str('factory')) {
      case 'large':
        return SliverAppBar.large(
          leading: leading,
          title: title,
          flexibleSpace: flexibleSpace,
          actions: actions.isEmpty ? null : actions,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: elevation,
          expandedHeight: expandedHeight,
          centerTitle: centerTitle,
          titleTextStyle: titleTextStyle,
        );
      case 'medium':
        return SliverAppBar.medium(
          leading: leading,
          title: title,
          flexibleSpace: flexibleSpace,
          actions: actions.isEmpty ? null : actions,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: elevation,
          expandedHeight: expandedHeight,
          centerTitle: centerTitle,
          titleTextStyle: titleTextStyle,
        );
      default:
        return SliverAppBar(
          leading: leading,
          title: title,
          flexibleSpace: flexibleSpace,
          actions: actions.isEmpty ? null : actions,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: elevation,
          toolbarHeight: toolbarHeight,
          centerTitle: centerTitle,
          titleTextStyle: titleTextStyle,
          pinned: pinned,
          floating: floating,
          snap: snap,
          expandedHeight: expandedHeight,
        );
    }
  });

  // SliverPadding：padding + 单个 sliver（命名参数 sliver 翻译为子节点）。
  r.register(
    'SliverPadding',
    (c) => SliverPadding(
      padding: edgeInsetsFromJson(c.map('padding')),
      sliver: ((c.children['sliver'] as Widget?) ?? const SizedBox.shrink()),
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

  // SliverFixedExtentList：delegate（`.builder` → 原生 SliverChildBuilderDelegate，
  // `.list` / 普通构造 → SliverChildListDelegate）+ itemExtent（必填，缺失按 0
  // 兜底暴露问题）。`.builder` 命名构造按 factory 还原，保留懒加载。
  r.register('SliverFixedExtentList', (c) {
    final itemExtent = c.num_('itemExtent') ?? 0;
    if (_isNamedBuilderForm(c)) {
      final children = _flatChildren(c, 'children');
      return SliverFixedExtentList.builder(
        itemExtent: itemExtent,
        itemCount: _builderCount(c, children.length),
        itemBuilder: (_, i) => _childAt(children, i),
      );
    }
    return SliverFixedExtentList(
      delegate: _sliverDelegate(c),
      itemExtent: itemExtent,
    );
  });

  // SliverFillViewport：delegate（同上分流）+ viewportFraction（缺省 1.0）/
  // padEnds（缺省 true），即 Flutter 默认。
  r.register(
    'SliverFillViewport',
    (c) => SliverFillViewport(
      delegate: _sliverDelegate(c),
      viewportFraction: c.num_('viewportFraction') ?? 1,
      padEnds: c.bool_('padEnds') ?? true,
    ),
  );

  // SliverOpacity / SliverOffstage / SliverIgnorePointer：必填属性缺省按
  // Flutter 组件同名默认兜底（opacity 1 / offstage false / ignoring false）。
  r.register(
    'SliverOpacity',
    (c) =>
        SliverOpacity(opacity: c.num_('opacity') ?? 1, sliver: ((c.children['sliver'] as Widget?) ?? const SizedBox.shrink())),
  );

  r.register(
    'SliverOffstage',
    (c) => SliverOffstage(
      offstage: c.bool_('offstage') ?? false,
      sliver: ((c.children['sliver'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register(
    'SliverIgnorePointer',
    (c) => SliverIgnorePointer(
      ignoring: c.bool_('ignoring') ?? false,
      sliver: ((c.children['sliver'] as Widget?) ?? const SizedBox.shrink()),
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
      sliver: ((c.children['sliver'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  // SliverVisibility：与盒子版同一组参数（visible / maintain*），另加
  // replacementSliver。断言链与 Visibility 一致，由调用方保证。
  r.register(
    'SliverVisibility',
    (c) => SliverVisibility(
      visible: c.bool_('visible') ?? true,
      maintainState: c.bool_('maintainState') ?? false,
      maintainAnimation: c.bool_('maintainAnimation') ?? false,
      maintainSize: c.bool_('maintainSize') ?? false,
      maintainSemantics: c.bool_('maintainSemantics') ?? false,
      maintainInteractivity: c.bool_('maintainInteractivity') ?? false,
      replacementSliver: (c.children['replacementSliver'] as Widget?) ?? const SliverToBoxAdapter(),
      sliver: ((c.children['sliver'] as Widget?) ?? const SizedBox.shrink()),
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

  // PageView：普通 children / `.builder`（itemBuilder + itemCount）；controller
  // 是 JS PageController 句柄时走 id-bridge（jumpToPage / animateToPage /
  // nextPage / previousPage），否则由 PageView 内部自建。
  r.register('PageView', (c) {
    final children = _flatChildren(c, 'children');
    final builder = _isNamedBuilderForm(c);
    final count = _builderCount(c, children.length);

    Widget build(PageController? controller) {
      final direction =
          axisFromJson(c.props['scrollDirection']) ?? Axis.horizontal;
      final reverse = c.bool_('reverse') ?? false;
      final pageSnapping = c.bool_('pageSnapping') ?? true;
      final physics = scrollPhysicsFromJson(c.props['physics']);
      final onPageChanged = c.on1<int>('onPageChanged');
      if (builder) {
        return PageView.builder(
          controller: controller,
          scrollDirection: direction,
          reverse: reverse,
          pageSnapping: pageSnapping,
          physics: physics,
          onPageChanged: onPageChanged,
          itemCount: count,
          itemBuilder: (_, i) => _childAt(children, i),
        );
      }
      return PageView(
        controller: controller,
        scrollDirection: direction,
        reverse: reverse,
        pageSnapping: pageSnapping,
        physics: physics,
        onPageChanged: onPageChanged,
        children: children,
      );
    }

    final pcId = JsControllerBridge.idOf(c.props['controller']);
    if (pcId != null) {
      final raw = c.props['controller'];
      final initial = raw is Map && raw['initialPage'] is num
          ? (raw['initialPage'] as num).toInt()
          : 0;
      final fraction = raw is Map && raw['viewportFraction'] is num
          ? (raw['viewportFraction'] as num).toDouble()
          : 1.0;
      return _pageControllerHost(c, pcId, initial, fraction, build);
    }
    return build(null);
  });
}
