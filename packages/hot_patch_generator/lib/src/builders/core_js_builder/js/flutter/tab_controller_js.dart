// TabController 的 JS 片段（随 flutter.js 发布）。
//
// 生成器把 Dart 侧 `late final TabController _c = TabController(length: 3, vsync: this)`
// 翻译成 `this._c = new TabController({length: 3, vsync: this})`（vsync 由本代理
// 类忽略），实例与宿主侧真实 TabController 按**句柄 id** 绑定。
// 句柄层（listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由 flutter.js 的
// `JsHandleObject` 提供（见 object_handle_js.dart）；本类只写差异：
//   - length/__index：本地镜像（宿主回传 index 更新）；真实实例在句柄 create
//     阶段就由宿主创建（length/initialIndex 走 meta）；渲染 TabBar / TabBarView
//     时按 id 取**同一个**实例；跨桥序列化只有 `{__handle: id}`。
//   - index setter：立即设置宿主 index 并通知监听者；
//   - animateTo(i)：宿主 controller.animateTo（带动画）。
const String tabControllerJsSource = r'''
  export class TabController extends JsHandleObject {
    constructor(opts) {
      super();
      opts = opts || {};
      this.length = (typeof opts.length === 'number') ? opts.length : 0;
      this.__index = (typeof opts.initialIndex === 'number') ? opts.initialIndex : 0;
      this.__bindHandle('ctrl/Tab', {
        // 构造参数随句柄 create 下发：宿主在 onCreate 阶段就能建出真实
        // TabController（length/initialIndex 此时已确定），构造后立即
        // `index =` / `animateTo()` 不会再因「controller 尚未创建」被丢弃。
        meta: function (self) {
          return { length: self.length, initialIndex: self.__index };
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
      });
    }
    get index() { return this.__index; }
    set index(v) {
      v = (typeof v === 'number') ? v : 0;
      // 同值：镜像没变化 → 不再下发宿主 op、也不再通知（避免一次假刷新）。
      if (this.__index === v) { return; }
      this.__index = v;
      if (this.__id != null) { __handleOp(this.__id, 'set', { name: 'index', value: v }); }
      // 与 Dart 语义一致：直接设置 index 立即通知监听者（宿主回传同一值时
      // 会被 onHost 的同值判等吞掉，不会重复通知）。
      this.__notify();
    }
    animateTo(index) {
      if (this.__id != null) { __handleOp(this.__id, 'call', { method: 'animateTo', args: [index] }); }
    }
  }

  // TabBarView 是**懒容器**（子页被 SliverFillViewport 强制成整屏，零尺寸占位
  // 布局中性）——不在运行时声明：由生成器配置 lazyChildHostTypes 生成包装类的
  // `static __lazy` / `Component.host` 的 lazyRule，构造期打 `lazyChildren` 标记（见 shared/js_class_defs.dart）。
''';
