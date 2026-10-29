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

export class KeyboardListener {
  constructor(props) {
    return __h('KeyboardListener', props);
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

export class RichText {
  constructor(props) {
    return __h('RichText', props);
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

// ===== Dart 值类（值对象 / Controller / 动画 / Key）=====
// 由 runtime.js 迁入：翻译层对它们一律 `new X({...})`，
// 跨桥经各自 toJSON 输出宿主协议（不在这里做任何 JSON 拍平）。
const G = globalThis;
const {
  defineProtoGetter: __defineProtoGetter,
  defineController, defineHandleKind, handleOp, reg,
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
function Duration(opts) {
  opts = __posArgs(opts, ['microseconds', 'milliseconds', 'seconds',
    'minutes', 'hours', 'days']);
  var ms = (opts.milliseconds || 0) + (opts.seconds || 0) * 1000 +
  (opts.minutes || 0) * 60000 + (opts.hours || 0) * 3600000 +
  (opts.days || 0) * 86400000;
  ms += (opts.microseconds || 0) / 1000;
  this.inMilliseconds = Math.round(ms);
  this.inMicroseconds = Math.round(ms * 1000);
}
Duration.prototype.toJSON = function () {
  return { __duration: this.inMilliseconds };
};
G.Duration = Duration;

function Size(props) {
  props = __posArgs(props, ['width', 'height']);
  this.width = props.width;
  this.height = props.height;
}
Size.prototype.toJSON = function () {
  return { width: this.width, height: this.height };
};
// Dart `Size` 的命名构造 / 静态常量（产物按统一规则发射 `Size.fromHeight({…})`）。
// **无界维度是 +∞**：跨桥时 `JSON.stringify(Infinity)` 得到 null，宿主侧按 ∞
// 还原（见 js_widget_registry 的 PreferredSize / layout 约束的 null 约定）。
Size.fromHeight = function (props) {
  props = __posArgs(props, ['height']);
  return new Size({ width: Infinity, height: props.height });
};
Size.fromWidth = function (props) {
  props = __posArgs(props, ['width']);
  return new Size({ width: props.width, height: Infinity });
};
Size.square = function (props) {
  props = __posArgs(props, ['dimension']);
  return new Size({ width: props.dimension, height: props.dimension });
};
Size.copy = function (props) {
  props = __posArgs(props, ['source']);
  return new Size({ width: props.source.width, height: props.source.height });
};
Size.zero = { width: 0, height: 0 };
Size.infinite = { width: Infinity, height: Infinity };
G.Size = Size;

function Offset(props) {
  props = __posArgs(props, ['dx', 'dy']);
  this.dx = props.dx != null ? props.dx : 0;
  this.dy = props.dy != null ? props.dy : 0;
}
Offset.prototype.toJSON = function () {
  return { dx: this.dx, dy: this.dy };
};
G.Offset = Offset;

// Alignment：产物在**值位置**（LinearGradient 的 begin/end、Container 的
// alignment 等）可能直接引用 `Alignment.topLeft`（不是所有位置都会经过
// 构建期的枚举转换器，如静态字段初值就是通用表达式翻译）。Dart 侧它是
// 常量对象，但跨桥协议是**成员名**（宿主 alignmentFromJson 只认字符串），
// 因此静态常量直接就是该字符串——与 Dart 里「同一常量是同一值」的语义一致
//（比较、传参、判等全部成立）。
function Alignment(props) {
  props = __posArgs(props, ['x', 'y']);
  this.x = props.x != null ? props.x : 0;
  this.y = props.y != null ? props.y : 0;
}
Alignment.prototype.toJSON = function () { return { x: this.x, y: this.y }; };
['topLeft', 'topCenter', 'topRight', 'centerLeft', 'center',
  'centerRight', 'bottomLeft', 'bottomCenter', 'bottomRight'
].forEach(function (n) { Alignment[n] = n; });
G.Alignment = Alignment;

function Radius(props) {
  props = __posArgs(props, ['radius']);
  var r = props.radius != null ? props.radius : (props.x != null ? props.x : 0);
  this.x = r;
  this.y = r;
}
Radius.circular = function (props) { return new Radius(props); };
Radius.prototype.toJSON = function () { return { radius: this.x }; };
G.Radius = Radius;

// BoxConstraints：布局约束值对象（LayoutBuilder 的 builder 第二参）。宿主按
// {minWidth, maxWidth, minHeight, maxHeight} 下发，无界维度发 null（JSON 不能
// 表达 Infinity），这里还原成 +∞（见【18.8】）。
function BoxConstraints(props) {
  props = __posArgs(props, ['minWidth', 'maxWidth', 'minHeight', 'maxHeight']);
  this.minWidth = props.minWidth != null ? props.minWidth : 0;
  this.maxWidth = props.maxWidth != null ? props.maxWidth : Infinity;
  this.minHeight = props.minHeight != null ? props.minHeight : 0;
  this.maxHeight = props.maxHeight != null ? props.maxHeight : Infinity;
}
__defineProtoGetter(BoxConstraints.prototype, 'biggest', function () {
  return new Size({ width: this.maxWidth, height: this.maxHeight });
});
__defineProtoGetter(BoxConstraints.prototype, 'smallest', function () {
  return new Size({ width: this.minWidth, height: this.minHeight });
});
__defineProtoGetter(BoxConstraints.prototype, 'isTight', function () {
  return this.minWidth >= this.maxWidth && this.minHeight >= this.maxHeight;
});
__defineProtoGetter(BoxConstraints.prototype, 'hasBoundedWidth', function () {
  return this.maxWidth < Infinity;
});
__defineProtoGetter(BoxConstraints.prototype, 'hasBoundedHeight', function () {
  return this.maxHeight < Infinity;
});
// 无界维度回 null：与宿主下发协议同形，保证跨语言往返一致。
BoxConstraints.prototype.toJSON = function () {
  return {
    minWidth: this.minWidth,
    maxWidth: this.maxWidth === Infinity ? null : this.maxWidth,
    minHeight: this.minHeight,
    maxHeight: this.maxHeight === Infinity ? null : this.maxHeight,
  };
};
G.BoxConstraints = BoxConstraints;

// TextSpan：Dart 富文本子树的值对象（RichText 的 `text`）。产物按统一规则
// 发射 `new TextSpan({text, style, children, semanticsLabel})`；这里镜像字段，
// 跨桥时由 JSON.stringify 递归序列化成普通对象，宿主 textSpanFromJson 再
// 还原成真正的 TextSpan 树。
function TextSpan(props) {
  props = __posArgs(props, ['text']);
  this.text = props.text;
  if (props.style != null) { this.style = props.style; }
  if (props.children != null) { this.children = props.children; }
  if (props.semanticsLabel != null) { this.semanticsLabel = props.semanticsLabel; }
}
G.TextSpan = TextSpan;

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

function LinearGradient(props) {
  var p = __gradientProps(props, ['colors', 'begin', 'end', 'stops', 'tileMode']);
  for (var k in p) { this[k] = p[k]; }
}
LinearGradient.prototype.toJSON = function () { return __gradientJson('linear', this); };
G.LinearGradient = LinearGradient;

function RadialGradient(props) {
  var p = __gradientProps(props,
  ['colors', 'center', 'radius', 'stops', 'focal', 'focalRadius', 'tileMode']);
  for (var k in p) { this[k] = p[k]; }
}
RadialGradient.prototype.toJSON = function () { return __gradientJson('radial', this); };
G.RadialGradient = RadialGradient;

function SweepGradient(props) {
  var p = __gradientProps(props,
  ['colors', 'center', 'startAngle', 'endAngle', 'stops', 'tileMode']);
  for (var k in p) { this[k] = p[k]; }
}
SweepGradient.prototype.toJSON = function () { return __gradientJson('sweep', this); };
G.SweepGradient = SweepGradient;

// BoxDecoration：字段名与 Dart 构造具名实参一致，toJSON 直出宿主协议
//（值为 null 的键不下发——宿主对 null 与缺省同义，少发更干净）。
function BoxDecoration(props) {
  props = __posArgs(props, ['color', 'image', 'border', 'borderRadius',
    'boxShadow', 'gradient', 'backgroundBlendMode', 'shape']);
  for (var k in props) {
    if (props[k] != null) { this[k] = props[k]; }
  }
}
BoxDecoration.prototype.toJSON = function () {
  var json = {};
  for (var k in this) {
    if (this[k] != null) { json[k] = this[k]; }
  }
  return json;
};
G.BoxDecoration = BoxDecoration;

function __toHex(v) {
  var n = (v >>> 0).toString(16).toUpperCase();
  while (n.length < 8) { n = '0' + n; }
  return '#' + n;
}

function Color(props) {
  props = __posArgs(props, ['value']);
  this.value = props.value != null ? (props.value >>> 0) : 0;
}
// 序列化：宿主 colorFromJson 只认 '#RRGGBB' / '#AARRGGBB'。
Color.prototype.toJSON = function () { return __toHex(this.value); };
Color.prototype.toString = function () { return __toHex(this.value); };
Color.prototype.withAlpha = function (a) {
  return new Color({ value: ((a & 0xFF) << 24) | (this.value & 0x00FFFFFF) });
};
Color.prototype.withOpacity = function (o) {
  var a = Math.round(Math.max(0, Math.min(1, o)) * 255);
  return this.withAlpha(a);
};
Color.prototype.withValues = function (opts) {
  opts = __posArgs(opts, []);
  var a = opts.alpha != null ? Math.round(opts.alpha * 255) : this.alpha;
  var r = opts.red != null ? opts.red : this.red;
  var g = opts.green != null ? opts.green : this.green;
  var b = opts.blue != null ? opts.blue : this.blue;
  return Color.fromARGB({ a: a, r: r, g: g, b: b });
};
Object.defineProperty(Color.prototype, 'alpha', {
  get: function () { return (this.value >> 24) & 0xFF; }
});
Object.defineProperty(Color.prototype, 'red', {
  get: function () { return (this.value >> 16) & 0xFF; }
});
Object.defineProperty(Color.prototype, 'green', {
  get: function () { return (this.value >> 8) & 0xFF; }
});
Object.defineProperty(Color.prototype, 'blue', {
  get: function () { return this.value & 0xFF; }
});
Color.fromARGB = function (props) {
  props = __posArgs(props, ['a', 'r', 'g', 'b']);
  return new Color({ value: ((props.a & 0xFF) << 24) | ((props.r & 0xFF) << 16) |
    ((props.g & 0xFF) << 8) | (props.b & 0xFF) });
};
Color.fromRGBO = function (props) {
  props = __posArgs(props, ['r', 'g', 'b', 'opacity']);
  var o = props.opacity != null ? props.opacity : 1;
  return Color.fromARGB({ a: Math.round(o * 255), r: props.r, g: props.g, b: props.b });
};
Color.lerp = function (props) {
  props = __posArgs(props, ['a', 'b', 't']);
  var a = props.a || new Color({ value: 0 });
  var b = props.b || new Color({ value: 0 });
  var t = props.t == null ? 0.5 : props.t;
  function mix(x, y) { return Math.round(x + (y - x) * t); }
  return Color.fromARGB({
    a: mix(a.alpha, b.alpha), r: mix(a.red, b.red),
    g: mix(a.green, b.green), b: mix(a.blue, b.blue)
  });
};
G.Color = Color;

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
function MaterialColor(props) {
  var p = __swatchBase(props);
  Color.call(this, { value: p.value });
  __swatch(this, p.swatch);
}
MaterialColor.prototype = Object.create(Color.prototype);
MaterialColor.prototype.constructor = MaterialColor;
G.MaterialColor = MaterialColor;

function MaterialAccentColor(props) {
  var p = __swatchBase(props);
  Color.call(this, { value: p.value });
  __swatch(this, p.swatch);
}
MaterialAccentColor.prototype = Object.create(Color.prototype);
MaterialAccentColor.prototype.constructor = MaterialAccentColor;
G.MaterialAccentColor = MaterialAccentColor;

function ColorSwatch(props) {
  var p = __swatchBase(props);
  Color.call(this, { value: p.value });
  __swatch(this, p.swatch);
}
ColorSwatch.prototype = Object.create(Color.prototype);
ColorSwatch.prototype.constructor = ColorSwatch;
G.ColorSwatch = ColorSwatch;

// ChangeNotifier 基类（IIFE 骨架内定义，挂 G 供产物继承）。
//
// **职责只有一件事：提供模型本体**。addListener / removeListener 保留在 JS
// 侧（JS 自身逻辑要订阅模型），notifyListeners 双路派发：
//   ① 本端 `_listeners`（JS 侧逻辑 / JS 侧消费者重建）；
//   ② 跨语言 `handleOp(__id, 'notify')`（通知 Dart 端**通用镜像**
//      JsChangeNotifier，驱动 Dart 侧 ChangeNotifierProvider 子树刷新）。
// 构造时登记句柄（kind=notifier/ChangeNotifier），meta.type = JS 端类名 —— Dart 端的
// 通用镜像据此「记下它的 JS 端类型」（context.watch<T>() 的类型一路传到这里）。
function ChangeNotifier() {
  this._listeners = [];
  this.__id = reg(this, 'notifier/ChangeNotifier', {
    meta: { type: (this.constructor && this.constructor.name) || 'ChangeNotifier' }
  });
}
ChangeNotifier.prototype.addListener = function(f) {
  this._listeners.push(f);
};
ChangeNotifier.prototype.removeListener = function(f) {
  var i = this._listeners.indexOf(f);
  if (i >= 0) {
    this._listeners.splice(i, 1);
  }
};
ChangeNotifier.prototype.notifyListeners = function() {
  var ls = this._listeners.slice();
  for (var i = 0; i < ls.length; i++) { ls[i](); }
  // 双路之②：JS→宿主只有异步桥，故这里是 fire-and-forget（不阻塞本地派发）。
  if (this.__id != null) { handleOp(this.__id, 'notify'); }
};
// Dart ChangeNotifier.dispose：清空订阅（释放闭包引用）。被 dispose 后
// 不再响应 notify（原生语义：disposed 后 notify 抛错；JS 侧简化为静默）。
// 同时释放跨语言句柄 → 宿主端的通用镜像一并销毁（1:1 资源）。
ChangeNotifier.prototype.dispose = function() {
  this._listeners = [];
  if (this.__id != null) {
    releaseHandle(this.__id);
    this.__id = null;
  }
};
// 作为元素 prop 下发时（如 ChangeNotifierProvider 的 `notifier`）只带句柄 id：
// 真实对象只存在于 JS 端，宿主经句柄取到自己的通用镜像。
ChangeNotifier.prototype.toJSON = function() {
  return { __handle: this.__id };
};

// 顶层暴露：产物（模块 evaluate）里 `class X extends ChangeNotifier` 经
// globalThis 裸引用解析（与顶层 var 语义等价）。
G.ChangeNotifier = ChangeNotifier;

// ValueNotifier<T>：单值版 ChangeNotifier（`ValueNotifier<int>(0)`）。
//
// **不属于本基类的句柄 kind**：构造时经 ChangeNotifier 登记 `notifier/ChangeNotifier`，
// meta.type 由 `constructor.name` 自动取成 'ValueNotifier'，宿主镜像仍是通用
// JsChangeNotifier（无需新 kind，见 change_notifier_bridge.dart）。
//
// `value` 用 defineProperty 的 get/set 实现，setter 里 **=== 守卫**是
// `ValueListenableBuilder`「值不变不重建」语义的唯一来源：相同即 return，
// 不同才赋值并 notifyListeners()（与 Dart ValueNotifier 一致）。
//
// 构造实参与其他 Dart 类一样按**具名 props 对象**下发（Dart 的 `ValueNotifier(this._value)`，
// 形参名就是 `_value`，见 ctor_signatures），故这里按 `_value` 键取值；
// 直接传裸值时（手写 / 内部调用）也兼容。
function ValueNotifier(props) {
  ChangeNotifier.call(this);
  this._value = (props !== null && typeof props === 'object' && '_value' in props)
  ? props._value
  : props;
}
ValueNotifier.prototype = Object.create(ChangeNotifier.prototype);
ValueNotifier.prototype.constructor = ValueNotifier;
Object.defineProperty(ValueNotifier.prototype, 'value', {
  configurable: true,
  enumerable: false,
  get: function () { return this._value; },
  set: function (v) {
    if (this._value === v) { return; }
    this._value = v;
    this.notifyListeners();
  },
});
G.ValueNotifier = ValueNotifier;
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
var Curves = {};
for (var __ci = 0; __ci < __CURVE_NAMES.length; __ci++) {
  Curves[__CURVE_NAMES[__ci]] = __CURVE_NAMES[__ci];
}
G.Curves = Curves;

G.CrossFadeState = { showFirst: 'showFirst', showSecond: 'showSecond' };

// 只在 JS 侧推导 value；作为组件 props 下发时经 toJSON 带上 `__curve`，
// 宿主用父控制器驱动同一条曲线（见 animation_bridge 的 jsDoubleAnimationOf）。
function Tween(opts) {
  opts = opts || {};
  this.begin = opts.begin;
  this.end = opts.end;
}
Tween.prototype.lerp = function (t) {
  var b = this.begin, e = this.end;
  if (typeof b === 'number' && typeof e === 'number') { return b + (e - b) * t; }
  if (b && e && typeof b.dx === 'number' && typeof e.dx === 'number') {
    return new Offset(b.dx + (e.dx - b.dx) * t, b.dy + (e.dy - b.dy) * t);
  }
  return t < 0.5 ? b : e;
};
G.Tween = Tween;

function CurvedAnimation(opts) {
  opts = opts || {};
  this.parent = opts.parent;
  this.curve = opts.curve;
}
Object.defineProperty(CurvedAnimation.prototype, 'value', {
  get: function () {
    var t = (this.parent && typeof this.parent.value === 'number') ? this.parent.value : 0;
    return __animCurveFn(this.curve)(t);
  }
});
CurvedAnimation.prototype.addListener = function (f) {
  if (this.parent && typeof this.parent.addListener === 'function') {
    this.parent.addListener(f);
  }
};
CurvedAnimation.prototype.removeListener = function (f) {
  if (this.parent && typeof this.parent.removeListener === 'function') {
    this.parent.removeListener(f);
  }
};
CurvedAnimation.prototype.toJSON = function () {
  return {
    __handle: this.parent ? this.parent.__id : null,
    __curve: this.curve,
    value: this.value
  };
};
G.CurvedAnimation = CurvedAnimation;

// 真实控制器在宿主（Ticker 驱动）；本镜像只保存 value 与时长：
//   - forward/reverse/repeat/stop/reset → `handleOp('call')`（载荷带 value 与
//     时长，宿主据此对齐状态后再驱动）；
//   - 宿主每帧回传 value → onHost 更新镜像 + __notify（JS listeners 据此重建）。
var AnimationController = defineController('ctrl/Flash', {
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
G.AnimationController = AnimationController;

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
var ScrollController = defineController('ctrl/Scroll', {
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
G.ScrollController = ScrollController;

// ===== PageController 代理类（对应 Flutter 官方 PageController）=====
// 与 ScrollController 同一套句柄层；镜像字段只有 page / initialPage。
// 构造参数（initialPage / viewportFraction）随 toJSON 的 extraJSON 下发，
// 宿主 PageView renderer 据此创建真实 PageController。
var PageController = defineController('ctrl/Page', {
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
G.PageController = PageController;

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
var TextEditingController = defineController('ctrl/Text', {
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
G.TextEditingController = TextEditingController;

var FocusNode = defineController('ctrl/Focus', {
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
G.FocusNode = FocusNode;

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
var LogicalKeyboardKey = {};
for (var __name in __KEY_CONSTS) {
  __defineProtoGetter(LogicalKeyboardKey, __name, (function (name) {
    return function () { return __logicalKey(__KEY_CONSTS[name][0], __KEY_CONSTS[name][1]); };
  })(__name));
}
G.LogicalKeyboardKey = LogicalKeyboardKey;

// PhysicalKeyboardKey：`event.physicalKey.usbHidUsage` 按 usb 码归一。
var __physKeys = {};
function PhysicalKeyboardKey(props) {
  props = props || {};
  this.usbHidUsage = props.usbHidUsage;
  this.debugName = props.debugName || '';
}
G.PhysicalKeyboardKey = PhysicalKeyboardKey;
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
function KeyEvent(props) {
  props = props || {};
  this.physicalKey = props.physicalKey;
  this.logicalKey = props.logicalKey;
  this.character = props.character == null ? null : String(props.character);
  this.timeStamp = props.timeStamp;
}
G.KeyEvent = KeyEvent;

var __KEY_EVENT_SUBCLASSES = {
  down: function KeyDownEvent(props) { KeyEvent.call(this, props); },
  up: function KeyUpEvent(props) { KeyEvent.call(this, props); },
  repeat: function KeyRepeatEvent(props) { KeyEvent.call(this, props); }
};
for (var __kind in __KEY_EVENT_SUBCLASSES) {
  var __ctor = __KEY_EVENT_SUBCLASSES[__kind];
  __ctor.prototype = Object.create(KeyEvent.prototype);
  __ctor.prototype.constructor = __ctor;
}
G.KeyDownEvent = __KEY_EVENT_SUBCLASSES.down;
G.KeyUpEvent = __KEY_EVENT_SUBCLASSES.up;
G.KeyRepeatEvent = __KEY_EVENT_SUBCLASSES.repeat;

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
var MediaQuery = {
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
var Orientation = { portrait: 'portrait', landscape: 'landscape' };
var Brightness = { dark: 'dark', light: 'light' };
var NavigationMode = { traditional: 'traditional', directional: 'directional' };

G.MediaQuery = MediaQuery;
G.Orientation = Orientation;
G.Brightness = Brightness;
G.NavigationMode = NavigationMode;
G.__jsuiSetMediaQuery = __jsuiSetMediaQuery;

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
var TabController = defineController('ctrl/Tab', {
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
G.TabController = TabController;

// TabBarView 是**懒容器**（子页被 SliverFillViewport 强制成整屏，零尺寸占位
// 布局中性）——不在运行时声明：由生成器配置 lazyChildHostTypes 在 __h 里给
// 元素打 `lazyChildren` 标记（见 hot_patch_generator 的 shared/js_class_defs.dart）。

// ObjectKey / ValueKey(对象值) 的身份 token：对象走 WeakMap（不阻止回收），
// 原始值没有身份，退化为值 string。
var okeySeq = 0;
var okeyIdx = new WeakMap();
function objectToken(v) {
  if (v === null || (typeof v !== 'object' && typeof v !== 'function')) {
    return 'p:' + String(v);
  }
  var t = okeyIdx.get(v);
  if (t == null) { okeySeq += 1; t = 'i:' + okeySeq; okeyIdx.set(v, t); }
  return t;
}

// ValueKey：按值相等，纯值 codec（不登记句柄）。
// 实例的**自有字段名 = 序列化字段名**（__vkey）：reconciler 的 keySig 用字段
// 形态判据，而 props.key 传的是 live 实例（不是 toJSON 产物），两边必须同形。
// 对象值跨语言保不住同一性，序列化退化为身份 token（与 keyValueSig 同源）。
function ValueKey(props) { this.__vkey = __posArgs(props, ['value']).value; }
ValueKey.prototype.toJSON = function () {
  var v = this.__vkey;
  if (v !== null && (typeof v === 'object' || typeof v === 'function')) {
    return { __vtok: objectToken(v) };
  }
  return { __vkey: v };
};

// ObjectKey：按被包裹对象的身份相等（只留身份 token，不再持有对象引用）。
function ObjectKey(props) { this.__okey = objectToken(__posArgs(props, ['value']).value); }
ObjectKey.prototype.toJSON = function () { return { __okey: this.__okey }; };

// PageStorageKey：Dart 侧 `extends ValueKey`（按**值**相等），但宿主必须造
// **真实** PageStorageKey——它的意义是滚动位置按 key 存进 PageStorage bucket，
// 那是宿主端行为（JS 侧只有一个值本体）。故 codec 与 ValueKey 同构另加 `__psk`
// 标记：宿主据此造 PageStorageKey 而非 ValueKey，keySig 前缀 `p:` 使它与
// 同值的 ValueKey 不等（与 Dart 的 runtimeType 参与相等一致）。
function PageStorageKey(props) {
  var value = __posArgs(props, ['value']).value;
  this.__psk = (value !== null && (typeof value === 'object' || typeof value === 'function'))
  ? { __vtok: objectToken(value) }
  : value;
}
PageStorageKey.prototype.toJSON = function () { return { __psk: this.__psk }; };

// GlobalKey / UniqueKey：登记为句柄（scope=page，随页面回收），宿主持真实实例。
defineHandleKind('key/Global', {});
function GlobalKey(props) {
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
GlobalKey.prototype.toJSON = function () { return { __handle: this.__id }; };

// GlobalKey.currentContext / findRenderObject()：BuildContext 与 RenderObject 是
// **宿主端**概念——JS 侧既没有真实对象，也没有同步取值的能力（JS→宿主只有异步
// 桥，见 handleOp）。故 currentContext 返回一个只携带 key 句柄 id 的代理，链式
// 调用在 JS 侧是空壳，最后一次调用经通用 op 落到宿主，由宿主用**真实**对象把
// Flutter 原生语义补全——位置/尺寸只在真正算得出来的一端计算。
//   - showOnScreen()：void 语义，fire-and-forget，宿主算出该结点位置并滚动；
//   - measure()：Flutter 的 `box.size` / `box.localToGlobal(Offset.zero)` 是
//     **同步属性**，而 JS→宿主只能异步，故这里返回 Promise（单源侧 `await`
//     后即为真实值，见 widget_details 的 _measureFixed）。
function KeyRef(id) { this.__key = id; }
KeyRef.prototype.findRenderObject = function () { return new KeyRef(this.__key); };
KeyRef.prototype.showOnScreen = function () {
  if (this.__key != null) { handleOp(this.__key, 'showOnScreen', {}); }
};
KeyRef.prototype.measure = function () {
  if (this.__key == null) { return Promise.resolve(null); }
  return handleOp(this.__key, 'measure', {});
};
Object.defineProperty(GlobalKey.prototype, 'currentContext', {
  get: function () { return this.__id == null ? null : new KeyRef(this.__id); }
});

// GlobalKey.currentState：State 是宿主对象，JS 侧只保留**句柄**。
//
// 运行时**不认识任何业务方法**（`insertItem` / `removeItem` 这类签名属于具体
// 组件）：每个 State 类型的代理类由生成器随该组件一起写进 flutter.js，并在
// 加载时用 `__registerStateProxy(type, class)` 登记；类型来自 **GlobalKey<T> 的
// 泛型实参**，随产物下发，不靠 runtimeType 猜。没有代理类时退化为通用句柄。
function StateHandle(id, type) { this.__key = id; this.__type = type || null; }
StateHandle.prototype.__op = function (op, payload) {
  if (this.__key == null) { return null; }
  var p = payload || {};
  // 类型随每次调用下发（来自 GenericKey 的泛型实参）：宿主据此分派到
  // `Type.method`，不同组件的同名方法互不覆盖。
  if (this.__type) { p.type = this.__type; }
  return handleOp(this.__key, '__state.' + op, p);
};
var __stateProxies = {};
function __registerStateProxy(type, cls) { __stateProxies[type] = cls; }
Object.defineProperty(GlobalKey.prototype, 'currentState', {
  get: function () {
    if (this.__id == null) { return null; }
    // 首选泛型实参（`GlobalKey<AnimatedListState>` 的 T）；未声明泛型时才问
    // 宿主 runtimeType。两者都没有则退化为通用句柄（调用时宿主会告警）。
    var type = this.__stateType || handleOp(this.__id, '__type', {});
    var cls = type ? __stateProxies[type] : null;
    return cls ? new cls(this.__id, type) : new StateHandle(this.__id, type);
  }
});
G.__registerStateProxy = __registerStateProxy;
G.__StateHandle = StateHandle;

defineHandleKind('key/Unique', {});
function UniqueKey() {
  this.__id = reg(this, 'key/Unique', {});
}
UniqueKey.prototype.toJSON = function () { return { __handle: this.__id }; };

// 值 → 签名片段（原始值按「类型 + 值」，对象按身份）。
function keyValueSig(v) {
  if (v === null || (typeof v !== 'object' && typeof v !== 'function')) {
    return typeof v + ':' + String(v);
  }
  return 'i:' + objectToken(v);
}

// key → 可比较签名；null / undefined（无 key）返回 null。
// 形态判据用**自有字段**（`__vkey` / `__okey`）：ValueKey 的值本身可以是
// null/undefined，故只能判「有没有这个字段」，不能判它的值。
function keySig(k) {
  if (k == null) { return null; }
  if (Object.prototype.hasOwnProperty.call(k, '__vkey')) { return 'v:' + keyValueSig(k.__vkey); }
  // PageStorageKey：同值也与 ValueKey 不等（`p:` 前缀），对象值同 ValueKey 走 token。
  if (Object.prototype.hasOwnProperty.call(k, '__psk')) {
    var pv = k.__psk;
    if (pv !== null && typeof pv === 'object' &&
    Object.prototype.hasOwnProperty.call(pv, '__vtok')) {
      return 'p:' + pv.__vtok;
    }
    return 'p:' + keyValueSig(pv);
  }
  if (Object.prototype.hasOwnProperty.call(k, '__okey')) { return 'o:' + k.__okey; }
  var hid = k.__id != null ? k.__id : k.__handle;
  if (hid != null) { return 'h:' + hid; }
  // 兜底：认不出的 key 对象按**引用身份**区分。绝不能 `String(k)` ——
  // 所有对象都会拼成 "[object Object]" 而互相撞车，导致不同 key 复用同一
  // 结点（`x:` 前缀保留，表明这是兜底签名）。
  return 'x:' + objectToken(k);
}

G.ValueKey = ValueKey;
G.ObjectKey = ObjectKey;
G.PageStorageKey = PageStorageKey;
G.UniqueKey = UniqueKey;
G.GlobalKey = GlobalKey;

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
var EasyRefreshController = defineController('ctrl/EasyRefresh', {
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
G.EasyRefreshController = EasyRefreshController;

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

function Timer(props) {
  __timerInit(this, props, false, null);
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

Timer.prototype.cancel = function () {
  this._cancelled = true;
  this._active = false;
  if (this._handle != null && typeof clearTimeout === 'function') {
    try { clearTimeout(this._handle); } catch (e) {}
  }
  this._handle = null;
};

Object.defineProperty(Timer.prototype, 'isActive', {
  get: function () { return !!this._active; }
});

// Timer 不是跨语言句柄：万一被当作值下发，只带状态字段（调试友好，宿主侧无对应还原）。
Timer.prototype.toJSON = function () {
  return { __timer: true, active: !!this._active, repeat: !!this._repeat, ms: this._ms };
};

Timer.periodic = function (props, second) {
  var t = Object.create(Timer.prototype);
  __timerInit(t, props, true, second);
  return t;
};

G.Timer = Timer;


// ===== Colors 常量（由 Flutter SDK colors.dart 自动生成）=====
// 全局注入：产物里 `Colors.red` / `Colors.red[400]` 原样求值，
// 翻译层不含任何色值表。
globalThis.Colors = (function () {
  function __c(v) { return new Color({ value: v }); }
  function __mc(primary, shades) {
    var m = new MaterialColor({ primary: primary });
    for (var k in shades) {
      m[k] = __c(shades[k]);
      m['shade' + k] = m[k];
    }
    if (m['shade500'] === undefined) {
      m['500'] = m;
      m['shade500'] = m;
    }
    return m;
  }
  function __mac(primary, shades) {
    var m = new MaterialAccentColor({ primary: primary });
    for (var k in shades) {
      m[k] = __c(shades[k]);
      m['shade' + k] = m[k];
    }
    return m;
  }
  return {
    red: __mc(0xFFF44336, {'50': 0xFFFFEBEE, '100': 0xFFFFCDD2, '200': 0xFFEF9A9A, '300': 0xFFE57373, '400': 0xFFEF5350, '500': 0xFFF44336, '600': 0xFFE53935, '700': 0xFFD32F2F, '800': 0xFFC62828, '900': 0xFFB71C1C}),
    pink: __mc(0xFFE91E63, {'50': 0xFFFCE4EC, '100': 0xFFF8BBD0, '200': 0xFFF48FB1, '300': 0xFFF06292, '400': 0xFFEC407A, '500': 0xFFE91E63, '600': 0xFFD81B60, '700': 0xFFC2185B, '800': 0xFFAD1457, '900': 0xFF880E4F}),
    purple: __mc(0xFF9C27B0, {'50': 0xFFF3E5F5, '100': 0xFFE1BEE7, '200': 0xFFCE93D8, '300': 0xFFBA68C8, '400': 0xFFAB47BC, '500': 0xFF9C27B0, '600': 0xFF8E24AA, '700': 0xFF7B1FA2, '800': 0xFF6A1B9A, '900': 0xFF4A148C}),
    deepPurple: __mc(0xFF673AB7, {'50': 0xFFEDE7F6, '100': 0xFFD1C4E9, '200': 0xFFB39DDB, '300': 0xFF9575CD, '400': 0xFF7E57C2, '500': 0xFF673AB7, '600': 0xFF5E35B1, '700': 0xFF512DA8, '800': 0xFF4527A0, '900': 0xFF311B92}),
    indigo: __mc(0xFF3F51B5, {'50': 0xFFE8EAF6, '100': 0xFFC5CAE9, '200': 0xFF9FA8DA, '300': 0xFF7986CB, '400': 0xFF5C6BC0, '500': 0xFF3F51B5, '600': 0xFF3949AB, '700': 0xFF303F9F, '800': 0xFF283593, '900': 0xFF1A237E}),
    blue: __mc(0xFF2196F3, {'50': 0xFFE3F2FD, '100': 0xFFBBDEFB, '200': 0xFF90CAF9, '300': 0xFF64B5F6, '400': 0xFF42A5F5, '500': 0xFF2196F3, '600': 0xFF1E88E5, '700': 0xFF1976D2, '800': 0xFF1565C0, '900': 0xFF0D47A1}),
    lightBlue: __mc(0xFF03A9F4, {'50': 0xFFE1F5FE, '100': 0xFFB3E5FC, '200': 0xFF81D4FA, '300': 0xFF4FC3F7, '400': 0xFF29B6F6, '500': 0xFF03A9F4, '600': 0xFF039BE5, '700': 0xFF0288D1, '800': 0xFF0277BD, '900': 0xFF01579B}),
    cyan: __mc(0xFF00BCD4, {'50': 0xFFE0F7FA, '100': 0xFFB2EBF2, '200': 0xFF80DEEA, '300': 0xFF4DD0E1, '400': 0xFF26C6DA, '500': 0xFF00BCD4, '600': 0xFF00ACC1, '700': 0xFF0097A7, '800': 0xFF00838F, '900': 0xFF006064}),
    teal: __mc(0xFF009688, {'50': 0xFFE0F2F1, '100': 0xFFB2DFDB, '200': 0xFF80CBC4, '300': 0xFF4DB6AC, '400': 0xFF26A69A, '500': 0xFF009688, '600': 0xFF00897B, '700': 0xFF00796B, '800': 0xFF00695C, '900': 0xFF004D40}),
    green: __mc(0xFF4CAF50, {'50': 0xFFE8F5E9, '100': 0xFFC8E6C9, '200': 0xFFA5D6A7, '300': 0xFF81C784, '400': 0xFF66BB6A, '500': 0xFF4CAF50, '600': 0xFF43A047, '700': 0xFF388E3C, '800': 0xFF2E7D32, '900': 0xFF1B5E20}),
    lightGreen: __mc(0xFF8BC34A, {'50': 0xFFF1F8E9, '100': 0xFFDCEDC8, '200': 0xFFC5E1A5, '300': 0xFFAED581, '400': 0xFF9CCC65, '500': 0xFF8BC34A, '600': 0xFF7CB342, '700': 0xFF689F38, '800': 0xFF558B2F, '900': 0xFF33691E}),
    lime: __mc(0xFFCDDC39, {'50': 0xFFF9FBE7, '100': 0xFFF0F4C3, '200': 0xFFE6EE9C, '300': 0xFFDCE775, '400': 0xFFD4E157, '500': 0xFFCDDC39, '600': 0xFFC0CA33, '700': 0xFFAFB42B, '800': 0xFF9E9D24, '900': 0xFF827717}),
    yellow: __mc(0xFFFFEB3B, {'50': 0xFFFFFDE7, '100': 0xFFFFF9C4, '200': 0xFFFFF59D, '300': 0xFFFFF176, '400': 0xFFFFEE58, '500': 0xFFFFEB3B, '600': 0xFFFDD835, '700': 0xFFFBC02D, '800': 0xFFF9A825, '900': 0xFFF57F17}),
    amber: __mc(0xFFFFC107, {'50': 0xFFFFF8E1, '100': 0xFFFFECB3, '200': 0xFFFFE082, '300': 0xFFFFD54F, '400': 0xFFFFCA28, '500': 0xFFFFC107, '600': 0xFFFFB300, '700': 0xFFFFA000, '800': 0xFFFF8F00, '900': 0xFFFF6F00}),
    orange: __mc(0xFFFF9800, {'50': 0xFFFFF3E0, '100': 0xFFFFE0B2, '200': 0xFFFFCC80, '300': 0xFFFFB74D, '400': 0xFFFFA726, '500': 0xFFFF9800, '600': 0xFFFB8C00, '700': 0xFFF57C00, '800': 0xFFEF6C00, '900': 0xFFE65100}),
    deepOrange: __mc(0xFFFF5722, {'50': 0xFFFBE9E7, '100': 0xFFFFCCBC, '200': 0xFFFFAB91, '300': 0xFFFF8A65, '400': 0xFFFF7043, '500': 0xFFFF5722, '600': 0xFFF4511E, '700': 0xFFE64A19, '800': 0xFFD84315, '900': 0xFFBF360C}),
    brown: __mc(0xFF795548, {'50': 0xFFEFEBE9, '100': 0xFFD7CCC8, '200': 0xFFBCAAA4, '300': 0xFFA1887F, '400': 0xFF8D6E63, '500': 0xFF795548, '600': 0xFF6D4C41, '700': 0xFF5D4037, '800': 0xFF4E342E, '900': 0xFF3E2723}),
    grey: __mc(0xFF9E9E9E, {'50': 0xFFFAFAFA, '100': 0xFFF5F5F5, '200': 0xFFEEEEEE, '300': 0xFFE0E0E0, '350': 0xFFD6D6D6, '400': 0xFFBDBDBD, '500': 0xFF9E9E9E, '600': 0xFF757575, '700': 0xFF616161, '800': 0xFF424242, '850': 0xFF303030, '900': 0xFF212121}),
    blueGrey: __mc(0xFF607D8B, {'50': 0xFFECEFF1, '100': 0xFFCFD8DC, '200': 0xFFB0BEC5, '300': 0xFF90A4AE, '400': 0xFF78909C, '500': 0xFF607D8B, '600': 0xFF546E7A, '700': 0xFF455A64, '800': 0xFF37474F, '900': 0xFF263238}),
    redAccent: __mac(0xFFFF5252, {'100': 0xFFFF8A80, '200': 0xFFFF5252, '400': 0xFFFF1744, '700': 0xFFD50000}),
    pinkAccent: __mac(0xFFFF4081, {'100': 0xFFFF80AB, '200': 0xFFFF4081, '400': 0xFFF50057, '700': 0xFFC51162}),
    purpleAccent: __mac(0xFFE040FB, {'100': 0xFFEA80FC, '200': 0xFFE040FB, '400': 0xFFD500F9, '700': 0xFFAA00FF}),
    deepPurpleAccent: __mac(0xFF7C4DFF, {'100': 0xFFB388FF, '200': 0xFF7C4DFF, '400': 0xFF651FFF, '700': 0xFF6200EA}),
    indigoAccent: __mac(0xFF536DFE, {'100': 0xFF8C9EFF, '200': 0xFF536DFE, '400': 0xFF3D5AFE, '700': 0xFF304FFE}),
    blueAccent: __mac(0xFF448AFF, {'100': 0xFF82B1FF, '200': 0xFF448AFF, '400': 0xFF2979FF, '700': 0xFF2962FF}),
    lightBlueAccent: __mac(0xFF40C4FF, {'100': 0xFF80D8FF, '200': 0xFF40C4FF, '400': 0xFF00B0FF, '700': 0xFF0091EA}),
    cyanAccent: __mac(0xFF18FFFF, {'100': 0xFF84FFFF, '200': 0xFF18FFFF, '400': 0xFF00E5FF, '700': 0xFF00B8D4}),
    tealAccent: __mac(0xFF64FFDA, {'100': 0xFFA7FFEB, '200': 0xFF64FFDA, '400': 0xFF1DE9B6, '700': 0xFF00BFA5}),
    greenAccent: __mac(0xFF69F0AE, {'100': 0xFFB9F6CA, '200': 0xFF69F0AE, '400': 0xFF00E676, '700': 0xFF00C853}),
    lightGreenAccent: __mac(0xFFB2FF59, {'100': 0xFFCCFF90, '200': 0xFFB2FF59, '400': 0xFF76FF03, '700': 0xFF64DD17}),
    limeAccent: __mac(0xFFEEFF41, {'100': 0xFFF4FF81, '200': 0xFFEEFF41, '400': 0xFFC6FF00, '700': 0xFFAEEA00}),
    yellowAccent: __mac(0xFFFFFF00, {'100': 0xFFFFFF8D, '200': 0xFFFFFF00, '400': 0xFFFFEA00, '700': 0xFFFFD600}),
    amberAccent: __mac(0xFFFFD740, {'100': 0xFFFFE57F, '200': 0xFFFFD740, '400': 0xFFFFC400, '700': 0xFFFFAB00}),
    orangeAccent: __mac(0xFFFFAB40, {'100': 0xFFFFD180, '200': 0xFFFFAB40, '400': 0xFFFF9100, '700': 0xFFFF6D00}),
    deepOrangeAccent: __mac(0xFFFF6E40, {'100': 0xFFFF9E80, '200': 0xFFFF6E40, '400': 0xFFFF3D00, '700': 0xFFDD2C00}),
    transparent: __c(0x00000000),
    black: __c(0xFF000000),
    black87: __c(0xDD000000),
    black54: __c(0x8A000000),
    black45: __c(0x73000000),
    black38: __c(0x61000000),
    black26: __c(0x42000000),
    black12: __c(0x1F000000),
    white: __c(0xFFFFFFFF),
    white70: __c(0xB3FFFFFF),
    white60: __c(0x99FFFFFF),
    white54: __c(0x8AFFFFFF),
    white38: __c(0x62FFFFFF),
    white30: __c(0x4DFFFFFF),
    white24: __c(0x3DFFFFFF),
    white12: __c(0x1FFFFFFF),
    white10: __c(0x1AFFFFFF)
  };
})();


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
