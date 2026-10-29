// ---------------------------------------------------------------------------
// State 句柄（GlobalKey.currentState 的承载）
//
// 属于**运行时核心**而非 Dart 值类：它是「宿主 State 对象在 JS 侧的代表」，
// 与 reconciler 的 stateProxy 注册表配套，产物里的 State 代理类直接
// `extends __StateHandle`（模块加载时求值，因此必须早于任何产物模块）。
//
// 值类区（flutter.js）里的 GlobalKey 只在运行期通过 `G.__StateHandle` 取用，
// 不依赖本片段的词法作用域。
// ---------------------------------------------------------------------------

const String stateHandleJsSource = r'''
  // GlobalKey.currentState：State 是宿主对象，JS 侧只保留**句柄**。
  //
  // 运行时**不认识任何业务方法**（`insertItem` / `removeItem` 这类签名属于具体
  // 组件）：每个 State 类型的代理类由生成器随该组件一起写进 flutter.js，并在
  // 加载时用 `__registerStateProxy(type, class)` 登记；类型来自 **GlobalKey<T> 的
  // 泛型实参**，随产物下发，不靠 runtimeType 猜。没有代理类时退化为通用句柄。
  function StateHandle(id, type) { this.__key = id; this.__type = type || null; }
  StateHandle.prototype.__op = function (op, payload) {
    if (this.__key == null) { return null; }
    var p = payload || {};
    // 类型随每次调用下发（来自 GenericKey 的泛型实参）：宿主据此分派到
    // `Type.method`，不同组件的同名方法互不覆盖。
    if (this.__type) { p.type = this.__type; }
    return handleOp(this.__key, '__state.' + op, p);
  };
  var __stateProxies = {};
  function __registerStateProxy(type, cls) { __stateProxies[type] = cls; }
  function __stateProxyOf(id, type) {
    var cls = type ? __stateProxies[type] : null;
    return cls ? new cls(id, type) : new StateHandle(id, type);
  }
  G.__registerStateProxy = __registerStateProxy;
  G.__StateHandle = StateHandle;
  G.__stateProxyOf = __stateProxyOf;
''';
