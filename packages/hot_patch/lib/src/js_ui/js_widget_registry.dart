import 'package:flutter/material.dart';

import '../json/flutter_from_json.dart';
import '../utils/hot_patch_log.dart';

/// 不需要动宿主；只有引入 Flutter 侧不存在的**视觉** widget 才注册一条。
class JsRenderContext {
  JsRenderContext({
    required this.type,
    required this.props,
    required this.children,
    required this.childTypes,
    required this.childContexts,
    required this.propChildren,
    required this.invoke,
  });

  /// 本结点的元素 type（宿主 widget 类型名 / 未注册组件的具体类型名）。
  /// 供默认 builder 识别「这是哪个未注册组件」，按名走原生注入或占位。
  final String type;

  final Map<String, dynamic> props;
  final List<Widget> children;

  /// 与 [children] 一一对应的宿主 type（用于 Scaffold 这类需要按类型
  /// 区分插槽的容器；JS 只能下发 element，无法在 props 里塞 widget）。
  final List<String> childTypes;

  /// 与 [children] 一一对应的子结点数据（type/props/propChildren），
  /// 用于 BottomNavigationBarItem / DropdownMenuItem 这类「非 Widget
  /// 数据载体」子结点——父 renderer 直接读数据组装，不走 widget 包装。
  final List<JsRenderContext> childContexts;

  /// 值为 element 的 props（如 ListTile.leading / ClipRRect.child）：
  /// prop 名 -> 已构建好的子 widget。
  final Map<String, Widget> propChildren;

  /// 把事件句柄（`{'__fn': id}`）回传到 JS 侧执行。
  final void Function(Object? handler, [List<Object?> args]) invoke;

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
  ///
  /// 事件回传统一按**参数数组**下发，`on`/`on1`…`on4` 只是按回调形参个数
  /// 糖化：`on` = 0 参（onTap/onPressed），`on1` = 1 参（onChanged…），
  /// `on2`/`on3`/`on4` = 2/3/4 参（onReorder、onPopInvokedWithResult…）。
  /// 每个 renderer 按事件真实签名选对应糖即可，JS 侧 __bind/__bindFn 无需改动。
  VoidCallback? on(String key) {
    final handler = props[key];
    if (handler == null) {
      // 事件键缺失 → onTap 为 null，点了必然没反应。
      return null;
    }
    return () => invoke(handler, const []);
  }

  /// 值为句柄的 prop → 带 1 个参数的回调（Switch/Checkbox/Slider 的 onChanged）。
  ValueChanged<T>? on1<T>(String key) {
    final handler = props[key];
    if (handler == null) return null;
    return (v) => invoke(handler, [v]);
  }

  /// 带 2 个参数的回调（如 ReorderableListView.onReorder、onPopInvokedWithResult）。
  void Function(A, B)? on2<A, B>(String key) {
    final handler = props[key];
    if (handler == null) return null;
    return (a, b) => invoke(handler, [a, b]);
  }

  /// 带 3 个参数的回调。
  void Function(A, B, C)? on3<A, B, C>(String key) {
    final handler = props[key];
    if (handler == null) return null;
    return (a, b, c) => invoke(handler, [a, b, c]);
  }

  /// 带 4 个参数的回调。
  void Function(A, B, C, D)? on4<A, B, C, D>(String key) {
    final handler = props[key];
    if (handler == null) return null;
    return (a, b, c, d) => invoke(handler, [a, b, c, d]);
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

// ===== 全局原生组件注入表 =====

/// 「无 JS 产物组件」（产物里的 `Component` 结点）的原生实现：组件名 → 构造。
///
/// **进程内全局一份**：同一 App 的所有 `JsUiWidget` 实例、所有 `Component`
/// 结点共用同一张表，不再随 widget 参数逐层透传。运行时（hot_patch 包）不
/// import 任何业务类，实现由业务方在 `main()` 里注册（与 [registerHostMethods]
/// 同一个位置，须在 `runApp` 之前）。
final Map<String, Widget Function(Map<String, dynamic> args)> _nativeComponents =
    {};

/// 注册一个「无 JS 产物组件」的原生实现（如生成器对 `@PatchIgnore` /
/// 无注解私有组件产出的「保留具体类型名」结点）。
///
/// **重复注册**：后注册覆盖先注册（Map 语义，幂等、不抛错）——同一实现在
/// 多处重复注册无副作用；但两个**不同实现**注册同一名字会静默覆盖，故这里
/// 在覆盖时打一条日志。约定：注册只在启动时做一次，不要在 `build()` 里调。
void registerNativeComponent(
  String name,
  Widget Function(Map<String, dynamic> args) build,
) {
  if (_nativeComponents.containsKey(name)) {
    HotPatchLog.warn('js_ui: 原生组件 "$name" 重复注册，后者覆盖前者');
  }
  _nativeComponents[name] = build;
}

typedef JsWidgetBuilder = Widget Function(JsRenderContext c);

/// 未注册类型元素的**默认 builder**（[JsWidgetRegistry] 的兜底）：
/// 按元素 type（= 具体组件名）查全局原生注入实现，命中则由其渲染；
/// 否则给出可见占位（便于定位缺失的翻译/注入）。
///
/// 产物里的元素 type 始终是「具体类型名」，故这里不需要任何「Component」
/// 哨兵类型——「未注册」只表现为 [JsWidgetRegistry.lookup] 未命中。
Widget _unknownWidgetBuilder(JsRenderContext c) {
  final native = _nativeComponents[c.type];
  if (native != null) return native(c.props);
  return buildMissingJsWidget(c.type, c.children);
}


/// `type -> Flutter widget` 注册表（宿主唯一扩展点）。
class JsWidgetRegistry {
  final Map<String, JsWidgetBuilder> _builders = {};

  /// lookup 未命中时的默认 builder（未注册组件的兜底）。
  ///
  /// 关键设计：**产物里的元素 type 永远是「具体类型名」**（生成器不再把不认识
  /// 的组件降级成统一的 'Component' 占位）。因此「某个类型没注册」只表现为
  /// [lookup] 返回 null —— 走本默认 builder：宿主按类型名找 `registerNativeComponent`
  /// 注入的原生实现，找不到再给可见占位。这样之后补上该类型的宿主 builder
  /// （或生成器 translator）时，**同一份产物无需重新生成、协议不变**。
  JsWidgetBuilder? _fallback = _unknownWidgetBuilder;

  void register(String type, JsWidgetBuilder builder) => _builders[type] = builder;

  /// 设置 lookup 未命中时的默认 builder（见 [_fallback]）。
  void registerFallback(JsWidgetBuilder builder) => _fallback = builder;

  JsWidgetBuilder? get fallback => _fallback;

  bool has(String type) => _builders.containsKey(type);

  JsWidgetBuilder? lookup(String type) => _builders[type];
}

/// 注册内置的宿主 widget 翻译。
///
/// 只覆盖「JS 侧组件用到的、Flutter 侧真实存在的」类型；未注册的类型渲染为
/// 错误占位（便于定位缺失的翻译），而不是静默空白。
///
/// 除基础视觉组件外的 widget 分两处：
///   - 各能力/三方库的组件（provider 三件套、TextField、ListView、TabBar、
///     NotificationListener …）**不在此注册**——由各自的 JsUiLibrary 子类注册
///     （见 capabilities/<能力>/<能力>_library.dart）；本核心文件不 import 它们；
///   - Builder **不在这里**：它是无状态委托，纯 JS 逻辑，宿主零感知。
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

  r.register('IndexedStack', (c) => IndexedStack(
        // index 是状态字段（`this._index`），切换后只重下发 props、子结点原位复用，
        // 因此各 tab 页的状态（滚动位置、输入内容）都能保留。
        index: c.int_('index') ?? 0,
        alignment: alignmentFromJson(c.props['alignment']) ??
            AlignmentDirectional.topStart,
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

  r.register('ClipOval', (c) => ClipOval(
        clipBehavior: clipBehaviorFromJson(c.props['clipBehavior']) ?? Clip.antiAlias,
        child: c.propChild('child'),
      ));

  r.register('Material', (c) => Material(
        color: colorFromJson(c.props['color']),
        elevation: c.num_('elevation') ?? 0,
        child: c.propChild('child'),
      ));

  // Transform.translate：位移（props.offset = {dx, dy}）+ child。
  r.register('Transform', (c) {
    final offset = c.map('offset') ?? const <String, dynamic>{};
    final dx = (offset['dx'] as num?)?.toDouble() ?? 0;
    final dy = (offset['dy'] as num?)?.toDouble() ?? 0;
    return Transform.translate(
      offset: Offset(dx, dy),
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

  // Button：生成器把 ElevatedButton/FilledButton/TextButton/OutlinedButton
  // 统一译为 `{type:'Button', props:{kind, label, event}}`，event 是运行时事件
  // 句柄（或 null 表示禁用）→ 点击经宿主把句柄 id 回传 JS 侧执行。
  r.register('Button', (c) {
    final style = buttonStyleFromJson(c.map('style'));
    final label = Text(c.str('label') ?? '');
    final onPressed = c.on('event');
    return switch (c.str('kind')) {
      'text' => TextButton(onPressed: onPressed, style: style, child: label),
      'outlined' =>
        OutlinedButton(onPressed: onPressed, style: style, child: label),
      'filled' => FilledButton(onPressed: onPressed, style: style, child: label),
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
        onChanged: c.on1<bool?>('event'),
        // 协议键仍叫 activeColor（生成器侧），Flutter 新版改名为 activeThumbColor
        activeThumbColor: colorFromJson(c.props['activeColor']),
        activeTrackColor: colorFromJson(c.props['activeTrackColor']),
        inactiveThumbColor: colorFromJson(c.props['inactiveThumbColor']),
        inactiveTrackColor: colorFromJson(c.props['inactiveTrackColor']),
      ));

  r.register('Checkbox', (c) => Checkbox(
        value: c.bool_('value'),
        tristate: c.bool_('tristate') ?? false,
        onChanged: c.on1<bool?>('event'),
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
        onChanged: c.on1<double>('event'),
      ));

  // Scaffold：appBar / body / floatingActionButton / bottomNavigationBar
  // 都是「值为 element 的 prop」（生成器把命名参数翻译进 props，产物
  // `Scaffold({appBar: AppBar({...}), body: Column({...})})`）——宿主
  // propChild 直取，不依赖 children 顺序/类型判断。appBar 经
  // _JsAppBarAdaptor 适配 PreferredSizeWidget（JS 节点是 JsUiWidget 包装，
  // 非原生 AppBar 实例）。
  r.register('Scaffold', (c) {
    final appBar = c.propChild('appBar');
    return Scaffold(
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      appBar: appBar == null ? null : _JsAppBarAdaptor(appBar),
      body: c.propChild('body'),
      floatingActionButton: c.propChild('floatingActionButton'),
      bottomNavigationBar: c.propChild('bottomNavigationBar'),
      // drawer / endDrawer 接进真实 Scaffold：AppBar 自动出现汉堡按钮，
      // 开启原生可用；关闭走 capabilities/drawer/drawer_bridge.dart 的抽屉作用域。
      drawer: c.propChild('drawer'),
      endDrawer: c.propChild('endDrawer'),
      drawerScrimColor: colorFromJson(c.props['drawerScrimColor']),
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
      onTap: c.on1<int>('event'),
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
        onChanged: c.on1<dynamic>('event'),
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
      onChanged: c.on1<dynamic>('event'),
      hint: hint == null ? null : Text(hint),
      isExpanded: c.bool_('isExpanded') ?? false,
    );
  });

  r.register('DropdownMenuItem', (c) => DropdownMenuItem<dynamic>(
        value: c.props['value'],
        child: Text(c.str('label') ?? ''),
      ));

  // 未注册类型不在**这里**注册：产物里的元素 type 始终是「具体类型名」，未命中
  // lookup 时统一走 registry 的默认 builder（见 [JsWidgetRegistry._fallback] /
  // `_unknownWidgetBuilder`）——按类型名找原生注入实现或占位。
}

/// AppBar 插槽适配器：把 JS 节点（JsUiWidget 包装）适配为
/// PreferredSizeWidget 交给 Scaffold.appBar。preferredSize 取 AppBar 默认
/// 高度 kToolbarHeight（demo 内 AppBar 均为默认 toolbarHeight）。
class _JsAppBarAdaptor extends StatelessWidget implements PreferredSizeWidget {
  const _JsAppBarAdaptor(this.child);

  final Widget child;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => child;
}

/// BottomNavigationBarItem 不是 Widget：宿主侧用它包装 item 数据，
/// 由 BottomNavigationBar renderer 收集还原为 items 列表。
class _JsBottomNavItem extends StatelessWidget {
  const _JsBottomNavItem(this.item);

  final BottomNavigationBarItem item;

  @override
  Widget build(BuildContext context) => item.icon;
}

/// 元素 type 未注册（既无宿主 builder、也无原生注入实现）时，给出可见占位。
Widget buildMissingJsWidget(String type, List<Widget> children) {
  HotPatchLog.error('js_ui: 未注册的宿主 widget 类型 "$type"');
  return Container(
    padding: const EdgeInsets.all(4),
    color: const Color(0x22FF0000),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('<missing widget: $type>', style: const TextStyle(fontSize: 11, color: Color(0xFFB00020))),
        ...children,
      ],
    ),
  );
}
