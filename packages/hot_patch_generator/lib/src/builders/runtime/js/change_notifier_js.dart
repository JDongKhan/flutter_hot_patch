// ChangeNotifier —— JS 侧状态管理基类（与 Dart 类名 1:1）。
//
// 作为 [jsUiRuntimeSource] 的一段拼接进同一 IIFE：在骨架内定义，尾部挂
// `G.ChangeNotifier`（globalThis），供模块产物（`__modules[...] = ...`）
// 里的模型类直接继承（裸引用解析，与顶层 var 语义等价）。不属于 env，
// 单独成文件便于演进（如引入混入 / 调试钩子）。
const String changeNotifierSource = r'''
// ChangeNotifier 基类（IIFE 骨架内定义，挂 G 供产物继承）。
//
// **职责只有一件事：提供模型本体**。addListener / removeListener 保留在 JS
// 侧（JS 自身逻辑要订阅模型），notifyListeners 双路派发：
//   ① 本端 `_listeners`（JS 侧逻辑 / JS 侧消费者重建）；
//   ② 跨语言 `handleOp(__id, 'notify')`（通知 Dart 端**通用镜像**
//      JsChangeNotifier，驱动 Dart 侧 ChangeNotifierProvider 子树刷新）。
// 构造时登记句柄（kind=notifier/ChangeNotifier），meta.type = JS 端类名 —— Dart 端的
// 通用镜像据此「记下它的 JS 端类型」（context.watch<T>() 的类型一路传到这里）。
class ChangeNotifier {
  constructor() {
    this._listeners = [];
    this.__id = reg(this, 'notifier/ChangeNotifier', {
      meta: { type: (this.constructor && this.constructor.name) || 'ChangeNotifier' }
    });
  }
}
ChangeNotifier.prototype.addListener = function(f) {
  this._listeners.push(f);
};
ChangeNotifier.prototype.removeListener = function(f) {
  var i = this._listeners.indexOf(f);
  if (i >= 0) {
    this._listeners.splice(i, 1);
  }
};
ChangeNotifier.prototype.notifyListeners = function() {
  var ls = this._listeners.slice();
  for (var i = 0; i < ls.length; i++) { ls[i](); }
  // 双路之②：JS→宿主只有异步桥，故这里是 fire-and-forget（不阻塞本地派发）。
  if (this.__id != null) { handleOp(this.__id, 'notify'); }
};
// Dart ChangeNotifier.dispose：清空订阅（释放闭包引用）。被 dispose 后
// 不再响应 notify（原生语义：disposed 后 notify 抛错；JS 侧简化为静默）。
// 同时释放跨语言句柄 → 宿主端的通用镜像一并销毁（1:1 资源）。
ChangeNotifier.prototype.dispose = function() {
  this._listeners = [];
  if (this.__id != null) {
    releaseHandle(this.__id);
    this.__id = null;
  }
};
// 作为元素 prop 下发时（如 ChangeNotifierProvider 的 `notifier`）只带句柄 id：
// 真实对象只存在于 JS 端，宿主经句柄取到自己的通用镜像。
ChangeNotifier.prototype.toJSON = function() {
  return { __handle: this.__id };
};

// 顶层暴露：产物（模块 evaluate）里 `class X extends ChangeNotifier` 经
// globalThis 裸引用解析（与顶层 var 语义等价）。
G.ChangeNotifier = ChangeNotifier;

// ValueNotifier<T>：单值版 ChangeNotifier（`ValueNotifier<int>(0)`）。
//
// **不属于本基类的句柄 kind**：构造时经 ChangeNotifier 登记 `notifier/ChangeNotifier`，
// meta.type 由 `constructor.name` 自动取成 'ValueNotifier'，宿主镜像仍是通用
// JsChangeNotifier（无需新 kind，见 change_notifier_bridge.dart）。
//
// `value` 用 defineProperty 的 get/set 实现，setter 里 **=== 守卫**是
// `ValueListenableBuilder`「值不变不重建」语义的唯一来源：相同即 return，
// 不同才赋值并 notifyListeners()（与 Dart ValueNotifier 一致）。
//
// 构造实参与其他 Dart 类一样按**具名 props 对象**下发（Dart 的 `ValueNotifier(this._value)`，
// 形参名就是 `_value`，见 ctor_signatures），故这里按 `_value` 键取值；
// 直接传裸值时（手写 / 内部调用）也兼容。
class ValueNotifier extends ChangeNotifier {
  constructor(props) {
    super();
    this._value = (props !== null && typeof props === 'object' && '_value' in props)
      ? props._value
      : props;
  }
}
Object.defineProperty(ValueNotifier.prototype, 'value', {
  configurable: true,
  enumerable: false,
  get: function () { return this._value; },
  set: function (v) {
    if (this._value === v) { return; }
    this._value = v;
    this.notifyListeners();
  },
});
G.ValueNotifier = ValueNotifier;''';
