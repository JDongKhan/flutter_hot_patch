import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../services/js_runtime_manager.dart';
import '../utils/dynamic_flutter_log.dart';
import 'capabilities/js_ui_capabilities.dart';
import 'ui_fallback.dart';

/// 条目 / 配置类值对象（`InputDecoration`、`BottomNavigationBarItem`、
/// `DropdownMenuItem` 等）在 JS 侧是普通值类（见生成器 `style_values_js`）：
/// 构造即值、留在父级 `props` 里，**没有任何类型表**。它们携带的 Widget 字段
/// 由运行时 `__descriptorOf` 摊成元素描述，父 renderer 用
/// [JsRenderContext.element] 就地还原成 Flutter widget（不进 reconciler 树，
/// 没有 patch/diff）。

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
/// 的 renderer）与 [_JsPlainNodeHost] 的生命周期回调都只需要「一个 id + 一组参数」，
/// 传 `invoke` 闭包只会让每层构造多一个与语义无关的参数。
void invokeJsHandler(Object? handler, [List<Object?> args = const []]) {
  if (handler is! Map) {
    // handler 形态不对 → 事件无法执行（点了没反应）。不能静默。
    JsLog.warn('js_ui: 事件句柄形态非法（${handler.runtimeType}），'
        '本次回调已丢弃（args=${args.length}）');
    return;
  }
  final id = handler['__fn'];
  if (id is! String) {
    // 句柄缺 __fn → 事件无法执行。不能静默。
    JsLog.warn('js_ui: 事件句柄缺少 __fn（$handler），本次回调已丢弃');
    return;
  }
  // args 双重编码：内层把数组变成 JSON 文本，外层再包成 JS 字符串字面量；
  // JS 侧 invoke 对字符串参数做一次 JSON.parse 还原为数组。单层编码会把
  // 字符串 payload 解析失败置 null。
  //
  // 编码失败（参数里有宿主侧对象、无 toJson 的类等）只丢这一次事件并记 error：
  // 异常若继续上抛，会从 build / 手势链路里炸掉整棵子树（Flutter 报
  // JsonUnsupportedObjectError + 错误页），比丢一次回调难定位得多。
  String encodedArgs;
  try {
    encodedArgs = jsonEncode(jsonEncode(args));
  } catch (e, st) {
    JsLog.error('js_ui: 事件参数无法 JSON 序列化（handler=$id，'
        '参数类型=${args.map((a) => a.runtimeType).join(', ')}），'
        '本次回调已丢弃：$e\n$st');
    return;
  }
  JsRuntimeManager.instance.evaluate(
    '__jsui.invoke(${jsonEncode(id)}, $encodedArgs);',
  );
}

/// 不需要动宿主；只有引入 Flutter 侧不存在的**视觉** widget 才注册一条。
class JsRenderContext {
  JsRenderContext({
    required this.type,
    required this.props,
    required this.children,
    this.key,
    this.context,
    this.lazySlotBuilder,
  });

  /// 本结点 renderer 所在位置的 [BuildContext]（宿主构建期提供）。
  ///
  /// 供「需要按调用位置取祖先」的渲染器使用（如 `MediaQuery.removePadding`）；
  /// 值对象里就地还原的元素（[buildJsElement]）没有宿主构建位置，为 null。
  final BuildContext? context;

  /// 本结点的元素 type（宿主 widget 类型名 / 未注册组件的具体类型名）。
  /// 供默认 builder 识别「这是哪个未注册组件」，按名走原生注入或占位。
  final String type;

  /// 结点声明的 `key`（JS 侧 `new UniqueKey()` / `ValueKey(...)` / `GlobalKey()`）
  /// 对应的**宿主 Flutter Key 实例**。
  ///
  /// GlobalKey / UniqueKey 是与 JS 句柄绑定的同一实例（跨帧稳定）；ValueKey /
  /// ObjectKey / PageStorageKey 按值现造。未声明 key 时为 null。
  ///
  /// renderer 应把它传给真实 widget（`key: c.key`）：运行时不做 wrapper 兜底，
  /// `GlobalKey.currentContext / currentState` 因此直接指向真实 widget。同一个
  /// key 只挂一次（不要既传给真实 widget 又套额外的 keyed wrapper）。
  final Key? key;

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

  /// 宿主按槽位拉取的入口（容器 props 带 `__pullItems` 时由运行时注入）。
  ///
  /// renderer 在 `itemBuilder` / `separatorBuilder` 里调 [lazySlot]：宿主首次
  /// 布局到该槽位时同步向 JS 拉取子树，因此子项 `initState` 与 Flutter 原生
  /// 一样只对可见项（含 `cacheExtent`）执行。
  final Widget Function(int slotIndex)? lazySlotBuilder;

  /// 取第 [slotIndex] 个惰性子项。非按槽位拉取的结点调用时给出明确的错误视图
  /// （不静默返回空，避免「列表空白但无日志」）。
  Widget lazySlot(int slotIndex) {
    final f = lazySlotBuilder;
    if (f == null) {
      return uiFallback('结点 "$type" 不支持按槽位拉取（slot $slotIndex）');
    }
    return f(slotIndex);
  }

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

  /// props 里的数字（number / 数字字符串）→ [num]；无法解析返回 null。
  num? num_(String key) {
    final v = props[key];
    if (v is num) return v;
    return num.tryParse('$v');
  }

  /// props 里的数字（number / 数字字符串）→ [double]；无法解析返回 null。
  double? double_(String key) {
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

  /// props 里的 map 值 → `Map<String, dynamic>`。
  ///
  /// 值可能是普通 JSON map，也可能是**元素描述的具名实参**
  /// （`{type, props, children}`——生成器把 `BoxDecoration(...)` /
  /// `ButtonStyle.styleFrom(...)` 这类「构造形态的值」也译成元素结点）。
  /// 后者取内层 `props`，普通 map 原样返回。
  Map<String, dynamic>? map(String key) => elementProps(props[key]);

  /// 把 props 里的原始值还原成普通 map（元素描述取内层 props）。
  ///
  /// 供需要脱离 props 键、直接处理嵌套值的场景复用；非 Map 值出声并忽略。
  Map<String, dynamic>? elementProps(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) {
      JsLog.warn('js_ui: props 值不是 Map（${raw.runtimeType}），已忽略');
      return null;
    }
    final inner = raw['props'];
    if (raw['type'] != null && inner is Map) {
      return inner.cast<String, dynamic>();
    }
    return raw.cast<String, dynamic>();
  }

  /// 单个元素描述（props 里值为 element 的键，或数组里的一项）→ widget。
  ///
  /// 值对象携带的 Widget 字段（`BottomNavigationBarItem.icon` /
  /// `InputDecoration.icon` …）走这里**就地**还原：不进 reconciler 树，父级
  /// 每次重建重建一次（与 Flutter 每次 build 重建 items 一致，没有 patch/diff）。
  Widget? element(Object? raw) => buildJsElement(raw);

  /// 元素描述数组（`AppBar.actions` / `BottomNavigationBar.items` /
  /// `MultiProvider.providers` 等）→ widget 列表（空项跳过）。
  List<Widget> elementList(Object? raw) {
    if (raw is! List) return const [];
    final out = <Widget>[];
    for (final e in raw) {
      final w = buildJsElement(e);
      if (w != null) {
        out.add(w);
      } else if (e != null) {
        JsLog.warn('js_ui: 元素数组里有无法解析的项'
            '（${_elementTypeLabel(e)}），已丢弃');
      }
    }
    return out;
  }
}

/// 把产物里的**元素描述**（`{type, props, children, element}`）渲染成 widget。
///
/// 用途：值对象携带的 Widget 字段（`BottomNavigationBarItem.icon` /
/// `InputDecoration.icon` / `DropdownMenuItem.child` …）就地还原；具名 slot
/// 已由 JS 侧挂载，宿主直接走 `children[key]`。
Widget? buildJsElement(Object? raw) {
  if (raw == null) return null;
  if (raw is! Map) {
    JsLog.warn('js_ui: 元素描述不是对象（${raw.runtimeType}），已丢弃');
    return null;
  }
  final type = raw['type'];
  if (type is! String || type.isEmpty) {
    JsLog.warn('js_ui: 元素描述缺少 type，已丢弃: $raw');
    return null;
  }
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
/// 协议唯一（由宿主包装类构造期的 `Component.__splitHost` 产出）：
///   - `__items`：builder 代理类展开结果（有序子结点）；
///   - 数组：widget 列表；
///   - `{__delegate: 'list' | 'builder', …}`：delegate 描述；
///   - `{element: true}`：单个 widget。
///
/// 不支持旧形状（children 是裸数组、元素混在 props 里）——产物以最新协议为准，
/// 形状不合法时宁可丢 slot 也不猜。
Map<String, Object?> _childrenFromSlots(Object? rawSlots) {
  final children = <String, Object?>{};
  if (rawSlots == null) return children;
  if (rawSlots is! Map) {
    JsLog.warn('js_ui: 元素 children 槽位不是对象（${rawSlots.runtimeType}），'
        '已按无子结点处理');
    return children;
  }

  void addList(String key, Object? value) {
    final widgets = <Widget>[];
    if (value is List) {
      for (final ch in value) {
        final w = buildJsElement(ch);
        // 数组槽位里解析不出的项按「没有这项」处理（可空语义），不兜底；
        // 但非空却解析不出来属于协议异常，必须留痕。
        if (w != null) {
          widgets.add(w);
        } else if (ch != null) {
          JsLog.warn('js_ui: 槽位 "$key" 的子元素无法解析'
              '（${_elementTypeLabel(ch)}），已丢弃');
        }
      }
    }
    children[key] = widgets;
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
      children[key] =
          buildJsElement(v) ?? uiFallback('槽位 "$key" 元素渲染失败：${_elementTypeLabel(v)}');
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

typedef JsWidgetBuilder = Widget Function(JsRenderContext c);

/// 未注册类型元素的**默认 builder**（[JsWidgetRegistry] 的兜底）：
/// 给出可见占位，便于定位缺失的翻译 / 注册。
///
/// 产物里的元素 type 始终是「具体类型名」，故这里不需要任何「Component」
/// 哨兵类型——「未注册」只表现为 [JsWidgetRegistry.lookup] 未命中。
Widget _unknownWidgetBuilder(JsRenderContext c) => buildMissingJsWidget(
  c.type,
  (c.children['__items'] as List<Widget>?) ?? const [],
);

/// 宿主组件注册表是否已完成一次性建表（`registerAllJsWidgets` 只跑一次）。
///
/// 建表之后再 `registerJsUiLibrary(...)` 的库拿不到 `JsUiLibrary.registerWidgets`
/// 回调，注册入口据此告警（禁止「注册了却没生效」静默）。
/// 建表之后直接 `jsWidgetRegistry.register(type, build)` 仍然有效——那只是往同一张
/// **可变**表里补条目，查表发生在渲染时刻。
bool jsWidgetRegistryBuilt = false;

/// `type -> Flutter widget` 注册表（宿主唯一扩展点）。
class JsWidgetRegistry {
  final Map<String, JsWidgetBuilder> _builders = {};

  /// lookup 未命中时的默认 builder（未注册组件的兜底）。
  ///
  /// 关键设计：**产物里的元素 type 永远是「具体类型名」**（生成器不再把不认识
  /// 的组件降级成统一的 'Component' 占位）。因此「某个类型没注册」只表现为
  /// [lookup] 返回 null —— 走本默认 builder 给出可见占位。之后补上该类型的
  /// 宿主 builder 即可，**同一份产物无需重新生成、协议不变**。
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

/// 元素 type 未注册（无宿主 builder）时的兜底。
Widget buildMissingJsWidget(String type, List<Widget> children) =>
    uiFallback('未注册的宿主 widget 类型 "$type"', children: children);
