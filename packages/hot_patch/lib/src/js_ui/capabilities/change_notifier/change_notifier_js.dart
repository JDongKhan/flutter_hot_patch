// ChangeNotifier —— JS 侧状态管理基类（与 Dart 类名 1:1）。
//
// 作为 [jsUiRuntimeSource] 的一段拼接进同一 IIFE：在骨架内定义，尾部挂
// `G.ChangeNotifier`（globalThis），供模块产物（`__modules[...] = ...`）
// 里的模型类直接继承（裸引用解析，与顶层 var 语义等价）。不属于 env，
// 单独成文件便于演进（如引入混入 / 调试钩子）。
const String changeNotifierSource = r'''
// ChangeNotifier 基类（IIFE 骨架内定义，挂 G 供产物继承）。
//
// **职责只有一件事：提供 VM 本体**。addListener / removeListener 保留在 JS
// 侧（JS 自身逻辑要订阅模型），notifyListeners 双路派发：
//   ① 本端 `_listeners`（JS 侧逻辑 / JS 侧消费者重建）；
//   ② 跨语言 `handleOp(__id, 'notify')`（通知 Dart 端**通用 VM 镜像**，
//      驱动 Dart 侧 ChangeNotifierProvider 子树刷新）。
// 构造时登记句柄（kind=vm/ChangeNotifier），meta.type = JS 端类名 —— Dart 端的
// 通用 VM 据此「记下它的 JS 端类型」（context.watch<T>() 的类型一路传到这里）。
function ChangeNotifier() {
  this._listeners = [];
  this.__id = reg(this, 'vm/ChangeNotifier', {
    meta: { type: (this.constructor && this.constructor.name) || 'ChangeNotifier' }
  });
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
// 同时释放跨语言句柄 → 宿主端的通用 VM 镜像一并销毁（1:1 资源）。
ChangeNotifier.prototype.dispose = function() {
  this._listeners = [];
  if (this.__id != null) {
    releaseHandle(this.__id);
    this.__id = null;
  }
};
// VM 作为元素 prop 下发时（ChangeNotifierProvider 的 `vm`）只带句柄 id：
// 真实对象只存在于 JS 端，宿主经句柄取到自己的通用 VM 镜像。
ChangeNotifier.prototype.toJSON = function() {
  return { __handle: this.__id };
};

// 顶层暴露：产物（模块 evaluate）里 `class X extends ChangeNotifier` 经
// globalThis 裸引用解析（与顶层 var 语义等价）。
G.ChangeNotifier = ChangeNotifier;''';