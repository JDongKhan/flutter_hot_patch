// 由 runtime_source.dart 拆出的 TabController JS 片段（能力内聚，见 capabilities/ 设计规范）。
// runtime_source 把骨架与各能力片段拼接后注入（同一 IIFE 作用域，片段间靠函数提升互调）。
const String tabControllerJsSource = r'''
  // ===== 【10.7】TabController 代理类（对应 Flutter 官方 TabController）===
  // 生成器把 Dart 侧 `late final TabController _c = TabController(length: 3, vsync: this)`
  // 翻译成 `this._c = new TabController({length: 3, vsync: this})`（vsync 由本代理
  // 类忽略），实例与宿主侧真实 TabController 按**句柄 id** 绑定。
  // 三件套基座（__listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由通用
  // 工厂 defineController 提供（见【1c】）；本类只写差异：
  //   - length/__index：本地镜像（宿主回传 index 更新）；真实实例由宿主在渲染
  //     TabBar / TabBarView 时按 id 取/建（length 随句柄下发，见 extraJSON）；
  //   - index setter：立即设置宿主 index 并通知监听者；
  //   - animateTo(i)：宿主 controller.animateTo（带动画）。
  var TabController = defineController('ctrl/Tab', {
    init: function (opts) {
      opts = opts || {};
      this.length = (typeof opts.length === 'number') ? opts.length : 0;
      this.__index = (typeof opts.initialIndex === 'number') ? opts.initialIndex : 0;
    },
    // 宿主回传（用户点 tab / animateTo 动画结束）→ 更新镜像 + 触发 listeners。
    // 值没变就不是状态变化，不能通知：宿主 attach 时会回传一次初始 index，
    // 若照常 notify，会让监听者（如外壳的 setState）做一次“原地刷新”，
    // 把已挂载子组件无谓地推进 didUpdateWidget → build。
    onHost: function (self, i) {
      if (typeof i !== 'number' || self.__index === i) { return; }
      self.__index = i;
      self.__notify();
    },
    // 跨桥序列化：`{__handle: id, length, initialIndex}`——宿主据此取/建真实
    // controller（见 capabilities/tab/tab_bridge.dart）。
    extraJSON: function (self) {
      return { length: self.length, initialIndex: self.__index };
    },
  });
  TabController.prototype.animateTo = function (index) {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'animateTo', args: [index] }); }
  };
  Object.defineProperty(TabController.prototype, 'index', {
    get: function () { return this.__index; },
    set: function (v) {
      v = (typeof v === 'number') ? v : 0;
      // 同值：镜像没变化 → 不再下发宿主 op、也不再通知（避免一次假刷新）。
      if (this.__index === v) { return; }
      this.__index = v;
      if (this.__id != null) { handleOp(this.__id, 'set', { name: 'index', value: v }); }
      // 与 Dart 语义一致：直接设置 index 立即通知监听者（宿主回传同一值时
      // 会被 onHost 的同值判等吞掉，不会重复通知）。
      this.__notify();
    }
  });
  G.TabController = TabController;

  // TabBarView 是**懒容器**（子页被 SliverFillViewport 强制成整屏，零尺寸占位
  // 布局中性）——不在运行时声明：由生成器配置 lazyChildHostTypes 在 __h 里给
  // 元素打 `lazyChildren` 标记（见 hot_patch_generator 的 shared/js_widget_defs.dart）。
''';
