// ChangeNotifier —— JS 侧状态管理基类（与 Dart 类名 1:1）。
//
// 作为 [jsUiRuntimeSource] 的一段拼接进同一 IIFE：在骨架内定义，尾部挂
// `G.ChangeNotifier`（globalThis），供模块产物（`__modules[...] = ...`）
// 里的模型类直接继承（裸引用解析，与顶层 var 语义等价）。不属于 env，
// 单独成文件便于演进（如引入混入 / 调试钩子）。
const String changeNotifierSource = r'''
// ChangeNotifier 基类（IIFE 骨架内定义，挂 G 供产物继承）：
// 模型 `class X extends ChangeNotifier` 共用，notifyListeners 触发订阅回调。
function ChangeNotifier() {
  this._listeners = [];
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
  this._listeners.slice().forEach(function(f) {
    f();
  });
};
// Dart ChangeNotifier.dispose：清空订阅（释放闭包引用）。被 dispose 后
// 不再响应 notify（原生语义：disposed 后 notify 抛错；JS 侧简化为静默）。
ChangeNotifier.prototype.dispose = function() {
  this._listeners = [];
};

// 顶层暴露：产物（模块 evaluate）里 `class X extends ChangeNotifier` 经
// globalThis 裸引用解析（与顶层 var 语义等价）。
G.ChangeNotifier = ChangeNotifier;''';