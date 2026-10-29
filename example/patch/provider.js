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
  static value(props) { return new ChangeNotifierProvider(Object.assign({}, props, { factory: 'value' })); }
}

export class Consumer {
  constructor(props) {
    this.props = props || {};
  }
  build(context) {
    var notifier = context.watch(this.props.model);
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      console.warn('[Consumer] builder 不是闭包');
      return null;
    }
    var child = fn(context, notifier);
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

// ===== 本包（provider）自有的运行期登记 =====
// ── provider 库自有的运行期登记（跟本包的类同一模块，随模块求值生效）──
var G = typeof globalThis !== 'undefined' ? globalThis : Function('return this')();
var __core = G.__core;
var registerScope = __core.registerScope;
var scopeOf = __core.scopeOf;
var subscribeListenable = __core.subscribeListenable;
var JsBuildContext = __core.JsBuildContext;

// model    = 类型名（生成器在翻译期写入，源自 `ChangeNotifierProvider<T>` 的 T）；
// notifier = JS 侧 provider 组件 build 时创建/复用的实例（活对象）。
registerScope('ChangeNotifierProvider', function (props) {
  if (!props || props.model == null) { return null; }
  var out = {};
  out[props.model] = props.notifier;
  return out;
});

// ---- extension BuildContextX on BuildContext ----
// 对齐 Dart：`context.watch<T>()` / `context.read<T>()` 是 **provider 的**
// extension，不是 BuildContext 的框架 API。故方法补丁归本模块，核心的
// build_context 片段只提供代理与通用 op 转发（见其文件头）。
//
// 取值同步（渲染期 `model.count` 要直接读，而 JS→宿主只有异步桥）⇒ 值在本端
// 按**类型名**沿 `__parent` 取最近作用域（核心通用机制 `scopeOf`，只认类型名，
// 不关心 T 是模型还是别的）；值是否可订阅由 `subscribeListenable` 鸭子判型。
// 「订阅谁」这半是库相关的，交宿主：op 经 `__host` 下发到真实 BuildContext，
// 由 provider/context_ops.dart 解析成模型镜像并建立依赖。

// `context.watch<T>()`：取最近提供 [type] 的值并订阅（notify 时只重建调用
// watch 的那个位置）。
JsBuildContext.prototype.watch = function (type) {
  var value = scopeOf(this.__anchor, type);
  // 把本端查找结果一并告知宿主：宿主据此区分「消费点在 provider 子树之外」
  // （真错误，宿主会告警）与「宿主侧本就没有该作用域的镜像」（正常，静默）。
  this.__host('watch', { type: type, found: value != null });
  if (value == null) { return undefined; }
  subscribeListenable(this.__anchor, value);
  return value;
};

// `context.read<T>()`：仅取实例，不订阅（按钮回调里的合法用法）。
JsBuildContext.prototype.read = function (type) {
  var value = scopeOf(this.__anchor, type);
  this.__host('read', { type: type, found: value != null });
  return value == null ? undefined : value;
};

