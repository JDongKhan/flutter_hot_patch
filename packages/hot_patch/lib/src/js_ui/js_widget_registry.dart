import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../services/js_runtime_manager.dart';
import '../utils/hot_patch_log.dart';
import 'capabilities/base_widget/button_from_json.dart';
import 'capabilities/base_widget/icon_from_json.dart';
import 'capabilities/base_widget/text_from_json.dart';
import 'capabilities/core/from_json/dart_values_from_json.dart';
import 'capabilities/core/from_json/layout_from_json.dart';
import 'capabilities/core/from_json/painting_from_json.dart';
import 'capabilities/core/from_json/widget_enum_from_json.dart';
import 'capabilities/js_ui_capabilities.dart';

/// 非 Widget 数据载体类型：它们在产物里也是 element 形态，但宿主 renderer
/// 只读数据（type/props/children）组装，不能当 Widget 挂载。
///
/// 这是一张**可注册表**：内置类型在此登记；业务 / 三方自定义的条目类型
/// （自定义导航项、下拉项、装饰配置等）在 `runApp` 前调用
/// [registerJsDataCarrierType] 登记即可，无需改框架源码。与
/// [registerNativeComponent] 同属「类型 → 消费方式」的公开扩展点。
final Set<String> _dataCarrierTypes = <String>{
  'BottomNavigationBarItem',
  'DropdownMenuItem',
  // InputDecoration 是值对象（不是 Widget），TextField renderer 只读它的
  // hintText / labelText 等 props。
  'InputDecoration',
};

/// 登记一个「非 Widget 数据载体」类型。
///
/// 数据载体与 Widget 的区别只在**消费方式**：同为 element 描述，Widget 由
/// 宿主挂载成子树，数据载体直接以 [JsRenderContext] 交给父 renderer 读字段。
/// 幂等，重复登记无副作用。
void registerJsDataCarrierType(String type) => _dataCarrierTypes.add(type);

/// 该类型是否登记为非 Widget 数据载体（类型表驱动，不做类型名硬编码判断）。
bool isJsDataCarrierType(String type) => _dataCarrierTypes.contains(type);

/// 宿主 → JS 事件回传（按钮点击、懒槽位挂载/卸载、LayoutBuilder 的 builder
/// 回调等所有「宿主调 JS 句柄」的唯一出口）。
///
/// handler 是运行时登记的句柄 `{'__fn': id}`（生成器在构建期把事件表达式绑到
/// 产出该结点的组件实例，绑定信息随 props 传下来）。
///
/// [args] 是**参数数组**：0 参事件 `[]`、onChanged `[v]`、多参事件 `[a,b]`…；
/// JS 侧句柄（__bindFn 生成的 wrapper）对它 apply 摊开成位置实参，故任意形参
/// 个数的事件共用同一条通路。
///
/// 放在顶层（而不是挂在每个结点的 State 上传参）的原因：能力实现（各 bridge
/// 的 renderer）与 [_JsNode] 的生命周期回调都只需要「一个 id + 一组参数」，
/// 传 `invoke` 闭包只会让每层构造多一个与语义无关的参数。
void invokeJsHandler(Object? handler, [List<Object?> args = const []]) {
  if (handler is! Map) {
    // handler 形态不对 → 静默丢弃，点了没反应。
    return;
  }
  final id = handler['__fn'];
  if (id is! String) {
    // 句柄缺 __fn → 静默丢弃。
    return;
  }
  // args 双重编码：内层把数组变成 JSON 文本，外层再包成 JS 字符串字面量；
  // JS 侧 invoke 对字符串参数做一次 JSON.parse 还原为数组。单层编码会把
  // 字符串 payload 解析失败置 null。
  JsRuntimeManager.instance.evaluate(
    '__jsui.invoke(${jsonEncode(id)}, ${jsonEncode(jsonEncode(args))});',
  );
}

/// 不需要动宿主；只有引入 Flutter 侧不存在的**视觉** widget 才注册一条。
class JsRenderContext {
  JsRenderContext({
    required this.type,
    required this.props,
    required this.children,
  });

  /// 本结点的元素 type（宿主 widget 类型名 / 未注册组件的具体类型名）。
  /// 供默认 builder 识别「这是哪个未注册组件」，按名走原生注入或占位。
  final String type;

  /// 普通值 props（不含 widget：widget 已在 `children` 里）。
  final Map<String, dynamic> props;

  /// 按 **Dart 实参原名** 索引的 slot，框架不认任何固定字段名：
  ///   - 单个 widget → `Widget`
  ///   - widget 数组 → `List<Widget>`
  ///   - 数据载体数组（`BottomNavigationBarItem` 等）→ `List<JsRenderContext>`
  ///   - delegate → `Map`（`{__delegate: 'list' | 'builder', …}`）
  ///   - `__items`（builder 展开结果）→ `List<Widget>`
  ///
  /// 取值方直接 `c.children['body'] as Widget?` /
  /// `c.children['children'] as List<Widget>?`，key 由 renderer 自己决定。
  final Map<String, Object?> children;

  /// 把事件句柄（`{'__fn': id}`）回传到 JS 侧执行。
  void invoke(Object? handler, [List<Object?> args = const []]) =>
      invokeJsHandler(handler, args);

  /// 把 props 上的事件字段（句柄）绑成 Flutter 回调；无句柄（null）时为 null。
  ///
  /// 事件回传统一按**参数数组**下发，`on`/`on1`…`on4` 只是按回调形参个数
  /// 糖化：`on` = 0 参（onTap/onPressed），`on1` = 1 参（onChanged…），
  /// `on2`/`on3`/`on4` = 2/3/4 参（onReorder、onPopInvokedWithResult…）。
  /// 每个 renderer 按事件真实签名选对应糖即可，JS 侧 __bindFn 无需改动。
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

  /// props 里的值可能是**元素描述的具名实参**（`{type, props, children}`）。
  /// 生成器把 `ButtonStyle(...)`/`InputDecoration(...)` 这类「构造形态的值」
  /// 也译成了元素结点，此处取它的内层 props。
  Map<String, dynamic>? elementProps(Object? raw) {
    if (raw is! Map) return null;
    final inner = raw['props'];
    if (raw['type'] != null && inner is Map) {
      return inner.cast<String, dynamic>();
    }
    return raw.cast<String, dynamic>();
  }

  /// 样式 map：值可能是 JSON map（`TextStyle(...)`），也可能是元素结点
  /// （`ElevatedButton.styleFrom(...)` 被当成构造 → `{type, props}`）——后者取内层 props。
  Map<String, dynamic>? styleMap(String key) => elementProps(props[key]);

  /// 单个元素描述（props 里值为 element 的键，或数组里的一项）→ widget。
  Widget? element(Object? raw) => buildJsElement(raw);

  /// 元素描述数组（`AppBar.actions` / `BottomNavigationBar.items` /
  /// `MultiProvider.providers` 等）→ widget 列表（空项跳过）。
  List<Widget> elementList(Object? raw) {
    if (raw is! List) return const [];
    final out = <Widget>[];
    for (final e in raw) {
      final w = buildJsElement(e);
      if (w != null) out.add(w);
    }
    return out;
  }
}

/// 把产物里的**元素描述**（`{type, props, children, element}`）渲染成 widget。
///
/// 用途：`__items`（builder 展开结果）/ 数据载体上下文等需要宿主自行递归渲染
/// 的场景；具名 slot 已由 JS 侧挂载，宿主直接走 `propChild` / `propChildList`。
Widget? buildJsElement(Object? raw) {
  if (raw is! Map) return null;
  final type = raw['type'];
  if (type is! String || type.isEmpty) return null;
  final props = raw['props'] is Map
      ? (raw['props'] as Map).cast<String, dynamic>()
      : <String, dynamic>{};
  final children = _childrenFromSlots(raw['children']);

  final builder = jsWidgetRegistry.lookup(type) ?? jsWidgetRegistry.fallback;
  if (builder == null) {
    return buildMissingJsWidget(
      type,
      (children['__items'] as List<Widget>?) ?? const [],
    );
  }
  return builder(
    JsRenderContext(
      type: type,
      props: props,
      children: children,
    ),
  );
}

/// 解析元素 `children` 槽位协议 → 按 Dart 实参原名索引的槽位表。
///
/// 协议唯一（由产物里的 `__h` 产出）：
///   - `__items`：builder 代理类展开结果（有序子结点）；
///   - 数组：widget / 数据载体列表；
///   - `{__delegate: 'list' | 'builder', …}`：delegate 描述；
///   - `{element: true}`：单个 widget / 数据载体。
///
/// 不支持旧形状（children 是裸数组、元素混在 props 里）——产物以最新协议为准，
/// 形状不合法时宁可丢 slot 也不猜。
Map<String, Object?> _childrenFromSlots(Object? rawSlots) {
  final children = <String, Object?>{};
  if (rawSlots is! Map) return children;

  void addList(String key, Object? value) {
    final widgets = <Widget>[];
    final contexts = <JsRenderContext>[];
    var dataCarrier = false;
    if (value is List) {
      for (final ch in value) {
        final w = buildJsElement(ch);
        if (w != null) widgets.add(w);
        final ctx = _descriptorContext(ch);
        contexts.add(ctx);
        if (isJsDataCarrierType(ctx.type)) dataCarrier = true;
      }
    }
    children[key] = dataCarrier ? contexts : widgets;
  }

  for (final entry in rawSlots.entries) {
    final key = '${entry.key}';
    final v = entry.value;
    if (key == '__items' && v is List) {
      children['__items'] = [
        for (final ch in v) buildJsElement(ch) ?? const SizedBox.shrink(),
      ];
      continue;
    }
    if (v is List) {
      addList(key, v);
      continue;
    }
    if (v is Map && v['__delegate'] != null) {
      if (v['__delegate'] == 'list') {
        addList(key, v['children']);
      } else {
        children[key] = v;
      }
      continue;
    }
    if (v is Map && v['element'] == true) {
      final ctx = _descriptorContext(v);
      children[key] = isJsDataCarrierType(ctx.type)
          ? ctx
          : buildJsElement(v);
    }
  }
  return children;
}

/// 元素描述 → 仅含数据（type/props/children）的上下文：供
/// `BottomNavigationBarItem` / `DropdownMenuItem` 这类**非 Widget 数据载体**
/// 子结点由父 renderer 直接读数据组装。
JsRenderContext _descriptorContext(Object? raw) {
  final props = raw is Map && raw['props'] is Map
      ? (raw['props'] as Map).cast<String, dynamic>()
      : <String, dynamic>{};
  return JsRenderContext(
    type: raw is Map ? '${raw['type']}' : '',
    props: props,
    children: _childrenFromSlots(raw is Map ? raw['children'] : null),
  );
}

/// `MaterialType` 枚举名 → 枚举值（缺省 null = Flutter 默认 `canvas`）。
MaterialType? _materialTypeFromJson(Object? v) => switch ('$v') {
  'canvas' => MaterialType.canvas,
  'card' => MaterialType.card,
  'circle' => MaterialType.circle,
  'button' => MaterialType.button,
  'transparency' => MaterialType.transparency,
  _ => null,
};

/// 源字符串 → 图片 provider：`FadeInImage.assetNetwork` 的 placeholder 永远是
/// 资源路径（[forceAsset]），其余按 `http` 前缀判网络 / 资源（与 `Image` 一致）。
ImageProvider _imageProvider(String source, {bool forceAsset = false}) =>
    (!forceAsset && source.startsWith('http')) ? NetworkImage(source) : AssetImage(source);

// ===== 全局原生组件注入表 =====

/// 「无 JS 产物组件」（产物里保留具体类型名、无 JS 类的结点）的原生实现。
///
/// 回调收到完整的 [JsRenderContext]：`props` 是普通属性，`children` 是按
/// Dart 实参原名索引的子树 slot（`child` / `children` / `actions` …），
/// `invoke` 可把事件句柄回传到 JS。因此原生注入实现可以像正常 Flutter
/// 组件一样渲染子组件，不再只有 props。
///
/// **进程内全局一份**：同一 App 的所有 `JsUiWidget` 实例、所有「无 JS 产物」
/// 结点共用同一张表，不再随 widget 参数逐层透传。运行时（hot_patch 包）不
/// import 任何业务类，实现由业务方在 `main()` 里注册（与 [registerHostMethods]
/// 同一个位置，须在 `runApp` 之前）。
final Map<String, JsWidgetBuilder> _nativeComponents = {};

/// 注册一个「无 JS 产物组件」的原生实现（如生成器对 `@PatchIgnore` /
/// 无注解私有组件产出的「保留具体类型名」结点）。
///
/// 回调参数是 [JsRenderContext]：`c.props` / `c.children` / `c.invoke`。
/// 例如：
/// ```dart
/// registerNativeComponent('_LabeledDivider', (c) => LabeledDivider(
///   text: c.str('text') ?? '',
///   child: c.children['child'] as Widget?,
/// ));
/// ```
///
/// **重复注册**：后注册覆盖先注册（Map 语义，幂等、不抛错）——同一实现在
/// 多处重复注册无副作用；但两个**不同实现**注册同一名字会静默覆盖，故这里
/// 在覆盖时打一条日志。约定：注册只在启动时做一次，不要在 `build()` 里调。
void registerNativeComponent(String name, JsWidgetBuilder build) {
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
  if (native != null) return native(c);
  return buildMissingJsWidget(c.type, ((c.children['__items'] as List<Widget>?) ?? const []));
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
  /// 或原生实现时，**同一份产物无需重新生成、协议不变**。
  JsWidgetBuilder? _fallback = _unknownWidgetBuilder;

  void register(String type, JsWidgetBuilder builder) =>
      _builders[type] = builder;

  /// 设置 lookup 未命中时的默认 builder（见 [_fallback]）。
  void registerFallback(JsWidgetBuilder builder) => _fallback = builder;

  JsWidgetBuilder? get fallback => _fallback;

  bool has(String type) => lookup(type) != null;

  /// 产物里的 type 可能带泛型实参（`ChangeNotifierProvider<NetworkVm>`）——
  /// 按**基础类型名**查表（`<...>` 之前的段）。
  JsWidgetBuilder? lookup(String type) =>
      _builders[type] ?? _builders[_baseType(type)];

  static String _baseType(String type) {
    final i = type.indexOf('<');
    return i < 0 ? type : type.substring(0, i);
  }
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
  r.register(
    'Text',
    (c) => Text(
      // `data` 是 Flutter `Text` 的首个位置形参名（`Text('你好')`）。
      c.str('data') ?? '',
      style: textStyleFromJson(c.map('style')),
      textAlign: textAlignFromJson(c.props['textAlign']),
      overflow: overflowFromJson(c.props['overflow']),
      maxLines: c.int_('maxLines'),
      softWrap: c.bool_('softWrap'),
      textDirection: textDirectionFromJson(c.props['textDirection']),
      textScaler: textScalerFromJson(c.props['textScaler']),
      semanticsLabel: c.str('semanticsLabel'),
    ),
  );

  r.register(
    'RichText',
    (c) => RichText(
      text: textSpanFromJson(c.props['text']) ?? const TextSpan(),
      textAlign: textAlignFromJson(c.props['textAlign']) ?? TextAlign.start,
      textDirection: textDirectionFromJson(c.props['textDirection']),
      softWrap: c.bool_('softWrap') ?? true,
      overflow: overflowFromJson(c.props['overflow']) ?? TextOverflow.clip,
      maxLines: c.int_('maxLines'),
      textScaler: textScalerFromJson(c.props['textScaler']) ??
          TextScaler.noScaling,
      selectionColor: colorFromJson(c.props['selectionColor']),
    ),
  );

  r.register(
    'Column',
    (c) => Column(
      mainAxisAlignment:
          mainAxisAlignmentFromJson(c.props['mainAxisAlignment']) ??
          MainAxisAlignment.start,
      crossAxisAlignment:
          crossAxisAlignmentFromJson(c.props['crossAxisAlignment']) ??
          CrossAxisAlignment.center,
      mainAxisSize:
          mainAxisSizeFromJson(c.props['mainAxisSize']) ?? MainAxisSize.max,
      children: ((c.children['children'] as List<Widget>?) ?? const []),
    ),
  );

  r.register(
    'Row',
    (c) => Row(
      mainAxisAlignment:
          mainAxisAlignmentFromJson(c.props['mainAxisAlignment']) ??
          MainAxisAlignment.start,
      crossAxisAlignment:
          crossAxisAlignmentFromJson(c.props['crossAxisAlignment']) ??
          CrossAxisAlignment.center,
      mainAxisSize:
          mainAxisSizeFromJson(c.props['mainAxisSize']) ?? MainAxisSize.max,
      children: ((c.children['children'] as List<Widget>?) ?? const []),
    ),
  );

  r.register(
    'Stack',
    (c) => Stack(
      alignment:
          alignmentFromJson(c.props['alignment']) ??
          AlignmentDirectional.topStart,
      fit: stackFitFromJson(c.props['fit']) ?? StackFit.loose,
      clipBehavior:
          clipBehaviorFromJson(c.props['clipBehavior']) ?? Clip.hardEdge,
      children: ((c.children['children'] as List<Widget>?) ?? const []),
    ),
  );

  r.register(
    'IndexedStack',
    (c) => IndexedStack(
      // index 是状态字段（`this._index`），切换后只重下发 props、子结点原位复用，
      // 因此各 tab 页的状态（滚动位置、输入内容）都能保留。
      index: c.int_('index') ?? 0,
      alignment:
          alignmentFromJson(c.props['alignment']) ??
          AlignmentDirectional.topStart,
      children: ((c.children['children'] as List<Widget>?) ?? const []),
    ),
  );

  r.register(
    'Wrap',
    (c) => Wrap(
      direction: axisFromJson(c.props['direction']) ?? Axis.horizontal,
      spacing: c.num_('spacing') ?? 0,
      runSpacing: c.num_('runSpacing') ?? 0,
      alignment:
          wrapAlignmentFromJson(c.props['alignment']) ?? WrapAlignment.start,
      runAlignment:
          wrapAlignmentFromJson(c.props['runAlignment']) ?? WrapAlignment.start,
      crossAxisAlignment:
          wrapCrossAlignmentFromJson(c.props['crossAxisAlignment']) ??
          WrapCrossAlignment.start,
      children: ((c.children['children'] as List<Widget>?) ?? const []),
    ),
  );

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
      child: (c.children['child'] as Widget?),
    );
  });

  r.register(
    'Padding',
    (c) => Padding(
      padding: edgeInsetsFromJson(c.map('padding')),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register('Center', (c) => Center(child: (c.children['child'] as Widget?)));

  r.register(
    'Align',
    (c) => Align(
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'SizedBox',
    (c) => SizedBox(
      width: c.num_('width'),
      height: c.num_('height'),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'Expanded',
    (c) => Expanded(flex: c.int_('flex') ?? 1, child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink())),
  );

  r.register(
    'Flexible',
    (c) => Flexible(flex: c.int_('flex') ?? 1, child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink())),
  );

  r.register(
    'Positioned',
    (c) => Positioned(
      left: c.num_('left'),
      top: c.num_('top'),
      right: c.num_('right'),
      bottom: c.num_('bottom'),
      width: c.num_('width'),
      height: c.num_('height'),
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register('ClipRRect', (c) {
    final radius = c.num_('borderRadius');
    return ClipRRect(
      borderRadius: radius == null
          ? BorderRadius.zero
          : BorderRadius.all(Radius.circular(radius)),
      clipBehavior:
          clipBehaviorFromJson(c.props['clipBehavior']) ?? Clip.antiAlias,
      child: (c.children['child'] as Widget?),
    );
  });

  r.register(
    'ClipOval',
    (c) => ClipOval(
      clipBehavior:
          clipBehaviorFromJson(c.props['clipBehavior']) ?? Clip.antiAlias,
      child: (c.children['child'] as Widget?),
    ),
  );

  // ColorFiltered：`colorFilter` 值走 colorFilterFromJson（mode / matrix /
  // gamma）；读不出时用「无效果」滤镜，保证子树仍按原样渲染。
  r.register(
    'ColorFiltered',
    (c) => ColorFiltered(
      colorFilter: colorFilterFromJson(c.props['colorFilter']) ??
          const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
      child: (c.children['child'] as Widget?),
    ),
  );

  // `ImageFiltered`：按 imageFilter 值对象模糊/膨胀/腐蚀/矩阵/组合。
  // 滤镜缺失（翻译失败）时用零 sigma 模糊兜底——零 sigma 等价于不变形。
  r.register('ImageFiltered', (c) {
    return ImageFiltered(
      imageFilter: imageFilterFromJson(c.props['imageFilter']) ??
          ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
      enabled: c.bool_('enabled') ?? true,
      child: (c.children['child'] as Widget?),
    );
  });

  // `Material`：除颜色/阴影外，`borderRadius` 是圆角的唯一来源（不写就是直角），
  // 必须映射；`shape`（ShapeBorder 值对象）跨语言未支持，写 `borderRadius`
  // 即等价于默认 `MaterialType.canvas` 下的圆角。
  r.register(
    'Material',
    (c) => Material(
      type: _materialTypeFromJson(c.props['type']) ?? MaterialType.canvas,
      color: colorFromJson(c.props['color']),
      elevation: c.num_('elevation') ?? 0,
      shadowColor: colorFromJson(c.props['shadowColor']),
      surfaceTintColor: colorFromJson(c.props['surfaceTintColor']),
      borderRadius: borderRadiusFromJson(c.map('borderRadius')),
      borderOnForeground: c.bool_('borderOnForeground') ?? true,
      clipBehavior: clipBehaviorFromJson(c.props['clipBehavior']) ?? Clip.none,
      child: (c.children['child'] as Widget?),
    ),
  );

  // Transform.translate：位移（props.offset = {dx, dy}）+ child。
  r.register('Transform', (c) {
    final offset = c.map('offset') ?? const <String, dynamic>{};
    final dx = (offset['dx'] as num?)?.toDouble() ?? 0;
    final dy = (offset['dy'] as num?)?.toDouble() ?? 0;
    return Transform.translate(offset: Offset(dx, dy), child: (c.children['child'] as Widget?));
  });

  r.register(
    'Card',
    (c) => Card(
      elevation: c.num_('elevation'),
      // 缺省必须是 null（走 Card 主题默认 EdgeInsets.all(4)）——`edgeInsetsFromJson`
      // 对 null 返回 zero，会把 item 之间的默认间隙抹平（原生 vs JS 并排可见）。
      margin: nullableEdgeInsets(c.map('margin')),
      color: colorFromJson(c.props['color']),
      shape: shapeFromJson(c.props['shape']),
      clipBehavior: clipBehaviorFromJson(c.props['clipBehavior']),
      shadowColor: colorFromJson(c.props['shadowColor']),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'Icon',
    (c) => Icon(
      // `icon` 是 Flutter `Icon` 的首个位置形参名（`Icon(Icons.star)`）。
      iconFromJson(c.props['icon']),
      size: c.num_('size'),
      color: colorFromJson(c.props['color']),
    ),
  );

  // `ImageIcon(AssetImage('a.jpg'))`：把**图片**当图标画，尺寸 / 颜色受
  // IconTheme 影响。与 Image / FadeInImage 同一套 provider 归一化：翻译层把
  // `AssetImage` / `NetworkImage` 折成路径/网址字符串，宿主按前缀还原 provider。
  r.register('ImageIcon', (c) {
    final source = c.str('image') ?? '';
    return ImageIcon(
      source.isEmpty ? null : _imageProvider(source),
      size: c.num_('size'),
      color: colorFromJson(c.props['color']),
      semanticLabel: c.str('semanticLabel'),
    );
  });

  // `Image.network('url')` / `Image.asset('a.png')`：工厂名（`props.factory`）
  // 决定构造哪个原生工厂，位置实参名随之不同（`Image.network` → `src`、
  // `Image.asset` → `name`、`Image(...)` → `image`）。
  r.register('Image', (c) {
    final factory = c.str('factory');
    final source = c.str('src') ?? c.str('name') ?? c.str('image') ?? '';
    final width = c.num_('width');
    final height = c.num_('height');
    final fit = boxFitFromJson(c.props['fit']);
    final color = colorFromJson(c.props['color']);
    final blend = blendModeFromJson(c.props['colorBlendMode']);
    final align = alignmentFromJson(c.props['alignment']) ?? Alignment.center;
    final repeat =
        imageRepeatFromJson(c.props['repeat']) ?? ImageRepeat.noRepeat;
    // 工厂名优先；缺失（旧产物 / 未登记）时退回按网址前缀判断。
    final isNetwork =
        factory == 'network' || (factory == null && source.startsWith('http'));
    return isNetwork
        ? Image.network(
            source,
            width: width,
            height: height,
            fit: fit,
            color: color,
            colorBlendMode: blend,
            alignment: align,
            repeat: repeat,
          )
        : Image.asset(
            source,
            width: width,
            height: height,
            fit: fit,
            color: color,
            colorBlendMode: blend,
            alignment: align,
            repeat: repeat,
          );
  });

  // `FadeInImage.assetNetwork(placeholder: 'a.jpg', image: 'https://…')`：
  // placeholder 是**资源路径**、image 是网址（`factory: 'assetNetwork'`）；
  // 普通构造 `FadeInImage(placeholder: AssetImage(…), image: NetworkImage(…))`
  // 两者都是 provider，翻译层已把 provider 归一化成路径/网址字符串，这里按
  // 前缀还原成原生 provider。
  r.register('FadeInImage', (c) {
    final assetNetwork = c.str('factory') == 'assetNetwork';
    return FadeInImage(
      placeholder: _imageProvider(c.str('placeholder') ?? '', forceAsset: assetNetwork),
      image: _imageProvider(c.str('image') ?? ''),
      fit: boxFitFromJson(c.props['fit']),
      placeholderFit: boxFitFromJson(c.props['placeholderFit']),
      fadeInDuration:
          durationFromJson(c.props['fadeInDuration']) ?? const Duration(milliseconds: 300),
      fadeOutDuration:
          durationFromJson(c.props['fadeOutDuration']) ?? const Duration(milliseconds: 300),
      width: c.num_('width'),
      height: c.num_('height'),
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
      repeat: imageRepeatFromJson(c.props['repeat']) ?? ImageRepeat.noRepeat,
    );
  });

  // `Hero`：跨路由共享元素动画。tag 两端按**同值字符串**配对（Dart 的 tag 是
  // Object，JS 只能发字符串/数字，字符串是唯一自然可比的形态）；子结点是
  // 飞行时的 shuttle 本体，宿主直接用。`flightShuttleBuilder` /
  // `placeholderBuilder` / `createRectTween` 是返回 widget / tween 的闭包，
  // 跨语言无法执行 → 不映射（走 Flutter 默认实现，与未声明时行为一致）。
  r.register('Hero', (c) {
    final tag = c.props['tag'];
    return Hero(
      tag: tag ?? '',
      transitionOnUserGestures: c.bool_('transitionOnUserGestures') ?? false,
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    );
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
                    : AssetImage(bgImage))
                as ImageProvider,
      child: (c.children['child'] as Widget?),
    );
  });

  // `PreferredSize(preferredSize: Size(0, 64), child: …)`：把**任意子树**声明成
  // `PreferredSizeWidget`（Scaffold.appBar / bottomNavigationBar / SliverAppBar 的
  // flexibleSpace 等位置要求这个类型）。preferredSize 只取 height/width 两个字段，
  // `Size.fromHeight(h)` 的 width 是 +∞（JSON 里被折叠成 null），按 ∞ 还原。
  r.register('PreferredSize', (c) {
    final raw = c.map('preferredSize') ?? const <String, dynamic>{};
    final w = raw['width'] is num ? (raw['width'] as num).toDouble() : double.infinity;
    final h = raw['height'] is num ? (raw['height'] as num).toDouble() : kToolbarHeight;
    return _JsPreferredSize(
      preferredSize: Size(w, h),
      child: c.children['child'] as Widget?,
    );
  });

  r.register(
    'Divider',
    (c) => Divider(
      height: c.num_('height'),
      thickness: c.num_('thickness'),
      indent: c.num_('indent'),
      endIndent: c.num_('endIndent'),
      color: colorFromJson(c.props['color']),
    ),
  );

  r.register('Spacer', (c) => Spacer(flex: c.int_('flex') ?? 1));

  // label 现在是结点（props['label']），运行时用 propChild 取。
  r.register(
    'Chip',
    (c) => Chip(
      label: (c.children['label'] as Widget?) ?? const SizedBox.shrink(),
      labelStyle: textStyleFromJson(c.map('labelStyle')),
      avatar: (c.children['avatar'] as Widget?),
      deleteIcon: (c.children['deleteIcon'] as Widget?),
      onDeleted: c.on('onDeleted'),
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      // padding 缺省必须为 null：否则 EdgeInsets.zero 会覆盖 Chip 默认
      // EdgeInsets.all(8.0)，JS 侧每个 chip 窄 16px（8 个 = 128px），
      // 与原生渲染/滚动范围不一致。
      padding: nullableEdgeInsets(c.map('padding')),
      side: borderSideFromJson(c.props['side']),
      shape: shapeFromJson(c.props['shape']),
      elevation: c.num_('elevation'),
    ),
  );

  // title / subtitle / leading / trailing 都是结点（props 里的 element prop）。
  r.register('ListTile', (c) {
    return ListTile(
      title: (c.children['title'] as Widget?),
      subtitle: (c.children['subtitle'] as Widget?),
      leading: (c.children['leading'] as Widget?),
      trailing: (c.children['trailing'] as Widget?),
      onTap: c.on('onTap'),
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

  // 四种按钮各自独立注册：type 就是构造名原样，事件键 `onPressed`，文案在
  // children 里的 Text（不再是 label prop）。`onPressed` 缺失 = 禁用。
  // style 值可能是 JSON map（`ButtonStyle(...)`），也可能是元素结点
  // （`XxxButton.styleFrom(...)` 被当成构造）→ styleMap 两种情况都取。
  r.register(
    'ElevatedButton',
    (c) => ElevatedButton(
      onPressed: c.on('onPressed'),
      style: buttonStyleFromJson(c.styleMap('style')),
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register(
    'TextButton',
    (c) => TextButton(
      onPressed: c.on('onPressed'),
      style: buttonStyleFromJson(c.styleMap('style')),
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register(
    'FilledButton',
    (c) => FilledButton(
      onPressed: c.on('onPressed'),
      style: buttonStyleFromJson(c.styleMap('style')),
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register(
    'OutlinedButton',
    (c) => OutlinedButton(
      onPressed: c.on('onPressed'),
      style: buttonStyleFromJson(c.styleMap('style')),
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register('InkWell', (c) {
    final radius = c.num_('borderRadius');
    return InkWell(
      onTap: c.on('onTap'),
      onLongPress: c.on('onLongPress'),
      onDoubleTap: c.on('onDoubleTap'),
      borderRadius: radius == null ? null : BorderRadius.circular(radius),
      splashColor: colorFromJson(c.props['splashColor']),
      highlightColor: colorFromJson(c.props['highlightColor']),
      child: (c.children['child'] as Widget?),
    );
  });

  r.register(
    'GestureDetector',
    (c) => GestureDetector(
      onTap: c.on('onTap'),
      onLongPress: c.on('onLongPress'),
      onDoubleTap: c.on('onDoubleTap'),
      behavior: hitTestBehaviorFromJson(c.props['behavior']),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'Switch',
    (c) => Switch(
      value: c.bool_('value') ?? false,
      onChanged: c.on1<bool?>('onChanged'),
      // 协议键仍叫 activeColor（生成器侧），Flutter 新版改名为 activeThumbColor
      activeThumbColor: colorFromJson(c.props['activeColor']),
      activeTrackColor: colorFromJson(c.props['activeTrackColor']),
      inactiveThumbColor: colorFromJson(c.props['inactiveThumbColor']),
      inactiveTrackColor: colorFromJson(c.props['inactiveTrackColor']),
    ),
  );

  r.register(
    'Checkbox',
    (c) => Checkbox(
      value: c.bool_('value'),
      tristate: c.bool_('tristate') ?? false,
      onChanged: c.on1<bool?>('onChanged'),
      activeColor: colorFromJson(c.props['activeColor']),
      checkColor: colorFromJson(c.props['checkColor']),
    ),
  );

  r.register(
    'Slider',
    (c) => Slider(
      value: c.num_('value') ?? 0,
      min: c.num_('min') ?? 0,
      max: c.num_('max') ?? 1,
      divisions: c.int_('divisions'),
      label: c.str('label'),
      activeColor: colorFromJson(c.props['activeColor']),
      inactiveColor: colorFromJson(c.props['inactiveColor']),
      onChanged: c.on1<double>('onChanged'),
    ),
  );

  // Scaffold：appBar / body / floatingActionButton / bottomNavigationBar
  // 都是「值为 element 的 prop」（生成器把命名参数翻译进 props，产物
  // `Scaffold({appBar: AppBar({...}), body: Column({...})})`）——宿主
  // propChild 直取，不依赖 children 顺序/类型判断。appBar 经
  // _JsAppBarAdaptor 适配 PreferredSizeWidget（JS 节点是 JsUiWidget 包装，
  // 非原生 AppBar 实例）。
  r.register('Scaffold', (c) {
    final appBar = (c.children['appBar'] as Widget?);
    return Scaffold(
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      // appBar 已经是 PreferredSizeWidget（真实 AppBar / PreferredSize 结点）时
      // 原样使用：PreferredSize 的全部意义就是自定义占位高度，套一层固定
      // kToolbarHeight 的适配器会把高度改回去。
      appBar: appBar == null
          ? null
          : (appBar is PreferredSizeWidget ? appBar : _JsAppBarAdaptor(appBar)),
      body: (c.children['body'] as Widget?),
      floatingActionButton: (c.children['floatingActionButton'] as Widget?),
      bottomNavigationBar: (c.children['bottomNavigationBar'] as Widget?),
      // drawer / endDrawer 接进真实 Scaffold：AppBar 自动出现汉堡按钮，
      // 开启原生可用；关闭走 capabilities/drawer/drawer_bridge.dart 的抽屉作用域。
      drawer: (c.children['drawer'] as Widget?),
      endDrawer: (c.children['endDrawer'] as Widget?),
      drawerScrimColor: colorFromJson(c.props['drawerScrimColor']),
    );
  });

  // AppBar：title / leading / flexibleSpace / actions 都按 Dart 形参原名从
  // children 取（actions 是数组 slot）。
  r.register('AppBar', (c) {
    final actions =
        (c.children['actions'] as List<Widget>?) ?? const <Widget>[];
    return AppBar(
      leading: (c.children['leading'] as Widget?),
      title: (c.children['title'] as Widget?),
      flexibleSpace: (c.children['flexibleSpace'] as Widget?),
      actions: actions.isEmpty ? null : actions,
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      foregroundColor: colorFromJson(c.props['foregroundColor']),
      elevation: c.num_('elevation'),
      toolbarHeight: c.num_('toolbarHeight'),
      centerTitle: c.bool_('centerTitle'),
      titleTextStyle: textStyleFromJson(c.map('titleTextStyle')),
    );
  });

  // ---------------------------------------------------------------------
  // 布局 / 装饰补充
  // ---------------------------------------------------------------------

  r.register(
    'SafeArea',
    (c) => SafeArea(
      left: c.bool_('left') ?? true,
      top: c.bool_('top') ?? true,
      right: c.bool_('right') ?? true,
      bottom: c.bool_('bottom') ?? true,
      // minimum：每边取 max(系统 padding, minimum)——即使系统 padding 为 0
      // （如 macOS 窗口）也能强制留白，是 SafeArea 唯一可见的效果来源。
      // 缺省即 EdgeInsets.zero（由 edgeInsetsFromJson 保证）。
      minimum: edgeInsetsFromJson(c.map('minimum')),
      // false 时底部用 padding.bottom；true 时改用 viewPadding.bottom
      // （手势条区域的固定内边距，键盘弹出时不跟随变化）。
      maintainBottomViewPadding: c.bool_('maintainBottomViewPadding') ?? false,
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register(
    'Opacity',
    (c) => Opacity(opacity: c.num_('opacity') ?? 1, child: (c.children['child'] as Widget?)),
  );

  r.register(
    'ConstrainedBox',
    (c) => ConstrainedBox(
      constraints:
          boxConstraintsFromJson(c.map('constraints')) ??
          const BoxConstraints(),
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register(
    'AspectRatio',
    (c) =>
        AspectRatio(aspectRatio: c.num_('aspectRatio') ?? 1, child: (c.children['child'] as Widget?)),
  );

  r.register(
    'FractionallySizedBox',
    (c) => FractionallySizedBox(
      widthFactor: c.num_('widthFactor'),
      heightFactor: c.num_('heightFactor'),
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'DecoratedBox',
    (c) => DecoratedBox(
      decoration:
          boxDecorationFromJson(c.map('decoration')) ?? const BoxDecoration(),
      child: (c.children['child'] as Widget?),
    ),
  );

  // ---------------------------------------------------------------------
  // 指示器
  // ---------------------------------------------------------------------

  r.register(
    'CircularProgressIndicator',
    (c) => CircularProgressIndicator(
      value: c.num_('value'),
      color: colorFromJson(c.props['color']),
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      strokeWidth: c.num_('strokeWidth') ?? 4.0,
    ),
  );

  r.register(
    'LinearProgressIndicator',
    (c) => LinearProgressIndicator(
      value: c.num_('value'),
      color: colorFromJson(c.props['color']),
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      minHeight: c.num_('minHeight'),
    ),
  );

  // ---------------------------------------------------------------------
  // 输入 / 导航
  // ---------------------------------------------------------------------

  r.register(
    'IconButton',
    (c) => IconButton(
      icon: (c.children['icon'] as Widget?) ?? const Icon(Icons.error_outline),
      onPressed: c.on('onPressed'),
      color: colorFromJson(c.props['color']),
      iconSize: c.num_('iconSize'),
      tooltip: c.str('tooltip'),
    ),
  );

  r.register(
    'FloatingActionButton',
    (c) => FloatingActionButton(
      // onPressed 缺省必须为 null：Flutter 默认 null = 禁用（灰色不可点）；
      // `() {}` 会变成可点但无动作，与原生语义不一致。
      onPressed: c.on('onPressed'),
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      foregroundColor: colorFromJson(c.props['foregroundColor']),
      mini: c.bool_('mini') ?? false,
      tooltip: c.str('tooltip'),
      elevation: c.num_('elevation'),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register('BottomNavigationBar', (c) {
    // items 是数据载体数组：从 children['items'] 的上下文读数据组装，
    // 不把 BottomNavigationBarItem 当 Widget 挂载。
    final items = <BottomNavigationBarItem>[];
    final raws =
        (c.children['items'] as List<JsRenderContext>?) ?? const [];
    for (final raw in raws) {
      final p = raw.props;
      items.add(
        BottomNavigationBarItem(
          icon: (raw.children['icon'] as Widget?) ??
              const Icon(Icons.error_outline),
          activeIcon: raw.children['activeIcon'] as Widget?,
          label: p['label'] == null ? null : '${p['label']}',
          tooltip: p['tooltip'] == null ? null : '${p['tooltip']}',
        ),
      );
    }
    return BottomNavigationBar(
      items: items,
      currentIndex: c.int_('currentIndex') ?? 0,
      onTap: c.on1<int>('onTap'),
      selectedItemColor: colorFromJson(c.props['selectedItemColor']),
      unselectedItemColor: colorFromJson(c.props['unselectedItemColor']),
    );
  });

  // BottomNavigationBarItem 非 Widget（见 BottomNavigationBar renderer，
  // 从 props.items 的元素描述组装）；若被单独挂载则退回显示 icon。
  r.register(
    'BottomNavigationBarItem',
    (c) => _JsBottomNavItem(
      BottomNavigationBarItem(
        icon: (c.children['icon'] as Widget?) ?? const Icon(Icons.error_outline),
        label: c.str('label'),
      ),
    ),
  );

  // RadioGroup：把选中值 + 回调提供给**子树内**的 Radio（子级不必再传
  // `groupValue` / `onChanged`，那两个是被它取代的旧 API）。onChanged 是必填，
  // JS 侧没给时用空函数兜底，避免整页因一个缺失回调挂掉。
  r.register(
    'RadioGroup',
    (c) => RadioGroup<dynamic>(
      groupValue: c.props['groupValue'],
      onChanged: c.on1<dynamic>('onChanged') ?? (dynamic _) {},
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    ),
  );

  r.register(
    'Radio',
    (c) => Radio<dynamic>(
      value: c.props['value'],
      // ignore: deprecated_member_use
      groupValue: c.props['groupValue'],
      // ignore: deprecated_member_use
      onChanged: c.on1<dynamic>('onChanged'),
      activeColor: colorFromJson(c.props['activeColor']),
    ),
  );

  r.register('DropdownButton', (c) {
    // items 是数据载体数组：从 children['items'] 的上下文读 value 与 child。
    final items = <DropdownMenuItem<dynamic>>[];
    final raws =
        (c.children['items'] as List<JsRenderContext>?) ?? const [];
    for (final raw in raws) {
      final p = raw.props;
      final child = raw.children['child'] as Widget?;
      items.add(
        DropdownMenuItem<dynamic>(
          value: p['value'],
          child: child ?? const SizedBox.shrink(),
        ),
      );
    }
    return DropdownButton<dynamic>(
      value: c.props['value'],
      items: items,
      onChanged: c.on1<dynamic>('onChanged'),
      hint: c.children['hint'] as Widget?,
      isExpanded: c.bool_('isExpanded') ?? false,
    );
  });

  r.register(
    'DropdownMenuItem',
    (c) => DropdownMenuItem<dynamic>(
      value: c.props['value'],
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

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

/// `PreferredSize` 承载：把 JS 子树声明成 `PreferredSizeWidget`，尺寸由 props
/// 的 preferredSize 决定（Scaffold.appBar 等位置据此占位）。
class _JsPreferredSize extends StatelessWidget implements PreferredSizeWidget {
  const _JsPreferredSize({required this.preferredSize, this.child});

  @override
  final Size preferredSize;

  final Widget? child;

  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
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
        Text(
          '<missing widget: $type>',
          style: const TextStyle(fontSize: 11, color: Color(0xFFB00020)),
        ),
        ...children,
      ],
    ),
  );
}
