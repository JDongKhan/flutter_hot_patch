// GENERATED CODE - DO NOT EDIT
// package 模块（package: flutter）：由 hot_patch_generator 生成
// 本包内有 JS 类的 widget（逻辑组件 / sliver 代理）集中于此文件

// 共享结点工厂：所有 package 模块与组件产物共用（本文件是它的唯一定义处）。
// 元素对象统一由本函数产出，带 element: true 标记；props 值是否是 widget
// 只看这个标记，不做形状猜测。
// 懒容器配置（**构建期唯一事实源**：shared/js_class_defs.dart 的
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


export class AbsorbPointer {
  constructor(props) {
    return __h('AbsorbPointer', props);
  }
}

export class AlertDialog {
  constructor(props) {
    return __h('AlertDialog', props);
  }
  static adaptive(props) { return new AlertDialog(Object.assign({}, props, { factory: 'adaptive' })); }
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

export class Baseline {
  constructor(props) {
    return __h('Baseline', props);
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

export class ColorFiltered {
  constructor(props) {
    return __h('ColorFiltered', props);
  }
}

export class Column {
  constructor(props) {
    return __h('Column', props);
  }
}

export class CompositedTransformFollower {
  constructor(props) {
    return __h('CompositedTransformFollower', props);
  }
}

export class CompositedTransformTarget {
  constructor(props) {
    return __h('CompositedTransformTarget', props);
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

export class CupertinoActionSheet {
  constructor(props) {
    return __h('CupertinoActionSheet', props);
  }
}

export class CupertinoActionSheetAction {
  constructor(props) {
    return __h('CupertinoActionSheetAction', props);
  }
}

export class CupertinoAlertDialog {
  constructor(props) {
    return __h('CupertinoAlertDialog', props);
  }
}

export class CupertinoDialogAction {
  constructor(props) {
    return __h('CupertinoDialogAction', props);
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

export class Dialog {
  constructor(props) {
    return __h('Dialog', props);
  }
  static fullscreen(props) { return new Dialog(Object.assign({}, props, { factory: 'fullscreen' })); }
}

export class Dismissible {
  constructor(props) {
    return __h('Dismissible', props);
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
  static styleFrom(props) { return new ButtonStyle(props); }
}

export class Expanded {
  constructor(props) {
    return __h('Expanded', props);
  }
}

export class FadeInImage {
  constructor(props) {
    return __h('FadeInImage', props);
  }
  static assetNetwork(props) { return new FadeInImage(Object.assign({}, props, { factory: 'assetNetwork' })); }
  static memoryNetwork(props) { return new FadeInImage(Object.assign({}, props, { factory: 'memoryNetwork' })); }
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
  static styleFrom(props) { return new ButtonStyle(props); }
}

export class FittedBox {
  constructor(props) {
    return __h('FittedBox', props);
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
  static extended(props) { return new FloatingActionButton(Object.assign({}, props, { factory: 'extended' })); }
  static large(props) { return new FloatingActionButton(Object.assign({}, props, { factory: 'large' })); }
  static small(props) { return new FloatingActionButton(Object.assign({}, props, { factory: 'small' })); }
}

export class Focus {
  constructor(props) {
    return __h('Focus', props);
  }
  static withExternalFocusNode(props) { return new Focus(Object.assign({}, props, { factory: 'withExternalFocusNode' })); }
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

export class Hero {
  constructor(props) {
    return __h('Hero', props);
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
  static styleFrom(props) { return new ButtonStyle(props); }
}

export class IgnorePointer {
  constructor(props) {
    return __h('IgnorePointer', props);
  }
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

export class ImageFiltered {
  constructor(props) {
    return __h('ImageFiltered', props);
  }
}

export class ImageIcon {
  constructor(props) {
    return __h('ImageIcon', props);
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
  static collapsed(props) { return new InputDecoration(Object.assign({}, props, { factory: 'collapsed' })); }
}

export class InteractiveViewer {
  constructor(props) {
    return __h('InteractiveViewer', props);
  }
  static builder(props) { return new InteractiveViewer(Object.assign({}, props, { factory: 'builder' })); }
}

export class IntrinsicHeight {
  constructor(props) {
    return __h('IntrinsicHeight', props);
  }
}

export class IntrinsicWidth {
  constructor(props) {
    return __h('IntrinsicWidth', props);
  }
}

export class KeyboardListener {
  constructor(props) {
    return __h('KeyboardListener', props);
  }
}

export class LimitedBox {
  constructor(props) {
    return __h('LimitedBox', props);
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

export class Offstage {
  constructor(props) {
    return __h('Offstage', props);
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
  static styleFrom(props) { return new ButtonStyle(props); }
}

export class Padding {
  constructor(props) {
    return __h('Padding', props);
  }
}

export class PopScope {
  constructor(props) {
    return __h('PopScope', props);
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

export class PreferredSize {
  constructor(props) {
    return __h('PreferredSize', props);
  }
}

export class Radio {
  constructor(props) {
    return __h('Radio', props);
  }
  static adaptive(props) { return new Radio(Object.assign({}, props, { factory: 'adaptive' })); }
}

export class RadioGroup {
  constructor(props) {
    return __h('RadioGroup', props);
  }
}

export class RepaintBoundary {
  constructor(props) {
    return __h('RepaintBoundary', props);
  }
  static wrap(props) { return new RepaintBoundary(Object.assign({}, props, { factory: 'wrap' })); }
}

export class RichText {
  constructor(props) {
    return __h('RichText', props);
  }
}

export class RotatedBox {
  constructor(props) {
    return __h('RotatedBox', props);
  }
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

export class SimpleDialog {
  constructor(props) {
    return __h('SimpleDialog', props);
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
  static styleFrom(props) { return new ButtonStyle(props); }
}

export class TextField {
  constructor(props) {
    return __h('TextField', props);
  }
}

export class Tooltip {
  constructor(props) {
    return __h('Tooltip', props);
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

export class Visibility {
  constructor(props) {
    return __h('Visibility', props);
  }
  static maintain(props) { return new Visibility(Object.assign({}, props, { factory: 'maintain' })); }
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
}

export class AnimatedList {
  constructor(props) {
    this.props = props || {};
    // 普通构造形态（没有 builder 回调，如 `SliverGrid(delegate: …)` /
    // `PageView(children: […])`）：与其它宿主类型同一协议，直接产出元素。
    if (!this.__hasBuilder()) {
      return __h('AnimatedList', this.props);
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
      console.warn('[AnimatedList] itemBuilder 不是闭包，按普通构造渲染');
      return __h('AnimatedList', this.props);
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
      count: this.props.initialItemCount || 0,
      ctx: context
    };
    return __h('AnimatedList', p);
  }
  static builder(props) { return new AnimatedList(Object.assign({}, props, { factory: 'builder' })); }
  static separated(props) { return new AnimatedList(Object.assign({}, props, { factory: 'separated' })); }

}

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
}

export class DragTarget {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    var props = __dragTargetProps(this, context);
    if (props == null) { return null; }
    return __h('DragTarget', props);
  }
}

export class Draggable {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    return __h('Draggable', __dragSourceProps(this));
  }
}

export class GridView {
  constructor(props) {
    this.props = props || {};
    // 普通构造形态（没有 builder 回调，如 `SliverGrid(delegate: …)` /
    // `PageView(children: […])`）：与其它宿主类型同一协议，直接产出元素。
    if (!this.__hasBuilder()) {
      return __h('GridView', this.props);
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
      console.warn('[GridView] itemBuilder 不是闭包，按普通构造渲染');
      return __h('GridView', this.props);
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
}

export class ListView {
  constructor(props) {
    this.props = props || {};
    // 普通构造形态（没有 builder 回调，如 `SliverGrid(delegate: …)` /
    // `PageView(children: […])`）：与其它宿主类型同一协议，直接产出元素。
    if (!this.__hasBuilder()) {
      return __h('ListView', this.props);
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
      console.warn('[ListView] itemBuilder 不是闭包，按普通构造渲染');
      return __h('ListView', this.props);
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
}

export class LongPressDraggable {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    return __h('LongPressDraggable', __dragSourceProps(this));
  }
}

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
}

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
}

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
};

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
}

export class OverlayPortal {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    var src = this.props;
    // 闭包不能进宿主 props（要跨桥序列化），展开后摘除。
    var p = {};
    for (var k in src) {
      if (k === 'overlayChildBuilder') { continue; }
      p[k] = src[k];
    }
    // SDK 的命名构造 `OverlayPortal.targetsRootOverlay`（已废弃）等价于挂到根
    // Overlay。`factory` 是命名构造的通用标记（由自动生成的同名静态方法写入），
    // 这里只补它对应的构造语义，不涉及任何类名/属性名白名单。
    if (p.factory === 'targetsRootOverlay') { p.overlayLocation = 'rootOverlay'; }
    var oc = null;
    if (typeof src.overlayChildBuilder === 'function') {
      oc = src.overlayChildBuilder(context);
    } else {
      console.warn('[OverlayPortal] overlayChildBuilder 不是闭包');
    }
    if (oc != null) { p.overlayChild = oc; }
    return __h('OverlayPortal', p);
  }
  static overlayChildLayoutBuilder(props) { return new OverlayPortal(Object.assign({}, props, { factory: 'overlayChildLayoutBuilder' })); }
  static targetsRootOverlay(props) { return new OverlayPortal(Object.assign({}, props, { factory: 'targetsRootOverlay' })); }
}

export class PageView {
  constructor(props) {
    this.props = props || {};
    // 普通构造形态（没有 builder 回调，如 `SliverGrid(delegate: …)` /
    // `PageView(children: […])`）：与其它宿主类型同一协议，直接产出元素。
    if (!this.__hasBuilder()) {
      return __h('PageView', this.props);
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
      console.warn('[PageView] itemBuilder 不是闭包，按普通构造渲染');
      return __h('PageView', this.props);
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
    // 普通构造形态（没有 builder 回调，如 `SliverGrid(delegate: …)` /
    // `PageView(children: […])`）：与其它宿主类型同一协议，直接产出元素。
    if (!this.__hasBuilder()) {
      return __h('ReorderableListView', this.props);
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
      console.warn('[ReorderableListView] itemBuilder 不是闭包，按普通构造渲染');
      return __h('ReorderableListView', this.props);
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
    // 普通构造形态（没有 builder 回调，如 `SliverGrid(delegate: …)` /
    // `PageView(children: […])`）：与其它宿主类型同一协议，直接产出元素。
    if (!this.__hasBuilder()) {
      return __h('SliverGrid', this.props);
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
      console.warn('[SliverGrid] itemBuilder 不是闭包，按普通构造渲染');
      return __h('SliverGrid', this.props);
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
    // 普通构造形态（没有 builder 回调，如 `SliverGrid(delegate: …)` /
    // `PageView(children: […])`）：与其它宿主类型同一协议，直接产出元素。
    if (!this.__hasBuilder()) {
      return __h('SliverList', this.props);
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
      console.warn('[SliverList] itemBuilder 不是闭包，按普通构造渲染');
      return __h('SliverList', this.props);
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
      count: this.props.itemCount || 0,
      ctx: context
    };
    return __h('SliverList', p);
  }
  static builder(props) { return new SliverList(Object.assign({}, props, { factory: 'builder' })); }
  static list(props) { return new SliverList(Object.assign({}, props, { factory: 'list' })); }
  static separated(props) { return new SliverList(Object.assign({}, props, { factory: 'separated' })); }

}

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
}

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
}

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
}

export class AnimatedListState extends __StateHandle {
  insertItem(index, duration) {
    this.__op('insertItem', { index: index, duration: duration });
  }
  // 与 Dart 同形（`removeItem(index, builder, {duration})`）：`builder` 是 Dart
  // 闭包，跨语言无法执行——宿主复用「被移除的原项」当退场项，这里只告警一次。
  removeItem(index, builder, duration) {
    if (typeof builder === 'function' && !AnimatedListState.__warnedRemoval) {
      AnimatedListState.__warnedRemoval = true;
      console.warn('[AnimatedList] 退场 builder 不可跨语言执行，已回退为「被移除的原项」（样式与普通项一致）');
    }
    this.__op('removeItem', { index: index, duration: duration });
  }
}
__registerStateProxy('AnimatedListState', AnimatedListState);

// ===== Dart 值类（值对象 / Controller / 动画 / Key / 枚举）=====
// 翻译层对它们一律 `new X({...})` / `X.member`；
// 跨桥经各自 toJSON 输出宿主协议（不在这里做任何 JSON 拍平）。
const G = globalThis;
const {
  defineProtoGetter: __defineProtoGetter,
  defineController, defineHandleKind, handleOp, reg,
  contextOf, asElement, hostIdOf, newRoot, mount, unmount,
  commit, emit, flushNow, abortRoot, releasePageHandles, host,
  roots, JsBuildContext,
} = G.__core;

// 构建期查不到构造签名时，位置实参以 `__pos: [...]` 下发；这里按形参名顺序
// 展开。任何类都可复用，不含类名判断。
function __posArgs(props, names) {
  if (!props || !props.__pos) { return props || {}; }
  var out = {};
  for (var k in props) {
    if (k !== '__pos') { out[k] = props[k]; }
  }
  for (var i = 0; i < names.length && i < props.__pos.length; i++) {
    out[names[i]] = props.__pos[i];
  }
  return out;
}

// Duration 产物键是 Dart 的命名实参（milliseconds / seconds / …），换算成
// 毫秒后经 toJSON 下发；宿主 durationFromJson 只认 `{__duration: ms}` 与裸数字。
function __durationMs(d) {
  if (d == null) { return null; }
  if (typeof d === 'number') { return d; }
  if (typeof d === 'object') {
    if (typeof d.__duration === 'number') { return d.__duration; }
    if (typeof d.inMilliseconds === 'number') { return d.inMilliseconds; }
  }
  return null;
}
export class Duration {
  constructor(opts) {
    opts = __posArgs(opts, ['microseconds', 'milliseconds', 'seconds',
      'minutes', 'hours', 'days']);
    var ms = (opts.milliseconds || 0) + (opts.seconds || 0) * 1000 +
    (opts.minutes || 0) * 60000 + (opts.hours || 0) * 3600000 +
    (opts.days || 0) * 86400000;
    ms += (opts.microseconds || 0) / 1000;
    this.inMilliseconds = Math.round(ms);
    this.inMicroseconds = Math.round(ms * 1000);
  }
  toJSON() {
    return { __duration: this.inMilliseconds };
  }
}

export class Size {
  constructor(props) {
    props = __posArgs(props, ['width', 'height']);
    this.width = props.width;
    this.height = props.height;
  }
  toJSON() {
    return { width: this.width, height: this.height };
  }
  static fromHeight(props) {
    props = __posArgs(props, ['height']);
    return new Size({ width: Infinity, height: props.height });
  }
  static fromWidth(props) {
    props = __posArgs(props, ['width']);
    return new Size({ width: props.width, height: Infinity });
  }
  static square(props) {
    props = __posArgs(props, ['dimension']);
    return new Size({ width: props.dimension, height: props.dimension });
  }
  static copy(props) {
    props = __posArgs(props, ['source']);
    return new Size({ width: props.source.width, height: props.source.height });
  }
  /** Dart 的 static const：零尺寸 / 无穷尺寸。 */
  static zero = new Size({ width: 0, height: 0 });
  static infinite = new Size({ width: Infinity, height: Infinity });
}
// Dart `Size` 的命名构造 / 静态常量（产物按统一规则发射 `Size.fromHeight({…})`）。
// **无界维度是 +∞**：跨桥时 `JSON.stringify(Infinity)` 得到 null，宿主侧按 ∞
// 还原（见 js_widget_registry 的 PreferredSize / layout 约束的 null 约定）。

export class Offset {
  constructor(props) {
    props = __posArgs(props, ['dx', 'dy']);
    this.dx = props.dx != null ? props.dx : 0;
    this.dy = props.dy != null ? props.dy : 0;
  }
  toJSON() {
    return { dx: this.dx, dy: this.dy };
  }
}

// Velocity：`DraggableDetails.velocity`（拖拽结束时的速度）。字段与 Dart 一致，
// 由拖拽片段把宿主的 `{pxPerSecond: {dx, dy}}` 还原成实例。
export class Velocity {
  constructor(props) {
    props = __posArgs(props, ['pixelsPerSecond']);
    this.pixelsPerSecond = props.pixelsPerSecond != null
    ? props.pixelsPerSecond
    : new Offset({ dx: 0, dy: 0 });
  }
  toJSON() {
    return { pxPerSecond: this.pixelsPerSecond };
  }
}

// Alignment：产物在**值位置**（LinearGradient 的 begin/end、Container 的
// alignment 等）可能直接引用 `Alignment.topLeft`（不是所有位置都会经过
// 构建期的枚举转换器，如静态字段初值就是通用表达式翻译）。Dart 侧它是
// 常量对象，但跨桥协议是**成员名**（宿主 alignmentFromJson 只认字符串），
// 因此静态常量直接就是该字符串——与 Dart 里「同一常量是同一值」的语义一致
//（比较、传参、判等全部成立）。
export class Alignment {
  constructor(props) {
    props = __posArgs(props, ['x', 'y']);
    this.x = props.x != null ? props.x : 0;
    this.y = props.y != null ? props.y : 0;
  }
  toJSON() {
    return { x: this.x, y: this.y };
  }
  // 静态常量即成员名字符串：宿主 alignmentFromJson 只认名字。
  static topLeft = "topLeft";
  static topCenter = "topCenter";
  static topRight = "topRight";
  static centerLeft = "centerLeft";
  static center = "center";
  static centerRight = "centerRight";
  static bottomLeft = "bottomLeft";
  static bottomCenter = "bottomCenter";
  static bottomRight = "bottomRight";
}

export class Radius {
  constructor(props) {
    props = __posArgs(props, ['radius']);
    var r = props.radius != null ? props.radius : (props.x != null ? props.x : 0);
    this.x = r;
    this.y = r;
  }
  toJSON() {
    return { radius: this.x };
  }
  static circular(props) { return new Radius(props); }
}

// BoxConstraints：布局约束值对象（LayoutBuilder 的 builder 第二参）。宿主按
// {minWidth, maxWidth, minHeight, maxHeight} 下发，无界维度发 null（JSON 不能
// 表达 Infinity），这里还原成 +∞（见【18.8】）。
export class BoxConstraints {
  constructor(props) {
    props = __posArgs(props, ['minWidth', 'maxWidth', 'minHeight', 'maxHeight']);
    this.minWidth = props.minWidth != null ? props.minWidth : 0;
    this.maxWidth = props.maxWidth != null ? props.maxWidth : Infinity;
    this.minHeight = props.minHeight != null ? props.minHeight : 0;
    this.maxHeight = props.maxHeight != null ? props.maxHeight : Infinity;
  }
  get biggest() { return new Size({ width: this.maxWidth, height: this.maxHeight }); }
  get smallest() { return new Size({ width: this.minWidth, height: this.minHeight }); }
  get isTight() { return this.minWidth >= this.maxWidth && this.minHeight >= this.maxHeight; }
  get hasBoundedWidth() { return this.maxWidth < Infinity; }
  get hasBoundedHeight() { return this.maxHeight < Infinity; }
  // 无界维度回 null：与宿主下发协议同形，保证跨语言往返一致。
  toJSON() {
    return {
      minWidth: this.minWidth,
      maxWidth: this.maxWidth === Infinity ? null : this.maxWidth,
      minHeight: this.minHeight,
      maxHeight: this.maxHeight === Infinity ? null : this.maxHeight,
    };
  }
}

// TextSpan：Dart 富文本子树的值对象（RichText 的 `text`）。产物按统一规则
// 发射 `new TextSpan({text, style, children, semanticsLabel})`；这里镜像字段，
// 跨桥时由 JSON.stringify 递归序列化成普通对象，宿主 textSpanFromJson 再
// 还原成真正的 TextSpan 树。
export class TextSpan {
  constructor(props) {
    props = __posArgs(props, ['text']);
    this.text = props.text;
    if (props.style != null) { this.style = props.style; }
    if (props.children != null) { this.children = props.children; }
    if (props.semanticsLabel != null) { this.semanticsLabel = props.semanticsLabel; }
  }
}

// ---------------------------------------------------------------------------
// 渐变与装饰：绘制层值对象（`LinearGradient` / `RadialGradient` /
// `SweepGradient` / `BoxDecoration`）。
//
// 来历与 Duration / Size 完全相同：Dart 里它们是普通的 const 构造，翻译层
// 按统一规则原样发射 `new LinearGradient({begin, end, colors})`，因此运行时
// **必须**有同名类——缺一个就是模块求值期的 `Can't find variable`，整页挂载
// 失败（静态字段初值在类定义时就执行，比任何方法体都早）。
//
// 跨桥协议见宿主 painting_from_json：
//   gradient → {kind:'linear'|'radial'|'sweep', colors, begin/end/center, radius, stops}
//   decoration → {color, border, borderRadius, boxShadow, gradient, image, shape}
// colors 里是 Color 实例：JSON.stringify 会递归调用其 toJSON 得到 '#AARRGGBB'，
// 宿主 colorFromJson 据此还原，无需在这里逐个转换。
// names[0] 恒为 colors（构造首位置实参，单独兜底成数组），其余从 1 开始。
function __gradientProps(props, names) {
  props = __posArgs(props, names);
  var out = { colors: props.colors != null ? props.colors : [] };
  for (var i = 1; i < names.length; i++) {
    if (props[names[i]] != null) { out[names[i]] = props[names[i]]; }
  }
  return out;
}
function __gradientJson(kind, self) {
  var json = { kind: kind, colors: self.colors };
  if (self.begin != null) { json.begin = self.begin; }
  if (self.end != null) { json.end = self.end; }
  if (self.center != null) { json.center = self.center; }
  if (self.radius != null) { json.radius = self.radius; }
  if (self.stops != null) { json.stops = self.stops; }
  return json;
}

export class LinearGradient {
  constructor(props) {
    var p = __gradientProps(props, ['colors', 'begin', 'end', 'stops', 'tileMode']);
    for (var k in p) { this[k] = p[k]; }
  }
  toJSON() {
    return __gradientJson('linear', this);
  }
}

export class RadialGradient {
  constructor(props) {
    var p = __gradientProps(props,
    ['colors', 'center', 'radius', 'stops', 'focal', 'focalRadius', 'tileMode']);
    for (var k in p) { this[k] = p[k]; }
  }
  toJSON() {
    return __gradientJson('radial', this);
  }
}

export class SweepGradient {
  constructor(props) {
    var p = __gradientProps(props,
    ['colors', 'center', 'startAngle', 'endAngle', 'stops', 'tileMode']);
    for (var k in p) { this[k] = p[k]; }
  }
  toJSON() {
    return __gradientJson('sweep', this);
  }
}

// BoxDecoration：字段名与 Dart 构造具名实参一致，toJSON 直出宿主协议
//（值为 null 的键不下发——宿主对 null 与缺省同义，少发更干净）。
export class BoxDecoration {
  constructor(props) {
    props = __posArgs(props, ['color', 'image', 'border', 'borderRadius',
      'boxShadow', 'gradient', 'backgroundBlendMode', 'shape']);
    for (var k in props) {
      if (props[k] != null) { this[k] = props[k]; }
    }
  }
  toJSON() {
    var json = {};
    for (var k in this) {
      if (this[k] != null) { json[k] = this[k]; }
    }
    return json;
  }
}


// ===== SDK 枚举值类（由源码 enum 声明自动生成，勿手改）=====
// 翻译层对 `Owner.member` 一律原样引用，跨桥 toJSON() 发成员名。

export class SchedulerServiceExtensions {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SchedulerServiceExtensions.' + this.name; }
  static timeDilation = new SchedulerServiceExtensions('timeDilation', 0);
}
SchedulerServiceExtensions.values = [SchedulerServiceExtensions.timeDilation];

export class SchedulerPhase {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SchedulerPhase.' + this.name; }
  static idle = new SchedulerPhase('idle', 0);
  static transientCallbacks = new SchedulerPhase('transientCallbacks', 1);
  static midFrameMicrotasks = new SchedulerPhase('midFrameMicrotasks', 2);
  static persistentCallbacks = new SchedulerPhase('persistentCallbacks', 3);
  static postFrameCallbacks = new SchedulerPhase('postFrameCallbacks', 4);
}
SchedulerPhase.values = [SchedulerPhase.idle, SchedulerPhase.transientCallbacks, SchedulerPhase.midFrameMicrotasks, SchedulerPhase.persistentCallbacks, SchedulerPhase.postFrameCallbacks];

export class AnimationBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'AnimationBehavior.' + this.name; }
  static normal = new AnimationBehavior('normal', 0);
  static preserve = new AnimationBehavior('preserve', 1);
}
AnimationBehavior.values = [AnimationBehavior.normal, AnimationBehavior.preserve];

export class AnimationStatus {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'AnimationStatus.' + this.name; }
  static dismissed = new AnimationStatus('dismissed', 0);
  static forward = new AnimationStatus('forward', 1);
  static reverse = new AnimationStatus('reverse', 2);
  static completed = new AnimationStatus('completed', 3);
}
AnimationStatus.values = [AnimationStatus.dismissed, AnimationStatus.forward, AnimationStatus.reverse, AnimationStatus.completed];

export class DiagnosticLevel {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DiagnosticLevel.' + this.name; }
  static hidden = new DiagnosticLevel('hidden', 0);
  static fine = new DiagnosticLevel('fine', 1);
  static debug = new DiagnosticLevel('debug', 2);
  static info = new DiagnosticLevel('info', 3);
  static warning = new DiagnosticLevel('warning', 4);
  static hint = new DiagnosticLevel('hint', 5);
  static summary = new DiagnosticLevel('summary', 6);
  static error = new DiagnosticLevel('error', 7);
  static off = new DiagnosticLevel('off', 8);
}
DiagnosticLevel.values = [DiagnosticLevel.hidden, DiagnosticLevel.fine, DiagnosticLevel.debug, DiagnosticLevel.info, DiagnosticLevel.warning, DiagnosticLevel.hint, DiagnosticLevel.summary, DiagnosticLevel.error, DiagnosticLevel.off];

export class DiagnosticsTreeStyle {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DiagnosticsTreeStyle.' + this.name; }
  static none = new DiagnosticsTreeStyle('none', 0);
  static sparse = new DiagnosticsTreeStyle('sparse', 1);
  static offstage = new DiagnosticsTreeStyle('offstage', 2);
  static dense = new DiagnosticsTreeStyle('dense', 3);
  static transition = new DiagnosticsTreeStyle('transition', 4);
  static error = new DiagnosticsTreeStyle('error', 5);
  static whitespace = new DiagnosticsTreeStyle('whitespace', 6);
  static flat = new DiagnosticsTreeStyle('flat', 7);
  static singleLine = new DiagnosticsTreeStyle('singleLine', 8);
  static errorProperty = new DiagnosticsTreeStyle('errorProperty', 9);
  static shallow = new DiagnosticsTreeStyle('shallow', 10);
  static truncateChildren = new DiagnosticsTreeStyle('truncateChildren', 11);
}
DiagnosticsTreeStyle.values = [DiagnosticsTreeStyle.none, DiagnosticsTreeStyle.sparse, DiagnosticsTreeStyle.offstage, DiagnosticsTreeStyle.dense, DiagnosticsTreeStyle.transition, DiagnosticsTreeStyle.error, DiagnosticsTreeStyle.whitespace, DiagnosticsTreeStyle.flat, DiagnosticsTreeStyle.singleLine, DiagnosticsTreeStyle.errorProperty, DiagnosticsTreeStyle.shallow, DiagnosticsTreeStyle.truncateChildren];

export class TargetPlatform {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TargetPlatform.' + this.name; }
  static android = new TargetPlatform('android', 0);
  static fuchsia = new TargetPlatform('fuchsia', 1);
  static iOS = new TargetPlatform('iOS', 2);
  static linux = new TargetPlatform('linux', 3);
  static macOS = new TargetPlatform('macOS', 4);
  static windows = new TargetPlatform('windows', 5);
}
TargetPlatform.values = [TargetPlatform.android, TargetPlatform.fuchsia, TargetPlatform.iOS, TargetPlatform.linux, TargetPlatform.macOS, TargetPlatform.windows];

export class FoundationServiceExtensions {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'FoundationServiceExtensions.' + this.name; }
  static reassemble = new FoundationServiceExtensions('reassemble', 0);
  static exit = new FoundationServiceExtensions('exit', 1);
  static connectedVmServiceUri = new FoundationServiceExtensions('connectedVmServiceUri', 2);
  static activeDevToolsServerAddress = new FoundationServiceExtensions('activeDevToolsServerAddress', 3);
  static platformOverride = new FoundationServiceExtensions('platformOverride', 4);
  static brightnessOverride = new FoundationServiceExtensions('brightnessOverride', 5);
}
FoundationServiceExtensions.values = [FoundationServiceExtensions.reassemble, FoundationServiceExtensions.exit, FoundationServiceExtensions.connectedVmServiceUri, FoundationServiceExtensions.activeDevToolsServerAddress, FoundationServiceExtensions.platformOverride, FoundationServiceExtensions.brightnessOverride];

export class Assertiveness {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'Assertiveness.' + this.name; }
  static polite = new Assertiveness('polite', 0);
  static assertive = new Assertiveness('assertive', 1);
}
Assertiveness.values = [Assertiveness.polite, Assertiveness.assertive];

export class AccessibilityFocusBlockType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'AccessibilityFocusBlockType.' + this.name; }
  static none = new AccessibilityFocusBlockType('none', 0);
  static blockSubtree = new AccessibilityFocusBlockType('blockSubtree', 1);
  static blockNode = new AccessibilityFocusBlockType('blockNode', 2);
}
AccessibilityFocusBlockType.values = [AccessibilityFocusBlockType.none, AccessibilityFocusBlockType.blockSubtree, AccessibilityFocusBlockType.blockNode];

export class DebugSemanticsDumpOrder {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DebugSemanticsDumpOrder.' + this.name; }
  static inverseHitTest = new DebugSemanticsDumpOrder('inverseHitTest', 0);
  static traversalOrder = new DebugSemanticsDumpOrder('traversalOrder', 1);
}
DebugSemanticsDumpOrder.values = [DebugSemanticsDumpOrder.inverseHitTest, DebugSemanticsDumpOrder.traversalOrder];

export class BorderStyle {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'BorderStyle.' + this.name; }
  static none = new BorderStyle('none', 0);
  static solid = new BorderStyle('solid', 1);
}
BorderStyle.values = [BorderStyle.none, BorderStyle.solid];

export class BoxShape {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'BoxShape.' + this.name; }
  static rectangle = new BoxShape('rectangle', 0);
  static circle = new BoxShape('circle', 1);
}
BoxShape.values = [BoxShape.rectangle, BoxShape.circle];

export class ResizeImagePolicy {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ResizeImagePolicy.' + this.name; }
  static exact = new ResizeImagePolicy('exact', 0);
  static fit = new ResizeImagePolicy('fit', 1);
}
ResizeImagePolicy.values = [ResizeImagePolicy.exact, ResizeImagePolicy.fit];

export class WebHtmlElementStrategy {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'WebHtmlElementStrategy.' + this.name; }
  static never = new WebHtmlElementStrategy('never', 0);
  static fallback = new WebHtmlElementStrategy('fallback', 1);
  static prefer = new WebHtmlElementStrategy('prefer', 2);
}
WebHtmlElementStrategy.values = [WebHtmlElementStrategy.never, WebHtmlElementStrategy.fallback, WebHtmlElementStrategy.prefer];

export class FlutterLogoStyle {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'FlutterLogoStyle.' + this.name; }
  static markOnly = new FlutterLogoStyle('markOnly', 0);
  static horizontal = new FlutterLogoStyle('horizontal', 1);
  static stacked = new FlutterLogoStyle('stacked', 2);
}
FlutterLogoStyle.values = [FlutterLogoStyle.markOnly, FlutterLogoStyle.horizontal, FlutterLogoStyle.stacked];

export class RenderComparison {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'RenderComparison.' + this.name; }
  static identical = new RenderComparison('identical', 0);
  static metadata = new RenderComparison('metadata', 1);
  static paint = new RenderComparison('paint', 2);
  static layout = new RenderComparison('layout', 3);
}
RenderComparison.values = [RenderComparison.identical, RenderComparison.metadata, RenderComparison.paint, RenderComparison.layout];

export class Axis {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'Axis.' + this.name; }
  static horizontal = new Axis('horizontal', 0);
  static vertical = new Axis('vertical', 1);
}
Axis.values = [Axis.horizontal, Axis.vertical];

export class VerticalDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'VerticalDirection.' + this.name; }
  static up = new VerticalDirection('up', 0);
  static down = new VerticalDirection('down', 1);
}
VerticalDirection.values = [VerticalDirection.up, VerticalDirection.down];

export class AxisDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'AxisDirection.' + this.name; }
  static up = new AxisDirection('up', 0);
  static right = new AxisDirection('right', 1);
  static down = new AxisDirection('down', 2);
  static left = new AxisDirection('left', 3);
}
AxisDirection.values = [AxisDirection.up, AxisDirection.right, AxisDirection.down, AxisDirection.left];

export class BoxFit {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'BoxFit.' + this.name; }
  static fill = new BoxFit('fill', 0);
  static contain = new BoxFit('contain', 1);
  static cover = new BoxFit('cover', 2);
  static fitWidth = new BoxFit('fitWidth', 3);
  static fitHeight = new BoxFit('fitHeight', 4);
  static none = new BoxFit('none', 5);
  static scaleDown = new BoxFit('scaleDown', 6);
}
BoxFit.values = [BoxFit.fill, BoxFit.contain, BoxFit.cover, BoxFit.fitWidth, BoxFit.fitHeight, BoxFit.none, BoxFit.scaleDown];

export class TextOverflow {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextOverflow.' + this.name; }
  static clip = new TextOverflow('clip', 0);
  static fade = new TextOverflow('fade', 1);
  static ellipsis = new TextOverflow('ellipsis', 2);
  static visible = new TextOverflow('visible', 3);
}
TextOverflow.values = [TextOverflow.clip, TextOverflow.fade, TextOverflow.ellipsis, TextOverflow.visible];

export class TextWidthBasis {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextWidthBasis.' + this.name; }
  static parent = new TextWidthBasis('parent', 0);
  static longestLine = new TextWidthBasis('longestLine', 1);
}
TextWidthBasis.values = [TextWidthBasis.parent, TextWidthBasis.longestLine];

export class ImageRepeat {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ImageRepeat.' + this.name; }
  static repeat = new ImageRepeat('repeat', 0);
  static repeatX = new ImageRepeat('repeatX', 1);
  static repeatY = new ImageRepeat('repeatY', 2);
  static noRepeat = new ImageRepeat('noRepeat', 3);
}
ImageRepeat.values = [ImageRepeat.repeat, ImageRepeat.repeatX, ImageRepeat.repeatY, ImageRepeat.noRepeat];

export class GestureDisposition {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'GestureDisposition.' + this.name; }
  static accepted = new GestureDisposition('accepted', 0);
  static rejected = new GestureDisposition('rejected', 1);
}
GestureDisposition.values = [GestureDisposition.accepted, GestureDisposition.rejected];

export class DragStartBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DragStartBehavior.' + this.name; }
  static down = new DragStartBehavior('down', 0);
  static start = new DragStartBehavior('start', 1);
}
DragStartBehavior.values = [DragStartBehavior.down, DragStartBehavior.start];

export class MultitouchDragStrategy {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'MultitouchDragStrategy.' + this.name; }
  static latestPointer = new MultitouchDragStrategy('latestPointer', 0);
  static averageBoundaryPointers = new MultitouchDragStrategy('averageBoundaryPointers', 1);
  static sumAllPointers = new MultitouchDragStrategy('sumAllPointers', 2);
}
MultitouchDragStrategy.values = [MultitouchDragStrategy.latestPointer, MultitouchDragStrategy.averageBoundaryPointers, MultitouchDragStrategy.sumAllPointers];

export class GestureRecognizerState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'GestureRecognizerState.' + this.name; }
  static ready = new GestureRecognizerState('ready', 0);
  static possible = new GestureRecognizerState('possible', 1);
  static defunct = new GestureRecognizerState('defunct', 2);
}
GestureRecognizerState.values = [GestureRecognizerState.ready, GestureRecognizerState.possible, GestureRecognizerState.defunct];

export class WrapAlignment {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'WrapAlignment.' + this.name; }
  static start = new WrapAlignment('start', 0);
  static end = new WrapAlignment('end', 1);
  static center = new WrapAlignment('center', 2);
  static spaceBetween = new WrapAlignment('spaceBetween', 3);
  static spaceAround = new WrapAlignment('spaceAround', 4);
  static spaceEvenly = new WrapAlignment('spaceEvenly', 5);
}
WrapAlignment.values = [WrapAlignment.start, WrapAlignment.end, WrapAlignment.center, WrapAlignment.spaceBetween, WrapAlignment.spaceAround, WrapAlignment.spaceEvenly];

export class WrapCrossAlignment {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'WrapCrossAlignment.' + this.name; }
  static start = new WrapCrossAlignment('start', 0);
  static end = new WrapCrossAlignment('end', 1);
  static center = new WrapCrossAlignment('center', 2);
}
WrapCrossAlignment.values = [WrapCrossAlignment.start, WrapCrossAlignment.end, WrapCrossAlignment.center];

export class HitTestBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'HitTestBehavior.' + this.name; }
  static deferToChild = new HitTestBehavior('deferToChild', 0);
  static opaque = new HitTestBehavior('opaque', 1);
  static translucent = new HitTestBehavior('translucent', 2);
}
HitTestBehavior.values = [HitTestBehavior.deferToChild, HitTestBehavior.opaque, HitTestBehavior.translucent];

export class DecorationPosition {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DecorationPosition.' + this.name; }
  static background = new DecorationPosition('background', 0);
  static foreground = new DecorationPosition('foreground', 1);
}
DecorationPosition.values = [DecorationPosition.background, DecorationPosition.foreground];

export class ScrollDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ScrollDirection.' + this.name; }
  static idle = new ScrollDirection('idle', 0);
  static forward = new ScrollDirection('forward', 1);
  static reverse = new ScrollDirection('reverse', 2);
}
ScrollDirection.values = [ScrollDirection.idle, ScrollDirection.forward, ScrollDirection.reverse];

export class SelectionResult {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SelectionResult.' + this.name; }
  static next = new SelectionResult('next', 0);
  static previous = new SelectionResult('previous', 1);
  static end = new SelectionResult('end', 2);
  static pending = new SelectionResult('pending', 3);
  static none = new SelectionResult('none', 4);
}
SelectionResult.values = [SelectionResult.next, SelectionResult.previous, SelectionResult.end, SelectionResult.pending, SelectionResult.none];

export class SelectionEventType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SelectionEventType.' + this.name; }
  static startEdgeUpdate = new SelectionEventType('startEdgeUpdate', 0);
  static endEdgeUpdate = new SelectionEventType('endEdgeUpdate', 1);
  static clear = new SelectionEventType('clear', 2);
  static selectAll = new SelectionEventType('selectAll', 3);
  static selectWord = new SelectionEventType('selectWord', 4);
  static selectParagraph = new SelectionEventType('selectParagraph', 5);
  static granularlyExtendSelection = new SelectionEventType('granularlyExtendSelection', 6);
  static directionallyExtendSelection = new SelectionEventType('directionallyExtendSelection', 7);
}
SelectionEventType.values = [SelectionEventType.startEdgeUpdate, SelectionEventType.endEdgeUpdate, SelectionEventType.clear, SelectionEventType.selectAll, SelectionEventType.selectWord, SelectionEventType.selectParagraph, SelectionEventType.granularlyExtendSelection, SelectionEventType.directionallyExtendSelection];

export class TextGranularity {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextGranularity.' + this.name; }
  static character = new TextGranularity('character', 0);
  static word = new TextGranularity('word', 1);
  static paragraph = new TextGranularity('paragraph', 2);
  static line = new TextGranularity('line', 3);
  static document = new TextGranularity('document', 4);
}
TextGranularity.values = [TextGranularity.character, TextGranularity.word, TextGranularity.paragraph, TextGranularity.line, TextGranularity.document];

export class SelectionExtendDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SelectionExtendDirection.' + this.name; }
  static previousLine = new SelectionExtendDirection('previousLine', 0);
  static nextLine = new SelectionExtendDirection('nextLine', 1);
  static forward = new SelectionExtendDirection('forward', 2);
  static backward = new SelectionExtendDirection('backward', 3);
}
SelectionExtendDirection.values = [SelectionExtendDirection.previousLine, SelectionExtendDirection.nextLine, SelectionExtendDirection.forward, SelectionExtendDirection.backward];

export class SelectionStatus {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SelectionStatus.' + this.name; }
  static uncollapsed = new SelectionStatus('uncollapsed', 0);
  static collapsed = new SelectionStatus('collapsed', 1);
  static none = new SelectionStatus('none', 2);
}
SelectionStatus.values = [SelectionStatus.uncollapsed, SelectionStatus.collapsed, SelectionStatus.none];

export class TextSelectionHandleType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextSelectionHandleType.' + this.name; }
  static left = new TextSelectionHandleType('left', 0);
  static right = new TextSelectionHandleType('right', 1);
  static collapsed = new TextSelectionHandleType('collapsed', 2);
}
TextSelectionHandleType.values = [TextSelectionHandleType.left, TextSelectionHandleType.right, TextSelectionHandleType.collapsed];

export class FlexFit {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'FlexFit.' + this.name; }
  static tight = new FlexFit('tight', 0);
  static loose = new FlexFit('loose', 1);
}
FlexFit.values = [FlexFit.tight, FlexFit.loose];

export class MainAxisSize {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'MainAxisSize.' + this.name; }
  static min = new MainAxisSize('min', 0);
  static max = new MainAxisSize('max', 1);
}
MainAxisSize.values = [MainAxisSize.min, MainAxisSize.max];

export class MainAxisAlignment {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'MainAxisAlignment.' + this.name; }
  static start = new MainAxisAlignment('start', 0);
  static end = new MainAxisAlignment('end', 1);
  static center = new MainAxisAlignment('center', 2);
  static spaceBetween = new MainAxisAlignment('spaceBetween', 3);
  static spaceAround = new MainAxisAlignment('spaceAround', 4);
  static spaceEvenly = new MainAxisAlignment('spaceEvenly', 5);
}
MainAxisAlignment.values = [MainAxisAlignment.start, MainAxisAlignment.end, MainAxisAlignment.center, MainAxisAlignment.spaceBetween, MainAxisAlignment.spaceAround, MainAxisAlignment.spaceEvenly];

export class CrossAxisAlignment {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'CrossAxisAlignment.' + this.name; }
  static start = new CrossAxisAlignment('start', 0);
  static end = new CrossAxisAlignment('end', 1);
  static center = new CrossAxisAlignment('center', 2);
  static stretch = new CrossAxisAlignment('stretch', 3);
  static baseline = new CrossAxisAlignment('baseline', 4);
}
CrossAxisAlignment.values = [CrossAxisAlignment.start, CrossAxisAlignment.end, CrossAxisAlignment.center, CrossAxisAlignment.stretch, CrossAxisAlignment.baseline];

export class TableCellVerticalAlignment {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TableCellVerticalAlignment.' + this.name; }
  static top = new TableCellVerticalAlignment('top', 0);
  static middle = new TableCellVerticalAlignment('middle', 1);
  static bottom = new TableCellVerticalAlignment('bottom', 2);
  static baseline = new TableCellVerticalAlignment('baseline', 3);
  static fill = new TableCellVerticalAlignment('fill', 4);
  static intrinsicHeight = new TableCellVerticalAlignment('intrinsicHeight', 5);
}
TableCellVerticalAlignment.values = [TableCellVerticalAlignment.top, TableCellVerticalAlignment.middle, TableCellVerticalAlignment.bottom, TableCellVerticalAlignment.baseline, TableCellVerticalAlignment.fill, TableCellVerticalAlignment.intrinsicHeight];

export class OverflowBoxFit {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'OverflowBoxFit.' + this.name; }
  static max = new OverflowBoxFit('max', 0);
  static deferToChild = new OverflowBoxFit('deferToChild', 1);
}
OverflowBoxFit.values = [OverflowBoxFit.max, OverflowBoxFit.deferToChild];

export class PerformanceOverlayOption {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PerformanceOverlayOption.' + this.name; }
  static displayRasterizerStatistics = new PerformanceOverlayOption('displayRasterizerStatistics', 0);
  static visualizeRasterizerStatistics = new PerformanceOverlayOption('visualizeRasterizerStatistics', 1);
  static displayEngineStatistics = new PerformanceOverlayOption('displayEngineStatistics', 2);
  static visualizeEngineStatistics = new PerformanceOverlayOption('visualizeEngineStatistics', 3);
}
PerformanceOverlayOption.values = [PerformanceOverlayOption.displayRasterizerStatistics, PerformanceOverlayOption.visualizeRasterizerStatistics, PerformanceOverlayOption.displayEngineStatistics, PerformanceOverlayOption.visualizeEngineStatistics];

export class CacheExtentStyle {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'CacheExtentStyle.' + this.name; }
  static pixel = new CacheExtentStyle('pixel', 0);
  static viewport = new CacheExtentStyle('viewport', 1);
}
CacheExtentStyle.values = [CacheExtentStyle.pixel, CacheExtentStyle.viewport];

export class SliverPaintOrder {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SliverPaintOrder.' + this.name; }
  static firstIsTop = new SliverPaintOrder('firstIsTop', 0);
  static lastIsTop = new SliverPaintOrder('lastIsTop', 1);
}
SliverPaintOrder.values = [SliverPaintOrder.firstIsTop, SliverPaintOrder.lastIsTop];

export class GrowthDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'GrowthDirection.' + this.name; }
  static forward = new GrowthDirection('forward', 0);
  static reverse = new GrowthDirection('reverse', 1);
}
GrowthDirection.values = [GrowthDirection.forward, GrowthDirection.reverse];

export class StackFit {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'StackFit.' + this.name; }
  static loose = new StackFit('loose', 0);
  static expand = new StackFit('expand', 1);
  static passthrough = new StackFit('passthrough', 2);
}
StackFit.values = [StackFit.loose, StackFit.expand, StackFit.passthrough];

export class PlatformViewHitTestBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PlatformViewHitTestBehavior.' + this.name; }
  static opaque = new PlatformViewHitTestBehavior('opaque', 0);
  static translucent = new PlatformViewHitTestBehavior('translucent', 1);
  static transparent = new PlatformViewHitTestBehavior('transparent', 2);
}
PlatformViewHitTestBehavior.values = [PlatformViewHitTestBehavior.opaque, PlatformViewHitTestBehavior.translucent, PlatformViewHitTestBehavior.transparent];

export class RenderingServiceExtensions {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'RenderingServiceExtensions.' + this.name; }
  static invertOversizedImages = new RenderingServiceExtensions('invertOversizedImages', 0);
  static debugPaint = new RenderingServiceExtensions('debugPaint', 1);
  static debugPaintBaselinesEnabled = new RenderingServiceExtensions('debugPaintBaselinesEnabled', 2);
  static repaintRainbow = new RenderingServiceExtensions('repaintRainbow', 3);
  static debugDumpLayerTree = new RenderingServiceExtensions('debugDumpLayerTree', 4);
  static debugDisableClipLayers = new RenderingServiceExtensions('debugDisableClipLayers', 5);
  static debugDisablePhysicalShapeLayers = new RenderingServiceExtensions('debugDisablePhysicalShapeLayers', 6);
  static debugDisableOpacityLayers = new RenderingServiceExtensions('debugDisableOpacityLayers', 7);
  static debugDumpRenderTree = new RenderingServiceExtensions('debugDumpRenderTree', 8);
  static debugDumpSemanticsTreeInTraversalOrder = new RenderingServiceExtensions('debugDumpSemanticsTreeInTraversalOrder', 9);
  static debugDumpSemanticsTreeInInverseHitTestOrder = new RenderingServiceExtensions('debugDumpSemanticsTreeInInverseHitTestOrder', 10);
  static profileRenderObjectPaints = new RenderingServiceExtensions('profileRenderObjectPaints', 11);
  static profileRenderObjectLayouts = new RenderingServiceExtensions('profileRenderObjectLayouts', 12);
}
RenderingServiceExtensions.values = [RenderingServiceExtensions.invertOversizedImages, RenderingServiceExtensions.debugPaint, RenderingServiceExtensions.debugPaintBaselinesEnabled, RenderingServiceExtensions.repaintRainbow, RenderingServiceExtensions.debugDumpLayerTree, RenderingServiceExtensions.debugDisableClipLayers, RenderingServiceExtensions.debugDisablePhysicalShapeLayers, RenderingServiceExtensions.debugDisableOpacityLayers, RenderingServiceExtensions.debugDumpRenderTree, RenderingServiceExtensions.debugDumpSemanticsTreeInTraversalOrder, RenderingServiceExtensions.debugDumpSemanticsTreeInInverseHitTestOrder, RenderingServiceExtensions.profileRenderObjectPaints, RenderingServiceExtensions.profileRenderObjectLayouts];

export class RenderAnimatedSizeState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'RenderAnimatedSizeState.' + this.name; }
  static start = new RenderAnimatedSizeState('start', 0);
  static stable = new RenderAnimatedSizeState('stable', 1);
  static changed = new RenderAnimatedSizeState('changed', 2);
  static unstable = new RenderAnimatedSizeState('unstable', 3);
}
RenderAnimatedSizeState.values = [RenderAnimatedSizeState.start, RenderAnimatedSizeState.stable, RenderAnimatedSizeState.changed, RenderAnimatedSizeState.unstable];

export class SpringType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SpringType.' + this.name; }
  static criticallyDamped = new SpringType('criticallyDamped', 0);
  static underDamped = new SpringType('underDamped', 1);
  static overDamped = new SpringType('overDamped', 2);
}
SpringType.values = [SpringType.criticallyDamped, SpringType.underDamped, SpringType.overDamped];

export class OverlayVisibilityMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'OverlayVisibilityMode.' + this.name; }
  static never = new OverlayVisibilityMode('never', 0);
  static editing = new OverlayVisibilityMode('editing', 1);
  static notEditing = new OverlayVisibilityMode('notEditing', 2);
  static always = new OverlayVisibilityMode('always', 3);
}
OverlayVisibilityMode.values = [OverlayVisibilityMode.never, OverlayVisibilityMode.editing, OverlayVisibilityMode.notEditing, OverlayVisibilityMode.always];

export class CupertinoButtonSize {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'CupertinoButtonSize.' + this.name; }
  static small = new CupertinoButtonSize('small', 0);
  static medium = new CupertinoButtonSize('medium', 1);
  static large = new CupertinoButtonSize('large', 2);
}
CupertinoButtonSize.values = [CupertinoButtonSize.small, CupertinoButtonSize.medium, CupertinoButtonSize.large];

export class CupertinoDatePickerMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'CupertinoDatePickerMode.' + this.name; }
  static time = new CupertinoDatePickerMode('time', 0);
  static date = new CupertinoDatePickerMode('date', 1);
  static dateAndTime = new CupertinoDatePickerMode('dateAndTime', 2);
  static monthYear = new CupertinoDatePickerMode('monthYear', 3);
}
CupertinoDatePickerMode.values = [CupertinoDatePickerMode.time, CupertinoDatePickerMode.date, CupertinoDatePickerMode.dateAndTime, CupertinoDatePickerMode.monthYear];

export class CupertinoTimerPickerMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'CupertinoTimerPickerMode.' + this.name; }
  static hm = new CupertinoTimerPickerMode('hm', 0);
  static ms = new CupertinoTimerPickerMode('ms', 1);
  static hms = new CupertinoTimerPickerMode('hms', 2);
}
CupertinoTimerPickerMode.values = [CupertinoTimerPickerMode.hm, CupertinoTimerPickerMode.ms, CupertinoTimerPickerMode.hms];

export class RefreshIndicatorMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'RefreshIndicatorMode.' + this.name; }
  static inactive = new RefreshIndicatorMode('inactive', 0);
  static drag = new RefreshIndicatorMode('drag', 1);
  static armed = new RefreshIndicatorMode('armed', 2);
  static refresh = new RefreshIndicatorMode('refresh', 3);
  static done = new RefreshIndicatorMode('done', 4);
}
RefreshIndicatorMode.values = [RefreshIndicatorMode.inactive, RefreshIndicatorMode.drag, RefreshIndicatorMode.armed, RefreshIndicatorMode.refresh, RefreshIndicatorMode.done];

export class ExpansionTileTransitionMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ExpansionTileTransitionMode.' + this.name; }
  static fade = new ExpansionTileTransitionMode('fade', 0);
  static scroll = new ExpansionTileTransitionMode('scroll', 1);
}
ExpansionTileTransitionMode.values = [ExpansionTileTransitionMode.fade, ExpansionTileTransitionMode.scroll];

export class CupertinoListSectionType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'CupertinoListSectionType.' + this.name; }
  static base = new CupertinoListSectionType('base', 0);
  static insetGrouped = new CupertinoListSectionType('insetGrouped', 1);
}
CupertinoListSectionType.values = [CupertinoListSectionType.base, CupertinoListSectionType.insetGrouped];

export class CupertinoUserInterfaceLevelData {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'CupertinoUserInterfaceLevelData.' + this.name; }
  static base = new CupertinoUserInterfaceLevelData('base', 0);
  static elevated = new CupertinoUserInterfaceLevelData('elevated', 1);
}
CupertinoUserInterfaceLevelData.values = [CupertinoUserInterfaceLevelData.base, CupertinoUserInterfaceLevelData.elevated];

export class NavigationBarBottomMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'NavigationBarBottomMode.' + this.name; }
  static automatic = new NavigationBarBottomMode('automatic', 0);
  static always = new NavigationBarBottomMode('always', 1);
}
NavigationBarBottomMode.values = [NavigationBarBottomMode.automatic, NavigationBarBottomMode.always];

export class DatePickerDateTimeOrder {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DatePickerDateTimeOrder.' + this.name; }
  static date_time_dayPeriod = new DatePickerDateTimeOrder('date_time_dayPeriod', 0);
  static date_dayPeriod_time = new DatePickerDateTimeOrder('date_dayPeriod_time', 1);
  static time_dayPeriod_date = new DatePickerDateTimeOrder('time_dayPeriod_date', 2);
  static dayPeriod_time_date = new DatePickerDateTimeOrder('dayPeriod_time_date', 3);
}
DatePickerDateTimeOrder.values = [DatePickerDateTimeOrder.date_time_dayPeriod, DatePickerDateTimeOrder.date_dayPeriod_time, DatePickerDateTimeOrder.time_dayPeriod_date, DatePickerDateTimeOrder.dayPeriod_time_date];

export class DatePickerDateOrder {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DatePickerDateOrder.' + this.name; }
  static dmy = new DatePickerDateOrder('dmy', 0);
  static mdy = new DatePickerDateOrder('mdy', 1);
  static ymd = new DatePickerDateOrder('ymd', 2);
  static ydm = new DatePickerDateOrder('ydm', 3);
}
DatePickerDateOrder.values = [DatePickerDateOrder.dmy, DatePickerDateOrder.mdy, DatePickerDateOrder.ymd, DatePickerDateOrder.ydm];

export class MaterialType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'MaterialType.' + this.name; }
  static canvas = new MaterialType('canvas', 0);
  static card = new MaterialType('card', 1);
  static circle = new MaterialType('circle', 2);
  static button = new MaterialType('button', 3);
  static transparency = new MaterialType('transparency', 4);
}
MaterialType.values = [MaterialType.canvas, MaterialType.card, MaterialType.circle, MaterialType.button, MaterialType.transparency];

export class NavigationDestinationLabelBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'NavigationDestinationLabelBehavior.' + this.name; }
  static alwaysShow = new NavigationDestinationLabelBehavior('alwaysShow', 0);
  static alwaysHide = new NavigationDestinationLabelBehavior('alwaysHide', 1);
  static onlyShowSelected = new NavigationDestinationLabelBehavior('onlyShowSelected', 2);
}
NavigationDestinationLabelBehavior.values = [NavigationDestinationLabelBehavior.alwaysShow, NavigationDestinationLabelBehavior.alwaysHide, NavigationDestinationLabelBehavior.onlyShowSelected];

export class RefreshIndicatorStatus {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'RefreshIndicatorStatus.' + this.name; }
  static drag = new RefreshIndicatorStatus('drag', 0);
  static armed = new RefreshIndicatorStatus('armed', 1);
  static snap = new RefreshIndicatorStatus('snap', 2);
  static refresh = new RefreshIndicatorStatus('refresh', 3);
  static done = new RefreshIndicatorStatus('done', 4);
  static canceled = new RefreshIndicatorStatus('canceled', 5);
}
RefreshIndicatorStatus.values = [RefreshIndicatorStatus.drag, RefreshIndicatorStatus.armed, RefreshIndicatorStatus.snap, RefreshIndicatorStatus.refresh, RefreshIndicatorStatus.done, RefreshIndicatorStatus.canceled];

export class RefreshIndicatorTriggerMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'RefreshIndicatorTriggerMode.' + this.name; }
  static anywhere = new RefreshIndicatorTriggerMode('anywhere', 0);
  static onEdge = new RefreshIndicatorTriggerMode('onEdge', 1);
}
RefreshIndicatorTriggerMode.values = [RefreshIndicatorTriggerMode.anywhere, RefreshIndicatorTriggerMode.onEdge];

export class SnackBarClosedReason {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SnackBarClosedReason.' + this.name; }
  static action = new SnackBarClosedReason('action', 0);
  static dismiss = new SnackBarClosedReason('dismiss', 1);
  static swipe = new SnackBarClosedReason('swipe', 2);
  static hide = new SnackBarClosedReason('hide', 3);
  static remove = new SnackBarClosedReason('remove', 4);
  static timeout = new SnackBarClosedReason('timeout', 5);
}
SnackBarClosedReason.values = [SnackBarClosedReason.action, SnackBarClosedReason.dismiss, SnackBarClosedReason.swipe, SnackBarClosedReason.hide, SnackBarClosedReason.remove, SnackBarClosedReason.timeout];

export class FloatingLabelBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'FloatingLabelBehavior.' + this.name; }
  static never = new FloatingLabelBehavior('never', 0);
  static auto = new FloatingLabelBehavior('auto', 1);
  static always = new FloatingLabelBehavior('always', 2);
}
FloatingLabelBehavior.values = [FloatingLabelBehavior.never, FloatingLabelBehavior.auto, FloatingLabelBehavior.always];

export class DynamicSchemeVariant {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DynamicSchemeVariant.' + this.name; }
  static tonalSpot = new DynamicSchemeVariant('tonalSpot', 0);
  static fidelity = new DynamicSchemeVariant('fidelity', 1);
  static monochrome = new DynamicSchemeVariant('monochrome', 2);
  static neutral = new DynamicSchemeVariant('neutral', 3);
  static vibrant = new DynamicSchemeVariant('vibrant', 4);
  static expressive = new DynamicSchemeVariant('expressive', 5);
  static content = new DynamicSchemeVariant('content', 6);
  static rainbow = new DynamicSchemeVariant('rainbow', 7);
  static fruitSalad = new DynamicSchemeVariant('fruitSalad', 8);
}
DynamicSchemeVariant.values = [DynamicSchemeVariant.tonalSpot, DynamicSchemeVariant.fidelity, DynamicSchemeVariant.monochrome, DynamicSchemeVariant.neutral, DynamicSchemeVariant.vibrant, DynamicSchemeVariant.expressive, DynamicSchemeVariant.content, DynamicSchemeVariant.rainbow, DynamicSchemeVariant.fruitSalad];

export class DayPeriod {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DayPeriod.' + this.name; }
  static am = new DayPeriod('am', 0);
  static pm = new DayPeriod('pm', 1);
}
DayPeriod.values = [DayPeriod.am, DayPeriod.pm];

export class TimeOfDayFormat {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TimeOfDayFormat.' + this.name; }
  static HH_colon_mm = new TimeOfDayFormat('HH_colon_mm', 0);
  static HH_dot_mm = new TimeOfDayFormat('HH_dot_mm', 1);
  static frenchCanadian = new TimeOfDayFormat('frenchCanadian', 2);
  static H_colon_mm = new TimeOfDayFormat('H_colon_mm', 3);
  static h_colon_mm_space_a = new TimeOfDayFormat('h_colon_mm_space_a', 4);
  static a_space_h_colon_mm = new TimeOfDayFormat('a_space_h_colon_mm', 5);
}
TimeOfDayFormat.values = [TimeOfDayFormat.HH_colon_mm, TimeOfDayFormat.HH_dot_mm, TimeOfDayFormat.frenchCanadian, TimeOfDayFormat.H_colon_mm, TimeOfDayFormat.h_colon_mm_space_a, TimeOfDayFormat.a_space_h_colon_mm];

export class HourFormat {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'HourFormat.' + this.name; }
  static HH = new HourFormat('HH', 0);
  static H = new HourFormat('H', 1);
  static h = new HourFormat('h', 2);
}
HourFormat.values = [HourFormat.HH, HourFormat.H, HourFormat.h];

export class PopupMenuPosition {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PopupMenuPosition.' + this.name; }
  static over = new PopupMenuPosition('over', 0);
  static under = new PopupMenuPosition('under', 1);
}
PopupMenuPosition.values = [PopupMenuPosition.over, PopupMenuPosition.under];

export class NavigationRailLabelType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'NavigationRailLabelType.' + this.name; }
  static none = new NavigationRailLabelType('none', 0);
  static selected = new NavigationRailLabelType('selected', 1);
  static all = new NavigationRailLabelType('all', 2);
}
NavigationRailLabelType.values = [NavigationRailLabelType.none, NavigationRailLabelType.selected, NavigationRailLabelType.all];

export class TimePickerEntryMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TimePickerEntryMode.' + this.name; }
  static dial = new TimePickerEntryMode('dial', 0);
  static input = new TimePickerEntryMode('input', 1);
  static dialOnly = new TimePickerEntryMode('dialOnly', 2);
  static inputOnly = new TimePickerEntryMode('inputOnly', 3);
}
TimePickerEntryMode.values = [TimePickerEntryMode.dial, TimePickerEntryMode.input, TimePickerEntryMode.dialOnly, TimePickerEntryMode.inputOnly];

export class StepState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'StepState.' + this.name; }
  static indexed = new StepState('indexed', 0);
  static editing = new StepState('editing', 1);
  static complete = new StepState('complete', 2);
  static disabled = new StepState('disabled', 3);
  static error = new StepState('error', 4);
}
StepState.values = [StepState.indexed, StepState.editing, StepState.complete, StepState.disabled, StepState.error];

export class StepperType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'StepperType.' + this.name; }
  static vertical = new StepperType('vertical', 0);
  static horizontal = new StepperType('horizontal', 1);
}
StepperType.values = [StepperType.vertical, StepperType.horizontal];

export class TabBarIndicatorSize {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TabBarIndicatorSize.' + this.name; }
  static tab = new TabBarIndicatorSize('tab', 0);
  static label = new TabBarIndicatorSize('label', 1);
}
TabBarIndicatorSize.values = [TabBarIndicatorSize.tab, TabBarIndicatorSize.label];

export class TabAlignment {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TabAlignment.' + this.name; }
  static start = new TabAlignment('start', 0);
  static startOffset = new TabAlignment('startOffset', 1);
  static fill = new TabAlignment('fill', 2);
  static center = new TabAlignment('center', 3);
}
TabAlignment.values = [TabAlignment.start, TabAlignment.startOffset, TabAlignment.fill, TabAlignment.center];

export class TabIndicatorAnimation {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TabIndicatorAnimation.' + this.name; }
  static linear = new TabIndicatorAnimation('linear', 0);
  static elastic = new TabIndicatorAnimation('elastic', 1);
}
TabIndicatorAnimation.values = [TabIndicatorAnimation.linear, TabIndicatorAnimation.elastic];

export class MaterialBannerClosedReason {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'MaterialBannerClosedReason.' + this.name; }
  static dismiss = new MaterialBannerClosedReason('dismiss', 0);
  static swipe = new MaterialBannerClosedReason('swipe', 1);
  static hide = new MaterialBannerClosedReason('hide', 2);
  static remove = new MaterialBannerClosedReason('remove', 3);
}
MaterialBannerClosedReason.values = [MaterialBannerClosedReason.dismiss, MaterialBannerClosedReason.swipe, MaterialBannerClosedReason.hide, MaterialBannerClosedReason.remove];

export class DropdownMenuCloseBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DropdownMenuCloseBehavior.' + this.name; }
  static all = new DropdownMenuCloseBehavior('all', 0);
  static self = new DropdownMenuCloseBehavior('self', 1);
  static none = new DropdownMenuCloseBehavior('none', 2);
}
DropdownMenuCloseBehavior.values = [DropdownMenuCloseBehavior.all, DropdownMenuCloseBehavior.self, DropdownMenuCloseBehavior.none];

export class SliderInteraction {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SliderInteraction.' + this.name; }
  static tapAndSlide = new SliderInteraction('tapAndSlide', 0);
  static tapOnly = new SliderInteraction('tapOnly', 1);
  static slideOnly = new SliderInteraction('slideOnly', 2);
  static slideThumb = new SliderInteraction('slideThumb', 3);
}
SliderInteraction.values = [SliderInteraction.tapAndSlide, SliderInteraction.tapOnly, SliderInteraction.slideOnly, SliderInteraction.slideThumb];

export class ButtonTextTheme {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ButtonTextTheme.' + this.name; }
  static normal = new ButtonTextTheme('normal', 0);
  static accent = new ButtonTextTheme('accent', 1);
  static primary = new ButtonTextTheme('primary', 2);
}
ButtonTextTheme.values = [ButtonTextTheme.normal, ButtonTextTheme.accent, ButtonTextTheme.primary];

export class ButtonBarLayoutBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ButtonBarLayoutBehavior.' + this.name; }
  static constrained = new ButtonBarLayoutBehavior('constrained', 0);
  static padded = new ButtonBarLayoutBehavior('padded', 1);
}
ButtonBarLayoutBehavior.values = [ButtonBarLayoutBehavior.constrained, ButtonBarLayoutBehavior.padded];

export class ListTileStyle {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ListTileStyle.' + this.name; }
  static list = new ListTileStyle('list', 0);
  static drawer = new ListTileStyle('drawer', 1);
}
ListTileStyle.values = [ListTileStyle.list, ListTileStyle.drawer];

export class ListTileControlAffinity {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ListTileControlAffinity.' + this.name; }
  static leading = new ListTileControlAffinity('leading', 0);
  static trailing = new ListTileControlAffinity('trailing', 1);
  static platform = new ListTileControlAffinity('platform', 2);
}
ListTileControlAffinity.values = [ListTileControlAffinity.leading, ListTileControlAffinity.trailing, ListTileControlAffinity.platform];

export class ListTileTitleAlignment {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ListTileTitleAlignment.' + this.name; }
  static threeLine = new ListTileTitleAlignment('threeLine', 0);
  static titleHeight = new ListTileTitleAlignment('titleHeight', 1);
  static top = new ListTileTitleAlignment('top', 2);
  static center = new ListTileTitleAlignment('center', 3);
  static bottom = new ListTileTitleAlignment('bottom', 4);
}
ListTileTitleAlignment.values = [ListTileTitleAlignment.threeLine, ListTileTitleAlignment.titleHeight, ListTileTitleAlignment.top, ListTileTitleAlignment.center, ListTileTitleAlignment.bottom];

export class ScriptCategory {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ScriptCategory.' + this.name; }
  static englishLike = new ScriptCategory('englishLike', 0);
  static dense = new ScriptCategory('dense', 1);
  static tall = new ScriptCategory('tall', 2);
}
ScriptCategory.values = [ScriptCategory.englishLike, ScriptCategory.dense, ScriptCategory.tall];

export class ShowValueIndicator {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ShowValueIndicator.' + this.name; }
  static onlyForDiscrete = new ShowValueIndicator('onlyForDiscrete', 0);
  static onlyForContinuous = new ShowValueIndicator('onlyForContinuous', 1);
  static always = new ShowValueIndicator('always', 2);
  static onDrag = new ShowValueIndicator('onDrag', 3);
  static alwaysVisible = new ShowValueIndicator('alwaysVisible', 4);
  static never = new ShowValueIndicator('never', 5);
}
ShowValueIndicator.values = [ShowValueIndicator.onlyForDiscrete, ShowValueIndicator.onlyForContinuous, ShowValueIndicator.always, ShowValueIndicator.onDrag, ShowValueIndicator.alwaysVisible, ShowValueIndicator.never];

export class Thumb {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'Thumb.' + this.name; }
  static start = new Thumb('start', 0);
  static end = new Thumb('end', 1);
}
Thumb.values = [Thumb.start, Thumb.end];

export class DrawerAlignment {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DrawerAlignment.' + this.name; }
  static start = new DrawerAlignment('start', 0);
  static end = new DrawerAlignment('end', 1);
}
DrawerAlignment.values = [DrawerAlignment.start, DrawerAlignment.end];

export class DatePickerEntryMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DatePickerEntryMode.' + this.name; }
  static calendar = new DatePickerEntryMode('calendar', 0);
  static input = new DatePickerEntryMode('input', 1);
  static calendarOnly = new DatePickerEntryMode('calendarOnly', 2);
  static inputOnly = new DatePickerEntryMode('inputOnly', 3);
}
DatePickerEntryMode.values = [DatePickerEntryMode.calendar, DatePickerEntryMode.input, DatePickerEntryMode.calendarOnly, DatePickerEntryMode.inputOnly];

export class DatePickerMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DatePickerMode.' + this.name; }
  static day = new DatePickerMode('day', 0);
  static year = new DatePickerMode('year', 1);
}
DatePickerMode.values = [DatePickerMode.day, DatePickerMode.year];

export class SnackBarBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SnackBarBehavior.' + this.name; }
  static fixed = new SnackBarBehavior('fixed', 0);
  static floating = new SnackBarBehavior('floating', 1);
}
SnackBarBehavior.values = [SnackBarBehavior.fixed, SnackBarBehavior.floating];

export class MaterialTapTargetSize {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'MaterialTapTargetSize.' + this.name; }
  static padded = new MaterialTapTargetSize('padded', 0);
  static shrinkWrap = new MaterialTapTargetSize('shrinkWrap', 1);
}
MaterialTapTargetSize.values = [MaterialTapTargetSize.padded, MaterialTapTargetSize.shrinkWrap];

export class CollapseMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'CollapseMode.' + this.name; }
  static parallax = new CollapseMode('parallax', 0);
  static pin = new CollapseMode('pin', 1);
  static none = new CollapseMode('none', 2);
}
CollapseMode.values = [CollapseMode.parallax, CollapseMode.pin, CollapseMode.none];

export class StretchMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'StretchMode.' + this.name; }
  static zoomBackground = new StretchMode('zoomBackground', 0);
  static blurBackground = new StretchMode('blurBackground', 1);
  static fadeTitle = new StretchMode('fadeTitle', 2);
}
StretchMode.values = [StretchMode.zoomBackground, StretchMode.blurBackground, StretchMode.fadeTitle];

export class IconAlignment {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'IconAlignment.' + this.name; }
  static start = new IconAlignment('start', 0);
  static end = new IconAlignment('end', 1);
}
IconAlignment.values = [IconAlignment.start, IconAlignment.end];

export class BottomNavigationBarType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'BottomNavigationBarType.' + this.name; }
  static fixed = new BottomNavigationBarType('fixed', 0);
  static shifting = new BottomNavigationBarType('shifting', 1);
}
BottomNavigationBarType.values = [BottomNavigationBarType.fixed, BottomNavigationBarType.shifting];

export class BottomNavigationBarLandscapeLayout {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'BottomNavigationBarLandscapeLayout.' + this.name; }
  static spread = new BottomNavigationBarLandscapeLayout('spread', 0);
  static centered = new BottomNavigationBarLandscapeLayout('centered', 1);
  static linear = new BottomNavigationBarLandscapeLayout('linear', 2);
}
BottomNavigationBarLandscapeLayout.values = [BottomNavigationBarLandscapeLayout.spread, BottomNavigationBarLandscapeLayout.centered, BottomNavigationBarLandscapeLayout.linear];

export class ThemeMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ThemeMode.' + this.name; }
  static system = new ThemeMode('system', 0);
  static light = new ThemeMode('light', 1);
  static dark = new ThemeMode('dark', 2);
}
ThemeMode.values = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

export class KeyDataTransitMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'KeyDataTransitMode.' + this.name; }
  static rawKeyData = new KeyDataTransitMode('rawKeyData', 0);
  static keyDataThenRawKeyData = new KeyDataTransitMode('keyDataThenRawKeyData', 1);
}
KeyDataTransitMode.values = [KeyDataTransitMode.rawKeyData, KeyDataTransitMode.keyDataThenRawKeyData];

export class SystemSoundType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SystemSoundType.' + this.name; }
  static click = new SystemSoundType('click', 0);
  static tick = new SystemSoundType('tick', 1);
  static alert = new SystemSoundType('alert', 2);
}
SystemSoundType.values = [SystemSoundType.click, SystemSoundType.tick, SystemSoundType.alert];

export class SmartDashesType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SmartDashesType.' + this.name; }
  static disabled = new SmartDashesType('disabled', 0);
  static enabled = new SmartDashesType('enabled', 1);
}
SmartDashesType.values = [SmartDashesType.disabled, SmartDashesType.enabled];

export class SmartQuotesType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SmartQuotesType.' + this.name; }
  static disabled = new SmartQuotesType('disabled', 0);
  static enabled = new SmartQuotesType('enabled', 1);
}
SmartQuotesType.values = [SmartQuotesType.disabled, SmartQuotesType.enabled];

export class TextInputAction {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextInputAction.' + this.name; }
  static none = new TextInputAction('none', 0);
  static unspecified = new TextInputAction('unspecified', 1);
  static done = new TextInputAction('done', 2);
  static go = new TextInputAction('go', 3);
  static search = new TextInputAction('search', 4);
  static send = new TextInputAction('send', 5);
  static next = new TextInputAction('next', 6);
  static previous = new TextInputAction('previous', 7);
  static continueAction = new TextInputAction('continueAction', 8);
  static join = new TextInputAction('join', 9);
  static route = new TextInputAction('route', 10);
  static emergencyCall = new TextInputAction('emergencyCall', 11);
  static newline = new TextInputAction('newline', 12);
}
TextInputAction.values = [TextInputAction.none, TextInputAction.unspecified, TextInputAction.done, TextInputAction.go, TextInputAction.search, TextInputAction.send, TextInputAction.next, TextInputAction.previous, TextInputAction.continueAction, TextInputAction.join, TextInputAction.route, TextInputAction.emergencyCall, TextInputAction.newline];

export class TextCapitalization {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextCapitalization.' + this.name; }
  static words = new TextCapitalization('words', 0);
  static sentences = new TextCapitalization('sentences', 1);
  static characters = new TextCapitalization('characters', 2);
  static none = new TextCapitalization('none', 3);
}
TextCapitalization.values = [TextCapitalization.words, TextCapitalization.sentences, TextCapitalization.characters, TextCapitalization.none];

export class FloatingCursorDragState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'FloatingCursorDragState.' + this.name; }
  static Start = new FloatingCursorDragState('Start', 0);
  static Update = new FloatingCursorDragState('Update', 1);
  static End = new FloatingCursorDragState('End', 2);
}
FloatingCursorDragState.values = [FloatingCursorDragState.Start, FloatingCursorDragState.Update, FloatingCursorDragState.End];

export class SelectionChangedCause {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SelectionChangedCause.' + this.name; }
  static tap = new SelectionChangedCause('tap', 0);
  static doubleTap = new SelectionChangedCause('doubleTap', 1);
  static longPress = new SelectionChangedCause('longPress', 2);
  static forcePress = new SelectionChangedCause('forcePress', 3);
  static keyboard = new SelectionChangedCause('keyboard', 4);
  static toolbar = new SelectionChangedCause('toolbar', 5);
  static drag = new SelectionChangedCause('drag', 6);
  static stylusHandwriting = new SelectionChangedCause('stylusHandwriting', 7);
}
SelectionChangedCause.values = [SelectionChangedCause.tap, SelectionChangedCause.doubleTap, SelectionChangedCause.longPress, SelectionChangedCause.forcePress, SelectionChangedCause.keyboard, SelectionChangedCause.toolbar, SelectionChangedCause.drag, SelectionChangedCause.stylusHandwriting];

export class MaxLengthEnforcement {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'MaxLengthEnforcement.' + this.name; }
  static none = new MaxLengthEnforcement('none', 0);
  static enforced = new MaxLengthEnforcement('enforced', 1);
  static truncateAfterCompositionEnds = new MaxLengthEnforcement('truncateAfterCompositionEnds', 2);
}
MaxLengthEnforcement.values = [MaxLengthEnforcement.none, MaxLengthEnforcement.enforced, MaxLengthEnforcement.truncateAfterCompositionEnds];

export class SwipeEdge {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SwipeEdge.' + this.name; }
  static left = new SwipeEdge('left', 0);
  static right = new SwipeEdge('right', 1);
}
SwipeEdge.values = [SwipeEdge.left, SwipeEdge.right];

export class UndoDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'UndoDirection.' + this.name; }
  static undo = new UndoDirection('undo', 0);
  static redo = new UndoDirection('redo', 1);
}
UndoDirection.values = [UndoDirection.undo, UndoDirection.redo];

export class DeviceOrientation {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DeviceOrientation.' + this.name; }
  static portraitUp = new DeviceOrientation('portraitUp', 0);
  static landscapeLeft = new DeviceOrientation('landscapeLeft', 1);
  static portraitDown = new DeviceOrientation('portraitDown', 2);
  static landscapeRight = new DeviceOrientation('landscapeRight', 3);
}
DeviceOrientation.values = [DeviceOrientation.portraitUp, DeviceOrientation.landscapeLeft, DeviceOrientation.portraitDown, DeviceOrientation.landscapeRight];

export class SystemUiOverlay {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SystemUiOverlay.' + this.name; }
  static top = new SystemUiOverlay('top', 0);
  static bottom = new SystemUiOverlay('bottom', 1);
}
SystemUiOverlay.values = [SystemUiOverlay.top, SystemUiOverlay.bottom];

export class SystemUiMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SystemUiMode.' + this.name; }
  static leanBack = new SystemUiMode('leanBack', 0);
  static immersive = new SystemUiMode('immersive', 1);
  static immersiveSticky = new SystemUiMode('immersiveSticky', 2);
  static edgeToEdge = new SystemUiMode('edgeToEdge', 3);
  static manual = new SystemUiMode('manual', 4);
}
SystemUiMode.values = [SystemUiMode.leanBack, SystemUiMode.immersive, SystemUiMode.immersiveSticky, SystemUiMode.edgeToEdge, SystemUiMode.manual];

export class ContentSensitivity {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ContentSensitivity.' + this.name; }
  static autoSensitive = new ContentSensitivity('autoSensitive', 0);
  static sensitive = new ContentSensitivity('sensitive', 1);
  static notSensitive = new ContentSensitivity('notSensitive', 2);
  static _unknown = new ContentSensitivity('_unknown', 3);
}
ContentSensitivity.values = [ContentSensitivity.autoSensitive, ContentSensitivity.sensitive, ContentSensitivity.notSensitive, ContentSensitivity._unknown];

export class KeyboardSide {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'KeyboardSide.' + this.name; }
  static any = new KeyboardSide('any', 0);
  static left = new KeyboardSide('left', 1);
  static right = new KeyboardSide('right', 2);
  static all = new KeyboardSide('all', 3);
}
KeyboardSide.values = [KeyboardSide.any, KeyboardSide.left, KeyboardSide.right, KeyboardSide.all];

export class ModifierKey {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ModifierKey.' + this.name; }
  static controlModifier = new ModifierKey('controlModifier', 0);
  static shiftModifier = new ModifierKey('shiftModifier', 1);
  static altModifier = new ModifierKey('altModifier', 2);
  static metaModifier = new ModifierKey('metaModifier', 3);
  static capsLockModifier = new ModifierKey('capsLockModifier', 4);
  static numLockModifier = new ModifierKey('numLockModifier', 5);
  static scrollLockModifier = new ModifierKey('scrollLockModifier', 6);
  static functionModifier = new ModifierKey('functionModifier', 7);
  static symbolModifier = new ModifierKey('symbolModifier', 8);
}
ModifierKey.values = [ModifierKey.controlModifier, ModifierKey.shiftModifier, ModifierKey.altModifier, ModifierKey.metaModifier, ModifierKey.capsLockModifier, ModifierKey.numLockModifier, ModifierKey.scrollLockModifier, ModifierKey.functionModifier, ModifierKey.symbolModifier];

export class ServicesServiceExtensions {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ServicesServiceExtensions.' + this.name; }
  static profilePlatformChannels = new ServicesServiceExtensions('profilePlatformChannels', 0);
  static evict = new ServicesServiceExtensions('evict', 1);
}
ServicesServiceExtensions.values = [ServicesServiceExtensions.profilePlatformChannels, ServicesServiceExtensions.evict];

export class CrossFadeState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'CrossFadeState.' + this.name; }
  static showFirst = new CrossFadeState('showFirst', 0);
  static showSecond = new CrossFadeState('showSecond', 1);
}
CrossFadeState.values = [CrossFadeState.showFirst, CrossFadeState.showSecond];

export class ScrollIncrementType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ScrollIncrementType.' + this.name; }
  static line = new ScrollIncrementType('line', 0);
  static page = new ScrollIncrementType('page', 1);
}
ScrollIncrementType.values = [ScrollIncrementType.line, ScrollIncrementType.page];

export class RouteInformationReportingType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'RouteInformationReportingType.' + this.name; }
  static none = new RouteInformationReportingType('none', 0);
  static neglect = new RouteInformationReportingType('neglect', 1);
  static navigate = new RouteInformationReportingType('navigate', 2);
}
RouteInformationReportingType.values = [RouteInformationReportingType.none, RouteInformationReportingType.neglect, RouteInformationReportingType.navigate];

export class WidgetState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'WidgetState.' + this.name; }
  static hovered = new WidgetState('hovered', 0);
  static focused = new WidgetState('focused', 1);
  static pressed = new WidgetState('pressed', 2);
  static dragged = new WidgetState('dragged', 3);
  static selected = new WidgetState('selected', 4);
  static scrolledUnder = new WidgetState('scrolledUnder', 5);
  static disabled = new WidgetState('disabled', 6);
  static error = new WidgetState('error', 7);
}
WidgetState.values = [WidgetState.hovered, WidgetState.focused, WidgetState.pressed, WidgetState.dragged, WidgetState.selected, WidgetState.scrolledUnder, WidgetState.disabled, WidgetState.error];

export class ConnectionState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ConnectionState.' + this.name; }
  static none = new ConnectionState('none', 0);
  static waiting = new ConnectionState('waiting', 1);
  static active = new ConnectionState('active', 2);
  static done = new ConnectionState('done', 3);
}
ConnectionState.values = [ConnectionState.none, ConnectionState.waiting, ConnectionState.active, ConnectionState.done];

export class AutovalidateMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'AutovalidateMode.' + this.name; }
  static disabled = new AutovalidateMode('disabled', 0);
  static always = new AutovalidateMode('always', 1);
  static onUserInteraction = new AutovalidateMode('onUserInteraction', 2);
  static onUnfocus = new AutovalidateMode('onUnfocus', 3);
  static onUserInteractionIfError = new AutovalidateMode('onUserInteractionIfError', 4);
}
AutovalidateMode.values = [AutovalidateMode.disabled, AutovalidateMode.always, AutovalidateMode.onUserInteraction, AutovalidateMode.onUnfocus, AutovalidateMode.onUserInteractionIfError];

export class ContextMenuButtonType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ContextMenuButtonType.' + this.name; }
  static cut = new ContextMenuButtonType('cut', 0);
  static copy = new ContextMenuButtonType('copy', 1);
  static paste = new ContextMenuButtonType('paste', 2);
  static selectAll = new ContextMenuButtonType('selectAll', 3);
  static delete = new ContextMenuButtonType('delete', 4);
  static lookUp = new ContextMenuButtonType('lookUp', 5);
  static searchWeb = new ContextMenuButtonType('searchWeb', 6);
  static share = new ContextMenuButtonType('share', 7);
  static liveTextInput = new ContextMenuButtonType('liveTextInput', 8);
  static custom = new ContextMenuButtonType('custom', 9);
}
ContextMenuButtonType.values = [ContextMenuButtonType.cut, ContextMenuButtonType.copy, ContextMenuButtonType.paste, ContextMenuButtonType.selectAll, ContextMenuButtonType.delete, ContextMenuButtonType.lookUp, ContextMenuButtonType.searchWeb, ContextMenuButtonType.share, ContextMenuButtonType.liveTextInput, ContextMenuButtonType.custom];

export class RoutePopDisposition {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'RoutePopDisposition.' + this.name; }
  static pop = new RoutePopDisposition('pop', 0);
  static doNotPop = new RoutePopDisposition('doNotPop', 1);
  static bubble = new RoutePopDisposition('bubble', 2);
}
RoutePopDisposition.values = [RoutePopDisposition.pop, RoutePopDisposition.doNotPop, RoutePopDisposition.bubble];

export class Orientation {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'Orientation.' + this.name; }
  static portrait = new Orientation('portrait', 0);
  static landscape = new Orientation('landscape', 1);
}
Orientation.values = [Orientation.portrait, Orientation.landscape];

export class NavigationMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'NavigationMode.' + this.name; }
  static traditional = new NavigationMode('traditional', 0);
  static directional = new NavigationMode('directional', 1);
}
NavigationMode.values = [NavigationMode.traditional, NavigationMode.directional];

export class ScrollPositionAlignmentPolicy {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ScrollPositionAlignmentPolicy.' + this.name; }
  static explicit = new ScrollPositionAlignmentPolicy('explicit', 0);
  static keepVisibleAtEnd = new ScrollPositionAlignmentPolicy('keepVisibleAtEnd', 1);
  static keepVisibleAtStart = new ScrollPositionAlignmentPolicy('keepVisibleAtStart', 2);
}
ScrollPositionAlignmentPolicy.values = [ScrollPositionAlignmentPolicy.explicit, ScrollPositionAlignmentPolicy.keepVisibleAtEnd, ScrollPositionAlignmentPolicy.keepVisibleAtStart];

export class DiagonalDragBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DiagonalDragBehavior.' + this.name; }
  static none = new DiagonalDragBehavior('none', 0);
  static weightedEvent = new DiagonalDragBehavior('weightedEvent', 1);
  static weightedContinuous = new DiagonalDragBehavior('weightedContinuous', 2);
  static free = new DiagonalDragBehavior('free', 3);
}
DiagonalDragBehavior.values = [DiagonalDragBehavior.none, DiagonalDragBehavior.weightedEvent, DiagonalDragBehavior.weightedContinuous, DiagonalDragBehavior.free];

export class KeyEventResult {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'KeyEventResult.' + this.name; }
  static handled = new KeyEventResult('handled', 0);
  static ignored = new KeyEventResult('ignored', 1);
  static skipRemainingHandlers = new KeyEventResult('skipRemainingHandlers', 2);
}
KeyEventResult.values = [KeyEventResult.handled, KeyEventResult.ignored, KeyEventResult.skipRemainingHandlers];

export class UnfocusDisposition {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'UnfocusDisposition.' + this.name; }
  static scope = new UnfocusDisposition('scope', 0);
  static previouslyFocusedChild = new UnfocusDisposition('previouslyFocusedChild', 1);
}
UnfocusDisposition.values = [UnfocusDisposition.scope, UnfocusDisposition.previouslyFocusedChild];

export class FocusHighlightMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'FocusHighlightMode.' + this.name; }
  static touch = new FocusHighlightMode('touch', 0);
  static traditional = new FocusHighlightMode('traditional', 1);
}
FocusHighlightMode.values = [FocusHighlightMode.touch, FocusHighlightMode.traditional];

export class FocusHighlightStrategy {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'FocusHighlightStrategy.' + this.name; }
  static automatic = new FocusHighlightStrategy('automatic', 0);
  static alwaysTouch = new FocusHighlightStrategy('alwaysTouch', 1);
  static alwaysTraditional = new FocusHighlightStrategy('alwaysTraditional', 2);
}
FocusHighlightStrategy.values = [FocusHighlightStrategy.automatic, FocusHighlightStrategy.alwaysTouch, FocusHighlightStrategy.alwaysTraditional];

export class TraversalDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TraversalDirection.' + this.name; }
  static up = new TraversalDirection('up', 0);
  static right = new TraversalDirection('right', 1);
  static down = new TraversalDirection('down', 2);
  static left = new TraversalDirection('left', 3);
}
TraversalDirection.values = [TraversalDirection.up, TraversalDirection.right, TraversalDirection.down, TraversalDirection.left];

export class TraversalEdgeBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TraversalEdgeBehavior.' + this.name; }
  static closedLoop = new TraversalEdgeBehavior('closedLoop', 0);
  static leaveFlutterView = new TraversalEdgeBehavior('leaveFlutterView', 1);
  static parentScope = new TraversalEdgeBehavior('parentScope', 2);
  static stop = new TraversalEdgeBehavior('stop', 3);
}
TraversalEdgeBehavior.values = [TraversalEdgeBehavior.closedLoop, TraversalEdgeBehavior.leaveFlutterView, TraversalEdgeBehavior.parentScope, TraversalEdgeBehavior.stop];

export class SnapshotMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SnapshotMode.' + this.name; }
  static permissive = new SnapshotMode('permissive', 0);
  static normal = new SnapshotMode('normal', 1);
  static forced = new SnapshotMode('forced', 2);
}
SnapshotMode.values = [SnapshotMode.permissive, SnapshotMode.normal, SnapshotMode.forced];

export class TooltipTriggerMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TooltipTriggerMode.' + this.name; }
  static manual = new TooltipTriggerMode('manual', 0);
  static longPress = new TooltipTriggerMode('longPress', 1);
  static tap = new TooltipTriggerMode('tap', 2);
}
TooltipTriggerMode.values = [TooltipTriggerMode.manual, TooltipTriggerMode.longPress, TooltipTriggerMode.tap];

export class BannerLocation {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'BannerLocation.' + this.name; }
  static topStart = new BannerLocation('topStart', 0);
  static topEnd = new BannerLocation('topEnd', 1);
  static bottomStart = new BannerLocation('bottomStart', 2);
  static bottomEnd = new BannerLocation('bottomEnd', 3);
}
BannerLocation.values = [BannerLocation.topStart, BannerLocation.topEnd, BannerLocation.bottomStart, BannerLocation.bottomEnd];

export class FloatingHeaderSnapMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'FloatingHeaderSnapMode.' + this.name; }
  static overlay = new FloatingHeaderSnapMode('overlay', 0);
  static scroll = new FloatingHeaderSnapMode('scroll', 1);
}
FloatingHeaderSnapMode.values = [FloatingHeaderSnapMode.overlay, FloatingHeaderSnapMode.scroll];

export class LockState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'LockState.' + this.name; }
  static ignored = new LockState('ignored', 0);
  static locked = new LockState('locked', 1);
  static unlocked = new LockState('unlocked', 2);
}
LockState.values = [LockState.ignored, LockState.locked, LockState.unlocked];

export class HeroFlightDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'HeroFlightDirection.' + this.name; }
  static push = new HeroFlightDirection('push', 0);
  static pop = new HeroFlightDirection('pop', 1);
}
HeroFlightDirection.values = [HeroFlightDirection.push, HeroFlightDirection.pop];

export class StandardComponentType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'StandardComponentType.' + this.name; }
  static backButton = new StandardComponentType('backButton', 0);
  static closeButton = new StandardComponentType('closeButton', 1);
  static moreButton = new StandardComponentType('moreButton', 2);
  static drawerButton = new StandardComponentType('drawerButton', 3);
}
StandardComponentType.values = [StandardComponentType.backButton, StandardComponentType.closeButton, StandardComponentType.moreButton, StandardComponentType.drawerButton];

export class InspectorButtonVariant {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'InspectorButtonVariant.' + this.name; }
  static filled = new InspectorButtonVariant('filled', 0);
  static toggle = new InspectorButtonVariant('toggle', 1);
  static iconOnly = new InspectorButtonVariant('iconOnly', 2);
}
InspectorButtonVariant.values = [InspectorButtonVariant.filled, InspectorButtonVariant.toggle, InspectorButtonVariant.iconOnly];

export class AndroidOverscrollIndicator {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'AndroidOverscrollIndicator.' + this.name; }
  static stretch = new AndroidOverscrollIndicator('stretch', 0);
  static glow = new AndroidOverscrollIndicator('glow', 1);
}
AndroidOverscrollIndicator.values = [AndroidOverscrollIndicator.stretch, AndroidOverscrollIndicator.glow];

export class ClipboardStatus {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ClipboardStatus.' + this.name; }
  static pasteable = new ClipboardStatus('pasteable', 0);
  static unknown = new ClipboardStatus('unknown', 1);
  static notPasteable = new ClipboardStatus('notPasteable', 2);
}
ClipboardStatus.values = [ClipboardStatus.pasteable, ClipboardStatus.unknown, ClipboardStatus.notPasteable];

export class LiveTextInputStatus {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'LiveTextInputStatus.' + this.name; }
  static enabled = new LiveTextInputStatus('enabled', 0);
  static unknown = new LiveTextInputStatus('unknown', 1);
  static disabled = new LiveTextInputStatus('disabled', 2);
}
LiveTextInputStatus.values = [LiveTextInputStatus.enabled, LiveTextInputStatus.unknown, LiveTextInputStatus.disabled];

export class ScrollDecelerationRate {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ScrollDecelerationRate.' + this.name; }
  static normal = new ScrollDecelerationRate('normal', 0);
  static fast = new ScrollDecelerationRate('fast', 1);
}
ScrollDecelerationRate.values = [ScrollDecelerationRate.normal, ScrollDecelerationRate.fast];

export class OverflowBarAlignment {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'OverflowBarAlignment.' + this.name; }
  static start = new OverflowBarAlignment('start', 0);
  static end = new OverflowBarAlignment('end', 1);
  static center = new OverflowBarAlignment('center', 2);
}
OverflowBarAlignment.values = [OverflowBarAlignment.start, OverflowBarAlignment.end, OverflowBarAlignment.center];

export class PanAxis {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PanAxis.' + this.name; }
  static horizontal = new PanAxis('horizontal', 0);
  static vertical = new PanAxis('vertical', 1);
  static aligned = new PanAxis('aligned', 2);
  static free = new PanAxis('free', 3);
}
PanAxis.values = [PanAxis.horizontal, PanAxis.vertical, PanAxis.aligned, PanAxis.free];

export class AutofillContextAction {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'AutofillContextAction.' + this.name; }
  static commit = new AutofillContextAction('commit', 0);
  static cancel = new AutofillContextAction('cancel', 1);
}
AutofillContextAction.values = [AutofillContextAction.commit, AutofillContextAction.cancel];

export class ChangeReportingBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ChangeReportingBehavior.' + this.name; }
  static onScrollEnd = new ChangeReportingBehavior('onScrollEnd', 0);
  static onScrollUpdate = new ChangeReportingBehavior('onScrollUpdate', 1);
}
ChangeReportingBehavior.values = [ChangeReportingBehavior.onScrollEnd, ChangeReportingBehavior.onScrollUpdate];

export class PlatformProvidedMenuItemType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PlatformProvidedMenuItemType.' + this.name; }
  static about = new PlatformProvidedMenuItemType('about', 0);
  static quit = new PlatformProvidedMenuItemType('quit', 1);
  static servicesSubmenu = new PlatformProvidedMenuItemType('servicesSubmenu', 2);
  static hide = new PlatformProvidedMenuItemType('hide', 3);
  static hideOtherApplications = new PlatformProvidedMenuItemType('hideOtherApplications', 4);
  static showAllApplications = new PlatformProvidedMenuItemType('showAllApplications', 5);
  static startSpeaking = new PlatformProvidedMenuItemType('startSpeaking', 6);
  static stopSpeaking = new PlatformProvidedMenuItemType('stopSpeaking', 7);
  static toggleFullScreen = new PlatformProvidedMenuItemType('toggleFullScreen', 8);
  static minimizeWindow = new PlatformProvidedMenuItemType('minimizeWindow', 9);
  static zoomWindow = new PlatformProvidedMenuItemType('zoomWindow', 10);
  static arrangeWindowsInFront = new PlatformProvidedMenuItemType('arrangeWindowsInFront', 11);
}
PlatformProvidedMenuItemType.values = [PlatformProvidedMenuItemType.about, PlatformProvidedMenuItemType.quit, PlatformProvidedMenuItemType.servicesSubmenu, PlatformProvidedMenuItemType.hide, PlatformProvidedMenuItemType.hideOtherApplications, PlatformProvidedMenuItemType.showAllApplications, PlatformProvidedMenuItemType.startSpeaking, PlatformProvidedMenuItemType.stopSpeaking, PlatformProvidedMenuItemType.toggleFullScreen, PlatformProvidedMenuItemType.minimizeWindow, PlatformProvidedMenuItemType.zoomWindow, PlatformProvidedMenuItemType.arrangeWindowsInFront];

export class DismissDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DismissDirection.' + this.name; }
  static vertical = new DismissDirection('vertical', 0);
  static horizontal = new DismissDirection('horizontal', 1);
  static endToStart = new DismissDirection('endToStart', 2);
  static startToEnd = new DismissDirection('startToEnd', 3);
  static up = new DismissDirection('up', 4);
  static down = new DismissDirection('down', 5);
  static none = new DismissDirection('none', 6);
}
DismissDirection.values = [DismissDirection.vertical, DismissDirection.horizontal, DismissDirection.endToStart, DismissDirection.startToEnd, DismissDirection.up, DismissDirection.down, DismissDirection.none];

export class ScrollbarOrientation {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ScrollbarOrientation.' + this.name; }
  static left = new ScrollbarOrientation('left', 0);
  static right = new ScrollbarOrientation('right', 1);
  static top = new ScrollbarOrientation('top', 2);
  static bottom = new ScrollbarOrientation('bottom', 3);
}
ScrollbarOrientation.values = [ScrollbarOrientation.left, ScrollbarOrientation.right, ScrollbarOrientation.top, ScrollbarOrientation.bottom];

export class RepeatMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'RepeatMode.' + this.name; }
  static restart = new RepeatMode('restart', 0);
  static reverse = new RepeatMode('reverse', 1);
}
RepeatMode.values = [RepeatMode.restart, RepeatMode.reverse];

export class OptionsViewOpenDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'OptionsViewOpenDirection.' + this.name; }
  static up = new OptionsViewOpenDirection('up', 0);
  static down = new OptionsViewOpenDirection('down', 1);
  static mostSpace = new OptionsViewOpenDirection('mostSpace', 2);
}
OptionsViewOpenDirection.values = [OptionsViewOpenDirection.up, OptionsViewOpenDirection.down, OptionsViewOpenDirection.mostSpace];

export class OverlayChildLocation {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'OverlayChildLocation.' + this.name; }
  static nearestOverlay = new OverlayChildLocation('nearestOverlay', 0);
  static rootOverlay = new OverlayChildLocation('rootOverlay', 1);
}
OverlayChildLocation.values = [OverlayChildLocation.nearestOverlay, OverlayChildLocation.rootOverlay];

export class WidgetsServiceExtensions {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'WidgetsServiceExtensions.' + this.name; }
  static debugDumpApp = new WidgetsServiceExtensions('debugDumpApp', 0);
  static debugDumpFocusTree = new WidgetsServiceExtensions('debugDumpFocusTree', 1);
  static showPerformanceOverlay = new WidgetsServiceExtensions('showPerformanceOverlay', 2);
  static didSendFirstFrameEvent = new WidgetsServiceExtensions('didSendFirstFrameEvent', 3);
  static didSendFirstFrameRasterizedEvent = new WidgetsServiceExtensions('didSendFirstFrameRasterizedEvent', 4);
  static fastReassemble = new WidgetsServiceExtensions('fastReassemble', 5);
  static profileWidgetBuilds = new WidgetsServiceExtensions('profileWidgetBuilds', 6);
  static profileUserWidgetBuilds = new WidgetsServiceExtensions('profileUserWidgetBuilds', 7);
  static debugAllowBanner = new WidgetsServiceExtensions('debugAllowBanner', 8);
}
WidgetsServiceExtensions.values = [WidgetsServiceExtensions.debugDumpApp, WidgetsServiceExtensions.debugDumpFocusTree, WidgetsServiceExtensions.showPerformanceOverlay, WidgetsServiceExtensions.didSendFirstFrameEvent, WidgetsServiceExtensions.didSendFirstFrameRasterizedEvent, WidgetsServiceExtensions.fastReassemble, WidgetsServiceExtensions.profileWidgetBuilds, WidgetsServiceExtensions.profileUserWidgetBuilds, WidgetsServiceExtensions.debugAllowBanner];

export class WidgetInspectorServiceExtensions {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'WidgetInspectorServiceExtensions.' + this.name; }
  static structuredErrors = new WidgetInspectorServiceExtensions('structuredErrors', 0);
  static show = new WidgetInspectorServiceExtensions('show', 1);
  static trackRebuildDirtyWidgets = new WidgetInspectorServiceExtensions('trackRebuildDirtyWidgets', 2);
  static widgetLocationIdMap = new WidgetInspectorServiceExtensions('widgetLocationIdMap', 3);
  static trackRepaintWidgets = new WidgetInspectorServiceExtensions('trackRepaintWidgets', 4);
  static disposeAllGroups = new WidgetInspectorServiceExtensions('disposeAllGroups', 5);
  static disposeGroup = new WidgetInspectorServiceExtensions('disposeGroup', 6);
  static isWidgetTreeReady = new WidgetInspectorServiceExtensions('isWidgetTreeReady', 7);
  static disposeId = new WidgetInspectorServiceExtensions('disposeId', 8);
  static setPubRootDirectories = new WidgetInspectorServiceExtensions('setPubRootDirectories', 9);
  static addPubRootDirectories = new WidgetInspectorServiceExtensions('addPubRootDirectories', 10);
  static removePubRootDirectories = new WidgetInspectorServiceExtensions('removePubRootDirectories', 11);
  static getPubRootDirectories = new WidgetInspectorServiceExtensions('getPubRootDirectories', 12);
  static setSelectionById = new WidgetInspectorServiceExtensions('setSelectionById', 13);
  static getParentChain = new WidgetInspectorServiceExtensions('getParentChain', 14);
  static getProperties = new WidgetInspectorServiceExtensions('getProperties', 15);
  static getChildren = new WidgetInspectorServiceExtensions('getChildren', 16);
  static getChildrenSummaryTree = new WidgetInspectorServiceExtensions('getChildrenSummaryTree', 17);
  static getChildrenDetailsSubtree = new WidgetInspectorServiceExtensions('getChildrenDetailsSubtree', 18);
  static getRootWidget = new WidgetInspectorServiceExtensions('getRootWidget', 19);
  static getRootWidgetTree = new WidgetInspectorServiceExtensions('getRootWidgetTree', 20);
  static getRootWidgetSummaryTree = new WidgetInspectorServiceExtensions('getRootWidgetSummaryTree', 21);
  static getRootWidgetSummaryTreeWithPreviews = new WidgetInspectorServiceExtensions('getRootWidgetSummaryTreeWithPreviews', 22);
  static getDetailsSubtree = new WidgetInspectorServiceExtensions('getDetailsSubtree', 23);
  static getSelectedWidget = new WidgetInspectorServiceExtensions('getSelectedWidget', 24);
  static getSelectedSummaryWidget = new WidgetInspectorServiceExtensions('getSelectedSummaryWidget', 25);
  static isWidgetCreationTracked = new WidgetInspectorServiceExtensions('isWidgetCreationTracked', 26);
  static screenshot = new WidgetInspectorServiceExtensions('screenshot', 27);
  static getLayoutExplorerNode = new WidgetInspectorServiceExtensions('getLayoutExplorerNode', 28);
  static setFlexFit = new WidgetInspectorServiceExtensions('setFlexFit', 29);
  static setFlexFactor = new WidgetInspectorServiceExtensions('setFlexFactor', 30);
  static setFlexProperties = new WidgetInspectorServiceExtensions('setFlexProperties', 31);
}
WidgetInspectorServiceExtensions.values = [WidgetInspectorServiceExtensions.structuredErrors, WidgetInspectorServiceExtensions.show, WidgetInspectorServiceExtensions.trackRebuildDirtyWidgets, WidgetInspectorServiceExtensions.widgetLocationIdMap, WidgetInspectorServiceExtensions.trackRepaintWidgets, WidgetInspectorServiceExtensions.disposeAllGroups, WidgetInspectorServiceExtensions.disposeGroup, WidgetInspectorServiceExtensions.isWidgetTreeReady, WidgetInspectorServiceExtensions.disposeId, WidgetInspectorServiceExtensions.setPubRootDirectories, WidgetInspectorServiceExtensions.addPubRootDirectories, WidgetInspectorServiceExtensions.removePubRootDirectories, WidgetInspectorServiceExtensions.getPubRootDirectories, WidgetInspectorServiceExtensions.setSelectionById, WidgetInspectorServiceExtensions.getParentChain, WidgetInspectorServiceExtensions.getProperties, WidgetInspectorServiceExtensions.getChildren, WidgetInspectorServiceExtensions.getChildrenSummaryTree, WidgetInspectorServiceExtensions.getChildrenDetailsSubtree, WidgetInspectorServiceExtensions.getRootWidget, WidgetInspectorServiceExtensions.getRootWidgetTree, WidgetInspectorServiceExtensions.getRootWidgetSummaryTree, WidgetInspectorServiceExtensions.getRootWidgetSummaryTreeWithPreviews, WidgetInspectorServiceExtensions.getDetailsSubtree, WidgetInspectorServiceExtensions.getSelectedWidget, WidgetInspectorServiceExtensions.getSelectedSummaryWidget, WidgetInspectorServiceExtensions.isWidgetCreationTracked, WidgetInspectorServiceExtensions.screenshot, WidgetInspectorServiceExtensions.getLayoutExplorerNode, WidgetInspectorServiceExtensions.setFlexFit, WidgetInspectorServiceExtensions.setFlexFactor, WidgetInspectorServiceExtensions.setFlexProperties];

export class ScrollViewKeyboardDismissBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ScrollViewKeyboardDismissBehavior.' + this.name; }
  static manual = new ScrollViewKeyboardDismissBehavior('manual', 0);
  static onDrag = new ScrollViewKeyboardDismissBehavior('onDrag', 1);
}
ScrollViewKeyboardDismissBehavior.values = [ScrollViewKeyboardDismissBehavior.manual, ScrollViewKeyboardDismissBehavior.onDrag];

export class SelectableRegionSelectionStatus {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SelectableRegionSelectionStatus.' + this.name; }
  static changing = new SelectableRegionSelectionStatus('changing', 0);
  static finalized = new SelectableRegionSelectionStatus('finalized', 1);
}
SelectableRegionSelectionStatus.values = [SelectableRegionSelectionStatus.changing, SelectableRegionSelectionStatus.finalized];

export class WindowPositionerAnchor {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'WindowPositionerAnchor.' + this.name; }
  static center = new WindowPositionerAnchor('center', 0);
  static top = new WindowPositionerAnchor('top', 1);
  static bottom = new WindowPositionerAnchor('bottom', 2);
  static left = new WindowPositionerAnchor('left', 3);
  static right = new WindowPositionerAnchor('right', 4);
  static topLeft = new WindowPositionerAnchor('topLeft', 5);
  static bottomLeft = new WindowPositionerAnchor('bottomLeft', 6);
  static topRight = new WindowPositionerAnchor('topRight', 7);
  static bottomRight = new WindowPositionerAnchor('bottomRight', 8);
}
WindowPositionerAnchor.values = [WindowPositionerAnchor.center, WindowPositionerAnchor.top, WindowPositionerAnchor.bottom, WindowPositionerAnchor.left, WindowPositionerAnchor.right, WindowPositionerAnchor.topLeft, WindowPositionerAnchor.bottomLeft, WindowPositionerAnchor.topRight, WindowPositionerAnchor.bottomRight];

export class Brightness {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'Brightness.' + this.name; }
  static dark = new Brightness('dark', 0);
  static light = new Brightness('light', 1);
}
Brightness.values = [Brightness.dark, Brightness.light];

export class FontStyle {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'FontStyle.' + this.name; }
  static normal = new FontStyle('normal', 0);
  static italic = new FontStyle('italic', 1);
}
FontStyle.values = [FontStyle.normal, FontStyle.italic];

export class TextAlign {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextAlign.' + this.name; }
  static left = new TextAlign('left', 0);
  static right = new TextAlign('right', 1);
  static center = new TextAlign('center', 2);
  static justify = new TextAlign('justify', 3);
  static start = new TextAlign('start', 4);
  static end = new TextAlign('end', 5);
}
TextAlign.values = [TextAlign.left, TextAlign.right, TextAlign.center, TextAlign.justify, TextAlign.start, TextAlign.end];

export class TextBaseline {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextBaseline.' + this.name; }
  static alphabetic = new TextBaseline('alphabetic', 0);
  static ideographic = new TextBaseline('ideographic', 1);
}
TextBaseline.values = [TextBaseline.alphabetic, TextBaseline.ideographic];

export class TextDecorationStyle {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextDecorationStyle.' + this.name; }
  static solid = new TextDecorationStyle('solid', 0);
  static double = new TextDecorationStyle('double', 1);
  static dotted = new TextDecorationStyle('dotted', 2);
  static dashed = new TextDecorationStyle('dashed', 3);
  static wavy = new TextDecorationStyle('wavy', 4);
}
TextDecorationStyle.values = [TextDecorationStyle.solid, TextDecorationStyle.double, TextDecorationStyle.dotted, TextDecorationStyle.dashed, TextDecorationStyle.wavy];

export class TextLeadingDistribution {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextLeadingDistribution.' + this.name; }
  static proportional = new TextLeadingDistribution('proportional', 0);
  static even = new TextLeadingDistribution('even', 1);
}
TextLeadingDistribution.values = [TextLeadingDistribution.proportional, TextLeadingDistribution.even];

export class TextDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextDirection.' + this.name; }
  static rtl = new TextDirection('rtl', 0);
  static ltr = new TextDirection('ltr', 1);
}
TextDirection.values = [TextDirection.rtl, TextDirection.ltr];

export class TextAffinity {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TextAffinity.' + this.name; }
  static upstream = new TextAffinity('upstream', 0);
  static downstream = new TextAffinity('downstream', 1);
}
TextAffinity.values = [TextAffinity.upstream, TextAffinity.downstream];

export class BoxHeightStyle {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'BoxHeightStyle.' + this.name; }
  static tight = new BoxHeightStyle('tight', 0);
  static max = new BoxHeightStyle('max', 1);
  static includeLineSpacingMiddle = new BoxHeightStyle('includeLineSpacingMiddle', 2);
  static includeLineSpacingTop = new BoxHeightStyle('includeLineSpacingTop', 3);
  static includeLineSpacingBottom = new BoxHeightStyle('includeLineSpacingBottom', 4);
  static strut = new BoxHeightStyle('strut', 5);
}
BoxHeightStyle.values = [BoxHeightStyle.tight, BoxHeightStyle.max, BoxHeightStyle.includeLineSpacingMiddle, BoxHeightStyle.includeLineSpacingTop, BoxHeightStyle.includeLineSpacingBottom, BoxHeightStyle.strut];

export class BoxWidthStyle {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'BoxWidthStyle.' + this.name; }
  static tight = new BoxWidthStyle('tight', 0);
  static max = new BoxWidthStyle('max', 1);
}
BoxWidthStyle.values = [BoxWidthStyle.tight, BoxWidthStyle.max];

export class PlaceholderAlignment {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PlaceholderAlignment.' + this.name; }
  static baseline = new PlaceholderAlignment('baseline', 0);
  static aboveBaseline = new PlaceholderAlignment('aboveBaseline', 1);
  static belowBaseline = new PlaceholderAlignment('belowBaseline', 2);
  static top = new PlaceholderAlignment('top', 3);
  static bottom = new PlaceholderAlignment('bottom', 4);
  static middle = new PlaceholderAlignment('middle', 5);
}
PlaceholderAlignment.values = [PlaceholderAlignment.baseline, PlaceholderAlignment.aboveBaseline, PlaceholderAlignment.belowBaseline, PlaceholderAlignment.top, PlaceholderAlignment.bottom, PlaceholderAlignment.middle];

export class PointerChange {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PointerChange.' + this.name; }
  static cancel = new PointerChange('cancel', 0);
  static add = new PointerChange('add', 1);
  static remove = new PointerChange('remove', 2);
  static hover = new PointerChange('hover', 3);
  static down = new PointerChange('down', 4);
  static move = new PointerChange('move', 5);
  static up = new PointerChange('up', 6);
  static panZoomStart = new PointerChange('panZoomStart', 7);
  static panZoomUpdate = new PointerChange('panZoomUpdate', 8);
  static panZoomEnd = new PointerChange('panZoomEnd', 9);
}
PointerChange.values = [PointerChange.cancel, PointerChange.add, PointerChange.remove, PointerChange.hover, PointerChange.down, PointerChange.move, PointerChange.up, PointerChange.panZoomStart, PointerChange.panZoomUpdate, PointerChange.panZoomEnd];

export class PointerDeviceKind {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PointerDeviceKind.' + this.name; }
  static touch = new PointerDeviceKind('touch', 0);
  static mouse = new PointerDeviceKind('mouse', 1);
  static stylus = new PointerDeviceKind('stylus', 2);
  static invertedStylus = new PointerDeviceKind('invertedStylus', 3);
  static trackpad = new PointerDeviceKind('trackpad', 4);
  static unknown = new PointerDeviceKind('unknown', 5);
}
PointerDeviceKind.values = [PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.stylus, PointerDeviceKind.invertedStylus, PointerDeviceKind.trackpad, PointerDeviceKind.unknown];

export class PointerSignalKind {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PointerSignalKind.' + this.name; }
  static none = new PointerSignalKind('none', 0);
  static scroll = new PointerSignalKind('scroll', 1);
  static scrollInertiaCancel = new PointerSignalKind('scrollInertiaCancel', 2);
  static scale = new PointerSignalKind('scale', 3);
  static unknown = new PointerSignalKind('unknown', 4);
}
PointerSignalKind.values = [PointerSignalKind.none, PointerSignalKind.scroll, PointerSignalKind.scrollInertiaCancel, PointerSignalKind.scale, PointerSignalKind.unknown];

export class BlendMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'BlendMode.' + this.name; }
  static clear = new BlendMode('clear', 0);
  static src = new BlendMode('src', 1);
  static dst = new BlendMode('dst', 2);
  static srcOver = new BlendMode('srcOver', 3);
  static dstOver = new BlendMode('dstOver', 4);
  static srcIn = new BlendMode('srcIn', 5);
  static dstIn = new BlendMode('dstIn', 6);
  static srcOut = new BlendMode('srcOut', 7);
  static dstOut = new BlendMode('dstOut', 8);
  static srcATop = new BlendMode('srcATop', 9);
  static dstATop = new BlendMode('dstATop', 10);
  static xor = new BlendMode('xor', 11);
  static plus = new BlendMode('plus', 12);
  static modulate = new BlendMode('modulate', 13);
  static screen = new BlendMode('screen', 14);
  static overlay = new BlendMode('overlay', 15);
  static darken = new BlendMode('darken', 16);
  static lighten = new BlendMode('lighten', 17);
  static colorDodge = new BlendMode('colorDodge', 18);
  static colorBurn = new BlendMode('colorBurn', 19);
  static hardLight = new BlendMode('hardLight', 20);
  static softLight = new BlendMode('softLight', 21);
  static difference = new BlendMode('difference', 22);
  static exclusion = new BlendMode('exclusion', 23);
  static multiply = new BlendMode('multiply', 24);
  static hue = new BlendMode('hue', 25);
  static saturation = new BlendMode('saturation', 26);
  static color = new BlendMode('color', 27);
  static luminosity = new BlendMode('luminosity', 28);
}
BlendMode.values = [BlendMode.clear, BlendMode.src, BlendMode.dst, BlendMode.srcOver, BlendMode.dstOver, BlendMode.srcIn, BlendMode.dstIn, BlendMode.srcOut, BlendMode.dstOut, BlendMode.srcATop, BlendMode.dstATop, BlendMode.xor, BlendMode.plus, BlendMode.modulate, BlendMode.screen, BlendMode.overlay, BlendMode.darken, BlendMode.lighten, BlendMode.colorDodge, BlendMode.colorBurn, BlendMode.hardLight, BlendMode.softLight, BlendMode.difference, BlendMode.exclusion, BlendMode.multiply, BlendMode.hue, BlendMode.saturation, BlendMode.color, BlendMode.luminosity];

export class FilterQuality {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'FilterQuality.' + this.name; }
  static none = new FilterQuality('none', 0);
  static low = new FilterQuality('low', 1);
  static medium = new FilterQuality('medium', 2);
  static high = new FilterQuality('high', 3);
}
FilterQuality.values = [FilterQuality.none, FilterQuality.low, FilterQuality.medium, FilterQuality.high];

export class StrokeCap {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'StrokeCap.' + this.name; }
  static butt = new StrokeCap('butt', 0);
  static round = new StrokeCap('round', 1);
  static square = new StrokeCap('square', 2);
}
StrokeCap.values = [StrokeCap.butt, StrokeCap.round, StrokeCap.square];

export class StrokeJoin {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'StrokeJoin.' + this.name; }
  static miter = new StrokeJoin('miter', 0);
  static round = new StrokeJoin('round', 1);
  static bevel = new StrokeJoin('bevel', 2);
}
StrokeJoin.values = [StrokeJoin.miter, StrokeJoin.round, StrokeJoin.bevel];

export class PaintingStyle {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PaintingStyle.' + this.name; }
  static fill = new PaintingStyle('fill', 0);
  static stroke = new PaintingStyle('stroke', 1);
}
PaintingStyle.values = [PaintingStyle.fill, PaintingStyle.stroke];

export class Clip {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'Clip.' + this.name; }
  static none = new Clip('none', 0);
  static hardEdge = new Clip('hardEdge', 1);
  static antiAlias = new Clip('antiAlias', 2);
  static antiAliasWithSaveLayer = new Clip('antiAliasWithSaveLayer', 3);
}
Clip.values = [Clip.none, Clip.hardEdge, Clip.antiAlias, Clip.antiAliasWithSaveLayer];

export class ColorSpace {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ColorSpace.' + this.name; }
  static sRGB = new ColorSpace('sRGB', 0);
  static extendedSRGB = new ColorSpace('extendedSRGB', 1);
  static displayP3 = new ColorSpace('displayP3', 2);
}
ColorSpace.values = [ColorSpace.sRGB, ColorSpace.extendedSRGB, ColorSpace.displayP3];

export class ImageByteFormat {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ImageByteFormat.' + this.name; }
  static rawRgba = new ImageByteFormat('rawRgba', 0);
  static rawStraightRgba = new ImageByteFormat('rawStraightRgba', 1);
  static rawUnmodified = new ImageByteFormat('rawUnmodified', 2);
  static rawExtendedRgba128 = new ImageByteFormat('rawExtendedRgba128', 3);
  static png = new ImageByteFormat('png', 4);
}
ImageByteFormat.values = [ImageByteFormat.rawRgba, ImageByteFormat.rawStraightRgba, ImageByteFormat.rawUnmodified, ImageByteFormat.rawExtendedRgba128, ImageByteFormat.png];

export class PixelFormat {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PixelFormat.' + this.name; }
  static rgba8888 = new PixelFormat('rgba8888', 0);
  static bgra8888 = new PixelFormat('bgra8888', 1);
  static rgbaFloat32 = new PixelFormat('rgbaFloat32', 2);
  static rFloat32 = new PixelFormat('rFloat32', 3);
}
PixelFormat.values = [PixelFormat.rgba8888, PixelFormat.bgra8888, PixelFormat.rgbaFloat32, PixelFormat.rFloat32];

export class TargetPixelFormat {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TargetPixelFormat.' + this.name; }
  static dontCare = new TargetPixelFormat('dontCare', 0);
  static rgbaFloat32 = new TargetPixelFormat('rgbaFloat32', 1);
  static rFloat32 = new TargetPixelFormat('rFloat32', 2);
}
TargetPixelFormat.values = [TargetPixelFormat.dontCare, TargetPixelFormat.rgbaFloat32, TargetPixelFormat.rFloat32];

export class PathFillType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PathFillType.' + this.name; }
  static nonZero = new PathFillType('nonZero', 0);
  static evenOdd = new PathFillType('evenOdd', 1);
}
PathFillType.values = [PathFillType.nonZero, PathFillType.evenOdd];

export class PathOperation {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PathOperation.' + this.name; }
  static difference = new PathOperation('difference', 0);
  static intersect = new PathOperation('intersect', 1);
  static union = new PathOperation('union', 2);
  static xor = new PathOperation('xor', 3);
  static reverseDifference = new PathOperation('reverseDifference', 4);
}
PathOperation.values = [PathOperation.difference, PathOperation.intersect, PathOperation.union, PathOperation.xor, PathOperation.reverseDifference];

export class BlurStyle {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'BlurStyle.' + this.name; }
  static normal = new BlurStyle('normal', 0);
  static solid = new BlurStyle('solid', 1);
  static outer = new BlurStyle('outer', 2);
  static inner = new BlurStyle('inner', 3);
}
BlurStyle.values = [BlurStyle.normal, BlurStyle.solid, BlurStyle.outer, BlurStyle.inner];

export class TileMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TileMode.' + this.name; }
  static clamp = new TileMode('clamp', 0);
  static repeated = new TileMode('repeated', 1);
  static mirror = new TileMode('mirror', 2);
  static decal = new TileMode('decal', 3);
}
TileMode.values = [TileMode.clamp, TileMode.repeated, TileMode.mirror, TileMode.decal];

export class VertexMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'VertexMode.' + this.name; }
  static triangles = new VertexMode('triangles', 0);
  static triangleStrip = new VertexMode('triangleStrip', 1);
  static triangleFan = new VertexMode('triangleFan', 2);
}
VertexMode.values = [VertexMode.triangles, VertexMode.triangleStrip, VertexMode.triangleFan];

export class PointMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'PointMode.' + this.name; }
  static points = new PointMode('points', 0);
  static lines = new PointMode('lines', 1);
  static polygon = new PointMode('polygon', 2);
}
PointMode.values = [PointMode.points, PointMode.lines, PointMode.polygon];

export class ClipOp {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ClipOp.' + this.name; }
  static difference = new ClipOp('difference', 0);
  static intersect = new ClipOp('intersect', 1);
}
ClipOp.values = [ClipOp.difference, ClipOp.intersect];

export class SemanticsRole {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SemanticsRole.' + this.name; }
  static none = new SemanticsRole('none', 0);
  static tab = new SemanticsRole('tab', 1);
  static tabBar = new SemanticsRole('tabBar', 2);
  static tabPanel = new SemanticsRole('tabPanel', 3);
  static dialog = new SemanticsRole('dialog', 4);
  static alertDialog = new SemanticsRole('alertDialog', 5);
  static table = new SemanticsRole('table', 6);
  static cell = new SemanticsRole('cell', 7);
  static row = new SemanticsRole('row', 8);
  static columnHeader = new SemanticsRole('columnHeader', 9);
  static dragHandle = new SemanticsRole('dragHandle', 10);
  static spinButton = new SemanticsRole('spinButton', 11);
  static comboBox = new SemanticsRole('comboBox', 12);
  static menuBar = new SemanticsRole('menuBar', 13);
  static menu = new SemanticsRole('menu', 14);
  static menuItem = new SemanticsRole('menuItem', 15);
  static menuItemCheckbox = new SemanticsRole('menuItemCheckbox', 16);
  static menuItemRadio = new SemanticsRole('menuItemRadio', 17);
  static list = new SemanticsRole('list', 18);
  static listItem = new SemanticsRole('listItem', 19);
  static form = new SemanticsRole('form', 20);
  static tooltip = new SemanticsRole('tooltip', 21);
  static loadingSpinner = new SemanticsRole('loadingSpinner', 22);
  static progressBar = new SemanticsRole('progressBar', 23);
  static hotKey = new SemanticsRole('hotKey', 24);
  static radioGroup = new SemanticsRole('radioGroup', 25);
  static status = new SemanticsRole('status', 26);
  static alert = new SemanticsRole('alert', 27);
  static complementary = new SemanticsRole('complementary', 28);
  static contentInfo = new SemanticsRole('contentInfo', 29);
  static main = new SemanticsRole('main', 30);
  static navigation = new SemanticsRole('navigation', 31);
  static region = new SemanticsRole('region', 32);
}
SemanticsRole.values = [SemanticsRole.none, SemanticsRole.tab, SemanticsRole.tabBar, SemanticsRole.tabPanel, SemanticsRole.dialog, SemanticsRole.alertDialog, SemanticsRole.table, SemanticsRole.cell, SemanticsRole.row, SemanticsRole.columnHeader, SemanticsRole.dragHandle, SemanticsRole.spinButton, SemanticsRole.comboBox, SemanticsRole.menuBar, SemanticsRole.menu, SemanticsRole.menuItem, SemanticsRole.menuItemCheckbox, SemanticsRole.menuItemRadio, SemanticsRole.list, SemanticsRole.listItem, SemanticsRole.form, SemanticsRole.tooltip, SemanticsRole.loadingSpinner, SemanticsRole.progressBar, SemanticsRole.hotKey, SemanticsRole.radioGroup, SemanticsRole.status, SemanticsRole.alert, SemanticsRole.complementary, SemanticsRole.contentInfo, SemanticsRole.main, SemanticsRole.navigation, SemanticsRole.region];

export class SemanticsInputType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SemanticsInputType.' + this.name; }
  static none = new SemanticsInputType('none', 0);
  static text = new SemanticsInputType('text', 1);
  static url = new SemanticsInputType('url', 2);
  static phone = new SemanticsInputType('phone', 3);
  static search = new SemanticsInputType('search', 4);
  static email = new SemanticsInputType('email', 5);
}
SemanticsInputType.values = [SemanticsInputType.none, SemanticsInputType.text, SemanticsInputType.url, SemanticsInputType.phone, SemanticsInputType.search, SemanticsInputType.email];

export class SemanticsHitTestBehavior {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SemanticsHitTestBehavior.' + this.name; }
  static defer = new SemanticsHitTestBehavior('defer', 0);
  static opaque = new SemanticsHitTestBehavior('opaque', 1);
  static transparent = new SemanticsHitTestBehavior('transparent', 2);
}
SemanticsHitTestBehavior.values = [SemanticsHitTestBehavior.defer, SemanticsHitTestBehavior.opaque, SemanticsHitTestBehavior.transparent];

export class SemanticsValidationResult {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'SemanticsValidationResult.' + this.name; }
  static none = new SemanticsValidationResult('none', 0);
  static valid = new SemanticsValidationResult('valid', 1);
  static invalid = new SemanticsValidationResult('invalid', 2);
}
SemanticsValidationResult.values = [SemanticsValidationResult.none, SemanticsValidationResult.valid, SemanticsValidationResult.invalid];

export class FramePhase {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'FramePhase.' + this.name; }
  static vsyncStart = new FramePhase('vsyncStart', 0);
  static buildStart = new FramePhase('buildStart', 1);
  static buildFinish = new FramePhase('buildFinish', 2);
  static rasterStart = new FramePhase('rasterStart', 3);
  static rasterFinish = new FramePhase('rasterFinish', 4);
  static rasterFinishWallTime = new FramePhase('rasterFinishWallTime', 5);
}
FramePhase.values = [FramePhase.vsyncStart, FramePhase.buildStart, FramePhase.buildFinish, FramePhase.rasterStart, FramePhase.rasterFinish, FramePhase.rasterFinishWallTime];

export class AppLifecycleState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'AppLifecycleState.' + this.name; }
  static detached = new AppLifecycleState('detached', 0);
  static resumed = new AppLifecycleState('resumed', 1);
  static inactive = new AppLifecycleState('inactive', 2);
  static hidden = new AppLifecycleState('hidden', 3);
  static paused = new AppLifecycleState('paused', 4);
}
AppLifecycleState.values = [AppLifecycleState.detached, AppLifecycleState.resumed, AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused];

export class AppExitResponse {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'AppExitResponse.' + this.name; }
  static exit = new AppExitResponse('exit', 0);
  static cancel = new AppExitResponse('cancel', 1);
}
AppExitResponse.values = [AppExitResponse.exit, AppExitResponse.cancel];

export class AppExitType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'AppExitType.' + this.name; }
  static cancelable = new AppExitType('cancelable', 0);
  static required = new AppExitType('required', 1);
}
AppExitType.values = [AppExitType.cancelable, AppExitType.required];

export class DisplayFeatureType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DisplayFeatureType.' + this.name; }
  static unknown = new DisplayFeatureType('unknown', 0);
  static fold = new DisplayFeatureType('fold', 1);
  static hinge = new DisplayFeatureType('hinge', 2);
  static cutout = new DisplayFeatureType('cutout', 3);
}
DisplayFeatureType.values = [DisplayFeatureType.unknown, DisplayFeatureType.fold, DisplayFeatureType.hinge, DisplayFeatureType.cutout];

export class DisplayFeatureState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DisplayFeatureState.' + this.name; }
  static unknown = new DisplayFeatureState('unknown', 0);
  static postureFlat = new DisplayFeatureState('postureFlat', 1);
  static postureHalfOpened = new DisplayFeatureState('postureHalfOpened', 2);
}
DisplayFeatureState.values = [DisplayFeatureState.unknown, DisplayFeatureState.postureFlat, DisplayFeatureState.postureHalfOpened];

export class DartPerformanceMode {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'DartPerformanceMode.' + this.name; }
  static balanced = new DartPerformanceMode('balanced', 0);
  static latency = new DartPerformanceMode('latency', 1);
  static throughput = new DartPerformanceMode('throughput', 2);
  static memory = new DartPerformanceMode('memory', 3);
}
DartPerformanceMode.values = [DartPerformanceMode.balanced, DartPerformanceMode.latency, DartPerformanceMode.throughput, DartPerformanceMode.memory];

export class ViewFocusState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ViewFocusState.' + this.name; }
  static unfocused = new ViewFocusState('unfocused', 0);
  static focused = new ViewFocusState('focused', 1);
}
ViewFocusState.values = [ViewFocusState.unfocused, ViewFocusState.focused];

export class ViewFocusDirection {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'ViewFocusDirection.' + this.name; }
  static undefined = new ViewFocusDirection('undefined', 0);
  static forward = new ViewFocusDirection('forward', 1);
  static backward = new ViewFocusDirection('backward', 2);
}
ViewFocusDirection.values = [ViewFocusDirection.undefined, ViewFocusDirection.forward, ViewFocusDirection.backward];

export class KeyEventType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'KeyEventType.' + this.name; }
  static down = new KeyEventType('down', 0);
  static up = new KeyEventType('up', 1);
  static repeat = new KeyEventType('repeat', 2);
}
KeyEventType.values = [KeyEventType.down, KeyEventType.up, KeyEventType.repeat];

export class KeyEventDeviceType {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'KeyEventDeviceType.' + this.name; }
  static keyboard = new KeyEventDeviceType('keyboard', 0);
  static directionalPad = new KeyEventDeviceType('directionalPad', 1);
  static gamepad = new KeyEventDeviceType('gamepad', 2);
  static joystick = new KeyEventDeviceType('joystick', 3);
  static hdmi = new KeyEventDeviceType('hdmi', 4);
}
KeyEventDeviceType.values = [KeyEventDeviceType.keyboard, KeyEventDeviceType.directionalPad, KeyEventDeviceType.gamepad, KeyEventDeviceType.joystick, KeyEventDeviceType.hdmi];

export class TimelineRecorder {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TimelineRecorder.' + this.name; }
  static perfetto = new TimelineRecorder('perfetto', 0);
  static chrome = new TimelineRecorder('chrome', 1);
  static systrace = new TimelineRecorder('systrace', 2);
}
TimelineRecorder.values = [TimelineRecorder.perfetto, TimelineRecorder.chrome, TimelineRecorder.systrace];

export class TimelineStream {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'TimelineStream.' + this.name; }
  static api = new TimelineStream('api', 0);
  static compiler = new TimelineStream('compiler', 1);
  static compilerVerbose = new TimelineStream('compilerVerbose', 2);
  static dart = new TimelineStream('dart', 3);
  static debugger = new TimelineStream('debugger', 4);
  static embedder = new TimelineStream('embedder', 5);
  static gc = new TimelineStream('gc', 6);
  static isolate = new TimelineStream('isolate', 7);
  static microtask = new TimelineStream('microtask', 8);
  static vm = new TimelineStream('vm', 9);
}
TimelineStream.values = [TimelineStream.api, TimelineStream.compiler, TimelineStream.compilerVerbose, TimelineStream.dart, TimelineStream.debugger, TimelineStream.embedder, TimelineStream.gc, TimelineStream.isolate, TimelineStream.microtask, TimelineStream.vm];

export class BrowserEngine {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'BrowserEngine.' + this.name; }
  static blink = new BrowserEngine('blink', 0);
  static webkit = new BrowserEngine('webkit', 1);
  static firefox = new BrowserEngine('firefox', 2);
}
BrowserEngine.values = [BrowserEngine.blink, BrowserEngine.webkit, BrowserEngine.firefox];

export class OperatingSystem {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'OperatingSystem.' + this.name; }
  static iOs = new OperatingSystem('iOs', 0);
  static android = new OperatingSystem('android', 1);
  static linux = new OperatingSystem('linux', 2);
  static windows = new OperatingSystem('windows', 3);
  static macOs = new OperatingSystem('macOs', 4);
  static unknown = new OperatingSystem('unknown', 5);
}
OperatingSystem.values = [OperatingSystem.iOs, OperatingSystem.android, OperatingSystem.linux, OperatingSystem.windows, OperatingSystem.macOs, OperatingSystem.unknown];

export class HttpClientResponseCompressionState {
  constructor(name, index) {
    this.name = name;
    this.index = index;
  }
  toJSON() { return this.name; }
  toString() { return 'HttpClientResponseCompressionState.' + this.name; }
  static notCompressed = new HttpClientResponseCompressionState('notCompressed', 0);
  static decompressed = new HttpClientResponseCompressionState('decompressed', 1);
  static compressed = new HttpClientResponseCompressionState('compressed', 2);
}
HttpClientResponseCompressionState.values = [HttpClientResponseCompressionState.notCompressed, HttpClientResponseCompressionState.decompressed, HttpClientResponseCompressionState.compressed];


// ===== IconData / Icons（由 SDK icons.dart 自动生成，勿手改）=====
export class IconData {
  constructor(props) {
    this.codePoint = props.codePoint;
    this.fontFamily = props.fontFamily == null ? null : props.fontFamily;
    this.matchTextDirection = props.matchTextDirection === true;
  }
  toJSON() {
    return { codePoint: this.codePoint, fontFamily: this.fontFamily,
      matchTextDirection: this.matchTextDirection };
  }
}

// 常量表：`name:code[|family][|R]`，逗号分隔（名字不含这三种分隔符）。
const __ICON_SRC = "ten_k:57344,ten_k_sharp:59136,ten_k_rounded:62687,ten_k_outlined:60914,ten_mp:57345,ten_mp_sharp:59137,ten_mp_rounded:62688,ten_mp_outlined:60915,eleven_mp:57346,eleven_mp_sharp:59138,eleven_mp_rounded:62689,eleven_mp_outlined:60916,onetwothree:984245,onetwothree_sharp:984002,onetwothree_rounded:58176,onetwothree_outlined:984496,twelve_mp:57347,twelve_mp_sharp:59139,twelve_mp_rounded:62690,twelve_mp_outlined:60917,thirteen_mp:57348,thirteen_mp_sharp:59140,thirteen_mp_rounded:62691,thirteen_mp_outlined:60918,fourteen_mp:57349,fourteen_mp_sharp:59141,fourteen_mp_rounded:62692,fourteen_mp_outlined:60919,fifteen_mp:57350,fifteen_mp_sharp:59142,fifteen_mp_rounded:62693,fifteen_mp_outlined:60920,sixteen_mp:57351,sixteen_mp_sharp:59143,sixteen_mp_rounded:62694,sixteen_mp_outlined:60921,seventeen_mp:57352,seventeen_mp_sharp:59144,seventeen_mp_rounded:62695,seventeen_mp_outlined:60922,eighteen_up_rating:984964,eighteen_up_rating_sharp:984876,eighteen_up_rating_rounded:985052,eighteen_up_rating_outlined:984788,eighteen_mp:57353,eighteen_mp_sharp:59145,eighteen_mp_rounded:62696,eighteen_mp_outlined:60923,nineteen_mp:57354,nineteen_mp_sharp:59146,nineteen_mp_rounded:62697,nineteen_mp_outlined:60924,one_k:57355,one_k_sharp:59148,one_k_rounded:62699,one_k_outlined:60925,one_k_plus:57356,one_k_plus_sharp:59147,one_k_plus_rounded:62698,one_k_plus_outlined:60926,one_x_mobiledata:57357,one_x_mobiledata_sharp:59149,one_x_mobiledata_rounded:62700,one_x_mobiledata_outlined:60927,twenty_mp:57358,twenty_mp_sharp:59150,twenty_mp_rounded:62701,twenty_mp_outlined:60928,twenty_one_mp:57359,twenty_one_mp_sharp:59151,twenty_one_mp_rounded:62702,twenty_one_mp_outlined:60929,twenty_two_mp:57360,twenty_two_mp_sharp:59152,twenty_two_mp_rounded:62703,twenty_two_mp_outlined:60930,twenty_three_mp:57361,twenty_three_mp_sharp:59153,twenty_three_mp_rounded:62704,twenty_three_mp_outlined:60931,twenty_four_mp:57362,twenty_four_mp_sharp:59154,twenty_four_mp_rounded:62705,twenty_four_mp_outlined:60932,two_k:57363,two_k_sharp:59156,two_k_rounded:62707,two_k_outlined:60933,two_k_plus:57364,two_k_plus_sharp:59155,two_k_plus_rounded:62706,two_k_plus_outlined:60934,two_mp:57365,two_mp_sharp:59157,two_mp_rounded:62708,two_mp_outlined:60935,thirty_fps:57366,thirty_fps_sharp:59159,thirty_fps_rounded:62709,thirty_fps_outlined:60936,thirty_fps_select:57367,thirty_fps_select_sharp:59158,thirty_fps_select_rounded:62710,thirty_fps_select_outlined:60937,threesixty:57368,threesixty_sharp:59160,threesixty_rounded:62711,threesixty_outlined:60938,threed_rotation:57369,threed_rotation_sharp:59161,threed_rotation_rounded:62712,threed_rotation_outlined:60939,three_g_mobiledata:57370,three_g_mobiledata_sharp:59162,three_g_mobiledata_rounded:62713,three_g_mobiledata_outlined:60940,three_k:57371,three_k_sharp:59164,three_k_rounded:62715,three_k_outlined:60941,three_k_plus:57372,three_k_plus_sharp:59163,three_k_plus_rounded:62714,three_k_plus_outlined:60942,three_mp:57373,three_mp_sharp:59165,three_mp_rounded:62716,three_mp_outlined:60943,three_p:57374,three_p_sharp:59166,three_p_rounded:62717,three_p_outlined:60944,four_g_mobiledata:57375,four_g_mobiledata_sharp:59167,four_g_mobiledata_rounded:62718,four_g_mobiledata_outlined:60945,four_g_plus_mobiledata:57376,four_g_plus_mobiledata_sharp:59168,four_g_plus_mobiledata_rounded:62719,four_g_plus_mobiledata_outlined:60946,four_k:57377,four_k_sharp:59170,four_k_rounded:62721,four_k_outlined:60947,four_k_plus:57378,four_k_plus_sharp:59169,four_k_plus_rounded:62720,four_k_plus_outlined:60948,four_mp:57379,four_mp_sharp:59171,four_mp_rounded:62722,four_mp_outlined:60949,five_g:57380,five_g_sharp:59172,five_g_rounded:62723,five_g_outlined:60950,five_k:57381,five_k_sharp:59174,five_k_rounded:62725,five_k_outlined:60951,five_k_plus:57382,five_k_plus_sharp:59173,five_k_plus_rounded:62724,five_k_plus_outlined:60952,five_mp:57383,five_mp_sharp:59175,five_mp_rounded:62726,five_mp_outlined:60953,sixty_fps:57384,sixty_fps_sharp:59177,sixty_fps_rounded:62727,sixty_fps_outlined:60954,sixty_fps_select:57385,sixty_fps_select_sharp:59176,sixty_fps_select_rounded:62728,sixty_fps_select_outlined:60955,six_ft_apart:57386,six_ft_apart_sharp:59178,six_ft_apart_rounded:62729,six_ft_apart_outlined:60956,six_k:57387,six_k_sharp:59180,six_k_rounded:62731,six_k_outlined:60957,six_k_plus:57388,six_k_plus_sharp:59179,six_k_plus_rounded:62730,six_k_plus_outlined:60958,six_mp:57389,six_mp_sharp:59181,six_mp_rounded:62732,six_mp_outlined:60959,seven_k:57390,seven_k_sharp:59183,seven_k_rounded:62734,seven_k_outlined:60960,seven_k_plus:57391,seven_k_plus_sharp:59182,seven_k_plus_rounded:62733,seven_k_plus_outlined:60961,seven_mp:57392,seven_mp_sharp:59184,seven_mp_rounded:62735,seven_mp_outlined:60962,eight_k:57393,eight_k_sharp:59186,eight_k_rounded:62737,eight_k_outlined:60963,eight_k_plus:57394,eight_k_plus_sharp:59185,eight_k_plus_rounded:62736,eight_k_plus_outlined:60964,eight_mp:57395,eight_mp_sharp:59187,eight_mp_rounded:62738,eight_mp_outlined:60965,nine_k:57396,nine_k_sharp:59189,nine_k_rounded:62740,nine_k_outlined:60966,nine_k_plus:57397,nine_k_plus_sharp:59188,nine_k_plus_rounded:62739,nine_k_plus_outlined:60967,nine_mp:57398,nine_mp_sharp:59190,nine_mp_rounded:62741,nine_mp_outlined:60968,abc:984246,abc_sharp:984003,abc_rounded:58564,abc_outlined:984497,ac_unit:57399,ac_unit_sharp:59191,ac_unit_rounded:62742,ac_unit_outlined:60969,access_alarm:57400,access_alarm_sharp:59192,access_alarm_rounded:62743,access_alarm_outlined:60970,access_alarms:57401,access_alarms_sharp:59193,access_alarms_rounded:62744,access_alarms_outlined:60971,access_time:57402,access_time_sharp:59195,access_time_rounded:62746,access_time_outlined:60973,access_time_filled:57403,access_time_filled_sharp:59194,access_time_filled_rounded:62745,access_time_filled_outlined:60972,accessibility:57404,accessibility_sharp:59197,accessibility_rounded:62748,accessibility_outlined:60975,accessibility_new:57405,accessibility_new_sharp:59196,accessibility_new_rounded:62747,accessibility_new_outlined:60974,accessible:57406,accessible_sharp:59199,accessible_rounded:62750,accessible_outlined:60977,accessible_forward:57407,accessible_forward_sharp:59198,accessible_forward_rounded:62749,accessible_forward_outlined:60976,account_balance:57408,account_balance_sharp:59200,account_balance_rounded:62751,account_balance_outlined:60978,account_balance_wallet:57409,account_balance_wallet_sharp:59201,account_balance_wallet_rounded:62752,account_balance_wallet_outlined:60979,account_box:57410,account_box_sharp:59202,account_box_rounded:62753,account_box_outlined:60980,account_circle:57411,account_circle_sharp:59203,account_circle_rounded:62754,account_circle_outlined:60981,account_tree:57412,account_tree_sharp:59204,account_tree_rounded:62755,account_tree_outlined:60982,ad_units:57413,ad_units_sharp:59205,ad_units_rounded:62756,ad_units_outlined:60983,adb:57414,adb_sharp:59206,adb_rounded:62757,adb_outlined:60984,add:57415,add_sharp:59224,add_rounded:62775,add_outlined:60999,add_a_photo:57416,add_a_photo_sharp:59207,add_a_photo_rounded:62758,add_a_photo_outlined:60985,add_alarm:57417,add_alarm_sharp:59208,add_alarm_rounded:62759,add_alarm_outlined:60986,add_alert:57418,add_alert_sharp:59209,add_alert_rounded:62760,add_alert_outlined:60987,add_box:57419,add_box_sharp:59210,add_box_rounded:62761,add_box_outlined:60988,add_business:57420,add_business_sharp:59211,add_business_rounded:62762,add_business_outlined:60989,add_call:57421,add_card:984247,add_card_sharp:984004,add_card_rounded:983761,add_card_outlined:984498,add_chart:57422,add_chart_sharp:59212,add_chart_rounded:62763,add_chart_outlined:60990,add_circle:57423,add_circle_sharp:59214,add_circle_rounded:62765,add_circle_outlined:60992,add_circle_outline:57424,add_circle_outline_sharp:59213,add_circle_outline_rounded:62764,add_circle_outline_outlined:60991,add_comment:57425,add_comment_sharp:59215,add_comment_rounded:62766,add_comment_outlined:60993,add_home:984965,add_home_sharp:984877,add_home_rounded:985053,add_home_outlined:984789,add_home_work:984966,add_home_work_sharp:984878,add_home_work_rounded:985054,add_home_work_outlined:984790,add_ic_call:57426,add_ic_call_sharp:59216,add_ic_call_rounded:62767,add_ic_call_outlined:60994,add_link:57427,add_link_sharp:59217,add_link_rounded:62768,add_link_outlined:60995,add_location:57428,add_location_sharp:59219,add_location_rounded:62770,add_location_outlined:60997,add_location_alt:57429,add_location_alt_sharp:59218,add_location_alt_rounded:62769,add_location_alt_outlined:60996,add_moderator:57430,add_moderator_sharp:59220,add_moderator_rounded:62771,add_moderator_outlined:60998,add_photo_alternate:57431,add_photo_alternate_sharp:59221,add_photo_alternate_rounded:62772,add_photo_alternate_outlined:61000,add_reaction:57432,add_reaction_sharp:59222,add_reaction_rounded:62773,add_reaction_outlined:61001,add_road:57433,add_road_sharp:59223,add_road_rounded:62774,add_road_outlined:61002,add_shopping_cart:57434,add_shopping_cart_sharp:59225,add_shopping_cart_rounded:62776,add_shopping_cart_outlined:61003,add_task:57435,add_task_sharp:59226,add_task_rounded:62777,add_task_outlined:61004,add_to_drive:57436,add_to_drive_sharp:59227,add_to_drive_rounded:62778,add_to_drive_outlined:61005,add_to_home_screen:57437,add_to_home_screen_sharp:59228,add_to_home_screen_rounded:62779,add_to_home_screen_outlined:61006,add_to_photos:57438,add_to_photos_sharp:59229,add_to_photos_rounded:62780,add_to_photos_outlined:61007,add_to_queue:57439,add_to_queue_sharp:59230,add_to_queue_rounded:62781,add_to_queue_outlined:61008,addchart:57440,addchart_sharp:59231,addchart_rounded:62782,addchart_outlined:61009,adf_scanner:984248,adf_scanner_sharp:984005,adf_scanner_rounded:983762,adf_scanner_outlined:984499,adjust:57441,adjust_sharp:59232,adjust_rounded:62783,adjust_outlined:61010,admin_panel_settings:57442,admin_panel_settings_sharp:59233,admin_panel_settings_rounded:62784,admin_panel_settings_outlined:61011,adobe:984249,adobe_sharp:984006,adobe_rounded:983763,adobe_outlined:984500,ads_click:984250,ads_click_sharp:984007,ads_click_rounded:983764,ads_click_outlined:984501,agriculture:57443,agriculture_sharp:59234,agriculture_rounded:62785,agriculture_outlined:61012,air:57444,air_sharp:59235,air_rounded:62786,air_outlined:61013,airline_seat_flat:57445,airline_seat_flat_sharp:59237,airline_seat_flat_rounded:62788,airline_seat_flat_outlined:61015,airline_seat_flat_angled:57446,airline_seat_flat_angled_sharp:59236,airline_seat_flat_angled_rounded:62787,airline_seat_flat_angled_outlined:61014,airline_seat_individual_suite:57447,airline_seat_individual_suite_sharp:59238,airline_seat_individual_suite_rounded:62789,airline_seat_individual_suite_outlined:61016,airline_seat_legroom_extra:57448,airline_seat_legroom_extra_sharp:59239,airline_seat_legroom_extra_rounded:62790,airline_seat_legroom_extra_outlined:61017,airline_seat_legroom_normal:57449,airline_seat_legroom_normal_sharp:59240,airline_seat_legroom_normal_rounded:62791,airline_seat_legroom_normal_outlined:61018,airline_seat_legroom_reduced:57450,airline_seat_legroom_reduced_sharp:59241,airline_seat_legroom_reduced_rounded:62792,airline_seat_legroom_reduced_outlined:61019,airline_seat_recline_extra:57451,airline_seat_recline_extra_sharp:59242,airline_seat_recline_extra_rounded:62793,airline_seat_recline_extra_outlined:61020,airline_seat_recline_normal:57452,airline_seat_recline_normal_sharp:59243,airline_seat_recline_normal_rounded:62794,airline_seat_recline_normal_outlined:61021,airline_stops:984251,airline_stops_sharp:984008,airline_stops_rounded:983765,airline_stops_outlined:984502,airlines:984252,airlines_sharp:984009,airlines_rounded:983766,airlines_outlined:984503,airplane_ticket:57453,airplane_ticket_sharp:59244,airplane_ticket_rounded:62795,airplane_ticket_outlined:61022,airplanemode_active:57454,airplanemode_active_sharp:59245,airplanemode_active_rounded:62796,airplanemode_active_outlined:61023,airplanemode_inactive:57455,airplanemode_inactive_sharp:59246,airplanemode_inactive_rounded:62797,airplanemode_inactive_outlined:61024,airplanemode_off:57455,airplanemode_off_sharp:59246,airplanemode_off_rounded:62797,airplanemode_off_outlined:61024,airplanemode_on:57454,airplanemode_on_sharp:59245,airplanemode_on_rounded:62796,airplanemode_on_outlined:61023,airplay:57456,airplay_sharp:59247,airplay_rounded:62798,airplay_outlined:61025,airport_shuttle:57457,airport_shuttle_sharp:59248,airport_shuttle_rounded:62799,airport_shuttle_outlined:61026,alarm:57458,alarm_sharp:59252,alarm_rounded:62803,alarm_outlined:61030,alarm_add:57459,alarm_add_sharp:59249,alarm_add_rounded:62800,alarm_add_outlined:61027,alarm_off:57460,alarm_off_sharp:59250,alarm_off_rounded:62801,alarm_off_outlined:61028,alarm_on:57461,alarm_on_sharp:59251,alarm_on_rounded:62802,alarm_on_outlined:61029,album:57462,album_sharp:59253,album_rounded:62804,album_outlined:61031,align_horizontal_center:57463,align_horizontal_center_sharp:59254,align_horizontal_center_rounded:62805,align_horizontal_center_outlined:61032,align_horizontal_left:57464,align_horizontal_left_sharp:59255,align_horizontal_left_rounded:62806,align_horizontal_left_outlined:61033,align_horizontal_right:57465,align_horizontal_right_sharp:59256,align_horizontal_right_rounded:62807,align_horizontal_right_outlined:61034,align_vertical_bottom:57466,align_vertical_bottom_sharp:59257,align_vertical_bottom_rounded:62808,align_vertical_bottom_outlined:61035,align_vertical_center:57467,align_vertical_center_sharp:59258,align_vertical_center_rounded:62809,align_vertical_center_outlined:61036,align_vertical_top:57468,align_vertical_top_sharp:59259,align_vertical_top_rounded:62810,align_vertical_top_outlined:61037,all_inbox:57469,all_inbox_sharp:59260,all_inbox_rounded:62811,all_inbox_outlined:61038,all_inclusive:57470,all_inclusive_sharp:59261,all_inclusive_rounded:62812,all_inclusive_outlined:61039,all_out:57471,all_out_sharp:59262,all_out_rounded:62813,all_out_outlined:61040,alt_route:57472,alt_route_sharp:59263,alt_route_rounded:62814,alt_route_outlined:61041,alternate_email:57473,alternate_email_sharp:59264,alternate_email_rounded:62815,alternate_email_outlined:61042,amp_stories:57474,amp_stories_sharp:59265,amp_stories_rounded:62816,amp_stories_outlined:61043,analytics:57475,analytics_sharp:59266,analytics_rounded:62817,analytics_outlined:61044,anchor:57476,anchor_sharp:59267,anchor_rounded:62818,anchor_outlined:61045,android:57477,android_sharp:59268,android_rounded:62819,android_outlined:61046,animation:57478,animation_sharp:59269,animation_rounded:62820,animation_outlined:61047,announcement:57479,announcement_sharp:59270,announcement_rounded:62821,announcement_outlined:61048,aod:57480,aod_sharp:59271,aod_rounded:62822,aod_outlined:61049,apartment:57481,apartment_sharp:59272,apartment_rounded:62823,apartment_outlined:61050,api:57482,api_sharp:59273,api_rounded:62824,api_outlined:61051,app_blocking:57483,app_blocking_sharp:59274,app_blocking_rounded:62825,app_blocking_outlined:61052,app_registration:57484,app_registration_sharp:59275,app_registration_rounded:62826,app_registration_outlined:61053,app_settings_alt:57485,app_settings_alt_sharp:59276,app_settings_alt_rounded:62827,app_settings_alt_outlined:61054,app_shortcut:984253,app_shortcut_sharp:984010,app_shortcut_rounded:983767,app_shortcut_outlined:984504,apple:984254,apple_sharp:984011,apple_rounded:983768,apple_outlined:984505,approval:57486,approval_sharp:59277,approval_rounded:62828,approval_outlined:61055,apps:57487,apps_sharp:59278,apps_rounded:62829,apps_outlined:61056,apps_outage:984255,apps_outage_sharp:984012,apps_outage_rounded:983769,apps_outage_outlined:984506,architecture:57488,architecture_sharp:59279,architecture_rounded:62830,architecture_outlined:61057,archive:57489,archive_sharp:59280,archive_rounded:62831,archive_outlined:61058,area_chart:984256,area_chart_sharp:984013,area_chart_rounded:983770,area_chart_outlined:984507,arrow_back:57490|R,arrow_back_sharp:59283|R,arrow_back_rounded:62834|R,arrow_back_outlined:61061|R,arrow_back_ios:57491|R,arrow_back_ios_sharp:59282|R,arrow_back_ios_rounded:62833|R,arrow_back_ios_outlined:61060|R,arrow_back_ios_new:57492|R,arrow_back_ios_new_sharp:59281|R,arrow_back_ios_new_rounded:62832|R,arrow_back_ios_new_outlined:61059|R,arrow_circle_down:57493,arrow_circle_down_sharp:59284,arrow_circle_down_rounded:62835,arrow_circle_down_outlined:61062,arrow_circle_left:984257,arrow_circle_left_sharp:984014,arrow_circle_left_rounded:983771,arrow_circle_left_outlined:984508,arrow_circle_right:984258,arrow_circle_right_sharp:984015,arrow_circle_right_rounded:983772,arrow_circle_right_outlined:984509,arrow_circle_up:57494,arrow_circle_up_sharp:59285,arrow_circle_up_rounded:62836,arrow_circle_up_outlined:61063,arrow_downward:57495,arrow_downward_sharp:59286,arrow_downward_rounded:62837,arrow_downward_outlined:61064,arrow_drop_down:57496,arrow_drop_down_sharp:59288,arrow_drop_down_rounded:62839,arrow_drop_down_outlined:61066,arrow_drop_down_circle:57497,arrow_drop_down_circle_sharp:59287,arrow_drop_down_circle_rounded:62838,arrow_drop_down_circle_outlined:61065,arrow_drop_up:57498,arrow_drop_up_sharp:59289,arrow_drop_up_rounded:62840,arrow_drop_up_outlined:61067,arrow_forward:57499|R,arrow_forward_sharp:59291|R,arrow_forward_rounded:62842|R,arrow_forward_outlined:61069|R,arrow_forward_ios:57500|R,arrow_forward_ios_sharp:59290|R,arrow_forward_ios_rounded:62841|R,arrow_forward_ios_outlined:61068|R,arrow_left:57501|R,arrow_left_sharp:59292|R,arrow_left_rounded:62843|R,arrow_left_outlined:61070|R,arrow_outward:985170,arrow_outward_sharp:985140,arrow_outward_rounded:985213,arrow_outward_outlined:985243,arrow_right:57502|R,arrow_right_sharp:59294|R,arrow_right_rounded:62845|R,arrow_right_outlined:61072|R,arrow_right_alt:57503|R,arrow_right_alt_sharp:59293|R,arrow_right_alt_rounded:62844|R,arrow_right_alt_outlined:61071|R,arrow_upward:57504,arrow_upward_sharp:59295,arrow_upward_rounded:62846,arrow_upward_outlined:61073,art_track:57505,art_track_sharp:59296,art_track_rounded:62847,art_track_outlined:61074,article:57506,article_sharp:59297,article_rounded:62848,article_outlined:61075,aspect_ratio:57507,aspect_ratio_sharp:59298,aspect_ratio_rounded:62849,aspect_ratio_outlined:61076,assessment:57508,assessment_sharp:59299,assessment_rounded:62850,assessment_outlined:61077,assignment:57509|R,assignment_sharp:59304|R,assignment_rounded:62855|R,assignment_outlined:61080|R,assignment_add:985171,assignment_ind:57510,assignment_ind_sharp:59300,assignment_ind_rounded:62851,assignment_ind_outlined:61078,assignment_late:57511,assignment_late_sharp:59301,assignment_late_rounded:62852,assignment_late_outlined:61079,assignment_return:57512|R,assignment_return_sharp:59302|R,assignment_return_rounded:62853|R,assignment_return_outlined:61081|R,assignment_returned:57513,assignment_returned_sharp:59303,assignment_returned_rounded:62854,assignment_returned_outlined:61082,assignment_turned_in:57514,assignment_turned_in_sharp:59305,assignment_turned_in_rounded:62856,assignment_turned_in_outlined:61083,assist_walker:985172,assist_walker_sharp:985141,assist_walker_rounded:985214,assist_walker_outlined:985244,assistant:57515,assistant_sharp:59308,assistant_rounded:62859,assistant_outlined:61085,assistant_direction:57516,assistant_direction_sharp:59306,assistant_direction_rounded:62857,assistant_direction_outlined:61084,assistant_navigation:57517,assistant_photo:57518,assistant_photo_sharp:59307,assistant_photo_rounded:62858,assistant_photo_outlined:61086,assured_workload:984259,assured_workload_sharp:984016,assured_workload_rounded:983773,assured_workload_outlined:984510,atm:57519,atm_sharp:59309,atm_rounded:62860,atm_outlined:61087,attach_email:57520,attach_email_sharp:59310,attach_email_rounded:62861,attach_email_outlined:61088,attach_file:57521,attach_file_sharp:59311,attach_file_rounded:62862,attach_file_outlined:61089,attach_money:57522,attach_money_sharp:59312,attach_money_rounded:62863,attach_money_outlined:61090,attachment:57523,attachment_sharp:59313,attachment_rounded:62864,attachment_outlined:61091,attractions:57524,attractions_sharp:59314,attractions_rounded:62865,attractions_outlined:61092,attribution:57525,attribution_sharp:59315,attribution_rounded:62866,attribution_outlined:61093,audio_file:984260,audio_file_sharp:984017,audio_file_rounded:983774,audio_file_outlined:984511,audiotrack:57526,audiotrack_sharp:59316,audiotrack_rounded:62867,audiotrack_outlined:61094,auto_awesome:57527,auto_awesome_sharp:59319,auto_awesome_rounded:62870,auto_awesome_outlined:61097,auto_awesome_mosaic:57528,auto_awesome_mosaic_sharp:59317,auto_awesome_mosaic_rounded:62868,auto_awesome_mosaic_outlined:61095,auto_awesome_motion:57529,auto_awesome_motion_sharp:59318,auto_awesome_motion_rounded:62869,auto_awesome_motion_outlined:61096,auto_delete:57530,auto_delete_sharp:59320,auto_delete_rounded:62871,auto_delete_outlined:61098,auto_fix_high:57531,auto_fix_high_sharp:59321,auto_fix_high_rounded:62872,auto_fix_high_outlined:61099,auto_fix_normal:57532,auto_fix_normal_sharp:59322,auto_fix_normal_rounded:62873,auto_fix_normal_outlined:61100,auto_fix_off:57533,auto_fix_off_sharp:59323,auto_fix_off_rounded:62874,auto_fix_off_outlined:61101,auto_graph:57534,auto_graph_sharp:59324,auto_graph_rounded:62875,auto_graph_outlined:61102,auto_mode:984967,auto_mode_sharp:984879,auto_mode_rounded:985055,auto_mode_outlined:984791,auto_stories:57535,auto_stories_sharp:59325,auto_stories_rounded:62876,auto_stories_outlined:61103,autofps_select:57536,autofps_select_sharp:59326,autofps_select_rounded:62877,autofps_select_outlined:61104,autorenew:57537,autorenew_sharp:59327,autorenew_rounded:62878,autorenew_outlined:61105,av_timer:57538,av_timer_sharp:59328,av_timer_rounded:62879,av_timer_outlined:61106,baby_changing_station:57539,baby_changing_station_sharp:59329,baby_changing_station_rounded:62880,baby_changing_station_outlined:61107,back_hand:984261,back_hand_sharp:984018,back_hand_rounded:983775,back_hand_outlined:984512,backpack:57540,backpack_sharp:59330,backpack_rounded:62881,backpack_outlined:61108,backspace:57541|R,backspace_sharp:59331|R,backspace_rounded:62882|R,backspace_outlined:61109|R,backup:57542,backup_sharp:59332,backup_rounded:62883,backup_outlined:61110,backup_table:57543,backup_table_sharp:59333,backup_table_rounded:62884,backup_table_outlined:61111,badge:57544,badge_sharp:59334,badge_rounded:62885,badge_outlined:61112,bakery_dining:57545,bakery_dining_sharp:59335,bakery_dining_rounded:62886,bakery_dining_outlined:61113,balance:984262,balance_sharp:984019,balance_rounded:983776,balance_outlined:984513,balcony:57546,balcony_sharp:59336,balcony_rounded:62887,balcony_outlined:61114,ballot:57547,ballot_sharp:59337,ballot_rounded:62888,ballot_outlined:61115,bar_chart:57548,bar_chart_sharp:59338,bar_chart_rounded:62889,bar_chart_outlined:61116,barcode_reader:985173,batch_prediction:57549,batch_prediction_sharp:59339,batch_prediction_rounded:62890,batch_prediction_outlined:61117,bathroom:57550,bathroom_sharp:59340,bathroom_rounded:62891,bathroom_outlined:61118,bathtub:57551,bathtub_sharp:59341,bathtub_rounded:62892,bathtub_outlined:61119,battery_0_bar:984968,battery_0_bar_sharp:984880,battery_0_bar_rounded:985056,battery_0_bar_outlined:984792,battery_1_bar:984969,battery_1_bar_sharp:984881,battery_1_bar_rounded:985057,battery_1_bar_outlined:984793,battery_2_bar:984970,battery_2_bar_sharp:984882,battery_2_bar_rounded:985058,battery_2_bar_outlined:984794,battery_3_bar:984971,battery_3_bar_sharp:984883,battery_3_bar_rounded:985059,battery_3_bar_outlined:984795,battery_4_bar:984972,battery_4_bar_sharp:984884,battery_4_bar_rounded:985060,battery_4_bar_outlined:984796,battery_5_bar:984973,battery_5_bar_sharp:984885,battery_5_bar_rounded:985061,battery_5_bar_outlined:984797,battery_6_bar:984974,battery_6_bar_sharp:984886,battery_6_bar_rounded:985062,battery_6_bar_outlined:984798,battery_alert:57552,battery_alert_sharp:59342,battery_alert_rounded:62893,battery_alert_outlined:61120,battery_charging_full:57553,battery_charging_full_sharp:59343,battery_charging_full_rounded:62894,battery_charging_full_outlined:61121,battery_full:57554,battery_full_sharp:59344,battery_full_rounded:62895,battery_full_outlined:61122,battery_saver:57555,battery_saver_sharp:59345,battery_saver_rounded:62896,battery_saver_outlined:61123,battery_std:57556,battery_std_sharp:59346,battery_std_rounded:62897,battery_std_outlined:61124,battery_unknown:57557|R,battery_unknown_sharp:59347|R,battery_unknown_rounded:62898|R,battery_unknown_outlined:61125|R,beach_access:57558,beach_access_sharp:59348,beach_access_rounded:62899,beach_access_outlined:61126,bed:57559,bed_sharp:59349,bed_rounded:62900,bed_outlined:61127,bedroom_baby:57560,bedroom_baby_sharp:59350,bedroom_baby_rounded:62901,bedroom_baby_outlined:61128,bedroom_child:57561,bedroom_child_sharp:59351,bedroom_child_rounded:62902,bedroom_child_outlined:61129,bedroom_parent:57562,bedroom_parent_sharp:59352,bedroom_parent_rounded:62903,bedroom_parent_outlined:61130,bedtime:57563,bedtime_sharp:59353,bedtime_rounded:62904,bedtime_outlined:61131,bedtime_off:984263,bedtime_off_sharp:984020,bedtime_off_rounded:983777,bedtime_off_outlined:984514,beenhere:57564,beenhere_sharp:59354,beenhere_rounded:62905,beenhere_outlined:61132,bento:57565,bento_sharp:59355,bento_rounded:62906,bento_outlined:61133,bike_scooter:57566,bike_scooter_sharp:59356,bike_scooter_rounded:62907,bike_scooter_outlined:61134,biotech:57567,biotech_sharp:59357,biotech_rounded:62908,biotech_outlined:61135,blender:57568,blender_sharp:59358,blender_rounded:62909,blender_outlined:61136,blind:985174,blind_sharp:985142,blind_rounded:985215,blind_outlined:985245,blinds:984975,blinds_sharp:984888,blinds_rounded:985064,blinds_outlined:984800,blinds_closed:984976,blinds_closed_sharp:984887,blinds_closed_rounded:985063,blinds_closed_outlined:984799,block:57569,block_sharp:59359,block_rounded:62910,block_outlined:61137,block_flipped:57570,bloodtype:57571,bloodtype_sharp:59360,bloodtype_rounded:62911,bloodtype_outlined:61138,bluetooth:57572,bluetooth_sharp:59366,bluetooth_rounded:62916,bluetooth_outlined:61143,bluetooth_audio:57573,bluetooth_audio_sharp:59361,bluetooth_audio_rounded:62912,bluetooth_audio_outlined:61139,bluetooth_connected:57574,bluetooth_connected_sharp:59362,bluetooth_connected_rounded:62913,bluetooth_connected_outlined:61140,bluetooth_disabled:57575,bluetooth_disabled_sharp:59363,bluetooth_disabled_rounded:62914,bluetooth_disabled_outlined:61141,bluetooth_drive:57576,bluetooth_drive_sharp:59364,bluetooth_drive_rounded:62915,bluetooth_drive_outlined:61142,bluetooth_searching:57577,bluetooth_searching_sharp:59365,bluetooth_searching_rounded:62917,bluetooth_searching_outlined:61144,blur_circular:57578,blur_circular_sharp:59367,blur_circular_rounded:62918,blur_circular_outlined:61145,blur_linear:57579,blur_linear_sharp:59368,blur_linear_rounded:62919,blur_linear_outlined:61146,blur_off:57580,blur_off_sharp:59369,blur_off_rounded:62920,blur_off_outlined:61147,blur_on:57581,blur_on_sharp:59370,blur_on_rounded:62921,blur_on_outlined:61148,bolt:57582,bolt_sharp:59371,bolt_rounded:62922,bolt_outlined:61149,book:57583,book_sharp:59373,book_rounded:62924,book_outlined:61151,book_online:57584,book_online_sharp:59372,book_online_rounded:62923,book_online_outlined:61150,bookmark:57585,bookmark_sharp:59378,bookmark_rounded:62929,bookmark_outlined:61155,bookmark_add:57586,bookmark_add_sharp:59374,bookmark_add_rounded:62925,bookmark_add_outlined:61152,bookmark_added:57587,bookmark_added_sharp:59375,bookmark_added_rounded:62926,bookmark_added_outlined:61153,bookmark_border:57588,bookmark_border_sharp:59376,bookmark_border_rounded:62927,bookmark_border_outlined:61154,bookmark_outline:57588,bookmark_outline_sharp:59376,bookmark_outline_rounded:62927,bookmark_outline_outlined:61154,bookmark_remove:57589,bookmark_remove_sharp:59377,bookmark_remove_rounded:62928,bookmark_remove_outlined:61156,bookmarks:57590,bookmarks_sharp:59379,bookmarks_rounded:62930,bookmarks_outlined:61157,border_all:57591,border_all_sharp:59380,border_all_rounded:62931,border_all_outlined:61158,border_bottom:57592,border_bottom_sharp:59381,border_bottom_rounded:62932,border_bottom_outlined:61159,border_clear:57593,border_clear_sharp:59382,border_clear_rounded:62933,border_clear_outlined:61160,border_color:57594,border_color_sharp:59383,border_color_rounded:62934,border_color_outlined:61161,border_horizontal:57595,border_horizontal_sharp:59384,border_horizontal_rounded:62935,border_horizontal_outlined:61162,border_inner:57596,border_inner_sharp:59385,border_inner_rounded:62936,border_inner_outlined:61163,border_left:57597,border_left_sharp:59386,border_left_rounded:62937,border_left_outlined:61164,border_outer:57598,border_outer_sharp:59387,border_outer_rounded:62938,border_outer_outlined:61165,border_right:57599,border_right_sharp:59388,border_right_rounded:62939,border_right_outlined:61166,border_style:57600,border_style_sharp:59389,border_style_rounded:62940,border_style_outlined:61167,border_top:57601,border_top_sharp:59390,border_top_rounded:62941,border_top_outlined:61168,border_vertical:57602,border_vertical_sharp:59391,border_vertical_rounded:62942,border_vertical_outlined:61169,boy:984264,boy_sharp:984021,boy_rounded:983778,boy_outlined:984515,branding_watermark:57603,branding_watermark_sharp:59392,branding_watermark_rounded:62943,branding_watermark_outlined:61170,breakfast_dining:57604,breakfast_dining_sharp:59393,breakfast_dining_rounded:62944,breakfast_dining_outlined:61171,brightness_1:57605,brightness_1_sharp:59394,brightness_1_rounded:62945,brightness_1_outlined:61172,brightness_2:57606,brightness_2_sharp:59395,brightness_2_rounded:62946,brightness_2_outlined:61173,brightness_3:57607,brightness_3_sharp:59396,brightness_3_rounded:62947,brightness_3_outlined:61174,brightness_4:57608,brightness_4_sharp:59397,brightness_4_rounded:62948,brightness_4_outlined:61175,brightness_5:57609,brightness_5_sharp:59398,brightness_5_rounded:62949,brightness_5_outlined:61176,brightness_6:57610,brightness_6_sharp:59399,brightness_6_rounded:62950,brightness_6_outlined:61177,brightness_7:57611,brightness_7_sharp:59400,brightness_7_rounded:62951,brightness_7_outlined:61178,brightness_auto:57612,brightness_auto_sharp:59401,brightness_auto_rounded:62952,brightness_auto_outlined:61179,brightness_high:57613,brightness_high_sharp:59402,brightness_high_rounded:62953,brightness_high_outlined:61180,brightness_low:57614,brightness_low_sharp:59403,brightness_low_rounded:62954,brightness_low_outlined:61181,brightness_medium:57615,brightness_medium_sharp:59404,brightness_medium_rounded:62955,brightness_medium_outlined:61182,broadcast_on_home:984977,broadcast_on_home_sharp:984889,broadcast_on_home_rounded:985065,broadcast_on_home_outlined:984801,broadcast_on_personal:984978,broadcast_on_personal_sharp:984890,broadcast_on_personal_rounded:985066,broadcast_on_personal_outlined:984802,broken_image:57616,broken_image_sharp:59405,broken_image_rounded:62956,broken_image_outlined:61183,browse_gallery:984762,browse_gallery_sharp:984749,browse_gallery_rounded:984775,browse_gallery_outlined:983996,browser_not_supported:57617,browser_not_supported_sharp:59406,browser_not_supported_rounded:62957,browser_not_supported_outlined:61184,browser_updated:984265,browser_updated_sharp:984022,browser_updated_rounded:983779,browser_updated_outlined:984516,brunch_dining:57618,brunch_dining_sharp:59407,brunch_dining_rounded:62958,brunch_dining_outlined:61185,brush:57619,brush_sharp:59408,brush_rounded:62959,brush_outlined:61186,bubble_chart:57620,bubble_chart_sharp:59409,bubble_chart_rounded:62960,bubble_chart_outlined:61187,bug_report:57621,bug_report_sharp:59410,bug_report_rounded:62961,bug_report_outlined:61188,build:57622,build_sharp:59412,build_rounded:62963,build_outlined:61190,build_circle:57623,build_circle_sharp:59411,build_circle_rounded:62962,build_circle_outlined:61189,bungalow:57624,bungalow_sharp:59413,bungalow_rounded:62964,bungalow_outlined:61191,burst_mode:57625,burst_mode_sharp:59414,burst_mode_rounded:62965,burst_mode_outlined:61192,bus_alert:57626,bus_alert_sharp:59415,bus_alert_rounded:62966,bus_alert_outlined:61193,business:57627,business_sharp:59417,business_rounded:62968,business_outlined:61195,business_center:57628,business_center_sharp:59416,business_center_rounded:62967,business_center_outlined:61194,cabin:57629,cabin_sharp:59418,cabin_rounded:62969,cabin_outlined:61196,cable:57630,cable_sharp:59419,cable_rounded:62970,cable_outlined:61197,cached:57631,cached_sharp:59420,cached_rounded:62971,cached_outlined:61198,cake:57632,cake_sharp:59421,cake_rounded:62972,cake_outlined:61199,calculate:57633,calculate_sharp:59422,calculate_rounded:62973,calculate_outlined:61200,calendar_month:984763,calendar_month_sharp:984750,calendar_month_rounded:984776,calendar_month_outlined:984351,calendar_today:57634,calendar_today_sharp:59423,calendar_today_rounded:62974,calendar_today_outlined:61201,calendar_view_day:57635,calendar_view_day_sharp:59424,calendar_view_day_rounded:62975,calendar_view_day_outlined:61202,calendar_view_month:57636,calendar_view_month_sharp:59425,calendar_view_month_rounded:62976,calendar_view_month_outlined:61203,calendar_view_week:57637,calendar_view_week_sharp:59426,calendar_view_week_rounded:62977,calendar_view_week_outlined:61204,call:57638,call_sharp:59433,call_rounded:62984,call_outlined:61210,call_end:57639,call_end_sharp:59427,call_end_rounded:62978,call_end_outlined:61205,call_made:57640|R,call_made_sharp:59428|R,call_made_rounded:62979|R,call_made_outlined:61206|R,call_merge:57641|R,call_merge_sharp:59429|R,call_merge_rounded:62980|R,call_merge_outlined:61207|R,call_missed:57642|R,call_missed_sharp:59431|R,call_missed_rounded:62982|R,call_missed_outlined:61209|R,call_missed_outgoing:57643|R,call_missed_outgoing_sharp:59430|R,call_missed_outgoing_rounded:62981|R,call_missed_outgoing_outlined:61208|R,call_received:57644|R,call_received_sharp:59432|R,call_received_rounded:62983|R,call_received_outlined:61211|R,call_split:57645|R,call_split_sharp:59434|R,call_split_rounded:62985|R,call_split_outlined:61212|R,call_to_action:57646,call_to_action_sharp:59435,call_to_action_rounded:62986,call_to_action_outlined:61213,camera:57647,camera_sharp:59443,camera_rounded:62994,camera_outlined:61219,camera_alt:57648,camera_alt_sharp:59436,camera_alt_rounded:62987,camera_alt_outlined:61214,camera_enhance:57649,camera_enhance_sharp:59437,camera_enhance_rounded:62988,camera_enhance_outlined:61215,camera_front:57650,camera_front_sharp:59438,camera_front_rounded:62989,camera_front_outlined:61216,camera_indoor:57651,camera_indoor_sharp:59439,camera_indoor_rounded:62990,camera_indoor_outlined:61217,camera_outdoor:57652,camera_outdoor_sharp:59440,camera_outdoor_rounded:62991,camera_outdoor_outlined:61218,camera_rear:57653,camera_rear_sharp:59441,camera_rear_rounded:62992,camera_rear_outlined:61220,camera_roll:57654,camera_roll_sharp:59442,camera_roll_rounded:62993,camera_roll_outlined:61221,cameraswitch:57655,cameraswitch_sharp:59444,cameraswitch_rounded:62995,cameraswitch_outlined:61222,campaign:57656,campaign_sharp:59445,campaign_rounded:62996,campaign_outlined:61223,cancel:57657,cancel_sharp:59448,cancel_rounded:62998,cancel_outlined:61224,cancel_presentation:57658,cancel_presentation_sharp:59446,cancel_presentation_rounded:62997,cancel_presentation_outlined:61225,cancel_schedule_send:57659,cancel_schedule_send_sharp:59447,cancel_schedule_send_rounded:62999,cancel_schedule_send_outlined:61226,candlestick_chart:984266,candlestick_chart_sharp:984023,candlestick_chart_rounded:983780,candlestick_chart_outlined:984517,car_crash:984979,car_crash_sharp:984891,car_crash_rounded:985067,car_crash_outlined:984803,car_rental:57660,car_rental_sharp:59449,car_rental_rounded:63000,car_rental_outlined:61227,car_repair:57661,car_repair_sharp:59450,car_repair_rounded:63001,car_repair_outlined:61228,card_giftcard:57662,card_giftcard_sharp:59451,card_giftcard_rounded:63002,card_giftcard_outlined:61229,card_membership:57663,card_membership_sharp:59452,card_membership_rounded:63003,card_membership_outlined:61230,card_travel:57664,card_travel_sharp:59453,card_travel_rounded:63004,card_travel_outlined:61231,carpenter:57665,carpenter_sharp:59454,carpenter_rounded:63005,carpenter_outlined:61232,cases:57666,cases_sharp:59455,cases_rounded:63006,cases_outlined:61233,casino:57667,casino_sharp:59456,casino_rounded:63007,casino_outlined:61234,cast:57668,cast_sharp:59459,cast_rounded:63010,cast_outlined:61237,cast_connected:57669,cast_connected_sharp:59457,cast_connected_rounded:63008,cast_connected_outlined:61235,cast_for_education:57670,cast_for_education_sharp:59458,cast_for_education_rounded:63009,cast_for_education_outlined:61236,castle:984267,castle_sharp:984024,castle_rounded:983781,castle_outlined:984518,catching_pokemon:57671,catching_pokemon_sharp:59460,catching_pokemon_rounded:63011,catching_pokemon_outlined:61238,category:57672,category_sharp:59461,category_rounded:63012,category_outlined:61239,celebration:57673,celebration_sharp:59462,celebration_rounded:63013,celebration_outlined:61240,cell_tower:984268,cell_tower_sharp:984025,cell_tower_rounded:983782,cell_tower_outlined:984519,cell_wifi:57674,cell_wifi_sharp:59463,cell_wifi_rounded:63014,cell_wifi_outlined:61241,center_focus_strong:57675,center_focus_strong_sharp:59464,center_focus_strong_rounded:63015,center_focus_strong_outlined:61242,center_focus_weak:57676,center_focus_weak_sharp:59465,center_focus_weak_rounded:63016,center_focus_weak_outlined:61243,chair:57677,chair_sharp:59467,chair_rounded:63018,chair_outlined:61245,chair_alt:57678,chair_alt_sharp:59466,chair_alt_rounded:63017,chair_alt_outlined:61244,chalet:57679,chalet_sharp:59468,chalet_rounded:63019,chalet_outlined:61246,change_circle:57680,change_circle_sharp:59469,change_circle_rounded:63020,change_circle_outlined:61247,change_history:57681,change_history_sharp:59470,change_history_rounded:63021,change_history_outlined:61248,charging_station:57682,charging_station_sharp:59471,charging_station_rounded:63022,charging_station_outlined:61249,chat:57683,chat_sharp:59474,chat_rounded:63025,chat_outlined:61252,chat_bubble:57684,chat_bubble_sharp:59473,chat_bubble_rounded:63024,chat_bubble_outlined:61251,chat_bubble_outline:57685,chat_bubble_outline_sharp:59472,chat_bubble_outline_rounded:63023,chat_bubble_outline_outlined:61250,check:57686,check_sharp:59479,check_rounded:63030,check_outlined:61257,check_box:57687,check_box_sharp:59476,check_box_rounded:63027,check_box_outlined:61254,check_box_outline_blank:57688,check_box_outline_blank_sharp:59475,check_box_outline_blank_rounded:63026,check_box_outline_blank_outlined:61253,check_circle:57689,check_circle_sharp:59478,check_circle_rounded:63029,check_circle_outlined:61256,check_circle_outline:57690,check_circle_outline_sharp:59477,check_circle_outline_rounded:63028,check_circle_outline_outlined:61255,checklist:57691,checklist_sharp:59481,checklist_rounded:63031,checklist_outlined:61258,checklist_rtl:57692,checklist_rtl_sharp:59480,checklist_rtl_rounded:63032,checklist_rtl_outlined:61259,checkroom:57693,checkroom_sharp:59482,checkroom_rounded:63033,checkroom_outlined:61260,chevron_left:57694|R,chevron_left_sharp:59483|R,chevron_left_rounded:63034|R,chevron_left_outlined:61261|R,chevron_right:57695|R,chevron_right_sharp:59484|R,chevron_right_rounded:63035|R,chevron_right_outlined:61262|R,child_care:57696,child_care_sharp:59485,child_care_rounded:63036,child_care_outlined:61263,child_friendly:57697,child_friendly_sharp:59486,child_friendly_rounded:63037,child_friendly_outlined:61264,chrome_reader_mode:57698|R,chrome_reader_mode_sharp:59487|R,chrome_reader_mode_rounded:63038|R,chrome_reader_mode_outlined:61265|R,church:984269,church_sharp:984026,church_rounded:983783,church_outlined:984520,circle:57699,circle_sharp:59489,circle_rounded:63040,circle_outlined:61267,circle_notifications:57700,circle_notifications_sharp:59488,circle_notifications_rounded:63039,circle_notifications_outlined:61266,class_:57701,class_sharp:59490,class_rounded:63041,class_outlined:61268,clean_hands:57702,clean_hands_sharp:59491,clean_hands_rounded:63042,clean_hands_outlined:61269,cleaning_services:57703,cleaning_services_sharp:59492,cleaning_services_rounded:63043,cleaning_services_outlined:61270,clear:57704,clear_sharp:59494,clear_rounded:63045,clear_outlined:61272,clear_all:57705,clear_all_sharp:59493,clear_all_rounded:63044,clear_all_outlined:61271,close:57706,close_sharp:59496,close_rounded:63047,close_outlined:61274,close_fullscreen:57707,close_fullscreen_sharp:59495,close_fullscreen_rounded:63046,close_fullscreen_outlined:61273,closed_caption:57708,closed_caption_sharp:59499,closed_caption_rounded:63050,closed_caption_outlined:61277,closed_caption_disabled:57709,closed_caption_disabled_sharp:59497,closed_caption_disabled_rounded:63048,closed_caption_disabled_outlined:61275,closed_caption_off:57710,closed_caption_off_sharp:59498,closed_caption_off_rounded:63049,closed_caption_off_outlined:61276,cloud:57711,cloud_sharp:59505,cloud_rounded:63056,cloud_outlined:61282,cloud_circle:57712,cloud_circle_sharp:59500,cloud_circle_rounded:63051,cloud_circle_outlined:61278,cloud_done:57713,cloud_done_sharp:59501,cloud_done_rounded:63052,cloud_done_outlined:61279,cloud_download:57714,cloud_download_sharp:59502,cloud_download_rounded:63053,cloud_download_outlined:61280,cloud_off:57715,cloud_off_sharp:59503,cloud_off_rounded:63054,cloud_off_outlined:61281,cloud_queue:57716,cloud_queue_sharp:59504,cloud_queue_rounded:63055,cloud_queue_outlined:61283,cloud_sync:984270,cloud_sync_sharp:984027,cloud_sync_rounded:983784,cloud_sync_outlined:984521,cloud_upload:57717,cloud_upload_sharp:59506,cloud_upload_rounded:63057,cloud_upload_outlined:61284,cloudy_snowing:984271,co2:984272,co2_sharp:984028,co2_rounded:983785,co2_outlined:984522,co_present:984273,co_present_sharp:984029,co_present_rounded:983786,co_present_outlined:984523,code:57718,code_sharp:59508,code_rounded:63059,code_outlined:61286,code_off:57719,code_off_sharp:59507,code_off_rounded:63058,code_off_outlined:61285,coffee:57720,coffee_sharp:59510,coffee_rounded:63061,coffee_outlined:61288,coffee_maker:57721,coffee_maker_sharp:59509,coffee_maker_rounded:63060,coffee_maker_outlined:61287,collections:57722,collections_sharp:59512,collections_rounded:63063,collections_outlined:61290,collections_bookmark:57723,collections_bookmark_sharp:59511,collections_bookmark_rounded:63062,collections_bookmark_outlined:61289,color_lens:57724,color_lens_sharp:59513,color_lens_rounded:63064,color_lens_outlined:61291,colorize:57725,colorize_sharp:59514,colorize_rounded:63065,colorize_outlined:61292,comment:57726,comment_sharp:59516,comment_rounded:63067,comment_outlined:61294,comment_bank:57727,comment_bank_sharp:59515,comment_bank_rounded:63066,comment_bank_outlined:61293,comments_disabled:984274,comments_disabled_sharp:984030,comments_disabled_rounded:983787,comments_disabled_outlined:984524,commit:984275,commit_sharp:984031,commit_rounded:983788,commit_outlined:984525,commute:57728,commute_sharp:59517,commute_rounded:63068,commute_outlined:61295,compare:57729,compare_sharp:59519,compare_rounded:63070,compare_outlined:61297,compare_arrows:57730,compare_arrows_sharp:59518,compare_arrows_rounded:63069,compare_arrows_outlined:61296,compass_calibration:57731,compass_calibration_sharp:59520,compass_calibration_rounded:63071,compass_calibration_outlined:61298,compost:984276,compost_sharp:984032,compost_rounded:983789,compost_outlined:984526,compress:57732,compress_sharp:59521,compress_rounded:63072,compress_outlined:61299,computer:57733,computer_sharp:59522,computer_rounded:63073,computer_outlined:61300,confirmation_num:57734,confirmation_num_sharp:59523,confirmation_num_rounded:63074,confirmation_num_outlined:61301,confirmation_number:57734,confirmation_number_sharp:59523,confirmation_number_rounded:63074,confirmation_number_outlined:61301,connect_without_contact:57735,connect_without_contact_sharp:59524,connect_without_contact_rounded:63075,connect_without_contact_outlined:61302,connected_tv:57736,connected_tv_sharp:59525,connected_tv_rounded:63076,connected_tv_outlined:61303,connecting_airports:984277,connecting_airports_sharp:984033,connecting_airports_rounded:983790,connecting_airports_outlined:984527,construction:57737,construction_sharp:59526,construction_rounded:63077,construction_outlined:61304,contact_emergency:985175,contact_emergency_sharp:985143,contact_emergency_rounded:985216,contact_emergency_outlined:985246,contact_mail:57738,contact_mail_sharp:59527,contact_mail_rounded:63078,contact_mail_outlined:61305,contact_page:57739,contact_page_sharp:59528,contact_page_rounded:63079,contact_page_outlined:61306,contact_phone:57740,contact_phone_sharp:59529,contact_phone_rounded:63080,contact_phone_outlined:61307,contact_support:57741,contact_support_sharp:59530,contact_support_rounded:63081,contact_support_outlined:61308,contactless:57742,contactless_sharp:59531,contactless_rounded:63082,contactless_outlined:61309,contacts:57743,contacts_sharp:59532,contacts_rounded:63083,contacts_outlined:61310,content_copy:57744,content_copy_sharp:59533,content_copy_rounded:63084,content_copy_outlined:61311,content_cut:57745,content_cut_sharp:59534,content_cut_rounded:63085,content_cut_outlined:61312,content_paste:57746,content_paste_sharp:59536,content_paste_rounded:63087,content_paste_outlined:61314,content_paste_go:984278,content_paste_go_sharp:984034,content_paste_go_rounded:983791,content_paste_go_outlined:984528,content_paste_off:57747,content_paste_off_sharp:59535,content_paste_off_rounded:63086,content_paste_off_outlined:61313,content_paste_search:984279,content_paste_search_sharp:984035,content_paste_search_rounded:983792,content_paste_search_outlined:984529,contrast:984280,contrast_sharp:984036,contrast_rounded:983793,contrast_outlined:984530,control_camera:57748,control_camera_sharp:59537,control_camera_rounded:63088,control_camera_outlined:61315,control_point:57749,control_point_sharp:59539,control_point_rounded:63090,control_point_outlined:61317,control_point_duplicate:57750,control_point_duplicate_sharp:59538,control_point_duplicate_rounded:63089,control_point_duplicate_outlined:61316,conveyor_belt:985176,cookie:984281,cookie_sharp:984037,cookie_rounded:983794,cookie_outlined:984531,copy:57744,copy_sharp:59533,copy_rounded:63084,copy_outlined:61311,copy_all:57751,copy_all_sharp:59540,copy_all_rounded:63091,copy_all_outlined:61318,copyright:57752,copyright_sharp:59541,copyright_rounded:63092,copyright_outlined:61319,coronavirus:57753,coronavirus_sharp:59542,coronavirus_rounded:63093,coronavirus_outlined:61320,corporate_fare:57754,corporate_fare_sharp:59543,corporate_fare_rounded:63094,corporate_fare_outlined:61321,cottage:57755,cottage_sharp:59544,cottage_rounded:63095,cottage_outlined:61322,countertops:57756,countertops_sharp:59545,countertops_rounded:63096,countertops_outlined:61323,create:57757,create_sharp:59547,create_rounded:63098,create_outlined:61325,create_new_folder:57758,create_new_folder_sharp:59546,create_new_folder_rounded:63097,create_new_folder_outlined:61324,credit_card:57759,credit_card_sharp:59549,credit_card_rounded:63100,credit_card_outlined:61327,credit_card_off:57760,credit_card_off_sharp:59548,credit_card_off_rounded:63099,credit_card_off_outlined:61326,credit_score:57761,credit_score_sharp:59550,credit_score_rounded:63101,credit_score_outlined:61328,crib:57762,crib_sharp:59551,crib_rounded:63102,crib_outlined:61329,crisis_alert:984980,crisis_alert_sharp:984892,crisis_alert_rounded:985068,crisis_alert_outlined:984804,crop:57763,crop_sharp:59562,crop_rounded:63113,crop_outlined:61338,crop_16_9:57764,crop_16_9_sharp:59552,crop_16_9_rounded:63103,crop_16_9_outlined:61330,crop_3_2:57765,crop_3_2_sharp:59553,crop_3_2_rounded:63104,crop_3_2_outlined:61331,crop_5_4:57766,crop_5_4_sharp:59554,crop_5_4_rounded:63105,crop_5_4_outlined:61332,crop_7_5:57767,crop_7_5_sharp:59555,crop_7_5_rounded:63106,crop_7_5_outlined:61333,crop_din:57768,crop_din_sharp:59556,crop_din_rounded:63107,crop_din_outlined:61334,crop_free:57769,crop_free_sharp:59557,crop_free_rounded:63108,crop_free_outlined:61335,crop_landscape:57770,crop_landscape_sharp:59558,crop_landscape_rounded:63109,crop_landscape_outlined:61336,crop_original:57771,crop_original_sharp:59559,crop_original_rounded:63110,crop_original_outlined:61337,crop_portrait:57772,crop_portrait_sharp:59560,crop_portrait_rounded:63111,crop_portrait_outlined:61339,crop_rotate:57773,crop_rotate_sharp:59561,crop_rotate_rounded:63112,crop_rotate_outlined:61340,crop_square:57774,crop_square_sharp:59563,crop_square_rounded:63114,crop_square_outlined:61341,cruelty_free:984282,cruelty_free_sharp:984038,cruelty_free_rounded:983795,cruelty_free_outlined:984532,css:984283,css_sharp:984039,css_rounded:983796,css_outlined:984533,currency_bitcoin:984764,currency_bitcoin_sharp:984751,currency_bitcoin_rounded:984777,currency_bitcoin_outlined:984394,currency_exchange:984284,currency_exchange_sharp:984040,currency_exchange_rounded:983797,currency_exchange_outlined:984534,currency_franc:984285,currency_franc_sharp:984041,currency_franc_rounded:983798,currency_franc_outlined:984535,currency_lira:984286,currency_lira_sharp:984042,currency_lira_rounded:983799,currency_lira_outlined:984536,currency_pound:984287,currency_pound_sharp:984043,currency_pound_rounded:983800,currency_pound_outlined:984537,currency_ruble:984288,currency_ruble_sharp:984044,currency_ruble_rounded:983801,currency_ruble_outlined:984538,currency_rupee:984289,currency_rupee_sharp:984045,currency_rupee_rounded:983802,currency_rupee_outlined:984539,currency_yen:984290,currency_yen_sharp:984046,currency_yen_rounded:983803,currency_yen_outlined:984540,currency_yuan:984291,currency_yuan_sharp:984047,currency_yuan_rounded:983804,currency_yuan_outlined:984541,curtains:984981,curtains_sharp:984894,curtains_rounded:985070,curtains_outlined:984806,curtains_closed:984982,curtains_closed_sharp:984893,curtains_closed_rounded:985069,curtains_closed_outlined:984805,cut:57745,cut_sharp:59534,cut_rounded:63085,cut_outlined:61312,cyclone:984983,cyclone_sharp:984895,cyclone_rounded:985071,cyclone_outlined:984807,dangerous:57775,dangerous_sharp:59564,dangerous_rounded:63115,dangerous_outlined:61342,dark_mode:57776,dark_mode_sharp:59565,dark_mode_rounded:63116,dark_mode_outlined:61343,dashboard:57777,dashboard_sharp:59567,dashboard_rounded:63118,dashboard_outlined:61345,dashboard_customize:57778,dashboard_customize_sharp:59566,dashboard_customize_rounded:63117,dashboard_customize_outlined:61344,data_array:984292,data_array_sharp:984048,data_array_rounded:983805,data_array_outlined:984542,data_exploration:984293,data_exploration_sharp:984049,data_exploration_rounded:983806,data_exploration_outlined:984543,data_object:984294,data_object_sharp:984050,data_object_rounded:983807,data_object_outlined:984544,data_saver_off:57779,data_saver_off_sharp:59568,data_saver_off_rounded:63119,data_saver_off_outlined:61346,data_saver_on:57780,data_saver_on_sharp:59569,data_saver_on_rounded:63120,data_saver_on_outlined:61347,data_thresholding:984295,data_thresholding_sharp:984051,data_thresholding_rounded:983808,data_thresholding_outlined:984545,data_usage:57781,data_usage_sharp:59570,data_usage_rounded:63121,data_usage_outlined:61348,dataset:984984,dataset_sharp:984897,dataset_rounded:985073,dataset_outlined:984809,dataset_linked:984985,dataset_linked_sharp:984896,dataset_linked_rounded:985072,dataset_linked_outlined:984808,date_range:57782,date_range_sharp:59571,date_range_rounded:63122,date_range_outlined:61349,deblur:984296,deblur_sharp:984052,deblur_rounded:983809,deblur_outlined:984546,deck:57783,deck_sharp:59572,deck_rounded:63123,deck_outlined:61350,dehaze:57784,dehaze_sharp:59573,dehaze_rounded:63124,dehaze_outlined:61351,delete:57785,delete_sharp:59576,delete_rounded:63127,delete_outlined:61354,delete_forever:57786,delete_forever_sharp:59574,delete_forever_rounded:63125,delete_forever_outlined:61352,delete_outline:57787,delete_outline_sharp:59575,delete_outline_rounded:63126,delete_outline_outlined:61353,delete_sweep:57788,delete_sweep_sharp:59577,delete_sweep_rounded:63128,delete_sweep_outlined:61355,delivery_dining:57789,delivery_dining_sharp:59578,delivery_dining_rounded:63129,delivery_dining_outlined:61356,density_large:984297,density_large_sharp:984053,density_large_rounded:983810,density_large_outlined:984547,density_medium:984298,density_medium_sharp:984054,density_medium_rounded:983811,density_medium_outlined:984548,density_small:984299,density_small_sharp:984055,density_small_rounded:983812,density_small_outlined:984549,departure_board:57790,departure_board_sharp:59579,departure_board_rounded:63130,departure_board_outlined:61357,description:57791,description_sharp:59580,description_rounded:63131,description_outlined:61358,deselect:984300,deselect_sharp:984056,deselect_rounded:983813,deselect_outlined:984550,design_services:57792,design_services_sharp:59581,design_services_rounded:63132,design_services_outlined:61359,desk:984986,desk_sharp:984898,desk_rounded:985074,desk_outlined:984810,desktop_access_disabled:57793,desktop_access_disabled_sharp:59582,desktop_access_disabled_rounded:63133,desktop_access_disabled_outlined:61360,desktop_mac:57794,desktop_mac_sharp:59583,desktop_mac_rounded:63134,desktop_mac_outlined:61361,desktop_windows:57795,desktop_windows_sharp:59584,desktop_windows_rounded:63135,desktop_windows_outlined:61362,details:57796,details_sharp:59585,details_rounded:63136,details_outlined:61363,developer_board:57797,developer_board_sharp:59587,developer_board_rounded:63138,developer_board_outlined:61365,developer_board_off:57798,developer_board_off_sharp:59586,developer_board_off_rounded:63137,developer_board_off_outlined:61364,developer_mode:57799,developer_mode_sharp:59588,developer_mode_rounded:63139,developer_mode_outlined:61366,device_hub:57800,device_hub_sharp:59589,device_hub_rounded:63140,device_hub_outlined:61367,device_thermostat:57801,device_thermostat_sharp:59590,device_thermostat_rounded:63141,device_thermostat_outlined:61368,device_unknown:57802|R,device_unknown_sharp:59591|R,device_unknown_rounded:63142|R,device_unknown_outlined:61369|R,devices:57803,devices_sharp:59593,devices_rounded:63144,devices_outlined:61371,devices_fold:984987,devices_fold_sharp:984899,devices_fold_rounded:985075,devices_fold_outlined:984811,devices_other:57804,devices_other_sharp:59592,devices_other_rounded:63143,devices_other_outlined:61370,dew_point:985177,dialer_sip:57805,dialer_sip_sharp:59594,dialer_sip_rounded:63145,dialer_sip_outlined:61372,dialpad:57806,dialpad_sharp:59595,dialpad_rounded:63146,dialpad_outlined:61373,diamond:984301,diamond_sharp:984057,diamond_rounded:983814,diamond_outlined:984551,difference:984302,difference_sharp:984058,difference_rounded:983815,difference_outlined:984552,dining:57807,dining_sharp:59596,dining_rounded:63147,dining_outlined:61374,dinner_dining:57808,dinner_dining_sharp:59597,dinner_dining_rounded:63148,dinner_dining_outlined:61375,directions:57809,directions_sharp:59609,directions_rounded:63159,directions_outlined:61384,directions_bike:57810,directions_bike_sharp:59598,directions_bike_rounded:63149,directions_bike_outlined:61376,directions_boat:57811,directions_boat_sharp:59600,directions_boat_rounded:63151,directions_boat_outlined:61378,directions_boat_filled:57812,directions_boat_filled_sharp:59599,directions_boat_filled_rounded:63150,directions_boat_filled_outlined:61377,directions_bus:57813,directions_bus_sharp:59602,directions_bus_rounded:63153,directions_bus_outlined:61380,directions_bus_filled:57814,directions_bus_filled_sharp:59601,directions_bus_filled_rounded:63152,directions_bus_filled_outlined:61379,directions_car:57815,directions_car_sharp:59604,directions_car_rounded:63155,directions_car_outlined:61382,directions_car_filled:57816,directions_car_filled_sharp:59603,directions_car_filled_rounded:63154,directions_car_filled_outlined:61381,directions_ferry:57811,directions_ferry_sharp:59600,directions_ferry_rounded:63151,directions_ferry_outlined:61378,directions_off:57817,directions_off_sharp:59605,directions_off_rounded:63156,directions_off_outlined:61383,directions_railway:57818,directions_railway_sharp:59607,directions_railway_rounded:63158,directions_railway_outlined:61386,directions_railway_filled:57819,directions_railway_filled_sharp:59606,directions_railway_filled_rounded:63157,directions_railway_filled_outlined:61385,directions_run:57820,directions_run_sharp:59608,directions_run_rounded:63160,directions_run_outlined:61387,directions_subway:57821,directions_subway_sharp:59611,directions_subway_rounded:63162,directions_subway_outlined:61389,directions_subway_filled:57822,directions_subway_filled_sharp:59610,directions_subway_filled_rounded:63161,directions_subway_filled_outlined:61388,directions_train:57818,directions_train_sharp:59607,directions_train_rounded:63158,directions_train_outlined:61386,directions_transit:57823,directions_transit_sharp:59613,directions_transit_rounded:63164,directions_transit_outlined:61391,directions_transit_filled:57824,directions_transit_filled_sharp:59612,directions_transit_filled_rounded:63163,directions_transit_filled_outlined:61390,directions_walk:57825,directions_walk_sharp:59614,directions_walk_rounded:63165,directions_walk_outlined:61392,dirty_lens:57826,dirty_lens_sharp:59615,dirty_lens_rounded:63166,dirty_lens_outlined:61393,disabled_by_default:57827,disabled_by_default_sharp:59616,disabled_by_default_rounded:63167,disabled_by_default_outlined:61394,disabled_visible:984303,disabled_visible_sharp:984059,disabled_visible_rounded:983816,disabled_visible_outlined:984553,disc_full:57828,disc_full_sharp:59617,disc_full_rounded:63168,disc_full_outlined:61395,discord:984304,discord_sharp:984060,discord_rounded:983817,discord_outlined:984554,discount:984765,discount_sharp:984752,discount_rounded:984778,discount_outlined:984739,display_settings:984305,display_settings_sharp:984061,display_settings_rounded:983818,display_settings_outlined:984555,diversity_1:985178,diversity_1_sharp:985144,diversity_1_rounded:985217,diversity_1_outlined:985247,diversity_2:985179,diversity_2_sharp:985145,diversity_2_rounded:985218,diversity_2_outlined:985248,diversity_3:985180,diversity_3_sharp:985146,diversity_3_rounded:985219,diversity_3_outlined:985249,dnd_forwardslash:57835,dnd_forwardslash_sharp:59623,dnd_forwardslash_rounded:63174,dnd_forwardslash_outlined:61401,dns:57829,dns_sharp:59618,dns_rounded:63169,dns_outlined:61396,do_disturb:57830,do_disturb_sharp:59622,do_disturb_rounded:63173,do_disturb_outlined:61400,do_disturb_alt:57831,do_disturb_alt_sharp:59619,do_disturb_alt_rounded:63170,do_disturb_alt_outlined:61397,do_disturb_off:57832,do_disturb_off_sharp:59620,do_disturb_off_rounded:63171,do_disturb_off_outlined:61398,do_disturb_on:57833,do_disturb_on_sharp:59621,do_disturb_on_rounded:63172,do_disturb_on_outlined:61399,do_not_disturb:57834,do_not_disturb_sharp:59627,do_not_disturb_rounded:63178,do_not_disturb_outlined:61405,do_not_disturb_alt:57835,do_not_disturb_alt_sharp:59623,do_not_disturb_alt_rounded:63174,do_not_disturb_alt_outlined:61401,do_not_disturb_off:57836,do_not_disturb_off_sharp:59624,do_not_disturb_off_rounded:63175,do_not_disturb_off_outlined:61402,do_not_disturb_on:57837,do_not_disturb_on_sharp:59625,do_not_disturb_on_rounded:63176,do_not_disturb_on_outlined:61403,do_not_disturb_on_total_silence:57838,do_not_disturb_on_total_silence_sharp:59626,do_not_disturb_on_total_silence_rounded:63177,do_not_disturb_on_total_silence_outlined:61404,do_not_step:57839,do_not_step_sharp:59628,do_not_step_rounded:63179,do_not_step_outlined:61406,do_not_touch:57840,do_not_touch_sharp:59629,do_not_touch_rounded:63180,do_not_touch_outlined:61407,dock:57841,dock_sharp:59630,dock_rounded:63181,dock_outlined:61408,document_scanner:57842,document_scanner_sharp:59631,document_scanner_rounded:63182,document_scanner_outlined:61409,domain:57843,domain_sharp:59633,domain_rounded:63184,domain_outlined:61411,domain_add:984306,domain_add_sharp:984062,domain_add_rounded:983819,domain_add_outlined:984556,domain_disabled:57844,domain_disabled_sharp:59632,domain_disabled_rounded:63183,domain_disabled_outlined:61410,domain_verification:57845,domain_verification_sharp:59634,domain_verification_rounded:63185,domain_verification_outlined:61412,done:57846,done_sharp:59637,done_rounded:63188,done_outlined:61415,done_all:57847,done_all_sharp:59635,done_all_rounded:63186,done_all_outlined:61413,done_outline:57848,done_outline_sharp:59636,done_outline_rounded:63187,done_outline_outlined:61414,donut_large:57849,donut_large_sharp:59638,donut_large_rounded:63189,donut_large_outlined:61416,donut_small:57850,donut_small_sharp:59639,donut_small_rounded:63190,donut_small_outlined:61417,door_back_door:57851,door_back_door_sharp:59640,door_back_door_rounded:63191,door_back_door_outlined:61418,door_front_door:57852,door_front_door_sharp:59641,door_front_door_rounded:63192,door_front_door_outlined:61419,door_sliding:57853,door_sliding_sharp:59642,door_sliding_rounded:63193,door_sliding_outlined:61420,doorbell:57854,doorbell_sharp:59643,doorbell_rounded:63194,doorbell_outlined:61421,double_arrow:57855,double_arrow_sharp:59644,double_arrow_rounded:63195,double_arrow_outlined:61422,downhill_skiing:57856,downhill_skiing_sharp:59645,downhill_skiing_rounded:63196,downhill_skiing_outlined:61423,download:57857,download_sharp:59648,download_rounded:63199,download_outlined:61426,download_done:57858,download_done_sharp:59646,download_done_rounded:63197,download_done_outlined:61424,download_for_offline:57859,download_for_offline_sharp:59647,download_for_offline_rounded:63198,download_for_offline_outlined:61425,downloading:57860,downloading_sharp:59649,downloading_rounded:63200,downloading_outlined:61427,drafts:57861,drafts_sharp:59650,drafts_rounded:63201,drafts_outlined:61428,drag_handle:57862,drag_handle_sharp:59651,drag_handle_rounded:63202,drag_handle_outlined:61429,drag_indicator:57863,drag_indicator_sharp:59652,drag_indicator_rounded:63203,drag_indicator_outlined:61430,draw:984307,draw_sharp:984063,draw_rounded:983820,draw_outlined:984557,drive_eta:57864,drive_eta_sharp:59653,drive_eta_rounded:63204,drive_eta_outlined:61431,drive_file_move:57865,drive_file_move_sharp:59654,drive_file_move_rounded:63205,drive_file_move_outlined:61432,drive_file_move_outline:57866,drive_file_move_rtl:984308,drive_file_move_rtl_sharp:984064,drive_file_move_rtl_rounded:983821,drive_file_move_rtl_outlined:984558,drive_file_rename_outline:57867,drive_file_rename_outline_sharp:59655,drive_file_rename_outline_rounded:63206,drive_file_rename_outline_outlined:61433,drive_folder_upload:57868,drive_folder_upload_sharp:59656,drive_folder_upload_rounded:63207,drive_folder_upload_outlined:61434,dry:57869,dry_sharp:59658,dry_rounded:63209,dry_outlined:61436,dry_cleaning:57870,dry_cleaning_sharp:59657,dry_cleaning_rounded:63208,dry_cleaning_outlined:61435,duo:57871,duo_sharp:59659,duo_rounded:63210,duo_outlined:61437,dvr:57872|R,dvr_sharp:59660|R,dvr_rounded:63211|R,dvr_outlined:61438|R,dynamic_feed:57873,dynamic_feed_sharp:59661,dynamic_feed_rounded:63212,dynamic_feed_outlined:61439,dynamic_form:57874,dynamic_form_sharp:59662,dynamic_form_rounded:63213,dynamic_form_outlined:61440,e_mobiledata:57875,e_mobiledata_sharp:59663,e_mobiledata_rounded:63214,e_mobiledata_outlined:61441,earbuds:57876,earbuds_sharp:59665,earbuds_rounded:63216,earbuds_outlined:61443,earbuds_battery:57877,earbuds_battery_sharp:59664,earbuds_battery_rounded:63215,earbuds_battery_outlined:61442,east:57878,east_sharp:59666,east_rounded:63217,east_outlined:61444,eco:57879,eco_sharp:59667,eco_rounded:63218,eco_outlined:61445,edgesensor_high:57880,edgesensor_high_sharp:59668,edgesensor_high_rounded:63219,edgesensor_high_outlined:61446,edgesensor_low:57881,edgesensor_low_sharp:59669,edgesensor_low_rounded:63220,edgesensor_low_outlined:61447,edit:57882,edit_sharp:59676,edit_rounded:63227,edit_outlined:61453,edit_attributes:57883,edit_attributes_sharp:59670,edit_attributes_rounded:63221,edit_attributes_outlined:61448,edit_calendar:984309,edit_calendar_sharp:984065,edit_calendar_rounded:983822,edit_calendar_outlined:984559,edit_document:985181,edit_location:57884,edit_location_sharp:59672,edit_location_rounded:63223,edit_location_outlined:61450,edit_location_alt:57885,edit_location_alt_sharp:59671,edit_location_alt_rounded:63222,edit_location_alt_outlined:61449,edit_note:984310,edit_note_sharp:984066,edit_note_rounded:983823,edit_note_outlined:984560,edit_notifications:57886,edit_notifications_sharp:59673,edit_notifications_rounded:63224,edit_notifications_outlined:61451,edit_off:57887,edit_off_sharp:59674,edit_off_rounded:63225,edit_off_outlined:61452,edit_road:57888,edit_road_sharp:59675,edit_road_rounded:63226,edit_road_outlined:61454,edit_square:985182,egg:984312,egg_sharp:984068,egg_rounded:983825,egg_outlined:984562,egg_alt:984311,egg_alt_sharp:984067,egg_alt_rounded:983824,egg_alt_outlined:984561,eject:57889,eject_sharp:59677,eject_rounded:63228,eject_outlined:61455,elderly:57890,elderly_sharp:59678,elderly_rounded:63229,elderly_outlined:61456,elderly_woman:984313,elderly_woman_sharp:984069,elderly_woman_rounded:983826,elderly_woman_outlined:984563,electric_bike:57891,electric_bike_sharp:59679,electric_bike_rounded:63230,electric_bike_outlined:61457,electric_bolt:984988,electric_bolt_sharp:984900,electric_bolt_rounded:985076,electric_bolt_outlined:984812,electric_car:57892,electric_car_sharp:59680,electric_car_rounded:63231,electric_car_outlined:61458,electric_meter:984989,electric_meter_sharp:984901,electric_meter_rounded:985077,electric_meter_outlined:984813,electric_moped:57893,electric_moped_sharp:59681,electric_moped_rounded:63232,electric_moped_outlined:61459,electric_rickshaw:57894,electric_rickshaw_sharp:59682,electric_rickshaw_rounded:63233,electric_rickshaw_outlined:61460,electric_scooter:57895,electric_scooter_sharp:59683,electric_scooter_rounded:63234,electric_scooter_outlined:61461,electrical_services:57896,electrical_services_sharp:59684,electrical_services_rounded:63235,electrical_services_outlined:61462,elevator:57897,elevator_sharp:59685,elevator_rounded:63236,elevator_outlined:61463,email:57898,email_sharp:59686,email_rounded:63237,email_outlined:61464,emergency:984314,emergency_sharp:984070,emergency_rounded:983827,emergency_outlined:984564,emergency_recording:984990,emergency_recording_sharp:984902,emergency_recording_rounded:985078,emergency_recording_outlined:984814,emergency_share:984991,emergency_share_sharp:984903,emergency_share_rounded:985079,emergency_share_outlined:984815,emoji_emotions:57899,emoji_emotions_sharp:59687,emoji_emotions_rounded:63238,emoji_emotions_outlined:61465,emoji_events:57900,emoji_events_sharp:59688,emoji_events_rounded:63239,emoji_events_outlined:61466,emoji_flags:57901,emoji_flags_sharp:59689,emoji_flags_rounded:63240,emoji_flags_outlined:61467,emoji_food_beverage:57902,emoji_food_beverage_sharp:59690,emoji_food_beverage_rounded:63241,emoji_food_beverage_outlined:61468,emoji_nature:57903,emoji_nature_sharp:59691,emoji_nature_rounded:63242,emoji_nature_outlined:61469,emoji_objects:57904,emoji_objects_sharp:59692,emoji_objects_rounded:63243,emoji_objects_outlined:61470,emoji_people:57905,emoji_people_sharp:59693,emoji_people_rounded:63244,emoji_people_outlined:61471,emoji_symbols:57906,emoji_symbols_sharp:59694,emoji_symbols_rounded:63245,emoji_symbols_outlined:61472,emoji_transportation:57907,emoji_transportation_sharp:59695,emoji_transportation_rounded:63246,emoji_transportation_outlined:61473,energy_savings_leaf:984992,energy_savings_leaf_sharp:984904,energy_savings_leaf_rounded:985080,energy_savings_leaf_outlined:984816,engineering:57908,engineering_sharp:59696,engineering_rounded:63247,engineering_outlined:61474,enhance_photo_translate:57649,enhance_photo_translate_sharp:59437,enhance_photo_translate_rounded:62988,enhance_photo_translate_outlined:61215,enhanced_encryption:57909,enhanced_encryption_sharp:59697,enhanced_encryption_rounded:63248,enhanced_encryption_outlined:61475,equalizer:57910,equalizer_sharp:59698,equalizer_rounded:63249,equalizer_outlined:61476,error:57911,error_sharp:59700,error_rounded:63251,error_outlined:61478,error_outline:57912,error_outline_sharp:59699,error_outline_rounded:63250,error_outline_outlined:61477,escalator:57913,escalator_sharp:59701,escalator_rounded:63252,escalator_outlined:61479,escalator_warning:57914,escalator_warning_sharp:59702,escalator_warning_rounded:63253,escalator_warning_outlined:61480,euro:57915,euro_sharp:59703,euro_rounded:63254,euro_outlined:61481,euro_symbol:57916,euro_symbol_sharp:59704,euro_symbol_rounded:63255,euro_symbol_outlined:61482,ev_station:57917,ev_station_sharp:59705,ev_station_rounded:63256,ev_station_outlined:61483,event:57918,event_sharp:59710,event_rounded:63260,event_outlined:61487,event_available:57919,event_available_sharp:59706,event_available_rounded:63257,event_available_outlined:61484,event_busy:57920,event_busy_sharp:59707,event_busy_rounded:63258,event_busy_outlined:61485,event_note:57921|R,event_note_sharp:59708|R,event_note_rounded:63259|R,event_note_outlined:61486|R,event_repeat:984315,event_repeat_sharp:984071,event_repeat_rounded:983828,event_repeat_outlined:984565,event_seat:57922,event_seat_sharp:59709,event_seat_rounded:63261,event_seat_outlined:61488,exit_to_app:57923,exit_to_app_sharp:59711,exit_to_app_rounded:63262,exit_to_app_outlined:61489,expand:57924,expand_sharp:59714,expand_rounded:63265,expand_outlined:61492,expand_circle_down:984316,expand_circle_down_sharp:984072,expand_circle_down_rounded:983829,expand_circle_down_outlined:984566,expand_less:57925,expand_less_sharp:59712,expand_less_rounded:63263,expand_less_outlined:61490,expand_more:57926,expand_more_sharp:59713,expand_more_rounded:63264,expand_more_outlined:61491,explicit:57927,explicit_sharp:59715,explicit_rounded:63266,explicit_outlined:61493,explore:57928,explore_sharp:59717,explore_rounded:63268,explore_outlined:61495,explore_off:57929,explore_off_sharp:59716,explore_off_rounded:63267,explore_off_outlined:61494,exposure:57930,exposure_sharp:59722,exposure_rounded:63273,exposure_outlined:61498,exposure_minus_1:57931,exposure_minus_1_sharp:59718,exposure_minus_1_rounded:63269,exposure_minus_1_outlined:61496,exposure_minus_2:57932,exposure_minus_2_sharp:59719,exposure_minus_2_rounded:63270,exposure_minus_2_outlined:61497,exposure_neg_1:57931,exposure_neg_1_sharp:59718,exposure_neg_1_rounded:63269,exposure_neg_1_outlined:61496,exposure_neg_2:57932,exposure_neg_2_sharp:59719,exposure_neg_2_rounded:63270,exposure_neg_2_outlined:61497,exposure_plus_1:57933,exposure_plus_1_sharp:59720,exposure_plus_1_rounded:63271,exposure_plus_1_outlined:61499,exposure_plus_2:57934,exposure_plus_2_sharp:59721,exposure_plus_2_rounded:63272,exposure_plus_2_outlined:61500,exposure_zero:57935,exposure_zero_sharp:59723,exposure_zero_rounded:63274,exposure_zero_outlined:61501,extension:57936,extension_sharp:59725,extension_rounded:63276,extension_outlined:61503,extension_off:57937,extension_off_sharp:59724,extension_off_rounded:63275,extension_off_outlined:61502,face:57938,face_sharp:59728,face_rounded:63279,face_outlined:61504,face_2:985183,face_2_sharp:985147,face_2_rounded:985220,face_2_outlined:985250,face_3:985184,face_3_sharp:985148,face_3_rounded:985221,face_3_outlined:985251,face_4:985185,face_4_sharp:985149,face_4_rounded:985222,face_4_outlined:985252,face_5:985186,face_5_sharp:985150,face_5_rounded:985223,face_5_outlined:985253,face_6:985187,face_6_sharp:985151,face_6_rounded:985224,face_6_outlined:985254,face_retouching_natural:57939,face_retouching_natural_sharp:59726,face_retouching_natural_rounded:63277,face_retouching_natural_outlined:61505,face_retouching_off:57940,face_retouching_off_sharp:59727,face_retouching_off_rounded:63278,face_retouching_off_outlined:61506,face_unlock_sharp:59729,face_unlock_rounded:63280,face_unlock_outlined:61507,facebook:57941,facebook_sharp:59730,facebook_rounded:63281,facebook_outlined:61508,fact_check:57942,fact_check_sharp:59731,fact_check_rounded:63282,fact_check_outlined:61509,factory:984317,factory_sharp:984073,factory_rounded:983830,factory_outlined:984567,family_restroom:57943,family_restroom_sharp:59732,family_restroom_rounded:63283,family_restroom_outlined:61510,fast_forward:57944,fast_forward_sharp:59733,fast_forward_rounded:63284,fast_forward_outlined:61511,fast_rewind:57945,fast_rewind_sharp:59734,fast_rewind_rounded:63285,fast_rewind_outlined:61512,fastfood:57946,fastfood_sharp:59735,fastfood_rounded:63286,fastfood_outlined:61513,favorite:57947,favorite_sharp:59737,favorite_rounded:63288,favorite_outlined:61515,favorite_border:57948,favorite_border_sharp:59736,favorite_border_rounded:63287,favorite_border_outlined:61514,favorite_outline:57948,favorite_outline_sharp:59736,favorite_outline_rounded:63287,favorite_outline_outlined:61514,fax:984318,fax_sharp:984074,fax_rounded:983831,fax_outlined:984568,featured_play_list:57949|R,featured_play_list_sharp:59738|R,featured_play_list_rounded:63289|R,featured_play_list_outlined:61516|R,featured_video:57950|R,featured_video_sharp:59739|R,featured_video_rounded:63290|R,featured_video_outlined:61517|R,feed:57951,feed_sharp:59740,feed_rounded:63291,feed_outlined:61518,feedback:57952,feedback_sharp:59741,feedback_rounded:63292,feedback_outlined:61519,female:57953,female_sharp:59742,female_rounded:63293,female_outlined:61520,fence:57954,fence_sharp:59743,fence_rounded:63294,fence_outlined:61521,festival:57955,festival_sharp:59744,festival_rounded:63295,festival_outlined:61522,fiber_dvr:57956,fiber_dvr_sharp:59745,fiber_dvr_rounded:63296,fiber_dvr_outlined:61523,fiber_manual_record:57957,fiber_manual_record_sharp:59746,fiber_manual_record_rounded:63297,fiber_manual_record_outlined:61524,fiber_new:57958,fiber_new_sharp:59747,fiber_new_rounded:63298,fiber_new_outlined:61525,fiber_pin:57959,fiber_pin_sharp:59748,fiber_pin_rounded:63299,fiber_pin_outlined:61526,fiber_smart_record:57960,fiber_smart_record_sharp:59749,fiber_smart_record_rounded:63300,fiber_smart_record_outlined:61527,file_copy:57961,file_copy_sharp:59750,file_copy_rounded:63301,file_copy_outlined:61528,file_download:57962,file_download_sharp:59753,file_download_rounded:63304,file_download_outlined:61531,file_download_done:57963,file_download_done_sharp:59751,file_download_done_rounded:63302,file_download_done_outlined:61529,file_download_off:57964,file_download_off_sharp:59752,file_download_off_rounded:63303,file_download_off_outlined:61530,file_open:984319,file_open_sharp:984075,file_open_rounded:983832,file_open_outlined:984569,file_present:57965,file_present_sharp:59754,file_present_rounded:63305,file_present_outlined:61532,file_upload:57966,file_upload_sharp:59755,file_upload_rounded:63306,file_upload_outlined:61533,file_upload_off:985188,filter:57967,filter_sharp:59774,filter_rounded:63325,filter_outlined:61552,filter_1:57968,filter_1_sharp:59756,filter_1_rounded:63307,filter_1_outlined:61534,filter_2:57969,filter_2_sharp:59757,filter_2_rounded:63308,filter_2_outlined:61535,filter_3:57970,filter_3_sharp:59758,filter_3_rounded:63309,filter_3_outlined:61536,filter_4:57971,filter_4_sharp:59759,filter_4_rounded:63310,filter_4_outlined:61537,filter_5:57972,filter_5_sharp:59760,filter_5_rounded:63311,filter_5_outlined:61538,filter_6:57973,filter_6_sharp:59761,filter_6_rounded:63312,filter_6_outlined:61539,filter_7:57974,filter_7_sharp:59762,filter_7_rounded:63313,filter_7_outlined:61540,filter_8:57975,filter_8_sharp:59763,filter_8_rounded:63314,filter_8_outlined:61541,filter_9:57976,filter_9_sharp:59765,filter_9_rounded:63316,filter_9_outlined:61542,filter_9_plus:57977,filter_9_plus_sharp:59764,filter_9_plus_rounded:63315,filter_9_plus_outlined:61543,filter_alt:57978,filter_alt_sharp:59766,filter_alt_rounded:63317,filter_alt_outlined:61544,filter_alt_off:984320,filter_alt_off_sharp:984076,filter_alt_off_rounded:983833,filter_alt_off_outlined:984570,filter_b_and_w:57979,filter_b_and_w_sharp:59767,filter_b_and_w_rounded:63318,filter_b_and_w_outlined:61545,filter_center_focus:57980,filter_center_focus_sharp:59768,filter_center_focus_rounded:63319,filter_center_focus_outlined:61546,filter_drama:57981,filter_drama_sharp:59769,filter_drama_rounded:63320,filter_drama_outlined:61547,filter_frames:57982,filter_frames_sharp:59770,filter_frames_rounded:63321,filter_frames_outlined:61548,filter_hdr:57983,filter_hdr_sharp:59771,filter_hdr_rounded:63322,filter_hdr_outlined:61549,filter_list:57984,filter_list_sharp:59772,filter_list_rounded:63323,filter_list_outlined:61550,filter_list_alt:57985,filter_list_off:984321,filter_list_off_sharp:984077,filter_list_off_rounded:983834,filter_list_off_outlined:984571,filter_none:57986,filter_none_sharp:59773,filter_none_rounded:63324,filter_none_outlined:61551,filter_tilt_shift:57987,filter_tilt_shift_sharp:59775,filter_tilt_shift_rounded:63326,filter_tilt_shift_outlined:61553,filter_vintage:57988,filter_vintage_sharp:59776,filter_vintage_rounded:63327,filter_vintage_outlined:61554,find_in_page:57989,find_in_page_sharp:59777,find_in_page_rounded:63328,find_in_page_outlined:61555,find_replace:57990,find_replace_sharp:59778,find_replace_rounded:63329,find_replace_outlined:61556,fingerprint:57991,fingerprint_sharp:59779,fingerprint_rounded:63330,fingerprint_outlined:61557,fire_extinguisher:57992,fire_extinguisher_sharp:59780,fire_extinguisher_rounded:63331,fire_extinguisher_outlined:61558,fire_hydrant:57993,fire_hydrant_alt:984993,fire_hydrant_alt_sharp:984905,fire_hydrant_alt_rounded:985081,fire_hydrant_alt_outlined:984817,fire_truck:984994,fire_truck_sharp:984906,fire_truck_rounded:985082,fire_truck_outlined:984818,fireplace:57994,fireplace_sharp:59781,fireplace_rounded:63332,fireplace_outlined:61559,first_page:57995|R,first_page_sharp:59782|R,first_page_rounded:63333|R,first_page_outlined:61560|R,fit_screen:57996,fit_screen_sharp:59783,fit_screen_rounded:63334,fit_screen_outlined:61561,fitbit:984322,fitbit_sharp:984078,fitbit_rounded:983835,fitbit_outlined:984572,fitness_center:57997,fitness_center_sharp:59784,fitness_center_rounded:63335,fitness_center_outlined:61562,flag:57998,flag_sharp:59785,flag_rounded:63336,flag_outlined:61563,flag_circle:984323,flag_circle_sharp:984079,flag_circle_rounded:983836,flag_circle_outlined:984573,flaky:57999,flaky_sharp:59786,flaky_rounded:63337,flaky_outlined:61564,flare:58000,flare_sharp:59787,flare_rounded:63338,flare_outlined:61565,flash_auto:58001,flash_auto_sharp:59788,flash_auto_rounded:63339,flash_auto_outlined:61566,flash_off:58002,flash_off_sharp:59789,flash_off_rounded:63340,flash_off_outlined:61567,flash_on:58003,flash_on_sharp:59790,flash_on_rounded:63341,flash_on_outlined:61568,flashlight_off:58004,flashlight_off_sharp:59791,flashlight_off_rounded:63342,flashlight_off_outlined:61569,flashlight_on:58005,flashlight_on_sharp:59792,flashlight_on_rounded:63343,flashlight_on_outlined:61570,flatware:58006,flatware_sharp:59793,flatware_rounded:63344,flatware_outlined:61571,flight:58007,flight_sharp:59795,flight_rounded:63346,flight_outlined:61573,flight_class:984324,flight_class_sharp:984080,flight_class_rounded:983837,flight_class_outlined:984574,flight_land:58008|R,flight_land_sharp:59794|R,flight_land_rounded:63345|R,flight_land_outlined:61572|R,flight_takeoff:58009|R,flight_takeoff_sharp:59796|R,flight_takeoff_rounded:63347|R,flight_takeoff_outlined:61574|R,flip:58010,flip_sharp:59799,flip_rounded:63350,flip_outlined:61577,flip_camera_android:58011,flip_camera_android_sharp:59797,flip_camera_android_rounded:63348,flip_camera_android_outlined:61575,flip_camera_ios:58012,flip_camera_ios_sharp:59798,flip_camera_ios_rounded:63349,flip_camera_ios_outlined:61576,flip_to_back:58013,flip_to_back_sharp:59800,flip_to_back_rounded:63351,flip_to_back_outlined:61578,flip_to_front:58014,flip_to_front_sharp:59801,flip_to_front_rounded:63352,flip_to_front_outlined:61579,flood:984995,flood_sharp:984907,flood_rounded:985083,flood_outlined:984819,flourescent:985189,flourescent_sharp:985152,flourescent_rounded:985225,flourescent_outlined:985255,fluorescent:985189,fluorescent_sharp:985152,fluorescent_rounded:985225,fluorescent_outlined:985255,flutter_dash:58016,flutter_dash_sharp:59803,flutter_dash_rounded:63354,flutter_dash_outlined:61581,fmd_bad:58017,fmd_bad_sharp:59804,fmd_bad_rounded:63355,fmd_bad_outlined:61582,fmd_good:58018,fmd_good_sharp:59805,fmd_good_rounded:63356,fmd_good_outlined:61583,foggy:984325,folder:58019,folder_sharp:59808,folder_rounded:63358,folder_outlined:61585,folder_copy:984326,folder_copy_sharp:984081,folder_copy_rounded:983838,folder_copy_outlined:984575,folder_delete:984327,folder_delete_sharp:984082,folder_delete_rounded:983839,folder_delete_outlined:984576,folder_off:984328,folder_off_sharp:984083,folder_off_rounded:983840,folder_off_outlined:984577,folder_open:58020,folder_open_sharp:59806,folder_open_rounded:63357,folder_open_outlined:61584,folder_shared:58021,folder_shared_sharp:59807,folder_shared_rounded:63359,folder_shared_outlined:61586,folder_special:58022,folder_special_sharp:59809,folder_special_rounded:63360,folder_special_outlined:61587,folder_zip:984329,folder_zip_sharp:984084,folder_zip_rounded:983841,folder_zip_outlined:984578,follow_the_signs:58023,follow_the_signs_sharp:59810,follow_the_signs_rounded:63361,follow_the_signs_outlined:61588,font_download:58024,font_download_sharp:59812,font_download_rounded:63363,font_download_outlined:61590,font_download_off:58025,font_download_off_sharp:59811,font_download_off_rounded:63362,font_download_off_outlined:61589,food_bank:58026,food_bank_sharp:59813,food_bank_rounded:63364,food_bank_outlined:61591,forest:984330,forest_sharp:984085,forest_rounded:983842,forest_outlined:984579,fork_left:984331,fork_left_sharp:984086,fork_left_rounded:983843,fork_left_outlined:984580,fork_right:984332,fork_right_sharp:984087,fork_right_rounded:983844,fork_right_outlined:984581,forklift:985190,format_align_center:58027,format_align_center_sharp:59814,format_align_center_rounded:63365,format_align_center_outlined:61592,format_align_justify:58028,format_align_justify_sharp:59815,format_align_justify_rounded:63366,format_align_justify_outlined:61593,format_align_left:58029,format_align_left_sharp:59816,format_align_left_rounded:63367,format_align_left_outlined:61594,format_align_right:58030,format_align_right_sharp:59817,format_align_right_rounded:63368,format_align_right_outlined:61595,format_bold:58031,format_bold_sharp:59818,format_bold_rounded:63369,format_bold_outlined:61596,format_clear:58032,format_clear_sharp:59819,format_clear_rounded:63370,format_clear_outlined:61597,format_color_fill:58033,format_color_fill_sharp:59820,format_color_fill_rounded:63371,format_color_fill_outlined:61598,format_color_reset:58034,format_color_reset_sharp:59821,format_color_reset_rounded:63372,format_color_reset_outlined:61599,format_color_text:58035,format_color_text_sharp:59822,format_color_text_rounded:63373,format_color_text_outlined:61600,format_indent_decrease:58036|R,format_indent_decrease_sharp:59823|R,format_indent_decrease_rounded:63374|R,format_indent_decrease_outlined:61601|R,format_indent_increase:58037|R,format_indent_increase_sharp:59824|R,format_indent_increase_rounded:63375|R,format_indent_increase_outlined:61602|R,format_italic:58038,format_italic_sharp:59825,format_italic_rounded:63376,format_italic_outlined:61603,format_line_spacing:58039,format_line_spacing_sharp:59826,format_line_spacing_rounded:63377,format_line_spacing_outlined:61604,format_list_bulleted:58040|R,format_list_bulleted_sharp:59827|R,format_list_bulleted_rounded:63378|R,format_list_bulleted_outlined:61605|R,format_list_bulleted_add:985191,format_list_numbered:58041,format_list_numbered_sharp:59829,format_list_numbered_rounded:63379,format_list_numbered_outlined:61606,format_list_numbered_rtl:58042,format_list_numbered_rtl_sharp:59828,format_list_numbered_rtl_rounded:63380,format_list_numbered_rtl_outlined:61607,format_overline:984333,format_overline_sharp:984088,format_overline_rounded:983845,format_overline_outlined:984582,format_paint:58043,format_paint_sharp:59830,format_paint_rounded:63381,format_paint_outlined:61608,format_quote:58044,format_quote_sharp:59831,format_quote_rounded:63382,format_quote_outlined:61609,format_shapes:58045,format_shapes_sharp:59832,format_shapes_rounded:63383,format_shapes_outlined:61610,format_size:58046,format_size_sharp:59833,format_size_rounded:63384,format_size_outlined:61611,format_strikethrough:58047,format_strikethrough_sharp:59834,format_strikethrough_rounded:63385,format_strikethrough_outlined:61612,format_textdirection_l_to_r:58048,format_textdirection_l_to_r_sharp:59835,format_textdirection_l_to_r_rounded:63386,format_textdirection_l_to_r_outlined:61613,format_textdirection_r_to_l:58049,format_textdirection_r_to_l_sharp:59836,format_textdirection_r_to_l_rounded:63387,format_textdirection_r_to_l_outlined:61614,format_underline:58050,format_underline_sharp:59837,format_underline_rounded:63388,format_underline_outlined:61615,format_underlined:58050,format_underlined_sharp:59837,format_underlined_rounded:63388,format_underlined_outlined:61615,fort:984334,fort_sharp:984089,fort_rounded:983846,fort_outlined:984583,forum:58051,forum_sharp:59838,forum_rounded:63389,forum_outlined:61616,forward:58052|R,forward_sharp:59842|R,forward_rounded:63393|R,forward_outlined:61620|R,forward_10:58053,forward_10_sharp:59839,forward_10_rounded:63390,forward_10_outlined:61617,forward_30:58054,forward_30_sharp:59840,forward_30_rounded:63391,forward_30_outlined:61618,forward_5:58055,forward_5_sharp:59841,forward_5_rounded:63392,forward_5_outlined:61619,forward_to_inbox:58056,forward_to_inbox_sharp:59843,forward_to_inbox_rounded:63394,forward_to_inbox_outlined:61621,foundation:58057,foundation_sharp:59844,foundation_rounded:63395,foundation_outlined:61622,free_breakfast:58058,free_breakfast_sharp:59845,free_breakfast_rounded:63396,free_breakfast_outlined:61623,free_cancellation:984335,free_cancellation_sharp:984090,free_cancellation_rounded:983847,free_cancellation_outlined:984584,front_hand:984336,front_hand_sharp:984091,front_hand_rounded:983848,front_hand_outlined:984585,front_loader:985192,fullscreen:58059,fullscreen_sharp:59847,fullscreen_rounded:63398,fullscreen_outlined:61625,fullscreen_exit:58060,fullscreen_exit_sharp:59846,fullscreen_exit_rounded:63397,fullscreen_exit_outlined:61624,functions:58061|R,functions_sharp:59848|R,functions_rounded:63399|R,functions_outlined:61626|R,g_mobiledata:58062,g_mobiledata_sharp:59849,g_mobiledata_rounded:63400,g_mobiledata_outlined:61627,g_translate:58063,g_translate_sharp:59850,g_translate_rounded:63401,g_translate_outlined:61628,gamepad:58064,gamepad_sharp:59851,gamepad_rounded:63402,gamepad_outlined:61629,games:58065,games_sharp:59852,games_rounded:63403,games_outlined:61630,garage:58066,garage_sharp:59853,garage_rounded:63404,garage_outlined:61631,gas_meter:984996,gas_meter_sharp:984908,gas_meter_rounded:985084,gas_meter_outlined:984820,gavel:58067,gavel_sharp:59854,gavel_rounded:63405,gavel_outlined:61632,generating_tokens:984337,generating_tokens_sharp:984092,generating_tokens_rounded:983849,generating_tokens_outlined:984586,gesture:58068,gesture_sharp:59855,gesture_rounded:63406,gesture_outlined:61633,get_app:58069,get_app_sharp:59856,get_app_rounded:63407,get_app_outlined:61634,gif:58070,gif_sharp:59857,gif_rounded:63408,gif_outlined:61635,gif_box:984338,gif_box_sharp:984093,gif_box_rounded:983850,gif_box_outlined:984587,girl:984339,girl_sharp:984094,girl_rounded:983851,girl_outlined:984588,gite:58071,gite_sharp:59858,gite_rounded:63409,gite_outlined:61636,golf_course:58072,golf_course_sharp:59859,golf_course_rounded:63410,golf_course_outlined:61637,gpp_bad:58073,gpp_bad_sharp:59860,gpp_bad_rounded:63411,gpp_bad_outlined:61638,gpp_good:58074,gpp_good_sharp:59861,gpp_good_rounded:63412,gpp_good_outlined:61639,gpp_maybe:58075,gpp_maybe_sharp:59862,gpp_maybe_rounded:63413,gpp_maybe_outlined:61640,gps_fixed:58076,gps_fixed_sharp:59863,gps_fixed_rounded:63414,gps_fixed_outlined:61641,gps_not_fixed:58077,gps_not_fixed_sharp:59864,gps_not_fixed_rounded:63415,gps_not_fixed_outlined:61642,gps_off:58078,gps_off_sharp:59865,gps_off_rounded:63416,gps_off_outlined:61643,grade:58079,grade_sharp:59866,grade_rounded:63417,grade_outlined:61644,gradient:58080,gradient_sharp:59867,gradient_rounded:63418,gradient_outlined:61645,grading:58081,grading_sharp:59868,grading_rounded:63419,grading_outlined:61646,grain:58082,grain_sharp:59869,grain_rounded:63420,grain_outlined:61647,graphic_eq:58083,graphic_eq_sharp:59870,graphic_eq_rounded:63421,graphic_eq_outlined:61648,grass:58084,grass_sharp:59871,grass_rounded:63422,grass_outlined:61649,grid_3x3:58085,grid_3x3_sharp:59872,grid_3x3_rounded:63423,grid_3x3_outlined:61650,grid_4x4:58086,grid_4x4_sharp:59873,grid_4x4_rounded:63424,grid_4x4_outlined:61651,grid_goldenratio:58087,grid_goldenratio_sharp:59874,grid_goldenratio_rounded:63425,grid_goldenratio_outlined:61652,grid_off:58088,grid_off_sharp:59875,grid_off_rounded:63426,grid_off_outlined:61653,grid_on:58089,grid_on_sharp:59876,grid_on_rounded:63427,grid_on_outlined:61654,grid_view:58090,grid_view_sharp:59877,grid_view_rounded:63428,grid_view_outlined:61655,group:58091,group_sharp:59879,group_rounded:63430,group_outlined:61657,group_add:58092,group_add_sharp:59878,group_add_rounded:63429,group_add_outlined:61656,group_off:984340,group_off_sharp:984095,group_off_rounded:983852,group_off_outlined:984589,group_remove:984341,group_remove_sharp:984096,group_remove_rounded:983853,group_remove_outlined:984590,group_work:58093,group_work_sharp:59880,group_work_rounded:63431,group_work_outlined:61658,groups:58094,groups_sharp:59881,groups_rounded:63432,groups_outlined:61659,groups_2:985193,groups_2_sharp:985153,groups_2_rounded:985226,groups_2_outlined:985256,groups_3:985194,groups_3_sharp:985154,groups_3_rounded:985227,groups_3_outlined:985257,h_mobiledata:58095,h_mobiledata_sharp:59882,h_mobiledata_rounded:63433,h_mobiledata_outlined:61660,h_plus_mobiledata:58096,h_plus_mobiledata_sharp:59883,h_plus_mobiledata_rounded:63434,h_plus_mobiledata_outlined:61661,hail:58097,hail_sharp:59884,hail_rounded:63435,hail_outlined:61662,handshake:984766,handshake_sharp:984753,handshake_rounded:984779,handshake_outlined:984740,handyman:58098,handyman_sharp:59885,handyman_rounded:63436,handyman_outlined:61663,hardware:58099,hardware_sharp:59886,hardware_rounded:63437,hardware_outlined:61664,hd:58100,hd_sharp:59887,hd_rounded:63438,hd_outlined:61665,hdr_auto:58101,hdr_auto_sharp:59889,hdr_auto_rounded:63439,hdr_auto_outlined:61666,hdr_auto_select:58102,hdr_auto_select_sharp:59888,hdr_auto_select_rounded:63440,hdr_auto_select_outlined:61667,hdr_enhanced_select:58103,hdr_enhanced_select_sharp:59890,hdr_enhanced_select_rounded:63441,hdr_enhanced_select_outlined:61668,hdr_off:58104,hdr_off_sharp:59892,hdr_off_rounded:63442,hdr_off_outlined:61669,hdr_off_select:58105,hdr_off_select_sharp:59891,hdr_off_select_rounded:63443,hdr_off_select_outlined:61670,hdr_on:58106,hdr_on_sharp:59894,hdr_on_rounded:63444,hdr_on_outlined:61671,hdr_on_select:58107,hdr_on_select_sharp:59893,hdr_on_select_rounded:63445,hdr_on_select_outlined:61672,hdr_plus:58108,hdr_plus_sharp:59895,hdr_plus_rounded:63446,hdr_plus_outlined:61673,hdr_strong:58109,hdr_strong_sharp:59896,hdr_strong_rounded:63447,hdr_strong_outlined:61674,hdr_weak:58110,hdr_weak_sharp:59897,hdr_weak_rounded:63448,hdr_weak_outlined:61675,headphones:58111,headphones_sharp:59899,headphones_rounded:63450,headphones_outlined:61677,headphones_battery:58112,headphones_battery_sharp:59898,headphones_battery_rounded:63449,headphones_battery_outlined:61676,headset:58113,headset_sharp:59902,headset_rounded:63453,headset_outlined:61680,headset_mic:58114,headset_mic_sharp:59900,headset_mic_rounded:63451,headset_mic_outlined:61678,headset_off:58115,headset_off_sharp:59901,headset_off_rounded:63452,headset_off_outlined:61679,healing:58116,healing_sharp:59903,healing_rounded:63454,healing_outlined:61681,health_and_safety:58117,health_and_safety_sharp:59904,health_and_safety_rounded:63455,health_and_safety_outlined:61682,hearing:58118,hearing_sharp:59906,hearing_rounded:63457,hearing_outlined:61684,hearing_disabled:58119,hearing_disabled_sharp:59905,hearing_disabled_rounded:63456,hearing_disabled_outlined:61683,heart_broken:984342,heart_broken_sharp:984097,heart_broken_rounded:983854,heart_broken_outlined:984591,heat_pump:984997,heat_pump_sharp:984909,heat_pump_rounded:985085,heat_pump_outlined:984821,height:58120,height_sharp:59907,height_rounded:63458,height_outlined:61685,help:58121|R,help_sharp:59910|R,help_rounded:63461|R,help_outlined:61688|R,help_center:58122,help_center_sharp:59908,help_center_rounded:63459,help_center_outlined:61686,help_outline:58123|R,help_outline_sharp:59909|R,help_outline_rounded:63460|R,help_outline_outlined:61687|R,hevc:58124,hevc_sharp:59911,hevc_rounded:63462,hevc_outlined:61689,hexagon:984343,hexagon_sharp:984098,hexagon_rounded:983855,hexagon_outlined:984592,hide_image:58125,hide_image_sharp:59912,hide_image_rounded:63463,hide_image_outlined:61690,hide_source:58126,hide_source_sharp:59913,hide_source_rounded:63464,hide_source_outlined:61691,high_quality:58127,high_quality_sharp:59914,high_quality_rounded:63465,high_quality_outlined:61692,highlight:58128,highlight_sharp:59917,highlight_rounded:63468,highlight_outlined:61695,highlight_alt:58129,highlight_alt_sharp:59915,highlight_alt_rounded:63466,highlight_alt_outlined:61693,highlight_off:58130,highlight_off_sharp:59916,highlight_off_rounded:63467,highlight_off_outlined:61694,highlight_remove:58130,highlight_remove_sharp:59916,highlight_remove_rounded:63467,highlight_remove_outlined:61694,hiking:58131,hiking_sharp:59918,hiking_rounded:63469,hiking_outlined:61696,history:58132,history_sharp:59920,history_rounded:63471,history_outlined:61698,history_edu:58133,history_edu_sharp:59919,history_edu_rounded:63470,history_edu_outlined:61697,history_toggle_off:58134,history_toggle_off_sharp:59921,history_toggle_off_rounded:63472,history_toggle_off_outlined:61699,hive:984344,hive_sharp:984099,hive_rounded:983856,hive_outlined:984593,hls:984345,hls_sharp:984101,hls_rounded:983858,hls_outlined:984595,hls_off:984346,hls_off_sharp:984100,hls_off_rounded:983857,hls_off_outlined:984594,holiday_village:58135,holiday_village_sharp:59922,holiday_village_rounded:63473,holiday_village_outlined:61700,home:58136,home_sharp:59926,home_rounded:63477,home_outlined:61703,home_filled:58137,home_max:58138,home_max_sharp:59923,home_max_rounded:63474,home_max_outlined:61701,home_mini:58139,home_mini_sharp:59924,home_mini_rounded:63475,home_mini_outlined:61702,home_repair_service:58140,home_repair_service_sharp:59925,home_repair_service_rounded:63476,home_repair_service_outlined:61704,home_work:58141,home_work_sharp:59927,home_work_rounded:63478,home_work_outlined:61705,horizontal_distribute:58142,horizontal_distribute_sharp:59928,horizontal_distribute_rounded:63479,horizontal_distribute_outlined:61706,horizontal_rule:58143,horizontal_rule_sharp:59929,horizontal_rule_rounded:63480,horizontal_rule_outlined:61707,horizontal_split:58144,horizontal_split_sharp:59930,horizontal_split_rounded:63481,horizontal_split_outlined:61708,hot_tub:58145,hot_tub_sharp:59931,hot_tub_rounded:63482,hot_tub_outlined:61709,hotel:58146,hotel_sharp:59932,hotel_rounded:63483,hotel_outlined:61710,hotel_class:984347,hotel_class_sharp:984102,hotel_class_rounded:983859,hotel_class_outlined:984596,hourglass_bottom:58147,hourglass_bottom_sharp:59933,hourglass_bottom_rounded:63484,hourglass_bottom_outlined:61711,hourglass_disabled:58148,hourglass_disabled_sharp:59934,hourglass_disabled_rounded:63485,hourglass_disabled_outlined:61712,hourglass_empty:58149,hourglass_empty_sharp:59935,hourglass_empty_rounded:63486,hourglass_empty_outlined:61713,hourglass_full:58150,hourglass_full_sharp:59936,hourglass_full_rounded:63487,hourglass_full_outlined:61714,hourglass_top:58151,hourglass_top_sharp:59937,hourglass_top_rounded:63488,hourglass_top_outlined:61715,house:58152,house_sharp:59938,house_rounded:63489,house_outlined:61716,house_siding:58153,house_siding_sharp:59939,house_siding_rounded:63490,house_siding_outlined:61717,houseboat:58154,houseboat_sharp:59940,houseboat_rounded:63491,houseboat_outlined:61718,how_to_reg:58155,how_to_reg_sharp:59941,how_to_reg_rounded:63492,how_to_reg_outlined:61719,how_to_vote:58156,how_to_vote_sharp:59942,how_to_vote_rounded:63493,how_to_vote_outlined:61720,html:984348,html_sharp:984103,html_rounded:983860,html_outlined:984597,http:58157,http_sharp:59943,http_rounded:63494,http_outlined:61721,https:58158,https_sharp:59944,https_rounded:63495,https_outlined:61722,hub:984349,hub_sharp:984104,hub_rounded:983861,hub_outlined:984598,hvac:58159,hvac_sharp:59945,hvac_rounded:63496,hvac_outlined:61723,ice_skating:58160,ice_skating_sharp:59946,ice_skating_rounded:63497,ice_skating_outlined:61724,icecream:58161,icecream_sharp:59947,icecream_rounded:63498,icecream_outlined:61725,image:58162,image_sharp:59951,image_rounded:63501,image_outlined:61728,image_aspect_ratio:58163,image_aspect_ratio_sharp:59948,image_aspect_ratio_rounded:63499,image_aspect_ratio_outlined:61726,image_not_supported:58164,image_not_supported_sharp:59949,image_not_supported_rounded:63500,image_not_supported_outlined:61727,image_search:58165,image_search_sharp:59950,image_search_rounded:63502,image_search_outlined:61729,imagesearch_roller:58166,imagesearch_roller_sharp:59952,imagesearch_roller_rounded:63503,imagesearch_roller_outlined:61730,import_contacts:58167,import_contacts_sharp:59953,import_contacts_rounded:63504,import_contacts_outlined:61731,import_export:58168,import_export_sharp:59954,import_export_rounded:63505,import_export_outlined:61732,important_devices:58169,important_devices_sharp:59955,important_devices_rounded:63506,important_devices_outlined:61733,inbox:58170,inbox_sharp:59956,inbox_rounded:63507,inbox_outlined:61734,incomplete_circle:984350,incomplete_circle_sharp:984105,incomplete_circle_rounded:983862,incomplete_circle_outlined:984599,indeterminate_check_box:58171,indeterminate_check_box_sharp:59957,indeterminate_check_box_rounded:63508,indeterminate_check_box_outlined:61735,info:58172,info_sharp:59959,info_rounded:63510,info_outlined:61736,info_outline:58173,info_outline_sharp:59958,info_outline_rounded:63509,input:58174|R,input_sharp:59960|R,input_rounded:63511|R,input_outlined:61737|R,insert_chart:58175,insert_chart_sharp:59962,insert_chart_rounded:63513,insert_chart_outlined:61738,insert_chart_outlined_sharp:59961,insert_chart_outlined_rounded:63512,insert_chart_outlined_outlined:61739,insert_comment:58177,insert_comment_sharp:59963,insert_comment_rounded:63514,insert_comment_outlined:61740,insert_drive_file:58178,insert_drive_file_sharp:59964,insert_drive_file_rounded:63515,insert_drive_file_outlined:61741,insert_emoticon:58179,insert_emoticon_sharp:59965,insert_emoticon_rounded:63516,insert_emoticon_outlined:61742,insert_invitation:58180,insert_invitation_sharp:59966,insert_invitation_rounded:63517,insert_invitation_outlined:61743,insert_link:58181,insert_link_sharp:59967,insert_link_rounded:63518,insert_link_outlined:61744,insert_page_break:984352,insert_page_break_sharp:984106,insert_page_break_rounded:983863,insert_page_break_outlined:984600,insert_photo:58182,insert_photo_sharp:59968,insert_photo_rounded:63519,insert_photo_outlined:61745,insights:58183,insights_sharp:59969,insights_rounded:63520,insights_outlined:61746,install_desktop:984353,install_desktop_sharp:984107,install_desktop_rounded:983864,install_desktop_outlined:984601,install_mobile:984354,install_mobile_sharp:984108,install_mobile_rounded:983865,install_mobile_outlined:984602,integration_instructions:58184,integration_instructions_sharp:59970,integration_instructions_rounded:63521,integration_instructions_outlined:61747,interests:984355,interests_sharp:984109,interests_rounded:983866,interests_outlined:984603,interpreter_mode:984356,interpreter_mode_sharp:984110,interpreter_mode_rounded:983867,interpreter_mode_outlined:984604,inventory:58185,inventory_sharp:59972,inventory_rounded:63523,inventory_outlined:61749,inventory_2:58186,inventory_2_sharp:59971,inventory_2_rounded:63522,inventory_2_outlined:61748,invert_colors:58187,invert_colors_sharp:59974,invert_colors_rounded:63525,invert_colors_outlined:61751,invert_colors_off:58188,invert_colors_off_sharp:59973,invert_colors_off_rounded:63524,invert_colors_off_outlined:61750,invert_colors_on:58187,invert_colors_on_sharp:59974,invert_colors_on_rounded:63525,invert_colors_on_outlined:61751,ios_share:58189,ios_share_sharp:59975,ios_share_rounded:63526,ios_share_outlined:61752,iron:58190,iron_sharp:59976,iron_rounded:63527,iron_outlined:61753,iso:58191,iso_sharp:59977,iso_rounded:63528,iso_outlined:61754,javascript:984357,javascript_sharp:984111,javascript_rounded:983868,javascript_outlined:984605,join_full:984358,join_full_sharp:984112,join_full_rounded:983869,join_full_outlined:984606,join_inner:984359,join_inner_sharp:984113,join_inner_rounded:983870,join_inner_outlined:984607,join_left:984360,join_left_sharp:984114,join_left_rounded:983871,join_left_outlined:984608,join_right:984361,join_right_sharp:984115,join_right_rounded:983872,join_right_outlined:984609,kayaking:58192,kayaking_sharp:59978,kayaking_rounded:63529,kayaking_outlined:61755,kebab_dining:984362,kebab_dining_sharp:984116,kebab_dining_rounded:983873,kebab_dining_outlined:984610,key:984363,key_sharp:984118,key_rounded:983875,key_outlined:984612,key_off:984364,key_off_sharp:984117,key_off_rounded:983874,key_off_outlined:984611,keyboard:58193,keyboard_sharp:59988,keyboard_rounded:63539,keyboard_outlined:61764,keyboard_alt:58194,keyboard_alt_sharp:59979,keyboard_alt_rounded:63530,keyboard_alt_outlined:61756,keyboard_arrow_down:58195,keyboard_arrow_down_sharp:59980,keyboard_arrow_down_rounded:63531,keyboard_arrow_down_outlined:61757,keyboard_arrow_left:58196,keyboard_arrow_left_sharp:59981,keyboard_arrow_left_rounded:63532,keyboard_arrow_left_outlined:61758,keyboard_arrow_right:58197,keyboard_arrow_right_sharp:59982,keyboard_arrow_right_rounded:63533,keyboard_arrow_right_outlined:61759,keyboard_arrow_up:58198,keyboard_arrow_up_sharp:59983,keyboard_arrow_up_rounded:63534,keyboard_arrow_up_outlined:61760,keyboard_backspace:58199|R,keyboard_backspace_sharp:59984|R,keyboard_backspace_rounded:63535|R,keyboard_backspace_outlined:61761|R,keyboard_capslock:58200,keyboard_capslock_sharp:59985,keyboard_capslock_rounded:63536,keyboard_capslock_outlined:61762,keyboard_command_key:984365,keyboard_command_key_sharp:984119,keyboard_command_key_rounded:983876,keyboard_command_key_outlined:984613,keyboard_control:58370,keyboard_control_sharp:60154,keyboard_control_rounded:63705,keyboard_control_outlined:61927,keyboard_control_key:984366,keyboard_control_key_sharp:984120,keyboard_control_key_rounded:983877,keyboard_control_key_outlined:984614,keyboard_double_arrow_down:984367,keyboard_double_arrow_down_sharp:984121,keyboard_double_arrow_down_rounded:983878,keyboard_double_arrow_down_outlined:984615,keyboard_double_arrow_left:984368,keyboard_double_arrow_left_sharp:984122,keyboard_double_arrow_left_rounded:983879,keyboard_double_arrow_left_outlined:984616,keyboard_double_arrow_right:984369,keyboard_double_arrow_right_sharp:984123,keyboard_double_arrow_right_rounded:983880,keyboard_double_arrow_right_outlined:984617,keyboard_double_arrow_up:984370,keyboard_double_arrow_up_sharp:984124,keyboard_double_arrow_up_rounded:983881,keyboard_double_arrow_up_outlined:984618,keyboard_hide:58201,keyboard_hide_sharp:59986,keyboard_hide_rounded:63537,keyboard_hide_outlined:61763,keyboard_option_key:984371,keyboard_option_key_sharp:984125,keyboard_option_key_rounded:983882,keyboard_option_key_outlined:984619,keyboard_return:58202,keyboard_return_sharp:59987,keyboard_return_rounded:63538,keyboard_return_outlined:61765,keyboard_tab:58203|R,keyboard_tab_sharp:59989|R,keyboard_tab_rounded:63540|R,keyboard_tab_outlined:61766|R,keyboard_voice:58204,keyboard_voice_sharp:59990,keyboard_voice_rounded:63541,keyboard_voice_outlined:61767,king_bed:58205,king_bed_sharp:59991,king_bed_rounded:63542,king_bed_outlined:61768,kitchen:58206,kitchen_sharp:59992,kitchen_rounded:63543,kitchen_outlined:61769,kitesurfing:58207,kitesurfing_sharp:59993,kitesurfing_rounded:63544,kitesurfing_outlined:61770,label:58208|R,label_sharp:59998|R,label_rounded:63549|R,label_outlined:61773|R,label_important:58209|R,label_important_sharp:59995|R,label_important_rounded:63546|R,label_important_outlined:61771|R,label_important_outline:58210,label_important_outline_sharp:59994,label_important_outline_rounded:63545,label_off:58211|R,label_off_sharp:59996|R,label_off_rounded:63547|R,label_off_outlined:61772|R,label_outline:58212|R,label_outline_sharp:59997|R,label_outline_rounded:63548|R,lan:984372,lan_sharp:984126,lan_rounded:983883,lan_outlined:984620,landscape:58213,landscape_sharp:59999,landscape_rounded:63550,landscape_outlined:61774,landslide:984998,landslide_sharp:984910,landslide_rounded:985086,landslide_outlined:984822,language:58214,language_sharp:60000,language_rounded:63551,language_outlined:61775,laptop:58215,laptop_sharp:60003,laptop_rounded:63554,laptop_outlined:61778,laptop_chromebook:58216,laptop_chromebook_sharp:60001,laptop_chromebook_rounded:63552,laptop_chromebook_outlined:61776,laptop_mac:58217,laptop_mac_sharp:60002,laptop_mac_rounded:63553,laptop_mac_outlined:61777,laptop_windows:58218,laptop_windows_sharp:60004,laptop_windows_rounded:63555,laptop_windows_outlined:61779,last_page:58219|R,last_page_sharp:60005|R,last_page_rounded:63556|R,last_page_outlined:61780|R,launch:58220|R,launch_sharp:60006|R,launch_rounded:63557|R,launch_outlined:61781|R,layers:58221,layers_sharp:60008,layers_rounded:63559,layers_outlined:61783,layers_clear:58222,layers_clear_sharp:60007,layers_clear_rounded:63558,layers_clear_outlined:61782,leaderboard:58223,leaderboard_sharp:60009,leaderboard_rounded:63560,leaderboard_outlined:61784,leak_add:58224,leak_add_sharp:60010,leak_add_rounded:63561,leak_add_outlined:61785,leak_remove:58225,leak_remove_sharp:60011,leak_remove_rounded:63562,leak_remove_outlined:61786,leave_bags_at_home:58425,leave_bags_at_home_sharp:60210,leave_bags_at_home_rounded:983057,leave_bags_at_home_outlined:61983,legend_toggle:58226,legend_toggle_sharp:60012,legend_toggle_rounded:63563,legend_toggle_outlined:61787,lens:58227,lens_sharp:60014,lens_rounded:63565,lens_outlined:61789,lens_blur:58228,lens_blur_sharp:60013,lens_blur_rounded:63564,lens_blur_outlined:61788,library_add:58229,library_add_sharp:60016,library_add_rounded:63567,library_add_outlined:61791,library_add_check:58230,library_add_check_sharp:60015,library_add_check_rounded:63566,library_add_check_outlined:61790,library_books:58231,library_books_sharp:60017,library_books_rounded:63568,library_books_outlined:61792,library_music:58232,library_music_sharp:60018,library_music_rounded:63569,library_music_outlined:61793,light:58233,light_sharp:60020,light_rounded:63571,light_outlined:61795,light_mode:58234,light_mode_sharp:60019,light_mode_rounded:63570,light_mode_outlined:61794,lightbulb:58235,lightbulb_sharp:60022,lightbulb_rounded:63573,lightbulb_outlined:61796,lightbulb_circle:984999,lightbulb_circle_sharp:984911,lightbulb_circle_rounded:985087,lightbulb_circle_outlined:984823,lightbulb_outline:58236,lightbulb_outline_sharp:60021,lightbulb_outline_rounded:63572,line_axis:984373,line_axis_sharp:984127,line_axis_rounded:983884,line_axis_outlined:984621,line_style:58237,line_style_sharp:60023,line_style_rounded:63574,line_style_outlined:61797,line_weight:58238,line_weight_sharp:60024,line_weight_rounded:63575,line_weight_outlined:61798,linear_scale:58239,linear_scale_sharp:60025,linear_scale_rounded:63576,linear_scale_outlined:61799,link:58240,link_sharp:60027,link_rounded:63578,link_outlined:61801,link_off:58241,link_off_sharp:60026,link_off_rounded:63577,link_off_outlined:61800,linked_camera:58242,linked_camera_sharp:60028,linked_camera_rounded:63579,linked_camera_outlined:61802,liquor:58243,liquor_sharp:60029,liquor_rounded:63580,liquor_outlined:61803,list:58244|R,list_sharp:60031|R,list_rounded:63582|R,list_outlined:61805|R,list_alt:58245|R,list_alt_sharp:60030|R,list_alt_rounded:63581|R,list_alt_outlined:61804|R,live_help:58246|R,live_help_sharp:60032|R,live_help_rounded:63583|R,live_help_outlined:61806|R,live_tv:58247,live_tv_sharp:60033,live_tv_rounded:63584,live_tv_outlined:61807,living:58248,living_sharp:60034,living_rounded:63585,living_outlined:61808,local_activity:58249,local_activity_sharp:60035,local_activity_rounded:63586,local_activity_outlined:61809,local_airport:58250,local_airport_sharp:60036,local_airport_rounded:63587,local_airport_outlined:61810,local_atm:58251,local_atm_sharp:60037,local_atm_rounded:63588,local_atm_outlined:61811,local_attraction:58249,local_attraction_sharp:60035,local_attraction_rounded:63586,local_attraction_outlined:61809,local_bar:58252,local_bar_sharp:60038,local_bar_rounded:63589,local_bar_outlined:61812,local_cafe:58253,local_cafe_sharp:60039,local_cafe_rounded:63590,local_cafe_outlined:61813,local_car_wash:58254,local_car_wash_sharp:60040,local_car_wash_rounded:63591,local_car_wash_outlined:61814,local_convenience_store:58255,local_convenience_store_sharp:60041,local_convenience_store_rounded:63592,local_convenience_store_outlined:61815,local_dining:58256,local_dining_sharp:60042,local_dining_rounded:63593,local_dining_outlined:61816,local_drink:58257,local_drink_sharp:60043,local_drink_rounded:63594,local_drink_outlined:61817,local_fire_department:58258,local_fire_department_sharp:60044,local_fire_department_rounded:63595,local_fire_department_outlined:61818,local_florist:58259,local_florist_sharp:60045,local_florist_rounded:63596,local_florist_outlined:61819,local_gas_station:58260,local_gas_station_sharp:60046,local_gas_station_rounded:63597,local_gas_station_outlined:61820,local_grocery_store:58261,local_grocery_store_sharp:60047,local_grocery_store_rounded:63598,local_grocery_store_outlined:61821,local_hospital:58262,local_hospital_sharp:60048,local_hospital_rounded:63599,local_hospital_outlined:61822,local_hotel:58263,local_hotel_sharp:60049,local_hotel_rounded:63600,local_hotel_outlined:61823,local_laundry_service:58264,local_laundry_service_sharp:60050,local_laundry_service_rounded:63601,local_laundry_service_outlined:61824,local_library:58265,local_library_sharp:60051,local_library_rounded:63602,local_library_outlined:61825,local_mall:58266,local_mall_sharp:60052,local_mall_rounded:63603,local_mall_outlined:61826,local_movies:58267,local_movies_sharp:60053,local_movies_rounded:63604,local_movies_outlined:61827,local_offer:58268,local_offer_sharp:60054,local_offer_rounded:63605,local_offer_outlined:61828,local_parking:58269,local_parking_sharp:60055,local_parking_rounded:63606,local_parking_outlined:61829,local_pharmacy:58270,local_pharmacy_sharp:60056,local_pharmacy_rounded:63607,local_pharmacy_outlined:61830,local_phone:58271,local_phone_sharp:60057,local_phone_rounded:63608,local_phone_outlined:61831,local_pizza:58272,local_pizza_sharp:60058,local_pizza_rounded:63609,local_pizza_outlined:61832,local_play:58273,local_play_sharp:60059,local_play_rounded:63610,local_play_outlined:61833,local_police:58274,local_police_sharp:60060,local_police_rounded:63611,local_police_outlined:61834,local_post_office:58275,local_post_office_sharp:60061,local_post_office_rounded:63612,local_post_office_outlined:61835,local_print_shop:58276,local_print_shop_sharp:60062,local_print_shop_rounded:63613,local_print_shop_outlined:61836,local_printshop:58276,local_printshop_sharp:60062,local_printshop_rounded:63613,local_printshop_outlined:61836,local_restaurant:58256,local_restaurant_sharp:60042,local_restaurant_rounded:63593,local_restaurant_outlined:61816,local_see:58277,local_see_sharp:60063,local_see_rounded:63614,local_see_outlined:61837,local_shipping:58278,local_shipping_sharp:60064,local_shipping_rounded:63615,local_shipping_outlined:61838,local_taxi:58279,local_taxi_sharp:60065,local_taxi_rounded:63616,local_taxi_outlined:61839,location_city:58280,location_city_sharp:60066,location_city_rounded:63617,location_city_outlined:61840,location_disabled:58281,location_disabled_sharp:60067,location_disabled_rounded:63618,location_disabled_outlined:61841,location_history:58520,location_history_sharp:60303,location_history_rounded:983150,location_history_outlined:62077,location_off:58282,location_off_sharp:60068,location_off_rounded:63619,location_off_outlined:61842,location_on:58283,location_on_sharp:60069,location_on_rounded:63620,location_on_outlined:61843,location_pin:58284,location_searching:58285,location_searching_sharp:60070,location_searching_rounded:63621,location_searching_outlined:61844,lock:58286,lock_sharp:60074,lock_rounded:63625,lock_outlined:61847,lock_clock:58287,lock_clock_sharp:60071,lock_clock_rounded:63622,lock_clock_outlined:61845,lock_open:58288,lock_open_sharp:60072,lock_open_rounded:63623,lock_open_outlined:61846,lock_outline:58289,lock_outline_sharp:60073,lock_outline_rounded:63624,lock_person:985000,lock_person_sharp:984912,lock_person_rounded:985088,lock_person_outlined:984824,lock_reset:984374,lock_reset_sharp:984128,lock_reset_rounded:983885,lock_reset_outlined:984622,login:58290,login_sharp:60075,login_rounded:63626,login_outlined:61848,logo_dev:984375,logo_dev_sharp:984129,logo_dev_rounded:983886,logo_dev_outlined:984623,logout:58291,logout_sharp:60076,logout_rounded:63627,logout_outlined:61849,looks:58292,looks_sharp:60082,looks_rounded:63633,looks_outlined:61855,looks_3:58293,looks_3_sharp:60077,looks_3_rounded:63628,looks_3_outlined:61850,looks_4:58294,looks_4_sharp:60078,looks_4_rounded:63629,looks_4_outlined:61851,looks_5:58295,looks_5_sharp:60079,looks_5_rounded:63630,looks_5_outlined:61852,looks_6:58296,looks_6_sharp:60080,looks_6_rounded:63631,looks_6_outlined:61853,looks_one:58297,looks_one_sharp:60081,looks_one_rounded:63632,looks_one_outlined:61854,looks_two:58298,looks_two_sharp:60083,looks_two_rounded:63634,looks_two_outlined:61856,loop:58299,loop_sharp:60084,loop_rounded:63635,loop_outlined:61857,loupe:58300,loupe_sharp:60085,loupe_rounded:63636,loupe_outlined:61858,low_priority:58301,low_priority_sharp:60086,low_priority_rounded:63637,low_priority_outlined:61859,loyalty:58302,loyalty_sharp:60087,loyalty_rounded:63638,loyalty_outlined:61860,lte_mobiledata:58303,lte_mobiledata_sharp:60088,lte_mobiledata_rounded:63639,lte_mobiledata_outlined:61861,lte_plus_mobiledata:58304,lte_plus_mobiledata_sharp:60089,lte_plus_mobiledata_rounded:63640,lte_plus_mobiledata_outlined:61862,luggage:58305,luggage_sharp:60090,luggage_rounded:63641,luggage_outlined:61863,lunch_dining:58306,lunch_dining_sharp:60091,lunch_dining_rounded:63642,lunch_dining_outlined:61864,lyrics:985001,lyrics_sharp:984913,lyrics_rounded:985089,lyrics_outlined:984825,macro_off:985195,macro_off_sharp:985155,macro_off_rounded:985228,macro_off_outlined:985258,mail:58307,mail_sharp:60093,mail_rounded:63644,mail_outlined:61866,mail_lock:985002,mail_lock_sharp:984914,mail_lock_rounded:985090,mail_lock_outlined:984826,mail_outline:58308,mail_outline_sharp:60092,mail_outline_rounded:63643,mail_outline_outlined:61865,male:58309,male_sharp:60094,male_rounded:63645,male_outlined:61867,man:984376,man_sharp:984130,man_rounded:983887,man_outlined:984624,man_2:985196,man_2_sharp:985156,man_2_rounded:985229,man_2_outlined:985259,man_3:985197,man_3_sharp:985157,man_3_rounded:985230,man_3_outlined:985260,man_4:985198,man_4_sharp:985158,man_4_rounded:985231,man_4_outlined:985261,manage_accounts:58310,manage_accounts_sharp:60095,manage_accounts_rounded:63646,manage_accounts_outlined:61868,manage_history:985003,manage_history_sharp:984915,manage_history_rounded:985091,manage_history_outlined:984827,manage_search:58311,manage_search_sharp:60096,manage_search_rounded:63647,manage_search_outlined:61869,map:58312,map_sharp:60097,map_rounded:63648,map_outlined:61870,maps_home_work:58313,maps_home_work_sharp:60098,maps_home_work_rounded:63649,maps_home_work_outlined:61871,maps_ugc:58314,maps_ugc_sharp:60099,maps_ugc_rounded:63650,maps_ugc_outlined:61872,margin:58315,margin_sharp:60100,margin_rounded:63651,margin_outlined:61873,mark_as_unread:58316,mark_as_unread_sharp:60101,mark_as_unread_rounded:63652,mark_as_unread_outlined:61874,mark_chat_read:58317,mark_chat_read_sharp:60102,mark_chat_read_rounded:63653,mark_chat_read_outlined:61875,mark_chat_unread:58318,mark_chat_unread_sharp:60103,mark_chat_unread_rounded:63654,mark_chat_unread_outlined:61876,mark_email_read:58319,mark_email_read_sharp:60104,mark_email_read_rounded:63655,mark_email_read_outlined:61877,mark_email_unread:58320,mark_email_unread_sharp:60105,mark_email_unread_rounded:63656,mark_email_unread_outlined:61878,mark_unread_chat_alt:984377,mark_unread_chat_alt_sharp:984131,mark_unread_chat_alt_rounded:983888,mark_unread_chat_alt_outlined:984625,markunread:58321,markunread_sharp:60107,markunread_rounded:63658,markunread_outlined:61880,markunread_mailbox:58322,markunread_mailbox_sharp:60106,markunread_mailbox_rounded:63657,markunread_mailbox_outlined:61879,masks:58323,masks_sharp:60108,masks_rounded:63659,masks_outlined:61881,maximize:58324,maximize_sharp:60109,maximize_rounded:63660,maximize_outlined:61882,media_bluetooth_off:58325,media_bluetooth_off_sharp:60110,media_bluetooth_off_rounded:63661,media_bluetooth_off_outlined:61883,media_bluetooth_on:58326,media_bluetooth_on_sharp:60111,media_bluetooth_on_rounded:63662,media_bluetooth_on_outlined:61884,mediation:58327,mediation_sharp:60112,mediation_rounded:63663,mediation_outlined:61885,medical_information:985004,medical_information_sharp:984916,medical_information_rounded:985092,medical_information_outlined:984828,medical_services:58328,medical_services_sharp:60113,medical_services_rounded:63664,medical_services_outlined:61886,medication:58329,medication_sharp:60114,medication_rounded:63665,medication_outlined:61887,medication_liquid:984378,medication_liquid_sharp:984132,medication_liquid_rounded:983889,medication_liquid_outlined:984626,meeting_room:58330,meeting_room_sharp:60115,meeting_room_rounded:63666,meeting_room_outlined:61888,memory:58331,memory_sharp:60116,memory_rounded:63667,memory_outlined:61889,menu:58332,menu_sharp:60119,menu_rounded:63670,menu_outlined:61892,menu_book:58333,menu_book_sharp:60117,menu_book_rounded:63668,menu_book_outlined:61890,menu_open:58334,menu_open_sharp:60118,menu_open_rounded:63669,menu_open_outlined:61891,merge:984379,merge_sharp:984133,merge_rounded:983890,merge_outlined:984627,merge_type:58335,merge_type_sharp:60120,merge_type_rounded:63671,merge_type_outlined:61893,message:58336,message_sharp:60121,message_rounded:63672,message_outlined:61894,messenger:57684,messenger_sharp:59473,messenger_rounded:63024,messenger_outlined:61251,messenger_outline:57685,messenger_outline_sharp:59472,messenger_outline_rounded:63023,messenger_outline_outlined:61250,mic:58337,mic_sharp:60126,mic_rounded:63677,mic_outlined:61899,mic_external_off:58338,mic_external_off_sharp:60122,mic_external_off_rounded:63673,mic_external_off_outlined:61895,mic_external_on:58339,mic_external_on_sharp:60123,mic_external_on_rounded:63674,mic_external_on_outlined:61896,mic_none:58340,mic_none_sharp:60124,mic_none_rounded:63675,mic_none_outlined:61897,mic_off:58341,mic_off_sharp:60125,mic_off_rounded:63676,mic_off_outlined:61898,microwave:58342,microwave_sharp:60127,microwave_rounded:63678,microwave_outlined:61900,military_tech:58343,military_tech_sharp:60128,military_tech_rounded:63679,military_tech_outlined:61901,minimize:58344,minimize_sharp:60129,minimize_rounded:63680,minimize_outlined:61902,minor_crash:985005,minor_crash_sharp:984917,minor_crash_rounded:985093,minor_crash_outlined:984829,miscellaneous_services:58345,miscellaneous_services_sharp:60130,miscellaneous_services_rounded:63681,miscellaneous_services_outlined:61903,missed_video_call:58346,missed_video_call_sharp:60131,missed_video_call_rounded:63682,missed_video_call_outlined:61904,mms:58347,mms_sharp:60132,mms_rounded:63683,mms_outlined:61905,mobile_friendly:58348,mobile_friendly_sharp:60133,mobile_friendly_rounded:63684,mobile_friendly_outlined:61906,mobile_off:58349,mobile_off_sharp:60134,mobile_off_rounded:63685,mobile_off_outlined:61907,mobile_screen_share:58350|R,mobile_screen_share_sharp:60135|R,mobile_screen_share_rounded:63686|R,mobile_screen_share_outlined:61908|R,mobiledata_off:58351,mobiledata_off_sharp:60136,mobiledata_off_rounded:63687,mobiledata_off_outlined:61909,mode:58352,mode_sharp:60141,mode_rounded:63692,mode_outlined:61914,mode_comment:58353,mode_comment_sharp:60137,mode_comment_rounded:63688,mode_comment_outlined:61910,mode_edit:58354,mode_edit_sharp:60139,mode_edit_rounded:63690,mode_edit_outlined:61912,mode_edit_outline:58355,mode_edit_outline_sharp:60138,mode_edit_outline_rounded:63689,mode_edit_outline_outlined:61911,mode_fan_off:985006,mode_fan_off_sharp:984918,mode_fan_off_rounded:985094,mode_fan_off_outlined:984830,mode_night:58356,mode_night_sharp:60140,mode_night_rounded:63691,mode_night_outlined:61913,mode_of_travel:984380,mode_of_travel_sharp:984134,mode_of_travel_rounded:983891,mode_of_travel_outlined:984628,mode_standby:58357,mode_standby_sharp:60142,mode_standby_rounded:63693,mode_standby_outlined:61915,model_training:58358,model_training_sharp:60143,model_training_rounded:63694,model_training_outlined:61916,monetization_on:58359,monetization_on_sharp:60144,monetization_on_rounded:63695,monetization_on_outlined:61917,money:58360,money_sharp:60147,money_rounded:63698,money_outlined:61920,money_off:58361,money_off_sharp:60146,money_off_rounded:63697,money_off_outlined:61919,money_off_csred:58362,money_off_csred_sharp:60145,money_off_csred_rounded:63696,money_off_csred_outlined:61918,monitor:58363,monitor_sharp:60148,monitor_rounded:63699,monitor_outlined:61921,monitor_heart:984381,monitor_heart_sharp:984135,monitor_heart_rounded:983892,monitor_heart_outlined:984629,monitor_weight:58364,monitor_weight_sharp:60149,monitor_weight_rounded:63700,monitor_weight_outlined:61922,monochrome_photos:58365,monochrome_photos_sharp:60150,monochrome_photos_rounded:63701,monochrome_photos_outlined:61923,mood:58366,mood_sharp:60152,mood_rounded:63703,mood_outlined:61925,mood_bad:58367,mood_bad_sharp:60151,mood_bad_rounded:63702,mood_bad_outlined:61924,moped:58368,moped_sharp:60153,moped_rounded:63704,moped_outlined:61926,more:58369,more_sharp:60155,more_rounded:63706,more_outlined:61928,more_horiz:58370,more_horiz_sharp:60154,more_horiz_rounded:63705,more_horiz_outlined:61927,more_time:58371,more_time_sharp:60156,more_time_rounded:63707,more_time_outlined:61929,more_vert:58372,more_vert_sharp:60157,more_vert_rounded:63708,more_vert_outlined:61930,mosque:984382,mosque_sharp:984136,mosque_rounded:983893,mosque_outlined:984630,motion_photos_auto:58373,motion_photos_auto_sharp:60158,motion_photos_auto_rounded:63709,motion_photos_auto_outlined:61931,motion_photos_off:58374,motion_photos_off_sharp:60159,motion_photos_off_rounded:63710,motion_photos_off_outlined:61932,motion_photos_on:58375,motion_photos_on_sharp:60160,motion_photos_on_rounded:63711,motion_photos_on_outlined:61933,motion_photos_pause:58376,motion_photos_pause_sharp:60161,motion_photos_pause_rounded:63712,motion_photos_pause_outlined:61934,motion_photos_paused:58377,motion_photos_paused_sharp:60162,motion_photos_paused_rounded:63713,motion_photos_paused_outlined:61935,motorcycle:58378,motorcycle_sharp:60163,motorcycle_rounded:63714,motorcycle_outlined:61936,mouse:58379,mouse_sharp:60164,mouse_rounded:63715,mouse_outlined:61937,move_down:984383,move_down_sharp:984137,move_down_rounded:983894,move_down_outlined:984631,move_to_inbox:58380,move_to_inbox_sharp:60165,move_to_inbox_rounded:63716,move_to_inbox_outlined:61938,move_up:984384,move_up_sharp:984138,move_up_rounded:983895,move_up_outlined:984632,movie:58381,movie_sharp:60168,movie_rounded:63719,movie_outlined:61941,movie_creation:58382,movie_creation_sharp:60166,movie_creation_rounded:63717,movie_creation_outlined:61939,movie_edit:985273,movie_filter:58383,movie_filter_sharp:60167,movie_filter_rounded:63718,movie_filter_outlined:61940,moving:58384,moving_sharp:60169,moving_rounded:63720,moving_outlined:61942,mp:58385,mp_sharp:60170,mp_rounded:63721,mp_outlined:61943,multiline_chart:58386|R,multiline_chart_sharp:60171|R,multiline_chart_rounded:63722|R,multiline_chart_outlined:61944|R,multiple_stop:58387,multiple_stop_sharp:60172,multiple_stop_rounded:63723,multiple_stop_outlined:61945,multitrack_audio:58083,multitrack_audio_sharp:59870,multitrack_audio_rounded:63421,multitrack_audio_outlined:61648,museum:58388,museum_sharp:60173,museum_rounded:63724,museum_outlined:61946,music_note:58389,music_note_sharp:60174,music_note_rounded:63725,music_note_outlined:61947,music_off:58390,music_off_sharp:60175,music_off_rounded:63726,music_off_outlined:61948,music_video:58391,music_video_sharp:60176,music_video_rounded:63727,music_video_outlined:61949,my_library_add:58229,my_library_add_sharp:60016,my_library_add_rounded:63567,my_library_add_outlined:61791,my_library_books:58231,my_library_books_sharp:60017,my_library_books_rounded:63568,my_library_books_outlined:61792,my_library_music:58232,my_library_music_sharp:60018,my_library_music_rounded:63569,my_library_music_outlined:61793,my_location:58392,my_location_sharp:60177,my_location_rounded:63728,my_location_outlined:61950,nat:58393,nat_sharp:60178,nat_rounded:63729,nat_outlined:61951,nature:58394,nature_sharp:60180,nature_rounded:63731,nature_outlined:61952,nature_people:58395,nature_people_sharp:60179,nature_people_rounded:63730,nature_people_outlined:61953,navigate_before:58396|R,navigate_before_sharp:60181|R,navigate_before_rounded:63732|R,navigate_before_outlined:61954|R,navigate_next:58397|R,navigate_next_sharp:60182|R,navigate_next_rounded:63733|R,navigate_next_outlined:61955|R,navigation:58398,navigation_sharp:60183,navigation_rounded:63734,navigation_outlined:61956,near_me:58399,near_me_sharp:60185,near_me_rounded:63736,near_me_outlined:61958,near_me_disabled:58400,near_me_disabled_sharp:60184,near_me_disabled_rounded:63735,near_me_disabled_outlined:61957,nearby_error:58401,nearby_error_sharp:60186,nearby_error_rounded:63737,nearby_error_outlined:61959,nearby_off:58402,nearby_off_sharp:60187,nearby_off_rounded:63738,nearby_off_outlined:61960,nest_cam_wired_stand:985007,nest_cam_wired_stand_sharp:984919,nest_cam_wired_stand_rounded:985095,nest_cam_wired_stand_outlined:984831,network_cell:58403,network_cell_sharp:60188,network_cell_rounded:63739,network_cell_outlined:61961,network_check:58404,network_check_sharp:60189,network_check_rounded:63740,network_check_outlined:61962,network_locked:58405,network_locked_sharp:60190,network_locked_rounded:63741,network_locked_outlined:61963,network_ping:984767,network_ping_sharp:984754,network_ping_rounded:984780,network_ping_outlined:984741,network_wifi:58406,network_wifi_sharp:60191,network_wifi_rounded:63742,network_wifi_outlined:61964,network_wifi_1_bar:985008,network_wifi_1_bar_sharp:984920,network_wifi_1_bar_rounded:985096,network_wifi_1_bar_outlined:984832,network_wifi_2_bar:985009,network_wifi_2_bar_sharp:984921,network_wifi_2_bar_rounded:985097,network_wifi_2_bar_outlined:984833,network_wifi_3_bar:985010,network_wifi_3_bar_sharp:984922,network_wifi_3_bar_rounded:985098,network_wifi_3_bar_outlined:984834,new_label:58407,new_label_sharp:60192,new_label_rounded:63743,new_label_outlined:61965,new_releases:58408,new_releases_sharp:60193,new_releases_rounded:983040,new_releases_outlined:61966,newspaper:984385,newspaper_sharp:984139,newspaper_rounded:983896,newspaper_outlined:984633,next_plan:58409,next_plan_sharp:60194,next_plan_rounded:983041,next_plan_outlined:61967,next_week:58410|R,next_week_sharp:60195|R,next_week_rounded:983042|R,next_week_outlined:61968|R,nfc:58411,nfc_sharp:60196,nfc_rounded:983043,nfc_outlined:61969,night_shelter:58412,night_shelter_sharp:60197,night_shelter_rounded:983044,night_shelter_outlined:61970,nightlife:58413,nightlife_sharp:60198,nightlife_rounded:983045,nightlife_outlined:61971,nightlight:58414,nightlight_sharp:60200,nightlight_rounded:983047,nightlight_outlined:61972,nightlight_round:58415,nightlight_round_sharp:60199,nightlight_round_rounded:983046,nightlight_round_outlined:61973,nights_stay:58416,nights_stay_sharp:60201,nights_stay_rounded:983048,nights_stay_outlined:61974,no_accounts:58417,no_accounts_sharp:60202,no_accounts_rounded:983049,no_accounts_outlined:61975,no_adult_content:985011,no_adult_content_sharp:984923,no_adult_content_rounded:985099,no_adult_content_outlined:984835,no_backpack:58418,no_backpack_sharp:60203,no_backpack_rounded:983050,no_backpack_outlined:61976,no_cell:58419,no_cell_sharp:60204,no_cell_rounded:983051,no_cell_outlined:61977,no_crash:985012,no_crash_sharp:984924,no_crash_rounded:985100,no_crash_outlined:984836,no_drinks:58420,no_drinks_sharp:60205,no_drinks_rounded:983052,no_drinks_outlined:61978,no_encryption:58421,no_encryption_sharp:60207,no_encryption_rounded:983054,no_encryption_outlined:61980,no_encryption_gmailerrorred:58422,no_encryption_gmailerrorred_sharp:60206,no_encryption_gmailerrorred_rounded:983053,no_encryption_gmailerrorred_outlined:61979,no_flash:58423,no_flash_sharp:60208,no_flash_rounded:983055,no_flash_outlined:61981,no_food:58424,no_food_sharp:60209,no_food_rounded:983056,no_food_outlined:61982,no_luggage:58425,no_luggage_sharp:60210,no_luggage_rounded:983057,no_luggage_outlined:61983,no_meals:58426,no_meals_sharp:60211,no_meals_rounded:983058,no_meals_outlined:61984,no_meals_ouline:58427,no_meeting_room:58428,no_meeting_room_sharp:60212,no_meeting_room_rounded:983059,no_meeting_room_outlined:61985,no_photography:58429,no_photography_sharp:60213,no_photography_rounded:983060,no_photography_outlined:61986,no_sim:58430,no_sim_sharp:60214,no_sim_rounded:983061,no_sim_outlined:61987,no_stroller:58431,no_stroller_sharp:60215,no_stroller_rounded:983062,no_stroller_outlined:61988,no_transfer:58432,no_transfer_sharp:60216,no_transfer_rounded:983063,no_transfer_outlined:61989,noise_aware:985013,noise_aware_sharp:984925,noise_aware_rounded:985101,noise_aware_outlined:984837,noise_control_off:985014,noise_control_off_sharp:984926,noise_control_off_rounded:985102,noise_control_off_outlined:984838,nordic_walking:58433,nordic_walking_sharp:60217,nordic_walking_rounded:983064,nordic_walking_outlined:61990,north:58434,north_sharp:60219,north_rounded:983066,north_outlined:61992,north_east:58435,north_east_sharp:60218,north_east_rounded:983065,north_east_outlined:61991,north_west:58436,north_west_sharp:60220,north_west_rounded:983067,north_west_outlined:61993,not_accessible:58437,not_accessible_sharp:60221,not_accessible_rounded:983068,not_accessible_outlined:61994,not_interested:58438,not_interested_sharp:60222,not_interested_rounded:983069,not_interested_outlined:61995,not_listed_location:58439,not_listed_location_sharp:60223,not_listed_location_rounded:983070,not_listed_location_outlined:61996,not_started:58440,not_started_sharp:60224,not_started_rounded:983071,not_started_outlined:61997,note:58441|R,note_sharp:60227|R,note_rounded:983074|R,note_outlined:62000|R,note_add:58442,note_add_sharp:60225,note_add_rounded:983072,note_add_outlined:61998,note_alt:58443|R,note_alt_sharp:60226|R,note_alt_rounded:983073|R,note_alt_outlined:61999|R,notes:58444,notes_sharp:60228,notes_rounded:983075,notes_outlined:62001,notification_add:58445,notification_add_sharp:60229,notification_add_rounded:983076,notification_add_outlined:62002,notification_important:58446,notification_important_sharp:60230,notification_important_rounded:983077,notification_important_outlined:62003,notifications:58447,notifications_sharp:60235,notifications_rounded:983082,notifications_outlined:62007,notifications_active:58448,notifications_active_sharp:60231,notifications_active_rounded:983078,notifications_active_outlined:62004,notifications_none:58449,notifications_none_sharp:60232,notifications_none_rounded:983079,notifications_none_outlined:62005,notifications_off:58450,notifications_off_sharp:60233,notifications_off_rounded:983080,notifications_off_outlined:62006,notifications_on:58448,notifications_on_sharp:60231,notifications_on_rounded:983078,notifications_on_outlined:62004,notifications_paused:58451,notifications_paused_sharp:60234,notifications_paused_rounded:983081,notifications_paused_outlined:62008,now_wallpaper:59082,now_wallpaper_sharp:60864,now_wallpaper_rounded:983711,now_wallpaper_outlined:62637,now_widgets:59110,now_widgets_sharp:60890,now_widgets_rounded:983737,now_widgets_outlined:62663,numbers:984386,numbers_sharp:984140,numbers_rounded:983897,numbers_outlined:984634,offline_bolt:58452,offline_bolt_sharp:60236,offline_bolt_rounded:983083,offline_bolt_outlined:62009,offline_pin:58453,offline_pin_sharp:60237,offline_pin_rounded:983084,offline_pin_outlined:62010,offline_share:58454,offline_share_sharp:60238,offline_share_rounded:983085,offline_share_outlined:62011,oil_barrel:985015,oil_barrel_sharp:984927,oil_barrel_rounded:985103,oil_barrel_outlined:984839,on_device_training:985016,on_device_training_sharp:984928,on_device_training_rounded:985104,on_device_training_outlined:984840,ondemand_video:58455,ondemand_video_sharp:60239,ondemand_video_rounded:983086,ondemand_video_outlined:62012,online_prediction:58456,online_prediction_sharp:60240,online_prediction_rounded:983087,online_prediction_outlined:62013,opacity:58457,opacity_sharp:60241,opacity_rounded:983088,opacity_outlined:62014,open_in_browser:58458,open_in_browser_sharp:60242,open_in_browser_rounded:983089,open_in_browser_outlined:62015,open_in_full:58459,open_in_full_sharp:60243,open_in_full_rounded:983090,open_in_full_outlined:62016,open_in_new:58460|R,open_in_new_sharp:60245|R,open_in_new_rounded:983092|R,open_in_new_outlined:62018|R,open_in_new_off:58461,open_in_new_off_sharp:60244,open_in_new_off_rounded:983091,open_in_new_off_outlined:62017,open_with:58462,open_with_sharp:60246,open_with_rounded:983093,open_with_outlined:62019,other_houses:58463,other_houses_sharp:60247,other_houses_rounded:983094,other_houses_outlined:62020,outbond:58464,outbond_sharp:60248,outbond_rounded:983095,outbond_outlined:62021,outbound:58465,outbound_sharp:60249,outbound_rounded:983096,outbound_outlined:62022,outbox:58466,outbox_sharp:60250,outbox_rounded:983097,outbox_outlined:62023,outdoor_grill:58467,outdoor_grill_sharp:60251,outdoor_grill_rounded:983098,outdoor_grill_outlined:62024,outgoing_mail:58468,outlet:58469,outlet_sharp:60252,outlet_rounded:983099,outlet_outlined:62025,outlined_flag:58470,outlined_flag_sharp:60253,outlined_flag_rounded:983100,outlined_flag_outlined:62026,output:984387,output_sharp:984141,output_rounded:983898,output_outlined:984635,padding:58471,padding_sharp:60254,padding_rounded:983101,padding_outlined:62027,pages:58472,pages_sharp:60255,pages_rounded:983102,pages_outlined:62028,pageview:58473,pageview_sharp:60256,pageview_rounded:983103,pageview_outlined:62029,paid:58474,paid_sharp:60257,paid_rounded:983104,paid_outlined:62030,palette:58475,palette_sharp:60258,palette_rounded:983105,palette_outlined:62031,pallet:985199,pan_tool:58476,pan_tool_sharp:60259,pan_tool_rounded:983106,pan_tool_outlined:62032,pan_tool_alt:984388,pan_tool_alt_sharp:984142,pan_tool_alt_rounded:983899,pan_tool_alt_outlined:984636,panorama:58477,panorama_sharp:60265,panorama_rounded:983112,panorama_outlined:62036,panorama_fish_eye:58478,panorama_fish_eye_sharp:60260,panorama_fish_eye_rounded:983107,panorama_fish_eye_outlined:62033,panorama_fisheye:58478,panorama_fisheye_sharp:60260,panorama_fisheye_rounded:983107,panorama_fisheye_outlined:62033,panorama_horizontal:58479,panorama_horizontal_sharp:60262,panorama_horizontal_rounded:983108,panorama_horizontal_outlined:62034,panorama_horizontal_select:58480,panorama_horizontal_select_sharp:60261,panorama_horizontal_select_rounded:983109,panorama_horizontal_select_outlined:62035,panorama_photosphere:58481,panorama_photosphere_sharp:60264,panorama_photosphere_rounded:983110,panorama_photosphere_outlined:62037,panorama_photosphere_select:58482,panorama_photosphere_select_sharp:60263,panorama_photosphere_select_rounded:983111,panorama_photosphere_select_outlined:62038,panorama_vertical:58483,panorama_vertical_sharp:60267,panorama_vertical_rounded:983113,panorama_vertical_outlined:62039,panorama_vertical_select:58484,panorama_vertical_select_sharp:60266,panorama_vertical_select_rounded:983114,panorama_vertical_select_outlined:62040,panorama_wide_angle:58485,panorama_wide_angle_sharp:60269,panorama_wide_angle_rounded:983115,panorama_wide_angle_outlined:62041,panorama_wide_angle_select:58486,panorama_wide_angle_select_sharp:60268,panorama_wide_angle_select_rounded:983116,panorama_wide_angle_select_outlined:62042,paragliding:58487,paragliding_sharp:60270,paragliding_rounded:983117,paragliding_outlined:62043,park:58488,park_sharp:60271,park_rounded:983118,park_outlined:62044,party_mode:58489,party_mode_sharp:60272,party_mode_rounded:983119,party_mode_outlined:62045,password:58490,password_sharp:60273,password_rounded:983120,password_outlined:62046,paste:57746,paste_sharp:59536,paste_rounded:63087,paste_outlined:61314,pattern:58491,pattern_sharp:60274,pattern_rounded:983121,pattern_outlined:62047,pause:58492,pause_sharp:60279,pause_rounded:983126,pause_outlined:62051,pause_circle:58493,pause_circle_sharp:60277,pause_circle_rounded:983124,pause_circle_outlined:62050,pause_circle_filled:58494,pause_circle_filled_sharp:60275,pause_circle_filled_rounded:983122,pause_circle_filled_outlined:62048,pause_circle_outline:58495,pause_circle_outline_sharp:60276,pause_circle_outline_rounded:983123,pause_circle_outline_outlined:62049,pause_presentation:58496,pause_presentation_sharp:60278,pause_presentation_rounded:983125,pause_presentation_outlined:62052,payment:58497,payment_sharp:60280,payment_rounded:983127,payment_outlined:62053,payments:58498,payments_sharp:60281,payments_rounded:983128,payments_outlined:62054,paypal:984389,paypal_sharp:984143,paypal_rounded:983900,paypal_outlined:984637,pedal_bike:58499,pedal_bike_sharp:60282,pedal_bike_rounded:983129,pedal_bike_outlined:62055,pending:58500,pending_sharp:60284,pending_rounded:983131,pending_outlined:62057,pending_actions:58501,pending_actions_sharp:60283,pending_actions_rounded:983130,pending_actions_outlined:62056,pentagon:984390,pentagon_sharp:984144,pentagon_rounded:983901,pentagon_outlined:984638,people:58502,people_sharp:60287,people_rounded:983134,people_outlined:62060,people_alt:58503,people_alt_sharp:60285,people_alt_rounded:983132,people_alt_outlined:62058,people_outline:58504,people_outline_sharp:60286,people_outline_rounded:983133,people_outline_outlined:62059,percent:984391,percent_sharp:984145,percent_rounded:983902,percent_outlined:984639,perm_camera_mic:58505,perm_camera_mic_sharp:60288,perm_camera_mic_rounded:983135,perm_camera_mic_outlined:62061,perm_contact_cal:58506,perm_contact_cal_sharp:60289,perm_contact_cal_rounded:983136,perm_contact_cal_outlined:62062,perm_contact_calendar:58506,perm_contact_calendar_sharp:60289,perm_contact_calendar_rounded:983136,perm_contact_calendar_outlined:62062,perm_data_setting:58507,perm_data_setting_sharp:60290,perm_data_setting_rounded:983137,perm_data_setting_outlined:62063,perm_device_info:58508,perm_device_info_sharp:60291,perm_device_info_rounded:983138,perm_device_info_outlined:62064,perm_device_information:58508,perm_device_information_sharp:60291,perm_device_information_rounded:983138,perm_device_information_outlined:62064,perm_identity:58509,perm_identity_sharp:60292,perm_identity_rounded:983139,perm_identity_outlined:62065,perm_media:58510,perm_media_sharp:60293,perm_media_rounded:983140,perm_media_outlined:62066,perm_phone_msg:58511,perm_phone_msg_sharp:60294,perm_phone_msg_rounded:983141,perm_phone_msg_outlined:62067,perm_scan_wifi:58512,perm_scan_wifi_sharp:60295,perm_scan_wifi_rounded:983142,perm_scan_wifi_outlined:62068,person:58513,person_sharp:60307,person_rounded:983153,person_outlined:62075,person_2:985200,person_2_sharp:985159,person_2_rounded:985232,person_2_outlined:985262,person_3:985201,person_3_sharp:985160,person_3_rounded:985233,person_3_outlined:985263,person_4:985202,person_4_sharp:985161,person_4_rounded:985234,person_4_outlined:985264,person_add:58514,person_add_sharp:60299,person_add_rounded:983146,person_add_outlined:62072,person_add_alt:58515,person_add_alt_sharp:60297,person_add_alt_rounded:983144,person_add_alt_outlined:62070,person_add_alt_1:58516,person_add_alt_1_sharp:60296,person_add_alt_1_rounded:983143,person_add_alt_1_outlined:62069,person_add_disabled:58517,person_add_disabled_sharp:60298,person_add_disabled_rounded:983145,person_add_disabled_outlined:62071,person_off:58518,person_off_sharp:60300,person_off_rounded:983147,person_off_outlined:62073,person_outline:58519,person_outline_sharp:60301,person_outline_rounded:983148,person_outline_outlined:62074,person_pin:58520,person_pin_sharp:60303,person_pin_rounded:983150,person_pin_outlined:62077,person_pin_circle:58521,person_pin_circle_sharp:60302,person_pin_circle_rounded:983149,person_pin_circle_outlined:62076,person_remove:58522,person_remove_sharp:60305,person_remove_rounded:983152,person_remove_outlined:62079,person_remove_alt_1:58523,person_remove_alt_1_sharp:60304,person_remove_alt_1_rounded:983151,person_remove_alt_1_outlined:62078,person_search:58524,person_search_sharp:60306,person_search_rounded:983154,person_search_outlined:62080,personal_injury:58525,personal_injury_sharp:60308,personal_injury_rounded:983155,personal_injury_outlined:62081,personal_video:58526,personal_video_sharp:60309,personal_video_rounded:983156,personal_video_outlined:62082,pest_control:58527,pest_control_sharp:60311,pest_control_rounded:983158,pest_control_outlined:62083,pest_control_rodent:58528,pest_control_rodent_sharp:60310,pest_control_rodent_rounded:983157,pest_control_rodent_outlined:62084,pets:58529,pets_sharp:60312,pets_rounded:983159,pets_outlined:62085,phishing:984392,phishing_sharp:984146,phishing_rounded:983903,phishing_outlined:984640,phone:58530,phone_sharp:60324,phone_rounded:983171,phone_outlined:62096,phone_android:58531,phone_android_sharp:60313,phone_android_rounded:983160,phone_android_outlined:62086,phone_bluetooth_speaker:58532,phone_bluetooth_speaker_sharp:60314,phone_bluetooth_speaker_rounded:983161,phone_bluetooth_speaker_outlined:62087,phone_callback:58533,phone_callback_sharp:60315,phone_callback_rounded:983162,phone_callback_outlined:62088,phone_disabled:58534,phone_disabled_sharp:60316,phone_disabled_rounded:983163,phone_disabled_outlined:62089,phone_enabled:58535,phone_enabled_sharp:60317,phone_enabled_rounded:983164,phone_enabled_outlined:62090,phone_forwarded:58536,phone_forwarded_sharp:60318,phone_forwarded_rounded:983165,phone_forwarded_outlined:62091,phone_in_talk:58537,phone_in_talk_sharp:60319,phone_in_talk_rounded:983166,phone_in_talk_outlined:62092,phone_iphone:58538,phone_iphone_sharp:60320,phone_iphone_rounded:983167,phone_iphone_outlined:62093,phone_locked:58539,phone_locked_sharp:60321,phone_locked_rounded:983168,phone_locked_outlined:62094,phone_missed:58540,phone_missed_sharp:60322,phone_missed_rounded:983169,phone_missed_outlined:62095,phone_paused:58541,phone_paused_sharp:60323,phone_paused_rounded:983170,phone_paused_outlined:62097,phonelink:58542,phonelink_sharp:60330,phonelink_rounded:983176,phonelink_outlined:62101,phonelink_erase:58543,phonelink_erase_sharp:60325,phonelink_erase_rounded:983172,phonelink_erase_outlined:62098,phonelink_lock:58544,phonelink_lock_sharp:60326,phonelink_lock_rounded:983173,phonelink_lock_outlined:62099,phonelink_off:58545,phonelink_off_sharp:60327,phonelink_off_rounded:983174,phonelink_off_outlined:62100,phonelink_ring:58546,phonelink_ring_sharp:60328,phonelink_ring_rounded:983175,phonelink_ring_outlined:62102,phonelink_setup:58547,phonelink_setup_sharp:60329,phonelink_setup_rounded:983177,phonelink_setup_outlined:62103,photo:58548,photo_sharp:60337,photo_rounded:983184,photo_outlined:62110,photo_album:58549,photo_album_sharp:60331,photo_album_rounded:983178,photo_album_outlined:62104,photo_camera:58550,photo_camera_sharp:60334,photo_camera_rounded:983181,photo_camera_outlined:62107,photo_camera_back:58551,photo_camera_back_sharp:60332,photo_camera_back_rounded:983179,photo_camera_back_outlined:62105,photo_camera_front:58552,photo_camera_front_sharp:60333,photo_camera_front_rounded:983180,photo_camera_front_outlined:62106,photo_filter:58553,photo_filter_sharp:60335,photo_filter_rounded:983182,photo_filter_outlined:62108,photo_library:58554,photo_library_sharp:60336,photo_library_rounded:983183,photo_library_outlined:62109,photo_size_select_actual:58555,photo_size_select_actual_sharp:60338,photo_size_select_actual_rounded:983185,photo_size_select_actual_outlined:62111,photo_size_select_large:58556,photo_size_select_large_sharp:60339,photo_size_select_large_rounded:983186,photo_size_select_large_outlined:62112,photo_size_select_small:58557,photo_size_select_small_sharp:60340,photo_size_select_small_rounded:983187,photo_size_select_small_outlined:62113,php:984393,php_sharp:984147,php_rounded:983904,php_outlined:984641,piano:58558,piano_sharp:60342,piano_rounded:983189,piano_outlined:62115,piano_off:58559,piano_off_sharp:60341,piano_off_rounded:983188,piano_off_outlined:62114,picture_as_pdf:58560,picture_as_pdf_sharp:60343,picture_as_pdf_rounded:983190,picture_as_pdf_outlined:62116,picture_in_picture:58561,picture_in_picture_sharp:60345,picture_in_picture_rounded:983192,picture_in_picture_outlined:62118,picture_in_picture_alt:58562,picture_in_picture_alt_sharp:60344,picture_in_picture_alt_rounded:983191,picture_in_picture_alt_outlined:62117,pie_chart:58563,pie_chart_sharp:60347,pie_chart_rounded:983194,pie_chart_outline:58565,pie_chart_outline_sharp:60346,pie_chart_outline_rounded:983193,pie_chart_outline_outlined:62119,pin:58566,pin_sharp:60349,pin_rounded:983196,pin_outlined:62122,pin_drop:58567,pin_drop_sharp:60348,pin_drop_rounded:983195,pin_drop_outlined:62121,pin_end:984395,pin_end_sharp:984148,pin_end_rounded:983905,pin_end_outlined:984642,pin_invoke:984396,pin_invoke_sharp:984149,pin_invoke_rounded:983906,pin_invoke_outlined:984643,pinch:984397,pinch_sharp:984150,pinch_rounded:983907,pinch_outlined:984644,pivot_table_chart:58568,pivot_table_chart_sharp:60350,pivot_table_chart_rounded:983197,pivot_table_chart_outlined:62123,pix:984398,pix_sharp:984151,pix_rounded:983908,pix_outlined:984645,place:58569,place_sharp:60351,place_rounded:983198,place_outlined:62124,plagiarism:58570,plagiarism_sharp:60352,plagiarism_rounded:983199,plagiarism_outlined:62125,play_arrow:58571,play_arrow_sharp:60353,play_arrow_rounded:983200,play_arrow_outlined:62126,play_circle:58572,play_circle_sharp:60356,play_circle_rounded:983203,play_circle_outlined:62129,play_circle_fill:58573,play_circle_fill_sharp:60354,play_circle_fill_rounded:983201,play_circle_fill_outlined:62127,play_circle_filled:58573,play_circle_filled_sharp:60354,play_circle_filled_rounded:983201,play_circle_filled_outlined:62127,play_circle_outline:58574,play_circle_outline_sharp:60355,play_circle_outline_rounded:983202,play_circle_outline_outlined:62128,play_disabled:58575,play_disabled_sharp:60357,play_disabled_rounded:983204,play_disabled_outlined:62130,play_for_work:58576,play_for_work_sharp:60358,play_for_work_rounded:983205,play_for_work_outlined:62131,play_lesson:58577,play_lesson_sharp:60359,play_lesson_rounded:983206,play_lesson_outlined:62132,playlist_add:58578|R,playlist_add_sharp:60361|R,playlist_add_rounded:983208|R,playlist_add_outlined:62134|R,playlist_add_check:58579,playlist_add_check_sharp:60360,playlist_add_check_rounded:983207,playlist_add_check_outlined:62133,playlist_add_check_circle:984399,playlist_add_check_circle_sharp:984152,playlist_add_check_circle_rounded:983909,playlist_add_check_circle_outlined:984646,playlist_add_circle:984400,playlist_add_circle_sharp:984153,playlist_add_circle_rounded:983910,playlist_add_circle_outlined:984647,playlist_play:58580,playlist_play_sharp:60362,playlist_play_rounded:983209,playlist_play_outlined:62135,playlist_remove:984401,playlist_remove_sharp:984154,playlist_remove_rounded:983911,playlist_remove_outlined:984648,plumbing:58581,plumbing_sharp:60363,plumbing_rounded:983210,plumbing_outlined:62136,plus_one:58582,plus_one_sharp:60364,plus_one_rounded:983211,plus_one_outlined:62137,podcasts:58583,podcasts_sharp:60365,podcasts_rounded:983212,podcasts_outlined:62138,point_of_sale:58584,point_of_sale_sharp:60366,point_of_sale_rounded:983213,point_of_sale_outlined:62139,policy:58585,policy_sharp:60367,policy_rounded:983214,policy_outlined:62140,poll:58586,poll_sharp:60368,poll_rounded:983215,poll_outlined:62141,polyline:984402,polyline_sharp:984155,polyline_rounded:983912,polyline_outlined:984649,polymer:58587,polymer_sharp:60369,polymer_rounded:983216,polymer_outlined:62142,pool:58588,pool_sharp:60370,pool_rounded:983217,pool_outlined:62143,portable_wifi_off:58589,portable_wifi_off_sharp:60371,portable_wifi_off_rounded:983218,portable_wifi_off_outlined:62144,portrait:58590,portrait_sharp:60372,portrait_rounded:983219,portrait_outlined:62145,post_add:58591,post_add_sharp:60373,post_add_rounded:983220,post_add_outlined:62146,power:58592,power_sharp:60377,power_rounded:983223,power_outlined:62149,power_input:58593,power_input_sharp:60374,power_input_rounded:983221,power_input_outlined:62147,power_off:58594,power_off_sharp:60375,power_off_rounded:983222,power_off_outlined:62148,power_settings_new:58595,power_settings_new_sharp:60376,power_settings_new_rounded:983224,power_settings_new_outlined:62150,precision_manufacturing:58596,precision_manufacturing_sharp:60378,precision_manufacturing_rounded:983225,precision_manufacturing_outlined:62151,pregnant_woman:58597,pregnant_woman_sharp:60379,pregnant_woman_rounded:983226,pregnant_woman_outlined:62152,present_to_all:58598,present_to_all_sharp:60380,present_to_all_rounded:983227,present_to_all_outlined:62153,preview:58599,preview_sharp:60381,preview_rounded:983228,preview_outlined:62154,price_change:58600,price_change_sharp:60382,price_change_rounded:983229,price_change_outlined:62155,price_check:58601,price_check_sharp:60383,price_check_rounded:983230,price_check_outlined:62156,print:58602,print_sharp:60385,print_rounded:983232,print_outlined:62158,print_disabled:58603,print_disabled_sharp:60384,print_disabled_rounded:983231,print_disabled_outlined:62157,priority_high:58604,priority_high_sharp:60386,priority_high_rounded:983233,priority_high_outlined:62159,privacy_tip:58605,privacy_tip_sharp:60387,privacy_tip_rounded:983234,privacy_tip_outlined:62160,private_connectivity:984403,private_connectivity_sharp:984156,private_connectivity_rounded:983913,private_connectivity_outlined:984650,production_quantity_limits:58606,production_quantity_limits_sharp:60388,production_quantity_limits_rounded:983235,production_quantity_limits_outlined:62161,propane:985017,propane_sharp:984929,propane_rounded:985105,propane_outlined:984841,propane_tank:985018,propane_tank_sharp:984930,propane_tank_rounded:985106,propane_tank_outlined:984842,psychology:58607,psychology_sharp:60389,psychology_rounded:983236,psychology_outlined:62162,psychology_alt:985203,psychology_alt_sharp:985162,psychology_alt_rounded:985235,psychology_alt_outlined:985265,public:58608,public_sharp:60391,public_rounded:983238,public_outlined:62164,public_off:58609,public_off_sharp:60390,public_off_rounded:983237,public_off_outlined:62163,publish:58610,publish_sharp:60392,publish_rounded:983239,publish_outlined:62165,published_with_changes:58611,published_with_changes_sharp:60393,published_with_changes_rounded:983240,published_with_changes_outlined:62166,punch_clock:984404,punch_clock_sharp:984157,punch_clock_rounded:983914,punch_clock_outlined:984651,push_pin:58612,push_pin_sharp:60394,push_pin_rounded:983241,push_pin_outlined:62167,qr_code:58613,qr_code_sharp:60397,qr_code_rounded:983243,qr_code_outlined:62169,qr_code_2:58614,qr_code_2_sharp:60395,qr_code_2_rounded:983242,qr_code_2_outlined:62168,qr_code_scanner:58615,qr_code_scanner_sharp:60396,qr_code_scanner_rounded:983244,qr_code_scanner_outlined:62170,query_builder:58616,query_builder_sharp:60398,query_builder_rounded:983245,query_builder_outlined:62171,query_stats:58617,query_stats_sharp:60399,query_stats_rounded:983246,query_stats_outlined:62172,question_answer:58618,question_answer_sharp:60400,question_answer_rounded:983247,question_answer_outlined:62173,question_mark:984405,question_mark_sharp:984158,question_mark_rounded:983915,question_mark_outlined:984652,queue:58619,queue_sharp:60403,queue_rounded:983250,queue_outlined:62175,queue_music:58620|R,queue_music_sharp:60401|R,queue_music_rounded:983248|R,queue_music_outlined:62174|R,queue_play_next:58621,queue_play_next_sharp:60402,queue_play_next_rounded:983249,queue_play_next_outlined:62176,quick_contacts_dialer:57740,quick_contacts_dialer_sharp:59529,quick_contacts_dialer_rounded:63080,quick_contacts_dialer_outlined:61307,quick_contacts_mail:57738,quick_contacts_mail_sharp:59527,quick_contacts_mail_rounded:63078,quick_contacts_mail_outlined:61305,quickreply:58622,quickreply_sharp:60404,quickreply_rounded:983251,quickreply_outlined:62177,quiz:58623,quiz_sharp:60405,quiz_rounded:983252,quiz_outlined:62178,quora:984406,quora_sharp:984159,quora_rounded:983916,quora_outlined:984653,r_mobiledata:58624,r_mobiledata_sharp:60406,r_mobiledata_rounded:983253,r_mobiledata_outlined:62179,radar:58625,radar_sharp:60407,radar_rounded:983254,radar_outlined:62180,radio:58626,radio_sharp:60410,radio_rounded:983257,radio_outlined:62183,radio_button_checked:58627,radio_button_checked_sharp:60408,radio_button_checked_rounded:983255,radio_button_checked_outlined:62181,radio_button_off:58628,radio_button_off_sharp:60409,radio_button_off_rounded:983256,radio_button_off_outlined:62182,radio_button_on:58627,radio_button_on_sharp:60408,radio_button_on_rounded:983255,radio_button_on_outlined:62181,radio_button_unchecked:58628,radio_button_unchecked_sharp:60409,radio_button_unchecked_rounded:983256,radio_button_unchecked_outlined:62182,railway_alert:58629,railway_alert_sharp:60411,railway_alert_rounded:983258,railway_alert_outlined:62184,ramen_dining:58630,ramen_dining_sharp:60412,ramen_dining_rounded:983259,ramen_dining_outlined:62185,ramp_left:984407,ramp_left_sharp:984160,ramp_left_rounded:983917,ramp_left_outlined:984654,ramp_right:984408,ramp_right_sharp:984161,ramp_right_rounded:983918,ramp_right_outlined:984655,rate_review:58631,rate_review_sharp:60413,rate_review_rounded:983260,rate_review_outlined:62186,raw_off:58632,raw_off_sharp:60414,raw_off_rounded:983261,raw_off_outlined:62187,raw_on:58633,raw_on_sharp:60415,raw_on_rounded:983262,raw_on_outlined:62188,read_more:58634,read_more_sharp:60416,read_more_rounded:983263,read_more_outlined:62189,real_estate_agent:58635,real_estate_agent_sharp:60417,real_estate_agent_rounded:983264,real_estate_agent_outlined:62190,rebase_edit:985204,receipt:58636,receipt_sharp:60419,receipt_rounded:983266,receipt_outlined:62192,receipt_long:58637,receipt_long_sharp:60418,receipt_long_rounded:983265,receipt_long_outlined:62191,recent_actors:58638,recent_actors_sharp:60420,recent_actors_rounded:983267,recent_actors_outlined:62193,recommend:58639,recommend_sharp:60421,recommend_rounded:983268,recommend_outlined:62194,record_voice_over:58640,record_voice_over_sharp:60422,record_voice_over_rounded:983269,record_voice_over_outlined:62195,rectangle:984409,rectangle_sharp:984162,rectangle_rounded:983919,rectangle_outlined:984656,recycling:984410,recycling_sharp:984163,recycling_rounded:983920,recycling_outlined:984657,reddit:984411,reddit_sharp:984164,reddit_rounded:983921,reddit_outlined:984658,redeem:58641,redeem_sharp:60423,redeem_rounded:983270,redeem_outlined:62196,redo:58642|R,redo_sharp:60424|R,redo_rounded:983271|R,redo_outlined:62197|R,reduce_capacity:58643,reduce_capacity_sharp:60425,reduce_capacity_rounded:983272,reduce_capacity_outlined:62198,refresh:58644,refresh_sharp:60426,refresh_rounded:983273,refresh_outlined:62199,remember_me:58645,remember_me_sharp:60427,remember_me_rounded:983274,remember_me_outlined:62200,remove:58646,remove_sharp:60434,remove_rounded:983281,remove_outlined:62206,remove_circle:58647,remove_circle_sharp:60429,remove_circle_rounded:983276,remove_circle_outlined:62202,remove_circle_outline:58648,remove_circle_outline_sharp:60428,remove_circle_outline_rounded:983275,remove_circle_outline_outlined:62201,remove_done:58649,remove_done_sharp:60430,remove_done_rounded:983277,remove_done_outlined:62203,remove_from_queue:58650,remove_from_queue_sharp:60431,remove_from_queue_rounded:983278,remove_from_queue_outlined:62204,remove_moderator:58651,remove_moderator_sharp:60432,remove_moderator_rounded:983279,remove_moderator_outlined:62205,remove_red_eye:58652,remove_red_eye_sharp:60433,remove_red_eye_rounded:983280,remove_red_eye_outlined:62207,remove_road:985019,remove_road_sharp:984931,remove_road_rounded:985107,remove_road_outlined:984843,remove_shopping_cart:58653,remove_shopping_cart_sharp:60435,remove_shopping_cart_rounded:983282,remove_shopping_cart_outlined:62208,reorder:58654,reorder_sharp:60436,reorder_rounded:983283,reorder_outlined:62209,repartition:985205,repartition_sharp:985163,repartition_rounded:985236,repartition_outlined:985266,repeat:58655,repeat_sharp:60440,repeat_rounded:983287,repeat_outlined:62213,repeat_on:58656,repeat_on_sharp:60437,repeat_on_rounded:983284,repeat_on_outlined:62210,repeat_one:58657,repeat_one_sharp:60439,repeat_one_rounded:983286,repeat_one_outlined:62212,repeat_one_on:58658,repeat_one_on_sharp:60438,repeat_one_on_rounded:983285,repeat_one_on_outlined:62211,replay:58659,replay_sharp:60445,replay_rounded:983292,replay_outlined:62218,replay_10:58660,replay_10_sharp:60441,replay_10_rounded:983288,replay_10_outlined:62214,replay_30:58661,replay_30_sharp:60442,replay_30_rounded:983289,replay_30_outlined:62215,replay_5:58662,replay_5_sharp:60443,replay_5_rounded:983290,replay_5_outlined:62216,replay_circle_filled:58663,replay_circle_filled_sharp:60444,replay_circle_filled_rounded:983291,replay_circle_filled_outlined:62217,reply:58664|R,reply_sharp:60447|R,reply_rounded:983294|R,reply_outlined:62220|R,reply_all:58665|R,reply_all_sharp:60446|R,reply_all_rounded:983293|R,reply_all_outlined:62219|R,report:58666,report_sharp:60451,report_rounded:983298,report_outlined:62223,report_gmailerrorred:58667,report_gmailerrorred_sharp:60448,report_gmailerrorred_rounded:983295,report_gmailerrorred_outlined:62221,report_off:58668,report_off_sharp:60449,report_off_rounded:983296,report_off_outlined:62222,report_problem:58669,report_problem_sharp:60450,report_problem_rounded:983297,report_problem_outlined:62224,request_page:58670,request_page_sharp:60452,request_page_rounded:983299,request_page_outlined:62225,request_quote:58671,request_quote_sharp:60453,request_quote_rounded:983300,request_quote_outlined:62226,reset_tv:58672,reset_tv_sharp:60454,reset_tv_rounded:983301,reset_tv_outlined:62227,restart_alt:58673,restart_alt_sharp:60455,restart_alt_rounded:983302,restart_alt_outlined:62228,restaurant:58674,restaurant_sharp:60457,restaurant_rounded:983304,restaurant_outlined:62230,restaurant_menu:58675,restaurant_menu_sharp:60456,restaurant_menu_rounded:983303,restaurant_menu_outlined:62229,restore:58676,restore_sharp:60460,restore_rounded:983307,restore_outlined:62232,restore_from_trash:58677,restore_from_trash_sharp:60458,restore_from_trash_rounded:983305,restore_from_trash_outlined:62231,restore_page:58678,restore_page_sharp:60459,restore_page_rounded:983306,restore_page_outlined:62233,reviews:58679,reviews_sharp:60461,reviews_rounded:983308,reviews_outlined:62234,rice_bowl:58680,rice_bowl_sharp:60462,rice_bowl_rounded:983309,rice_bowl_outlined:62235,ring_volume:58681,ring_volume_sharp:60463,ring_volume_rounded:983310,ring_volume_outlined:62236,rocket:984412,rocket_sharp:984166,rocket_rounded:983923,rocket_outlined:984660,rocket_launch:984413,rocket_launch_sharp:984165,rocket_launch_rounded:983922,rocket_launch_outlined:984659,roller_shades:985020,roller_shades_sharp:984933,roller_shades_rounded:985109,roller_shades_outlined:984845,roller_shades_closed:985021,roller_shades_closed_sharp:984932,roller_shades_closed_rounded:985108,roller_shades_closed_outlined:984844,roller_skating:984768,roller_skating_sharp:984755,roller_skating_rounded:984781,roller_skating_outlined:984742,roofing:58682,roofing_sharp:60464,roofing_rounded:983311,roofing_outlined:62237,room:58683,room_sharp:60467,room_rounded:983313,room_outlined:62238,room_preferences:58684,room_preferences_sharp:60465,room_preferences_rounded:983312,room_preferences_outlined:62239,room_service:58685,room_service_sharp:60466,room_service_rounded:983314,room_service_outlined:62240,rotate_90_degrees_ccw:58686,rotate_90_degrees_ccw_sharp:60468,rotate_90_degrees_ccw_rounded:983315,rotate_90_degrees_ccw_outlined:62241,rotate_90_degrees_cw:984414,rotate_90_degrees_cw_sharp:984167,rotate_90_degrees_cw_rounded:983924,rotate_90_degrees_cw_outlined:984661,rotate_left:58687,rotate_left_sharp:60469,rotate_left_rounded:983316,rotate_left_outlined:62242,rotate_right:58688,rotate_right_sharp:60470,rotate_right_rounded:983317,rotate_right_outlined:62243,roundabout_left:984415,roundabout_left_sharp:984168,roundabout_left_rounded:983925,roundabout_left_outlined:984662,roundabout_right:984416,roundabout_right_sharp:984169,roundabout_right_rounded:983926,roundabout_right_outlined:984663,rounded_corner:58689,rounded_corner_sharp:60471,rounded_corner_rounded:983318,rounded_corner_outlined:62244,route:984417,route_sharp:984170,route_rounded:983927,route_outlined:984664,router:58690,router_sharp:60472,router_rounded:983319,router_outlined:62245,rowing:58691,rowing_sharp:60473,rowing_rounded:983320,rowing_outlined:62246,rss_feed:58692,rss_feed_sharp:60474,rss_feed_rounded:983321,rss_feed_outlined:62247,rsvp:58693,rsvp_sharp:60475,rsvp_rounded:983322,rsvp_outlined:62248,rtt:58694,rtt_sharp:60476,rtt_rounded:983323,rtt_outlined:62249,rule:58695,rule_sharp:60478,rule_rounded:983325,rule_outlined:62251,rule_folder:58696,rule_folder_sharp:60477,rule_folder_rounded:983324,rule_folder_outlined:62250,run_circle:58697,run_circle_sharp:60479,run_circle_rounded:983326,run_circle_outlined:62252,running_with_errors:58698,running_with_errors_sharp:60480,running_with_errors_rounded:983327,running_with_errors_outlined:62253,rv_hookup:58699,rv_hookup_sharp:60481,rv_hookup_rounded:983328,rv_hookup_outlined:62254,safety_check:985022,safety_check_sharp:984934,safety_check_rounded:985110,safety_check_outlined:984846,safety_divider:58700,safety_divider_sharp:60482,safety_divider_rounded:983329,safety_divider_outlined:62255,sailing:58701,sailing_sharp:60483,sailing_rounded:983330,sailing_outlined:62256,sanitizer:58702,sanitizer_sharp:60484,sanitizer_rounded:983331,sanitizer_outlined:62257,satellite:58703,satellite_sharp:60485,satellite_rounded:983332,satellite_outlined:62258,satellite_alt:984418,satellite_alt_sharp:984171,satellite_alt_rounded:983928,satellite_alt_outlined:984665,save:58704,save_sharp:60487,save_rounded:983334,save_outlined:62260,save_alt:58705,save_alt_sharp:60486,save_alt_rounded:983333,save_alt_outlined:62259,save_as:984419,save_as_sharp:984172,save_as_rounded:983929,save_as_outlined:984666,saved_search:58706,saved_search_sharp:60488,saved_search_rounded:983335,saved_search_outlined:62261,savings:58707,savings_sharp:60489,savings_rounded:983336,savings_outlined:62262,scale:984420,scale_sharp:984173,scale_rounded:983930,scale_outlined:984667,scanner:58708,scanner_sharp:60490,scanner_rounded:983337,scanner_outlined:62263,scatter_plot:58709,scatter_plot_sharp:60491,scatter_plot_rounded:983338,scatter_plot_outlined:62264,schedule:58710,schedule_sharp:60493,schedule_rounded:983339,schedule_outlined:62265,schedule_send:58711,schedule_send_sharp:60492,schedule_send_rounded:983340,schedule_send_outlined:62266,schema:58712,schema_sharp:60494,schema_rounded:983341,schema_outlined:62267,school:58713,school_sharp:60495,school_rounded:983342,school_outlined:62268,science:58714,science_sharp:60496,science_rounded:983343,science_outlined:62269,score:58715,score_sharp:60497,score_rounded:983344,score_outlined:62270,scoreboard:984769,scoreboard_sharp:984756,scoreboard_rounded:984782,scoreboard_outlined:984743,screen_lock_landscape:58716,screen_lock_landscape_sharp:60498,screen_lock_landscape_rounded:983345,screen_lock_landscape_outlined:62271,screen_lock_portrait:58717,screen_lock_portrait_sharp:60499,screen_lock_portrait_rounded:983346,screen_lock_portrait_outlined:62272,screen_lock_rotation:58718,screen_lock_rotation_sharp:60500,screen_lock_rotation_rounded:983347,screen_lock_rotation_outlined:62273,screen_rotation:58719,screen_rotation_sharp:60501,screen_rotation_rounded:983348,screen_rotation_outlined:62274,screen_rotation_alt:985023,screen_rotation_alt_sharp:984935,screen_rotation_alt_rounded:985111,screen_rotation_alt_outlined:984847,screen_search_desktop:58720,screen_search_desktop_sharp:60502,screen_search_desktop_rounded:983349,screen_search_desktop_outlined:62275,screen_share:58721|R,screen_share_sharp:60503|R,screen_share_rounded:983350|R,screen_share_outlined:62276|R,screenshot:58722,screenshot_sharp:60504,screenshot_rounded:983351,screenshot_outlined:62277,screenshot_monitor:985024,screenshot_monitor_sharp:984936,screenshot_monitor_rounded:985112,screenshot_monitor_outlined:984848,scuba_diving:984770,scuba_diving_sharp:984757,scuba_diving_rounded:984783,scuba_diving_outlined:984744,sd:58723,sd_sharp:60507,sd_rounded:983354,sd_outlined:62280,sd_card:58724,sd_card_sharp:60506,sd_card_rounded:983353,sd_card_outlined:62279,sd_card_alert:58725,sd_card_alert_sharp:60505,sd_card_alert_rounded:983352,sd_card_alert_outlined:62278,sd_storage:58726,sd_storage_sharp:60508,sd_storage_rounded:983355,sd_storage_outlined:62281,search:58727,search_sharp:60510,search_rounded:983357,search_outlined:62283,search_off:58728,search_off_sharp:60509,search_off_rounded:983356,search_off_outlined:62282,security:58729,security_sharp:60511,security_rounded:983358,security_outlined:62284,security_update:58730,security_update_sharp:60513,security_update_rounded:983360,security_update_outlined:62286,security_update_good:58731,security_update_good_sharp:60512,security_update_good_rounded:983359,security_update_good_outlined:62285,security_update_warning:58732,security_update_warning_sharp:60514,security_update_warning_rounded:983361,security_update_warning_outlined:62287,segment:58733,segment_sharp:60515,segment_rounded:983362,segment_outlined:62288,select_all:58734,select_all_sharp:60516,select_all_rounded:983363,select_all_outlined:62289,self_improvement:58735,self_improvement_sharp:60517,self_improvement_rounded:983364,self_improvement_outlined:62290,sell:58736,sell_sharp:60518,sell_rounded:983365,sell_outlined:62291,send:58737|R,send_sharp:60520|R,send_rounded:983367|R,send_outlined:62293|R,send_and_archive:58738,send_and_archive_sharp:60519,send_and_archive_rounded:983366,send_and_archive_outlined:62292,send_time_extension:984421,send_time_extension_sharp:984174,send_time_extension_rounded:983931,send_time_extension_outlined:984668,send_to_mobile:58739,send_to_mobile_sharp:60521,send_to_mobile_rounded:983368,send_to_mobile_outlined:62294,sensor_door:58740,sensor_door_sharp:60522,sensor_door_rounded:983369,sensor_door_outlined:62295,sensor_occupied:985025,sensor_occupied_sharp:984937,sensor_occupied_rounded:985113,sensor_occupied_outlined:984849,sensor_window:58741,sensor_window_sharp:60523,sensor_window_rounded:983370,sensor_window_outlined:62296,sensors:58742,sensors_sharp:60525,sensors_rounded:983372,sensors_outlined:62298,sensors_off:58743,sensors_off_sharp:60524,sensors_off_rounded:983371,sensors_off_outlined:62297,sentiment_dissatisfied:58744,sentiment_dissatisfied_sharp:60526,sentiment_dissatisfied_rounded:983373,sentiment_dissatisfied_outlined:62299,sentiment_neutral:58745,sentiment_neutral_sharp:60527,sentiment_neutral_rounded:983374,sentiment_neutral_outlined:62300,sentiment_satisfied:58746,sentiment_satisfied_sharp:60529,sentiment_satisfied_rounded:983376,sentiment_satisfied_outlined:62302,sentiment_satisfied_alt:58747,sentiment_satisfied_alt_sharp:60528,sentiment_satisfied_alt_rounded:983375,sentiment_satisfied_alt_outlined:62301,sentiment_very_dissatisfied:58748,sentiment_very_dissatisfied_sharp:60530,sentiment_very_dissatisfied_rounded:983377,sentiment_very_dissatisfied_outlined:62303,sentiment_very_satisfied:58749,sentiment_very_satisfied_sharp:60531,sentiment_very_satisfied_rounded:983378,sentiment_very_satisfied_outlined:62304,set_meal:58750,set_meal_sharp:60532,set_meal_rounded:983379,set_meal_outlined:62305,settings:58751,settings_sharp:60549,settings_rounded:983396,settings_outlined:62318,settings_accessibility:58752,settings_accessibility_sharp:60533,settings_accessibility_rounded:983380,settings_accessibility_outlined:62306,settings_applications:58753,settings_applications_sharp:60534,settings_applications_rounded:983381,settings_applications_outlined:62307,settings_backup_restore:58754,settings_backup_restore_sharp:60535,settings_backup_restore_rounded:983382,settings_backup_restore_outlined:62308,settings_bluetooth:58755,settings_bluetooth_sharp:60536,settings_bluetooth_rounded:983383,settings_bluetooth_outlined:62309,settings_brightness:58756,settings_brightness_sharp:60537,settings_brightness_rounded:983384,settings_brightness_outlined:62310,settings_cell:58757,settings_cell_sharp:60538,settings_cell_rounded:983385,settings_cell_outlined:62311,settings_display:58756,settings_display_sharp:60537,settings_display_rounded:983384,settings_display_outlined:62310,settings_ethernet:58758,settings_ethernet_sharp:60539,settings_ethernet_rounded:983386,settings_ethernet_outlined:62312,settings_input_antenna:58759,settings_input_antenna_sharp:60540,settings_input_antenna_rounded:983387,settings_input_antenna_outlined:62313,settings_input_component:58760,settings_input_component_sharp:60541,settings_input_component_rounded:983388,settings_input_component_outlined:62314,settings_input_composite:58761,settings_input_composite_sharp:60542,settings_input_composite_rounded:983389,settings_input_composite_outlined:62315,settings_input_hdmi:58762,settings_input_hdmi_sharp:60543,settings_input_hdmi_rounded:983390,settings_input_hdmi_outlined:62316,settings_input_svideo:58763,settings_input_svideo_sharp:60544,settings_input_svideo_rounded:983391,settings_input_svideo_outlined:62317,settings_overscan:58764,settings_overscan_sharp:60545,settings_overscan_rounded:983392,settings_overscan_outlined:62319,settings_phone:58765,settings_phone_sharp:60546,settings_phone_rounded:983393,settings_phone_outlined:62320,settings_power:58766,settings_power_sharp:60547,settings_power_rounded:983394,settings_power_outlined:62321,settings_remote:58767,settings_remote_sharp:60548,settings_remote_rounded:983395,settings_remote_outlined:62322,settings_suggest:58768,settings_suggest_sharp:60550,settings_suggest_rounded:983397,settings_suggest_outlined:62323,settings_system_daydream:58769,settings_system_daydream_sharp:60551,settings_system_daydream_rounded:983398,settings_system_daydream_outlined:62324,settings_voice:58770,settings_voice_sharp:60552,settings_voice_rounded:983399,settings_voice_outlined:62325,severe_cold:985026,severe_cold_sharp:984938,severe_cold_rounded:985114,severe_cold_outlined:984850,shape_line:985206,shape_line_sharp:985164,shape_line_rounded:985237,shape_line_outlined:985267,share:58771,share_sharp:60555,share_rounded:983402,share_outlined:62328,share_arrival_time:58772,share_arrival_time_sharp:60553,share_arrival_time_rounded:983400,share_arrival_time_outlined:62326,share_location:58773,share_location_sharp:60554,share_location_rounded:983401,share_location_outlined:62327,shelves:985207,shield:58774,shield_sharp:60556,shield_rounded:983403,shield_outlined:62329,shield_moon:984422,shield_moon_sharp:984175,shield_moon_rounded:983932,shield_moon_outlined:984669,shop:58775,shop_sharp:60558,shop_rounded:983405,shop_outlined:62331,shop_2:58776,shop_2_sharp:60557,shop_2_rounded:983404,shop_2_outlined:62330,shop_two:58777,shop_two_sharp:60559,shop_two_rounded:983406,shop_two_outlined:62332,shopify:984423,shopify_sharp:984176,shopify_rounded:983933,shopify_outlined:984670,shopping_bag:58778,shopping_bag_sharp:60560,shopping_bag_rounded:983407,shopping_bag_outlined:62333,shopping_basket:58779,shopping_basket_sharp:60561,shopping_basket_rounded:983408,shopping_basket_outlined:62334,shopping_cart:58780,shopping_cart_sharp:60562,shopping_cart_rounded:983409,shopping_cart_outlined:62335,shopping_cart_checkout:984424,shopping_cart_checkout_sharp:984177,shopping_cart_checkout_rounded:983934,shopping_cart_checkout_outlined:984671,short_text:58781|R,short_text_sharp:60563|R,short_text_rounded:983410|R,short_text_outlined:62336|R,shortcut:58782,shortcut_sharp:60564,shortcut_rounded:983411,shortcut_outlined:62337,show_chart:58783|R,show_chart_sharp:60565|R,show_chart_rounded:983412|R,show_chart_outlined:62338|R,shower:58784,shower_sharp:60566,shower_rounded:983413,shower_outlined:62339,shuffle:58785,shuffle_sharp:60568,shuffle_rounded:983415,shuffle_outlined:62341,shuffle_on:58786,shuffle_on_sharp:60567,shuffle_on_rounded:983414,shuffle_on_outlined:62340,shutter_speed:58787,shutter_speed_sharp:60569,shutter_speed_rounded:983416,shutter_speed_outlined:62342,sick:58788,sick_sharp:60570,sick_rounded:983417,sick_outlined:62343,sign_language:985027,sign_language_sharp:984939,sign_language_rounded:985115,sign_language_outlined:984851,signal_cellular_0_bar:58789,signal_cellular_0_bar_sharp:60571,signal_cellular_0_bar_rounded:983418,signal_cellular_0_bar_outlined:62344,signal_cellular_4_bar:58790,signal_cellular_4_bar_sharp:60572,signal_cellular_4_bar_rounded:983419,signal_cellular_4_bar_outlined:62345,signal_cellular_alt:58791,signal_cellular_alt_sharp:60573,signal_cellular_alt_rounded:983420,signal_cellular_alt_outlined:62346,signal_cellular_alt_1_bar:985028,signal_cellular_alt_1_bar_sharp:984940,signal_cellular_alt_1_bar_rounded:985116,signal_cellular_alt_1_bar_outlined:984852,signal_cellular_alt_2_bar:985029,signal_cellular_alt_2_bar_sharp:984941,signal_cellular_alt_2_bar_rounded:985117,signal_cellular_alt_2_bar_outlined:984853,signal_cellular_connected_no_internet_0_bar:58792,signal_cellular_connected_no_internet_0_bar_sharp:60574,signal_cellular_connected_no_internet_0_bar_rounded:983421,signal_cellular_connected_no_internet_0_bar_outlined:62347,signal_cellular_connected_no_internet_4_bar:58793,signal_cellular_connected_no_internet_4_bar_sharp:60575,signal_cellular_connected_no_internet_4_bar_rounded:983422,signal_cellular_connected_no_internet_4_bar_outlined:62348,signal_cellular_no_sim:58794,signal_cellular_no_sim_sharp:60576,signal_cellular_no_sim_rounded:983423,signal_cellular_no_sim_outlined:62349,signal_cellular_nodata:58795,signal_cellular_nodata_sharp:60577,signal_cellular_nodata_rounded:983424,signal_cellular_nodata_outlined:62350,signal_cellular_null:58796,signal_cellular_null_sharp:60578,signal_cellular_null_rounded:983425,signal_cellular_null_outlined:62351,signal_cellular_off:58797,signal_cellular_off_sharp:60579,signal_cellular_off_rounded:983426,signal_cellular_off_outlined:62352,signal_wifi_0_bar:58798,signal_wifi_0_bar_sharp:60580,signal_wifi_0_bar_rounded:983427,signal_wifi_0_bar_outlined:62353,signal_wifi_4_bar:58799,signal_wifi_4_bar_sharp:60582,signal_wifi_4_bar_rounded:983429,signal_wifi_4_bar_outlined:62355,signal_wifi_4_bar_lock:58800,signal_wifi_4_bar_lock_sharp:60581,signal_wifi_4_bar_lock_rounded:983428,signal_wifi_4_bar_lock_outlined:62354,signal_wifi_bad:58801,signal_wifi_bad_sharp:60583,signal_wifi_bad_rounded:983430,signal_wifi_bad_outlined:62356,signal_wifi_connected_no_internet_4:58802,signal_wifi_connected_no_internet_4_sharp:60584,signal_wifi_connected_no_internet_4_rounded:983431,signal_wifi_connected_no_internet_4_outlined:62357,signal_wifi_off:58803,signal_wifi_off_sharp:60585,signal_wifi_off_rounded:983432,signal_wifi_off_outlined:62358,signal_wifi_statusbar_4_bar:58804,signal_wifi_statusbar_4_bar_sharp:60586,signal_wifi_statusbar_4_bar_rounded:983433,signal_wifi_statusbar_4_bar_outlined:62359,signal_wifi_statusbar_connected_no_internet_4:58805,signal_wifi_statusbar_connected_no_internet_4_sharp:60587,signal_wifi_statusbar_connected_no_internet_4_rounded:983434,signal_wifi_statusbar_connected_no_internet_4_outlined:62360,signal_wifi_statusbar_null:58806,signal_wifi_statusbar_null_sharp:60588,signal_wifi_statusbar_null_rounded:983435,signal_wifi_statusbar_null_outlined:62361,signpost:984425,signpost_sharp:984178,signpost_rounded:983935,signpost_outlined:984672,sim_card:58807,sim_card_sharp:60591,sim_card_rounded:983438,sim_card_outlined:62364,sim_card_alert:58808,sim_card_alert_sharp:60589,sim_card_alert_rounded:983436,sim_card_alert_outlined:62362,sim_card_download:58809,sim_card_download_sharp:60590,sim_card_download_rounded:983437,sim_card_download_outlined:62363,single_bed:58810,single_bed_sharp:60592,single_bed_rounded:983439,single_bed_outlined:62365,sip:58811,sip_sharp:60593,sip_rounded:983440,sip_outlined:62366,skateboarding:58812,skateboarding_sharp:60594,skateboarding_rounded:983441,skateboarding_outlined:62367,skip_next:58813,skip_next_sharp:60595,skip_next_rounded:983442,skip_next_outlined:62368,skip_previous:58814,skip_previous_sharp:60596,skip_previous_rounded:983443,skip_previous_outlined:62369,sledding:58815,sledding_sharp:60597,sledding_rounded:983444,sledding_outlined:62370,slideshow:58816,slideshow_sharp:60598,slideshow_rounded:983445,slideshow_outlined:62371,slow_motion_video:58817,slow_motion_video_sharp:60599,slow_motion_video_rounded:983446,slow_motion_video_outlined:62372,smart_button:58818,smart_button_sharp:60600,smart_button_rounded:983447,smart_button_outlined:62373,smart_display:58819,smart_display_sharp:60601,smart_display_rounded:983448,smart_display_outlined:62374,smart_screen:58820,smart_screen_sharp:60602,smart_screen_rounded:983449,smart_screen_outlined:62375,smart_toy:58821,smart_toy_sharp:60603,smart_toy_rounded:983450,smart_toy_outlined:62376,smartphone:58822,smartphone_sharp:60604,smartphone_rounded:983451,smartphone_outlined:62377,smoke_free:58823,smoke_free_sharp:60605,smoke_free_rounded:983452,smoke_free_outlined:62378,smoking_rooms:58824,smoking_rooms_sharp:60606,smoking_rooms_rounded:983453,smoking_rooms_outlined:62379,sms:58825,sms_sharp:60608,sms_rounded:983455,sms_outlined:62381,sms_failed:58826,sms_failed_sharp:60607,sms_failed_rounded:983454,sms_failed_outlined:62380,snapchat:984426,snapchat_sharp:984179,snapchat_rounded:983936,snapchat_outlined:984673,snippet_folder:58827,snippet_folder_sharp:60609,snippet_folder_rounded:983456,snippet_folder_outlined:62382,snooze:58828,snooze_sharp:60610,snooze_rounded:983457,snooze_outlined:62383,snowboarding:58829,snowboarding_sharp:60611,snowboarding_rounded:983458,snowboarding_outlined:62384,snowing:984427,snowmobile:58830,snowmobile_sharp:60612,snowmobile_rounded:983459,snowmobile_outlined:62385,snowshoeing:58831,snowshoeing_sharp:60613,snowshoeing_rounded:983460,snowshoeing_outlined:62386,soap:58832,soap_sharp:60614,soap_rounded:983461,soap_outlined:62387,social_distance:58833,social_distance_sharp:60615,social_distance_rounded:983462,social_distance_outlined:62388,solar_power:985030,solar_power_sharp:984942,solar_power_rounded:985118,solar_power_outlined:984854,sort:58834|R,sort_sharp:60617|R,sort_rounded:983464|R,sort_outlined:62390|R,sort_by_alpha:58835,sort_by_alpha_sharp:60616,sort_by_alpha_rounded:983463,sort_by_alpha_outlined:62389,sos:985031,sos_sharp:984943,sos_rounded:985119,sos_outlined:984855,soup_kitchen:984428,soup_kitchen_sharp:984180,soup_kitchen_rounded:983937,soup_kitchen_outlined:984674,source:58836,source_sharp:60618,source_rounded:983465,source_outlined:62391,south:58837,south_sharp:60620,south_rounded:983467,south_outlined:62393,south_america:984429,south_america_sharp:984181,south_america_rounded:983938,south_america_outlined:984675,south_east:58838,south_east_sharp:60619,south_east_rounded:983466,south_east_outlined:62392,south_west:58839,south_west_sharp:60621,south_west_rounded:983468,south_west_outlined:62394,spa:58840,spa_sharp:60622,spa_rounded:983469,spa_outlined:62395,space_bar:58841,space_bar_sharp:60623,space_bar_rounded:983470,space_bar_outlined:62396,space_dashboard:58842,space_dashboard_sharp:60624,space_dashboard_rounded:983471,space_dashboard_outlined:62397,spatial_audio:985032,spatial_audio_sharp:984945,spatial_audio_rounded:985121,spatial_audio_outlined:984857,spatial_audio_off:985033,spatial_audio_off_sharp:984944,spatial_audio_off_rounded:985120,spatial_audio_off_outlined:984856,spatial_tracking:985034,spatial_tracking_sharp:984946,spatial_tracking_rounded:985122,spatial_tracking_outlined:984858,speaker:58843,speaker_sharp:60629,speaker_rounded:983476,speaker_outlined:62401,speaker_group:58844,speaker_group_sharp:60625,speaker_group_rounded:983472,speaker_group_outlined:62398,speaker_notes:58845,speaker_notes_sharp:60627,speaker_notes_rounded:983474,speaker_notes_outlined:62400,speaker_notes_off:58846,speaker_notes_off_sharp:60626,speaker_notes_off_rounded:983473,speaker_notes_off_outlined:62399,speaker_phone:58847,speaker_phone_sharp:60628,speaker_phone_rounded:983475,speaker_phone_outlined:62402,speed:58848,speed_sharp:60630,speed_rounded:983477,speed_outlined:62403,spellcheck:58849,spellcheck_sharp:60631,spellcheck_rounded:983478,spellcheck_outlined:62404,splitscreen:58850,splitscreen_sharp:60632,splitscreen_rounded:983479,splitscreen_outlined:62405,spoke:984430,spoke_sharp:984182,spoke_rounded:983939,spoke_outlined:984676,sports:58851,sports_sharp:60647,sports_rounded:983492,sports_outlined:62418,sports_bar:58852,sports_bar_sharp:60633,sports_bar_rounded:983480,sports_bar_outlined:62406,sports_baseball:58853,sports_baseball_sharp:60634,sports_baseball_rounded:983481,sports_baseball_outlined:62407,sports_basketball:58854,sports_basketball_sharp:60635,sports_basketball_rounded:983482,sports_basketball_outlined:62408,sports_cricket:58855,sports_cricket_sharp:60636,sports_cricket_rounded:983483,sports_cricket_outlined:62409,sports_esports:58856,sports_esports_sharp:60637,sports_esports_rounded:983484,sports_esports_outlined:62410,sports_football:58857,sports_football_sharp:60638,sports_football_rounded:983485,sports_football_outlined:62411,sports_golf:58858,sports_golf_sharp:60639,sports_golf_rounded:983486,sports_golf_outlined:62412,sports_gymnastics:984771,sports_gymnastics_sharp:984758,sports_gymnastics_rounded:984784,sports_gymnastics_outlined:984745,sports_handball:58859,sports_handball_sharp:60640,sports_handball_rounded:983487,sports_handball_outlined:62413,sports_hockey:58860,sports_hockey_sharp:60641,sports_hockey_rounded:983488,sports_hockey_outlined:62414,sports_kabaddi:58861,sports_kabaddi_sharp:60642,sports_kabaddi_rounded:983489,sports_kabaddi_outlined:62415,sports_martial_arts:984431,sports_martial_arts_sharp:984183,sports_martial_arts_rounded:983940,sports_martial_arts_outlined:984677,sports_mma:58862,sports_mma_sharp:60643,sports_mma_rounded:983490,sports_mma_outlined:62416,sports_motorsports:58863,sports_motorsports_sharp:60644,sports_motorsports_rounded:983491,sports_motorsports_outlined:62417,sports_rugby:58864,sports_rugby_sharp:60645,sports_rugby_rounded:983493,sports_rugby_outlined:62419,sports_score:58865,sports_score_sharp:60646,sports_score_rounded:983494,sports_score_outlined:62420,sports_soccer:58866,sports_soccer_sharp:60648,sports_soccer_rounded:983495,sports_soccer_outlined:62421,sports_tennis:58867,sports_tennis_sharp:60649,sports_tennis_rounded:983496,sports_tennis_outlined:62422,sports_volleyball:58868,sports_volleyball_sharp:60650,sports_volleyball_rounded:983497,sports_volleyball_outlined:62423,square:984432,square_sharp:984184,square_rounded:983941,square_outlined:984678,square_foot:58869,square_foot_sharp:60651,square_foot_rounded:983498,square_foot_outlined:62424,ssid_chart:984433,ssid_chart_sharp:984185,ssid_chart_rounded:983942,ssid_chart_outlined:984679,stacked_bar_chart:58870,stacked_bar_chart_sharp:60652,stacked_bar_chart_rounded:983499,stacked_bar_chart_outlined:62425,stacked_line_chart:58871,stacked_line_chart_sharp:60653,stacked_line_chart_rounded:983500,stacked_line_chart_outlined:62426,stadium:984434,stadium_sharp:984186,stadium_rounded:983943,stadium_outlined:984680,stairs:58872,stairs_sharp:60654,stairs_rounded:983501,stairs_outlined:62427,star:58873,star_sharp:60661,star_rounded:983508,star_outlined:62432,star_border:58874,star_border_sharp:60656,star_border_rounded:983503,star_border_outlined:62428,star_border_purple500:58875,star_border_purple500_sharp:60655,star_border_purple500_rounded:983502,star_border_purple500_outlined:62429,star_half:58876|R,star_half_sharp:60657|R,star_half_rounded:983504|R,star_half_outlined:62430|R,star_outline:58877,star_outline_sharp:60658,star_outline_rounded:983505,star_outline_outlined:62431,star_purple500:58878,star_purple500_sharp:60659,star_purple500_rounded:983506,star_purple500_outlined:62433,star_rate:58879,star_rate_sharp:60660,star_rate_rounded:983507,star_rate_outlined:62434,stars:58880,stars_sharp:60662,stars_rounded:983509,stars_outlined:62435,start:984435,start_sharp:984187,start_rounded:983944,start_outlined:984681,stay_current_landscape:58881,stay_current_landscape_sharp:60663,stay_current_landscape_rounded:983510,stay_current_landscape_outlined:62436,stay_current_portrait:58882,stay_current_portrait_sharp:60664,stay_current_portrait_rounded:983511,stay_current_portrait_outlined:62437,stay_primary_landscape:58883,stay_primary_landscape_sharp:60665,stay_primary_landscape_rounded:983512,stay_primary_landscape_outlined:62438,stay_primary_portrait:58884,stay_primary_portrait_sharp:60666,stay_primary_portrait_rounded:983513,stay_primary_portrait_outlined:62439,sticky_note_2:58885,sticky_note_2_sharp:60667,sticky_note_2_rounded:983514,sticky_note_2_outlined:62440,stop:58886,stop_sharp:60670,stop_rounded:983516,stop_outlined:62442,stop_circle:58887,stop_circle_sharp:60668,stop_circle_rounded:983515,stop_circle_outlined:62441,stop_screen_share:58888,stop_screen_share_sharp:60669,stop_screen_share_rounded:983517,stop_screen_share_outlined:62443,storage:58889,storage_sharp:60671,storage_rounded:983518,storage_outlined:62444,store:58890,store_sharp:60673,store_rounded:983520,store_outlined:62446,store_mall_directory:58891,store_mall_directory_sharp:60672,store_mall_directory_rounded:983519,store_mall_directory_outlined:62445,storefront:58892,storefront_sharp:60674,storefront_rounded:983521,storefront_outlined:62447,storm:58893,storm_sharp:60675,storm_rounded:983522,storm_outlined:62448,straight:984436,straight_sharp:984188,straight_rounded:983945,straight_outlined:984682,straighten:58894,straighten_sharp:60676,straighten_rounded:983523,straighten_outlined:62449,stream:58895,stream_sharp:60677,stream_rounded:983524,stream_outlined:62450,streetview:58896,streetview_sharp:60678,streetview_rounded:983525,streetview_outlined:62451,strikethrough_s:58897,strikethrough_s_sharp:60679,strikethrough_s_rounded:983526,strikethrough_s_outlined:62452,stroller:58898,stroller_sharp:60680,stroller_rounded:983527,stroller_outlined:62453,style:58899,style_sharp:60681,style_rounded:983528,style_outlined:62454,subdirectory_arrow_left:58900,subdirectory_arrow_left_sharp:60682,subdirectory_arrow_left_rounded:983529,subdirectory_arrow_left_outlined:62455,subdirectory_arrow_right:58901,subdirectory_arrow_right_sharp:60683,subdirectory_arrow_right_rounded:983530,subdirectory_arrow_right_outlined:62456,subject:58902|R,subject_sharp:60684|R,subject_rounded:983531|R,subject_outlined:62457|R,subscript:58903,subscript_sharp:60685,subscript_rounded:983532,subscript_outlined:62458,subscriptions:58904,subscriptions_sharp:60686,subscriptions_rounded:983533,subscriptions_outlined:62459,subtitles:58905,subtitles_sharp:60688,subtitles_rounded:983535,subtitles_outlined:62461,subtitles_off:58906,subtitles_off_sharp:60687,subtitles_off_rounded:983534,subtitles_off_outlined:62460,subway:58907,subway_sharp:60689,subway_rounded:983536,subway_outlined:62462,summarize:58908,summarize_sharp:60690,summarize_rounded:983537,summarize_outlined:62463,sunny:984437,sunny_snowing:984438,superscript:58909,superscript_sharp:60691,superscript_rounded:983538,superscript_outlined:62464,supervised_user_circle:58910,supervised_user_circle_sharp:60692,supervised_user_circle_rounded:983539,supervised_user_circle_outlined:62465,supervisor_account:58911,supervisor_account_sharp:60693,supervisor_account_rounded:983540,supervisor_account_outlined:62466,support:58912,support_sharp:60695,support_rounded:983542,support_outlined:62468,support_agent:58913,support_agent_sharp:60694,support_agent_rounded:983541,support_agent_outlined:62467,surfing:58914,surfing_sharp:60696,surfing_rounded:983543,surfing_outlined:62469,surround_sound:58915,surround_sound_sharp:60697,surround_sound_rounded:983544,surround_sound_outlined:62470,swap_calls:58916,swap_calls_sharp:60698,swap_calls_rounded:983545,swap_calls_outlined:62471,swap_horiz:58917,swap_horiz_sharp:60699,swap_horiz_rounded:983546,swap_horiz_outlined:62472,swap_horizontal_circle:58918,swap_horizontal_circle_sharp:60700,swap_horizontal_circle_rounded:983547,swap_horizontal_circle_outlined:62473,swap_vert:58919,swap_vert_sharp:60701,swap_vert_rounded:983548,swap_vert_outlined:62474,swap_vert_circle:58920,swap_vert_circle_sharp:60702,swap_vert_circle_rounded:983549,swap_vert_circle_outlined:62475,swap_vertical_circle:58920,swap_vertical_circle_sharp:60702,swap_vertical_circle_rounded:983549,swap_vertical_circle_outlined:62475,swipe:58921,swipe_sharp:60703,swipe_rounded:983550,swipe_outlined:62476,swipe_down:984440,swipe_down_sharp:984190,swipe_down_rounded:983947,swipe_down_outlined:984684,swipe_down_alt:984439,swipe_down_alt_sharp:984189,swipe_down_alt_rounded:983946,swipe_down_alt_outlined:984683,swipe_left:984442,swipe_left_sharp:984192,swipe_left_rounded:983949,swipe_left_outlined:984686,swipe_left_alt:984441,swipe_left_alt_sharp:984191,swipe_left_alt_rounded:983948,swipe_left_alt_outlined:984685,swipe_right:984444,swipe_right_sharp:984194,swipe_right_rounded:983951,swipe_right_outlined:984688,swipe_right_alt:984443,swipe_right_alt_sharp:984193,swipe_right_alt_rounded:983950,swipe_right_alt_outlined:984687,swipe_up:984446,swipe_up_sharp:984196,swipe_up_rounded:983953,swipe_up_outlined:984690,swipe_up_alt:984445,swipe_up_alt_sharp:984195,swipe_up_alt_rounded:983952,swipe_up_alt_outlined:984689,swipe_vertical:984447,swipe_vertical_sharp:984197,swipe_vertical_rounded:983954,swipe_vertical_outlined:984691,switch_access_shortcut:984449,switch_access_shortcut_sharp:984199,switch_access_shortcut_rounded:983956,switch_access_shortcut_outlined:984693,switch_access_shortcut_add:984448,switch_access_shortcut_add_sharp:984198,switch_access_shortcut_add_rounded:983955,switch_access_shortcut_add_outlined:984692,switch_account:58922,switch_account_sharp:60704,switch_account_rounded:983551,switch_account_outlined:62477,switch_camera:58923,switch_camera_sharp:60705,switch_camera_rounded:983552,switch_camera_outlined:62478,switch_left:58924,switch_left_sharp:60706,switch_left_rounded:983553,switch_left_outlined:62479,switch_right:58925,switch_right_sharp:60707,switch_right_rounded:983554,switch_right_outlined:62480,switch_video:58926,switch_video_sharp:60708,switch_video_rounded:983555,switch_video_outlined:62481,synagogue:984450,synagogue_sharp:984200,synagogue_rounded:983957,synagogue_outlined:984694,sync:58927,sync_sharp:60712,sync_rounded:983559,sync_outlined:62484,sync_alt:58928,sync_alt_sharp:60709,sync_alt_rounded:983556,sync_alt_outlined:62482,sync_disabled:58929,sync_disabled_sharp:60710,sync_disabled_rounded:983557,sync_disabled_outlined:62483,sync_lock:984451,sync_lock_sharp:984201,sync_lock_rounded:983958,sync_lock_outlined:984695,sync_problem:58930,sync_problem_sharp:60711,sync_problem_rounded:983558,sync_problem_outlined:62485,system_security_update:58931,system_security_update_sharp:60714,system_security_update_rounded:983561,system_security_update_outlined:62487,system_security_update_good:58932,system_security_update_good_sharp:60713,system_security_update_good_rounded:983560,system_security_update_good_outlined:62486,system_security_update_warning:58933,system_security_update_warning_sharp:60715,system_security_update_warning_rounded:983562,system_security_update_warning_outlined:62488,system_update:58934,system_update_sharp:60717,system_update_rounded:983564,system_update_outlined:62490,system_update_alt:58935,system_update_alt_sharp:60716,system_update_alt_rounded:983563,system_update_alt_outlined:62489,system_update_tv:58935,system_update_tv_sharp:60716,system_update_tv_rounded:983563,system_update_tv_outlined:62489,tab:58936,tab_sharp:60718,tab_rounded:983565,tab_outlined:62491,tab_unselected:58937,tab_unselected_sharp:60719,tab_unselected_rounded:983566,tab_unselected_outlined:62492,table_bar:984452,table_bar_sharp:984202,table_bar_rounded:983959,table_bar_outlined:984696,table_chart:58938,table_chart_sharp:60720,table_chart_rounded:983567,table_chart_outlined:62493,table_restaurant:984453,table_restaurant_sharp:984203,table_restaurant_rounded:983960,table_restaurant_outlined:984697,table_rows:58939,table_rows_sharp:60721,table_rows_rounded:983568,table_rows_outlined:62494,table_view:58940,table_view_sharp:60722,table_view_rounded:983569,table_view_outlined:62495,tablet:58941,tablet_sharp:60725,tablet_rounded:983572,tablet_outlined:62498,tablet_android:58942,tablet_android_sharp:60723,tablet_android_rounded:983570,tablet_android_outlined:62496,tablet_mac:58943,tablet_mac_sharp:60724,tablet_mac_rounded:983571,tablet_mac_outlined:62497,tag:58944,tag_sharp:60727,tag_rounded:983574,tag_outlined:62500,tag_faces:58945,tag_faces_sharp:60726,tag_faces_rounded:983573,tag_faces_outlined:62499,takeout_dining:58946,takeout_dining_sharp:60728,takeout_dining_rounded:983575,takeout_dining_outlined:62501,tap_and_play:58947,tap_and_play_sharp:60729,tap_and_play_rounded:983576,tap_and_play_outlined:62502,tapas:58948,tapas_sharp:60730,tapas_rounded:983577,tapas_outlined:62503,task:58949,task_sharp:60732,task_rounded:983579,task_outlined:62505,task_alt:58950,task_alt_sharp:60731,task_alt_rounded:983578,task_alt_outlined:62504,taxi_alert:58951,taxi_alert_sharp:60733,taxi_alert_rounded:983580,taxi_alert_outlined:62506,telegram:984454,telegram_sharp:984204,telegram_rounded:983961,telegram_outlined:984698,temple_buddhist:984455,temple_buddhist_sharp:984205,temple_buddhist_rounded:983962,temple_buddhist_outlined:984699,temple_hindu:984456,temple_hindu_sharp:984206,temple_hindu_rounded:983963,temple_hindu_outlined:984700,terminal:984457,terminal_sharp:984207,terminal_rounded:983964,terminal_outlined:984701,terrain:58952,terrain_sharp:60734,terrain_rounded:983581,terrain_outlined:62507,text_decrease:984458,text_decrease_sharp:984208,text_decrease_rounded:983965,text_decrease_outlined:984702,text_fields:58953,text_fields_sharp:60735,text_fields_rounded:983582,text_fields_outlined:62508,text_format:58954,text_format_sharp:60736,text_format_rounded:983583,text_format_outlined:62509,text_increase:984459,text_increase_sharp:984209,text_increase_rounded:983966,text_increase_outlined:984703,text_rotate_up:58955,text_rotate_up_sharp:60737,text_rotate_up_rounded:983584,text_rotate_up_outlined:62510,text_rotate_vertical:58956,text_rotate_vertical_sharp:60738,text_rotate_vertical_rounded:983585,text_rotate_vertical_outlined:62511,text_rotation_angledown:58957,text_rotation_angledown_sharp:60739,text_rotation_angledown_rounded:983586,text_rotation_angledown_outlined:62512,text_rotation_angleup:58958,text_rotation_angleup_sharp:60740,text_rotation_angleup_rounded:983587,text_rotation_angleup_outlined:62513,text_rotation_down:58959,text_rotation_down_sharp:60741,text_rotation_down_rounded:983588,text_rotation_down_outlined:62514,text_rotation_none:58960,text_rotation_none_sharp:60742,text_rotation_none_rounded:983589,text_rotation_none_outlined:62515,text_snippet:58961,text_snippet_sharp:60743,text_snippet_rounded:983590,text_snippet_outlined:62516,textsms:58962,textsms_sharp:60744,textsms_rounded:983591,textsms_outlined:62517,texture:58963,texture_sharp:60745,texture_rounded:983592,texture_outlined:62518,theater_comedy:58964,theater_comedy_sharp:60746,theater_comedy_rounded:983593,theater_comedy_outlined:62519,theaters:58965,theaters_sharp:60747,theaters_rounded:983594,theaters_outlined:62520,thermostat:58966,thermostat_sharp:60749,thermostat_rounded:983596,thermostat_outlined:62522,thermostat_auto:58967,thermostat_auto_sharp:60748,thermostat_auto_rounded:983595,thermostat_auto_outlined:62521,thumb_down:58968,thumb_down_sharp:60752,thumb_down_rounded:983599,thumb_down_outlined:62525,thumb_down_alt:58969,thumb_down_alt_sharp:60750,thumb_down_alt_rounded:983597,thumb_down_alt_outlined:62523,thumb_down_off_alt:58970,thumb_down_off_alt_sharp:60751,thumb_down_off_alt_rounded:983598,thumb_down_off_alt_outlined:62524,thumb_up:58971,thumb_up_sharp:60755,thumb_up_rounded:983602,thumb_up_outlined:62528,thumb_up_alt:58972,thumb_up_alt_sharp:60753,thumb_up_alt_rounded:983600,thumb_up_alt_outlined:62526,thumb_up_off_alt:58973,thumb_up_off_alt_sharp:60754,thumb_up_off_alt_rounded:983601,thumb_up_off_alt_outlined:62527,thumbs_up_down:58974,thumbs_up_down_sharp:60756,thumbs_up_down_rounded:983603,thumbs_up_down_outlined:62529,thunderstorm:985035,thunderstorm_sharp:984947,thunderstorm_rounded:985123,thunderstorm_outlined:984859,tiktok:984460,tiktok_sharp:984210,tiktok_rounded:983967,tiktok_outlined:984704,time_to_leave:58975,time_to_leave_sharp:60757,time_to_leave_rounded:983604,time_to_leave_outlined:62530,timelapse:58976,timelapse_sharp:60758,timelapse_rounded:983605,timelapse_outlined:62531,timeline:58977,timeline_sharp:60759,timeline_rounded:983606,timeline_outlined:62532,timer:58978,timer_sharp:60765,timer_rounded:983612,timer_outlined:62538,timer_10:58979,timer_10_sharp:60761,timer_10_rounded:983607,timer_10_outlined:62533,timer_10_select:58980,timer_10_select_sharp:60760,timer_10_select_rounded:983608,timer_10_select_outlined:62534,timer_3:58981,timer_3_sharp:60763,timer_3_rounded:983609,timer_3_outlined:62535,timer_3_select:58982,timer_3_select_sharp:60762,timer_3_select_rounded:983610,timer_3_select_outlined:62536,timer_off:58983,timer_off_sharp:60764,timer_off_rounded:983611,timer_off_outlined:62537,tips_and_updates:984461,tips_and_updates_sharp:984211,tips_and_updates_rounded:983968,tips_and_updates_outlined:984705,tire_repair:984772,tire_repair_sharp:984759,tire_repair_rounded:984785,tire_repair_outlined:984746,title:58984,title_sharp:60766,title_rounded:983613,title_outlined:62539,toc:58985|R,toc_sharp:60767|R,toc_rounded:983614|R,toc_outlined:62540|R,today:58986,today_sharp:60768,today_rounded:983615,today_outlined:62541,toggle_off:58987,toggle_off_sharp:60769,toggle_off_rounded:983616,toggle_off_outlined:62542,toggle_on:58988,toggle_on_sharp:60770,toggle_on_rounded:983617,toggle_on_outlined:62543,token:984462,token_sharp:984212,token_rounded:983969,token_outlined:984706,toll:58989,toll_sharp:60771,toll_rounded:983618,toll_outlined:62544,tonality:58990,tonality_sharp:60772,tonality_rounded:983619,tonality_outlined:62545,topic:58991,topic_sharp:60773,topic_rounded:983620,topic_outlined:62546,tornado:985036,tornado_sharp:984948,tornado_rounded:985124,tornado_outlined:984860,touch_app:58992,touch_app_sharp:60774,touch_app_rounded:983621,touch_app_outlined:62547,tour:58993,tour_sharp:60775,tour_rounded:983622,tour_outlined:62548,toys:58994,toys_sharp:60776,toys_rounded:983623,toys_outlined:62549,track_changes:58995,track_changes_sharp:60777,track_changes_rounded:983624,track_changes_outlined:62550,traffic:58996,traffic_sharp:60778,traffic_rounded:983625,traffic_outlined:62551,train:58997,train_sharp:60779,train_rounded:983626,train_outlined:62552,tram:58998,tram_sharp:60780,tram_rounded:983627,tram_outlined:62553,transcribe:985037,transcribe_sharp:984949,transcribe_rounded:985125,transcribe_outlined:984861,transfer_within_a_station:58999,transfer_within_a_station_sharp:60781,transfer_within_a_station_rounded:983628,transfer_within_a_station_outlined:62554,transform:59000,transform_sharp:60782,transform_rounded:983629,transform_outlined:62555,transgender:59001,transgender_sharp:60783,transgender_rounded:983630,transgender_outlined:62556,transit_enterexit:59002,transit_enterexit_sharp:60784,transit_enterexit_rounded:983631,transit_enterexit_outlined:62557,translate:59003,translate_sharp:60785,translate_rounded:983632,translate_outlined:62558,travel_explore:59004,travel_explore_sharp:60786,travel_explore_rounded:983633,travel_explore_outlined:62559,trending_down:59005|R,trending_down_sharp:60787|R,trending_down_rounded:983634|R,trending_down_outlined:62560|R,trending_flat:59006|R,trending_flat_sharp:60788|R,trending_flat_rounded:983635|R,trending_flat_outlined:62561|R,trending_neutral:59006,trending_neutral_sharp:60788,trending_neutral_rounded:983635,trending_neutral_outlined:62561,trending_up:59007|R,trending_up_sharp:60789|R,trending_up_rounded:983636|R,trending_up_outlined:62562|R,trip_origin:59008,trip_origin_sharp:60790,trip_origin_rounded:983637,trip_origin_outlined:62563,trolley:985208,troubleshoot:985038,troubleshoot_sharp:984950,troubleshoot_rounded:985126,troubleshoot_outlined:984862,try_sms_star:59009,try_sms_star_sharp:60791,try_sms_star_rounded:983638,try_sms_star_outlined:62564,tsunami:985039,tsunami_sharp:984951,tsunami_rounded:985127,tsunami_outlined:984863,tty:59010,tty_sharp:60792,tty_rounded:983639,tty_outlined:62565,tune:59011,tune_sharp:60793,tune_rounded:983640,tune_outlined:62566,tungsten:59012,tungsten_sharp:60794,tungsten_rounded:983641,tungsten_outlined:62567,turn_left:984463,turn_left_sharp:984213,turn_left_rounded:983970,turn_left_outlined:984707,turn_right:984464,turn_right_sharp:984214,turn_right_rounded:983971,turn_right_outlined:984708,turn_sharp_left:984465,turn_sharp_left_sharp:984215,turn_sharp_left_rounded:983972,turn_sharp_left_outlined:984709,turn_sharp_right:984466,turn_sharp_right_sharp:984216,turn_sharp_right_rounded:983973,turn_sharp_right_outlined:984710,turn_slight_left:984467,turn_slight_left_sharp:984217,turn_slight_left_rounded:983974,turn_slight_left_outlined:984711,turn_slight_right:984468,turn_slight_right_sharp:984218,turn_slight_right_rounded:983975,turn_slight_right_outlined:984712,turned_in:59013,turned_in_sharp:60796,turned_in_rounded:983643,turned_in_outlined:62569,turned_in_not:59014,turned_in_not_sharp:60795,turned_in_not_rounded:983642,turned_in_not_outlined:62568,tv:59015,tv_sharp:60798,tv_rounded:983645,tv_outlined:62571,tv_off:59016,tv_off_sharp:60797,tv_off_rounded:983644,tv_off_outlined:62570,two_wheeler:59017,two_wheeler_sharp:60799,two_wheeler_rounded:983646,two_wheeler_outlined:62572,type_specimen:985040,type_specimen_sharp:984952,type_specimen_rounded:985128,type_specimen_outlined:984864,u_turn_left:984469,u_turn_left_sharp:984219,u_turn_left_rounded:983976,u_turn_left_outlined:984713,u_turn_right:984470,u_turn_right_sharp:984220,u_turn_right_rounded:983977,u_turn_right_outlined:984714,umbrella:59018,umbrella_sharp:60800,umbrella_rounded:983647,umbrella_outlined:62573,unarchive:59019,unarchive_sharp:60801,unarchive_rounded:983648,unarchive_outlined:62574,undo:59020|R,undo_sharp:60802|R,undo_rounded:983649|R,undo_outlined:62575|R,unfold_less:59021,unfold_less_sharp:60803,unfold_less_rounded:983650,unfold_less_outlined:62576,unfold_less_double:985209,unfold_less_double_sharp:985165,unfold_less_double_rounded:985238,unfold_less_double_outlined:985268,unfold_more:59022,unfold_more_sharp:60804,unfold_more_rounded:983651,unfold_more_outlined:62577,unfold_more_double:985210,unfold_more_double_sharp:985166,unfold_more_double_rounded:985239,unfold_more_double_outlined:985269,unpublished:59023,unpublished_sharp:60805,unpublished_rounded:983652,unpublished_outlined:62578,unsubscribe:59024,unsubscribe_sharp:60806,unsubscribe_rounded:983653,unsubscribe_outlined:62579,upcoming:59025,upcoming_sharp:60807,upcoming_rounded:983654,upcoming_outlined:62580,update:59026,update_sharp:60809,update_rounded:983656,update_outlined:62582,update_disabled:59027,update_disabled_sharp:60808,update_disabled_rounded:983655,update_disabled_outlined:62581,upgrade:59028,upgrade_sharp:60810,upgrade_rounded:983657,upgrade_outlined:62583,upload:59029,upload_sharp:60812,upload_rounded:983659,upload_outlined:62585,upload_file:59030,upload_file_sharp:60811,upload_file_rounded:983658,upload_file_outlined:62584,usb:59031,usb_sharp:60814,usb_rounded:983661,usb_outlined:62587,usb_off:59032,usb_off_sharp:60813,usb_off_rounded:983660,usb_off_outlined:62586,vaccines:984471,vaccines_sharp:984221,vaccines_rounded:983978,vaccines_outlined:984715,vape_free:984773,vape_free_sharp:984760,vape_free_rounded:984786,vape_free_outlined:984747,vaping_rooms:984774,vaping_rooms_sharp:984761,vaping_rooms_rounded:984787,vaping_rooms_outlined:984748,verified:59033,verified_sharp:60815,verified_rounded:983662,verified_outlined:62588,verified_user:59034,verified_user_sharp:60816,verified_user_rounded:983663,verified_user_outlined:62589,vertical_align_bottom:59035,vertical_align_bottom_sharp:60817,vertical_align_bottom_rounded:983664,vertical_align_bottom_outlined:62590,vertical_align_center:59036,vertical_align_center_sharp:60818,vertical_align_center_rounded:983665,vertical_align_center_outlined:62591,vertical_align_top:59037,vertical_align_top_sharp:60819,vertical_align_top_rounded:983666,vertical_align_top_outlined:62592,vertical_distribute:59038,vertical_distribute_sharp:60820,vertical_distribute_rounded:983667,vertical_distribute_outlined:62593,vertical_shades:985041,vertical_shades_sharp:984954,vertical_shades_rounded:985130,vertical_shades_outlined:984866,vertical_shades_closed:985042,vertical_shades_closed_sharp:984953,vertical_shades_closed_rounded:985129,vertical_shades_closed_outlined:984865,vertical_split:59039,vertical_split_sharp:60821,vertical_split_rounded:983668,vertical_split_outlined:62594,vibration:59040,vibration_sharp:60822,vibration_rounded:983669,vibration_outlined:62595,video_call:59041,video_call_sharp:60823,video_call_rounded:983670,video_call_outlined:62596,video_camera_back:59042,video_camera_back_sharp:60824,video_camera_back_rounded:983671,video_camera_back_outlined:62597,video_camera_front:59043,video_camera_front_sharp:60825,video_camera_front_rounded:983672,video_camera_front_outlined:62598,video_chat:985211,video_chat_sharp:985167,video_chat_rounded:985240,video_chat_outlined:985270,video_collection:59045,video_collection_sharp:60827,video_collection_rounded:983674,video_collection_outlined:62600,video_file:984472,video_file_sharp:984222,video_file_rounded:983979,video_file_outlined:984716,video_label:59044,video_label_sharp:60826,video_label_rounded:983673,video_label_outlined:62599,video_library:59045,video_library_sharp:60827,video_library_rounded:983674,video_library_outlined:62600,video_settings:59046,video_settings_sharp:60828,video_settings_rounded:983675,video_settings_outlined:62601,video_stable:59047,video_stable_sharp:60829,video_stable_rounded:983676,video_stable_outlined:62602,videocam:59048,videocam_sharp:60831,videocam_rounded:983678,videocam_outlined:62604,videocam_off:59049,videocam_off_sharp:60830,videocam_off_rounded:983677,videocam_off_outlined:62603,videogame_asset:59050,videogame_asset_sharp:60833,videogame_asset_rounded:983680,videogame_asset_outlined:62606,videogame_asset_off:59051,videogame_asset_off_sharp:60832,videogame_asset_off_rounded:983679,videogame_asset_off_outlined:62605,view_agenda:59052,view_agenda_sharp:60834,view_agenda_rounded:983681,view_agenda_outlined:62607,view_array:59053,view_array_sharp:60835,view_array_rounded:983682,view_array_outlined:62608,view_carousel:59054,view_carousel_sharp:60836,view_carousel_rounded:983683,view_carousel_outlined:62609,view_column:59055,view_column_sharp:60837,view_column_rounded:983684,view_column_outlined:62610,view_comfortable:59056,view_comfortable_sharp:60838,view_comfortable_rounded:983685,view_comfortable_outlined:62611,view_comfy:59056,view_comfy_sharp:60838,view_comfy_rounded:983685,view_comfy_outlined:62611,view_comfy_alt:984473,view_comfy_alt_sharp:984223,view_comfy_alt_rounded:983980,view_comfy_alt_outlined:984717,view_compact:59057,view_compact_sharp:60839,view_compact_rounded:983686,view_compact_outlined:62612,view_compact_alt:984474,view_compact_alt_sharp:984224,view_compact_alt_rounded:983981,view_compact_alt_outlined:984718,view_cozy:984475,view_cozy_sharp:984225,view_cozy_rounded:983982,view_cozy_outlined:984719,view_day:59058,view_day_sharp:60840,view_day_rounded:983687,view_day_outlined:62613,view_headline:59059,view_headline_sharp:60841,view_headline_rounded:983688,view_headline_outlined:62614,view_in_ar:59060,view_in_ar_sharp:60842,view_in_ar_rounded:983689,view_in_ar_outlined:62615,view_kanban:984476,view_kanban_sharp:984226,view_kanban_rounded:983983,view_kanban_outlined:984720,view_list:59061|R,view_list_sharp:60843|R,view_list_rounded:983690|R,view_list_outlined:62616|R,view_module:59062,view_module_sharp:60844,view_module_rounded:983691,view_module_outlined:62617,view_quilt:59063|R,view_quilt_sharp:60845|R,view_quilt_rounded:983692|R,view_quilt_outlined:62618|R,view_sidebar:59064,view_sidebar_sharp:60846,view_sidebar_rounded:983693,view_sidebar_outlined:62619,view_stream:59065,view_stream_sharp:60847,view_stream_rounded:983694,view_stream_outlined:62620,view_timeline:984477,view_timeline_sharp:984227,view_timeline_rounded:983984,view_timeline_outlined:984721,view_week:59066,view_week_sharp:60848,view_week_rounded:983695,view_week_outlined:62621,vignette:59067,vignette_sharp:60849,vignette_rounded:983696,vignette_outlined:62622,villa:59068,villa_sharp:60850,villa_rounded:983697,villa_outlined:62623,visibility:59069,visibility_sharp:60852,visibility_rounded:983699,visibility_outlined:62625,visibility_off:59070,visibility_off_sharp:60851,visibility_off_rounded:983698,visibility_off_outlined:62624,voice_chat:59071,voice_chat_sharp:60853,voice_chat_rounded:983700,voice_chat_outlined:62626,voice_over_off:59072,voice_over_off_sharp:60854,voice_over_off_rounded:983701,voice_over_off_outlined:62627,voicemail:59073,voicemail_sharp:60855,voicemail_rounded:983702,voicemail_outlined:62628,volcano:985043,volcano_sharp:984955,volcano_rounded:985131,volcano_outlined:984867,volume_down:59074,volume_down_sharp:60856,volume_down_rounded:983703,volume_down_outlined:62629,volume_down_alt:984478,volume_mute:59075,volume_mute_sharp:60857,volume_mute_rounded:983704,volume_mute_outlined:62630,volume_off:59076,volume_off_sharp:60858,volume_off_rounded:983705,volume_off_outlined:62631,volume_up:59077,volume_up_sharp:60859,volume_up_rounded:983706,volume_up_outlined:62632,volunteer_activism:59078,volunteer_activism_sharp:60860,volunteer_activism_rounded:983707,volunteer_activism_outlined:62633,vpn_key:59079,vpn_key_sharp:60861,vpn_key_rounded:983708,vpn_key_outlined:62634,vpn_key_off:984479,vpn_key_off_sharp:984228,vpn_key_off_rounded:983985,vpn_key_off_outlined:984722,vpn_lock:59080,vpn_lock_sharp:60862,vpn_lock_rounded:983709,vpn_lock_outlined:62635,vrpano:59081,vrpano_sharp:60863,vrpano_rounded:983710,vrpano_outlined:62636,wallet:985044,wallet_sharp:984956,wallet_rounded:985132,wallet_outlined:984868,wallet_giftcard:57662,wallet_giftcard_sharp:59451,wallet_giftcard_rounded:63002,wallet_giftcard_outlined:61229,wallet_membership:57663,wallet_membership_sharp:59452,wallet_membership_rounded:63003,wallet_membership_outlined:61230,wallet_travel:57664,wallet_travel_sharp:59453,wallet_travel_rounded:63004,wallet_travel_outlined:61231,wallpaper:59082,wallpaper_sharp:60864,wallpaper_rounded:983711,wallpaper_outlined:62637,warehouse:984480,warehouse_sharp:984229,warehouse_rounded:983986,warehouse_outlined:984723,warning:59083,warning_sharp:60866,warning_rounded:983713,warning_outlined:62639,warning_amber:59084,warning_amber_sharp:60865,warning_amber_rounded:983712,warning_amber_outlined:62638,wash:59085,wash_sharp:60867,wash_rounded:983714,wash_outlined:62640,watch:59086,watch_sharp:60869,watch_rounded:983716,watch_outlined:62642,watch_later:59087,watch_later_sharp:60868,watch_later_rounded:983715,watch_later_outlined:62641,watch_off:984481,watch_off_sharp:984230,watch_off_rounded:983987,watch_off_outlined:984724,water:59088,water_sharp:60871,water_rounded:983718,water_outlined:62644,water_damage:59089,water_damage_sharp:60870,water_damage_rounded:983717,water_damage_outlined:62643,water_drop:984482,water_drop_sharp:984231,water_drop_rounded:983988,water_drop_outlined:984725,waterfall_chart:59090,waterfall_chart_sharp:60872,waterfall_chart_rounded:983719,waterfall_chart_outlined:62645,waves:59091,waves_sharp:60873,waves_rounded:983720,waves_outlined:62646,waving_hand:984483,waving_hand_sharp:984232,waving_hand_rounded:983989,waving_hand_outlined:984726,wb_auto:59092,wb_auto_sharp:60874,wb_auto_rounded:983721,wb_auto_outlined:62647,wb_cloudy:59093,wb_cloudy_sharp:60875,wb_cloudy_rounded:983722,wb_cloudy_outlined:62648,wb_incandescent:59094,wb_incandescent_sharp:60876,wb_incandescent_rounded:983723,wb_incandescent_outlined:62649,wb_iridescent:59095,wb_iridescent_sharp:60877,wb_iridescent_rounded:983724,wb_iridescent_outlined:62650,wb_shade:59096,wb_shade_sharp:60878,wb_shade_rounded:983725,wb_shade_outlined:62651,wb_sunny:59097,wb_sunny_sharp:60879,wb_sunny_rounded:983726,wb_sunny_outlined:62652,wb_twighlight:59098,wb_twilight:59099,wb_twilight_sharp:60880,wb_twilight_rounded:983727,wb_twilight_outlined:62653,wc:59100,wc_sharp:60881,wc_rounded:983728,wc_outlined:62654,web:59101,web_sharp:60884,web_rounded:983731,web_outlined:62657,web_asset:59102,web_asset_sharp:60883,web_asset_rounded:983730,web_asset_outlined:62656,web_asset_off:59103,web_asset_off_sharp:60882,web_asset_off_rounded:983729,web_asset_off_outlined:62655,web_stories:59104,web_stories_sharp:985168,web_stories_rounded:985241,web_stories_outlined:985271,webhook:984484,webhook_sharp:984233,webhook_rounded:983990,webhook_outlined:984727,wechat:984485,wechat_sharp:984234,wechat_rounded:983991,wechat_outlined:984728,weekend:59105,weekend_sharp:60885,weekend_rounded:983732,weekend_outlined:62658,west:59106,west_sharp:60886,west_rounded:983733,west_outlined:62659,whatshot:59107,whatshot_sharp:60887,whatshot_rounded:983734,whatshot_outlined:62660,wheelchair_pickup:59108,wheelchair_pickup_sharp:60888,wheelchair_pickup_rounded:983735,wheelchair_pickup_outlined:62661,where_to_vote:59109,where_to_vote_sharp:60889,where_to_vote_rounded:983736,where_to_vote_outlined:62662,widgets:59110,widgets_sharp:60890,widgets_rounded:983737,widgets_outlined:62663,width_full:985045,width_full_sharp:984957,width_full_rounded:985133,width_full_outlined:984869,width_normal:985046,width_normal_sharp:984958,width_normal_rounded:985134,width_normal_outlined:984870,width_wide:985047,width_wide_sharp:984959,width_wide_rounded:985135,width_wide_outlined:984871,wifi:59111,wifi_sharp:60896,wifi_rounded:983743,wifi_outlined:62668,wifi_1_bar:985048,wifi_1_bar_sharp:984960,wifi_1_bar_rounded:985136,wifi_1_bar_outlined:984872,wifi_2_bar:985049,wifi_2_bar_sharp:984961,wifi_2_bar_rounded:985137,wifi_2_bar_outlined:984873,wifi_calling:59112,wifi_calling_sharp:60892,wifi_calling_rounded:983739,wifi_calling_outlined:62665,wifi_calling_3:59113,wifi_calling_3_sharp:60891,wifi_calling_3_rounded:983738,wifi_calling_3_outlined:62664,wifi_channel:984487,wifi_channel_sharp:984236,wifi_channel_rounded:983993,wifi_channel_outlined:984730,wifi_find:984488,wifi_find_sharp:984237,wifi_find_rounded:983994,wifi_find_outlined:984731,wifi_lock:59114,wifi_lock_sharp:60893,wifi_lock_rounded:983740,wifi_lock_outlined:62666,wifi_off:59115,wifi_off_sharp:60894,wifi_off_rounded:983741,wifi_off_outlined:62667,wifi_password:984489,wifi_password_sharp:984238,wifi_password_rounded:983995,wifi_password_outlined:984732,wifi_protected_setup:59116,wifi_protected_setup_sharp:60895,wifi_protected_setup_rounded:983742,wifi_protected_setup_outlined:62669,wifi_tethering:59117,wifi_tethering_sharp:60899,wifi_tethering_rounded:983746,wifi_tethering_outlined:62672,wifi_tethering_error:984490,wifi_tethering_error_sharp:984239,wifi_tethering_error_rounded:984490,wifi_tethering_error_outlined:984733,wifi_tethering_error_rounded_sharp:984239,wifi_tethering_error_rounded_rounded:983744,wifi_tethering_error_rounded_outlined:984733,wifi_tethering_off:59119,wifi_tethering_off_sharp:60898,wifi_tethering_off_rounded:983745,wifi_tethering_off_outlined:62671,wind_power:985050,wind_power_sharp:984962,wind_power_rounded:985138,wind_power_outlined:984874,window:59120,window_sharp:60900,window_rounded:983747,window_outlined:62673,wine_bar:59121,wine_bar_sharp:60901,wine_bar_rounded:983748,wine_bar_outlined:62674,woman:984491,woman_sharp:984240,woman_rounded:983997,woman_outlined:984734,woman_2:985212,woman_2_sharp:985169,woman_2_rounded:985242,woman_2_outlined:985272,woo_commerce:984492,woo_commerce_sharp:984241,woo_commerce_rounded:983998,woo_commerce_outlined:984735,wordpress:984493,wordpress_sharp:984242,wordpress_rounded:983999,wordpress_outlined:984736,work:59122,work_sharp:60904,work_rounded:983751,work_outlined:62677,work_history:985051,work_history_sharp:984963,work_history_rounded:985139,work_history_outlined:984875,work_off:59123,work_off_sharp:60902,work_off_rounded:983749,work_off_outlined:62675,work_outline:59124,work_outline_sharp:60903,work_outline_rounded:983750,work_outline_outlined:62676,workspace_premium:984494,workspace_premium_sharp:984243,workspace_premium_rounded:984000,workspace_premium_outlined:984737,workspaces:59125,workspaces_sharp:60905,workspaces_rounded:983752,workspaces_outlined:62678,workspaces_filled:59126,workspaces_outline:59127,wrap_text:59128|R,wrap_text_sharp:60906|R,wrap_text_rounded:983753|R,wrap_text_outlined:62679|R,wrong_location:59129,wrong_location_sharp:60907,wrong_location_rounded:983754,wrong_location_outlined:62680,wysiwyg:59130,wysiwyg_sharp:60908,wysiwyg_rounded:983755,wysiwyg_outlined:62681,yard:59131,yard_sharp:60909,yard_rounded:983756,yard_outlined:62682,youtube_searched_for:59132,youtube_searched_for_sharp:60910,youtube_searched_for_rounded:983757,youtube_searched_for_outlined:62683,zoom_in:59133,zoom_in_sharp:60911,zoom_in_rounded:983758,zoom_in_outlined:62684,zoom_in_map:984495,zoom_in_map_sharp:984244,zoom_in_map_rounded:984001,zoom_in_map_outlined:984738,zoom_out:59134,zoom_out_sharp:60913,zoom_out_rounded:983760,zoom_out_outlined:62686,zoom_out_map:59135,zoom_out_map_sharp:60912,zoom_out_map_rounded:983759,zoom_out_map_outlined:62685";
const __ICON_CACHE = new Map();
// 名字 → IconData（命中即缓存，同一名字始终同一实例，对齐 Dart const 规范化）。
function __iconOf(name) {
  var hit = __ICON_CACHE.get(name);
  if (hit !== undefined) { return hit; }
  var head = name + ':';
  var at = -1;
  if (__ICON_SRC.slice(0, head.length) === head) {
    at = 0;
  } else {
    var found = __ICON_SRC.indexOf(',' + head);
    if (found < 0) { return undefined; }
    at = found + 1;
  }
  var end = __ICON_SRC.indexOf(',', at);
  var spec = end < 0 ? __ICON_SRC.slice(at) : __ICON_SRC.slice(at, end);
  var parts = spec.slice(head.length).split('|');
  var family = 'MaterialIcons';
  var rtl = false;
  for (var k = 1; k < parts.length; k++) {
    if (parts[k] === 'R') { rtl = true; } else { family = parts[k]; }
  }
  var icon = new IconData({ codePoint: Number(parts[0]),
    fontFamily: family, matchTextDirection: rtl });
  __ICON_CACHE.set(name, icon);
  return icon;
}
// `Icons`：与 SDK 常量表同名一一对应的只读视图。表里没有的名字（含
// toString 这类对象方法）落回普通对象行为，与直接写对象字面量一致。
export const Icons = new Proxy({}, {
  get: function (target, name) {
    if (typeof name !== 'string') { return Reflect.get(target, name); }
    var icon = __iconOf(name);
    return icon === undefined ? Reflect.get(target, name) : icon;
  }
});

// 单值构造的取值：位置实参的形参名因类而异（`value` / `radius` / `index` /
// `textScaleFactor` …），值都是「唯一那个数」；裸数字也接受。
function __one(props) {
  if (props == null) { return 0; }
  if (typeof props === 'number' || typeof props === 'string') { return props; }
  for (var k in props) {
    if (k !== '__pos' && props[k] != null) { return props[k]; }
  }
  return 0;
}

// ----- 边距 ---------------------------------------------------------------
// 宿主协议：{left, top, right, bottom}（layout_from_json.edgeInsetsFromJson）。
export class EdgeInsets {
  constructor(props) {
    props = __posArgs(props, ['left', 'top', 'right', 'bottom']);
    this.left = props.left != null ? props.left : 0;
    this.top = props.top != null ? props.top : 0;
    this.right = props.right != null ? props.right : 0;
    this.bottom = props.bottom != null ? props.bottom : 0;
  }
  get horizontal() { return this.left + this.right; }
  get vertical() { return this.top + this.bottom; }
  get isEmpty() {
    return this.left === 0 && this.top === 0 && this.right === 0 && this.bottom === 0;
  }
  toJSON() {
    return { left: this.left, top: this.top, right: this.right, bottom: this.bottom };
  }
  static zero = new EdgeInsets({});
  static all(props) {
    var v = __one(props);
    return new EdgeInsets({ left: v, top: v, right: v, bottom: v });
  }
  static only(props) { return new EdgeInsets(props); }
  static symmetric(props) {
    var h = props.horizontal != null ? props.horizontal : 0;
    var v = props.vertical != null ? props.vertical : 0;
    return new EdgeInsets({ left: h, top: v, right: h, bottom: v });
  }
  static fromLTRB(props) {
    props = __posArgs(props, ['left', 'top', 'right', 'bottom']);
    return new EdgeInsets(props);
  }
  static fromSTEB(props) {
    props = __posArgs(props, ['start', 'top', 'end', 'bottom']);
    return new EdgeInsets({
      left: props.start != null ? props.start : 0,
      top: props.top != null ? props.top : 0,
      right: props.end != null ? props.end : 0,
      bottom: props.bottom != null ? props.bottom : 0,
    });
  }
}

// ----- 圆角 / 边框 -----------------------------------------------------------
// 宿主协议：BorderRadius → {radius} 或四角数字；Border → {all} 或四边 side。
function __radiusOf(v) {
  if (v instanceof Radius) { return v; }
  return new Radius({ radius: typeof v === 'number' ? v : __one(v) });
}

export class BorderRadius {
  constructor(props) {
    props = __posArgs(props, ['topLeft', 'topRight', 'bottomLeft', 'bottomRight']);
    this.topLeft = __radiusOf(props.topLeft);
    this.topRight = __radiusOf(props.topRight);
    this.bottomLeft = __radiusOf(props.bottomLeft);
    this.bottomRight = __radiusOf(props.bottomRight);
  }
  toJSON() {
    var tl = this.topLeft.x, tr = this.topRight.x;
    var bl = this.bottomLeft.x, br = this.bottomRight.x;
    if (tl === tr && tr === bl && bl === br) { return { radius: tl }; }
    return { topLeft: tl, topRight: tr, bottomLeft: bl, bottomRight: br };
  }
  get horizontal() { return this.topLeft.x + this.bottomLeft.x; }
  get vertical() { return this.topLeft.x + this.bottomLeft.x; }
  static zero = new BorderRadius({});
  static all(props) {
    var r = __radiusOf(props.radius);
    return new BorderRadius({ topLeft: r, topRight: r, bottomLeft: r, bottomRight: r });
  }
  static circular(props) { return BorderRadius.all({ radius: __one(props) }); }
  static only(props) { return new BorderRadius(props); }
  static vertical(props) {
    var r = __radiusOf(__one(props));
    return new BorderRadius({ topLeft: r, topRight: r });
  }
  static horizontal(props) {
    var r = __radiusOf(__one(props));
    return new BorderRadius({ topLeft: r, bottomLeft: r });
  }
}

export class BorderSide {
  constructor(props) {
    props = __posArgs(props, ['color', 'width', 'style', 'strokeAlign']);
    this.color = props.color != null ? props.color : null;
    this.width = props.width != null ? props.width : 1;
    this.style = props.style != null ? props.style : 'solid';
    if (props.strokeAlign != null) { this.strokeAlign = props.strokeAlign; }
  }
  toJSON() {
    return { color: this.color, width: this.width, style: this.style };
  }
  static none = new BorderSide({ width: 0, style: 'none' });
}

export class Border {
  constructor(props) {
    props = __posArgs(props, ['top', 'right', 'bottom', 'left']);
    if (props.all != null) { this.all = props.all; }
    if (props.top != null) { this.top = props.top; }
    if (props.right != null) { this.right = props.right; }
    if (props.bottom != null) { this.bottom = props.bottom; }
    if (props.left != null) { this.left = props.left; }
  }
  // `Border.all(color:.., width:..)` 的实参与 BorderSide 同形。
  static all(props) { return new Border({ all: new BorderSide(props) }); }
  static fromBorderSide(props) {
    props = __posArgs(props, ['side']);
    return new Border({ all: props.side });
  }
  toJSON() {
    if (this.all != null) { return { all: this.all }; }
    return { top: this.top, right: this.right, bottom: this.bottom, left: this.left };
  }
}

export class BoxShadow {
  constructor(props) {
    props = __posArgs(props, ['color', 'offset', 'blurRadius', 'spreadRadius', 'blurStyle']);
    this.color = props.color != null ? props.color : null;
    this.offset = props.offset != null ? props.offset : new Offset({ dx: 0, dy: 0 });
    this.blurRadius = props.blurRadius != null ? props.blurRadius : 0;
    this.spreadRadius = props.spreadRadius != null ? props.spreadRadius : 0;
    this.blurStyle = props.blurStyle != null ? props.blurStyle : 'normal';
  }
  toJSON() {
    return {
      color: this.color,
      dx: this.offset.dx,
      dy: this.offset.dy,
      blur: this.blurRadius,
      spread: this.spreadRadius,
      blurStyle: this.blurStyle,
    };
  }
}

// ----- 文字 ---------------------------------------------------------------
// 宿主协议：TextStyle 直取同名字段；FontWeight → 'bold'/'w600'；
// TextDecoration → 成员名；TextScaler → {linear} / 'noScaling'。
export class TextDecoration {
  constructor(props) { this.name = __one(props); }
  toJSON() { return this.name; }
  static none = new TextDecoration('none');
  static underline = new TextDecoration('underline');
  static overline = new TextDecoration('overline');
  static lineThrough = new TextDecoration('lineThrough');
}

export class FontWeight {
  constructor(props) { this.value = __one(__posArgs(props, ['index'])); }
  toJSON() {
    if (this.value === 400) { return 'normal'; }
    if (this.value === 700) { return 'bold'; }
    return 'w' + this.value;
  }
  static w100 = new FontWeight(100);
  static w200 = new FontWeight(200);
  static w300 = new FontWeight(300);
  static w400 = new FontWeight(400);
  static w500 = new FontWeight(500);
  static w600 = new FontWeight(600);
  static w700 = new FontWeight(700);
  static w800 = new FontWeight(800);
  static w900 = new FontWeight(900);
  static normal = FontWeight.w400;
  static bold = FontWeight.w700;
}

export class TextScaler {
  constructor(props) {
    this.__none = props === null;
    if (!this.__none) { this.factor = __one(props); }
  }
  toJSON() { return this.__none ? 'noScaling' : { linear: this.factor }; }
  static noScaling = new TextScaler(null);
  static linear(props) {
    props = __posArgs(props, ['textScaleFactor']);
    return new TextScaler(
    props.textScaleFactor != null ? props.textScaleFactor : __one(props));
  }
}

export class TextStyle {
  constructor(props) {
    props = props || {};
    // TextStyle 的构造参数全是具名参（源码里没有位置参、也没有命名构造），
    // 产物只可能下发 Dart 实参本身，不存在 `__pos` / `factory` 这类协议键，
    // 因此按原名直接拷贝，不做协议键过滤。
    for (var k in props) {
      if (props[k] != null) { this[k] = props[k]; }
    }
  }
  toJSON() {
    var j = {};
    for (var k in this) {
      if (this[k] != null) { j[k] = this[k]; }
    }
    return j;
  }
}

// ----- 形状 ---------------------------------------------------------------
// 宿主协议：shapeFromJson → {kind:'rounded'|'stadium'|'circle'|'beveled'|
// 'continuous', borderRadius, side}。
class __OutlinedBorder {
  constructor(kind, props) {
    props = __posArgs(props, ['borderRadius', 'side']);
    this.__kind = kind;
    if (props.borderRadius != null) { this.borderRadius = props.borderRadius; }
    if (props.side != null) { this.side = props.side; }
  }
  toJSON() {
    var j = { kind: this.__kind };
    if (this.borderRadius != null) { j.borderRadius = this.borderRadius; }
    if (this.side != null) { j.side = this.side; }
    return j;
  }
}
export class RoundedRectangleBorder extends __OutlinedBorder {
  constructor(props) { super('rounded', props); }
}
export class CircleBorder extends __OutlinedBorder {
  constructor(props) { super('circle', props); }
}
export class StadiumBorder extends __OutlinedBorder {
  constructor(props) { super('stadium', props); }
}
export class BeveledRectangleBorder extends __OutlinedBorder {
  constructor(props) { super('beveled', props); }
}
export class ContinuousRectangleBorder extends __OutlinedBorder {
  constructor(props) { super('continuous', props); }
}

// ----- 图片 ---------------------------------------------------------------
// AssetImage / NetworkImage 的跨桥形态就是**源字符串**（构造名由静态方法写进
// `props.factory` 只在元素层起作用，值对象本身不带 factory）；宿主
// `_imageProvider` 按 'http' 前缀区分网络图与资源图。DecorationImage →
// {source, fit}。
export class AssetImage {
  constructor(props) {
    props = __posArgs(props, ['assetName']);
    this.assetName = props.assetName != null ? props.assetName : __one(props);
  }
  toJSON() { return this.assetName; }
}

export class NetworkImage {
  constructor(props) {
    props = __posArgs(props, ['url', 'scale', 'headers']);
    this.url = props.url != null ? props.url : __one(props);
    if (props.scale != null) { this.scale = props.scale; }
    if (props.headers != null) { this.headers = props.headers; }
  }
  toJSON() { return this.url; }
}

export class DecorationImage {
  constructor(props) {
    props = props || {};
    for (var k in props) {
      if (k !== '__pos' && props[k] != null) { this[k] = props[k]; }
    }
  }
  toJSON() {
    var j = { source: this.image };
    if (this.fit != null) { j.fit = this.fit; }
    return j;
  }
}

// ----- 滤镜 ---------------------------------------------------------------
// 宿主协议：ImageFilter → {kind:'blur'|'dilate'|'erode'|'matrix'|'compose',…}；
// ColorFilter → {kind:'mode'|'matrix'|'linearToSrgbGamma'|'srgbToLinearGamma',…}。
class __KindValue {
  constructor(kind, props) {
    this.__kind = kind;
    props = props || {};
    for (var k in props) {
      if (k !== '__pos' && props[k] != null) { this[k] = props[k]; }
    }
  }
  toJSON() {
    var j = { kind: this.__kind };
    for (var k in this) {
      if (k !== '__kind' && this[k] != null) { j[k] = this[k]; }
    }
    return j;
  }
}

export class ImageFilter extends __KindValue {
  constructor(props) { super('blur', props); }
  static blur(props) {
    props = __posArgs(props, ['sigmaX', 'sigmaY', 'tileMode']);
    return new __KindValue('blur', props);
  }
  static dilate(props) {
    props = __posArgs(props, ['radiusX', 'radiusY']);
    return new __KindValue('dilate', props);
  }
  static erode(props) {
    props = __posArgs(props, ['radiusX', 'radiusY']);
    return new __KindValue('erode', props);
  }
  static matrix(props) {
    props = __posArgs(props, ['matrix']);
    return new __KindValue('matrix', props);
  }
  static compose(props) {
    props = __posArgs(props, ['outer', 'inner']);
    return new __KindValue('compose', props);
  }
}

export class ColorFilter extends __KindValue {
  constructor(props) { super('mode', props); }
  static mode(props) {
    props = __posArgs(props, ['color', 'blendMode']);
    return new __KindValue('mode', props);
  }
  static matrix(props) {
    props = __posArgs(props, ['matrix']);
    return new __KindValue('matrix', props);
  }
  static linearToSrgbGamma = new __KindValue('linearToSrgbGamma', {});
  static srgbToLinearGamma = new __KindValue('srgbToLinearGamma', {});
}

// ----- 数值列表 -----------------------------------------------------------
// `Float64List.fromList([...])`：ImageFilter.matrix 的入参（宿主只校验 16 个）。
export class Float64List {
  constructor(props) {
    props = __posArgs(props, ['elements']);
    this.elements = props.elements != null ? props.elements : (props.__pos || []);
  }
  get length() { return this.elements.length; }
  toJSON() { return this.elements; }
  static fromList(props) {
    props = __posArgs(props, ['elements']);
    var list = props.elements != null ? props.elements : props;
    return new Float64List({ elements: list });
  }
}

// ----- 栅格代理 -----------------------------------------------------------
// 宿主协议：键名与 Dart 构造具名实参同名（scroll_controller_bridge 直接读）。
class __GridDelegate {
  constructor(props) {
    props = props || {};
    for (var k in props) {
      if (k !== '__pos' && props[k] != null) { this[k] = props[k]; }
    }
  }
  toJSON() {
    var j = {};
    for (var k in this) {
      if (this[k] != null) { j[k] = this[k]; }
    }
    return j;
  }
}
export class SliverGridDelegateWithFixedCrossAxisCount extends __GridDelegate {
  constructor(props) {
    super(__posArgs(props, ['crossAxisCount', 'mainAxisSpacing',
      'crossAxisSpacing', 'childAspectRatio', 'mainAxisExtent']));
  }
}
export class SliverGridDelegateWithMaxCrossAxisExtent extends __GridDelegate {
  constructor(props) {
    super(__posArgs(props, ['maxCrossAxisExtent', 'mainAxisSpacing',
      'crossAxisSpacing', 'childAspectRatio', 'mainAxisExtent']));
  }
}

// ----- 滚动物理 -----------------------------------------------------------
// 宿主协议：scrollPhysicsFromJson 认**类名字符串**——每个物理类 toJSON 即自身
// 类名，与 Dart 里「同一类实例同一个物理」语义一致。
class __ScrollPhysics {
  constructor(name, props) {
    this.__name = name;
    if (props && props.parent != null) { this.parent = props.parent; }
  }
  toJSON() { return this.__name; }
}
export class BouncingScrollPhysics extends __ScrollPhysics {
  constructor(props) { super('BouncingScrollPhysics', props); }
}
export class ClampingScrollPhysics extends __ScrollPhysics {
  constructor(props) { super('ClampingScrollPhysics', props); }
}
export class NeverScrollableScrollPhysics extends __ScrollPhysics {
  constructor(props) { super('NeverScrollableScrollPhysics', props); }
}
export class AlwaysScrollableScrollPhysics extends __ScrollPhysics {
  constructor(props) { super('AlwaysScrollableScrollPhysics', props); }
}

// ----- 按钮样式 -----------------------------------------------------------
// 宿主协议：buttonStyleFromJson 直取同名字段（padding / minimumSize / side /
// shape / textStyle 等由各自类 toJSON 递归）。
export class ButtonStyle {
  constructor(props) {
    props = props || {};
    // 与 TextStyle 同理：构造参数全是具名参，直接按原名拷贝。
    for (var k in props) {
      if (props[k] != null) { this[k] = props[k]; }
    }
  }
  toJSON() {
    var j = {};
    for (var k in this) {
      if (this[k] != null) { j[k] = this[k]; }
    }
    return j;
  }
}

function __toHex(v) {
  var n = (v >>> 0).toString(16).toUpperCase();
  while (n.length < 8) { n = '0' + n; }
  return '#' + n;
}

export class Color {
  constructor(props) {
    props = __posArgs(props, ['value']);
    this.value = props.value != null ? (props.value >>> 0) : 0;
  }
  withAlpha(a) {
    return new Color({ value: ((a & 0xFF) << 24) | (this.value & 0x00FFFFFF) });
  }
  withOpacity(o) {
    var a = Math.round(Math.max(0, Math.min(1, o)) * 255);
    return this.withAlpha(a);
  }
  withValues(opts) {
    opts = __posArgs(opts, []);
    var a = opts.alpha != null ? Math.round(opts.alpha * 255) : this.alpha;
    var r = opts.red != null ? opts.red : this.red;
    var g = opts.green != null ? opts.green : this.green;
    var b = opts.blue != null ? opts.blue : this.blue;
    return Color.fromARGB({ a: a, r: r, g: g, b: b });
  }
  toJSON() {
    return __toHex(this.value);
  }
  toString() {
    return __toHex(this.value);
  }
  static fromARGB(props) {
    props = __posArgs(props, ['a', 'r', 'g', 'b']);
    return new Color({ value: ((props.a & 0xFF) << 24) | ((props.r & 0xFF) << 16) |
      ((props.g & 0xFF) << 8) | (props.b & 0xFF) });
  }
  static fromRGBO(props) {
    props = __posArgs(props, ['r', 'g', 'b', 'opacity']);
    var o = props.opacity != null ? props.opacity : 1;
    return Color.fromARGB({ a: Math.round(o * 255), r: props.r, g: props.g, b: props.b });
  }
  static lerp(props) {
    props = __posArgs(props, ['a', 'b', 't']);
    var a = props.a || new Color({ value: 0 });
    var b = props.b || new Color({ value: 0 });
    var t = props.t == null ? 0.5 : props.t;
    function mix(x, y) { return Math.round(x + (y - x) * t); }
    return Color.fromARGB({
      a: mix(a.alpha, b.alpha), r: mix(a.red, b.red),
      g: mix(a.green, b.green), b: mix(a.blue, b.blue)
    });
  }
  get alpha() {
    return (this.value >> 24) & 0xFF;
  }
  get red() {
    return (this.value >> 16) & 0xFF;
  }
  get green() {
    return (this.value >> 8) & 0xFF;
  }
  get blue() {
    return this.value & 0xFF;
  }
}
// 序列化：宿主 colorFromJson 只认 '#RRGGBB' / '#AARRGGBB'。

// MaterialColor / MaterialAccentColor / ColorSwatch：值仍是 Color（主色），
// 额外持各档位。档位同时挂在 `shadeNN` 与数字下标上，故 Dart 的
// `Colors.red[400]` / `Colors.red.shade400` 在 JS 里都能原样求值。
function __swatch(base, shades) {
  base.__shades = shades || {};
  return base;
}
function __swatchBase(props) {
  props = __posArgs(props, ['primary', 'swatch']);
  var v = props.value != null ? props.value : props.primary;
  return { value: v, swatch: props.swatch };
}
export class MaterialColor extends Color {
  constructor(props) {
    var p = __swatchBase(props);
    super({ value: p.value });
    __swatch(this, p.swatch);
  }
}

export class MaterialAccentColor extends Color {
  constructor(props) {
    var p = __swatchBase(props);
    super({ value: p.value });
    __swatch(this, p.swatch);
  }
}

export class ColorSwatch extends Color {
  constructor(props) {
    var p = __swatchBase(props);
    super({ value: p.value });
    __swatch(this, p.swatch);
  }
}

// ChangeNotifier 基类（flutter.js 模块内的 `export class`）。
//
// **职责只有一件事：提供模型本体**。addListener / removeListener 保留在 JS
// 侧（JS 自身逻辑要订阅模型），notifyListeners 双路派发：
//   ① 本端 `_listeners`（JS 侧逻辑 / JS 侧消费者重建）；
//   ② 跨语言 `handleOp(__id, 'notify')`（通知 Dart 端**通用镜像**
//      JsChangeNotifier，驱动 Dart 侧 ChangeNotifierProvider 子树刷新）。
// 构造时登记句柄（kind=notifier/ChangeNotifier），meta.type = JS 端类名 —— Dart 端的
// 通用镜像据此「记下它的 JS 端类型」（context.watch<T>() 的类型一路传到这里）。
export class ChangeNotifier {
  constructor() {
    this._listeners = [];
    this.__id = reg(this, 'notifier/ChangeNotifier', {
      meta: { type: (this.constructor && this.constructor.name) || 'ChangeNotifier' }
    });
  }
  addListener(f) {
    this._listeners.push(f);
  }
  removeListener(f) {
    var i = this._listeners.indexOf(f);
    if (i >= 0) {
      this._listeners.splice(i, 1);
    }
  }
  notifyListeners() {
    var ls = this._listeners.slice();
    for (var i = 0; i < ls.length; i++) { ls[i](); }
    // 双路之②：JS→宿主只有异步桥，故这里是 fire-and-forget（不阻塞本地派发）。
    if (this.__id != null) { handleOp(this.__id, 'notify'); }
  }
  // Dart ChangeNotifier.dispose：清空订阅（释放闭包引用）。被 dispose 后
  // 不再响应 notify（原生语义：disposed 后 notify 抛错；JS 侧简化为静默）。
  // 同时释放跨语言句柄 → 宿主端的通用镜像一并销毁（1:1 资源）。
  // 作为元素 prop 下发时（如 ChangeNotifierProvider 的 `notifier`）只带句柄 id：
  // 真实对象只存在于 JS 端，宿主经句柄取到自己的通用镜像。
  dispose() {
    this._listeners = [];
    if (this.__id != null) {
      releaseHandle(this.__id);
      this.__id = null;
    }
  }
  toJSON() {
    return { __handle: this.__id };
  }
}

// ValueNotifier<T>：单值版 ChangeNotifier（`ValueNotifier<int>(0)`）。
//
// **不属于本基类的句柄 kind**：构造时经 ChangeNotifier 登记 `notifier/ChangeNotifier`，
// meta.type 由 `constructor.name` 自动取成 'ValueNotifier'，宿主镜像仍是通用
// JsChangeNotifier（无需新 kind，见 change_notifier_bridge.dart）。
//
// `value` 用类内 getter/setter 实现，setter 里 **=== 守卫**是
// `ValueListenableBuilder`「值不变不重建」语义的唯一来源：相同即 return，
// 不同才赋值并 notifyListeners()（与 Dart ValueNotifier 一致）。
//
// 构造实参与其他 Dart 类一样按**具名 props 对象**下发（Dart 的 `ValueNotifier(this._value)`，
// 形参名就是 `_value`，见 ctor_signatures），故这里按 `_value` 键取值；
// 直接传裸值时（手写 / 内部调用）也兼容。
export class ValueNotifier extends ChangeNotifier {
  constructor(props) {
    super();
    this._value = (props !== null && typeof props === 'object' && '_value' in props)
    ? props._value
    : props;
  }
  get value() { return this._value; }
  set value(v) {
    if (this._value === v) { return; }
    this._value = v;
    this.notifyListeners();
  }
}
// 只用于 JS 侧推导（AnimatedBuilder 读 value 时宿主已完成真实插值）；
// 宿主侧按同名表还原真实 Curve（见 animation_from_json.curveFromJson）。
function __animCurveFn(name) {
  switch (name) {
    case 'linear': return function (t) { return t; };
    case 'ease': case 'easeInOut': return function (t) {
      return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
    };
    case 'easeIn': return function (t) { return t * t; };
    case 'easeOut': return function (t) { return 1 - (1 - t) * (1 - t); };
    case 'fastOutSlowIn': return function (t) { return t * t * (3 - 2 * t); };
    default:
    console.warn('[patch] 未登记的曲线 "' + name + '"，JS 侧按 linear 估算');

    return function (t) { return t; };
  }
}

// 生成器对 `Curves.easeOut` 这类「类名.成员」有两种落点（props 位会翻成
// 成员名字符串，其它位置原样引用），运行时提供同名对象后两边口径一致。
// 值一律是**成员名字符串**，宿主按名字查真实曲线 / 枚举（见
// animation_from_json 的 curveFromJson / crossFadeStateFromJson）。
var __CURVE_NAMES = [
  'linear', 'ease', 'easeIn', 'easeOut', 'easeInOut', 'easeInToLinear',
  'easeInSine', 'easeOutSine', 'easeInOutSine',
  'easeInQuad', 'easeOutQuad', 'easeInOutQuad',
  'easeInCubic', 'easeOutCubic', 'easeInOutCubic',
  'easeInQuart', 'easeOutQuart', 'easeInOutQuart',
  'easeInQuint', 'easeOutQuint', 'easeInOutQuint',
  'easeInExpo', 'easeOutExpo', 'easeInOutExpo',
  'easeInCirc', 'easeOutCirc', 'easeInOutCirc',
  'easeInBack', 'easeOutBack', 'easeInOutBack',
  'fastOutSlowIn', 'slowMiddle', 'decelerate',
  'bounceIn', 'bounceOut', 'bounceInOut',
  'elasticIn', 'elasticOut', 'elasticInOut',
  'fastLinearToSlowEaseIn', 'fastEaseInToSlowEaseOut'
];
export const Curves = {};
for (var __ci = 0; __ci < __CURVE_NAMES.length; __ci++) {
  Curves[__CURVE_NAMES[__ci]] = __CURVE_NAMES[__ci];
}

// 只在 JS 侧推导 value；作为组件 props 下发时经 toJSON 带上 `__curve`，
// 宿主用父控制器驱动同一条曲线（见 animation_bridge 的 jsDoubleAnimationOf）。
export class Tween {
  constructor(opts) {
    opts = opts || {};
    this.begin = opts.begin;
    this.end = opts.end;
  }
  lerp(t) {
    var b = this.begin, e = this.end;
    if (typeof b === 'number' && typeof e === 'number') { return b + (e - b) * t; }
    if (b && e && typeof b.dx === 'number' && typeof e.dx === 'number') {
      return new Offset(b.dx + (e.dx - b.dx) * t, b.dy + (e.dy - b.dy) * t);
    }
    return t < 0.5 ? b : e;
  }
}

export class CurvedAnimation {
  constructor(opts) {
    opts = opts || {};
    this.parent = opts.parent;
    this.curve = opts.curve;
  }
  get value() {
    var t = (this.parent && typeof this.parent.value === 'number') ? this.parent.value : 0;
    return __animCurveFn(this.curve)(t);
  }
  addListener(f) {
    if (this.parent && typeof this.parent.addListener === 'function') {
      this.parent.addListener(f);
    }
  }
  removeListener(f) {
    if (this.parent && typeof this.parent.removeListener === 'function') {
      this.parent.removeListener(f);
    }
  }
  toJSON() {
    return {
      __handle: this.parent ? this.parent.__id : null,
      __curve: this.curve,
      value: this.value
    };
  }
}

// 真实控制器在宿主（Ticker 驱动）；本镜像只保存 value 与时长：
//   - forward/reverse/repeat/stop/reset → `handleOp('call')`（载荷带 value 与
//     时长，宿主据此对齐状态后再驱动）；
//   - 宿主每帧回传 value → onHost 更新镜像 + __notify（JS listeners 据此重建）。
export const AnimationController = defineController('ctrl/Flash', {
  init: function (opts) {
    opts = opts || {};
    this._value = (typeof opts.value === 'number') ? opts.value : 0;
    this.lowerBound = (typeof opts.lowerBound === 'number') ? opts.lowerBound : 0;
    this.upperBound = (typeof opts.upperBound === 'number') ? opts.upperBound : 1;
    this.durationMs = __durationMs(opts.duration);
    if (this.durationMs == null) { this.durationMs = 300; }
  },
  onHost: function (self, p) {
    if (p != null && typeof p === 'number') {
      self._value = p;
      self.__notify();
    }
  },
  extraJSON: function (self) {
    return { value: self._value, durationMs: self.durationMs };
  }
});
Object.defineProperty(AnimationController.prototype, 'value', {
  get: function () { return this._value; },
  set: function (v) {
    var n = (typeof v === 'number') ? v : 0;
    if (this._value === n) { return; }
    this._value = n;
    if (this.__id != null) {
      handleOp(this.__id, 'set', { name: 'value', value: n });
    }
    this.__notify();
  }
});
AnimationController.prototype.__play = function (method, opts) {
  if (this.__id == null) { return; }
  // 生成器把命名实参摊平为位置实参（`repeat(reverse: true)` → `repeat(true)`），
  // 故 opts 可能是布尔（reverse）/ 数字（duration 毫秒）/ 对象三种形态，这里统一归一。
  var o = opts;
  if (o === true || o === false) { o = { reverse: o }; }
  else if (typeof o === 'number') { o = { duration: o }; }
  else { o = o || {}; }
  var ms = (o.duration != null) ? __durationMs(o.duration) : this.durationMs;
  handleOp(this.__id, 'call', {
    // id 一并下发：宿主基座的 onOp 不带 id，而「挂逐帧回传」需要它。
    id: this.__id,
    method: method,
    durationMs: ms,
    reverse: !!o.reverse,
    value: this._value
  });
};
AnimationController.prototype.forward = function (opts) {
  this.__play('forward', opts);
};
AnimationController.prototype.reverse = function (opts) {
  this.__play('reverse', opts);
};
AnimationController.prototype.repeat = function (opts) {
  this.__play('repeat', opts);
};
AnimationController.prototype.stop = function () {
  this.__play('stop', null);
};
AnimationController.prototype.reset = function () {
  this.__play('reset', null);
};

// 生成器把 Dart 侧 `final ScrollController _scrollController = ScrollController();`
// 翻译成 `this._scrollController = new ScrollController()`；实例与宿主侧真实
// ScrollController 按**句柄 id** 绑定。
// 三件套基座（__listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由通用
// 工厂 defineController 提供（见【4】）；本类只写差异：
//   - offset / position / hasClients：本地镜像（宿主回传 metrics 更新）；
//   - jumpTo/animateTo：实例级 host 通道（载荷带 id，多实例互不干扰）；
//   - addListener/removeListener：JS 闭包直接登记——**匿名闭包天然支持**，
//     无需生成器合成方法名，不存在重名问题。
// 跨桥序列化：props 里的实例经 toJSON 输出 `{__handle: id}`，宿主据此取/建
// 真实 controller（见 scroll_controller_bridge.dart）。
// 动画实参归一：Dart 的具名实参在 JS 调用里是**位置化扁平**（JS 无具名参数），
// 因此 `animateTo(offset, duration: d, curve: c)` 到运行时就是
// `(offset, d, c)`；也兼容直接传 options 对象的形态。三种 duration 形态
// （Duration 实例 / options.duration 毫秒数 / options.duration 为 Duration）
// 与两种 curve 形态（字符串 / options.curve）统一归一。
function __animArgs(opts, curveArg) {
  var ms = 300;
  var curve = 'easeOut';
  if (opts != null) {
    if (typeof opts.inMilliseconds === 'number') {
      ms = opts.inMilliseconds;
    } else if (typeof opts.duration === 'number') {
      ms = opts.duration;
    } else if (opts.duration && typeof opts.duration.inMilliseconds === 'number') {
      ms = opts.duration.inMilliseconds;
    }
    if (typeof opts.curve === 'string') { curve = opts.curve; }
  }
  if (typeof curveArg === 'string') { curve = curveArg; }
  return { ms: ms, curve: curve };
}
export const ScrollController = defineController('ctrl/Scroll', {
  init: function () {
    this.offset = 0;
    this.__maxScrollExtent = 0;
    this.__viewportDimension = 0;
    this.__extentAfter = 0;
  },
  // 宿主回传 metrics 快照 → 更新镜像并触发 listeners（listener 无参，
  // 与 Dart addListener 语义一致；闭包内读 this._scrollController.offset）。
  onHost: function (self, p) {
    if (!p) { return; }
    self.offset = p.pixels;
    self.__maxScrollExtent = p.maxScrollExtent;
    self.__viewportDimension = p.viewportDimension;
    self.__extentAfter = p.extentAfter;
    self.__notify();
  },
});
ScrollController.prototype.jumpTo = function (offset) {
  if (this.__id != null) { handleOp(this.__id, 'call', { method: 'jumpTo', args: [offset] }); }
};
ScrollController.prototype.animateTo = function (offset, opts, curveArg) {
  if (this.__id == null) { return; }
  var a = __animArgs(opts, curveArg);
  handleOp(this.__id, 'call', { method: 'animateTo', args: [offset, a.ms, a.curve] });
};
Object.defineProperty(ScrollController.prototype, 'position', {
  get: function () {
    return {
      pixels: this.offset,
      maxScrollExtent: this.__maxScrollExtent,
      viewportDimension: this.__viewportDimension,
      extentAfter: this.__extentAfter
    };
  }
});
Object.defineProperty(ScrollController.prototype, 'hasClients', {
  get: function () { return this.__id != null; }
});

// ===== PageController 代理类（对应 Flutter 官方 PageController）=====
// 与 ScrollController 同一套句柄层；镜像字段只有 page / initialPage。
// 构造参数（initialPage / viewportFraction）随 toJSON 的 extraJSON 下发，
// 宿主 PageView renderer 据此创建真实 PageController。
export const PageController = defineController('ctrl/Page', {
  init: function (opts) {
    var o = opts || {};
    this.initialPage = (o.initialPage != null) ? o.initialPage : 0;
    this.page = this.initialPage;
    this.viewportFraction = (o.viewportFraction != null) ? o.viewportFraction : 1.0;
  },
  onHost: function (self, p) {
    if (p && p.page != null) { self.page = p.page; }
    self.__notify();
  },
  extraJSON: function (self) {
    return {
      initialPage: self.initialPage,
      viewportFraction: self.viewportFraction
    };
  }
});
PageController.prototype.jumpToPage = function (page) {
  if (this.__id != null) { handleOp(this.__id, 'call', { method: 'jumpToPage', args: [page] }); }
};
PageController.prototype.animateToPage = function (page, opts, curveArg) {
  if (this.__id == null) { return; }
  var a = __animArgs(opts, curveArg);
  handleOp(this.__id, 'call', { method: 'animateToPage', args: [page, a.ms, a.curve] });
};
PageController.prototype.nextPage = function (opts, curveArg) {
  if (this.__id == null) { return; }
  var a = __animArgs(opts, curveArg);
  handleOp(this.__id, 'call', { method: 'nextPage', args: [a.ms, a.curve] });
};
PageController.prototype.previousPage = function (opts, curveArg) {
  if (this.__id == null) { return; }
  var a = __animArgs(opts, curveArg);
  handleOp(this.__id, 'call', { method: 'previousPage', args: [a.ms, a.curve] });
};
Object.defineProperty(PageController.prototype, 'hasClients', {
  get: function () { return this.__id != null; }
});

// TextEditingController：JS 侧代理类，与宿主真实 TextEditingController 按
// **句柄 id** 绑定（通用层，同 ScrollController 模式）。
// 三件套基座（__listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由通用
// 工厂 defineController 提供（见【4】）；本类只写差异：
//   - text：本地镜像（宿主经 textFn 回传更新），setter 发 host set 同步宿主；
//   - selection：本地镜像，setter 发 host setSelection；
//   - clear()：发 host clear + 清镜像；
//   - TextField(controller: 句柄) 渲染时宿主按 id 取真实实例，用户输入经
//     textFn 回传 JS 镜像并触发 listeners。
// 跨桥序列化：props 里的实例经 toJSON 输出 `{__handle: id}`。
export const TextEditingController = defineController('ctrl/Text', {
  init: function (initial) {
    this.__text =
    (initial && typeof initial.text === 'string') ? initial.text : '';
    this.__selection = null;
  },
  // 宿主回传（TextField 输入后同步镜像 + 触发 listeners）。
  onHost: function (self, t) {
    self.__text = (t == null) ? '' : String(t);
    self.__notify();
  },
});
TextEditingController.prototype.clear = function () {
  this.__text = '';
  if (this.__id != null) { handleOp(this.__id, 'call', { method: 'clear' }); }
  this.__notify();
};
Object.defineProperty(TextEditingController.prototype, 'text', {
  get: function () { return this.__text; },
  set: function (v) {
    this.__text = (v == null) ? '' : String(v);
    if (this.__id != null) {
      handleOp(this.__id, 'set', { name: 'text', value: this.__text });
    }
    this.__notify();
  }
});
Object.defineProperty(TextEditingController.prototype, 'selection', {
  get: function () { return this.__selection; },
  set: function (s) {
    this.__selection = s;
    if (this.__id != null) {
      var b = (s && typeof s.baseOffset === 'number') ? s.baseOffset : 0;
      var e = (s && typeof s.extentOffset === 'number') ? s.extentOffset : b;
      handleOp(this.__id, 'call', { method: 'setSelection', args: [b, e] });
    }
  }
});

export const FocusNode = defineController('ctrl/Focus', {
  init: function (opts) {
    var o = opts || {};
    this.__hasFocus = false;
    this.__debugLabel = (o.debugLabel != null) ? String(o.debugLabel) : null;
    this.__skipTraversal = o.skipTraversal === true;
    this.__canRequestFocus = o.canRequestFocus !== false;
    this.__descendantsAreFocusable = o.descendantsAreFocusable !== false;
  },
  onHost: function (self, v) {
    self.__hasFocus = v === true;
    self.__notify();
  },
  meta: function (self) {
    return {
      debugLabel: self.__debugLabel,
      skipTraversal: self.__skipTraversal,
      canRequestFocus: self.__canRequestFocus,
      descendantsAreFocusable: self.__descendantsAreFocusable
    };
  }
});
FocusNode.prototype.requestFocus = function () {
  if (this.__id != null) { handleOp(this.__id, 'call', { method: 'requestFocus' }); }
};
FocusNode.prototype.unfocus = function () {
  if (this.__id != null) { handleOp(this.__id, 'call', { method: 'unfocus' }); }
};
Object.defineProperty(FocusNode.prototype, 'hasFocus', {
  get: function () { return this.__hasFocus === true; }
});

// LogicalKeyboardKey：keyId → 实例（身份去重，常量与事件共用同一张表）。
var __keyInstances = {};
function __logicalKey(keyId, label) {
  var k = __keyInstances[keyId];
  if (!k) {
    k = { keyId: keyId, keyLabel: label || '', debugName: label || '' };
    __keyInstances[keyId] = k;
  }
  return k;
}

// 常量表：名字 → [keyId, keyLabel]。宿主回传的事件按 keyId 归一，所以这里
// 只登记「JS 源码里可能出现的名字」，两端读到的仍是同一实例。
var __KEY_CONSTS = {
  space: [0x00000000020, 'Space'],
  enter: [0x0010000000D, 'Enter'],
  escape: [0x0010000001B, 'Escape'],
  tab: [0x00100000009, 'Tab'],
  backspace: [0x00100000008, 'Backspace'],
  delete: [0x0010000007F, 'Delete'],
  capsLock: [0x00100000104, 'Caps Lock'],
  arrowUp: [0x00100000304, 'Arrow Up'],
  arrowDown: [0x00100000301, 'Arrow Down'],
  arrowLeft: [0x00100000302, 'Arrow Left'],
  arrowRight: [0x00100000303, 'Arrow Right'],
  home: [0x00100000306, 'Home'],
  end: [0x00100000305, 'End'],
  pageUp: [0x00100000308, 'Page Up'],
  pageDown: [0x00100000307, 'Page Down'],
  controlLeft: [0x00200000100, 'Control Left'],
  controlRight: [0x00200000101, 'Control Right'],
  shiftLeft: [0x00200000102, 'Shift Left'],
  shiftRight: [0x00200000103, 'Shift Right'],
  altLeft: [0x00200000104, 'Alt Left'],
  altRight: [0x00200000105, 'Alt Right'],
  metaLeft: [0x00200000106, 'Meta Left'],
  metaRight: [0x00200000107, 'Meta Right']
};
// 数字与字母键：logical keyId 就是字符码（digit0 = 0x30，keyA = 0x61），
// keyLabel 与 Flutter 一致（大写字母 / 数字本身）。
for (var __d = 0; __d < 10; __d++) {
  __KEY_CONSTS['digit' + __d] = [0x30 + __d, String(__d)];
}
for (var __c = 0; __c < 26; __c++) {
  var __letter = String.fromCharCode(0x61 + __c).toUpperCase();
  __KEY_CONSTS['key' + __letter] = [0x61 + __c, __letter];
}
export const LogicalKeyboardKey = {};
for (var __name in __KEY_CONSTS) {
  __defineProtoGetter(LogicalKeyboardKey, __name, (function (name) {
    return function () { return __logicalKey(__KEY_CONSTS[name][0], __KEY_CONSTS[name][1]); };
  })(__name));
}

// PhysicalKeyboardKey：`event.physicalKey.usbHidUsage` 按 usb 码归一。
var __physKeys = {};
export class PhysicalKeyboardKey {
  constructor(props) {
    props = props || {};
    this.usbHidUsage = props.usbHidUsage;
    this.debugName = props.debugName || '';
  }
}
function __physicalKey(usb, label) {
  var k = __physKeys[usb];
  if (!k) {
    k = new PhysicalKeyboardKey({ usbHidUsage: usb, debugName: label });
    __physKeys[usb] = k;
  }
  return k;
}

// KeyEvent：Dart 的 KeyEvent 是抽象基类，按下 / 抬起 / 重复是三个子类，
// 源码用 `event is KeyDownEvent` 区分——这里生成真子类以保持同一语义。
export class KeyEvent {
  constructor(props) {
    props = props || {};
    this.physicalKey = props.physicalKey;
    this.logicalKey = props.logicalKey;
    this.character = props.character == null ? null : String(props.character);
    this.timeStamp = props.timeStamp;
  }
}

// 按键事件子类：Dart 侧各自是 KeyEvent 的子类，JS 侧原生 extends（这样
// `instanceof KeyDownEvent` 与 `instanceof KeyEvent` 同时成立）。
export class KeyDownEvent extends KeyEvent {
  constructor(props) { super(props); }
}
export class KeyUpEvent extends KeyEvent {
  constructor(props) { super(props); }
}
export class KeyRepeatEvent extends KeyEvent {
  constructor(props) { super(props); }
}

// 宿主桥接见 capabilities/keyboard_listener/keyboard_listener_bridge.dart：
// 原生 KeyEvent → JSON（kind / character / keyId / keyLabel / usbHidUsage /
// timeStamp），这里还原成实例并调事件句柄。挂 G：宿主经 evaluate 裸引用调用。
G.__jsuiKeyEvent = function (handleId, eventJson) {
  var h = handles[handleId];
  if (!h || typeof h.obj !== 'function') { return; }
  var m = {};
  try { m = JSON.parse(eventJson) || {}; } catch (e) { return; }
  var Ctor = __KEY_EVENT_SUBCLASSES[m.kind] || KeyEvent;
  h.obj(new Ctor({
    character: m.character,
    logicalKey: __logicalKey(m.logicalKeyId, m.logicalKeyLabel),
    physicalKey: __physicalKey(m.physicalKeyUsb, m.physicalKeyLabel),
    timeStamp: new Duration({ microseconds: m.timeStampUs || 0 })
  }));
};

// ctx 句柄 id -> {
//   anchor, all, allKey, vals: {aspect: value}, keys: {aspect: key},
//   pending: {aspect: true}, missing: {aspect: true}
// }
var __jsuiMqByCtx = {};
// 最近一次解析到的整份真值：新 ctx 首帧尚未回填时先读它（同一运行时同一窗口，
// 基本等价），避免「先显示 0x0 再校正」的闪一帧。
var __jsuiMqLastAll = null;
// 真值到达前的兜底常量（构造一次）：字段齐全，避免读崩。
var __jsuiMqFallback = null;

function __jsuiMqScale(factor) {
  return { __factor: factor, scale: function (x) { return this.__factor * x; } };
}

function __jsuiMqEmpty() {
  if (__jsuiMqFallback == null) {
    __jsuiMqFallback = __jsuiMqBuild({
      size: { width: 0, height: 0 },
      padding: { left: 0, top: 0, right: 0, bottom: 0 },
      viewPadding: { left: 0, top: 0, right: 0, bottom: 0 },
      viewInsets: { left: 0, top: 0, right: 0, bottom: 0 },
      devicePixelRatio: 1,
      textScaleFactor: 1,
      orientation: Orientation.portrait,
      platformBrightness: Brightness.light,
      alwaysUse24HourFormat: false,
      accessibleNavigation: false,
      disableAnimations: false,
      invertColors: false,
      highContrast: false,
      boldText: false,
      navigationMode: NavigationMode.traditional,
    });
  }
  return __jsuiMqFallback;
}

// 宿主下发的 JSON → JS 侧 MediaQueryData 同形对象（aspect = null 时整份）。
function __jsuiMqBuild(json) {
  var s = json.size || { width: 0, height: 0 };
  var f = json.textScaleFactor != null ? json.textScaleFactor : 1;
  return {
    size: new Size({ width: s.width, height: s.height }),
    padding: json.padding,
    viewPadding: json.viewPadding,
    viewInsets: json.viewInsets,
    devicePixelRatio: json.devicePixelRatio,
    textScaleFactor: f,
    textScaler: __jsuiMqScale(f),
    orientation: json.orientation,
    platformBrightness: json.platformBrightness,
    alwaysUse24HourFormat: json.alwaysUse24HourFormat,
    accessibleNavigation: json.accessibleNavigation,
    disableAnimations: json.disableAnimations,
    invertColors: json.invertColors,
    highContrast: json.highContrast,
    boldText: json.boldText,
    navigationMode: json.navigationMode,
  };
}

// 单 aspect 的宿主原值 → 本端值（size 包成 Size、textScaler 包出 scale 方法，
// 其余是标量 / 已同形的对象，原样用）。
function __jsuiMqDecode(aspect, raw) {
  if (aspect == null) { return __jsuiMqBuild(raw); }
  if (aspect === 'size') {
    return new Size({ width: raw.width, height: raw.height });
  }
  if (aspect === 'textScaler') { return __jsuiMqScale(raw.__factor); }
  return raw;
}

function __jsuiMqEntry(id, context) {
  var e = __jsuiMqByCtx[id];
  if (!e) {
    e = __jsuiMqByCtx[id] = {
      anchor: context ? context.__anchor : null,
      all: null, allKey: '',
      vals: {}, keys: {}, pending: {}, missing: {},
    };
  }
  return e;
}

// 唯一写口：宿主回填 / 变化回推。
//   aspect = null → 整份数据；否则只更新该 aspect。
//   **与缓存不同才标脏**（一次真值变化只重建一次）。
function __jsuiSetMediaQuery(ctxId, aspect, raw) {
  var id = String(ctxId);
  var e = __jsuiMqEntry(id, null);
  if (raw == null) {
    // 该位置上方没有 MediaQuery：标记后不再重试，避免每次 build 都发桥消息。
    e.missing[aspect] = true;
    return;
  }
  var key = JSON.stringify(raw);
  if (aspect == null) {
    if (e.allKey === key) { return; }
    e.allKey = key;
    e.all = __jsuiMqBuild(raw);
    __jsuiMqLastAll = e.all;
  } else {
    if (e.keys[aspect] === key) { return; }
    e.keys[aspect] = key;
    e.vals[aspect] = __jsuiMqDecode(aspect, raw);
  }
  var a = e.anchor;
  if (a && a.__unmounted) {
    // 组件已卸载（句柄即将/已被释放）：丢掉这条缓存，不再标脏。
    delete __jsuiMqByCtx[id];
    return;
  }
  if (a) { markDirty(a); }
}

// 按 aspect 向宿主取一次值（每个 aspect 只取一次，之后靠回推）。
function __jsuiMqFetch(e, id, aspect) {
  var slot = aspect == null ? 'all' : aspect;
  if (e.pending[slot] || e.missing[slot]) { return; }
  e.pending[slot] = true;
  try {
    var p = handleOp(id, 'mediaQuery',
    aspect == null ? null : { 'aspect': aspect });
    if (p && typeof p.then === 'function') {
      p.then(function (raw) {
        e.pending[slot] = false;
        __jsuiSetMediaQuery(id, aspect, raw);
      }, function () { e.pending[slot] = false; });
    } else {
      e.pending[slot] = false;
    }
  } catch (err) {
    e.pending[slot] = false;
  }
}

// `MediaQuery.of(context)`：整份数据（依赖全部 aspect）。
function __jsuiMqOf(context) {
  var id = null;
  try { id = context.__handle(); } catch (err) { id = null; }
  if (id == null) { return __jsuiMqLastAll || __jsuiMqEmpty(); }
  var e = __jsuiMqEntry(id, context);
  if (e.all == null) { __jsuiMqFetch(e, id, null); }
  return e.all || __jsuiMqLastAll || __jsuiMqEmpty();
}

// `MediaQuery.<x>Of(context)`：只依赖该 aspect。
function __jsuiMqAspect(context, aspect) {
  var id = null;
  try { id = context.__handle(); } catch (err) { id = null; }
  if (id == null) { return (__jsuiMqLastAll || __jsuiMqEmpty())[aspect]; }
  var e = __jsuiMqEntry(id, context);
  var v = e.vals[aspect];
  if (v === undefined) { __jsuiMqFetch(e, id, aspect); }
  if (v !== undefined) { return v; }
  // 该 aspect 还没回来：从整份数据 / 最近值 / 兜底里取同名字段投影。
  var src = e.all || __jsuiMqLastAll || __jsuiMqEmpty();
  return src[aspect];
}

// Dart 的静态取值方法：每个都按自己的 aspect 代理（取值 + 重建粒度都对齐）。
export const MediaQuery = {
  of: function (context) { return __jsuiMqOf(context); },
  // `maybeOf` 语义：没有 MediaQuery 祖先时返回 null；这里退化为兜底对象
  // （字段齐全，读不崩），与 `of` 同源。
  maybeOf: function (context) { return __jsuiMqOf(context); },
  sizeOf: function (context) { return __jsuiMqAspect(context, 'size'); },
  paddingOf: function (context) { return __jsuiMqAspect(context, 'padding'); },
  viewPaddingOf: function (context) {
    return __jsuiMqAspect(context, 'viewPadding');
  },
  viewInsetsOf: function (context) {
    return __jsuiMqAspect(context, 'viewInsets');
  },
  devicePixelRatioOf: function (context) {
    return __jsuiMqAspect(context, 'devicePixelRatio');
  },
  textScalerOf: function (context) {
    return __jsuiMqAspect(context, 'textScaler');
  },
  orientationOf: function (context) {
    return __jsuiMqAspect(context, 'orientation');
  },
  platformBrightnessOf: function (context) {
    return __jsuiMqAspect(context, 'platformBrightness');
  },
  navigationModeOf: function (context) {
    return __jsuiMqAspect(context, 'navigationMode');
  },
  alwaysUse24HourFormatOf: function (context) {
    return __jsuiMqAspect(context, 'alwaysUse24HourFormat');
  },
  accessibleNavigationOf: function (context) {
    return __jsuiMqAspect(context, 'accessibleNavigation');
  },
  boldTextOf: function (context) {
    return __jsuiMqAspect(context, 'boldText');
  },
  disableAnimationsOf: function (context) {
    return __jsuiMqAspect(context, 'disableAnimations');
  },
  highContrastOf: function (context) {
    return __jsuiMqAspect(context, 'highContrast');
  },
  invertColorsOf: function (context) {
    return __jsuiMqAspect(context, 'invertColors');
  },
};

G.__jsuiSetMediaQuery = __jsuiSetMediaQuery;

// 可变状态按属性实时读写：`building` / `activeRoot` 是核心闭包里的 var，
// 解构 const 只会拿到求值当时的快照。
function __panelBuilding() { return G.__core.building; }
function __panelActiveRoot() { return G.__core.activeRoot; }
function __panelSetActiveRoot(v) { G.__core.activeRoot = v; }

// 面板序号：key 既是 JS 侧独立根的 pageKey，也是宿主侧 store 的路由键。
var panelSeq = 0;
// key -> { key, kind, el, caller, root, result, hasResult, resolve, reject }
var panels = {};

function newPanelKey() {
  panelSeq += 1;
  return 'jsui_panel_' + panelSeq;
}

// 弹层参数里的「可跨桥的标量 / 值对象」：builder 与 context 留在本端，
// 其余按 JSON 下发（Color 等值类自带 toJSON）。
function panelOptionsJson(options) {
  var out = {};
  for (var k in options) {
    if (k === 'context' || k === 'builder') { continue; }
    var v = options[k];
    if (v === null || v === undefined) { continue; }
    if (typeof v === 'function') { continue; }
    out[k] = v;
  }
  return out;
}

// 按「消费它的调用位置」定位面板。三条命中路径按可信度排序：
//   1. 面板上下文代理（builder 的形参 ctx 被打了 `__panelKey`）——最准，
//      嵌套 showDialog 时每个 builder 各自指向自己的面板，不会串台；
//   2. 组件实例的 `__root` 是面板根（弹层内容里的组件调 pop）——按树归属；
//   3. 兜底：同一调用方打开的面板里**最近打开**的那个（LIFO，与 Dart 里
//      `Navigator.pop` 弹最上层路由同义）。
function panelOf(context) {
  if (context && context.__panelKey) {
    var tagged = panels[context.__panelKey];
    if (tagged) { return tagged; }
  }
  var inst = null;
  if (context && context.__anchor) { inst = context.__anchor; }
  else if (context && context.__root) { inst = context; }
  else if (__panelBuilding()) { inst = __panelBuilding(); }
  if (!inst) { return null; }
  var root = inst.__root;
  if (root && panels[root.key]) { return panels[root.key]; }
  var found = null;
  for (var k in panels) {
    if (panels[k].caller === inst) { found = panels[k]; }
  }
  return found;
}

// 打开面板：builder 执行一次 → 建面板记录 → 请求宿主 push 路由。
// 返回的 Promise 与 Dart `showDialog<T>` 的 Future 同义（结果为 pop 传的值）。
function openPanel(kind, options) {
  if (!options || typeof options !== 'object') { options = {}; }
  // 调用方实例：事件执行期取当前构建位置；延迟副作用里（构建位置为空）取
  // 传入 context 代理的锚点实例——面板根因此挂在调用方的 `__parent` 链上，
  // 弹层里的 `context.watch/read` 仍能看到页面的 provider 作用域。
  var given = options.context;
  var caller = __panelBuilding() || (given && given.__anchor) || null;
  var callerNode = given && given.__nodeId
  ? given.__nodeId
  : (caller ? contextOf(caller).__nodeId : null);
  var key = newPanelKey();
  // builder 的形参 ctx：**专用代理**（不打在调用方那个缓存代理上——`contextOf`
  // 按实例缓存，共用会把页面的代理永久指向某个面板）。带 `__panelKey` 后
  // `Navigator.pop(ctx)` / `Navigator.of(ctx)` 精确落到本面板，嵌套 showDialog
  // 也不会串台。
  var anchor = new JsBuildContext(caller, callerNode);
  anchor.__panelKey = key;
  // 建树回调按 Flutter 的原形参名取：`showDialog` / `showModalBottomSheet`
  // 等用 `builder`，`showGeneralDialog` 用 `pageBuilder`——两者都是「在弹层
  // 上下文里建一次树」，协议相同，这里不按 API 名特判。
  var buildFn = typeof options.builder === 'function'
  ? options.builder
  : (typeof options.pageBuilder === 'function' ? options.pageBuilder : null);
  var built = null;
  if (buildFn) {
    // 与 Dart 一致：建树回调立即执行（在弹层上下文里建树）。
    // 只传 ctx：`pageBuilder` 的 animation / secondaryAnimation 是宿主侧的
    // 动画对象，JS 端没有可等价的值（用到的话属于未支持项）。
    built = buildFn(anchor);
  }
  var el = asElement(built);
  var p = {
    key: key, kind: kind, el: el, caller: caller, root: null,
    result: null, hasResult: false, resolve: null, reject: null
  };
  var promise = new Promise(function (resolve, reject) {
    p.resolve = resolve;
    p.reject = reject;
  });
  panels[key] = p;
  host('jsuiPanelOpen', [{
      key: key,
      kind: kind,
      anchor: anchor.__nodeId,
      options: panelOptionsJson(options)
    }]).then(function () {}, function (err) {
    // 宿主没打开（无可用 BuildContext / 路由失败）：撤销本端记录，让
    // `await showDialog(...)` 的调用方拿到异常，而不是永远悬着的 Promise。
    if (panels[key] === p) { delete panels[key]; }
    if (p.reject) { p.reject(err); }
  });
  return promise;
}

// 宿主首帧后回调：把 builder 产出的元素树挂到独立根上并下发首批补丁。
// 幂等：重复调用（重建 / 二次回调）直接返回。
function panelMount(key) {
  var p = panels[key];
  if (!p || p.root) { return false; }
  var root = newRoot(key);
  roots[key] = root;
  var prev = __panelActiveRoot();
  __panelSetActiveRoot(root);
  root.mounting = true;
  try {
    root.ops = [];
    // parent = 调用方实例：`__parent` 链因此与页面连通（provider 等按类型
    // 向上的作用域照常可见）；slot=null 故不产出 insert op。
    root.inst = mount(p.el, p.caller, null);
    emit({ op: 'root', id: hostIdOf(root.inst) });
    commit(root);
  } catch (e) {
    abortRoot(root);
    throw e;
  } finally {
    root.mounting = false;
    __panelSetActiveRoot(prev);
  }
  p.root = root;
  // 挂载期间累积的 setState（initState 里同步 setState）补一次 flush。
  if (root.dirty.length) { flushNow(root); }
  return true;
}

// 宿主路由关闭后回调（barrier / 返回键 / Navigator.pop 都汇到这一条）：
// 卸载独立根 → 结算 Promise。本端清理由 unmount 逐实例释放，页面兜底
// （releasePageHandles）保证任何残留都不会跨面板累积。
function panelClosed(key) {
  var p = panels[key];
  if (!p) { return false; }
  delete panels[key];
  var root = p.root || roots[key] || null;
  p.root = null;
  p.el = null;
  p.caller = null;
  if (root && root.inst) {
    var prev = __panelActiveRoot();
    __panelSetActiveRoot(root);
    try {
      // ops 丢弃即可：宿主那棵子树随路由一起销毁，无需回传 remove。
      root.ops = [];
      unmount(root.inst);
    } finally {
      root.ops = null;
      __panelSetActiveRoot(prev);
    }
    root.inst = null;
  }
  delete roots[key];
  releasePageHandles(key);
  var resolve = p.resolve;
  p.resolve = null;
  p.reject = null;
  if (resolve) { resolve(p.hasResult ? p.result : null); }
  return true;
}

// `Navigator.pop(context, result)` 的 JS 侧落点：结果**不回传宿主**（宿主
// 侧路由只负责关闭），所以 pop 传的值留在本端，关闭回调时直接结算。
//
// 返回 false 表示 context 不在任何面板里：页面级路由由宿主 App 自己管理，
// JS 侧不越权（也做不到——路由栈在 Dart）。
function panelPop(context, result) {
  var p = panelOf(context);
  if (!p) {
    // 明确出声：这类调用不会被静默忽略，否则表现为「点了没反应」。
    console.warn('jsui: Navigator.pop 未命中任何弹层面板（页面级路由请由宿主管理）');
    return false;
  }
  p.result = result;
  p.hasResult = true;
  host('jsuiPanelPop', [p.key]).then(function () {}, function () {});
  return true;
}

// ── 对外 API：Dart 顶层函数一比一（全部具名实参 → 单个 options 对象）──
// Dart 侧签名（NamedArgument 全部落进 options 对象，由宿主按 kind 还原）：
//   showDialog<T>({context, builder, barrierDismissible, barrierColor, …})
export function showDialog(options) { return openPanel('dialog', options); }
// 自适应：iOS / macOS 走 Cupertino，其余走 Material（宿主调 showAdaptiveDialog）。
export function showAdaptiveDialog(options) { return openPanel('adaptive', options); }
export function showGeneralDialog(options) { return openPanel('general', options); }
export function showCupertinoDialog(options) { return openPanel('cupertino', options); }
export function showModalBottomSheet(options) { return openPanel('sheet', options); }
// Cupertino 的模态弹层（通常承载 CupertinoActionSheet）：与 Material 的
// showModalBottomSheet 语义不同（路由/动画/安全区归属都是 Cupertino 的）。
export function showCupertinoModalPopup(options) { return openPanel('cupertinoSheet', options); }

// 宿主侧两个入口（路由首帧后挂载 / 路由关闭后卸载）装到 `__jsui`：
// runtime.js 的 api 不再包含任何面板知识。
G.__jsui.panelMount = panelMount;
G.__jsui.panelClosed = panelClosed;

export class Navigator {
  constructor(context) { this.__context = context; }
  static of(context, opts) { return new Navigator(context); }
  static maybeOf(context, opts) { return new Navigator(context); }
  static pop(context, result) { return panelPop(context, result); }
  static maybePop(context, result) { return panelPop(context, result); }
  pop(result) { return panelPop(this.__context, result); }
  maybePop(result) { return panelPop(this.__context, result); }
  canPop() { return panelOf(this.__context) !== null; }
}

// ── data 身份表：任意 JS 值 ⇄ 跨桥 id ──
var __dragDataSeq = 0;
var __dragDataIds = new Map();
var __dragDataRefs = new Map();

function __dragRef(value) {
  if (value == null) { return null; }
  var id = __dragDataIds.get(value);
  if (id) { return id; }
  id = 'jsui_drag_' + (++__dragDataSeq);
  __dragDataIds.set(value, id);
  __dragDataRefs.set(id, value);
  return id;
}

function __dragData(id) {
  if (id == null) { return null; }
  return __dragDataRefs.has(id) ? __dragDataRefs.get(id) : id;
}

function __dragDataList(ids) {
  var out = [];
  if (!ids) { return out; }
  for (var i = 0; i < ids.length; i++) { out.push(__dragData(ids[i])); }
  return out;
}

// ── 事件详情还原：宿主只发 JSON（位置 → {dx, dy}，速度 → {pxPerSecond}）──
function __dragOffset(json) {
  json = json || {};
  return new Offset({
    dx: json.dx == null ? 0 : json.dx,
    dy: json.dy == null ? 0 : json.dy,
  });
}

function __dragUpdateDetails(json) {
  json = json || {};
  return {
    globalPosition: __dragOffset(json.globalPosition),
    localPosition: __dragOffset(json.localPosition),
    delta: __dragOffset(json.delta),
    primaryDelta: json.primaryDelta == null ? null : json.primaryDelta,
    sourceTimeStamp: json.sourceTimeStampUs == null
    ? null
    : new Duration({ microseconds: json.sourceTimeStampUs }),
  };
}

// `DraggableDetails`：字段与 Flutter 一致（**没有** `data`——负载要用用户
// 自己的闭包变量），`velocity` 是 Velocity 实例。
function __draggableDetails(json) {
  json = json || {};
  return {
    wasAccepted: json.wasAccepted === true,
    offset: __dragOffset(json.offset),
    velocity: new Velocity({
      pixelsPerSecond: __dragOffset(json.velocity && json.velocity.pxPerSecond),
    }),
  };
}

function __dragTargetDetails(json) {
  json = json || {};
  return { data: __dragData(json.data), offset: __dragOffset(json.offset) };
}

// ── Draggable / LongPressDraggable 共用的 props 折算 ──
// `data` 换成 id、四个事件换成句柄（用户回调留在本侧，宿主只回传 id / 位置）。
// 两个类共用本函数、各自给出宿主 type 名（不做「是不是某个类」的判断）。
function __dragSourceProps(self) {
  var p = self.props || {};
  var props = {};
  for (var k in p) {
    if (k === 'data' || k === 'onDragStarted' || k === 'onDragUpdate' ||
    k === 'onDragEnd' || k === 'onDragCompleted') { continue; }
    props[k] = p[k];
  }
  props.data = __dragRef(p.data);
  // 同一位点复用同一句柄：重建不新增跨语言句柄，卸载随实例释放。
  props.onDragStarted = self.__bindFn(0, [], function () {
    var f = self.props.onDragStarted;
    if (typeof f === 'function') { f(); }
  });
  props.onDragUpdate = self.__bindFn(1, [], function (json) {
    var f = self.props.onDragUpdate;
    if (typeof f === 'function') { f(__dragUpdateDetails(json)); }
  });
  props.onDragEnd = self.__bindFn(2, [], function (json) {
    var f = self.props.onDragEnd;
    if (typeof f === 'function') { f(__draggableDetails(json)); }
  });
  props.onDragCompleted = self.__bindFn(3, [], function () {
    var f = self.props.onDragCompleted;
    if (typeof f === 'function') { f(); }
  });
  return props;
}

// ── DragTarget 的 props 折算 ──
// `builder(context, candidateData, rejectedData)` 只能在 JS 里执行（候选/被拒
// 数据只在悬停时由宿主产生），与 LayoutBuilder 同一方案：登记成句柄，宿主
// 回调时把**id 列表**带回来，本侧换回原值后执行 builder，结果作为 `child`
// 插槽随下一次 patch 回填。
//
// `onWillAccept` / `onWillAcceptWithDetails` 需要**同步**返回 bool，跨语言只能
// 异步，故不接（宿主侧恒接受），并用一条警告把这件事说清楚。
function __dragTargetProps(self, context) {
  var p = self.props || {};
  var builder = p.builder;
  if (typeof builder !== 'function') {
    console.warn('[DragTarget] builder 不是闭包');
    return null;
  }
  if (typeof p.onWillAccept === 'function' ||
  typeof p.onWillAcceptWithDetails === 'function') {
    console.warn(
    '[DragTarget] onWillAccept / onWillAcceptWithDetails 需要同步返回值，' +
    '跨语言只能异步，已忽略（目标恒接受）'
    );
  }
  var props = {};
  for (var k in p) {
    if (k === 'builder' || k === 'onWillAccept' || k === 'onWillAcceptWithDetails' ||
    k === 'onAccept' || k === 'onAcceptWithDetails' ||
    k === 'onMove' || k === 'onLeave') { continue; }
    props[k] = p[k];
  }
  // 悬停时宿主会反复回调：同一次候选集合只重建一次子树（id 列表即身份签名）。
  props.builder = self.__bindFn(0, [], function (json) {
    json = json || {};
    var sig = (json.candidate || []).join('|') + '#' + (json.rejected || []).join('|');
    if (sig === self.__dragSig) { return; }
    self.__dragSig = sig;
    // 字段名不能叫 `__child`：那是 reconciler 记录本实例挂出的子宿主结点的
    // 内部字段，props 里再塞它会成环。
    self.__dragTargetChild = builder(
    context, __dragDataList(json.candidate), __dragDataList(json.rejected));
    self.setState(function () {});
  });
  props.onAccept = self.__bindFn(1, [], function (id) {
    var f = self.props.onAccept;
    if (typeof f === 'function') { f(__dragData(id)); }
  });
  props.onAcceptWithDetails = self.__bindFn(2, [], function (json) {
    var f = self.props.onAcceptWithDetails;
    if (typeof f === 'function') { f(__dragTargetDetails(json)); }
  });
  props.onMove = self.__bindFn(3, [], function (json) {
    var f = self.props.onMove;
    if (typeof f === 'function') { f(__dragTargetDetails(json)); }
  });
  props.onLeave = self.__bindFn(4, [], function (id) {
    var f = self.props.onLeave;
    if (typeof f === 'function') { f(__dragData(id)); }
  });
  if (self.__dragTargetChild != null) { props.child = self.__dragTargetChild; }
  return props;
}

// ── LayerLink：CompositedTransform 的锚点，句柄即身份 ──
defineHandleKind('layer/Link', {});
export class LayerLink {
  constructor(props) {
    this.__id = reg(this, 'layer/Link', {});
  }
  toJSON() {
    return { __handle: this.__id };
  }
}

// ── OverlayPortalController：命令发往宿主，本侧只镜像 isShowing ──
// show() / hide() 在未 attach 时也不会丢：宿主 OverlayPortalController 自身
// 记录 z 序，attach 时接管，故可以在 initState 里直接 show()。
defineHandleKind('overlay/Portal', {});
export class OverlayPortalController {
  constructor(props) {
    var debugLabel = __posArgs(props, ['debugLabel']).debugLabel;
    this.__showing = false;
    this.__id = reg(this, 'overlay/Portal', {
      meta: debugLabel == null ? null : { debugLabel: debugLabel }
    });
  }
  toJSON() {
    return { __handle: this.__id };
  }
  show() {
    this.__showing = true;
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'show' }); }
  }
  hide() {
    this.__showing = false;
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'hide' }); }
  }
  toggle() {
    if (this.__showing) { this.hide(); } else { this.show(); }
  }
  get isShowing() { return this.__showing; }
}

// 宿主下发的约束 JSON → BoxConstraints。
// 挂 G：包模块（flutter.js）只能裸引用全局，IIFE 内的局部声明它看不见。
G.__jsuiBoxConstraints = function (json) {
  json = json || {};
  return new BoxConstraints({
    minWidth: json.minWidth == null ? 0 : json.minWidth,
    maxWidth: json.maxWidth == null ? Infinity : json.maxWidth,
    minHeight: json.minHeight == null ? 0 : json.minHeight,
    maxHeight: json.maxHeight == null ? Infinity : json.maxHeight,
  });
};

// 生成器把 Dart 侧 `late final TabController _c = TabController(length: 3, vsync: this)`
// 翻译成 `this._c = new TabController({length: 3, vsync: this})`（vsync 由本代理
// 类忽略），实例与宿主侧真实 TabController 按**句柄 id** 绑定。
// 三件套基座（__listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由通用
// 工厂 defineController 提供（见【4】）；本类只写差异：
//   - length/__index：本地镜像（宿主回传 index 更新）；真实实例由宿主在渲染
//     TabBar / TabBarView 时按 id 取/建（length 随句柄下发，见 extraJSON）；
//   - index setter：立即设置宿主 index 并通知监听者；
//   - animateTo(i)：宿主 controller.animateTo（带动画）。
export const TabController = defineController('ctrl/Tab', {
  init: function (opts) {
    opts = opts || {};
    this.length = (typeof opts.length === 'number') ? opts.length : 0;
    this.__index = (typeof opts.initialIndex === 'number') ? opts.initialIndex : 0;
  },
  // 宿主回传（用户点 tab / animateTo 动画结束）→ 更新镜像 + 触发 listeners。
  // 值没变就不是状态变化，不能通知：宿主 attach 时会回传一次初始 index，
  // 若照常 notify，会让监听者（如外壳的 setState）做一次“原地刷新”，
  // 把已挂载子组件无谓地推进 didUpdateWidget → build。
  onHost: function (self, i) {
    if (typeof i !== 'number' || self.__index === i) { return; }
    self.__index = i;
    self.__notify();
  },
  // 跨桥序列化：`{__handle: id, length, initialIndex}`——宿主据此取/建真实
  // controller（见 capabilities/tab/tab_bridge.dart）。
  extraJSON: function (self) {
    return { length: self.length, initialIndex: self.__index };
  },
});
TabController.prototype.animateTo = function (index) {
  if (this.__id != null) { handleOp(this.__id, 'call', { method: 'animateTo', args: [index] }); }
};
Object.defineProperty(TabController.prototype, 'index', {
  get: function () { return this.__index; },
  set: function (v) {
    v = (typeof v === 'number') ? v : 0;
    // 同值：镜像没变化 → 不再下发宿主 op、也不再通知（避免一次假刷新）。
    if (this.__index === v) { return; }
    this.__index = v;
    if (this.__id != null) { handleOp(this.__id, 'set', { name: 'index', value: v }); }
    // 与 Dart 语义一致：直接设置 index 立即通知监听者（宿主回传同一值时
    // 会被 onHost 的同值判等吞掉，不会重复通知）。
    this.__notify();
  }
});

// TabBarView 是**懒容器**（子页被 SliverFillViewport 强制成整屏，零尺寸占位
// 布局中性）——不在运行时声明：由生成器配置 lazyChildHostTypes 在 __h 里给
// 元素打 `lazyChildren` 标记（见 hot_patch_generator 的 shared/js_class_defs.dart）。

// objectToken / keyValueSig / keySig 属于**运行时核心**（key_sig_js.dart，随
// runtime.js 先加载）：identity WeakMap 由核心与这里的 Key 类共用。
const objectToken = G.objectToken;

// ValueKey：按值相等，纯值 codec（不登记句柄）。
// 实例的**自有字段名 = 序列化字段名**（__vkey）：reconciler 的 keySig 用字段
// 形态判据，而 props.key 传的是 live 实例（不是 toJSON 产物），两边必须同形。
// 对象值跨语言保不住同一性，序列化退化为身份 token（与 keyValueSig 同源）。
export class ValueKey {
  constructor(props) { this.__vkey = __posArgs(props, ['value']).value; }
  toJSON() {
    var v = this.__vkey;
    if (v !== null && (typeof v === 'object' || typeof v === 'function')) {
      return { __vtok: objectToken(v) };
    }
    return { __vkey: v };
  }
}

// ObjectKey：按被包裹对象的身份相等（只留身份 token，不再持有对象引用）。
export class ObjectKey {
  constructor(props) { this.__okey = objectToken(__posArgs(props, ['value']).value); }
  toJSON() {
    return { __okey: this.__okey };
  }
}

// PageStorageKey：Dart 侧 `extends ValueKey`（按**值**相等），但宿主必须造
// **真实** PageStorageKey——它的意义是滚动位置按 key 存进 PageStorage bucket，
// 那是宿主端行为（JS 侧只有一个值本体）。故 codec 与 ValueKey 同构另加 `__psk`
// 标记：宿主据此造 PageStorageKey 而非 ValueKey，keySig 前缀 `p:` 使它与
// 同值的 ValueKey 不等（与 Dart 的 runtimeType 参与相等一致）。
export class PageStorageKey {
  constructor(props) {
    var value = __posArgs(props, ['value']).value;
    this.__psk = (value !== null && (typeof value === 'object' || typeof value === 'function'))
    ? { __vtok: objectToken(value) }
    : value;
  }
  toJSON() {
    return { __psk: this.__psk };
  }
}

// GlobalKey / UniqueKey：登记为句柄（scope=page，随页面回收），宿主持真实实例。
defineHandleKind('key/Global', {});
export class GlobalKey {
  constructor(props) {
    var debugLabel = __posArgs(props, ['debugLabel']).debugLabel;
    // 泛型实参由产物下发（`new GlobalKey({typeArguments: ['AnimatedListState']})`）：
    // Dart 的 `GlobalKey<T>` 在 AOT 是 reified 的，T 就是「currentState 的类型」，
    // 取值不需要问宿主、也不靠 runtimeType 猜。
    var ta = (props && props.typeArguments) || [];
    this.__stateType = ta.length ? ta[0] : null;
    this.__id = reg(this, 'key/Global', {
      meta: debugLabel == null ? null : { debugLabel: debugLabel }
    });
  }
  toJSON() {
    return { __handle: this.__id };
  }
  get currentContext() {
    return this.__id == null ? null : new KeyRef(this.__id);
  }
  get currentState() {
    if (this.__id == null) { return null; }
    // 首选泛型实参（`GlobalKey<AnimatedListState>` 的 T）；未声明泛型时才问
    // 宿主 runtimeType。两者都没有则退化为通用句柄（调用时宿主会告警）。
    var type = this.__stateType || handleOp(this.__id, '__type', {});
    return __stateProxyOf(this.__id, type);
  }
}

// GlobalKey.currentContext / findRenderObject()：BuildContext 与 RenderObject 是
// **宿主端**概念——JS 侧既没有真实对象，也没有同步取值的能力（JS→宿主只有异步
// 桥，见 handleOp）。故 currentContext 返回一个只携带 key 句柄 id 的代理，链式
// 调用在 JS 侧是空壳，最后一次调用经通用 op 落到宿主，由宿主用**真实**对象把
// Flutter 原生语义补全——位置/尺寸只在真正算得出来的一端计算。
//   - showOnScreen()：void 语义，fire-and-forget，宿主算出该结点位置并滚动；
//   - measure()：Flutter 的 `box.size` / `box.localToGlobal(Offset.zero)` 是
//     **同步属性**，而 JS→宿主只能异步，故这里返回 Promise（单源侧 `await`
//     后即为真实值，见 widget_details 的 _measureFixed）。
export class KeyRef {
  constructor(id) { this.__key = id; }
  showOnScreen() {
    if (this.__key != null) { handleOp(this.__key, 'showOnScreen', {}); }
  }
  measure() {
    if (this.__key == null) { return Promise.resolve(null); }
    return handleOp(this.__key, 'measure', {});
  }
  findRenderObject() {
    return new KeyRef(this.__key);
  }
}

// GlobalKey.currentState：StateHandle / __registerStateProxy 属于**运行时核心**
// （state_handle_js.dart，随 runtime.js 先加载），这里只补 `currentState` getter。
// 运行时**不认识任何业务方法**：代理类由生成器随组件写进 flutter.js，并用
// `__registerStateProxy(type, class)` 登记；类型来自 GlobalKey<T> 的泛型实参。

defineHandleKind('key/Unique', {});
export class UniqueKey {
  constructor() {
    this.__id = reg(this, 'key/Unique', {});
  }
  toJSON() {
    return { __handle: this.__id };
  }
}



// 宿主侧桥接见 capabilities/easy_refresh/easy_refresh_bridge.dart 的
// `_runAwaitableEvent`：evaluate 本函数触发一次事件，并等 token 回传。
// 挂 G（globalThis）：宿主经 evaluate 裸引用调用，与 `__jsui` 同一约定。
G.__jsuiAwaitRun = function (handleId, token) {
  var h = handles[handleId];
  var out = null;
  try {
    out = (h && typeof h.obj === 'function') ? h.obj() : null;
  } catch (e) {
    // 事件方法同步抛错：按「已完成」收尾——指示器必须收起，不能挂死在转圈。
    console.error(String(e));

  }
  // 完成回传走 host（唯一 JS→宿主出口）；onFulfilled / onRejected 都必须回传，
  // 否则宿主侧那条 pending 永远等不到结算。
  var done = function () { host('jsuiAwaitDone', [token]); };
  if (out && typeof out.then === 'function') {
    out.then(done, done);
  } else {
    done();
  }
};

// 与 ScrollController 同款句柄层（三件套见【4】defineController）：JS 实例与
// 宿主真实 EasyRefreshController 按句柄 id 绑定。控制方法把**原始实参数组**
// 原样下发（`handleOp 'call'`），由宿主按 Dart 形参的类型/顺序还原：
// 生成器对方法调用的具名实参是位置化扁平（JS 无具名参数），所以这里不臆造
// 形参名，交给宿主按类型判别（数值 → overOffset、Duration 值 → duration、
// 曲线名 → curve、布尔 → force）。
// 宿主侧桥接见 capabilities/easy_refresh/easy_refresh_bridge.dart。
export const EasyRefreshController = defineController('ctrl/EasyRefresh', {
  init: function (opts) {
    var o = opts || {};
    this.controlFinishRefresh = !!o.controlFinishRefresh;
    this.controlFinishLoad = !!o.controlFinishLoad;
  },
  // 构造参数随句柄 create 下发：宿主据此创建真实 controller（putIfAbsent——
  // 创建消息与首帧渲染谁先到都复用同一实例）。
  meta: function (self) {
    return {
      controlFinishRefresh: self.controlFinishRefresh,
      controlFinishLoad: self.controlFinishLoad
    };
  },
  // 组件渲染时 controller 经 toJSON 跨桥（`{__handle, controlFinish*}`），
  // Host 在渲染期兜底创建时同样读得到构造参数。
  extraJSON: function (self) {
    return {
      controlFinishRefresh: self.controlFinishRefresh,
      controlFinishLoad: self.controlFinishLoad
    };
  }
});
EasyRefreshController.prototype.__op = function (method, args) {
  if (this.__id == null) { return undefined; }
  return handleOp(this.__id, 'call', { method: method, args: args });
};
EasyRefreshController.prototype.callRefresh = function () {
  return this.__op('callRefresh', Array.prototype.slice.call(arguments));
};
EasyRefreshController.prototype.callLoad = function () {
  return this.__op('callLoad', Array.prototype.slice.call(arguments));
};
EasyRefreshController.prototype.openHeaderSecondary = function () {
  return this.__op('openHeaderSecondary', Array.prototype.slice.call(arguments));
};
EasyRefreshController.prototype.closeHeaderSecondary = function () {
  return this.__op('closeHeaderSecondary', Array.prototype.slice.call(arguments));
};
EasyRefreshController.prototype.openFooterSecondary = function () {
  return this.__op('openFooterSecondary', Array.prototype.slice.call(arguments));
};
EasyRefreshController.prototype.closeFooterSecondary = function () {
  return this.__op('closeFooterSecondary', Array.prototype.slice.call(arguments));
};
EasyRefreshController.prototype.resetHeader = function () {
  return this.__op('resetHeader', []);
};
EasyRefreshController.prototype.resetFooter = function () {
  return this.__op('resetFooter', []);
};
EasyRefreshController.prototype.finishRefresh = function () {
  return this.__op('finishRefresh', Array.prototype.slice.call(arguments));
};
EasyRefreshController.prototype.finishLoad = function () {
  return this.__op('finishLoad', Array.prototype.slice.call(arguments));
};

// 实参归一：正常形态是 `{duration, callback}`；构建期查不到签名时位置实参
// 落在 `__pos` 里，由 __posArgs 按形参名展开。容错地再支持一次
// 「第一个实参直接就是 Duration 对象」的形态，避免任何调用写法静默失效。
function __timerArgs(props, second) {
  var duration = null;
  var callback = null;
  if (props && typeof props.inMilliseconds === 'number') {
    duration = props;
    callback = second;
  } else {
    var opts = __posArgs(props, ['duration', 'callback']);
    duration = opts.duration;
    callback = opts.callback;
  }
  var ms = __durationMs(duration);
  if (ms == null || ms < 0) { ms = 0; }
  return { ms: ms, callback: callback };
}

export class Timer {
  constructor(props) {
    __timerInit(this, props, false, null);
  }
  cancel() {
    this._cancelled = true;
    this._active = false;
    if (this._handle != null && typeof clearTimeout === 'function') {
      try { clearTimeout(this._handle); } catch (e) {}
    }
    this._handle = null;
  }
  toJSON() {
    return { __timer: true, active: !!this._active, repeat: !!this._repeat, ms: this._ms };
  }
  static periodic(props, second) {
    var t = Object.create(Timer.prototype);
    __timerInit(t, props, true, second);
    return t;
  }
  get isActive() {
    return !!this._active;
  }
}

// __timerInit 在所有 Timer 实例间共用（构造与 periodic 两条入口）。
function __timerInit(self, props, repeat, second) {
  var args = __timerArgs(props, second);
  self._ms = args.ms;
  self._callback = args.callback;
  self._repeat = !!repeat;
  self._active = true;
  self._cancelled = false;
  self._handle = null;
  __timerSchedule(self);
}

function __timerSchedule(self) {
  if (self._cancelled) { return; }
  self._handle = setTimeout(function () {
    self._handle = null;
    if (self._cancelled) { return; }
    if (!self._repeat) { self._active = false; }
    try {
      if (typeof self._callback === 'function') { self._callback(self); }
    } catch (e) {
      console.error('[patch] Timer 回调异常: ' +
      ((e && e.message) ? e.message : e));
    }
    if (self._repeat && !self._cancelled) { __timerSchedule(self); }
  }, self._ms);
}



// Timer 不是跨语言句柄：万一被当作值下发，只带状态字段（调试友好，宿主侧无对应还原）。




// ===== Colors 常量（由 Flutter SDK colors.dart 自动生成）=====
// Dart 侧 `Colors` 是 `class Colors { static const MaterialColor red = … }`，
// 产物一比一：class + static 字段（不是对象字面量）。`Colors.red[400]`
// 原样求值，翻译层不含任何色值表，重构建即跟随 SDK。
function __colorsColor(v) { return new Color({ value: v }); }
function __colorsPalette(primary, shades) {
  const m = new MaterialColor({ primary: primary });
  for (const k in shades) {
    m[k] = __colorsColor(shades[k]);
    m["shade" + k] = m[k];
  }
  if (m["shade500"] === undefined) {
    m["500"] = m;
    m["shade500"] = m;
  }
  return m;
}
function __colorsAccent(primary, shades) {
  const m = new MaterialAccentColor({ primary: primary });
  for (const k in shades) {
    m[k] = __colorsColor(shades[k]);
    m["shade" + k] = m[k];
  }
  return m;
}
export class Colors {
  static red = __colorsPalette(0xFFF44336, {'50': 0xFFFFEBEE, '100': 0xFFFFCDD2, '200': 0xFFEF9A9A, '300': 0xFFE57373, '400': 0xFFEF5350, '500': 0xFFF44336, '600': 0xFFE53935, '700': 0xFFD32F2F, '800': 0xFFC62828, '900': 0xFFB71C1C});
  static pink = __colorsPalette(0xFFE91E63, {'50': 0xFFFCE4EC, '100': 0xFFF8BBD0, '200': 0xFFF48FB1, '300': 0xFFF06292, '400': 0xFFEC407A, '500': 0xFFE91E63, '600': 0xFFD81B60, '700': 0xFFC2185B, '800': 0xFFAD1457, '900': 0xFF880E4F});
  static purple = __colorsPalette(0xFF9C27B0, {'50': 0xFFF3E5F5, '100': 0xFFE1BEE7, '200': 0xFFCE93D8, '300': 0xFFBA68C8, '400': 0xFFAB47BC, '500': 0xFF9C27B0, '600': 0xFF8E24AA, '700': 0xFF7B1FA2, '800': 0xFF6A1B9A, '900': 0xFF4A148C});
  static deepPurple = __colorsPalette(0xFF673AB7, {'50': 0xFFEDE7F6, '100': 0xFFD1C4E9, '200': 0xFFB39DDB, '300': 0xFF9575CD, '400': 0xFF7E57C2, '500': 0xFF673AB7, '600': 0xFF5E35B1, '700': 0xFF512DA8, '800': 0xFF4527A0, '900': 0xFF311B92});
  static indigo = __colorsPalette(0xFF3F51B5, {'50': 0xFFE8EAF6, '100': 0xFFC5CAE9, '200': 0xFF9FA8DA, '300': 0xFF7986CB, '400': 0xFF5C6BC0, '500': 0xFF3F51B5, '600': 0xFF3949AB, '700': 0xFF303F9F, '800': 0xFF283593, '900': 0xFF1A237E});
  static blue = __colorsPalette(0xFF2196F3, {'50': 0xFFE3F2FD, '100': 0xFFBBDEFB, '200': 0xFF90CAF9, '300': 0xFF64B5F6, '400': 0xFF42A5F5, '500': 0xFF2196F3, '600': 0xFF1E88E5, '700': 0xFF1976D2, '800': 0xFF1565C0, '900': 0xFF0D47A1});
  static lightBlue = __colorsPalette(0xFF03A9F4, {'50': 0xFFE1F5FE, '100': 0xFFB3E5FC, '200': 0xFF81D4FA, '300': 0xFF4FC3F7, '400': 0xFF29B6F6, '500': 0xFF03A9F4, '600': 0xFF039BE5, '700': 0xFF0288D1, '800': 0xFF0277BD, '900': 0xFF01579B});
  static cyan = __colorsPalette(0xFF00BCD4, {'50': 0xFFE0F7FA, '100': 0xFFB2EBF2, '200': 0xFF80DEEA, '300': 0xFF4DD0E1, '400': 0xFF26C6DA, '500': 0xFF00BCD4, '600': 0xFF00ACC1, '700': 0xFF0097A7, '800': 0xFF00838F, '900': 0xFF006064});
  static teal = __colorsPalette(0xFF009688, {'50': 0xFFE0F2F1, '100': 0xFFB2DFDB, '200': 0xFF80CBC4, '300': 0xFF4DB6AC, '400': 0xFF26A69A, '500': 0xFF009688, '600': 0xFF00897B, '700': 0xFF00796B, '800': 0xFF00695C, '900': 0xFF004D40});
  static green = __colorsPalette(0xFF4CAF50, {'50': 0xFFE8F5E9, '100': 0xFFC8E6C9, '200': 0xFFA5D6A7, '300': 0xFF81C784, '400': 0xFF66BB6A, '500': 0xFF4CAF50, '600': 0xFF43A047, '700': 0xFF388E3C, '800': 0xFF2E7D32, '900': 0xFF1B5E20});
  static lightGreen = __colorsPalette(0xFF8BC34A, {'50': 0xFFF1F8E9, '100': 0xFFDCEDC8, '200': 0xFFC5E1A5, '300': 0xFFAED581, '400': 0xFF9CCC65, '500': 0xFF8BC34A, '600': 0xFF7CB342, '700': 0xFF689F38, '800': 0xFF558B2F, '900': 0xFF33691E});
  static lime = __colorsPalette(0xFFCDDC39, {'50': 0xFFF9FBE7, '100': 0xFFF0F4C3, '200': 0xFFE6EE9C, '300': 0xFFDCE775, '400': 0xFFD4E157, '500': 0xFFCDDC39, '600': 0xFFC0CA33, '700': 0xFFAFB42B, '800': 0xFF9E9D24, '900': 0xFF827717});
  static yellow = __colorsPalette(0xFFFFEB3B, {'50': 0xFFFFFDE7, '100': 0xFFFFF9C4, '200': 0xFFFFF59D, '300': 0xFFFFF176, '400': 0xFFFFEE58, '500': 0xFFFFEB3B, '600': 0xFFFDD835, '700': 0xFFFBC02D, '800': 0xFFF9A825, '900': 0xFFF57F17});
  static amber = __colorsPalette(0xFFFFC107, {'50': 0xFFFFF8E1, '100': 0xFFFFECB3, '200': 0xFFFFE082, '300': 0xFFFFD54F, '400': 0xFFFFCA28, '500': 0xFFFFC107, '600': 0xFFFFB300, '700': 0xFFFFA000, '800': 0xFFFF8F00, '900': 0xFFFF6F00});
  static orange = __colorsPalette(0xFFFF9800, {'50': 0xFFFFF3E0, '100': 0xFFFFE0B2, '200': 0xFFFFCC80, '300': 0xFFFFB74D, '400': 0xFFFFA726, '500': 0xFFFF9800, '600': 0xFFFB8C00, '700': 0xFFF57C00, '800': 0xFFEF6C00, '900': 0xFFE65100});
  static deepOrange = __colorsPalette(0xFFFF5722, {'50': 0xFFFBE9E7, '100': 0xFFFFCCBC, '200': 0xFFFFAB91, '300': 0xFFFF8A65, '400': 0xFFFF7043, '500': 0xFFFF5722, '600': 0xFFF4511E, '700': 0xFFE64A19, '800': 0xFFD84315, '900': 0xFFBF360C});
  static brown = __colorsPalette(0xFF795548, {'50': 0xFFEFEBE9, '100': 0xFFD7CCC8, '200': 0xFFBCAAA4, '300': 0xFFA1887F, '400': 0xFF8D6E63, '500': 0xFF795548, '600': 0xFF6D4C41, '700': 0xFF5D4037, '800': 0xFF4E342E, '900': 0xFF3E2723});
  static grey = __colorsPalette(0xFF9E9E9E, {'50': 0xFFFAFAFA, '100': 0xFFF5F5F5, '200': 0xFFEEEEEE, '300': 0xFFE0E0E0, '350': 0xFFD6D6D6, '400': 0xFFBDBDBD, '500': 0xFF9E9E9E, '600': 0xFF757575, '700': 0xFF616161, '800': 0xFF424242, '850': 0xFF303030, '900': 0xFF212121});
  static blueGrey = __colorsPalette(0xFF607D8B, {'50': 0xFFECEFF1, '100': 0xFFCFD8DC, '200': 0xFFB0BEC5, '300': 0xFF90A4AE, '400': 0xFF78909C, '500': 0xFF607D8B, '600': 0xFF546E7A, '700': 0xFF455A64, '800': 0xFF37474F, '900': 0xFF263238});
  static redAccent = __colorsAccent(0xFFFF5252, {'100': 0xFFFF8A80, '200': 0xFFFF5252, '400': 0xFFFF1744, '700': 0xFFD50000});
  static pinkAccent = __colorsAccent(0xFFFF4081, {'100': 0xFFFF80AB, '200': 0xFFFF4081, '400': 0xFFF50057, '700': 0xFFC51162});
  static purpleAccent = __colorsAccent(0xFFE040FB, {'100': 0xFFEA80FC, '200': 0xFFE040FB, '400': 0xFFD500F9, '700': 0xFFAA00FF});
  static deepPurpleAccent = __colorsAccent(0xFF7C4DFF, {'100': 0xFFB388FF, '200': 0xFF7C4DFF, '400': 0xFF651FFF, '700': 0xFF6200EA});
  static indigoAccent = __colorsAccent(0xFF536DFE, {'100': 0xFF8C9EFF, '200': 0xFF536DFE, '400': 0xFF3D5AFE, '700': 0xFF304FFE});
  static blueAccent = __colorsAccent(0xFF448AFF, {'100': 0xFF82B1FF, '200': 0xFF448AFF, '400': 0xFF2979FF, '700': 0xFF2962FF});
  static lightBlueAccent = __colorsAccent(0xFF40C4FF, {'100': 0xFF80D8FF, '200': 0xFF40C4FF, '400': 0xFF00B0FF, '700': 0xFF0091EA});
  static cyanAccent = __colorsAccent(0xFF18FFFF, {'100': 0xFF84FFFF, '200': 0xFF18FFFF, '400': 0xFF00E5FF, '700': 0xFF00B8D4});
  static tealAccent = __colorsAccent(0xFF64FFDA, {'100': 0xFFA7FFEB, '200': 0xFF64FFDA, '400': 0xFF1DE9B6, '700': 0xFF00BFA5});
  static greenAccent = __colorsAccent(0xFF69F0AE, {'100': 0xFFB9F6CA, '200': 0xFF69F0AE, '400': 0xFF00E676, '700': 0xFF00C853});
  static lightGreenAccent = __colorsAccent(0xFFB2FF59, {'100': 0xFFCCFF90, '200': 0xFFB2FF59, '400': 0xFF76FF03, '700': 0xFF64DD17});
  static limeAccent = __colorsAccent(0xFFEEFF41, {'100': 0xFFF4FF81, '200': 0xFFEEFF41, '400': 0xFFC6FF00, '700': 0xFFAEEA00});
  static yellowAccent = __colorsAccent(0xFFFFFF00, {'100': 0xFFFFFF8D, '200': 0xFFFFFF00, '400': 0xFFFFEA00, '700': 0xFFFFD600});
  static amberAccent = __colorsAccent(0xFFFFD740, {'100': 0xFFFFE57F, '200': 0xFFFFD740, '400': 0xFFFFC400, '700': 0xFFFFAB00});
  static orangeAccent = __colorsAccent(0xFFFFAB40, {'100': 0xFFFFD180, '200': 0xFFFFAB40, '400': 0xFFFF9100, '700': 0xFFFF6D00});
  static deepOrangeAccent = __colorsAccent(0xFFFF6E40, {'100': 0xFFFF9E80, '200': 0xFFFF6E40, '400': 0xFFFF3D00, '700': 0xFFDD2C00});
  static transparent = __colorsColor(0x00000000);
  static black = __colorsColor(0xFF000000);
  static black87 = __colorsColor(0xDD000000);
  static black54 = __colorsColor(0x8A000000);
  static black45 = __colorsColor(0x73000000);
  static black38 = __colorsColor(0x61000000);
  static black26 = __colorsColor(0x42000000);
  static black12 = __colorsColor(0x1F000000);
  static white = __colorsColor(0xFFFFFFFF);
  static white70 = __colorsColor(0xB3FFFFFF);
  static white60 = __colorsColor(0x99FFFFFF);
  static white54 = __colorsColor(0x8AFFFFFF);
  static white38 = __colorsColor(0x62FFFFFF);
  static white30 = __colorsColor(0x4DFFFFFF);
  static white24 = __colorsColor(0x3DFFFFFF);
  static white12 = __colorsColor(0x1FFFFFFF);
  static white10 = __colorsColor(0x1AFFFFFF);
}

