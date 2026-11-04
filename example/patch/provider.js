// GENERATED CODE - DO NOT EDIT
// package 模块（package: provider）：由 hot_patch_generator 生成
// 本包内有 JS 类的 widget（逻辑组件 / sliver 代理）集中于此文件

import { Component } from 'flutter.js';


export class ChangeNotifierProvider extends Component {
  initState() {
    var p = this.props;
    var notifier = null, owns = false;
    if (p.create !== undefined && p.create !== null) {
      // `create` 是**函数类型**形参，按统一规则下发普通函数（工厂闭包）：
      // 只调用一次，实例生命周期归本组件。值形态（非函数）也兼容。
      notifier = typeof p.create === 'function' ? p.create() : p.create;
      owns = true;
    } else if (p.value !== undefined && p.value !== null) {
      notifier = p.value;
    }
    this.__value = notifier;
    this.__ownsValue = owns;
  }
  build() {
    return Component.host('ChangeNotifierProvider', {
      typeArguments: this.props.typeArguments,
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

export class Consumer extends Component {
  build(context) {
    var notifier = context.watch({ typeArguments: this.props.typeArguments });
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      __warn('[Consumer] builder 不是闭包');
      return null;
    }
    var child = fn(context, notifier);
    return Component.host('Consumer', {
      typeArguments: this.props.typeArguments,
      notifier: notifier,
      child: child
    });
  }
}

export class MultiProvider extends Component {
  build() {
    var provs = this.props.providers || [];
    var node = this.props.child;
    for (var i = provs.length - 1; i >= 0; i--) {
      // providers 项是翻译层 `new ChangeNotifierProvider(...)` 产出的实例
      // （元素携带 inst）——注入 child 后**复用同一个实例**，不再 new 第二次。
      var prov = provs[i];
      var p = {};
      for (var k in prov.props) { p[k] = prov.props[k]; }
      p.child = node;
      // 实例即元素：复用同一个 provider 实例（换 child 后直接作为上一层元素）。
      prov.props = p;
      node = prov;
    }
    return node;
  }
}

// ===== 本包（provider）自有的运行期登记 =====
// ── provider 库自有的运行期登记（跟本包的类同一模块，随模块求值生效）──
var G = typeof globalThis !== 'undefined' ? globalThis : Function('return this')();
var __core = G.__core;
var __registerScope = __core.__registerScope;
var __scopeOf = __core.__scopeOf;
var __subscribeListenable = __core.__subscribeListenable;
var JsBuildContext = __core.JsBuildContext;
// 告警走核心导出的通用日志入口（debug 生效、release 零开销），不新开通道。
function __warn(text) { __core.log('warn', text); }

// 类型实参的唯一载体是 `typeArguments: ['T']`（生成器按位置顺序原样下发，
// 与值构造、组件结点、泛型方法调用同一份规则）。这里只取第一个——provider 的
// 作用域是单类型键控的；缺失即翻译/调用面不合规，出声而不是静默返回。
function __scopeTypeOf(props, api) {
  var ta = (props && props.typeArguments) || [];
  if (!ta.length) {
    __warn('[provider] ' + api + ' 缺少类型实参 typeArguments，无法定位作用域');
    return null;
  }
  return ta[0];
}

// type      = 类型名（生成器在翻译期写入，源自 `ChangeNotifierProvider<T>` 的 T）；
// notifier  = JS 侧 provider 组件 build 时创建/复用的实例（活对象）。
__registerScope('ChangeNotifierProvider', function (props) {
  var type = __scopeTypeOf(props, 'ChangeNotifierProvider');
  if (type == null) { return null; }
  var out = {};
  out[type] = props.notifier;
  return out;
});

// ---- extension BuildContextX on BuildContext ----
// 对齐 Dart：`context.watch<T>()` / `context.read<T>()` 是 **provider 的**
// extension，不是 BuildContext 的框架 API。故方法补丁归本模块，核心的
// build_context 片段只提供代理与通用 op 转发（见其文件头）。
//
// 调用面与构造同形：类型实参并入尾参对象（`context.watch({ typeArguments: ['T'] })`）。
//
// 取值同步（渲染期 `model.count` 要直接读，而 JS→宿主只有异步桥）⇒ 值在本端
// 按**类型名**沿 `__parent` 取最近作用域（核心通用机制 `__scopeOf`，只认类型名，
// 不关心 T 是模型还是别的）；值是否可订阅由 `__subscribeListenable` 鸭子判型。
// 「订阅谁」这半是库相关的，交宿主：op 经 `__host` 下发到真实 BuildContext，
// 由 provider/context_ops.dart 解析成模型镜像并建立依赖。

// `context.watch<T>()`：取最近提供 [type] 的值并订阅（notify 时只重建调用
// watch 的那个位置）。
JsBuildContext.prototype.watch = function (props) {
  var type = __scopeTypeOf(props, 'context.watch');
  if (type == null) { return undefined; }
  var value = __scopeOf(this.__anchor, type);
  // 把本端查找结果一并告知宿主：宿主据此区分「消费点在 provider 子树之外」
  // （真错误，宿主会告警）与「宿主侧本就没有该作用域的镜像」（正常，静默）。
  this.__host('watch', { type: type, found: value != null });
  if (value == null) { return undefined; }
  __subscribeListenable(this.__anchor, value);
  return value;
};

// `context.read<T>()`：仅取实例，不订阅（按钮回调里的合法用法）。
JsBuildContext.prototype.read = function (props) {
  var type = __scopeTypeOf(props, 'context.read');
  if (type == null) { return undefined; }
  var value = __scopeOf(this.__anchor, type);
  this.__host('read', { type: type, found: value != null });
  return value == null ? undefined : value;
};

