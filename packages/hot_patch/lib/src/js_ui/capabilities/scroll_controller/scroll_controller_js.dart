// 由 runtime_js.dart 拆出的 ScrollController JS 片段（能力内聚，见 capabilities/ 设计规范）。
// runtime_source 把骨架与各能力片段拼接后注入（同一 IIFE 作用域，片段间靠函数提升互调）。
const String scrollControllerJsSource = r'''
  // ===== 【10.5】ScrollController 代理类（对应 Flutter 官方 ScrollController）===
  // 生成器把 Dart 侧 `final ScrollController _scrollController = ScrollController();`
  // 翻译成 `this._scrollController = new ScrollController()`；实例与宿主侧真实
  // ScrollController 按**句柄 id** 绑定。
  // 三件套基座（__listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由通用
  // 工厂 defineController 提供（见【1c】）；本类只写差异：
  //   - offset / position / hasClients：本地镜像（宿主回传 metrics 更新）；
  //   - jumpTo/animateTo：实例级 host 通道（载荷带 id，多实例互不干扰）；
  //   - addListener/removeListener：JS 闭包直接登记——**匿名闭包天然支持**，
  //     无需生成器合成方法名，不存在重名问题。
  // 跨桥序列化：props 里的实例经 toJSON 输出 `{__handle: id}`，宿主据此取/建
  // 真实 controller（见 scroll_controller_bridge.dart）。
  var ScrollController = defineController('ctrl/Scroll', {
    init: function () {
      this.offset = 0;
      this.__maxScrollExtent = 0;
      this.__viewportDimension = 0;
      this.__extentAfter = 0;
    },
    // 宿主回传 metrics 快照 → 更新镜像并触发 listeners（listener 无参，
    // 与 Dart addListener 语义一致；闭包内读 this._scrollController.offset）。
    onHost: function (self, p) {
      if (!p) { return; }
      self.offset = p.pixels;
      self.__maxScrollExtent = p.maxScrollExtent;
      self.__viewportDimension = p.viewportDimension;
      self.__extentAfter = p.extentAfter;
      self.__notify();
    },
  });
  ScrollController.prototype.jumpTo = function (offset) {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'jumpTo', args: [offset] }); }
  };
  ScrollController.prototype.animateTo = function (offset, opts) {
    if (this.__id == null) { return; }
    var ms = (opts && typeof opts.duration === 'number') ? opts.duration : 300;
    var curve = (opts && opts.curve) ? opts.curve : 'easeOut';
    handleOp(this.__id, 'call', { method: 'animateTo', args: [offset, ms, curve] });
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
  G.ScrollController = ScrollController;

  // ===== PageController 代理类（对应 Flutter 官方 PageController）=====
  // 与 ScrollController 同一套句柄层；镜像字段只有 page / initialPage。
  // 构造参数（initialPage / viewportFraction）随 toJSON 的 extraJSON 下发，
  // 宿主 PageView renderer 据此创建真实 PageController。
  var PageController = defineController('ctrl/Page', {
    init: function (opts) {
      var o = opts || {};
      this.initialPage = (o.initialPage != null) ? o.initialPage : 0;
      this.page = this.initialPage;
      this.viewportFraction = (o.viewportFraction != null) ? o.viewportFraction : 1.0;
    },
    onHost: function (self, p) {
      if (p && p.page != null) { self.page = p.page; }
      self.__notify();
    },
    extraJSON: function (self) {
      return {
        initialPage: self.initialPage,
        viewportFraction: self.viewportFraction
      };
    }
  });
  PageController.prototype.jumpToPage = function (page) {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'jumpToPage', args: [page] }); }
  };
  PageController.prototype.animateToPage = function (page, opts) {
    if (this.__id == null) { return; }
    var ms = (opts && typeof opts.duration === 'number') ? opts.duration : 300;
    var curve = (opts && opts.curve) ? opts.curve : 'easeOut';
    handleOp(this.__id, 'call', { method: 'animateToPage', args: [page, ms, curve] });
  };
  PageController.prototype.nextPage = function (opts) {
    if (this.__id == null) { return; }
    var ms = (opts && typeof opts.duration === 'number') ? opts.duration : 300;
    handleOp(this.__id, 'call', { method: 'nextPage', args: [ms] });
  };
  PageController.prototype.previousPage = function (opts) {
    if (this.__id == null) { return; }
    var ms = (opts && typeof opts.duration === 'number') ? opts.duration : 300;
    handleOp(this.__id, 'call', { method: 'previousPage', args: [ms] });
  };
  Object.defineProperty(PageController.prototype, 'hasClients', {
    get: function () { return this.__id != null; }
  });
  G.PageController = PageController;
''';
