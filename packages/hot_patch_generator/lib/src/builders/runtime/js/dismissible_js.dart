// Dismissible 能力的 JS 片段：confirmDismiss 的「异步回程」。
//
// 宿主（用户滑动到阈值）--__jsuiAwaitValue(句柄 id, token, 参数 JSON)--> JS
//   JS 执行事件方法 → 若返回 Promise 则 await → 结果经 host 回传 token
//   JS --> 宿主通道 'jsuiAwaitValueDone'（[token, 结果 JSON]）→ 宿主任结算
//
// 与 easy_refresh 的 `__jsuiAwaitRun` 同一思路（见 easy_refresh_js.dart）：
// 宿主 → JS 的 invoke 是单向的，且 iOS/JavaScriptCore 无法把 JS Promise 交回
// Dart；于是由 JS 侧 await 事件句柄的返回值，再经唯一 JS→宿主出口回传。
const String dismissibleJsSource = r'''
  // DismissDirection 枚举镜像：Dart 里 `DismissDirection.endToStart` 是枚举值，
  // 跨语言只有名字能表达（宿主也按 name 下发/回传），因此 JS 侧的同名常量就是
  // 名字字符串。这样 `direction == DismissDirection.endToStart` 这种源码级比较
  // 在 JS 侧**语义不变**（生成器对 props 里的枚举值同样下发名字字符串）。
  G.DismissDirection = {
    horizontal: 'horizontal',
    vertical: 'vertical',
    startToEnd: 'startToEnd',
    endToStart: 'endToStart',
    up: 'up',
    down: 'down'
  };

  // 宿主侧桥接见 capabilities/dismissible/dismissible_bridge.dart 的
  // `_awaitJsValue`：evaluate 本函数触发一次事件，并等 token + 结果回传。
  // 挂 G（globalThis）：宿主经 evaluate 裸引用调用，与 `__jsuiAwaitRun` 同一约定。
  G.__jsuiAwaitValue = function (handleId, token, argsJson) {
    var h = handles[handleId];
    var args = [];
    try { args = argsJson ? JSON.parse(argsJson) : []; } catch (e) { args = []; }
    var out;
    try {
      out = (h && typeof h.obj === 'function') ? h.obj.apply(null, args) : null;
    } catch (e) {
      // 事件同步抛错：按「已返回 null」收尾，宿主那条 pending 必须有结果。
      console.error(String(e));
      host('jsuiAwaitValueDone', [token, 'null']);
      return;
    }
    var done = function (v) {
      var s = 'null';
      try { s = JSON.stringify(v === undefined ? null : v); } catch (e) { s = 'null'; }
      host('jsuiAwaitValueDone', [token, s]);
    };
    if (out && typeof out.then === 'function') {
      out.then(done, function () { done(null); });
    } else {
      done(out);
    }
  };
''';
