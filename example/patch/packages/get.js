// 三方库 JS（宿主维护）：get（GetX）
//
// 生成器不生成 get.js —— 三方库的 JS 由宿主放在工程根的 `js/` 目录，
// 构建时由 `ui_third_party_js` 原样拷贝到 `patch/packages/get.js`。
// 文件名即 Dart 包名（`js/get.js` ↔ `package:get`）；业务产物按
// `import { Get, GetBuilder, Obx, RxInt } from '../packages/get.js'` 取用。
//
// 本文件只实现 GetX 的「状态管理」子集（路由 / 弹窗 / 国际化不在本模块）：
//   - `Get.put / find / delete / reset`：进程内全局实例表，不走 widget 树；
//   - `GetxController.update()`：手动通知本实例的全部 GetBuilder 重建；
//   - `GetBuilder<T>`：从实例表取 controller，订阅 update，重建 builder 子树；
//   - `Obx` + `Rx*`：build 期间开启「读追踪」，闭包内读到的 Rx 登记为依赖，
//     Rx 赋值时标脏重建——与 GetX 的 Obx 自动依赖同语义。
import { Component } from '../flutter.js';

var G = typeof globalThis !== 'undefined' ? globalThis : Function('return this')();
var __core = G.__core;
var __typeArgumentOf = __core.__typeArgumentOf;

// 告警走核心导出的通用日志入口（debug 生效、release 零开销），不新开通道。
function __warn(text) { __core.log('warn', text); }

// ---- Get 的依赖注入（全局实例表）----
//
// key = 类型名 [+ '@' + tag]，与 GetX 的 `Get.put(inst, tag: 'x')` 口径一致。
// 类型名来自调用点下发的 `typeArguments`（生成器按调用点泛型实参发射）。
var __instances = new Map();

function __keyOf(type, tag) {
  return tag == null ? type : type + '@' + tag;
}

// 构造 / 方法调用的尾参对象里取第一个类型实参（`{ typeArguments: {...} }`）。
function __typeOf(props, api) {
  return __typeArgumentOf(props, api);
}

export class Get {
  // `Get.put<T>(inst)` → 位置实参 inst + 尾参 `{ typeArguments }`。
  static put(instance, props) {
    if (instance == null) {
      __warn('[Get.put] 实例为空，已忽略');
      return instance;
    }
    var p = props || {};
    var type = __typeOf(p, 'Get.put') ||
      (instance.constructor && instance.constructor.name);
    if (type == null) {
      __warn('[Get.put] 缺少类型信息，未登记实例');
      return instance;
    }
    __instances.set(__keyOf(type, p.tag), instance);
    if (typeof instance.onInit === 'function') { instance.onInit(); }
    return instance;
  }

  // `Get.find<T>()` → 只有尾参 `{ typeArguments, tag }`。
  static find(props) {
    var p = props || {};
    var type = __typeOf(p, 'Get.find');
    if (type == null) { return undefined; }
    var key = __keyOf(type, p.tag);
    var instance = __instances.get(key);
    if (instance === undefined) {
      __warn('[Get.find] 未找到 ' + key + '（是否忘了 Get.put？）');
    }
    return instance;
  }

  // `Get.delete<T>()` → 只认尾参；返回是否真的删除了实例。
  static delete(props) {
    var p = props || {};
    var type = __typeOf(p, 'Get.delete');
    if (type == null) { return false; }
    var key = __keyOf(type, p.tag);
    var instance = __instances.get(key);
    if (instance === undefined) { return false; }
    __instances.delete(key);
    if (typeof instance.onClose === 'function') { instance.onClose(); }
    if (typeof instance.dispose === 'function') { instance.dispose(); }
    return true;
  }

  // `Get.reset()`：清空整张实例表（demo 的页面级清理入口）。
  static reset() {
    __instances.clear();
  }
}

// ---- GetxController：手动通知 ----
export class GetxController {
  constructor() {
    this.__updaters = new Set();
  }

  // `update()`：通知所有订阅者重建；`ids` 非空时只通知匹配的 GetBuilder。
  update(ids) {
    this.__updaters.forEach(function (fn) { fn(ids); });
  }

  onInit() {}

  onClose() {}

  __addUpdater(fn) { this.__updaters.add(fn); }

  __removeUpdater(fn) { this.__updaters.delete(fn); }
}

// ---- Rx：Obx 的自动追踪载体 ----
//
// 读 `.value` 时若正处于某个 Obx 的 build 期间，就把自己登记进当前追踪集合；
// 写 `.value` 时通知所有监听者（Obx 的 listener 只做一次 setState）。
var __tracking = null;

export class Rx {
  // 构造实参由生成器按 Dart 构造签名映射为对象（`new RxInt({ initial: 0 })`）；
  // 兼容直接传原始值（手写测试 / 兼容非位置参数形态）。
  constructor(args) {
    var initial = args;
    if (args != null && typeof args === 'object' &&
        Object.prototype.hasOwnProperty.call(args, 'initial')) {
      initial = args.initial;
    }
    this._value = initial;
    this._listeners = new Set();
  }

  get value() {
    if (__tracking !== null) { __tracking.add(this); }
    return this._value;
  }

  set value(next) {
    if (this._value === next) { return; }
    this._value = next;
    var ls = [];
    this._listeners.forEach(function (fn) { ls.push(fn); });
    for (var i = 0; i < ls.length; i++) { ls[i](); }
  }

  addListener(fn) { this._listeners.add(fn); }

  removeListener(fn) { this._listeners.delete(fn); }

  toString() { return String(this._value); }
}

// GetX 的 Rx 家族：同一套读写语义，仅类型标注不同。
export class RxInt extends Rx {}
export class RxDouble extends Rx {}
export class RxString extends Rx {}
export class RxBool extends Rx {}
export class RxList extends Rx {}

// ---- GetBuilder：手动订阅 ----
export class GetBuilder extends Component {
  initState() {
    var props = this.props;
    var self = this;
    var type = __typeOf(props, 'GetBuilder');
    var ctrl = null;

    // `init`：GetX 允许在 GetBuilder 上直接给实例 / 工厂；给了就登记进实例表。
    if (props.init !== undefined && props.init !== null) {
      ctrl = typeof props.init === 'function' ? props.init() : props.init;
      if (type != null) { __instances.set(__keyOf(type, props.tag), ctrl); }
    }
    if (ctrl == null && type != null) {
      ctrl = __instances.get(__keyOf(type, props.tag));
    }
    this.__controller = ctrl;
    if (ctrl == null || typeof ctrl.__addUpdater !== 'function') {
      __warn('[GetBuilder] 未找到控制器'
        + (type == null ? '（缺少类型实参）' : '（' + type + ' 未 Get.put）'));
      return;
    }

    this.__updater = function (ids) {
      // `update(['a'])` 的 id 过滤：GetBuilder 声明了 id 且不在列表内就不重建。
      var want = props.id;
      if (want != null && ids != null && ids.length && ids.indexOf(want) < 0) {
        return;
      }
      self.setState(function () {});
    };
    ctrl.__addUpdater(this.__updater);
  }

  build(context) {
    var fn = this.props.builder;
    var ctrl = this.__controller;
    if (typeof fn !== 'function') {
      __warn('[GetBuilder] builder 不是闭包');
      return null;
    }
    if (ctrl == null) { return null; }
    return fn(ctrl);
  }

  dispose() {
    if (this.__controller && this.__updater) {
      this.__controller.__removeUpdater(this.__updater);
    }
    this.__controller = null;
    this.__updater = null;
  }
}

// ---- Obx：自动追踪 ----
export class Obx extends Component {
  initState() {
    var self = this;
    this.__tracked = [];
    // 所有被追踪 Rx 共用一个 listener：任一变 → 标脏本组件。
    this.__listener = function () { self.setState(function () {}); };
  }

  build(context) {
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      __warn('[Obx] builder 不是闭包');
      return null;
    }
    // 重建前先精确退订上一轮追踪到的 Rx，避免闭包分支变化后残留监听。
    __untrack(this);

    var tracked = new Set();
    var prev = __tracking;
    __tracking = tracked;
    var widget;
    try {
      widget = fn();
    } finally {
      __tracking = prev;
    }

    var self = this;
    this.__tracked = [];
    tracked.forEach(function (rx) {
      rx.addListener(self.__listener);
      self.__tracked.push(rx);
    });
    return widget;
  }

  dispose() {
    __untrack(this);
    this.__listener = null;
  }
}

function __untrack(inst) {
  var tracked = inst.__tracked || [];
  for (var i = 0; i < tracked.length; i++) {
    tracked[i].removeListener(inst.__listener);
  }
  inst.__tracked = [];
}
