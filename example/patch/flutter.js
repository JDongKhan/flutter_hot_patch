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

export class Radio {
  constructor(props) {
    return __h('Radio', props);
  }
  static adaptive(props) { return new Radio(Object.assign({}, props, { factory: 'adaptive' })); }
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
    red: __mc(0xFFF44336, {'50': 0xFFFFEBEE, '100': 0xFFFFCDD2, '200': 0xFFEF9A9A, '300': 0xFFE57373, '400': 0xFFEF5350, '600': 0xFFE53935, '700': 0xFFD32F2F, '800': 0xFFC62828, '900': 0xFFB71C1C}),
    pink: __mc(0xFFE91E63, {'50': 0xFFFCE4EC, '100': 0xFFF8BBD0, '200': 0xFFF48FB1, '300': 0xFFF06292, '400': 0xFFEC407A, '600': 0xFFD81B60, '700': 0xFFC2185B, '800': 0xFFAD1457, '900': 0xFF880E4F}),
    purple: __mc(0xFF9C27B0, {'50': 0xFFF3E5F5, '100': 0xFFE1BEE7, '200': 0xFFCE93D8, '300': 0xFFBA68C8, '400': 0xFFAB47BC, '600': 0xFF8E24AA, '700': 0xFF7B1FA2, '800': 0xFF6A1B9A, '900': 0xFF4A148C}),
    deepPurple: __mc(0xFF673AB7, {'50': 0xFFEDE7F6, '100': 0xFFD1C4E9, '200': 0xFFB39DDB, '300': 0xFF9575CD, '400': 0xFF7E57C2, '600': 0xFF5E35B1, '700': 0xFF512DA8, '800': 0xFF4527A0, '900': 0xFF311B92}),
    indigo: __mc(0xFF3F51B5, {'50': 0xFFE8EAF6, '100': 0xFFC5CAE9, '200': 0xFF9FA8DA, '300': 0xFF7986CB, '400': 0xFF5C6BC0, '600': 0xFF3949AB, '700': 0xFF303F9F, '800': 0xFF283593, '900': 0xFF1A237E}),
    blue: __mc(0xFF2196F3, {'50': 0xFFE3F2FD, '100': 0xFFBBDEFB, '200': 0xFF90CAF9, '300': 0xFF64B5F6, '400': 0xFF42A5F5, '600': 0xFF1E88E5, '700': 0xFF1976D2, '800': 0xFF1565C0, '900': 0xFF0D47A1}),
    lightBlue: __mc(0xFF03A9F4, {'50': 0xFFE1F5FE, '100': 0xFFB3E5FC, '200': 0xFF81D4FA, '300': 0xFF4FC3F7, '400': 0xFF29B6F6, '600': 0xFF039BE5, '700': 0xFF0288D1, '800': 0xFF0277BD, '900': 0xFF01579B}),
    cyan: __mc(0xFF00BCD4, {'50': 0xFFE0F7FA, '100': 0xFFB2EBF2, '200': 0xFF80DEEA, '300': 0xFF4DD0E1, '400': 0xFF26C6DA, '600': 0xFF00ACC1, '700': 0xFF0097A7, '800': 0xFF00838F, '900': 0xFF006064}),
    teal: __mc(0xFF009688, {'50': 0xFFE0F2F1, '100': 0xFFB2DFDB, '200': 0xFF80CBC4, '300': 0xFF4DB6AC, '400': 0xFF26A69A, '600': 0xFF00897B, '700': 0xFF00796B, '800': 0xFF00695C, '900': 0xFF004D40}),
    green: __mc(0xFF4CAF50, {'50': 0xFFE8F5E9, '100': 0xFFC8E6C9, '200': 0xFFA5D6A7, '300': 0xFF81C784, '400': 0xFF66BB6A, '600': 0xFF43A047, '700': 0xFF388E3C, '800': 0xFF2E7D32, '900': 0xFF1B5E20}),
    lightGreen: __mc(0xFF8BC34A, {'50': 0xFFF1F8E9, '100': 0xFFDCEDC8, '200': 0xFFC5E1A5, '300': 0xFFAED581, '400': 0xFF9CCC65, '600': 0xFF7CB342, '700': 0xFF689F38, '800': 0xFF558B2F, '900': 0xFF33691E}),
    lime: __mc(0xFFCDDC39, {'50': 0xFFF9FBE7, '100': 0xFFF0F4C3, '200': 0xFFE6EE9C, '300': 0xFFDCE775, '400': 0xFFD4E157, '600': 0xFFC0CA33, '700': 0xFFAFB42B, '800': 0xFF9E9D24, '900': 0xFF827717}),
    yellow: __mc(0xFFFFEB3B, {'50': 0xFFFFFDE7, '100': 0xFFFFF9C4, '200': 0xFFFFF59D, '300': 0xFFFFF176, '400': 0xFFFFEE58, '600': 0xFFFDD835, '700': 0xFFFBC02D, '800': 0xFFF9A825, '900': 0xFFF57F17}),
    amber: __mc(0xFFFFC107, {'50': 0xFFFFF8E1, '100': 0xFFFFECB3, '200': 0xFFFFE082, '300': 0xFFFFD54F, '400': 0xFFFFCA28, '600': 0xFFFFB300, '700': 0xFFFFA000, '800': 0xFFFF8F00, '900': 0xFFFF6F00}),
    orange: __mc(0xFFFF9800, {'50': 0xFFFFF3E0, '100': 0xFFFFE0B2, '200': 0xFFFFCC80, '300': 0xFFFFB74D, '400': 0xFFFFA726, '600': 0xFFFB8C00, '700': 0xFFF57C00, '800': 0xFFEF6C00, '900': 0xFFE65100}),
    deepOrange: __mc(0xFFFF5722, {'50': 0xFFFBE9E7, '100': 0xFFFFCCBC, '200': 0xFFFFAB91, '300': 0xFFFF8A65, '400': 0xFFFF7043, '600': 0xFFF4511E, '700': 0xFFE64A19, '800': 0xFFD84315, '900': 0xFFBF360C}),
    brown: __mc(0xFF795548, {'50': 0xFFEFEBE9, '100': 0xFFD7CCC8, '200': 0xFFBCAAA4, '300': 0xFFA1887F, '400': 0xFF8D6E63, '600': 0xFF6D4C41, '700': 0xFF5D4037, '800': 0xFF4E342E, '900': 0xFF3E2723}),
    grey: __mc(0xFF9E9E9E, {'50': 0xFFFAFAFA, '100': 0xFFF5F5F5, '200': 0xFFEEEEEE, '300': 0xFFE0E0E0, '350': 0xFFD6D6D6, '400': 0xFFBDBDBD, '600': 0xFF757575, '700': 0xFF616161, '800': 0xFF424242, '850': 0xFF303030, '900': 0xFF212121}),
    blueGrey: __mc(0xFF607D8B, {'50': 0xFFECEFF1, '100': 0xFFCFD8DC, '200': 0xFFB0BEC5, '300': 0xFF90A4AE, '400': 0xFF78909C, '600': 0xFF546E7A, '700': 0xFF455A64, '800': 0xFF37474F, '900': 0xFF263238}),
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

export class ValueListenableBuilder {
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
      console.warn('[ValueListenableBuilder] builder 不是闭包');
      return null;
    }
    var l = this.props.listenable;
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
