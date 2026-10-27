// @hot_patch protocol: 0.3.2
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
ChangeNotifierProvider.value = function (props) { return new ChangeNotifierProvider(props); };


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
      // providers 项是翻译层 `new ChangeNotifierProvider(...)` 产出的实例
      // （元素携带 inst）——注入 child 后**复用同一个实例**，不再 new 第二次。
      var prov = __asElement(provs[i]);
      var p = {};
      for (var k in prov.props) { p[k] = prov.props[k]; }
      p.child = node;
      if (prov.inst) {
        prov.inst.props = p;
        node = {
          type: prov.type, props: p, children: {}, element: true, inst: prov.inst
        };
      } else {
        node = __h(prov.type, p);
      }
    }
    return node;
  }
}

