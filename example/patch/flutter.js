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
export function __h(type, props) {
  var p = props || {};
  // JS 组件类：props 原样保留，__applyProps 靠它派生构造参数字段。
  if (typeof type !== 'string') {
    return { type: type, props: p, children: {}, element: true };
  }
  var data = {}, slots = {};
  for (var k in p) {
    if (!Object.prototype.hasOwnProperty.call(p, k)) { continue; }
    var v = p[k];
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
    // props 原样透传（含 itemBuilder/separatorBuilder/childCount/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 用 propChildList('__items') 取。
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
    // props 原样透传（含 itemBuilder/separatorBuilder/childCount/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 用 propChildList('__items') 取。
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
    // props 原样透传（含 itemBuilder/separatorBuilder/childCount/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 用 propChildList('__items') 取。
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
    // props 原样透传（含 itemBuilder/separatorBuilder/childCount/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 用 propChildList('__items') 取。
    var p = {};
    for (var k in this.props) { p[k] = this.props[k]; }
    p.__items = out;
    return __h('ReorderableListView', p);
  }
}

export class SliverFillViewport {
  constructor(props) {
    this.props = props || {};
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
    // props 原样透传（含 itemBuilder/separatorBuilder/childCount/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 用 propChildList('__items') 取。
    var p = {};
    for (var k in this.props) { p[k] = this.props[k]; }
    p.__items = out;
    return __h('SliverFillViewport', p);
  }
}

export class SliverFixedExtentList {
  constructor(props) {
    this.props = props || {};
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
    // props 原样透传（含 itemBuilder/separatorBuilder/childCount/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 用 propChildList('__items') 取。
    var p = {};
    for (var k in this.props) { p[k] = this.props[k]; }
    p.__items = out;
    return __h('SliverFixedExtentList', p);
  }
}

export class SliverGrid {
  constructor(props) {
    this.props = props || {};
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
    // props 原样透传（含 itemBuilder/separatorBuilder/childCount/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 用 propChildList('__items') 取。
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
    // props 原样透传（含 itemBuilder/separatorBuilder/childCount/itemCount/factory）；
    // 展开结果走内部键 __items（不是 Flutter 属性名），由 __h 按元素数组归入
    // children 对象，宿主 renderer 用 propChildList('__items') 取。
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
