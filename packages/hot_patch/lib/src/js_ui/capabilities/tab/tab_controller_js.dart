// 由 runtime_source.dart 拆出的 TabController JS 片段（能力内聚，见 capabilities/ 设计规范）。
// runtime_source 把骨架与各能力片段拼接后注入（同一 IIFE 作用域，片段间靠函数提升互调）。
const String tabControllerJsSource = r'''
  // ===== 【10.7】TabController 代理类（对应 Flutter 官方 TabController）===
  // 生成器把 Dart 侧 `late final TabController _c = TabController(length: 3, vsync: this)`
  // 翻译成 `this._c = new TabController({length: 3, vsync: this})`（vsync 由本代理
  // 类忽略），实例与宿主侧真实 TabController 按**句柄 id** 绑定（通用层，见
  // 【1b】句柄注册表）：
  //   - 构造：登记 kind=ctrl/Tab 句柄（scope=page），登记 index 转发句柄（宿主用户
  //     点 tab / 动画结束经 invoke 回传页码），真实实例由宿主在渲染 TabBar /
  //     TabBarView 时按 id 取/建（length 随句柄下发）；
  //   - index：本地镜像（宿主回传更新），setter 立即设置宿主 index；
  //   - animateTo(i)：宿主 controller.animateTo（带动画）；
  //   - addListener/removeListener：闭包直接登记（匿名闭包天然支持）；
  //   - dispose：通用 releaseHandle（释放内部句柄 + 通知宿主释放真实 controller）。
  // 跨桥序列化：toJSON 输出 `{__handle: id, length, initialIndex}`——宿主据此取/建
  // 真实 controller（见 capabilities/tab/tab_bridge.dart）。
  defineHandleKind('ctrl/Tab', {
    release: function (h) {
      var tc = h.obj;
      if (!tc) { return; }
      if (tc.__indexFn) { releaseHandle(tc.__indexFn.__fn, false); tc.__indexFn = null; }
      tc.__listeners = [];
    }
  });
  function TabController(opts) {
    opts = opts || {};
    this.__listeners = [];
    this.length = (typeof opts.length === 'number') ? opts.length : 0;
    this.__index = (typeof opts.initialIndex === 'number') ? opts.initialIndex : 0;
    var self = this;
    this.__indexFn = fn(function (i) { self.__onIndex(i); });
    // 登记为句柄（scope=page）：自动同步宿主 onCreate（meta 携带 index 转发
    // 句柄）；页面退出时 disposeRoot 兜底释放。
    this.__id = reg(this, 'ctrl/Tab', { meta: { fn: this.__indexFn } });
  }
  TabController.prototype.addListener = function (f) {
    if (typeof f === 'function') { this.__listeners.push(f); }
  };
  TabController.prototype.removeListener = function (f) {
    var i = this.__listeners.indexOf(f);
    if (i >= 0) { this.__listeners.splice(i, 1); }
  };
  TabController.prototype.animateTo = function (index) {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'animateTo', args: [index] }); }
  };
  TabController.prototype.dispose = function () {
    releaseHandle(this.__id);
    this.__id = null;
  };
  TabController.prototype.toJSON = function () {
    return {
      __handle: this.__id,
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
      if (this.__id != null) { handleOp(this.__id, 'set', { name: 'index', value: this.__index }); }
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

  // TabBarView 登记为**懒容器**：它的 children 不随容器一起挂载，宿主真的 inflate
  // 到某个槽位时才挂载该子页（见 reconciler 的 lazyChildHosts / lazyMount）——
  // 这是「TabBarView 的懒加载」在 JS 侧的落点；否则一次切 TabBarView 就会把全部
  // 子页的 initState（连带网络请求）都跑掉。
  registerLazyChildHost('TabBarView');
''';
