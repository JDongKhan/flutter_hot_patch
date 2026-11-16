// WidgetsBinding（Dart 类名 1:1）：Flutter SDK 的帧调度 API 面。
//
// 产物里的 `WidgetsBinding.instance.xxx` 按**同名翻译**原样落成同名调用
// （`WidgetsBinding.instance` 是 PrefixedIdentifier，翻译层对大写前缀原样保留；
// 成员调用是普通成员调用），因此这里只需提供同名类与同名方法，翻译器与运行时
// 框架都不动。依赖的宿主能力全部走既有唯一出口 `_app_host_.invoke`：
//   - `jsuiRequestFrame`：既有通道（JS setState 也用它），用于逐帧续帧；
//   - `jsuiEndOfFrame`：新增内建通道，宿主用 `WidgetsBinding.instance.endOfFrame`
//     结算（真正的帧末），见 builtin_host_methods 的 `_endOfFrame`。
//
// 帧模型（设计内）：JS 侧没有独立帧循环，帧由宿主 Flutter 驱动。宿主在
// `jsuiRequestFrame` 的 begin-frame 回调里先 flush JS 待重建，再回调
// `__jsui.frameTick(ms)`；`frameTick` 跑完持久回调后若仍有存活的回调，就再请求
// 一帧，形成逐帧节奏（同一帧的重复请求由宿主 `_flushScheduled` 合并）。
//
// 语义差：`addPersistentFrameCallback` 的回调运行在宿主 build 之前（flush 之后），
// 不是 Dart 的「build/paint 之后」；`addPostFrameCallback` 仍用一次性
// `setTimeout(cb, 0)` 表示「当前任务（含微任务）结束」。
//
// 未实现的成员（不产出占位实现，调用即显式失败）：`addObserver` /
// `removeObserver`（JS 侧没有 App 生命周期事件通道）、`scheduleFrameCallback`、
// `waitUntilFirstFrameRasterized`；`SchedulerBinding` 不提供同名类。
const String widgetsBindingJsSource = r'''
  export class WidgetsBinding {
    static __instance = null;
    // 同一轮「帧后」待执行的回调；`__scheduled` 保证一批只排一个定时器。
    static __queue = [];
    static __scheduled = false;
    // 持久帧回调：{ cb, root }。root 是注册时所在页面/弹层根的 key，页面销毁时
    // 由 onRootClose 生命周期实现摘除；注册发生在无构建上下文时记 null（跟随整个
    // runtime）。
    static __persistent = [];

    static get instance() {
      if (WidgetsBinding.__instance == null) {
        WidgetsBinding.__instance = new WidgetsBinding();
      }
      return WidgetsBinding.__instance;
    }

    // 注册时所在根的 key：build 期优先，其次当前活动根（挂载 / flush 期）。
    static __rootKey() {
      var inst = G.__core.building;
      var root = inst && inst.__root ? inst.__root : G.__core.activeRoot;
      return root ? root.key : null;
    }

    // 请求宿主在下一帧回调 `__jsui.frameTick`（复用既有的唯一帧请求通道）。
    static __requestFrame() {
      if (typeof sendMessage === 'function' && G._app_host_) {
        G._app_host_.invoke('jsuiRequestFrame', []);
      }
    }

    // 宿主每帧回调入口：派发持久帧回调；仍有存活回调时续帧。
    // 页面销毁时的摘除由 onRootClose 实现负责（见文件末尾），这里不再判断根是否存活。
    static frameTick(ms) {
      var timestamp = new Duration({ milliseconds: ms });
      var alive = [];
      for (var i = 0; i < WidgetsBinding.__persistent.length; i++) {
        var entry = WidgetsBinding.__persistent[i];
        alive.push(entry);
        try {
          entry.cb(timestamp);
        } catch (e) {
          __error('WidgetsBinding.addPersistentFrameCallback: ' + String(e));
        }
      }
      WidgetsBinding.__persistent = alive;
      if (alive.length > 0) { WidgetsBinding.__requestFrame(); }
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

    // `addPersistentFrameCallback(FrameCallback cb)`：宿主每帧回调一次，直到
    // 注册它的页面根销毁。Dart 侧没有移除接口，这里同样不提供。
    addPersistentFrameCallback(cb) {
      if (typeof cb !== 'function') { return; }
      WidgetsBinding.__persistent.push({
        cb: cb,
        root: WidgetsBinding.__rootKey()
      });
      WidgetsBinding.__requestFrame();
    }

    // `Future<void> get endOfFrame`：宿主用 Flutter 的 endOfFrame 结算，返回
    // Promise，帧结束（post-frame 之后）时完成；空闲时由宿主自动催一帧。
    get endOfFrame() {
      if (typeof sendMessage !== 'function' || !G._app_host_) {
        return Promise.resolve();
      }
      return G._app_host_.invoke('jsuiEndOfFrame', []);
    }

    // 宿主负责帧循环：JS 侧没有可催的帧，保持空操作（不伪造调度）。
    scheduleFrame() {}

    ensureVisualUpdate() { this.scheduleFrame(); }
  }

  // 宿主每帧回调入口（与 panelMount 同口径：宿主调用点带存在性守卫，
  // 早于本模块加载时是 no-op；而注册持久回调必然先经过本模块）。
  G.__jsui.frameTick = WidgetsBinding.frameTick;

  // 页面根关闭：丢弃该页注册的持久帧回调（root 为 null 的跟随整个 runtime，
  // 其它页面的回调保留）。生命周期由 runtime 核心统一调度，本类不再感知 __roots。
  G.__core.__implement({
    name: 'widgetsBindingFrames',
    onRootClose: function (root) {
      var list = WidgetsBinding.__persistent;
      var kept = [];
      for (var i = 0; i < list.length; i++) {
        if (list[i].root !== root.key) { kept.push(list[i]); }
      }
      WidgetsBinding.__persistent = kept;
    }
  });
''';
