// easy_refresh 能力的 JS 片段（随 flutter.js 发布）。
//
// EasyRefresh 的「手势 / 物理 / 指示器」都在宿主侧，而回调 onRefresh / onLoad
// 由 JS 补丁实现，因此存在一次**宿主发起、JS 异步完成**的往返：
//
//   宿主（用户下拉）--__awaitRefreshRun(句柄 id, token)--> JS 执行事件方法
//   JS（任务结束）----> 宿主通道 'jsuiAwaitDone'（回传 token）--> 指示器收起
//
// 为什么要有这条回程：宿主 → JS 的 `__jsui.invoke` 是**单向**的，且 flutter_js
// 在 iOS/JavaScriptCore 上无法把 JS 的 Promise 交回 Dart（evaluateAsync 就是
// 同步 evaluate），宿主拿不到「JS 任务何时结束」。于是由 JS 侧 await 事件句柄的
// 返回值，完成后再经**唯一 JS→宿主出口** `_app_host_.invoke`（invokeHostMethod）
// 回传 token，宿主据此结算对应 Completer（见 easy_refresh_bridge.dart）。
//
// 事件句柄能返回 Promise，靠的是 `__createFnHandle` 生成的 wrapper 原样返回箭头
// 闭包的结果（见 js/mini_react_js.dart）；Dart 的 async 方法在 JS 侧就是
// async 函数，返回 Promise。
const String easyRefreshJsSource = r'''
  // 宿主侧桥接见 capabilities/easy_refresh/easy_refresh_bridge.dart 的
  // `_runAwaitableEvent`：evaluate 本函数触发一次事件，并等 token 回传。
  // 挂 G（globalThis）：宿主经 evaluate 裸引用调用，与 `__jsui` 同一约定。
  G.__awaitRefreshRun = function (handleId, token) {
    var fn = handleObjectOf(handleId);
    var out = null;
    try {
      out = (typeof fn === 'function') ? fn() : null;
    } catch (e) {
      // 事件方法同步抛错：按「已完成」收尾——指示器必须收起，不能挂死在转圈。
              console.error(String(e));
      
    }
    // 完成回传走 host（唯一 JS→宿主出口）；onFulfilled / onRejected 都必须回传，
    // 否则宿主侧那条 pending 永远等不到结算。
    var done = function () { invokeHostMethod('jsuiAwaitDone', [token]); };
    if (out && typeof out.then === 'function') {
      out.then(done, done);
    } else {
      done();
    }
  };

  // 与 ScrollController 同款句柄层（基类见 controller_base_js.dart）：JS 实例与
  // 宿主真实 EasyRefreshController 按句柄 id 绑定。控制方法把**原始实参数组**
  // 原样下发（`handleOp 'call'`），由宿主按 Dart 形参的类型/顺序还原：
  // 生成器对方法调用的具名实参是位置化扁平（JS 无具名参数），所以这里不臆造
  // 形参名，交给宿主按类型判别（数值 → overOffset、Duration 值 → duration、
  // 曲线名 → curve、布尔 → force）。
  // 宿主侧桥接见 capabilities/easy_refresh/easy_refresh_bridge.dart。
  export class EasyRefreshController extends ControllerBase {
    constructor(opts) {
      super();
      var o = opts || {};
      this.controlFinishRefresh = !!o.controlFinishRefresh;
      this.controlFinishLoad = !!o.controlFinishLoad;
      this.__bindHandle('ctrl/EasyRefresh', {
        // 构造参数随句柄 create 下发：宿主据此创建真实 controller（putIfAbsent——
        // 创建消息与首帧渲染谁先到都复用同一实例）。
        meta: function (self) {
          return {
            controlFinishRefresh: self.controlFinishRefresh,
            controlFinishLoad: self.controlFinishLoad
          };
        },
        // 组件渲染时 controller 经 toJSON 跨桥（`{__handle, controlFinish*}`），
        // Host 在渲染期兜底创建时同样读得到构造参数。
        extraJSON: function (self) {
          return {
            controlFinishRefresh: self.controlFinishRefresh,
            controlFinishLoad: self.controlFinishLoad
          };
        }
      });
    }
    __op(method, args) {
      if (this.__id == null) { return undefined; }
      return handleOp(this.__id, 'call', { method: method, args: args });
    }
    callRefresh() {
      return this.__op('callRefresh', Array.prototype.slice.call(arguments));
    }
    callLoad() {
      return this.__op('callLoad', Array.prototype.slice.call(arguments));
    }
    openHeaderSecondary() {
      return this.__op('openHeaderSecondary', Array.prototype.slice.call(arguments));
    }
    closeHeaderSecondary() {
      return this.__op('closeHeaderSecondary', Array.prototype.slice.call(arguments));
    }
    openFooterSecondary() {
      return this.__op('openFooterSecondary', Array.prototype.slice.call(arguments));
    }
    closeFooterSecondary() {
      return this.__op('closeFooterSecondary', Array.prototype.slice.call(arguments));
    }
    resetHeader() { return this.__op('resetHeader', []); }
    resetFooter() { return this.__op('resetFooter', []); }
    finishRefresh() {
      return this.__op('finishRefresh', Array.prototype.slice.call(arguments));
    }
    finishLoad() {
      return this.__op('finishLoad', Array.prototype.slice.call(arguments));
    }
  }
''';
