// GENERATED CODE - DO NOT EDIT
// package 模块（package: provider）：由 hot_patch_generator 生成
// 本包内有 JS 类的 widget（逻辑组件 / sliver 代理）集中于此文件

import { Component } from 'flutter.js';


export class ChangeNotifierProvider extends Component {
  initState() {
    var p = this.props;
    if (p.create !== undefined && p.create !== null) {
      // `create` 是**函数类型**形参，按统一规则下发普通函数（工厂闭包）：
      // 只调用一次，实例生命周期归本组件。值形态（非函数）也兼容。
      this._value = typeof p.create === 'function' ? p.create(this.context) : p.create;
      this._ownsValue = true;
    } else if (p.value !== undefined && p.value !== null) {
      this._value = p.value;
      this._ownsValue = false;
    }
  }
  // `value`：provider 作用域对外的取值入口（watch/read 读这里）。
  get value() { return this._value; }
  build() {
    // `.value(...)` 的模型实例可能被父级替换：每次 build 从最新 props 取。
    if (!this._ownsValue && this.props.value !== undefined) {
      this._value = this.props.value;
    }
    var type = __typeArgumentOf(this.props, 'ChangeNotifierProvider');
    if (type != null) {
      __inheritElement(this, type);
      // 与 provider 的 InheritedNotifier 同义：模型实例换了 → 通知依赖者重建。
      if (this._published && this._published !== this._value) {
        __notifyClients(this);
      }
      this._published = this._value;
    }
    return this.props.child;
  }
  dispose() {
    if (this._ownsValue && this._value &&
    typeof this._value.dispose === 'function') {
      this._value.dispose();
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
    return fn(context, notifier, this.props.child);
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
var __inheritElement = __core.__inheritElement;
var __notifyClients = __core.__notifyClients;
var __typeArgumentOf = __core.__typeArgumentOf;
var __subscribeListenable = __core.__subscribeListenable;
var JsBuildContext = __core.JsBuildContext;
// 告警走核心导出的通用日志入口（debug 生效、release 零开销），不新开通道。
function __warn(text) { __core.log('warn', text); }

// 同一个消费位置重复重建时不刷屏：按 (api, 类型名) 只告警一次。
function __warnMissingScope(anchor, props, api) {
  var type = __typeArgumentOf(props, null);
  if (type == null) { return; } // 缺类型实参已由 JsBuildContext 出声
  var seen = anchor && (anchor.__missingScopeWarned ||
  (anchor.__missingScopeWarned = {}));
  var key = api + '|' + type;
  if (seen && seen[key]) { return; }
  if (seen) { seen[key] = true; }
  __warn('[provider] ' + api + '(' + type + ') 未找到提供者'
  + '（消费点可能不在 provider 子树内）');
}

// ---- extension BuildContextX on BuildContext ----
// 对齐 Dart：`context.watch<T>()` / `context.read<T>()` 是 **provider 的**
// extension，不是 BuildContext 的框架 API。故方法补丁归本模块。
//
// 调用面与构造同形：类型实参并入尾参对象（`context.watch({ typeArguments })`）。
// **取值必须同步**（渲染期 `model.count` 要直接读，而 JS→宿主只有异步桥），
// 因此查找走 `JsBuildContext` 的 `getInheritedWidgetOfExactType` /
// `dependOnInheritedWidgetOfExactType`；provider 作用域结点用 `value` 暴露模型。
// 值是否可订阅由 `__subscribeListenable` 鸭子判型（原生 ChangeNotifier API）。

// `context.watch<T>()`：取最近提供 [type] 的作用域并订阅（notify 时只重建
// 调用 watch 的那个位置；模型实例被 provider 替换时也会收到依赖通知）。
JsBuildContext.prototype.watch = function (props) {
  var scope = this.dependOnInheritedWidgetOfExactType(props);
  if (scope == null) {
    __warnMissingScope(this.__anchor, props, 'context.watch');
    return undefined;
  }
  var value = scope.value;
  __subscribeListenable(this.__anchor, value, scope);
  return value;
};

// `context.read<T>()`：仅取实例，不订阅（按钮回调里的合法用法）。
JsBuildContext.prototype.read = function (props) {
  var scope = this.getInheritedWidgetOfExactType(props);
  if (scope == null) {
    __warnMissingScope(this.__anchor, props, 'context.read');
    return undefined;
  }
  return scope.value;
};

