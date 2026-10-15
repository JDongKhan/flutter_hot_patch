/// package 模块 builder：把**每个 package** 的全部已注册 widget 类型产出为
/// 一个共享 JS 模块 `patch/<package>.js`（工厂函数 + 逻辑组件类，全局唯一
/// 一份，消除各组件产物里内联同类工厂函数造成的重复与文件爆炸）。
library;

import 'dart:async';

import 'package:build/build.dart';

import '../../translator/builtin_translators.dart';
import '../../translator/widget2js.dart';

import '../js_widget_defs.dart';
import '../product_path.dart';

/// widget 模块 builder 的**种子输入默认路径**（构建期固定文件，不含运行时代码）。
///
/// build_runner 的输出名必须在 buildExtensions 里静态声明，无法按构建期发现
/// 的类型动态命名，因此把「全部 package 模块产物」挂在本文件下，包清单由
/// [registeredWidgetPackages] 静态推导。
///
/// 该路径可由使用方 `build.yaml` 的 `options: { seed_file: ... }` 覆盖
/// （见 [seedPathFrom]）；使用方**必须**在包内提供该种子文件。
const String defaultSeedPath = 'lib/js_widgets.dart';

/// 从 builder options 读取种子输入路径：`options: { seed_file: <path> }`，
/// 缺省或非法值回退 [defaultSeedPath]。
String seedPathFrom(BuilderOptions options) {
  final value = options.config['seed_file'];
  if (value is String && value.isNotEmpty) return value;
  return defaultSeedPath;
}

/// 已注册 widget 类型 → (package → {type})：由 translator 注册表推导，
/// 作为 package 模块产物清单（每个包一个文件）的唯一来源。
Map<String, Set<String>> registeredWidgetPackages() {
  final registry = WidgetTranslatorRegistry();
  registerBuiltinTranslators(registry);
  final out = <String, Set<String>>{};
  for (final t in registry.registeredTypes) {
    final tr = registry.lookup(t);
    if (tr == null) continue;
    (out[tr.packageName] ??= <String>{}).addAll(tr.jsonTypes);
  }
  return out;
}

/// widget 模块 builder：把**每个 package** 的全部已注册 widget 类型产出为
/// 一个共享 JS 模块 `patch/<package>.js`（工厂函数 + 逻辑组件类，全局唯一
/// 一份，消除各组件产物里内联同类工厂函数造成的重复与文件爆炸）。
///
/// 输出挂在种子输入 [seedPath] 下（默认 [defaultSeedPath]，可由使用方
/// `build.yaml` 的 `options: { seed_file: ... }` 覆盖）；输出名从
/// [registeredWidgetPackages] 静态推导，构建时按包名渲染整包即可。
///
/// **使用方必须提供该种子文件**——本 builder 无降级路径，缺少种子输入即
/// 不产出任何 package 模块，组件产物的 import 会因此悬空。
class WidgetModuleBuilder implements Builder {
  const WidgetModuleBuilder({this.seedPath = defaultSeedPath});

  /// 种子输入路径（见 [defaultSeedPath]），可由 builder options 覆盖。
  final String seedPath;

  @override
  Map<String, List<String>> get buildExtensions {
    final pkgs = <String>{
      // `__h` 宿主（基础包 flutter）即使未注册任何 flutter widget 也要产出。
      nodeHelperPackage,
      ...registeredWidgetPackages().keys,
    }.toList()
      ..sort();
    return {
      '^$seedPath': [for (final p in pkgs) packageModulePath(p)],
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
/// 源码（类名 = Dart 类型名）：`props.builder` 是拥有者组件上的
/// `_xxxBuilderN(index)` 方法名、`props.separatorBuilder`（`.separated` 形态）
/// 是分隔项方法名、计数键为 `itemCount`（命名构造）或 `childCount`
/// （`SliverChildBuilderDelegate` 形态）；build 时循环调用收集子树，包回同名的
/// 宿主节点——children 交给宿主按原生 `ListView.builder` / `SliverList.builder`
/// / `GridView.builder` / `SliverChildBuilderDelegate` 还原。与 ListenableBuilder
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
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
  }
  build(context) {
    var owner = this.__owner();
    if (!owner) { return null; }
    var out = [];
    // 计数键兼容两种写法：命名构造的 itemCount / delegate 形态的 childCount。
    var n = this.props.childCount !== undefined
        ? this.props.childCount
        : (this.props.itemCount || 0);
    // `.separated` 形态：item / separator 首尾交替展开（n 项 → 2n-1 个子节点）。
    var sep = this.props.separatorBuilder;
    for (var i = 0; i < n; i++) {
      out.push(owner[this.props.builder].call(owner, context, i));
      if (sep && i < n - 1) { out.push(owner[sep].call(owner, context, i)); }
    }
    // props 原样透传（含 builder/separatorBuilder/childCount/itemCount）：宿主据
    // `builder` 判定 builder 形态，并据此还原 Flutter 原生命名构造。
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

/// ChangeNotifierProvider：解析 create/value 得到 VM，然后**交给宿主**。
///
/// JS 侧不做任何 provider 记账（无 `__provides`）：本类只负责
///   ① 造/取 VM（`create` 为类引用时 new 一次，生命周期归本类；实例时复用）；
///   ② 渲染宿主结点 `ChangeNotifierProvider`，props 带 `{model, vm}`——
///      宿主据此建 Dart 侧的 provider 映射（通用 VM 镜像 + provider 子树），
///      `context.watch<T>()` 的 T 就是这里的 `model`（类型名一路传给宿主）。
/// VM 的真实对象只存在于 JS 端：`vm` 走句柄（`{__handle:id}`）下发。
const String jsChangeNotifierProviderComponent = '''
export class ChangeNotifierProvider {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  initState() {
    var p = this.props;
    var vm = null, owns = false;
    if (p.create !== undefined && p.create !== null) {
      if (typeof p.create === 'function') { vm = new p.create(); }
      else { vm = p.create; }
      owns = true;
    } else if (p.value !== undefined && p.value !== null) {
      vm = p.value;
    }
    this.__value = vm;
    this.__ownsValue = owns;
  }
  build() {
    // child 两种传入方式：直接使用时是 `props.child`（命名参数翻译成 prop）；
    // 被 MultiProvider 包裹时由 `__h(type, props, [node])` 放进 children。
    var child = this.props.child != null ? this.props.child
        : (this.children.length ? this.children[0] : null);
    return __h('ChangeNotifierProvider', { model: this.props.model, vm: this.__value }, [child]);
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

/// Consumer：消费 VM——沿祖先找最近 provider 的 VM 并订阅（watch），再调用拥有者
/// 组件上的 `props.builder` 方法（`_consumerBuilderN(context, value)`）渲染局部子树。
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
    var vm = context.watch(this.props.model);
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    var child = owner[name].call(owner, context, vm);
    return __h('Consumer', { model: this.props.model, vm: vm }, [child]);
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
    return __h('ListenableBuilder', { vm: owner[this.props.listenable] }, [child]);
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
    ..writeln('// package 模块（package: $package）：由 ui_component_generator 生成')
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