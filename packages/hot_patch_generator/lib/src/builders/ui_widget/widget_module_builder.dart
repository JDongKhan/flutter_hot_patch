/// package 模块 builder：把**每个 package** 的全部已注册 widget 类型产出为
/// 一个共享 JS 模块 `patch/<package>.js`（工厂函数 + 逻辑组件类，全局唯一
/// 一份，消除各组件产物里内联同类工厂函数造成的重复与文件爆炸）。
library;

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import '../shared/color_constants.dart';
import '../shared/ctor_signatures.dart';
import '../shared/js_format.dart';
import '../shared/js_class_defs.dart';
import '../shared/paths.dart';
import '../runtime/js/animation_js.dart';
import '../runtime/js/change_notifier_js.dart';
import '../runtime/js/color_js.dart';
import '../runtime/js/dart_values_js.dart';
import '../runtime/js/easy_refresh_js.dart';
import '../runtime/js/focus_js.dart';
import '../runtime/js/key_js.dart';
import '../runtime/js/keyboard_listener_js.dart';
import '../runtime/js/layout_builder_js.dart';
import '../runtime/js/media_query_js.dart';
import '../runtime/js/scroll_controller_js.dart';
import '../runtime/js/tab_controller_js.dart';
import '../runtime/js/text_editing_controller_js.dart';
import '../runtime/js/timer_js.dart';

/// Dart 值类区源码（`patch/flutter.js` 尾部，从 runtime.js 迁入）。
///
/// 收录标准：**Dart / Flutter 值类型与 Controller 的 JS 镜像**——
/// `Duration` / `Size` / `Offset` / `EdgeInsets` / `TextStyle` / `Color` /
/// `ChangeNotifier` / `AnimationController` / 各 Controller / `Key` / `Timer`…
/// 翻译层对它们一律发射 `new X({...})`（一比一），跨桥靠各自 `toJSON()`。
///
/// **拼接顺序有意义**：值类在前（`__posArgs` / `__durationMs` 等工具与基础值类），
/// 控制器在后（依赖 `G.__core` 的 `defineController` / 句柄表）。片段内的
/// `function` 声明会提升，故同区内可以前后互引。
String flutterValueClassesSource() => [
      dartValuesJsSource,
      colorJsSource,
      changeNotifierSource,
      animationJsSource,
      scrollControllerJsSource,
      textEditingControllerJsSource,
      focusJsSource,
      keyboardListenerJsSource,
      mediaQueryJsSource,
      layoutBuilderJsSource,
      tabControllerJsSource,
      keyJsSource,
      easyRefreshJsSource,
      timerJsSource,
    ].join('\n');

/// 有 JS 类的类型 → (package → {type})：由静态登记推导（[jsClassWidgetTypes]
/// 与 [widgetPackageOf]），作为 package 模块产物清单（每个包一个文件）的唯一来源。
Map<String, Set<String>> registeredWidgetPackages() {
  final out = <String, Set<String>>{};
  for (final t in jsClassWidgetTypes) {
    (out[widgetPackageOf(t)] ??= <String>{}).add(t);
  }
  return out;
}

/// widget 模块 builder：把**每个 package** 的全部已注册 widget 类型产出为
/// 一个共享 JS 模块 `patch/<package>.js`（工厂函数 + 逻辑组件类，全局唯一
/// 一份，消除各组件产物里内联同类工厂函数造成的重复与文件爆炸）。
///
/// 输出挂在包根伪资产 `$package$` 下（与 `ui_host_register` / `ui_patch_manifest`
/// 同款输入：整包一个输入，输出路径静态、无需任何种子文件）；输出名从
/// [registeredWidgetPackages] 静态推导，构建时按包名渲染整包即可。
class WidgetModuleBuilder implements Builder {
  const WidgetModuleBuilder();

  @override
  Map<String, List<String>> get buildExtensions {
    final pkgs = <String>{
      // `__h` 宿主（基础包 flutter）即使未注册任何 flutter widget 也要产出。
      nodeHelperPackage,
      ...registeredWidgetPackages().keys,
    }.toList()..sort();
    return {
      // `$package$`：整包伪资产，输入一个包、产出该包的全部 package 模块。
      r'$package$': [for (final p in pkgs) packageModulePath(p)],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final packages = registeredWidgetPackages();
    for (final out in buildStep.allowedOutputs) {
      // 输出路径形如 patch/<package>.js → 反推 package
      final segs = out.path.split('/');
      if (segs.length != 2 || segs[0] != 'patch' || !segs[1].endsWith('.js')) {
        continue;
      }
      final pkg = segs[1].substring(0, segs[1].length - '.js'.length);
      await buildStep.writeAsString(
        out,
        canonicalizeJsIndent(renderPackageModule(pkg, packages[pkg] ?? const <String>{})),
      );
    }
  }
}

/// 共享结点工厂源码：`export function __h(type, props)`，把翻译层按原名下发的
/// props 拆成 `{type, props, children, element}`：
///
///   - 组件类（`typeof type === 'function'`）走 [__element]：props 保留，**不实例化**；
///     真正实例化只由 reconciler 的 mount 完成。
///   - 用户代码 `new CommunityPage(props)` 按普通类语义得到**组件实例**；父级把
///     它当子结点消费时由 [__asElement] 折算成元素描述（`build` 原型方法判定，
///     不做类型名猜测）。宿主包装类（`new Text(props)`）在构造里直接调用 `__h`。
///   - 每个元素对象都带 **`element: true`** 标记（`__h` / `__element` 统一加）
///     ——这是唯一可靠的 widget 判据，不再靠 `{type, props}` 形状猜测；
///   - 值是元素（`element === true`）或「元素数组」→ 移入 `children` 对象，
///     key 与 props 原名**完全一致**（`child` / `content` / `top` / `body` /
///     `items` 走同一条路径，不再有固定键表）；
///   - `delegate` 产物（`{__delegate:'list'|'builder', …}`）也移入 `children`，
///     **不参与 props**；运行时按 `__delegate` 形态消费；
///   - `ListView.builder` 不再在代理类里展开：代理只写入内部键
///     `children.__builder = {item, sep, count, ctx}`，由运行时按容器是否懒
///     决定「立刻调 itemBuilder」还是「宿主 inflate 到该项时再调」；
///   - 其余值留在 `props`；
///   - `type` 是函数（JS 组件类）时 props **原样保留**——`__applyProps` 靠它
///     派生构造参数字段。JS 组件内部 build 再调用 `__h('X', props)` 时，
///     宿主类型才做拆分。
String jsNodeHelperSource() => '''
// 共享结点工厂：所有 package 模块与组件产物共用（本文件是它的唯一定义处）。
// 元素对象统一由本函数产出，带 element: true 标记；props 值是否是 widget
// 只看这个标记，不做形状猜测。
// 懒容器配置（**构建期唯一事实源**：shared/js_class_defs.dart 的
// lazyChildHostTypes）。运行时只认元素上的 lazyChildren 标记，不认识任何类型。
var __lazyChildHosts = ${lazyChildHostTypesLiteral()};
function __lazyChildrenOf(type, props) {
  var rule = __lazyChildHosts[type];
  if (rule === undefined) { return false; }
  if (rule === true) { return true; }
  for (var i = 0; i < rule.length; i++) {
    if (props && props[rule[i]] !== undefined) { return true; }
  }
  return false;
}
function __isElement(v) {
  return v != null && typeof v === 'object' && v.element === true;
}
function __isElementList(v) {
  if (!Array.isArray(v) || v.length === 0) { return false; }
  for (var i = 0; i < v.length; i++) {
    if (v[i] != null && !__isElement(v[i])) { return false; }
  }
  return true;
}
// 组件实例 → 元素描述：生成类与普通类一样「构造即实例」（`new CommunityPage(...)`
// 得到实例），父级把它当子结点消费时在这里统一折算。判定只看原型上有没有
// build（组件类的语言级特征），不查类型名表、不需要 toJson / 特殊标记。
// `inst` 随元素携带：reconciler mount 直接复用它（不再 new 第二次）。
// 同一实例 → 同一元素描述：Dart「const 规范化」在 JS 侧的对应物（const 构造
// 经 `__const` 缓存后实例唯一），reconciler 据此按引用短路子树更新。
export function __asElement(v) {
  if (v == null || typeof v !== 'object' || v.element === true) { return v; }
  var C = v.constructor;
  if (typeof C === 'function' && C.prototype &&
      typeof C.prototype.build === 'function') {
    if (v.__elCache) { return v.__elCache; }
    var e = {
      type: C, props: v.props || {}, children: {}, element: true, inst: v
    };
    v.__elCache = e;
    return e;
  }
  return v;
}
// 数组逐项归一化（只复制命中项，普通值数组保持原引用）。
export function __asElementList(v) {
  if (!Array.isArray(v)) { return v; }
  var out = null;
  for (var i = 0; i < v.length; i++) {
    var w = __asElement(v[i]);
    if (w !== v[i]) {
      if (!out) { out = v.slice(); }
      out[i] = w;
    }
  }
  return out || v;
}
// 组件元素描述：`type` 是 JS 类引用，props 值里的组件实例同样折算成元素
// （`new MultiProvider({providers: [new ChangeNotifierProvider(...)]})` 这类
// 直接构造、不经过 __h 的路径也保持一致）。真正的实例化只由 mount 完成。
export function __element(type, props) {
  var p = props || {};
  var out = {};
  for (var k in p) {
    if (!Object.prototype.hasOwnProperty.call(p, k)) { continue; }
    out[k] = __asElementList(__asElement(p[k]));
  }
  return { type: type, props: out, children: {}, element: true };
}
export function __h(type, props) {
  // JS 组件类：只产出元素描述，不在此实例化。
  if (typeof type !== 'string') {
    return __element(type, props);
  }
  var p = props || {};
  var data = {}, slots = {};
  for (var k in p) {
    if (!Object.prototype.hasOwnProperty.call(p, k)) { continue; }
    var v = __asElementList(__asElement(p[k]));
    if (__isElement(v)) { slots[k] = v; continue; }
    if (__isElementList(v)) { slots[k] = v; continue; }
    // builder 延迟展开描述（命名构造代理写入）同样进 children，不参与 props。
    if (k === '__builder' && v != null && typeof v === 'object') {
      slots[k] = v;
      continue;
    }
    // delegate 两种形态都进 children，不参与 props。
    if (v != null && typeof v === 'object' && v.__delegate) {
      slots[k] = v;
      continue;
    }
    data[k] = v;
  }
  var el = { type: type, props: data, children: slots, element: true };
  // 懒容器标记：由构建期配置决定（见 lazyChildHostTypes），运行时据此决定
  // 子结点是否延迟到宿主 inflate 时再挂载。
  if (__lazyChildrenOf(type, p)) { el.lazyChildren = true; }
  return el;
}''';

/// 懒容器配置的 JS 字面量：`{ "PageView": true, "ListView": ["itemExtent"] }`。
/// 空键列表 = 无条件懒（`true`）；非空 = props 带其中任一键时才懒。
String lazyChildHostTypesLiteral() {
  final parts = <String>[];
  lazyChildHostTypes.forEach((type, keys) {
    final value = keys.isEmpty
        ? 'true'
        : '[${keys.map(jsonEncode).join(', ')}]';
    parts.add('${jsonEncode(type)}: $value');
  });
  return '{${parts.join(', ')}}';
}

/// 包装类的**命名构造静态方法**（`ListView.separated(props)`）。
///
/// 翻译层对命名构造是 1:1 发射（`A.b(...)` → `A.b({...})`），所以 JS 类上必须有
/// 同名静态方法。构造名从源码自动抽取（[CtorSignatures.ctorNamesOf]），SDK /
/// 依赖包新增命名构造后重构建即自动补齐，无需登记任何类名或构造名。
///
/// 静态方法内部把构造名写成 `props.factory`：宿主渲染仍按「类型 + 工厂名」
/// 选原生工厂，翻译层与产物形态都不感知这层协议。
String namedCtorStatics(String type, {Iterable<String> extra = const []}) {
  final names = <String>{...?CtorSignatures.instance?.ctorNamesOf(type), ...extra};
  if (names.isEmpty) return '';
  final b = StringBuffer();
  for (final n in names.toList()..sort()) {
    b.writeln('  static $n(props) { '
        "return new $type(Object.assign({}, props, { factory: '$n' })); }");
  }
  return b.toString();
}

/// 逻辑组件的**命名构造静态方法**（`ChangeNotifierProvider.value(props)`）。
///
/// 与包装类同一条口径：翻译层对命名构造 1:1 发射（`A.b(...)` → `A.b({...})`），
/// 构造名从源码自动抽取（[CtorSignatures.ctorNamesOf]），SDK / 依赖包新增命名
/// 构造后重构建即自动补齐，不需要任何类名或构造名登记。
String logicCtorStatics(String type) {
  final names = CtorSignatures.instance?.ctorNamesOf(type) ?? const <String>{};
  if (names.isEmpty) return '';
  final b = StringBuffer();
  for (final n in names.toList()..sort()) {
    b.writeln('$type.$n = function (props) { return new $type(props); };');
  }
  return b.toString();
}

/// 宿主包装类源码：类名 = 宿主类型名，构造即产出元素描述（type 仍是**字符串**）。
/// 宿主结点的实例化由宿主注册表完成，reconciler 从不 `new` 这个类。
///
/// 同一份源码也用于 `@PatchIgnore(isComponent: true)` 的组件包装类（生成在
/// 该组件**自己的源文件产物**里）：[exported] 为 false 时生成产物内可见的
/// `class`（私有类只可能在本产物里使用）。
String hostWrapperSource(String type, {bool exported = true}) => '''
${exported ? 'export ' : ''}class $type {
  constructor(props) {
    return __h('$type', props);
  }
${namedCtorStatics(type)}}''';

/// builder 命名构造（`X.builder(...)` / `X.separated(...)`）的 JS 侧代理类
/// 源码（类名 = Dart 类型名）：产物显式带 `props.factory`（`builder` /
/// `separated`），回调按 Flutter 该命名构造的形参名下发——`itemBuilder`、
/// `separatorBuilder`、`itemCount`。`delegate:` 形态不经过本类（直接是宿主节点，
/// 由 `children.delegate` 描述消费）。
///
/// build 时**不展开**子结点，只写入延迟展开描述
/// `children.__builder = {item, sep, count, ctx}`：容器是否懒由元素上的
/// `lazyChildren` 标记决定（生成期按 `lazyChildHostTypes` 打到元素上）。
/// 懒容器下 `itemBuilder` 推迟到宿主 inflate 到该项时才调用（与 Flutter
/// `ListView.builder` 只构造可见项一致），非懒容器由运行时立刻按描述展开。
///
/// 被委托方法的第一个实参是 **build 的 `context` 形参**（运行时统一
/// `inst.build(contextOf(inst))` 传入，锚点就是本代理组件自身的结点，与 Dart 侧
/// `ListView.builder(itemBuilder: (context, i) => …)` 的形参同源），随描述一起
/// 带上，展开时原样传入，保持与原实现一致的上下文语义。
String builderProxySource(String type) {
  final countKey = builderCountPropKey(type);
  return '''
export class $type {
  constructor(props) {
    this.props = props || {};
    // 普通构造形态（没有 builder 回调，如 `SliverGrid(delegate: …)` /
    // `PageView(children: […])`）：与其它宿主类型同一协议，直接产出元素。
    if (!this.__hasBuilder()) {
      return __h('$type', this.props);
    }
  }
  __hasBuilder() {
    return typeof this.props.itemBuilder === 'function';
  }
  build(context) {
    var item = this.props.itemBuilder;
    // builder 协议只有**一种形态：闭包（函数）**。非函数说明调用方漏了闭包化，
    // 出声后按普通构造渲染（宁可空列表也不静默）。
    if (!this.__hasBuilder()) {
      console.warn('[$type] itemBuilder 不是闭包，按普通构造渲染');
      return __h('$type', this.props);
    }
    // props 原样透传（含 itemCount/factory）；**builder 回调从 props 摘除**——
    // 它只用于展开，函数不能进宿主 props（要跨桥序列化）。
    var p = {};
    for (var k in this.props) {
      if (k === 'itemBuilder' || k === 'separatorBuilder') { continue; }
      p[k] = this.props[k];
    }
    // 展开描述走内部键 __builder，由 __h 归入 children，宿主 renderer 不感知。
    p.__builder = {
      item: item,
      sep: this.props.separatorBuilder || null,
      count: this.props.$countKey || 0,
      ctx: context
    };
    return __h('$type', p);
  }
${namedCtorStatics(type, extra: const ['builder', 'separated'])}
}''';
}

/// 「逻辑 widget」类型 → JS 类源码（在本模块里内联一个普通类，类名 = Dart 名）。
///
/// 与宿主 type 节点不同：这些 widget 的**状态/订阅逻辑必须跑在 JS 里**，
/// 因此元素写成 `__h(<类名>, props, children)`（类引用，由本模块 export），
/// 运行时 `new` 该组件类并按组件路径挂载，由组件 `build()` 自行消费 props
/// （provider 提供/消费 VM、Builder 委托拥有者方法返回子树）。运行时会给普通
/// 类实例补挂 `props/setState/context/__bindFn`
/// （见 js_ui/runtime_js.dart）。键集合与 js_class_defs 的
/// `logicWidgetTypes` 一致。
const Map<String, String> logicWidgetSources = {
  'Builder': jsBuilderComponent,
  'ChangeNotifierProvider': jsChangeNotifierProviderComponent,
  'MultiProvider': jsMultiProviderComponent,
  'Consumer': jsConsumerComponent,
  'ListenableBuilder': jsListenableBuilderComponent,
  'ValueListenableBuilder': jsValueListenableBuilderComponent,
  'TweenAnimationBuilder': jsTweenAnimationBuilderComponent,
  'AnimatedBuilder': jsAnimatedBuilderComponent,
  'NestedScrollView': jsNestedScrollViewComponent,
  'LayoutBuilder': jsLayoutBuilderComponent,
  'OrientationBuilder': jsOrientationBuilderComponent,
  'SliverPersistentHeader': jsSliverPersistentHeaderComponent,
  'Overlay': jsOverlayComponent,
};

/// 值类（**不是 widget**、不产出元素）→ JS 类源码：同样内联在包模块里。
///
/// 与 [logicWidgetSources] 的区别只在语义：值类由业务代码 `new` 出来当普通对象
/// 传递（props 里的载体），元素树里不会出现它的 type。运行时对两者的处理相同
/// （都是模块导出的普通类，使用方 `new X({...})`）。
const Map<String, String> valueClassSources = {
  'OverlayEntry': jsOverlayEntryClass,
};

/// Overlay：条目表 + `Overlay.of(context)` 的 JS 实现。
///
/// 为什么逻辑必须在 JS 侧：`OverlayEntry.builder` 是 JS 闭包，宿主执行不了。
/// 因此条目在 JS 里逐条展开成**兄弟结点**，宿主只看到 `Stack` 插槽：
///   - 声明式：`Overlay(initialEntries: [...])` 的条目直接进表；
///   - 命令式：`Overlay.of(context)` 沿作用域取最近的**本实例**
///     （构造函数里声明 `__provides`，与宿主结点声明作用域同一套机制），
///     之后 `insert` / `remove` / `markNeedsBuild` 与 Dart 的 OverlayState 同义。
///
/// 语义与 Flutter 对齐：条目按整块区域叠放（`fit: expand` + `topLeft`，与
/// `_RenderTheater` 相同）；被 `remove()` 过的条目立即退出渲染。
const String jsOverlayComponent = '''
export class Overlay {
  constructor(props) {
    this.props = props || {};
    // 条目表：声明式与命令式共用一张表（Dart 侧同样是 _entries）。
    this.__entries = [];
    // 作用域声明：本实例即「OverlayState」，子孙 `Overlay.of(context)` 取到它。
    this.__provides = { OverlayState: this };
    var init = this.props.initialEntries;
    if (Array.isArray(init)) {
      for (var i = 0; i < init.length; i++) { this.__attach(init[i]); }
    }
  }
  // 条目归属：同一个条目被别的 Overlay 占用时先摘除（Dart 语义：一个条目只能
  // 属于一个 Overlay）；重复 insert 不重复展开。
  __attach(entry) {
    if (!entry || entry.__owner === this) { return; }
    if (entry.__owner) { entry.__owner.remove(entry); }
    entry.__owner = this;
    entry.__removed = false;
    this.__entries.push(entry);
  }
  // ── 与 OverlayState 同名同义的命令式 API ────────────────────────────────
  insert(entry) {
    this.__attach(entry);
    this.setState(function () {});
  }
  insertAll(entries) {
    if (Array.isArray(entries)) {
      for (var i = 0; i < entries.length; i++) { this.__attach(entries[i]); }
    }
    this.setState(function () {});
  }
  remove(entry) {
    if (!entry || entry.__owner !== this) { return; }
    entry.__owner = null;
    entry.__removed = true;
    for (var i = 0; i < this.__entries.length; i++) {
      if (this.__entries[i] === entry) { this.__entries.splice(i, 1); break; }
    }
    this.setState(function () {});
  }
  markNeedsBuild(entry) {
    if (entry && entry.__owner === this) { this.setState(function () {}); }
  }
  build(context) {
    var kids = [];
    for (var i = 0; i < this.__entries.length; i++) {
      var e = this.__entries[i];
      if (!e || e.__removed) { continue; }
      var w = e.__build(context);
      // 与 Dart 一致：null 条目（builder 返回 null）不占位。
      if (w != null) { kids.push(w); }
    }
    return __h('Stack', { alignment: 'topLeft', fit: 'expand', children: kids });
  }
  dispose() {
    for (var i = 0; i < this.__entries.length; i++) {
      if (this.__entries[i]) { this.__entries[i].__owner = null; }
    }
    this.__entries = [];
  }
}
Overlay.of = function (context) {
  return __scopeOf(context, 'OverlayState');
};''';

/// OverlayEntry：条目的载体（值类，不是元素）。
///
/// `builder` / `opaque` / `maintainState` 与 Dart 字段一一对应；`mounted` 是
/// getter（所在 Overlay 已登记且未移除）；`remove()` / `markNeedsBuild()` 转发给
/// 所属 Overlay。
const String jsOverlayEntryClass = '''
export class OverlayEntry {
  constructor(props) {
    this.props = props || {};
    this.builder = this.props.builder;
    this.opaque = !!this.props.opaque;
    this.maintainState = this.props.maintainState !== false;
    this.__owner = null;
    this.__removed = false;
  }
  get mounted() { return this.__owner != null && !this.__removed; }
  remove() {
    // 幂等：Dart 对**已移除**的条目在 remove 时断言（`_overlay != null`），
    // JS 侧改为静默 no-op——重复移除不该把整个事件回调炸掉。
    if (this.__removed) { return; }
    if (this.__owner) { this.__owner.remove(this); }
  }
  markNeedsBuild() {
    if (this.__owner) { this.__owner.markNeedsBuild(this); }
  }
  __build(context) {
    return typeof this.builder === 'function' ? this.builder(context) : null;
  }
}''';

/// Builder：无状态委托组件——调用拥有者组件上的 `props.builder` 方法
/// （`_builderN(context)`，含 `var model = context.watch(...)` 前置语句）拿子树。
/// 传下去的 context 就是 **build 收到的形参**（本组件自身的 BuildContext 代理，
/// 与 Dart 侧 `Builder(builder: (context) => …)` 的形参一致）。
const String jsBuilderComponent = '''
export class Builder {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    // builder 协议唯一形态：闭包。闭包由组件 build 期生成（箭头函数，this 已绑定）。
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      console.warn('[Builder] builder 不是闭包');
      return null;
    }
    return fn(context);
  }
}''';

/// NestedScrollView：**头部 slivers 由 JS 侧展开**。
///
/// Dart 的 `headerSliverBuilder` 是返回 sliver 列表的闭包，跨语言无法执行；
/// 因此本类在 build 里调用它（第二参 `innerBoxIsScrolled` 传 false，与 Flutter
/// 首帧语义一致），把结果与 `body` 一起作为插槽交给宿主结点——宿主只按
/// `headerSlivers` / `body` 两个键取子树，不感知 builder 的存在。
const String jsNestedScrollViewComponent = '''
export class NestedScrollView {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    var p = {};
    var src = this.props;
    for (var k in src) {
      if (!Object.prototype.hasOwnProperty.call(src, k)) { continue; }
      // builder 只在本类里执行，不往宿主 props 里传（函数不能跨语言）。
      if (k === 'headerSliverBuilder') { continue; }
      p[k] = src[k];
    }
    var fn = src.headerSliverBuilder;
    p.headerSlivers = typeof fn === 'function' ? (fn(context, false) || []) : [];
    return __h('NestedScrollView', p);
  }
}''';

/// OrientationBuilder：`builder(context, orientation)` 必须在 JS 里执行。
///
/// 与 Flutter 源码 1:1——原生实现就是
/// `LayoutBuilder(builder: (context, c) => builder(context, c.maxWidth > c.maxHeight
///   ? Orientation.landscape : Orientation.portrait))`，
/// 这里同样**基于 LayoutBuilder 类**委托，不自己取窗口方向。
const String jsOrientationBuilderComponent = '''
export class OrientationBuilder {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    var builder = this.props.builder;
    if (typeof builder !== 'function') {
      console.warn('[OrientationBuilder] builder 不是闭包');
      return null;
    }
    return __h(LayoutBuilder, {
      'builder': function (context, constraints) {
        return builder(context, constraints.maxWidth > constraints.maxHeight
          ? Orientation.landscape
          : Orientation.portrait);
      },
    });
  }
}''';

/// LayoutBuilder：`builder(context, constraints)` 在 JS 里执行，约束由宿主下发。
///
/// 与 Dart 的关系：Flutter 的 LayoutBuilder 在**布局阶段**执行 builder 决定子树，
/// 而 builder 闭包只存在于 JS、约束也只有布局阶段才知道。所以本类把 builder
/// **登记成跨语言句柄**放进宿主结点的 props（`builder`，键名与 Dart 形参一致）；
/// 宿主用真实 `LayoutBuilder` 承载该结点，布局时 `invoke(句柄, [约束 JSON])`
/// 回调本类 —— 本类用约束执行 builder，把结果作为子结点下发（patch 增量子树）。
///
/// 约束按值去重：宿主每次布局都会回调，同值不重建（避免布局→重建→再布局自激）。
/// 首帧（还没有约束）子树为空，与 Flutter LayoutBuilder 自身的首帧语义一致。
const String jsLayoutBuilderComponent = '''
export class LayoutBuilder {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    var builder = this.props.builder;
    if (typeof builder !== 'function') {
      console.warn('[LayoutBuilder] builder 不是闭包');
      return null;
    }
    var self = this;
    // 同一位点复用同一句柄（重建不新增跨语言句柄，卸载随实例释放）。
    // 宿主在布局阶段调用：实参是本结点的**父约束** JSON，不是事件参数。
    var handle = this.__bindFn(0, [], function (json) {
      var c = __jsuiBoxConstraints(json);
      var prev = self.__constraints;
      if (prev && prev.minWidth === c.minWidth && prev.maxWidth === c.maxWidth &&
          prev.minHeight === c.minHeight && prev.maxHeight === c.maxHeight) {
        return;
      }
      self.__constraints = c;
      // 字段名不能叫 `__child`：那是 reconciler 记录「本实例挂出的子宿主结点」
      // 的内部字段（见 mini_react 的 `ci.__child = mount(...)`），mount 之后会
      // 被覆盖成宿主实例（带 __parent/__el，序列化时成环），props 里再塞它
      // 就变成循环引用。
      self.__lbChild = builder(context, c);
      self.setState(function () {});
    });
    var props = { 'builder': handle };
    if (this.__lbChild != null) { props.child = this.__lbChild; }
    return __h('LayoutBuilder', props);
  }
}''';

/// SliverPersistentHeader：`delegate.build(context, shrinkOffset, overlapsContent)`
/// 在**布局阶段**同步执行，而 delegate 只存在于 JS。
///
/// 与 LayoutBuilder 同一方案：
///   - `minExtent` / `maxExtent` 是 delegate 的**同步 getter**，在 JS 里直接读，
///     随 props 下发（header 的高度插值由 Flutter 原生负责，不跨语言）；
///   - `build` 登记成跨语言句柄（`builder`），宿主在布局阶段把
///     `{shrinkOffset, overlapsContent}` 交给它；本类执行 delegate.build 后把
///     子树作为子结点 patch 下发，宿主下一帧用新子树重排。
///   - 因此滚动过程中**内容**晚一帧跟随（高度不受影响）；首帧子树为空。
const String jsSliverPersistentHeaderComponent = '''
export class SliverPersistentHeader {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    var delegate = this.props.delegate;
    if (!delegate || typeof delegate.build !== 'function') {
      console.warn('[SliverPersistentHeader] delegate.build 不是闭包');
      return null;
    }
    var self = this;
    // 首帧：宿主要到**布局阶段**才回调句柄，而 pinned 头的 paintExtent 由子级
    // 实际高度决定（`min(childExtent, …)`），零高占位会触发「layoutExtent 超过
    // paintExtent」的断言。所以这里先按 (0, false) 展一次——与 Flutter 首次布局
    // 时 scrollOffset=0 的入参一致，只是把那次调用提前到 build 阶段。
    if (this.__sphDelegate !== delegate) {
      this.__sphDelegate = delegate;
      this.__sphSig = { shrinkOffset: 0, overlaps: false };
      this.__sphChild = delegate.build(context, 0, false);
    }
    // 同一位点复用同一句柄（重建不新增跨语言句柄，卸载随实例释放）。
    // 宿主在布局阶段调用：实参是 {shrinkOffset, overlapsContent}，不是事件参数。
    var handle = this.__bindFn(0, [], function (json) {
      var prev = self.__sphSig;
      if (prev && prev.shrinkOffset === json.shrinkOffset &&
          prev.overlaps === json.overlapsContent) {
        return;
      }
      self.__sphSig = { shrinkOffset: json.shrinkOffset, overlaps: json.overlapsContent };
      // 字段名不能叫 `__child`（reconciler 内部字段，见 LayoutBuilder 处的说明）。
      self.__sphChild = delegate.build(context, json.shrinkOffset, json.overlapsContent);
      self.setState(function () {});
    });
    var props = {
      'minExtent': delegate.minExtent,
      'maxExtent': delegate.maxExtent,
      'builder': handle
    };
    // pinned / floating 原样透传给宿主（默认 false 由宿主兜底）。
    if (this.props.pinned !== undefined) { props.pinned = this.props.pinned; }
    if (this.props.floating !== undefined) { props.floating = this.props.floating; }
    if (this.__sphChild != null) { props.child = this.__sphChild; }
    return __h('SliverPersistentHeader', props);
  }
}''';

/// ChangeNotifierProvider：解析 create/value 得到模型实例，然后**交给宿主**。
///
/// JS 侧不做任何 provider 专用记账：本类只负责
///   ① 造/取模型实例（`create` 为类引用时 new 一次，生命周期归本类；实例时复用）；
///   ② 渲染宿主结点 `ChangeNotifierProvider`，props 带 `{model, notifier}`——
///      宿主据此建 Dart 侧的 provider 映射（ChangeNotifier 镜像 + provider 子树），
///      `context.watch<T>()` 的 T 就是这里的 `model`（类型名一路传给宿主）。
/// 模型真实对象只存在于 JS 端：`notifier` 走句柄（`{__handle:id}`）下发。
const String jsChangeNotifierProviderComponent = '''
export class ChangeNotifierProvider {
  constructor(props) {
    this.props = props || {};
  }
  initState() {
    var p = this.props;
    var notifier = null, owns = false;
    if (p.create !== undefined && p.create !== null) {
      if (typeof p.create === 'function') { notifier = new p.create(); }
      else { notifier = p.create; }
      owns = true;
    } else if (p.value !== undefined && p.value !== null) {
      notifier = p.value;
    }
    this.__value = notifier;
    this.__ownsValue = owns;
  }
  build() {
    return __h('ChangeNotifierProvider', {
      model: this.props.model,
      notifier: this.__value,
      child: this.props.child
    });
  }
  dispose() {
    if (this.__ownsValue && this.__value &&
        typeof this.__value.dispose === 'function') {
      this.__value.dispose();
    }
  }
}''';

/// MultiProvider：把 providers 数组按「嵌套 Provider」语义组合——
/// providers[0] 最外层，最后一个最内层（离 child 最近），与原生一致。
const String jsMultiProviderComponent = '''
export class MultiProvider {
  constructor(props) {
    this.props = props || {};
  }
  build() {
    var provs = this.props.providers || [];
    var node = this.props.child;
    for (var i = provs.length - 1; i >= 0; i--) {
      // providers 项是翻译层 `new ChangeNotifierProvider(...)` 产出的实例
      // （元素携带 inst）——注入 child 后**复用同一个实例**，不再 new 第二次。
      var prov = __asElement(provs[i]);
      var p = {};
      for (var k in prov.props) { p[k] = prov.props[k]; }
      p.child = node;
      if (prov.inst) {
        prov.inst.props = p;
        node = {
          type: prov.type, props: p, children: {}, element: true, inst: prov.inst
        };
      } else {
        node = __h(prov.type, p);
      }
    }
    return node;
  }
}''';

/// Consumer：消费 VM——按 `props.model`（类型名）经 **build 收到的 context**
/// 取值并订阅（`context.watch(model)`，与 Dart 的 `Consumer` 口径一致），
/// 再调用拥有者组件上的 `props.builder` 方法
/// （`_consumerBuilderN(context, value)`）渲染局部子树。
///
/// 本类仍必须订阅 VM：UI 的真正更新来自 **JS 侧重建**（VM notify → 标脏该位置
/// → 重读 `model.count` → 下发 patch）。宿主侧同时把这段子树映射成 Dart 的
/// 监听边界（`Consumer` 宿主结点），使 Dart 侧的 provider 子树也能刷新（P2）。
const String jsConsumerComponent = '''
export class Consumer {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    var notifier = context.watch(this.props.model);
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      console.warn('[Consumer] builder 不是闭包');
      return null;
    }
    var child = fn(context, notifier);
    return __h('Consumer', {
      model: this.props.model,
      notifier: notifier,
      child: child
    });
  }
}''';

/// ListenableBuilder：局部重建——订阅 `listenable`（**产物下发的是 listenable
/// 实例本身**，如 `this._model`，不是字段名）、模型 notify 时仅重建本结点子树
/// （`setState` 只标记本结点 dirty）。子树抽在拥有者组件的 `props.builder`
/// 方法（`_lbBuilderN()`）里。与 Consumer 同理：JS 订阅是 UI 更新源，宿主映射
/// 只提供 Dart 侧边界。
const String jsListenableBuilderComponent = '''
export class ListenableBuilder {
  constructor(props) {
    this.props = props || {};
  }
  initState() {
    var l = this.props.listenable;
    if (l && typeof l.addListener === 'function') {
      var self = this;
      this.__listenable = l;
      this.__listener = function () { self.setState(function () {}); };
      l.addListener(this.__listener);
    }
  }
  build(context) {
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      console.warn('[ListenableBuilder] builder 不是闭包');
      return null;
    }
    return __h('ListenableBuilder', { notifier: this.props.listenable, child: fn(context) });
  }
  dispose() {
    if (this.__listenable && this.__listener) {
      this.__listenable.removeListener(this.__listener);
    }
  }
}''';

/// ValueListenableBuilder：与 ListenableBuilder 完全同构（同一订阅/局部重建
/// 机制），只多一步——把 `valueListenable.value` 作为 builder 的第二个实参传下去
/// （`builder(context, value, child)`），与 Dart 的
/// `builder: (context, value, child) => …` 形参语义一致。
///
/// 订阅对象是 ValueNotifier（JS 侧 extends ChangeNotifier，句柄 kind 复用
/// `notifier/ChangeNotifier`），故 `addListener` / 宿主映射与 ListenableBuilder 同一套。
const String jsValueListenableBuilderComponent = '''
export class ValueListenableBuilder {
  constructor(props) {
    this.props = props || {};
  }
  initState() {
    this.__subscribe(this.props.valueListenable);
  }
  didUpdateWidget() {
    var next = this.props.valueListenable;
    if (next !== this.__listenable) { this.__subscribe(next); }
  }
  __subscribe(l) {
    if (this.__listenable && this.__listener) {
      this.__listenable.removeListener(this.__listener);
    }
    this.__listenable = l;
    this.__listener = null;
    if (l && typeof l.addListener === 'function') {
      var self = this;
      this.__listener = function () { self.setState(function () {}); };
      l.addListener(this.__listener);
    }
  }
  build(context) {
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      console.warn('[ValueListenableBuilder] builder 不是闭包');
      return null;
    }
    var l = this.props.valueListenable;
    var value = (l && l.value !== undefined) ? l.value : null;
    return __h('ValueListenableBuilder', {
      notifier: l,
      child: fn(context, value, this.props.child)
    });
  }
  dispose() {
    if (this.__listenable && this.__listener) {
      this.__listenable.removeListener(this.__listener);
    }
  }
}''';

/// AnimatedBuilder：与 ListenableBuilder 同一套「订阅 → 局部重建」机制（Animation
/// 是 Listenable，JS 侧 `AnimationController` 镜像由宿主逐帧回传 value 后
/// `__notify`），区别只是订阅键是 `animation`：
///   - 订阅 `props.animation`，动画帧到达时只重建本结点子树；
///   - builder 形参是 `(context, child)`，子树抽在 `props.builder` 方法里，child
///     作为独立子结点由宿主映射直传（与 Dart 侧 `child:` 语义一致）。
const String jsAnimatedBuilderComponent = '''
export class AnimatedBuilder {
  constructor(props) {
    this.props = props || {};
  }
  initState() {
    var a = this.props.animation;
    if (a && typeof a.addListener === 'function') {
      var self = this;
      this.__animation = a;
      this.__listener = function () { self.setState(function () {}); };
      a.addListener(this.__listener);
    }
  }
  build(context) {
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      console.warn('[AnimatedBuilder] builder 不是闭包');
      return null;
    }
    return __h('AnimatedBuilder', { child: fn(context, this.props.child) });
  }
  dispose() {
    if (this.__animation && this.__listener) {
      this.__animation.removeListener(this.__listener);
    }
  }
}''';

/// TweenAnimationBuilder：**隐式动画**，语义与 Flutter 的
/// `_TweenAnimationBuilderState` 一一对应：
///   - 首帧价值显示 `tween.begin`（begin 为 null 时取 end）；begin != end 时
///     **立刻 forward**（Flutter 的 initState 就是这么做的），begin == end 才
///     静止在那里；
///   - `tween.end` 变化 → begin 改成「当前显示值」、进度归零后 forward，所以
///     动画途中改目标不会跳变；
///   - 每帧按 `curve` 弯曲进度，再用 `tween.lerp` 求值，只重建本结点子树；
///   - 进度到 1 调 `onEnd` 一次（对应 Flutter 的 status.isCompleted）。
///
/// 动画进度由 JS 侧的 `AnimationController` 镜像驱动（宿主逐帧回传 value，
/// 与 AnimatedBuilder 同一机制），因此不新增任何宿主 widget。
const String jsTweenAnimationBuilderComponent = '''
// Duration 可能是 JS 的 Duration 实例，也可能是裸毫秒数。
function __tabMs(d) {
  if (d == null) { return null; }
  if (typeof d === 'number') { return d; }
  if (typeof d === 'object' && typeof d.inMilliseconds === 'number') {
    return d.inMilliseconds;
  }
  return null;
}

// 值相等判定：数字直接比；Offset 这类值对象按分量比（每次 build 都会新建
// 实例，不能靠引用相等，否则每帧都被当成「目标变了」重新起动画）。
function __tabSame(a, b) {
  if (a === b) { return true; }
  if (a && b && typeof a.dx === 'number' && typeof b.dx === 'number') {
    return a.dx === b.dx && a.dy === b.dy;
  }
  return false;
}

export class TweenAnimationBuilder {
  constructor(props) {
    this.props = props || {};
  }
  initState() {
    var p = this.props;
    var self = this;
    this.__tabTween = p.tween || new Tween({});
    this.__tabValue = this.__tabTween.begin != null
      ? this.__tabTween.begin
      : this.__tabTween.end;
    var ctrl = new AnimationController({ duration: p.duration, value: 0 });
    this.__tabCtrl = ctrl;
    this.__tabCurved = new CurvedAnimation({
      parent: ctrl,
      curve: p.curve || 'linear'
    });
    this.__tabListener = function () {
      self.__tabValue = self.__tabTween.lerp(self.__tabCurved.value);
      self.setState(function () {});
      if (ctrl.value >= 1 && !self.__tabEnded) {
        self.__tabEnded = true;
        __invokeCallback(self.props.onEnd, []);
      }
    };
    ctrl.addListener(this.__tabListener);
    // 与 Flutter 的 initState 一致：begin != end 时进入即播（如 Tween(0 → 1)
    // 进场就有动画，onEnd 也会在到位时触发一次）。
    if (!__tabSame(this.__tabTween.begin, this.__tabTween.end)) {
      this.__tabEnded = false;
      ctrl.forward();
    }
  }
  didUpdateWidget() {
    var p = this.props;
    var next = p.tween || new Tween({});
    var prev = this.__tabTween || new Tween({});
    var ms = __tabMs(p.duration);
    if (ms != null && ms !== this.__tabCtrl.durationMs) {
      this.__tabCtrl.durationMs = ms;
    }
    // 同一段动画进行中父级重建时，目标没变就继续用原 tween——换成新实例会把
    // begin 退回源值，正在跑的进度就会跳变。
    if (!__tabSame(next.end, prev.end)) {
      next.begin = this.__tabValue;
      this.__tabTween = next;
      this.__tabEnded = false;
      this.__tabCtrl.reset();
      this.__tabCtrl.forward();
    }
  }
  build(context) {
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      console.warn('[TweenAnimationBuilder] builder 不是闭包');
      return null;
    }
    return fn(context, this.__tabValue, this.props.child);
  }
  dispose() {
    if (this.__tabCtrl) {
      this.__tabCtrl.removeListener(this.__tabListener);
      this.__tabCtrl.dispose();
    }
  }
}''';

/// package 模块产物：把该 package 里**有 JS 类**的 widget 类型导出为 JS 类
/// （逻辑组件：provider 状态处理 / Builder 委托；sliver builder 代理）。
///
/// 宿主 widget（Text/Column/...）**不产出任何代码**：它们的元素 type 就是类型名
/// 字符串（`__h('Text', {...})`），由宿主注册表映射成 Flutter widget；
/// 本模块只在有 JS 逻辑时才有存在意义。
///
/// 一个 package 一个文件（文件名即包名）。共用元素工厂 `__h` / 归一化
/// `__asElement` 只在其宿主包（[nodeHelperPackage]）里定义一次，其它包从
/// `<host>.js` 相对 import。
/// 产物自包含（不依赖运行时 `__jsui`），宿主既有渲染路径与 JS 运行时都能
/// 消费同一份产物。
String renderPackageModule(String package, Set<String> types) {
  final sorted = types.toList()..sort();
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// package 模块（package: $package）：由 hot_patch_generator 生成')
    ..writeln('// 本包内有 JS 类的 widget（逻辑组件 / sliver 代理）集中于此文件')
    ..writeln();
  if (package == nodeHelperPackage) {
    b
      ..writeln(jsNodeHelperSource())
      ..writeln();
    // 宿主包装类：`new Text({...})` → `__h('Text', {...})`。翻译层因此可以对
    // 所有 widget 构造统一发射 `new Type(props)`，产物里不再出现 `__h('X', …)`。
    for (final t in hostWrapperTypes.toList()..sort()) {
      b
        ..writeln()
        ..writeln(hostWrapperSource(t));
    }
  } else {
    final nodeRel = relativeProduct(
      packageModulePath(package),
      packageModulePath(nodeHelperPackage),
    );
    b
      ..writeln("import { __h, __asElement } from '$nodeRel';")
      ..writeln();
  }
  for (final t in sorted) {
    // 值类（不是 widget、不产出元素）：只导出普通类，使用方 `new X({...})`。
    final value = valueClassSources[t];
    if (value != null) {
      b
        ..writeln()
        ..writeln(value);
      continue;
    }
    // 逻辑 widget（provider 状态处理 / Builder 委托）：状态与订阅逻辑全部在
    // JS 侧，本包导出普通类，元素 type 即该类，宿主零感知。
    final logic = logicWidgetSources[t];
    if (logic != null) {
      b
        ..writeln()
        ..writeln(logic)
        ..writeln(logicCtorStatics(t));
      continue;
    }
    // builder 命名构造代理（`.builder` / `.separated`）：元素 type 是类引用，
    // build 时循环调用拥有者方法收集子树；普通构造与 `delegate:` 形态由渲染层
    // 直接产出宿主节点（`__h('SliverList', ...)`），不经过本类。
    if (builderFormTypes.contains(t)) {
      b
        ..writeln()
        ..writeln(builderProxySource(t));
    }
  }
  // 随组件下发的 State 代理类（`GlobalKey.currentState` 的方法属于具体组件）：
  // 紧挨该组件的包装类写出，运行时只负责按 runtimeType 取类。
  for (final t in sorted) {
    final src = stateProxySources[t];
    if (src == null) continue;
    b
      ..writeln()
      ..writeln(src);
  }
  // -----------------------------------------------------------------------
  // Dart 值类区：**固定在产物最末**（所有 widget / 逻辑组件包装类之后）。
  //
  // 分区判据是「这是不是 Dart / Flutter 的值类型」——`Duration` / `Size` /
  // `Offset` / `Color` / `TextStyle` / `ChangeNotifier` / 各 Controller / `Key` /
  // 枚举镜像 / `Colors` 常量表。它们是产物里 `new X({...})` 的落点，与上面的
  // widget 包装类**用途不同**（包装类产出元素描述，值类承载数据），因此单独
  // 成区并置于末尾：读产物时先看到 UI 结构，再看数据类型。
  //
  // 顺序约束（区内）：值类 → 枚举镜像 → Colors。`__mc` 在求值期就
  // `new MaterialColor(...)`，而 MaterialColor 的原型在值类区赋值——晚于实例
  // 创建就会丢 toJSON。
  //
  // 与 runtime 的唯一耦合面是 `G.__core`（原型补丁 / 控制器注册 / 句柄表），
  // 见 runtime_js.dart 的【11.5】——跨模块只走 G，不假设同一 IIFE 作用域。
  if (package == nodeHelperPackage) {
    b
      ..writeln()
      ..writeln('// ===== Dart 值类（值对象 / Controller / 动画 / Key / 枚举）=====')
      ..writeln('// 翻译层对它们一律 `new X({...})` / `X.member`；')
      ..writeln('// 跨桥经各自 toJSON 输出宿主协议（不在这里做任何 JSON 拍平）。')
      ..writeln('const G = globalThis;')
      ..writeln('const {')
      ..writeln('  defineProtoGetter: __defineProtoGetter,')
      ..writeln('  defineController, defineHandleKind, handleOp, reg,')
      ..writeln('} = G.__core;')
      ..writeln()
      ..writeln(flutterValueClassesSource());
    // Colors 常量（SDK colors.dart 自动抽取）：`Colors.red` / `Colors.red[400]`
    // 在 JS 侧原样求值，翻译层不含任何色值表；新增颜色重构建即生效。
    final colors = colorsJsSource();
    if (colors != null) {
      b
        ..writeln()
        ..writeln(colors);
    } else {
      // ignore: avoid_print - 构建期日志
      print('[hot_patch_generator] 未能定位 Flutter SDK colors.dart，'
          'Colors 常量未注入（产物里 Colors.* 会解析失败）');
    }
  }
  return b.toString();
}
