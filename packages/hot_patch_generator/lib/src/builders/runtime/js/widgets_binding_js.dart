// WidgetsBinding（Dart 类名 1:1）：Flutter SDK 的帧调度 API 面。
//
// 产物里的 `WidgetsBinding.instance.addPostFrameCallback(cb)` 按**同名翻译**
// 原样落成同名调用（`WidgetsBinding.instance` 是 PrefixedIdentifier，翻译层
// 对大写前缀原样保留；`addPostFrameCallback` 是普通成员调用），因此这里只需
// 提供同名类与同名方法，翻译器与运行时框架都不动。
//
// 语义差（设计内）：JS 侧没有独立帧循环——帧由宿主 Flutter 驱动，JS 只能观察
// 「当前任务（含微任务）结束」，故 post-frame 用一次性 `setTimeout(cb, 0)` 承接：
// 同一轮注册的回调按注册顺序在同一批执行，形参是与 `FrameCallback(Duration)`
// 同形的时长对象（批开始时刻）。`scheduleFrame` / `ensureVisualUpdate` 是空
// 操作（下一帧由宿主决定，JS 无权催帧）。
//
// 未实现的成员（不产出占位实现，调用即显式失败）：`addObserver` /
// `removeObserver`（JS 侧没有 App 生命周期事件通道）、`addPersistentFrameCallback`
// （无逐帧回调源）、`scheduleFrameCallback`、`waitUntilFirstFrameRasterized`。
const String widgetsBindingJsSource = r'''
  export class WidgetsBinding {
    static __instance = null;
    // 同一轮「帧后」待执行的回调；`__scheduled` 保证一批只排一个定时器。
    static __queue = [];
    static __scheduled = false;

    static get instance() {
      if (WidgetsBinding.__instance == null) {
        WidgetsBinding.__instance = new WidgetsBinding();
      }
      return WidgetsBinding.__instance;
    }

    // `addPostFrameCallback(FrameCallback cb)`：当前任务结束后执行一次。
    // 形参与 Dart 一致（Duration 时间戳）；非函数实参直接忽略（与 Dart 的
    // 空回调类型约束一致，不在这里抛业务错）。
    addPostFrameCallback(cb) {
      if (typeof cb !== 'function') { return; }
      WidgetsBinding.__queue.push(cb);
      if (WidgetsBinding.__scheduled) { return; }
      WidgetsBinding.__scheduled = true;
      setTimeout(function () {
        WidgetsBinding.__scheduled = false;
        var pending = WidgetsBinding.__queue;
        WidgetsBinding.__queue = [];
        var timestamp = new Duration({ milliseconds: Date.now() });
        for (var i = 0; i < pending.length; i++) {
          pending[i](timestamp);
        }
      }, 0);
    }

    // 宿主负责帧循环：JS 侧没有可催的帧，保持空操作（不伪造调度）。
    scheduleFrame() {}

    ensureVisualUpdate() { this.scheduleFrame(); }
  }
''';
