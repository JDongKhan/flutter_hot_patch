// GENERATED CODE - DO NOT EDIT
// package 模块（package: provider）：由 hot_patch_generator 生成
// 本包内有 JS 类的 widget（逻辑组件 / sliver 代理）集中于此文件

import { __h } from 'flutter.js';


export class ChangeNotifierProvider {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  initState() {
    var p = this.props;
    var notifier = null, owns = false;
    if (p.create !== undefined && p.create !== null) {
      if (typeof p.create === 'function') { notifier = new p.create(); }
      else { notifier = p.create; }
      owns = true;
    } else if (p.value !== undefined && p.value !== null) {
      notifier = p.value;
    }
    this.__value = notifier;
    this.__ownsValue = owns;
  }
  build() {
    // child 两种传入方式：直接使用时是 `props.child`（命名参数翻译成 prop）；
    // 被 MultiProvider 包裹时由 `__h(type, props, [node])` 放进 children。
    var child = this.props.child != null ? this.props.child
        : (this.children.length ? this.children[0] : null);
    return __h('ChangeNotifierProvider', { model: this.props.model, notifier: this.__value }, [child]);
  }
  dispose() {
    if (this.__ownsValue && this.__value &&
        typeof this.__value.dispose === 'function') {
      this.__value.dispose();
    }
  }
}

export class Consumer {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  build(context) {
    var notifier = context.watch(this.props.model);
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    var child = owner[name].call(owner, context, notifier);
    return __h('Consumer', { model: this.props.model, notifier: notifier }, [child]);
  }
}

export class MultiProvider {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  build() {
    var provs = this.props.providers || [];
    // child 两种传入方式：直接使用时是 `props.child`（命名参数翻译成 prop）；
    // 作为普通元素挂载时子结点在 `children[0]`（生成器把 MultiProvider 的
    // `child:` 翻译成元素 children）。漏掉后者会把 providers 包在 undefined
    // 外面，整段子树静默消失（Card 只剩空壳，控制台无异常）。
    var node = this.props.child != null ? this.props.child
        : (this.children.length ? this.children[0] : null);
    for (var i = provs.length - 1; i >= 0; i--) {
      node = __h(provs[i].type, provs[i].props, [node]);
    }
    return node;
  }
}
