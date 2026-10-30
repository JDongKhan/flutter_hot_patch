// GlobalKey.currentState 的 JS 侧承载（随 flutter.js 发布，属 Dart 值类区的最前置）。
//
// 为什么在 flutter.js 而不是 runtime：它是「Dart / Flutter 对象在 JS 侧的代表」，
// 与 ControllerBase / GlobalKey 同一层；runtime.js 只做运行环境与 mini-react 核心，
// 不认识任何 Dart 对象。依赖方向仍单向（flutter.js → runtime.js，用 `G.__core`）。
//
// 必须排在**同文件靠后**的 State 代理类之前（`export class AnimatedListState
// extends StateHandle`，模块求值期即需要该类已初始化），因此由 package 模块在
// 结点辅助区之后、包装类之前写出。
//
// State 是宿主对象，JS 侧只持有句柄：方法按名转发到宿主（`__state.<op>`）。
// 运行时**不认识任何业务方法**（`insertItem` / `removeItem` 属于具体组件）：
// 每个 State 类型的代理类随该组件发在 flutter.js 里，加载时用
// `registerStateProxy(type, class)` 登记；类型来自 **GlobalKey<T> 的泛型实参**，
// 随产物下发，不靠 runtimeType 猜。没有代理类时退化为通用 StateHandle。
const String stateHandleJsSource = r'''
  export class StateHandle {
    constructor(id, type) {
      this.__key = id;
      this.__type = type || null;
    }
    // 类型随每次调用下发（来自 GlobalKey 的泛型实参）：宿主据此分派到
    // `Type.method`，不同组件的同名方法互不覆盖。
    __op(op, payload) {
      if (this.__key == null) { return null; }
      var p = payload || {};
      if (this.__type) { p.type = this.__type; }
      return handleOp(this.__key, '__state.' + op, p);
    }
  }

  var __stateProxies = {};

  export function registerStateProxy(type, cls) {
    __stateProxies[type] = cls;
  }

  export function stateProxyOf(id, type) {
    var cls = type ? __stateProxies[type] : null;
    return cls ? new cls(id, type) : new StateHandle(id, type);
  }
''';
