// GENERATED CODE - DO NOT EDIT
// widget 模块（package: provider）：由 ui_component_generator 生成
// 工厂函数返回 {type, props, children}，供组件产物按需 import

import { __h } from '../flutter/Node.js';

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
