// provider 包｜`patch/provider.js` 的**库自有片段**（追加在该 package 模块尾部）。
//
// 为什么在这里：`patch/provider.js` 是 provider 这个 **package 的模块**（内含
// `ChangeNotifierProvider` / `Consumer` / `MultiProvider` 的 JS 类，见
// `js_class_defs.dart` 的 `widgetPackages`）。provider 对运行时提出的额外要求
// （作用域登记 + `extension BuildContextX` 的 watch/read）属于**这个包自己的
// 知识**，因此跟它的类放在同一个模块里，模块求值即生效。
//
// 与 runtime.js 的分工：
//   - runtime.js（mini-react 核心）只提供**通用的**继承机制
//     （`__inheritedElements` / `__dependents` / `__notifyClients`）与 BuildContext
//     代理，不含任何 provider 知识；
//   - 本片段把 provider 包**自己的**知识接进去：`ChangeNotifierProvider` 把模型
//     实例登记为「按类型名键控的继承结点」（键来自 `props.typeArguments`）；
//     `context.watch/read` 复用 `JsBuildContext` 的继承查找，再读结点的 `value`。
//
// **跨模块只走 G**：核心符号经 `G.__core` 解构，不假设与 runtime 同一作用域。
//
// **加载时机**：任何构造 provider 组件的产物都会 import `patch/provider.js`
// （`widgetPackages` 决定类型归属），模块加载器先加载依赖再求值，故本片段一定
// 早于任何 `context.watch` 调用。
const String providerModuleEpilogue = r'''
  // ── provider 库自有的运行期登记（跟本包的类同一模块，随模块求值生效）──
  var G = typeof globalThis !== 'undefined' ? globalThis : Function('return this')();
  var __core = G.__core;
  var __inheritElement = __core.__inheritElement;
  var __notifyClients = __core.__notifyClients;
  var __typeArgumentOf = __core.__typeArgumentOf;
  var __subscribeListenable = __core.__subscribeListenable;
  var JsBuildContext = __core.JsBuildContext;
  // 告警走核心导出的通用日志入口（debug 生效、release 零开销），不新开通道。
  function __warn(text) { __core.log('warn', text); }

  // 同一个消费位置重复重建时不刷屏：按 (api, 类型名) 只告警一次。
  function __warnMissingScope(anchor, props, api) {
    var type = __typeArgumentOf(props, null);
    if (type == null) { return; } // 缺类型实参已由 JsBuildContext 出声
    var seen = anchor && (anchor.__missingScopeWarned ||
      (anchor.__missingScopeWarned = {}));
    var key = api + '|' + type;
    if (seen && seen[key]) { return; }
    if (seen) { seen[key] = true; }
    __warn('[provider] ' + api + '(' + type + ') 未找到提供者'
      + '（消费点可能不在 provider 子树内）');
  }

  // ---- extension BuildContextX on BuildContext ----
  // 对齐 Dart：`context.watch<T>()` / `context.read<T>()` 是 **provider 的**
  // extension，不是 BuildContext 的框架 API。故方法补丁归本模块。
  //
  // 调用面与构造同形：类型实参并入尾参对象（`context.watch({ typeArguments })`）。
  // **取值必须同步**（渲染期 `model.count` 要直接读，而 JS→宿主只有异步桥），
  // 因此查找走 `JsBuildContext` 的 `getInheritedWidgetOfExactType` /
  // `dependOnInheritedWidgetOfExactType`；provider 作用域结点用 `value` 暴露模型。
  // 值是否可订阅由 `__subscribeListenable` 鸭子判型（原生 ChangeNotifier API）。

  // `context.watch<T>()`：取最近提供 [type] 的作用域并订阅（notify 时只重建
  // 调用 watch 的那个位置；模型实例被 provider 替换时也会收到依赖通知）。
  JsBuildContext.prototype.watch = function (props) {
    var scope = this.dependOnInheritedWidgetOfExactType(props);
    if (scope == null) {
      __warnMissingScope(this.__anchor, props, 'context.watch');
      return undefined;
    }
    var value = scope.value;
    __subscribeListenable(this.__anchor, value, scope);
    return value;
  };

  // `context.read<T>()`：仅取实例，不订阅（按钮回调里的合法用法）。
  JsBuildContext.prototype.read = function (props) {
    var scope = this.getInheritedWidgetOfExactType(props);
    if (scope == null) {
      __warnMissingScope(this.__anchor, props, 'context.read');
      return undefined;
    }
    return scope.value;
  };
''';
