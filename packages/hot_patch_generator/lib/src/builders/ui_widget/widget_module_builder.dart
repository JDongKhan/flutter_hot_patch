/// package 模块 builder：把**每个 package** 的全部已注册 widget 类型产出为
/// 一个共享 JS 模块 `patch/<package>.js`（工厂函数 + 逻辑组件类，全局唯一
/// 一份，消除各组件产物里内联同类工厂函数造成的重复与文件爆炸）。
library;

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import '../shared/js_widget_defs.dart';
import '../shared/paths.dart';

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
        renderPackageModule(pkg, packages[pkg] ?? const <String>{}),
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
// 懒容器配置（**构建期唯一事实源**：shared/js_widget_defs.dart 的
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

/// 宿主包装类源码：类名 = 宿主类型名，构造即产出元素描述（type 仍是**字符串**）。
/// 宿主结点的实例化由宿主注册表完成，reconciler 从不 `new` 这个类。
String hostWrapperSource(String type) => '''
export class $type {
  constructor(props) {
    return __h('$type', props);
  }
}''';

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
  return '''
export class $type {
  constructor(props) {
    this.props = props || {};
  }
  __owner() {
    var name = this.props.itemBuilder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
  }
  build(context) {
    var owner = this.__owner();
    if (!owner) { return null; }
    // props 原样透传（含 itemBuilder/separatorBuilder/itemCount/factory）；
    // 展开描述走内部键 __builder，由 __h 归入 children，宿主 renderer 不感知。
    var p = {};
    for (var k in this.props) { p[k] = this.props[k]; }
    p.__builder = {
      item: this.props.itemBuilder,
      sep: this.props.separatorBuilder || null,
      count: this.props.itemCount || 0,
      ctx: context
    };
    return __h('$type', p);
  }
}''';
}

/// 「逻辑 widget」类型 → JS 类源码（在本模块里内联一个普通类，类名 = Dart 名）。
///
/// 与宿主 type 节点不同：这些 widget 的**状态/订阅逻辑必须跑在 JS 里**，
/// 因此元素写成 `__h(<类名>, props, children)`（类引用，由本模块 export），
/// 运行时 `new` 该组件类并按组件路径挂载，由组件 `build()` 自行消费 props
/// （provider 提供/消费 VM、Builder 委托拥有者方法返回子树）。运行时会给普通
/// 类实例补挂 `props/setState/context/__bindFn`
/// （见 js_ui/runtime_js.dart）。键集合与 js_widget_defs 的
/// `logicWidgetTypes` 一致。
const Map<String, String> logicWidgetSources = {
  'Builder': jsBuilderComponent,
  'ChangeNotifierProvider': jsChangeNotifierProviderComponent,
  'MultiProvider': jsMultiProviderComponent,
  'Consumer': jsConsumerComponent,
  'ListenableBuilder': jsListenableBuilderComponent,
  'ValueListenableBuilder': jsValueListenableBuilderComponent,
  'AnimatedBuilder': jsAnimatedBuilderComponent,
};

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
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    return owner[name].call(owner, context);
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
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    var child = owner[name].call(owner, context, notifier);
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
  __owner() {
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
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
    var owner = this.__owner();
    if (!owner) { return null; }
    var child = owner[this.props.builder].call(owner, context);
    return __h('ListenableBuilder', { notifier: this.props.listenable, child: child });
  }
  dispose() {
    if (this.__listenable && this.__listener) {
      this.__listenable.removeListener(this.__listener);
    }
  }
}''';

/// ValueListenableBuilder：与 ListenableBuilder 完全同构（同一订阅/局部重建
/// 机制），只多一步——把 `listenable.value` 作为 builder 的第二个实参传下去
/// （`owner[props.builder].call(owner, context, value)`），与 Dart 的
/// `builder: (context, value, child) => …` 形参语义一致。
///
/// 订阅对象是 ValueNotifier（JS 侧 extends ChangeNotifier，句柄 kind 复用
/// `notifier/ChangeNotifier`），故 `addListener` / 宿主映射与 ListenableBuilder 同一套。
const String jsValueListenableBuilderComponent = '''
export class ValueListenableBuilder {
  constructor(props) {
    this.props = props || {};
  }
  __owner() {
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
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
    var owner = this.__owner();
    if (!owner) { return null; }
    var l = this.props.listenable;
    var value = (l && l.value !== undefined) ? l.value : null;
    var child = owner[this.props.builder].call(owner, context, value);
    return __h('ValueListenableBuilder', { notifier: l, child: child });
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
  __owner() {
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
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
    var owner = this.__owner();
    if (!owner) { return null; }
    var child = owner[this.props.builder].call(owner, context, this.props.child);
    return __h('AnimatedBuilder', { child: child });
  }
  dispose() {
    if (this.__animation && this.__listener) {
      this.__animation.removeListener(this.__listener);
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
    // 逻辑 widget（provider 状态处理 / Builder 委托）：状态与订阅逻辑全部在
    // JS 侧，本包导出普通类，元素 type 即该类，宿主零感知。
    final logic = logicWidgetSources[t];
    if (logic != null) {
      b
        ..writeln()
        ..writeln(logic);
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
  return b.toString();
}
