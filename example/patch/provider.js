// GENERATED CODE - DO NOT EDIT
// package 模块（package: provider）：由 hot_patch_generator 生成
// 本包内有 JS 类的 widget（逻辑组件 / sliver 代理）集中于此文件

import { __h, __asElement } from 'flutter.js';


export class ChangeNotifierProvider {
  constructor(props) {
    this.props = props || {};
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
    return __h('ChangeNotifierProvider', {
      model: this.props.model,
      notifier: this.__value,
      child: this.props.child
    });
  }
  dispose() {
    if (this.__ownsValue && this.__value &&
        typeof this.__value.dispose === 'function') {
      this.__value.dispose();
    }
  }
}

export class Consumer {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    var notifier = context.watch(this.props.model);
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    var child = owner[name].call(owner, context, notifier);
    return __h('Consumer', {
      model: this.props.model,
      notifier: notifier,
      child: child
    });
  }
}

export class MultiProvider {
  constructor(props) {
    this.props = props || {};
  }
  build() {
    var provs = this.props.providers || [];
    var node = this.props.child;
    for (var i = provs.length - 1; i >= 0; i--) {
      // providers 项可能是元素描述，也可能是用户直接 new 出来的组件实例
      // （`new MultiProvider({providers: [new ChangeNotifierProvider(...)]})`
      // 不经过 __h）——统一折算后再取 type / props。
      var prov = __asElement(provs[i]);
      var p = {};
      for (var k in prov.props) { p[k] = prov.props[k]; }
      p.child = node;
      node = __h(prov.type, p);
    }
    return node;
  }
}
