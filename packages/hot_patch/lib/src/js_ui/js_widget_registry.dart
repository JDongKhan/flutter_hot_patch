import 'package:flutter/material.dart';

import '../json/flutter_from_json.dart';
import '../services/js_runtime_manager.dart';
import '../utils/hot_patch_log.dart';

// ===== ScrollController 桥接表（JS ScrollController ↔ Dart ScrollController）====
// JS 侧 `new ScrollController()` 经 scrollControllerRegister 通道登记
// metrics 转发句柄；宿主渲染 SingleChildScrollView(controller: {__jsuiScrollController:
// id}) 时按 id 取/建真实 controller 并挂转发（滚动 → invoke 句柄 → JS 实例
// 更新镜像 → 触发其 listeners）。jumpTo/animateTo/dispose 走实例级通道。
final Map<String, ScrollController> _jsScrollControllers = {};
final Map<String, Object?> _jsScrollMetricsHandles = {};
final Set<String> _jsScrollAttached = {};

bool _scrollControllerChannelsRegistered = false;

/// 幂等注册 ScrollController 桥接通道（JsUiWidget 启动时调用一次；
/// registerHostMethod 全局表 + 断言防重复，故用标志位兜底）。
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
String? _scrollControllerIdOf(Object? prop) {
  if (prop is Map) {
    final id = prop['__jsuiScrollController'];
    if (id is String) return id;
  }
  return null;
}

/// 一次结点构建的上下文：JS 下发的 props + 已构建好的子 widget + 事件回传。
///
/// 这是宿主与 JS 的唯一"翻译面"：JS 侧的 `Text({...})` 到这里变成
/// 真正的 Flutter `Text`。新增一个 JS 组件只要用已有 type 组合即可，
/// 不需要动宿主；只有引入 Flutter 侧不存在的**视觉** widget 才注册一条。
class JsBuildContext {
  JsBuildContext({
    required this.props,
    required this.children,
    required this.childTypes,
    required this.childContexts,
    required this.propChildren,
    required this.nativeComponents,
    required this.invoke,
  });

  final Map<String, dynamic> props;
  final List<Widget> children;

  /// 与 [children] 一一对应的宿主 type（用于 Scaffold 这类需要按类型
  /// 区分插槽的容器；JS 只能下发 element，无法在 props 里塞 widget）。
  final List<String> childTypes;

  /// 与 [children] 一一对应的子结点数据（type/props/propChildren），
  /// 用于 BottomNavigationBarItem / DropdownMenuItem 这类「非 Widget
  /// 数据载体」子结点——父 renderer 直接读数据组装，不走 widget 包装。
  final List<JsBuildContext> childContexts;

  /// 值为 element 的 props（如 ListTile.leading / ClipRRect.child）：
  /// prop 名 -> 已构建好的子 widget。
  final Map<String, Widget> propChildren;

  /// 非私有/无注解组件（Component 节点）的原生注入表：组件名 -> 构造。
  /// 运行时（hot_patch 包）不 import 业务类，由业务方注册。
  final Map<String, Widget Function(Map<String, dynamic> args)>
      nativeComponents;

  /// 把事件句柄（`{'__fn': id}`）回传到 JS 侧执行。
  final void Function(Object? handler, [Object? payload]) invoke;

  Widget? child([int index = 0]) => index < children.length ? children[index] : null;

  /// 要求子 widget 非空时使用（Expanded / 按钮的 child 等）。
  Widget get childOrEmpty => child() ?? const SizedBox.shrink();

  /// 按子结点 type 取第一个匹配的子 widget。
  Widget? childOfType(String type) {
    for (var i = 0; i < childTypes.length; i++) {
      if (childTypes[i] == type) return children[i];
    }
    return null;
  }

  bool hasChildOfType(String type) => childTypes.contains(type);

  /// 取「值为 element 的 prop」对应的子 widget（如 ListTile.leading）。
  Widget? propChild(String key) => propChildren[key];

  /// 把 props 上的事件字段（句柄）绑成 Flutter 回调；无句柄（null）时为 null。
  VoidCallback? on(String key) {
    final handler = props[key];
    if (handler == null) return null;
    return () => invoke(handler);
  }

  /// 值为句柄的 prop → 带 payload 的回调（Switch/Checkbox/Slider 的 onChanged）。
  ValueChanged<T>? onValue<T>(String key) {
    final handler = props[key];
    if (handler == null) return null;
    return (v) => invoke(handler, v);
  }

  String? str(String key) {
    final v = props[key];
    return v == null ? null : '$v';
  }

  double? num_(String key) {
    final v = props[key];
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  int? int_(String key) {
    final v = props[key];
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  bool? bool_(String key) {
    final v = props[key];
    return v is bool ? v : null;
  }

  Map<String, dynamic>? map(String key) {
    final v = props[key];
    return v is Map ? v.cast<String, dynamic>() : null;
  }
}

typedef JsWidgetBuilder = Widget Function(JsBuildContext c);

/// `type -> Flutter widget` 注册表（宿主唯一扩展点）。
class JsWidgetRegistry {
  final Map<String, JsWidgetBuilder> _builders = {};

  void register(String type, JsWidgetBuilder builder) => _builders[type] = builder;

  bool has(String type) => _builders.containsKey(type);

  JsWidgetBuilder? lookup(String type) => _builders[type];
}

/// 注册内置的宿主 widget 翻译。
///
/// 只覆盖「JS 侧组件用到的、Flutter 侧真实存在的」类型；未注册的类型渲染为
/// 错误占位（便于定位缺失的翻译），而不是静默空白。
///
/// 状态类 widget（provider / Builder / ListenableBuilder）**不在这里**：
/// 它们由 JS 侧逻辑组件承担，宿主零感知。
void registerBuiltinJsWidgets(JsWidgetRegistry r) {
  r.register('Text', (c) => Text(
        c.str('data') ?? '',
        style: textStyleFromJson(c.map('style')),
        textAlign: textAlignFromJson(c.props['textAlign']),
        overflow: overflowFromJson(c.props['overflow']),
        maxLines: c.int_('maxLines'),
        softWrap: c.bool_('softWrap'),
        textDirection: textDirectionFromJson(c.props['textDirection']),
        textScaler: textScalerFromJson(c.props['textScaler']),
        semanticsLabel: c.str('semanticsLabel'),
      ));

  r.register('Column', (c) => Column(
        mainAxisAlignment: mainAxisAlignmentFromJson(c.props['mainAxisAlignment']) ?? MainAxisAlignment.start,
        crossAxisAlignment: crossAxisAlignmentFromJson(c.props['crossAxisAlignment']) ?? CrossAxisAlignment.center,
        mainAxisSize: mainAxisSizeFromJson(c.props['mainAxisSize']) ?? MainAxisSize.max,
        children: c.children,
      ));

  r.register('Row', (c) => Row(
        mainAxisAlignment: mainAxisAlignmentFromJson(c.props['mainAxisAlignment']) ?? MainAxisAlignment.start,
        crossAxisAlignment: crossAxisAlignmentFromJson(c.props['crossAxisAlignment']) ?? CrossAxisAlignment.center,
        mainAxisSize: mainAxisSizeFromJson(c.props['mainAxisSize']) ?? MainAxisSize.max,
        children: c.children,
      ));

  r.register('Stack', (c) => Stack(
        alignment: alignmentFromJson(c.props['alignment']) ?? AlignmentDirectional.topStart,
        fit: stackFitFromJson(c.props['fit']) ?? StackFit.loose,
        clipBehavior: clipBehaviorFromJson(c.props['clipBehavior']) ?? Clip.hardEdge,
        children: c.children,
      ));

  r.register('Wrap', (c) => Wrap(
        direction: axisFromJson(c.props['direction']) ?? Axis.horizontal,
        spacing: c.num_('spacing') ?? 0,
        runSpacing: c.num_('runSpacing') ?? 0,
        alignment: wrapAlignmentFromJson(c.props['alignment']) ?? WrapAlignment.start,
        runAlignment:
            wrapAlignmentFromJson(c.props['runAlignment']) ?? WrapAlignment.start,
        crossAxisAlignment: wrapCrossAlignmentFromJson(
                c.props['crossAxisAlignment']) ??
            WrapCrossAlignment.start,
        children: c.children,
      ));

  r.register('ListView', (c) {
    // controller 是 JS ScrollController 句柄时走通用桥接包装器（与
    // SingleChildScrollView 同一套 controller 绑定/metrics 回传），
    // 无 controller → 原样 ListView。
    final scId = _scrollControllerIdOf(c.props['controller']);
    if (scId != null) {
      final shrinkWrap = c.bool_('shrinkWrap') ?? false;
      final scrollDirection =
          axisFromJson(c.props['scrollDirection']) ?? Axis.vertical;
      final padding = nullableEdgeInsets(c.map('padding'));
      final physics = scrollPhysicsFromJson(c.props['physics']);
      final itemExtent = c.num_('itemExtent');
      final children = c.children;
      return _JsScrollControllerView(
        controllerId: scId,
        invoke: c.invoke,
        buildScrollView: (controller) => ListView(
          controller: controller,
          // shrinkWrap 缺省保持 Flutter 默认（false）——与原生渲染一致。
          shrinkWrap: shrinkWrap,
          scrollDirection: scrollDirection,
          padding: padding,
          physics: physics,
          itemExtent: itemExtent,
          children: children,
        ),
      );
    }
    return ListView(
      // shrinkWrap 缺省保持 Flutter 默认（false）——与原生渲染一致；
      // 存量 JS 产物未下发时同样按默认处理。
      shrinkWrap: c.bool_('shrinkWrap') ?? false,
      scrollDirection: axisFromJson(c.props['scrollDirection']) ?? Axis.vertical,
      padding: nullableEdgeInsets(c.map('padding')),
      physics: scrollPhysicsFromJson(c.props['physics']),
      itemExtent: c.num_('itemExtent'),
      children: c.children,
    );
  });

  // CustomScrollView：slivers 是 children（宿主侧 SliverList/SliverAppBar 等
  // 已注册为 widget，直接进 slivers 列表）；controller 与 ListView 同款
  // 分流通用 _JsScrollControllerView 包装器。
  r.register('CustomScrollView', (c) {
    final scId = _scrollControllerIdOf(c.props['controller']);
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

  // SliverList：生成器把 `delegate: SliverChildListDelegate([...])` 的 children
  // 展开为子节点，宿主侧补回 delegate 还原官方写法。
  r.register('SliverList', (c) => SliverList(
        delegate: SliverChildListDelegate(c.children),
      ));

  // SliverGrid：gridDelegate 仅支持 SliverGridDelegateWithFixedCrossAxisCount
  // （crossAxisCount 必填——与 Flutter 一致，缺失会断言；其余缺省 0/1.0 即
  // Flutter 默认）。
  r.register('SliverGrid', (c) => SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: c.int_('crossAxisCount') ?? 1,
          mainAxisSpacing: c.num_('mainAxisSpacing') ?? 0,
          crossAxisSpacing: c.num_('crossAxisSpacing') ?? 0,
          childAspectRatio: c.num_('childAspectRatio') ?? 1,
          mainAxisExtent: c.num_('mainAxisExtent'),
        ),
        delegate: SliverChildListDelegate(c.children),
      ));

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

  // NotificationListener：JS 侧没有 ScrollPosition/controller，滚动监听统一
  // 由宿主抓 ScrollNotification，把 metrics 快照经 invoke 回传 JS 事件方法
  // （payload 形状与 Dart ScrollNotification 一致，JS 里 `n.metrics.pixels`
  // 等属性访问原样可用）。固定 return false，不拦截事件继续冒泡。
  r.register('NotificationListener', (c) => _NotificationListener(
        onNotification: c.props['onNotification'],
        invoke: c.invoke,
        child: c.childOrEmpty,
      ));

  // SingleChildScrollView：controller 是 JS ScrollController 实例的序列化句柄
  // （{__jsuiScrollController: id}）时，返回 _JsScrollControllerView（按 id
  // 绑定真实 controller，滚动经 invoke 回传 metrics 镜像到 JS 实例）；
  // 无 controller → 原样 SingleChildScrollView（存量 JS 兼容）。
  r.register('SingleChildScrollView', (c) {
    final scId = _scrollControllerIdOf(c.props['controller']);
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

  r.register('Container', (c) {
    final deco = boxDecorationFromJson(c.map('decoration'));
    // decoration 为空时 clipBehavior 必须为 Clip.none（Flutter 断言）。
    final clip = deco == null
        ? Clip.none
        : (clipBehaviorFromJson(c.props['clipBehavior']) ?? Clip.none);
    return Container(
      width: c.num_('width'),
      height: c.num_('height'),
      // color 与 decoration 同传会断言：decoration 优先（其内可含 color）。
      color: deco == null ? colorFromJson(c.props['color']) : null,
      decoration: deco,
      padding: edgeInsetsFromJson(c.map('padding')),
      margin: edgeInsetsFromJson(c.map('margin')),
      alignment: alignmentFromJson(c.props['alignment']),
      constraints: boxConstraintsFromJson(c.map('constraints')),
      clipBehavior: clip,
      child: c.child(),
    );
  });

  r.register('Padding', (c) => Padding(
        padding: edgeInsetsFromJson(c.map('padding')),
        child: c.child(),
      ));

  r.register('Center', (c) => Center(child: c.child()));

  r.register('Align', (c) => Align(
        alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
        child: c.child(),
      ));

  r.register('SizedBox', (c) => SizedBox(
        width: c.num_('width'),
        height: c.num_('height'),
        child: c.child(),
      ));

  r.register('Expanded', (c) => Expanded(
        flex: c.int_('flex') ?? 1,
        child: c.childOrEmpty,
      ));

  r.register('Flexible', (c) => Flexible(
        flex: c.int_('flex') ?? 1,
        child: c.childOrEmpty,
      ));

  r.register('Positioned', (c) => Positioned(
        left: c.num_('left'),
        top: c.num_('top'),
        right: c.num_('right'),
        bottom: c.num_('bottom'),
        width: c.num_('width'),
        height: c.num_('height'),
        child: c.childOrEmpty,
      ));

  r.register('ClipRRect', (c) {
    final radius = c.num_('borderRadius');
    return ClipRRect(
      borderRadius:
          radius == null ? BorderRadius.zero : BorderRadius.all(Radius.circular(radius)),
      clipBehavior: clipBehaviorFromJson(c.props['clipBehavior']) ?? Clip.antiAlias,
      child: c.propChild('child'),
    );
  });

  r.register('Card', (c) => Card(
        elevation: c.num_('elevation'),
        margin: edgeInsetsFromJson(c.map('margin')),
        color: colorFromJson(c.props['color']),
        shape: shapeFromJson(c.props['shape']),
        clipBehavior: clipBehaviorFromJson(c.props['clipBehavior']),
        shadowColor: colorFromJson(c.props['shadowColor']),
        child: c.child(),
      ));

  r.register('Icon', (c) => Icon(
        iconFromJson(c.props['icon']),
        size: c.num_('size'),
        color: colorFromJson(c.props['color']),
      ));

  r.register('Image', (c) {
    final source = c.str('source') ?? '';
    final width = c.num_('width');
    final height = c.num_('height');
    final fit = boxFitFromJson(c.props['fit']);
    final color = colorFromJson(c.props['color']);
    final blend = blendModeFromJson(c.props['colorBlendMode']);
    final align = alignmentFromJson(c.props['alignment']) ?? Alignment.center;
    final repeat = imageRepeatFromJson(c.props['repeat']) ?? ImageRepeat.noRepeat;
    return source.startsWith('http')
        ? Image.network(source,
            width: width,
            height: height,
            fit: fit,
            color: color,
            colorBlendMode: blend,
            alignment: align,
            repeat: repeat)
        : Image.asset(source,
            width: width,
            height: height,
            fit: fit,
            color: color,
            colorBlendMode: blend,
            alignment: align,
            repeat: repeat);
  });

  r.register('CircleAvatar', (c) {
    final bgImage = c.str('backgroundImage');
    return CircleAvatar(
      radius: c.num_('radius'),
      minRadius: c.num_('minRadius'),
      maxRadius: c.num_('maxRadius'),
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      foregroundColor: colorFromJson(c.props['foregroundColor']),
      backgroundImage: bgImage == null
          ? null
          : (bgImage.startsWith('http')
              ? NetworkImage(bgImage)
              : AssetImage(bgImage)) as ImageProvider,
      child: c.child(),
    );
  });

  r.register('Divider', (c) => Divider(
        height: c.num_('height'),
        thickness: c.num_('thickness'),
        indent: c.num_('indent'),
        endIndent: c.num_('endIndent'),
        color: colorFromJson(c.props['color']),
      ));

  r.register('Spacer', (c) => Spacer(flex: c.int_('flex') ?? 1));

  r.register('Chip', (c) => Chip(
        label: Text(c.str('label') ?? '',
            style: textStyleFromJson(c.map('labelStyle'))),
        avatar: c.propChild('avatar'),
        deleteIcon: c.propChild('deleteIcon'),
        onDeleted: c.on('onDeleted'),
        backgroundColor: colorFromJson(c.props['backgroundColor']),
        // padding 缺省必须为 null：否则 EdgeInsets.zero 会覆盖 Chip 默认
        // EdgeInsets.all(8.0)，JS 侧每个 chip 窄 16px（8 个 = 128px），
        // 与原生渲染/滚动范围不一致。
        padding: nullableEdgeInsets(c.map('padding')),
        side: borderSideFromJson(c.props['side']),
        shape: shapeFromJson(c.props['shape']),
        elevation: c.num_('elevation'),
      ));

  r.register('ListTile', (c) {
    final title = c.str('title');
    final subtitle = c.str('subtitle');
    return ListTile(
      title: title == null ? null : Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      leading: c.propChild('leading'),
      trailing: c.propChild('trailing'),
      onTap: c.on('event'),
      onLongPress: c.on('onLongPress'),
      tileColor: colorFromJson(c.props['tileColor']),
      iconColor: colorFromJson(c.props['iconColor']),
      textColor: colorFromJson(c.props['textColor']),
      // contentPadding 缺省必须为 null：否则 EdgeInsets.zero 会覆盖主题
      // 默认（水平 16），JS 侧 ListTile 内容贴边。
      contentPadding: nullableEdgeInsets(c.map('contentPadding')),
      dense: c.bool_('dense'),
      shape: shapeFromJson(c.props['shape']),
    );
  });

  r.register('ElevatedButton', (c) => ElevatedButton(
        onPressed: c.on('onPressed'),
        style: buttonStyleFromJson(c.map('style')),
        child: c.childOrEmpty,
      ));

  r.register('TextButton', (c) => TextButton(
        onPressed: c.on('onPressed'),
        style: buttonStyleFromJson(c.map('style')),
        child: c.childOrEmpty,
      ));

  // Button：生成器把 ElevatedButton/TextButton/OutlinedButton 统一译为
  // `{type:'Button', props:{kind, label, event}}`，event 是运行时事件句柄
  // （或 null 表示禁用）→ 点击经宿主把句柄 id 回传 JS 侧执行。
  r.register('Button', (c) {
    final style = buttonStyleFromJson(c.map('style'));
    final label = Text(c.str('label') ?? '');
    final onPressed = c.on('event');
    return switch (c.str('kind')) {
      'text' => TextButton(onPressed: onPressed, style: style, child: label),
      'outlined' =>
        OutlinedButton(onPressed: onPressed, style: style, child: label),
      _ => ElevatedButton(onPressed: onPressed, style: style, child: label),
    };
  });

  r.register('InkWell', (c) {
    final radius = c.num_('borderRadius');
    return InkWell(
      onTap: c.on('event'),
      onLongPress: c.on('onLongPress'),
      onDoubleTap: c.on('onDoubleTap'),
      borderRadius: radius == null ? null : BorderRadius.circular(radius),
      splashColor: colorFromJson(c.props['splashColor']),
      highlightColor: colorFromJson(c.props['highlightColor']),
      child: c.child(),
    );
  });

  r.register(
      'GestureDetector',
      (c) => GestureDetector(
            onTap: c.on('event'),
            onLongPress: c.on('onLongPress'),
            onDoubleTap: c.on('onDoubleTap'),
            behavior: hitTestBehaviorFromJson(c.props['behavior']),
            child: c.child(),
          ));

  r.register('Switch', (c) => Switch(
        value: c.bool_('value') ?? false,
        onChanged: c.onValue<bool?>('event'),
        // 协议键仍叫 activeColor（生成器侧），Flutter 新版改名为 activeThumbColor
        activeThumbColor: colorFromJson(c.props['activeColor']),
        activeTrackColor: colorFromJson(c.props['activeTrackColor']),
        inactiveThumbColor: colorFromJson(c.props['inactiveThumbColor']),
        inactiveTrackColor: colorFromJson(c.props['inactiveTrackColor']),
      ));

  r.register('Checkbox', (c) => Checkbox(
        value: c.bool_('value'),
        tristate: c.bool_('tristate') ?? false,
        onChanged: c.onValue<bool?>('event'),
        activeColor: colorFromJson(c.props['activeColor']),
        checkColor: colorFromJson(c.props['checkColor']),
      ));

  r.register('Slider', (c) => Slider(
        value: c.num_('value') ?? 0,
        min: c.num_('min') ?? 0,
        max: c.num_('max') ?? 1,
        divisions: c.int_('divisions'),
        label: c.str('label'),
        activeColor: colorFromJson(c.props['activeColor']),
        inactiveColor: colorFromJson(c.props['inactiveColor']),
        onChanged: c.onValue<double>('event'),
      ));

  r.register('Scaffold', (c) {
    final appBar = c.childOfType('AppBar');
    return Scaffold(
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      appBar: appBar is AppBar ? appBar : null,
      body: c.hasChildOfType('AppBar') ? c.child(1) : c.child(0),
      floatingActionButton: c.propChild('floatingActionButton'),
      bottomNavigationBar: c.propChild('bottomNavigationBar'),
    );
  });

  // AppBar：title / leading 是「值为 element 的 prop」（propChild），
  // actions 全部进 children（生成器把 actions 追加为子节点）。
  r.register('AppBar', (c) => AppBar(
        leading: c.propChild('leading'),
        title: c.propChild('title'),
        actions: c.children.isEmpty ? null : c.children,
        backgroundColor: colorFromJson(c.props['backgroundColor']),
        foregroundColor: colorFromJson(c.props['foregroundColor']),
        elevation: c.num_('elevation'),
        toolbarHeight: c.num_('toolbarHeight'),
        centerTitle: c.bool_('centerTitle'),
        titleTextStyle: textStyleFromJson(c.map('titleTextStyle')),
      ));

  // ---------------------------------------------------------------------
  // 布局 / 装饰补充
  // ---------------------------------------------------------------------

  r.register('SafeArea', (c) => SafeArea(
        left: c.bool_('left') ?? true,
        top: c.bool_('top') ?? true,
        right: c.bool_('right') ?? true,
        bottom: c.bool_('bottom') ?? true,
        child: c.childOrEmpty,
      ));

  r.register('Opacity', (c) => Opacity(
        opacity: c.num_('opacity') ?? 1,
        child: c.child(),
      ));

  r.register('ConstrainedBox', (c) => ConstrainedBox(
        constraints:
            boxConstraintsFromJson(c.map('constraints')) ?? const BoxConstraints(),
        child: c.childOrEmpty,
      ));

  r.register('AspectRatio', (c) => AspectRatio(
        aspectRatio: c.num_('aspectRatio') ?? 1,
        child: c.child(),
      ));

  r.register('FractionallySizedBox', (c) => FractionallySizedBox(
        widthFactor: c.num_('widthFactor'),
        heightFactor: c.num_('heightFactor'),
        alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
        child: c.child(),
      ));

  r.register('DecoratedBox', (c) => DecoratedBox(
        decoration:
            boxDecorationFromJson(c.map('decoration')) ?? const BoxDecoration(),
        child: c.child(),
      ));

  // ---------------------------------------------------------------------
  // 指示器
  // ---------------------------------------------------------------------

  r.register('CircularProgressIndicator', (c) => CircularProgressIndicator(
        value: c.num_('value'),
        color: colorFromJson(c.props['color']),
        backgroundColor: colorFromJson(c.props['backgroundColor']),
        strokeWidth: c.num_('strokeWidth') ?? 4.0,
      ));

  r.register('LinearProgressIndicator', (c) => LinearProgressIndicator(
        value: c.num_('value'),
        color: colorFromJson(c.props['color']),
        backgroundColor: colorFromJson(c.props['backgroundColor']),
        minHeight: c.num_('minHeight'),
      ));

  // ---------------------------------------------------------------------
  // 输入 / 导航
  // ---------------------------------------------------------------------

  r.register('TextField', (c) => _JsTextField(
        value: c.str('value'),
        onChanged: c.onValue<String>('event'),
        hintText: c.str('hintText'),
        labelText: c.str('labelText'),
        obscureText: c.bool_('obscureText') ?? false,
        enabled: c.bool_('enabled'),
        keyboardType: textInputTypeFromJson(c.props['keyboardType']),
        maxLines: c.int_('maxLines') ?? 1,
        style: textStyleFromJson(c.map('style')),
        textAlign: textAlignFromJson(c.props['textAlign']),
      ));

  r.register('IconButton', (c) => IconButton(
        icon: c.propChild('icon') ?? const Icon(Icons.error_outline),
        onPressed: c.on('event'),
        color: colorFromJson(c.props['color']),
        iconSize: c.num_('iconSize'),
        tooltip: c.str('tooltip'),
      ));

  r.register('FloatingActionButton', (c) => FloatingActionButton(
        // onPressed 缺省必须为 null：Flutter 默认 null = 禁用（灰色不可点）；
        // `() {}` 会变成可点但无动作，与原生语义不一致。
        onPressed: c.on('event'),
        backgroundColor: colorFromJson(c.props['backgroundColor']),
        foregroundColor: colorFromJson(c.props['foregroundColor']),
        mini: c.bool_('mini') ?? false,
        tooltip: c.str('tooltip'),
        elevation: c.num_('elevation'),
        child: c.propChild('child'),
      ));

  r.register('BottomNavigationBar', (c) {
    // BottomNavigationBarItem 非 Widget：从 childContexts 读数据直接组装，
    // c.children 里对应的占位结点不渲染。
    final items = <BottomNavigationBarItem>[];
    for (var i = 0; i < c.childContexts.length; i++) {
      if (c.childTypes[i] != 'BottomNavigationBarItem') continue;
      final item = c.childContexts[i];
      items.add(BottomNavigationBarItem(
        icon: item.propChild('icon') ?? const Icon(Icons.error_outline),
        label: item.str('label'),
      ));
    }
    return BottomNavigationBar(
      items: items,
      currentIndex: c.int_('currentIndex') ?? 0,
      onTap: c.onValue<int>('event'),
      selectedItemColor: colorFromJson(c.props['selectedItemColor']),
      unselectedItemColor: colorFromJson(c.props['unselectedItemColor']),
    );
  });

  // BottomNavigationBarItem 非 Widget（见 BottomNavigationBar renderer，
  // 从 childContexts 组装）；若被单独挂载则退回显示 icon。
  r.register('BottomNavigationBarItem', (c) => _JsBottomNavItem(
        BottomNavigationBarItem(
          icon: c.propChild('icon') ?? const Icon(Icons.error_outline),
          label: c.str('label'),
        ),
      ));

  r.register('Radio', (c) => Radio<dynamic>(
        value: c.props['value'],
        // ignore: deprecated_member_use
        groupValue: c.props['groupValue'],
        // ignore: deprecated_member_use
        onChanged: c.onValue<dynamic>('event'),
        activeColor: colorFromJson(c.props['activeColor']),
      ));

  r.register('DropdownButton', (c) {
    // DropdownMenuItem 同上：从 childContexts 读 value/label 组装。
    final items = <DropdownMenuItem<dynamic>>[];
    for (var i = 0; i < c.childContexts.length; i++) {
      if (c.childTypes[i] != 'DropdownMenuItem') continue;
      final item = c.childContexts[i];
      items.add(DropdownMenuItem<dynamic>(
        value: item.props['value'],
        child: Text(item.str('label') ?? ''),
      ));
    }
    final hint = c.str('hint');
    return DropdownButton<dynamic>(
      value: c.props['value'],
      items: items,
      onChanged: c.onValue<dynamic>('event'),
      hint: hint == null ? null : Text(hint),
      isExpanded: c.bool_('isExpanded') ?? false,
    );
  });

  r.register('DropdownMenuItem', (c) => DropdownMenuItem<dynamic>(
        value: c.props['value'],
        child: Text(c.str('label') ?? ''),
      ));

  // Component：无 JS 产物的组件节点（无注解的 lib 普通 widget /
  // @UIComponentIgnore）→ 宿主 nativeComponents 原生注入；未注册给可见占位。
  r.register('Component', (c) {
    final name = c.str('component') ?? '';
    final native = c.nativeComponents[name];
    if (native != null) return native(c.map('args') ?? const {});
    return buildMissingJsWidget(name, c.children);
  });
}

/// NotificationListener 桥接组件（对应注册 key 'NotificationListener'）：
/// 宿主侧监听子树里的滚动通知，把 metrics 快照回传 JS。
///
/// JS 侧写法：
/// ```js
/// NotificationListener({ onNotification: this.__bind("_onScroll") }, [ ... ])
/// ```
/// 滚动时宿主经 invoke 回传 `{type, metrics:{pixels, maxScrollExtent,
/// extentAfter, viewportDimension, axisDirection}}`，JS 事件方法形参（如 n）
/// 直接收下，`n.metrics.pixels` 等属性访问与 Dart 侧源码一比一可用。
class _NotificationListener extends StatefulWidget {
  const _NotificationListener({
    required this.onNotification,
    required this.invoke,
    required this.child,
  });

  /// JS 侧事件句柄（`{'__fn': id}`）。
  final Object? onNotification;

  /// 宿主 → JS 事件回传（js_ui_widget.dart 的 _invoke）。
  final void Function(Object? handler, [Object? payload]) invoke;

  final Widget child;

  @override
  State<_NotificationListener> createState() => _NotificationListenerState();
}

class _NotificationListenerState extends State<_NotificationListener> {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        final handler = widget.onNotification;
        if (handler != null) {
          // payload 形状对齐 Dart ScrollNotification（metrics 对象 + type 名），
          // JS 事件方法体里的 `n.metrics.pixels` / `n.metrics.extentAfter`
          // 由生成器原样翻译后可直接读取。
          widget.invoke(handler, {
            'type': n.runtimeType.toString(),
            'metrics': {
              'pixels': n.metrics.pixels,
              'maxScrollExtent': n.metrics.maxScrollExtent,
              'extentAfter': n.metrics.extentAfter,
              'viewportDimension': n.metrics.viewportDimension,
              'axisDirection': n.metrics.axisDirection.name,
            },
          });
        }
        // 不拦截：返回 false 让通知继续向上冒泡，外部其它监听不受影响。
        return false;
      },
      child: widget.child,
    );
  }
}

/// ScrollController 桥接的通用包装器：任何 ScrollView 子类
/// （SingleChildScrollView / ListView / 后续的 CustomScrollView）把各自的
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
  final void Function(Object? handler, [Object? payload]) invoke;

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
    widget.invoke(handler, {
      'pixels': _controller.offset,
      'maxScrollExtent': _controller.position.maxScrollExtent,
      'viewportDimension': _controller.position.viewportDimension,
      'extentAfter': _controller.position.extentAfter,
    });
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

/// TextField 受控封装：JS 侧只下发 value 字符串与 onChanged 句柄，
/// controller 由宿主持有并在 props.value 变化时同步（光标移到末尾）。
class _JsTextField extends StatefulWidget {
  const _JsTextField({
    required this.value,
    required this.onChanged,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.enabled,
    this.keyboardType,
    this.maxLines = 1,
    this.style,
    this.textAlign,
  });

  final String? value;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final bool? enabled;
  final TextInputType? keyboardType;
  final int? maxLines;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<_JsTextField> createState() => _JsTextFieldState();
}

class _JsTextFieldState extends State<_JsTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(_JsTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 仅受控模式（value 非空）同步 controller；value 为 null 时是非受控，
    // 重建不回写，避免清空用户输入。
    final v = widget.value;
    if (v != null && v != _controller.text) {
      _controller.value = TextEditingValue(
        text: v,
        selection: TextSelection.collapsed(offset: v.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      // obscureText 时 Flutter 要求 maxLines == 1
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      style: widget.style,
      textAlign: widget.textAlign ?? TextAlign.start,
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
      ),
    );
  }
}

/// BottomNavigationBarItem 不是 Widget：宿主侧用它包装 item 数据，
/// 由 BottomNavigationBar renderer 收集还原为 items 列表。
class _JsBottomNavItem extends StatelessWidget {
  const _JsBottomNavItem(this.item);

  final BottomNavigationBarItem item;

  @override
  Widget build(BuildContext context) => item.icon;
}

/// 迁移中的 JS 组件引用了宿主未注册的类型时，给出可见占位。
Widget buildMissingJsWidget(String type, List<Widget> children) {
  HotPatchLog.log('js_ui: 未注册的宿主 widget 类型 "$type"');
  return Container(
    padding: const EdgeInsets.all(4),
    color: const Color(0x22FF0000),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('<未注册 widget: $type>', style: const TextStyle(fontSize: 11, color: Color(0xFFB00020))),
        ...children,
      ],
    ),
  );
}
