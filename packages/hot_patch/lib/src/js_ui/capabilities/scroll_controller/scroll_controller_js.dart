// 由 runtime_source.dart 拆出的 ScrollController JS 片段（能力内聚，见 capabilities/ 设计规范）。
// runtime_source 把骨架与各能力片段拼接后注入（同一 IIFE 作用域，片段间靠函数提升互调）。
const String scrollControllerJsSource = r'''
  // ===== 【10.5】ScrollController 代理类（对应 Flutter 官方 ScrollController）===
  // 生成器把 Dart 侧 `final ScrollController _scrollController = ScrollController();`
  // 翻译成 `this._scrollController = new ScrollController()`；实例与宿主侧真实
  // ScrollController 按**句柄 id** 绑定（通用层，见【1b】句柄注册表）：
  //   - 构造：登记 kind=ctrl/Scroll 句柄（scope=page，页面退出自动回收），并把
  //     metrics 转发句柄（fn）交给宿主；
  //   - addListener/removeListener：JS 闭包直接登记——**匿名闭包天然支持**，
  //     无需生成器合成方法名，不存在重名问题；
  //   - jumpTo/animateTo/dispose：dispose 走通用 releaseHandle（通知宿主释放真实
  //     controller），jumpTo/animateTo 走实例级 host 通道（载荷带 id，多实例互不干扰）；
  //   - offset / position / hasClients：本地镜像（宿主回传更新）。
  // 跨桥序列化：props 里的实例经 toJSON 输出 `{__handle: id}`，宿主据此取/建
  // 真实 controller（见 scroll_controller_bridge.dart）。
  defineHandleKind('ctrl/Scroll', {
    release: function (h) {
      var c = h.obj;
      if (!c) { return; }
      // 内部 metrics 转发句柄是框架实现（用户无从释放），随本控制器一并释放。
      if (c.__metricsFn) { releaseHandle(c.__metricsFn.__fn, false); c.__metricsFn = null; }
      c.__listeners = [];
    }
  });
  function ScrollController() {
    this.__listeners = [];
    this.offset = 0;
    this.__maxScrollExtent = 0;
    this.__viewportDimension = 0;
    this.__extentAfter = 0;
    var self = this;
    this.__metricsFn = fn(function (p) { self.__onMetrics(p); });
    // 登记为句柄（scope=page）：自动同步宿主 onCreate（meta 携带 metrics 转发
    // 句柄供宿主回传滚动快照）；页面退出时 disposeRoot 兜底释放。
    this.__id = reg(this, 'ctrl/Scroll', { meta: { fn: this.__metricsFn } });
  }
  ScrollController.prototype.addListener = function (f) {
    if (typeof f === 'function') { this.__listeners.push(f); }
  };
  ScrollController.prototype.removeListener = function (f) {
    var i = this.__listeners.indexOf(f);
    if (i >= 0) { this.__listeners.splice(i, 1); }
  };
  ScrollController.prototype.jumpTo = function (offset) {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'jumpTo', args: [offset] }); }
  };
  ScrollController.prototype.animateTo = function (offset, opts) {
    if (this.__id == null) { return; }
    var ms = (opts && typeof opts.duration === 'number') ? opts.duration : 300;
    var curve = (opts && opts.curve) ? opts.curve : 'easeOut';
    handleOp(this.__id, 'call', { method: 'animateTo', args: [offset, ms, curve] });
  };
  ScrollController.prototype.dispose = function () {
    releaseHandle(this.__id);
    this.__id = null;
  };
  ScrollController.prototype.toJSON = function () {
    return { __handle: this.__id };
  };
  Object.defineProperty(ScrollController.prototype, 'position', {
    get: function () {
      return {
        pixels: this.offset,
        maxScrollExtent: this.__maxScrollExtent,
        viewportDimension: this.__viewportDimension,
        extentAfter: this.__extentAfter
      };
    }
  });
  Object.defineProperty(ScrollController.prototype, 'hasClients', {
    get: function () { return this.__id != null; }
  });
  // 宿主回传 metrics 快照 → 更新镜像并触发 listeners（listener 无参，
  // 与 Dart addListener 语义一致；闭包内读 this._scrollController.offset）。
  ScrollController.prototype.__onMetrics = function (p) {
    if (!p) { return; }
    this.offset = p.pixels;
    this.__maxScrollExtent = p.maxScrollExtent;
    this.__viewportDimension = p.viewportDimension;
    this.__extentAfter = p.extentAfter;
    var fs = this.__listeners;
    for (var i = 0; i < fs.length; i++) { fs[i](); }
  };
  G.ScrollController = ScrollController;
''';
