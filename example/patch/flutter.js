// GENERATED CODE - DO NOT EDIT
// package 模块（package: flutter）：由 hot_patch_generator 生成
// 本包内有 JS 类的 widget（逻辑组件 / sliver 代理）集中于此文件

// 共享结点工厂：所有 package 模块与组件产物共用（本文件是它的唯一定义处）。
// 元素对象统一由本函数产出，带 element: true 标记；props 值是否是 widget
// 只看这个标记，不做形状猜测。
// 懒容器配置（**构建期唯一事实源**：shared/js_widget_defs.dart 的
// lazyChildHostTypes）。运行时只认元素上的 lazyChildren 标记，不认识任何类型。
var __lazyChildHosts = {"TabBarView": true, "PageView": true, "GridView": true, "SliverGrid": true, "SliverFixedExtentList": true, "SliverFillViewport": true, "ListView": ["itemExtent"]};
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
}


export class Align {
  constructor(props) {
    return __h('Align', props);
  }
}

export class AnimatedAlign {
  constructor(props) {
    return __h('AnimatedAlign', props);
  }
}

export class AnimatedContainer {
  constructor(props) {
    return __h('AnimatedContainer', props);
  }
}

export class AnimatedCrossFade {
  constructor(props) {
    return __h('AnimatedCrossFade', props);
  }
}

export class AnimatedDefaultTextStyle {
  constructor(props) {
    return __h('AnimatedDefaultTextStyle', props);
  }
}

export class AnimatedOpacity {
  constructor(props) {
    return __h('AnimatedOpacity', props);
  }
}

export class AnimatedPadding {
  constructor(props) {
    return __h('AnimatedPadding', props);
  }
}

export class AnimatedPositioned {
  constructor(props) {
    return __h('AnimatedPositioned', props);
  }
  static fromRect(props) { return new AnimatedPositioned(Object.assign({}, props, { factory: 'fromRect' })); }
}

export class AnimatedRotation {
  constructor(props) {
    return __h('AnimatedRotation', props);
  }
}

export class AnimatedScale {
  constructor(props) {
    return __h('AnimatedScale', props);
  }
}

export class AnimatedSize {
  constructor(props) {
    return __h('AnimatedSize', props);
  }
}

export class AnimatedSlide {
  constructor(props) {
    return __h('AnimatedSlide', props);
  }
}

export class AnimatedSwitcher {
  constructor(props) {
    return __h('AnimatedSwitcher', props);
  }
}

export class AppBar {
  constructor(props) {
    return __h('AppBar', props);
  }
}

export class AspectRatio {
  constructor(props) {
    return __h('AspectRatio', props);
  }
}

export class BottomNavigationBar {
  constructor(props) {
    return __h('BottomNavigationBar', props);
  }
}

export class BottomNavigationBarItem {
  constructor(props) {
    return __h('BottomNavigationBarItem', props);
  }
}

export class CachedNetworkImage {
  constructor(props) {
    return __h('CachedNetworkImage', props);
  }
}

export class Card {
  constructor(props) {
    return __h('Card', props);
  }
  static filled(props) { return new Card(Object.assign({}, props, { factory: 'filled' })); }
  static outlined(props) { return new Card(Object.assign({}, props, { factory: 'outlined' })); }
}

export class Center {
  constructor(props) {
    return __h('Center', props);
  }
}

export class Checkbox {
  constructor(props) {
    return __h('Checkbox', props);
  }
  static adaptive(props) { return new Checkbox(Object.assign({}, props, { factory: 'adaptive' })); }
}

export class Chip {
  constructor(props) {
    return __h('Chip', props);
  }
}

export class CircleAvatar {
  constructor(props) {
    return __h('CircleAvatar', props);
  }
}

export class CircularProgressIndicator {
  constructor(props) {
    return __h('CircularProgressIndicator', props);
  }
  static adaptive(props) { return new CircularProgressIndicator(Object.assign({}, props, { factory: 'adaptive' })); }
}

export class ClipOval {
  constructor(props) {
    return __h('ClipOval', props);
  }
}

export class ClipRRect {
  constructor(props) {
    return __h('ClipRRect', props);
  }
}

export class Column {
  constructor(props) {
    return __h('Column', props);
  }
}

export class ConstrainedBox {
  constructor(props) {
    return __h('ConstrainedBox', props);
  }
}

export class Container {
  constructor(props) {
    return __h('Container', props);
  }
}

export class CustomScrollView {
  constructor(props) {
    return __h('CustomScrollView', props);
  }
}

export class DecoratedBox {
  constructor(props) {
    return __h('DecoratedBox', props);
  }
}

export class DefaultTabController {
  constructor(props) {
    return __h('DefaultTabController', props);
  }
}

export class Divider {
  constructor(props) {
    return __h('Divider', props);
  }
}

export class Drawer {
  constructor(props) {
    return __h('Drawer', props);
  }
}

export class DrawerHeader {
  constructor(props) {
    return __h('DrawerHeader', props);
  }
}

export class DropdownButton {
  constructor(props) {
    return __h('DropdownButton', props);
  }
  static _formField(props) { return new DropdownButton(Object.assign({}, props, { factory: '_formField' })); }
}

export class DropdownMenuItem {
  constructor(props) {
    return __h('DropdownMenuItem', props);
  }
}

export class EasyRefresh {
  constructor(props) {
    return __h('EasyRefresh', props);
  }
  static builder(props) { return new EasyRefresh(Object.assign({}, props, { factory: 'builder' })); }
}

export class ElevatedButton {
  constructor(props) {
    return __h('ElevatedButton', props);
  }
  static icon(props) { return new ElevatedButton(Object.assign({}, props, { factory: 'icon' })); }
}

export class Expanded {
  constructor(props) {
    return __h('Expanded', props);
  }
}

export class FadeTransition {
  constructor(props) {
    return __h('FadeTransition', props);
  }
}

export class FilledButton {
  constructor(props) {
    return __h('FilledButton', props);
  }
  static icon(props) { return new FilledButton(Object.assign({}, props, { factory: 'icon' })); }
  static tonal(props) { return new FilledButton(Object.assign({}, props, { factory: 'tonal' })); }
  static tonalIcon(props) { return new FilledButton(Object.assign({}, props, { factory: 'tonalIcon' })); }
}

export class Flexible {
  constructor(props) {
    return __h('Flexible', props);
  }
}

export class FloatingActionButton {
  constructor(props) {
    return __h('FloatingActionButton', props);
  }
  static extended(props) { return new FloatingActionButton(Object.assign({}, props, { factory: 'extended' })); }
  static large(props) { return new FloatingActionButton(Object.assign({}, props, { factory: 'large' })); }
  static small(props) { return new FloatingActionButton(Object.assign({}, props, { factory: 'small' })); }
}

export class FractionallySizedBox {
  constructor(props) {
    return __h('FractionallySizedBox', props);
  }
}

export class GestureDetector {
  constructor(props) {
    return __h('GestureDetector', props);
  }
}

export class Icon {
  constructor(props) {
    return __h('Icon', props);
  }
}

export class IconButton {
  constructor(props) {
    return __h('IconButton', props);
  }
  static filled(props) { return new IconButton(Object.assign({}, props, { factory: 'filled' })); }
  static filledTonal(props) { return new IconButton(Object.assign({}, props, { factory: 'filledTonal' })); }
  static outlined(props) { return new IconButton(Object.assign({}, props, { factory: 'outlined' })); }
}

export class Image {
  constructor(props) {
    return __h('Image', props);
  }
  static _(props) { return new Image(Object.assign({}, props, { factory: '_' })); }
  static asset(props) { return new Image(Object.assign({}, props, { factory: 'asset' })); }
  static file(props) { return new Image(Object.assign({}, props, { factory: 'file' })); }
  static memory(props) { return new Image(Object.assign({}, props, { factory: 'memory' })); }
  static network(props) { return new Image(Object.assign({}, props, { factory: 'network' })); }
}

export class IndexedStack {
  constructor(props) {
    return __h('IndexedStack', props);
  }
}

export class InkWell {
  constructor(props) {
    return __h('InkWell', props);
  }
}

export class InputDecoration {
  constructor(props) {
    return __h('InputDecoration', props);
  }
  static collapsed(props) { return new InputDecoration(Object.assign({}, props, { factory: 'collapsed' })); }
}

export class LinearProgressIndicator {
  constructor(props) {
    return __h('LinearProgressIndicator', props);
  }
}

export class ListTile {
  constructor(props) {
    return __h('ListTile', props);
  }
}

export class Material {
  constructor(props) {
    return __h('Material', props);
  }
}

export class NotificationListener {
  constructor(props) {
    return __h('NotificationListener', props);
  }
}

export class Opacity {
  constructor(props) {
    return __h('Opacity', props);
  }
}

export class OutlinedButton {
  constructor(props) {
    return __h('OutlinedButton', props);
  }
  static icon(props) { return new OutlinedButton(Object.assign({}, props, { factory: 'icon' })); }
}

export class Padding {
  constructor(props) {
    return __h('Padding', props);
  }
}

export class Positioned {
  constructor(props) {
    return __h('Positioned', props);
  }
  static directional(props) { return new Positioned(Object.assign({}, props, { factory: 'directional' })); }
  static fill(props) { return new Positioned(Object.assign({}, props, { factory: 'fill' })); }
  static fromRect(props) { return new Positioned(Object.assign({}, props, { factory: 'fromRect' })); }
  static fromRelativeRect(props) { return new Positioned(Object.assign({}, props, { factory: 'fromRelativeRect' })); }
}

export class Radio {
  constructor(props) {
    return __h('Radio', props);
  }
  static adaptive(props) { return new Radio(Object.assign({}, props, { factory: 'adaptive' })); }
}

export class RotationTransition {
  constructor(props) {
    return __h('RotationTransition', props);
  }
}

export class Row {
  constructor(props) {
    return __h('Row', props);
  }
}

export class SafeArea {
  constructor(props) {
    return __h('SafeArea', props);
  }
}

export class Scaffold {
  constructor(props) {
    return __h('Scaffold', props);
  }
}

export class ScaleTransition {
  constructor(props) {
    return __h('ScaleTransition', props);
  }
}

export class SingleChildScrollView {
  constructor(props) {
    return __h('SingleChildScrollView', props);
  }
}

export class SizeTransition {
  constructor(props) {
    return __h('SizeTransition', props);
  }
}

export class SizedBox {
  constructor(props) {
    return __h('SizedBox', props);
  }
  static expand(props) { return new SizedBox(Object.assign({}, props, { factory: 'expand' })); }
  static fromSize(props) { return new SizedBox(Object.assign({}, props, { factory: 'fromSize' })); }
  static shrink(props) { return new SizedBox(Object.assign({}, props, { factory: 'shrink' })); }
  static square(props) { return new SizedBox(Object.assign({}, props, { factory: 'square' })); }
}

export class Slider {
  constructor(props) {
    return __h('Slider', props);
  }
  static adaptive(props) { return new Slider(Object.assign({}, props, { factory: 'adaptive' })); }
}

export class SliverAppBar {
  constructor(props) {
    return __h('SliverAppBar', props);
  }
  static large(props) { return new SliverAppBar(Object.assign({}, props, { factory: 'large' })); }
  static medium(props) { return new SliverAppBar(Object.assign({}, props, { factory: 'medium' })); }
}

export class SliverFillRemaining {
  constructor(props) {
    return __h('SliverFillRemaining', props);
  }
}

export class SliverFillViewport {
  constructor(props) {
    return __h('SliverFillViewport', props);
  }
}

export class SliverFixedExtentList {
  constructor(props) {
    return __h('SliverFixedExtentList', props);
  }
  static builder(props) { return new SliverFixedExtentList(Object.assign({}, props, { factory: 'builder' })); }
  static list(props) { return new SliverFixedExtentList(Object.assign({}, props, { factory: 'list' })); }
}

export class SliverIgnorePointer {
  constructor(props) {
    return __h('SliverIgnorePointer', props);
  }
}

export class SliverOffstage {
  constructor(props) {
    return __h('SliverOffstage', props);
  }
}

export class SliverOpacity {
  constructor(props) {
    return __h('SliverOpacity', props);
  }
}

export class SliverPadding {
  constructor(props) {
    return __h('SliverPadding', props);
  }
}

export class SliverSafeArea {
  constructor(props) {
    return __h('SliverSafeArea', props);
  }
}

export class SliverToBoxAdapter {
  constructor(props) {
    return __h('SliverToBoxAdapter', props);
  }
}

export class SliverVisibility {
  constructor(props) {
    return __h('SliverVisibility', props);
  }
  static maintain(props) { return new SliverVisibility(Object.assign({}, props, { factory: 'maintain' })); }
}

export class Spacer {
  constructor(props) {
    return __h('Spacer', props);
  }
}

export class Stack {
  constructor(props) {
    return __h('Stack', props);
  }
  static _fromJson(props) { return new Stack(Object.assign({}, props, { factory: '_fromJson' })); }
}

export class Switch {
  constructor(props) {
    return __h('Switch', props);
  }
  static adaptive(props) { return new Switch(Object.assign({}, props, { factory: 'adaptive' })); }
}

export class Tab {
  constructor(props) {
    return __h('Tab', props);
  }
}

export class TabBar {
  constructor(props) {
    return __h('TabBar', props);
  }
  static secondary(props) { return new TabBar(Object.assign({}, props, { factory: 'secondary' })); }
}

export class TabBarView {
  constructor(props) {
    return __h('TabBarView', props);
  }
}

export class Text {
  constructor(props) {
    return __h('Text', props);
  }
  static _(props) { return new Text(Object.assign({}, props, { factory: '_' })); }
  static rich(props) { return new Text(Object.assign({}, props, { factory: 'rich' })); }
}

export class TextButton {
  constructor(props) {
    return __h('TextButton', props);
  }
  static icon(props) { return new TextButton(Object.assign({}, props, { factory: 'icon' })); }
}

export class TextField {
  constructor(props) {
    return __h('TextField', props);
  }
}

export class Transform {
  constructor(props) {
    return __h('Transform', props);
  }
  static _(props) { return new Transform(Object.assign({}, props, { factory: '_' })); }
  static flip(props) { return new Transform(Object.assign({}, props, { factory: 'flip' })); }
  static rotate(props) { return new Transform(Object.assign({}, props, { factory: 'rotate' })); }
  static scale(props) { return new Transform(Object.assign({}, props, { factory: 'scale' })); }
  static translate(props) { return new Transform(Object.assign({}, props, { factory: 'translate' })); }
}

export class Wrap {
  constructor(props) {
    return __h('Wrap', props);
  }
}

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
}

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
}

export class GridView {
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
    return __h('GridView', p);
  }
  static builder(props) { return new GridView(Object.assign({}, props, { factory: 'builder' })); }
  static count(props) { return new GridView(Object.assign({}, props, { factory: 'count' })); }
  static custom(props) { return new GridView(Object.assign({}, props, { factory: 'custom' })); }
  static extent(props) { return new GridView(Object.assign({}, props, { factory: 'extent' })); }
  static separated(props) { return new GridView(Object.assign({}, props, { factory: 'separated' })); }

}

export class ListView {
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
    return __h('ListView', p);
  }
  static builder(props) { return new ListView(Object.assign({}, props, { factory: 'builder' })); }
  static custom(props) { return new ListView(Object.assign({}, props, { factory: 'custom' })); }
  static separated(props) { return new ListView(Object.assign({}, props, { factory: 'separated' })); }

}

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
}

export class PageView {
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
    return __h('PageView', p);
  }
  static builder(props) { return new PageView(Object.assign({}, props, { factory: 'builder' })); }
  static custom(props) { return new PageView(Object.assign({}, props, { factory: 'custom' })); }
  static separated(props) { return new PageView(Object.assign({}, props, { factory: 'separated' })); }

}

export class ReorderableListView {
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
    return __h('ReorderableListView', p);
  }
  static builder(props) { return new ReorderableListView(Object.assign({}, props, { factory: 'builder' })); }
  static separated(props) { return new ReorderableListView(Object.assign({}, props, { factory: 'separated' })); }

}

export class SliverGrid {
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
    return __h('SliverGrid', p);
  }
  static builder(props) { return new SliverGrid(Object.assign({}, props, { factory: 'builder' })); }
  static count(props) { return new SliverGrid(Object.assign({}, props, { factory: 'count' })); }
  static extent(props) { return new SliverGrid(Object.assign({}, props, { factory: 'extent' })); }
  static list(props) { return new SliverGrid(Object.assign({}, props, { factory: 'list' })); }
  static separated(props) { return new SliverGrid(Object.assign({}, props, { factory: 'separated' })); }

}

export class SliverList {
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
    return __h('SliverList', p);
  }
  static builder(props) { return new SliverList(Object.assign({}, props, { factory: 'builder' })); }
  static list(props) { return new SliverList(Object.assign({}, props, { factory: 'list' })); }
  static separated(props) { return new SliverList(Object.assign({}, props, { factory: 'separated' })); }

}

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
}
