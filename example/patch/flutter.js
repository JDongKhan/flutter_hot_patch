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

// ----- 枚举镜像 ---------------------------------------------------------
// Dart 枚举 → JS class + static 字段，值 = 成员名字符串：跨语言只有 name 能
// 表达（宿主也按 name 下发/回传），这样源码级比较
// `direction == DismissDirection.endToStart` 在 JS 侧语义不变。
// 需要运行时存在「枚举类」的枚举在此登记（只做字符串转换的仍由翻译层下发名字）。
export class DismissDirection {
  static horizontal = "horizontal";
  static vertical = "vertical";
  static startToEnd = "startToEnd";
  static endToStart = "endToStart";
  static up = "up";
  static down = "down";
}

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

export const CrossFadeState = { showFirst: 'showFirst', showSecond: 'showSecond' };

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

// Dart 枚举 / 常量镜像：产物里 `Orientation.portrait` 等是原样引用，
// 值取同一套字符串（宿主 JSON 里也是这套字符串）。
export const Orientation = { portrait: 'portrait', landscape: 'landscape' };
export const Brightness = { dark: 'dark', light: 'light' };
export const NavigationMode = { traditional: 'traditional', directional: 'directional' };

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

