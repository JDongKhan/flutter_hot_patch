import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../services/js_runtime_manager.dart';
import '../utils/hot_patch_log.dart';
import 'capabilities/js_ui_capabilities.dart';
import 'ui_fallback.dart';

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
        // 数组槽位里解析不出的项按「没有这项」处理（可空语义），不兜底。
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
        for (final ch in v)
          buildJsElement(ch) ?? uiFallback('子元素渲染失败：${_elementTypeLabel(ch)}'),
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
          : buildJsElement(v) ?? uiFallback('槽位 "$key" 元素渲染失败：${_elementTypeLabel(v)}');
    }
  }
  return children;
}

/// 元素描述的类型名（兜底提示用；结构不合法时退化到 runtimeType）。
String _elementTypeLabel(Object? raw) {
  if (raw is Map) {
    final t = raw['type'];
    if (t is String && t.isNotEmpty) return t;
  }
  return '${raw.runtimeType}';
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

/// 元素 type 未注册（既无宿主 builder、也无原生注入实现）时的兜底。
Widget buildMissingJsWidget(String type, List<Widget> children) =>
    uiFallback('未注册的宿主 widget 类型 "$type"', children: children);
