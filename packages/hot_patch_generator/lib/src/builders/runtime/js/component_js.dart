// ===== Component 基类（随 `patch/flutter.js` 发布）=====
//
// 翻译出来的组件类都 `extends StatelessWidget` / `extends StatefulWidget`，
// 两者继承 Component。`Component` 实例**自身就是元素**：
//
//   - `__element: true` —— reconciler 判定「这是不是元素」的唯一标记；
//   - `__type`          —— 真实子类（`this.constructor`），类型比较 / 日志都用它；
//   - `props`           —— 子类构造参数（Dart 的 Widget 字段来源）。
//
// 因此 `new X(props)` 直接就是元素，不再有「实例 → 元素描述」的折算，
// 也不再靠「原型上有没有 build」猜组件——只需 `__element === true`。
//
// setState / context 也在这里：它们是「Dart 组件语义」的一部分，
// 不属于 mini-react 核心；运行时只通过 `G.__core` 提供标脏、句柄登记与构建
// 锚点三类通用机制。
const String componentJsSource = r'''
  // ===== Component（Dart 组件的基类）=====
  // 依赖方向单向：flutter.js → runtime.js，跨模块只走 G.__core。
  var __cc = G.__core;

  export class Component {
    // 懒容器声明：默认 false；宿主包装类按构建期配置覆盖为 true（无条件懒）
    // 或 props 键数组（带其中任一键时才懒）。运行时只读这个声明，不认识类型。
    static __lazy = false;

    // 宿主 props 里**可能是函数**的键名单（构建期来自源码构造签名）。默认空 =
    // 本类型没有回调，运行时零循环；有回调的类型覆盖成数组，签名不可得时覆盖
    // 成 null（运行时回退全量扫描）。静态继承让「无回调」不必逐个类写空数组。
    static __fnProps = [];

    // 把宿主元素的 props 按统一协议拆成 data / `__children`：widget 实参、widget
    // 数组、`__builder`、delegate 归子槽，其余归 props。**在元素构造期完成**，
    // reconciler 直接消费结果，不在 mount/patch 里做业务拆分。
    static __splitHost(el, lazyRule) {
      var p = el.props || {};
      var data = {}, slots = {};
      for (var k in p) {
        if (!Object.prototype.hasOwnProperty.call(p, k)) { continue; }
        var v = p[k];
        if (__cc.__isElement(v) || __cc.__isElementList(v) ||
            (k === '__builder' && v != null && typeof v === 'object') ||
            (v != null && typeof v === 'object' && v.__delegate)) {
          slots[k] = v;
        } else {
          data[k] = v;
        }
      }
      el.__children = slots;
      el.props = data;
      if (lazyRule === true) {
        el.lazyChildren = true;
      } else if (Array.isArray(lazyRule)) {
        for (var i = 0; i < lazyRule.length; i++) {
          if (p[lazyRule[i]] !== undefined) { el.lazyChildren = true; break; }
        }
      }
      return el;
    }

    // 按**宿主类型名**产出宿主元素（逻辑组件内部用：`ChangeNotifierProvider` /
    // `Stack` 这类宿主结点）。props 在构造期按统一协议拆好；懒标记由调用方给出
    // （builder 代理按构建期配置传入）。
    static host(type, props, lazy) {
      var el = Component.__splitHost(
        { __type: type, props: props || {}, __element: true }, lazy);
      el.__anchor = __cc.anchor || null;
      return el;
    }

    constructor(args) {
      this.props = args || {};
      // 实例即元素：reconciler 只认 `__element` 标记，不做任何类型猜测。
      this.__element = true;
      // 真实子类。**`__type` 是运行时保留名**：Dart 里业务字段常叫 `type`
      //（`_ListContent(type: '全部')`），只有双下划线名才不会被业务字段覆盖。
      this.__type = this.constructor;
      // 构建锚点：本元素由哪个组件实例的 build 产出。宿主 props 里的函数值在
      // 下发边界被换成句柄（见 mini_react 的 __hostProps），回调执行时据此还原
      // `this.context` / 构造期句柄归属，语义与「编译期就绑定」完全一致。
      this.__anchor = __cc.anchor || null;
      // 宿主包装类（自身原型**没有重写 build**）在构造期就拆好 props/children；
      // 逻辑组件 / 翻译组件保留原样 props（它们自己消费构造参数）。
      if (!Object.prototype.hasOwnProperty.call(this.constructor.prototype, 'build')) {
        Component.__splitHost(this, this.constructor.__lazy);
      }
    }

    setState(mutate) {
      if (typeof mutate === 'function') { mutate.call(this); }
      __cc.__markDirty(this);
    }

    // 复制 props 并摘除**不能跨语言**的键（回调闭包 / 内联 builder）：JS 侧自己
    // 消费它们，宿主只接收可序列化的数据。逻辑组件统一走这一处，不再各写一遍循环。
    __propsExcept(skip) {
      var out = {};
      for (var k in this.props) {
        if (!Object.prototype.hasOwnProperty.call(this.props, k)) { continue; }
        if (skip.indexOf(k) >= 0) { continue; }
        out[k] = this.props[k];
      }
      return out;
    }

    // 与 Dart 一致：`context` 既是 build 形参、也是实例上可访问的同一对象。
    // **按执行位置解析**：委托型组件（Builder / Consumer）把 builder 方法以
    // owner 为 this 调用时，锚点仍是当前构建位置。
    get context() { return __cc.__contextOf(__cc.building || this); }

    // Dart `State` 生命周期的同名空实现：产物里 `super.initState()` /
    // `super.didChangeDependencies()` 等一比一翻译后仍可正常调用
    // （Flutter 原生基类的这些实现本身就是空操作）。
    initState() {}
    didChangeDependencies() {}
    didUpdateWidget(oldWidget) {}
    activate() {}
    deactivate() {}
    dispose() {}

    // 空 build：Dart 里 `State.build` 是抽象方法，但 SDK mixin
    // （AutomaticKeepAliveClientMixin 等）会在自己的 build 里调用 `super.build`。
    // 这些 SDK mixin 不参与翻译，产物中的 `super.build(context)` 因此落到这里。
    // 真正缺少 build 的组件会由 pull 阶段报「组件 build 未产出任何结点」（不静默）。
    build(context) {}
  }

  // Flutter 的两个 Widget 基类：只作为翻译产物的 `extends` 落点。
  // 本模型里 widget 与 state 合并为一个实例，二者不携带额外语义。
  export class StatelessWidget extends Component {}
  export class StatefulWidget extends Component {}

  // 订阅型布局组件（ListenableBuilder / ValueListenableBuilder / AnimatedBuilder）
  // 共用的一层「订阅 → 只标脏本结点」机制：绑定一个 Listenable，notify 时只重建
  // 自己的子树（不扩散到父级）；卸载时精确退订。
  class __ListenableSubscriber extends Component {
    constructor(props) {
      super(props);
      this.__listenable = null;
      this.__listener = null;
    }

    // 订阅 [l]；listener 体由子类给（缺省 = 只标脏本结点）。
    __listen(l, body) {
      if (this.__listenable === l && this.__listener) { return; }
      this.__unlisten();
      this.__listenable = l;
      if (!l || typeof l.addListener !== 'function') { return; }
      var self = this;
      this.__listener = body || function () { self.setState(function () {}); };
      l.addListener(this.__listener);
    }

    __unlisten() {
      var l = this.__listenable;
      if (l && this.__listener && typeof l.removeListener === 'function') {
        l.removeListener(this.__listener);
      }
      this.__listenable = null;
      this.__listener = null;
    }

    dispose() { this.__unlisten(); }
  }
''';
