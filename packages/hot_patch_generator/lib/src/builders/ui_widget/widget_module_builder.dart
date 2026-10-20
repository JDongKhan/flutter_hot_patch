/// package 模块 builder：把**每个 package** 的全部已注册 widget 类型产出为
/// 一个共享 JS 模块 `patch/<package>.js`（工厂函数 + 逻辑组件类，全局唯一
/// 一份，消除各组件产物里内联同类工厂函数造成的重复与文件爆炸）。
library;

import 'dart:async';

import 'package:build/build.dart';

import '../js_widget_defs.dart';
import '../product_path.dart';

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
    }.toList()
      ..sort();
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

/// 共享结点工厂源码：`export function __h(...)`，归一化 props/children，
/// 返回 {type, props, children} 元素描述（与 JSON 字面量树同形状）。它是
/// [nodeHelperPackage] 包模块的一部分，全局只有这一处定义。
const String jsNodeHelperSource = '''
// 共享结点工厂：所有 package 模块与组件产物共用（本文件是它的唯一定义处）。
// 归一化 props/children，返回 {type, props, children} 元素描述，供运行时按
// type 映射 Flutter widget 或组件类。
export function __h(type, props, children) {
  return {
    type: type,
    props: props || {},
    children: children == null
        ? []
        : (Array.isArray(children) ? children : [children]),
  };
}''';

/// builder/factory 形态（`X.builder(...)` / `X.separated(...)`）的 JS 侧代理类
/// 源码（类名 = Dart 类型名）：道具**按 Dart 形参名**下发（统一翻译不改名），
/// 故回调方法名取 `props.itemBuilder`（命名构造的一致参数名；`delegate:
/// SliverChildBuilderDelegate(...)` 形态的是 `props.builder`）、分隔项方法名取
/// `props.separatorBuilder`、计数键为 `itemCount`（命名构造）或 `childCount`
/// （delegate 形态）；`props.factory` 是命名构造名（`builder` / `separated`），
/// 原样透传给宿主供其还原原生构造。build 时循环调用收集子树，包回同名的宿主
/// 节点——children 交给宿主按原生 `ListView.builder` / `SliverList.builder` /
/// `GridView.builder` / `SliverChildBuilderDelegate` 还原。与 ListenableBuilder
/// 的 `__owner()` 向上找拥有者方法机制一致。
///
/// 只在 builder 形态下被渲染层引用（普通 children/delegate 形态直接是宿主节点
/// `__h('SliverList', ...)`），因此 build 无需再判形态。
///
/// 被委托方法的第一个实参是 **build 的 `context` 形参**（运行时统一
/// `inst.build(contextOf(inst))` 传入，锚点就是本代理组件自身的结点，与 Dart 侧
/// `ListView.builder(itemBuilder: (context, i) => …)` 的形参同源），无需再自行查找。
String builderProxySource(String type) {
  return '''
export class $type {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  __owner() {
    var name = this.props.itemBuilder || this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
  }
  build(context) {
    var owner = this.__owner();
    if (!owner) { return null; }
    var name = this.props.itemBuilder || this.props.builder;
    var out = [];
    // 计数键兼容两种写法：命名构造的 itemCount / delegate 形态的 childCount。
    var n = this.props.childCount !== undefined
        ? this.props.childCount
        : (this.props.itemCount || 0);
    // `.separated` 形态：item / separator 首尾交替展开（n 项 → 2n-1 个子节点）。
    var sep = this.props.separatorBuilder;
    for (var i = 0; i < n; i++) {
      out.push(owner[name].call(owner, context, i));
      if (sep && i < n - 1) { out.push(owner[sep].call(owner, context, i)); }
    }
    // props 原样透传（含 itemBuilder/separatorBuilder/childCount/itemCount/factory）：
    // 宿主据回调键判定 builder 形态，据 factory 还原 Flutter 原生命名构造。
    return __h('$type', this.props, out);
  }
}''';
}

/// 「逻辑 widget」类型 → JS 类源码（在本模块里内联一个普通类，类名 = Dart 名）。
///
/// 与宿主 type 节点不同：这些 widget 的**状态/订阅逻辑必须跑在 JS 里**，
/// 因此元素写成 `__h(<类名>, props, children)`（类引用，由本模块 export），
/// 运行时 `new` 该组件类并按组件路径挂载，由组件 `build()` 自行消费 props
/// （provider 提供/消费 VM、Builder 委托拥有者方法返回子树）。运行时会给普通
/// 类实例补挂 `props/setState/context/__bind`
/// （见 js_ui/runtime_source.dart）。键集合与 js_widget_defs 的
/// `logicWidgetTypes` 一致。
const Map<String, String> logicWidgetSources = {
  'Builder': jsBuilderComponent,
  'ChangeNotifierProvider': jsChangeNotifierProviderComponent,
  'MultiProvider': jsMultiProviderComponent,
  'Consumer': jsConsumerComponent,
  'ListenableBuilder': jsListenableBuilderComponent,
  'ValueListenableBuilder': jsValueListenableBuilderComponent,
};

/// Builder：无状态委托组件——调用拥有者组件上的 `props.builder` 方法
/// （`_builderN(context)`，含 `var model = context.watch(...)` 前置语句）拿子树。
/// 传下去的 context 就是 **build 收到的形参**（本组件自身的 BuildContext 代理，
/// 与 Dart 侧 `Builder(builder: (context) => …)` 的形参一致）。
const String jsBuilderComponent = '''
export class Builder {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
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
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
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
    // child 两种传入方式：直接使用时是 `props.child`（命名参数翻译成 prop）；
    // 被 MultiProvider 包裹时由 `__h(type, props, [node])` 放进 children。
    var child = this.props.child != null ? this.props.child
        : (this.children.length ? this.children[0] : null);
    return __h('ChangeNotifierProvider', { model: this.props.model, notifier: this.__value }, [child]);
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
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  build() {
    var provs = this.props.providers || [];
    var node = this.props.child;
    for (var i = provs.length - 1; i >= 0; i--) {
      node = __h(provs[i].type, provs[i].props, [node]);
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
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  build(context) {
    var notifier = context.watch(this.props.model);
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    var child = owner[name].call(owner, context, notifier);
    return __h('Consumer', { model: this.props.model, notifier: notifier }, [child]);
  }
}''';

/// ListenableBuilder：局部重建——订阅 `listenable`（拥有者组件上的模型字段），
/// 模型 notify 时仅重建本结点子树（`setState` 只标记本结点 dirty）。
/// 子树抽在拥有者组件的 `props.builder` 方法（`_lbBuilderN()`）里。
/// 与 Consumer 同理：JS 订阅是 UI 更新源，宿主映射只提供 Dart 侧边界。
const String jsListenableBuilderComponent = '''
export class ListenableBuilder {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  __owner() {
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
  }
  initState() {
    var owner = this.__owner();
    if (!owner) { return; }
    var l = owner[this.props.listenable];
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
    return __h('ListenableBuilder', { notifier: owner[this.props.listenable] }, [child]);
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
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  __owner() {
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
  }
  initState() {
    var owner = this.__owner();
    if (!owner) { return; }
    var l = owner[this.props.listenable];
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
    var l = owner[this.props.listenable];
    var value = (l && l.value !== undefined) ? l.value : null;
    var child = owner[this.props.builder].call(owner, context, value);
    return __h('ValueListenableBuilder', { notifier: l }, [child]);
  }
  dispose() {
    if (this.__listenable && this.__listener) {
      this.__listenable.removeListener(this.__listener);
    }
  }
}''';

/// package 模块产物：把该 package 里**有 JS 类**的 widget 类型导出为 JS 类
/// （逻辑组件：provider 状态处理 / Builder 委托；sliver builder 代理）。
///
/// 宿主 widget（Text/Column/...）**不产出任何代码**：它们的元素 type 就是类型名
/// 字符串（`__h('Text', {...}, [...])`），由宿主注册表映射成 Flutter widget；
/// 本模块只在有 JS 逻辑时才有存在意义。
///
/// 一个 package 一个文件（文件名即包名）。共用元素工厂 `__h` 只在其宿主包
/// （[nodeHelperPackage]）里定义一次，其它包从 `<host>.js` 相对 import。
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
      ..writeln(jsNodeHelperSource)
      ..writeln();
  } else {
    final nodeRel =
        relativeProduct(packageModulePath(package), packageModulePath(nodeHelperPackage));
    b
      ..writeln("import { __h } from '$nodeRel';")
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
    // Sliver builder 代理：`SliverList({builder, childCount})` 形态
    // 走本类（build 时循环调用拥有者方法收集子树）；普通形态由渲染层直接
    // 产出宿主节点（`__h('SliverList', ...)`），不经过本类。
    if (builderFormTypes.contains(t)) {
      b
        ..writeln()
        ..writeln(builderProxySource(t));
    }
  }
  return b.toString();
}