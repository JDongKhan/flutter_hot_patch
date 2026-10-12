/// 「有 JS 类的 widget」定义：逻辑组件（provider 状态处理 / Builder 委托）、
/// sliver builder 代理，以及它们的 JS 源码与类型集合。
///
/// 这些类型在 JS 侧有真实的类实现（元素 type 用**类引用**），与宿主 widget
/// （Text/Column/... 元素 type 是字符串字面量）区分开。本文件是这些类型与
/// 源码的**唯一事实源**，供 package 模块渲染、组件产物渲染共用。
library;

/// 共享结点工厂 `__h` 的宿主 package：并入基础包 flutter 的模块
/// （`patch/flutter.js`）。其它 package 模块与组件产物统一从它
/// `import { __h }`，使 `__h` 全局只定义一次。
const String nodeHelperPackage = 'flutter';

/// package 模块产物路径：`patch/<package>.js`（**一个 package 一个文件**）。
///
/// 这类产物是 **package 级**（`flutter` / `provider` 等，与 lib 源码目录无关），
/// 因此直接落在 patch 根下；而组件/模型产物落在 `patch/` 下镜像 lib 源码路径。
/// 同包的 widget 工厂/逻辑组件集中在一个文件里，避免按类型拆成大量小文件难以
/// 维护，也天然只保留一份实现。
String packageModulePath(String package) => 'patch/$package.js';

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

/// 支持 builder/factory 写法的滚动视图与 sliver 组件（产物带
/// `delegateBuilder` 时走内联代理组件，普通 children 形态走宿主节点）。
const Set<String> sliverBuilderTypes = {
  'GridView',
  'SliverList',
  'SliverGrid',
  'SliverFixedExtentList',
  'SliverFillViewport',
};

/// SliverChildBuilderDelegate 的 JS 侧代理类源码（类名 = Dart 类型名）：
/// `props.delegateBuilder` 是拥有者组件上的 `_sliverBuilderN(index)` 方法名、
/// `childCount` 指定数量；build 时循环调用收集子树，包回同名的宿主节点
/// （children 交给宿主 SliverChildListDelegate 还原）。与 ListenableBuilder 的
/// `__owner()` 向上找拥有者方法机制一致。
///
/// 只在 `.builder` 懒加载形态下被渲染层引用（普通形态直接是宿主节点
/// `__h('SliverList', ...)`），因此 build() 无需再判形态。
String sliverBuilderSource(String type) {
  return '''
export class $type {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  __owner() {
    var name = this.props.delegateBuilder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
  }
  build() {
    var owner = this.__owner();
    if (!owner) { return null; }
    var out = [];
    // 计数键兼容两种写法：sliver 的 childCount / GridView.builder 的 itemCount。
    var n = this.props.childCount !== undefined
        ? this.props.childCount
        : (this.props.itemCount || 0);
    for (var i = 0; i < n; i++) { out.push(owner[this.props.delegateBuilder].call(owner, i)); }
    var p = {};
    for (var k in this.props) {
      if (k !== 'delegateBuilder' && k !== 'childCount' && k !== 'itemCount') {
        p[k] = this.props[k];
      }
    }
    return __h('$type', p, out);
  }
}''';
}

/// 「逻辑 widget」类型 → JS 类源码（在本模块里内联一个普通类，类名 = Dart 名）。
///
/// 与宿主 type 节点不同：这些 widget 的**状态/订阅逻辑必须跑在 JS 里**，
/// 因此元素写成 `__h(<类名>, props, children)`（类引用，由本模块 export），
/// 运行时 `new` 该组件类并按组件路径挂载，由组件 `build()` 自行消费 props
/// （provider 提供/消费 VM、Builder 委托拥有者方法返回子树）。运行时会给普通
/// 类实例补挂 `props/setState/watch/read/__watch/__read/__bind`
/// （见 js_ui/runtime_source.dart）。
const Map<String, String> logicWidgetSources = {
  'Builder': jsBuilderComponent,
  'ChangeNotifierProvider': jsChangeNotifierProviderComponent,
  'MultiProvider': jsMultiProviderComponent,
  'Consumer': jsConsumerComponent,
  'ListenableBuilder': jsListenableBuilderComponent,
};

/// 「元素 type 是 JS 类」的 widget 类型集合 = 有 JS 类的类型（唯一事实源：
/// 逻辑 widget 表 + sliver 代理表）。渲染层据此决定元素 type 用类引用还是
/// 类型名字符串；宿主 widget 不在其中，零 import。
Set<String> get jsClassWidgetTypes =>
    {...sliverBuilderTypes, ...logicWidgetSources.keys};

/// Builder：无状态委托组件——调用拥有者组件上的 `props.builder` 方法
/// （`_builderN()`，含 `var model = this.__watch(...)` 前置语句）拿子树。
const String jsBuilderComponent = '''
export class Builder {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  build() {
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    return owner[name].call(owner);
  }
}''';

/// ChangeNotifierProvider：把 create/value 解析出的 VM 挂成「提供者结点」
/// （`__provides[model]` + `__value`）。provider 是**纯值结点：不监听、不
/// 记账**——订阅由消费者（`watch`）自己给 VM 挂监听并持有台账，notify 时只
/// 标记该订阅位置重建，作用域最小。生命周期与原生一致：`create` 语义下
/// provider 拥有 VM（类引用时 provider 内 new，实例时直接复用），卸载时
/// dispose；`value` 语义下不拥有、不释放。
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
    this.__provides = {};
    this.__provides[p.model] = this;
  }
  build() {
    // child 两种传入方式：直接使用时是 `props.child`（命名参数翻译成 prop）；
    // 被 MultiProvider 包裹时由 `__h(type, props, [node])` 放进 children。
    if (this.props.child != null) { return this.props.child; }
    return this.children.length ? this.children[0] : null;
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

/// Consumer：消费 VM——沿祖先找提供者取 VM 并订阅（watch），再调用拥有者
/// 组件上的 `props.builder` 方法（`_consumerBuilderN(value)`）渲染局部子树。
const String jsConsumerComponent = '''
export class Consumer {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  build() {
    var vm = this.watch(this.props.model);
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    return owner[name].call(owner, vm);
  }
}''';

/// ListenableBuilder：局部重建——订阅 `listenable`（拥有者组件上的模型字段），
/// 模型 notify 时仅重建本结点子树（`setState` 只标记本结点 dirty）。
/// 子树抽在拥有者组件的 `props.builder` 方法（`_lbBuilderN()`）里。
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
  build() {
    var owner = this.__owner();
    if (!owner) { return null; }
    return owner[this.props.builder].call(owner);
  }
  dispose() {
    if (this.__listenable && this.__listener) {
      this.__listenable.removeListener(this.__listener);
    }
  }
}''';