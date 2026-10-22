// GENERATED CODE - DO NOT EDIT
// package 模块（package: flutter）：由 hot_patch_generator 生成
// 本包内有 JS 类的 widget（逻辑组件 / sliver 代理）集中于此文件

// 共享结点工厂：所有 package 模块与组件产物共用（本文件是它的唯一定义处）。
// 元素对象统一由本函数产出，带 element: true 标记；props 值是否是 widget
// 只看这个标记，不做形状猜测。
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
export function __asElement(v) {
  if (v == null || typeof v !== 'object' || v.element === true) { return v; }
  var C = v.constructor;
  if (typeof C === 'function' && C.prototype &&
      typeof C.prototype.build === 'function') {
    return {
      type: C, props: v.props || {}, children: {}, element: true, inst: v
    };
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
    // delegate 两种形态都进 children，不参与 props。
    if (v != null && typeof v === 'object' && v.__delegate) {
      slots[k] = v;
      continue;
    }
    data[k] = v;
  }
  return { type: type, props: data, children: slots, element: true };
}


export class Align {
  constructor(props) {
    return __h('Align', props);
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
}

export class ElevatedButton {
  constructor(props) {
    return __h('ElevatedButton', props);
  }
}

export class Expanded {
  constructor(props) {
    return __h('Expanded', props);
  }
}

export class FilledButton {
  constructor(props) {
    return __h('FilledButton', props);
  }
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
}

export class Image {
  constructor(props) {
    return __h('Image', props);
  }
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
}

export class Radio {
  constructor(props) {
    return __h('Radio', props);
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

export class SingleChildScrollView {
  constructor(props) {
    return __h('SingleChildScrollView', props);
  }
}

export class SizedBox {
  constructor(props) {
    return __h('SizedBox', props);
  }
}

export class Slider {
  constructor(props) {
    return __h('Slider', props);
  }
}

export class SliverAppBar {
  constructor(props) {
    return __h('SliverAppBar', props);
  }
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
}

export class Switch {
  constructor(props) {
    return __h('Switch', props);
  }
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
}

export class TextButton {
  constructor(props) {
    return __h('TextButton', props);
  }
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
}

export class Wrap {
  constructor(props) {
    return __h('Wrap', props);
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
    var name = this.props.itemBuilder;
    var out = [];
    var n = this.props.itemCount || 0;
    // `.separated` 形态：item / separator 首尾交替展开（n 项 → 2n-1 个子节点）。
    var sep = this.props.separatorBuilder;
    for (var i = 0; i < n; i++) {
      out.push(owner[name].call(owner, context, i));
      if (sep && i < n - 1) { out.push(owner[sep].call(owner, context, i)); }
    }
    // props 原样透传（含 itemBuilder/separatorBuilder/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 按序取用。
    var p = {};
    for (var k in this.props) { p[k] = this.props[k]; }
    p.__items = out;
    return __h('GridView', p);
  }
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
    var name = this.props.itemBuilder;
    var out = [];
    var n = this.props.itemCount || 0;
    // `.separated` 形态：item / separator 首尾交替展开（n 项 → 2n-1 个子节点）。
    var sep = this.props.separatorBuilder;
    for (var i = 0; i < n; i++) {
      out.push(owner[name].call(owner, context, i));
      if (sep && i < n - 1) { out.push(owner[sep].call(owner, context, i)); }
    }
    // props 原样透传（含 itemBuilder/separatorBuilder/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 按序取用。
    var p = {};
    for (var k in this.props) { p[k] = this.props[k]; }
    p.__items = out;
    return __h('ListView', p);
  }
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
    var name = this.props.itemBuilder;
    var out = [];
    var n = this.props.itemCount || 0;
    // `.separated` 形态：item / separator 首尾交替展开（n 项 → 2n-1 个子节点）。
    var sep = this.props.separatorBuilder;
    for (var i = 0; i < n; i++) {
      out.push(owner[name].call(owner, context, i));
      if (sep && i < n - 1) { out.push(owner[sep].call(owner, context, i)); }
    }
    // props 原样透传（含 itemBuilder/separatorBuilder/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 按序取用。
    var p = {};
    for (var k in this.props) { p[k] = this.props[k]; }
    p.__items = out;
    return __h('PageView', p);
  }
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
    var name = this.props.itemBuilder;
    var out = [];
    var n = this.props.itemCount || 0;
    // `.separated` 形态：item / separator 首尾交替展开（n 项 → 2n-1 个子节点）。
    var sep = this.props.separatorBuilder;
    for (var i = 0; i < n; i++) {
      out.push(owner[name].call(owner, context, i));
      if (sep && i < n - 1) { out.push(owner[sep].call(owner, context, i)); }
    }
    // props 原样透传（含 itemBuilder/separatorBuilder/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 按序取用。
    var p = {};
    for (var k in this.props) { p[k] = this.props[k]; }
    p.__items = out;
    return __h('ReorderableListView', p);
  }
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
    var name = this.props.itemBuilder;
    var out = [];
    var n = this.props.itemCount || 0;
    // `.separated` 形态：item / separator 首尾交替展开（n 项 → 2n-1 个子节点）。
    var sep = this.props.separatorBuilder;
    for (var i = 0; i < n; i++) {
      out.push(owner[name].call(owner, context, i));
      if (sep && i < n - 1) { out.push(owner[sep].call(owner, context, i)); }
    }
    // props 原样透传（含 itemBuilder/separatorBuilder/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 按序取用。
    var p = {};
    for (var k in this.props) { p[k] = this.props[k]; }
    p.__items = out;
    return __h('SliverGrid', p);
  }
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
    var name = this.props.itemBuilder;
    var out = [];
    var n = this.props.itemCount || 0;
    // `.separated` 形态：item / separator 首尾交替展开（n 项 → 2n-1 个子节点）。
    var sep = this.props.separatorBuilder;
    for (var i = 0; i < n; i++) {
      out.push(owner[name].call(owner, context, i));
      if (sep && i < n - 1) { out.push(owner[sep].call(owner, context, i)); }
    }
    // props 原样透传（含 itemBuilder/separatorBuilder/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 按序取用。
    var p = {};
    for (var k in this.props) { p[k] = this.props[k]; }
    p.__items = out;
    return __h('SliverList', p);
  }
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
