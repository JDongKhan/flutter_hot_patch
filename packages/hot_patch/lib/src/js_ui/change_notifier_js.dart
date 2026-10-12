// ChangeNotifier —— JS 侧状态管理基类（与 Dart 类名 1:1）。
//
// 模型 `class X extends ChangeNotifier` 共用：addListener / removeListener /
// notifyListeners / dispose。**顶层书写（不包 IIFE）**：必须落到全局，供
// 模块产物（`__modules[...] = ...`）里的模型类直接继承。由
// jsRuntimeEnvSource 拼接注入（不属于 env，单独成文件）。
const String changeNotifierSource = r'''
// ChangeNotifier 的 JS 基类（1:1 保持 Dart 类名）：模型 `class X
// extends ChangeNotifier` 共用，notifyListeners 触发订阅回调。
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
''';