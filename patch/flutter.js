// GENERATED CODE - DO NOT EDIT
// package 模块（package: flutter）：由 ui_component_generator 生成
// 本包内有 JS 类的 widget（逻辑组件 / sliver 代理）集中于此文件

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
}


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
}

export class GridView {
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
    return __h('GridView', p, out);
  }
}

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
}

export class SliverFillViewport {
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
    return __h('SliverFillViewport', p, out);
  }
}

export class SliverFixedExtentList {
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
    return __h('SliverFixedExtentList', p, out);
  }
}

export class SliverGrid {
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
    return __h('SliverGrid', p, out);
  }
}

export class SliverList {
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
    return __h('SliverList', p, out);
  }
}
