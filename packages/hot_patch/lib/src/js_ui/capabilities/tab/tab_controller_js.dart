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
    onHost: function (self, i) {
      if (typeof i !== 'number') { return; }
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
      this.__index = (typeof v === 'number') ? v : 0;
      if (this.__id != null) { handleOp(this.__id, 'set', { name: 'index', value: this.__index }); }
      // 与 Dart 语义一致：直接设置 index 立即通知监听者（宿主回传会再通知一次，
      // 幂等，setState 重复触发无副作用）。
      this.__notify();
    }
  });
  G.TabController = TabController;

  // TabBarView 是**懒容器**（子页被 SliverFillViewport 强制成整屏，零尺寸占位
  // 布局中性）——名单不在这里声明，见 capabilities/tab/tab_library.dart 的
  // lazyChildHostTypes（Dart 侧声明 → 随运行时骨架一起注入 registerLazyChildHost）。
''';
