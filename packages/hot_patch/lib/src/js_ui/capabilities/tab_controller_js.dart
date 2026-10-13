// 由 runtime_source.dart 拆出的 TabController JS 片段（能力内聚，见 capabilities/ 设计规范）。
// runtime_source 把骨架与各能力片段拼接后注入（同一 IIFE 作用域，releaseController /
// releaseTabController 依赖函数提升互调）。
const String tabControllerJsSource = r'''
  // ===== 【10.7】TabController 代理类（对应 Flutter 官方 TabController）===
  // 生成器把 Dart 侧 `late final TabController _c = TabController(length: 3, vsync: this)`
  // 翻译成 `this._c = new TabController({length: 3, vsync: this})`（vsync 由本代理
  // 类忽略），实例与宿主侧真实 TabController 按 id 绑定（同 ScrollController 模式）：
  //   - 构造：登记 index 转发句柄（宿主用户点 tab / 动画结束经 invoke 回传页码），
  //     真实实例由宿主在渲染 TabBar / TabBarView 时按 id 取/建（length 随句柄下发）；
  //   - index：本地镜像（宿主回传更新），setter 立即设置宿主 index；
  //   - animateTo(i)：宿主 controller.animateTo（带动画）；
  //   - addListener/removeListener：闭包直接登记（匿名闭包天然支持）；
  //   - dispose：删句柄 + 通知宿主释放真实 controller（幂等）。
  // 跨桥序列化：toJSON 输出 `{__jsuiTabController: id, length, initialIndex}`——
  // 宿主据此取/建真实 controller（见 capabilities/tab_drawer_bridge.dart）。
  function releaseTabController(tc) {
    if (!tc) { return; }
    if (tc.__indexFn) { delete handlers[tc.__indexFn.__fn]; tc.__indexFn = null; }
    if (tc.__id != null) {
      host('tabControllerDispose', [tc.__id]);
      tc.__id = null;
    }
    tc.__listeners = [];
  }
  function TabController(opts) {
    opts = opts || {};
    this.__kind = 'tc';
    this.__id = nextId('tc');
    this.__listeners = [];
    this.length = (typeof opts.length === 'number') ? opts.length : 0;
    this.__index = (typeof opts.initialIndex === 'number') ? opts.initialIndex : 0;
    var self = this;
    this.__indexFn = fn(function (i) { self.__onIndex(i); });
    // 按当前页面登记（同 ScrollController），页面退出时 disposeRoot 兜底释放。
    if (activeRoot) {
      var list = pageControllers[activeRoot.key] ||
        (pageControllers[activeRoot.key] = []);
      list.push(this);
    }
    host('tabControllerRegister', [this.__id, this.__indexFn]);
  }
  TabController.prototype.addListener = function (f) {
    if (typeof f === 'function') { this.__listeners.push(f); }
  };
  TabController.prototype.removeListener = function (f) {
    var i = this.__listeners.indexOf(f);
    if (i >= 0) { this.__listeners.splice(i, 1); }
  };
  TabController.prototype.animateTo = function (index) {
    if (this.__id != null) { host('tabControllerAnimateTo', [this.__id, index]); }
  };
  TabController.prototype.dispose = function () { releaseTabController(this); };
  TabController.prototype.toJSON = function () {
    return {
      __jsuiTabController: this.__id,
      length: this.length,
      initialIndex: this.__index
    };
  };
  TabController.prototype.__notifyIndex = function () {
    var fs = this.__listeners;
    for (var i = 0; i < fs.length; i++) { fs[i](); }
  };
  Object.defineProperty(TabController.prototype, 'index', {
    get: function () { return this.__index; },
    set: function (v) {
      this.__index = (typeof v === 'number') ? v : 0;
      if (this.__id != null) { host('tabControllerSetIndex', [this.__id, this.__index]); }
      // 与 Dart 语义一致：直接设置 index 立即通知监听者（宿主回传会再通知一次，
      // 幂等，setState 重复触发无副作用）。
      this.__notifyIndex();
    }
  });
  // 宿主回传（用户点 tab / animateTo 动画结束）→ 更新镜像 + 触发 listeners。
  TabController.prototype.__onIndex = function (i) {
    if (typeof i !== 'number') { return; }
    this.__index = i;
    this.__notifyIndex();
  };
  G.TabController = TabController;
''';