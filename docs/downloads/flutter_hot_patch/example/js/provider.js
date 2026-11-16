// 三方库 JS（宿主维护）：provider
//
// 生成器不再生成 provider.js —— 三方库的 JS 由宿主放在工程根的 `js/` 目录，
// 构建时由 `ui_third_party_js` 原样拷贝到 `patch/packages/provider.js`。
// 文件名即 Dart 包名（`js/provider.js` ↔ `package:provider`），业务产物按
// `import { ChangeNotifierProvider, Consumer, MultiProvider } from
// '../packages/provider.js'` 取用。
//
// 本文件在拷贝后位于 `patch/packages/`，故对 flutter.js 的相对路径是 `../`。
import { Component } from '../flutter.js';

// ChangeNotifierProvider：解析 create/value 得到模型实例，全部逻辑留在 JS。
//
// 不产出宿主结点：本类自己登记为「按类型名键控的继承结点」
// （`__inheritedElements`，类型名取自 `props.typeArguments`），build 直接返回
// child。`context.watch/read` 经 `JsBuildContext` 的继承查找取到本结点后读
// `value`（对齐 provider 的 `_InheritedProviderScope.value`）。
export class ChangeNotifierProvider extends Component {
  initState() {
    var p = this.props;
    if (p.create !== undefined && p.create !== null) {
      // `create` 是函数类型形参，按统一规则下发普通函数（工厂闭包）：
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
  static value(props) {
    return new ChangeNotifierProvider(Object.assign({}, props, { factory: 'value' }));
  }
}

// MultiProvider：把 providers 数组按「嵌套 Provider」语义组合——
// providers[0] 最外层，最后一个最内层（离 child 最近），与原生一致。
export class MultiProvider extends Component {
  build() {
    var provs = this.props.providers || [];
    var node = this.props.child;
    for (var i = provs.length - 1; i >= 0; i--) {
      // providers 项是翻译层 `new ChangeNotifierProvider(...)` 产出的实例
      // （元素携带 inst）——注入 child 后复用同一个实例，不再 new 第二次。
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

// Consumer：消费 VM——按 `props.typeArguments[0]`（类型名）经 build 收到的
// context 取值并订阅（`context.watch({typeArguments})`），再调用拥有者组件上的
// `props.builder` 方法渲染局部子树。
//
// UI 更新全部来自 JS 侧重建（VM notify → 标脏该位置 → 重读 `model.count`
// → 下发 patch）：本类直接返回 builder 子树，不产出宿主监听结点。
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

// Selector：Consumer 的「按选中值过滤重建」版本。
//
// 取值与 Consumer 相同（本位置最近的作用域模型），但先经
// `props.selector(context, model)` 折算成只含所需字段的选中值；模型通知时先
// 重算选中值，**没变就完全不重建**（builder 子树不重跑），变了才标脏。判定
// 口径与 provider 一致：
//   - 传了 `props.shouldRebuild(previous, next)` 就用它；
//   - 否则按 provider 默认的 DeepCollectionEquality 深比较（List / Set / Map /
//     record 结构相等；其余对象按同一性，即 Dart 默认 `==`）。
// 作用域换实例（provider 的 value 被替换）由依赖登记照常触发重建并重订阅。
export class Selector extends Component {
  build(context) {
    var props = this.props;
    var builder = props.builder;
    if (typeof builder !== 'function') {
      __warn('[Selector] builder 不是闭包');
      return null;
    }
    var scope = context.dependOnInheritedWidgetOfExactType({
      typeArguments: props.typeArguments,
    });
    if (scope == null) {
      __warnMissingScope(this, props, 'Selector');
      return builder(context, undefined, props.child);
    }
    var model = scope.value;
    __subscribeSelected(this, context, model);
    var selected = __selectOf(this, context, model);
    this.__selected = selected;
    this.__hasSelected = true;
    return builder(context, selected, props.child);
  }

  dispose() {
    __unsubscribeSelected(this);
  }
}

// ── provider 自有的运行期登记（跟本模块的类同一文件，随模块求值生效）──
var G = typeof globalThis !== 'undefined' ? globalThis : Function('return this')();
var __core = G.__core;
var __inheritElement = __core.__inheritElement;
var __notifyClients = __core.__notifyClients;
var __typeArgumentOf = __core.__typeArgumentOf;
var __subscribeListenable = __core.__subscribeListenable;
var JsBuildContext = __core.JsBuildContext;
// 告警走核心导出的通用日志入口（debug 生效、release 零开销），不新开通道。
function __warn(text) { __core.log('warn', text); }
function __error(text) { __core.log('error', text); }

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

// ---- Selector 的选中值 / 订阅 ----

// 选中值：`props.selector(context, model)`。selector 必须是闭包；异常出声并
// 按 undefined 处理（不静默吞掉，也不让一次失败拖垮整棵树）。
function __selectOf(inst, context, model) {
  var fn = inst.props.selector;
  if (typeof fn !== 'function') {
    __warn('[Selector] selector 不是闭包');
    return undefined;
  }
  try {
    return fn(context, model);
  } catch (e) {
    __error('[Selector] selector 执行失败: ' + String(e));
    return undefined;
  }
}

// 选中值是否需要重建：优先 `props.shouldRebuild(previous, next)`，否则按
// provider 默认的 DeepCollectionEquality 口径。
function __selectedChanged(inst, previous, next) {
  var fn = inst.props.shouldRebuild;
  if (typeof fn === 'function') {
    try {
      return fn(previous, next) === true;
    } catch (e) {
      __error('[Selector] shouldRebuild 执行失败: ' + String(e));
      return true;
    }
  }
  return !__deepEquals(previous, next);
}

// 在 [model] 上挂「重算选中值 → 变了才标脏」的监听；订阅由选择器实例自己
// 持有，模型实例被替换时先精确退订旧的，避免悬空监听继续标脏。
function __subscribeSelected(inst, context, model) {
  if (!model || typeof model.addListener !== 'function') {
    __unsubscribeSelected(inst);
    return;
  }
  if (inst.__selValue === model && inst.__selListener) { return; }
  __unsubscribeSelected(inst);
  inst.__selValue = model;
  inst.__selListener = function () {
    var next = __selectOf(inst, context, model);
    if (inst.__hasSelected && !__selectedChanged(inst, inst.__selected, next)) {
      return;
    }
    inst.__selected = next;
    inst.__hasSelected = true;
    inst.setState(function () {});
  };
  model.addListener(inst.__selListener);
}

function __unsubscribeSelected(inst) {
  if (inst.__selValue && inst.__selListener &&
      typeof inst.__selValue.removeListener === 'function') {
    inst.__selValue.removeListener(inst.__selListener);
  }
  inst.__selValue = null;
  inst.__selListener = null;
}

// provider 默认比较口径（collection 的 DeepCollectionEquality）：List / Set /
// Map / record 结构相等；其它对象沿用 Dart 默认 `==`（同一性）。
function __deepEquals(a, b) {
  if (a === b) { return true; }
  if (a == null || b == null) { return false; }
  if (typeof a !== 'object' || typeof b !== 'object') { return false; }
  var i, j;
  if (Array.isArray(a) || Array.isArray(b)) {
    if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) { return false; }
    for (i = 0; i < a.length; i++) {
      if (!__deepEquals(a[i], b[i])) { return false; }
    }
    return true;
  }
  if (a instanceof Set || b instanceof Set) {
    if (!(a instanceof Set) || !(b instanceof Set) || a.size !== b.size) { return false; }
    var xs = [], ys = [], used = [];
    a.forEach(function (v) { xs.push(v); });
    b.forEach(function (v) { ys.push(v); });
    for (i = 0; i < xs.length; i++) {
      var hit = false;
      for (j = 0; j < ys.length; j++) {
        if (used[j]) { continue; }
        if (__deepEquals(xs[i], ys[j])) { used[j] = true; hit = true; break; }
      }
      if (!hit) { return false; }
    }
    return true;
  }
  if (a instanceof Map || b instanceof Map) {
    if (!(a instanceof Map) || !(b instanceof Map) || a.size !== b.size) { return false; }
    var same = true;
    a.forEach(function (v, k) {
      if (!b.has(k) || !__deepEquals(v, b.get(k))) { same = false; }
    });
    return same;
  }
  // record / 普通对象字面量：自有键结构相等（位置字段 `$1…$N`、命名字段原名）。
  if (a.constructor !== Object || b.constructor !== Object) { return false; }
  var ka = Object.keys(a), kb = Object.keys(b);
  if (ka.length !== kb.length) { return false; }
  for (i = 0; i < ka.length; i++) {
    var k = ka[i];
    if (!Object.prototype.hasOwnProperty.call(b, k)) { return false; }
    if (!__deepEquals(a[k], b[k])) { return false; }
  }
  return true;
}

// ---- extension BuildContextX on BuildContext ----
// 对齐 Dart：`context.watch<T>()` / `context.read<T>()` 是 provider 的
// extension，不是 BuildContext 的框架 API，故方法补丁归本模块。
//
// 调用面与构造同形：类型实参并入尾参对象（`context.watch({ typeArguments })`）。
// 取值必须同步（渲染期 `model.count` 要直接读，而 JS→宿主只有异步桥），
// 因此查找走 `JsBuildContext` 的 `getInheritedWidgetOfExactType` /
// `dependOnInheritedWidgetOfExactType`；provider 作用域结点用 `value` 暴露模型。
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

JsBuildContext.prototype.read = function (props) {
  var scope = this.getInheritedWidgetOfExactType(props);
  if (scope == null) {
    __warnMissingScope(this.__anchor, props, 'context.read');
    return undefined;
  }
  return scope.value;
};
