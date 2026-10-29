// ===== 基础能力：Dart Timer 的同名注入（JS 侧片段）=====
//
// 产物的构造翻译是 **1:1 原样发射**：`Timer.periodic(duration, cb)` →
// `Timer.periodic({duration, callback})`，运行时只要存在同名类即可执行。
// 因此这里不引入任何新的产物协议，只补 Dart SDK 的 `Timer`：
//
//   - `Timer(…)` / `Timer.periodic(…)` 均为同名 JS 函数；
//   - 引擎（flutter_js / QuickJS）只提供一次性 `setTimeout`，没有
//     `setInterval`，周期定时用「回调内再次 setTimeout」实现；
//   - `cancel()` 后不再触发（宿主没有 clearTimeout 时也只靠取消标记兜底，
//     残留的一次宿主定时器到期后会直接 return）。
//
// 与其它能力一样，这里是**唯一要改的地方**：以后 Dart 侧新增同类的定时
// 语义（如 `Timer.run`），只需在本文件补一个同名方法，翻译器与宿主都不动。
const String timerJsSource = r'''
  // 实参归一：正常形态是 `{duration, callback}`；构建期查不到签名时位置实参
  // 落在 `__pos` 里，由 __posArgs 按形参名展开。容错地再支持一次
  // 「第一个实参直接就是 Duration 对象」的形态，避免任何调用写法静默失效。
  function __timerArgs(props, second) {
    var duration = null;
    var callback = null;
    if (props && typeof props.inMilliseconds === 'number') {
      duration = props;
      callback = second;
    } else {
      var opts = __posArgs(props, ['duration', 'callback']);
      duration = opts.duration;
      callback = opts.callback;
    }
    var ms = __durationMs(duration);
    if (ms == null || ms < 0) { ms = 0; }
    return { ms: ms, callback: callback };
  }

  export class Timer {
    constructor(props) {
      __timerInit(this, props, false, null);
    }
    cancel() {
    this._cancelled = true;
    this._active = false;
    if (this._handle != null && typeof clearTimeout === 'function') {
  try { clearTimeout(this._handle); } catch (e) {}
    }
    this._handle = null;
    }
    toJSON() {
    return { __timer: true, active: !!this._active, repeat: !!this._repeat, ms: this._ms };
    }
    static periodic(props, second) {
    var t = Object.create(Timer.prototype);
    __timerInit(t, props, true, second);
    return t;
    }
    get isActive() {
      return !!this._active;
    }
  }

  // __timerInit 在所有 Timer 实例间共用（构造与 periodic 两条入口）。
  function __timerInit(self, props, repeat, second) {
    var args = __timerArgs(props, second);
    self._ms = args.ms;
    self._callback = args.callback;
    self._repeat = !!repeat;
    self._active = true;
    self._cancelled = false;
    self._handle = null;
    __timerSchedule(self);
  }

  function __timerSchedule(self) {
    if (self._cancelled) { return; }
    self._handle = setTimeout(function () {
      self._handle = null;
      if (self._cancelled) { return; }
      if (!self._repeat) { self._active = false; }
      try {
        if (typeof self._callback === 'function') { self._callback(self); }
      } catch (e) {
        console.error('[patch] Timer 回调异常: ' +
          ((e && e.message) ? e.message : e));
      }
      if (self._repeat && !self._cancelled) { __timerSchedule(self); }
    }, self._ms);
  }



  // Timer 不是跨语言句柄：万一被当作值下发，只带状态字段（调试友好，宿主侧无对应还原）。


''';
