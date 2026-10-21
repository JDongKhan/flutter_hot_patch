// easy_refresh 能力的 JS 片段（能力内聚，见 capabilities/ 设计规范）。
//
// EasyRefresh 的「手势 / 物理 / 指示器」都在宿主侧，而回调 onRefresh / onLoad
// 由 JS 补丁实现，因此存在一次**宿主发起、JS 异步完成**的往返：
//
//   宿主（用户下拉）--__jsuiAwaitRun(句柄 id, token)--> JS 执行事件方法
//   JS（任务结束）----> 宿主通道 'jsuiAwaitDone'（回传 token）--> 指示器收起
//
// 为什么要有这条回程：宿主 → JS 的 `__jsui.invoke` 是**单向**的，且 flutter_js
// 在 iOS/JavaScriptCore 上无法把 JS 的 Promise 交回 Dart（evaluateAsync 就是
// 同步 evaluate），宿主拿不到「JS 任务何时结束」。于是由 JS 侧 await 事件句柄的
// 返回值，完成后再经**唯一 JS→宿主出口** `_app_host_.invoke`（host）回传 token，
// 宿主据此结算对应 Completer（见 easy_refresh_bridge.dart）。
//
// 事件句柄能返回 Promise，靠的是 `__bindFn` 生成的 wrapper 原样返回箭头闭包
// 的结果（见 js/mini_react_js.dart）；Dart 的 async 方法在 JS 侧就是
// async 函数，返回 Promise。
const String easyRefreshJsSource = r'''
  // ===== 【11】EasyRefresh｜宿主发起 + JS 异步完成 =====================
  // 宿主侧桥接见 capabilities/easy_refresh/easy_refresh_bridge.dart 的
  // `_runAwaitableEvent`：evaluate 本函数触发一次事件，并等 token 回传。
  // 挂 G（globalThis）：宿主经 evaluate 裸引用调用，与 `__jsui` 同一约定。
  G.__jsuiAwaitRun = function (handleId, token) {
    var h = handles[handleId];
    var out = null;
    try {
      out = (h && typeof h.obj === 'function') ? h.obj() : null;
    } catch (e) {
      // 事件方法同步抛错：按「已完成」收尾——指示器必须收起，不能挂死在转圈。
      if (typeof console !== 'undefined' && console.error) {
        console.error(String(e));
      }
    }
    // 完成回传走 host（唯一 JS→宿主出口）；onFulfilled / onRejected 都必须回传，
    // 否则宿主侧那条 pending 永远等不到结算。
    var done = function () { host('jsuiAwaitDone', [token]); };
    if (out && typeof out.then === 'function') {
      out.then(done, done);
    } else {
      done();
    }
  };
''';
