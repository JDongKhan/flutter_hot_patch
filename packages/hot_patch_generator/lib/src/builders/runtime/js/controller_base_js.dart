// 控制器基类：Dart Controller（ScrollController / TabController / …）的 JS 镜像
// 共用的一层句柄封装（随 flutter.js 发布）。
//
// 职责（与能力无关）：
//   - `__listeners` + addListener / removeListener / `__notify`（Dart Listenable 语义）；
//   - 跨语言句柄登记（kind 由子类给出），meta 携带「宿主回传句柄」与子类构造参数；
//   - `toJSON` 输出 `{__handle: id}`（props 里的 controller 跨桥只传句柄）；
//   - 句柄释放时清掉回传句柄与订阅（释放入口由 runtime 的句柄机制驱动）。
//
// 子类只写差异（构造里初始化镜像字段，然后调用 `__bindHandle(kind, spec)`）：
//   spec.onHost(self, p) ：宿主回传 → 更新镜像 + `__notify`（缺省则无回传句柄）；
//   spec.meta(self)      ：随句柄 create 下发给宿主的构造参数（宿主据此创建真实对象）；
//   spec.extraJSON(self) ：toJSON 附加字段（如 Tab 的 length / initialIndex）。
//
// 依赖方向：本类用 runtime 的句柄机制（`G.__core`：registerHandle / handleOp /
// releaseHandle / createFnHandle），runtime 不需要认识任何控制器。
const String controllerBaseJsSource = r'''
  export class ControllerBase {
    constructor() {
      this.__listeners = [];
      this.__id = null;
      this.__spec = null;
    }

    // 子类构造末尾调用：登记为句柄（scope 由句柄机制按当前上下文决定——通常是
    // 「随持有它的组件实例释放」），并自动同步宿主 onCreate（meta 携带回传句柄
    // 与子类构造参数，供宿主创建真实对象）；页面退出时 disposeRoot 兜底释放。
    __bindHandle(kind, spec) {
      spec = spec || {};
      this.__spec = spec;
      var self = this;
      if (spec.onHost) {
        this.__hostFn = __createFnHandle(function (p) { spec.onHost(self, p); });
      }
      var meta = this.__hostFn ? { fn: this.__hostFn } : null;
      if (spec.meta) {
        var extra = spec.meta(this);
        if (extra) {
          meta = meta || {};
          for (var k in extra) { meta[k] = extra[k]; }
        }
      }
      // 释放钩子随登记声明（由本控制器实现，不经全局 kind 注册表）。
      this.__id = registerHandle(this, kind, {
        meta: meta,
        release: function (h) { if (h.obj) { h.obj.__releaseResources(); } }
      });
      return this.__id;
    }

    // 句柄释放（宿主发起或页面兜底）：内部回传句柄是框架实现（用户无从释放），
    // 随本控制器一并释放；订阅一并清空（避免闭包引用泄漏）。
    __releaseResources() {
      if (this.__hostFn) {
        releaseHandle(this.__hostFn.__fn, false);
        this.__hostFn = null;
      }
      this.__listeners = [];
    }

    addListener(f) {
      if (typeof f === 'function') { this.__listeners.push(f); }
    }

    removeListener(f) {
      var i = this.__listeners.indexOf(f);
      if (i >= 0) { this.__listeners.splice(i, 1); }
    }

    __notify() {
      var fs = this.__listeners;
      for (var i = 0; i < fs.length; i++) { fs[i](); }
    }

    // 动画实参归一（ScrollController / PageController 共用）：Dart 的具名实参
    // 在 JS 调用里是**位置化扁平**（JS 无具名参数），因此
    // `animateTo(offset, duration: d, curve: c)` 到运行时就是 `(offset, d, c)`；
    // 也兼容直接传 options 对象的形态。三种 duration 形态（Duration 实例 /
    // options.duration 毫秒数 / options.duration 为 Duration）与两种 curve 形态
    // （字符串 / options.curve）统一归一。
    __animateArgs(opts, curveArg) {
      var ms = 300;
      var curve = 'easeOut';
      if (opts != null) {
        if (typeof opts.inMilliseconds === 'number') {
          ms = opts.inMilliseconds;
        } else if (typeof opts.duration === 'number') {
          ms = opts.duration;
        } else if (opts.duration && typeof opts.duration.inMilliseconds === 'number') {
          ms = opts.duration.inMilliseconds;
        }
        if (typeof opts.curve === 'string') { curve = opts.curve; }
      }
      if (typeof curveArg === 'string') { curve = curveArg; }
      return { ms: ms, curve: curve };
    }

    dispose() {
      if (this.__id != null) { releaseHandle(this.__id); }
      this.__id = null;
    }

    toJSON() {
      var out = { __handle: this.__id };
      var spec = this.__spec;
      if (spec && spec.extraJSON) {
        var extra = spec.extraJSON(this);
        if (extra) { for (var k in extra) { out[k] = extra[k]; } }
      }
      return out;
    }
  }
''';
