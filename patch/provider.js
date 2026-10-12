// GENERATED CODE - DO NOT EDIT
// package 模块（package: provider）：由 ui_component_generator 生成
// 本包全部 widget 工厂集中于此文件；工厂返回 {type, props, children}

import { __h } from 'flutter.js';


class ChangeNotifierProviderComponent {
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
}
export function ChangeNotifierProvider(props, children) {
  return __h(ChangeNotifierProviderComponent, props, children);
}

class ConsumerComponent {
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
}
export function Consumer(props, children) {
  return __h(ConsumerComponent, props, children);
}

class MultiProviderComponent {
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
}
export function MultiProvider(props, children) {
  return __h(MultiProviderComponent, props, children);
}
