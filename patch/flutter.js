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
  build(context) {
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    return owner[name].call(owner, context);
  }
}

export class GridView {
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
    return __h('GridView', this.props, out);
  }
}

export class ListView {
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
    return __h('ListView', this.props, out);
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
}

export class SliverFillViewport {
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
    return __h('SliverFillViewport', this.props, out);
  }
}

export class SliverFixedExtentList {
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
    return __h('SliverFixedExtentList', this.props, out);
  }
}

export class SliverGrid {
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
    return __h('SliverGrid', this.props, out);
  }
}

export class SliverList {
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
    return __h('SliverList', this.props, out);
  }
}

export class ValueListenableBuilder {
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
    var l = owner[this.props.listenable];
    var value = (l && l.value !== undefined) ? l.value : null;
    var child = owner[this.props.builder].call(owner, context, value);
    return __h('ValueListenableBuilder', { vm: l }, [child]);
  }
  dispose() {
    if (this.__listenable && this.__listener) {
      this.__listenable.removeListener(this.__listener);
    }
  }
}
