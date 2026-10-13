// 由 runtime_source.dart 拆出的 ScrollController JS 片段（能力内聚，见 capabilities/ 设计规范）。
// runtime_source 把骨架与各能力片段拼接后注入（同一 IIFE 作用域，releaseController 依赖函数提升）。
const String scrollControllerJsSource = r'''
  // ===== 【10.5】ScrollController 代理类（对应 Flutter 官方 ScrollController）===
  // 生成器把 Dart 侧 `final ScrollController _scrollController = ScrollController();`
  // 翻译成 `this._scrollController = new ScrollController()`；实例与宿主侧真实
  // ScrollController 按 id 绑定：
  //   - 构造：登记 metrics 转发句柄（fn），宿主滚动时经 invoke 回传镜像；
  //   - addListener/removeListener：JS 闭包直接登记——**匿名闭包天然支持**，
  //     无需生成器合成方法名，不存在重名问题；
  //   - jumpTo/animateTo/dispose：实例级 host 通道（载荷带 id），多实例互不干扰；
  //   - offset / position / hasClients：本地镜像（宿主回传更新）。
  // 跨桥序列化：props 里的实例经 toJSON 输出 `{__jsuiScrollController: id}`，
  // 宿主据此取/建真实 controller（见 js_widget_registry.dart）。
  //
  // 释放一个控制器：页面退出兜底与组件 dispose 共用的入口——按 __kind 分派到
  // 各自的释放逻辑（sc / tec / tc），避免走错通道导致宿主真实对象泄漏。
  // 幂等——重复调用为空操作。
  function releaseController(c) {
    if (!c) { return; }
    if (c.__kind === 'tec') { releaseTextEditingController(c); return; }
    if (c.__kind === 'tc') { releaseTabController(c); return; }
    if (c.__metricsFn) { delete handlers[c.__metricsFn.__fn]; c.__metricsFn = null; }
    if (c.__id != null) {
      host('scrollControllerDispose', [c.__id]);
      c.__id = null;
    }
    c.__listeners = [];
  }
  function ScrollController() {
    this.__kind = 'sc';
    this.__id = nextId('sc');
    this.__listeners = [];
    this.offset = 0;
    this.__maxScrollExtent = 0;
    this.__viewportDimension = 0;
    this.__extentAfter = 0;
    var self = this;
    this.__metricsFn = fn(function (p) { self.__onMetrics(p); });
    // 按当前页面登记（构造发生在 mount/构建期间，activeRoot 即本页根），
    // 页面退出时 disposeRoot 兜底释放。
    if (activeRoot) {
      var list = pageControllers[activeRoot.key] ||
        (pageControllers[activeRoot.key] = []);
      list.push(this);
    }
    host('scrollControllerRegister', [this.__id, this.__metricsFn]);
  }
  ScrollController.prototype.addListener = function (f) {
    if (typeof f === 'function') { this.__listeners.push(f); }
  };
  ScrollController.prototype.removeListener = function (f) {
    var i = this.__listeners.indexOf(f);
    if (i >= 0) { this.__listeners.splice(i, 1); }
  };
  ScrollController.prototype.jumpTo = function (offset) {
    if (this.__id != null) { host('scrollControllerJumpTo', [this.__id, offset]); }
  };
  ScrollController.prototype.animateTo = function (offset, opts) {
    if (this.__id == null) { return; }
    var ms = (opts && typeof opts.duration === 'number') ? opts.duration : 300;
    var curve = (opts && opts.curve) ? opts.curve : 'easeOut';
    host('scrollControllerAnimateTo', [this.__id, offset, ms, curve]);
  };
  ScrollController.prototype.dispose = function () {
    releaseController(this);
  };
  ScrollController.prototype.toJSON = function () {
    return { __jsuiScrollController: this.__id };
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