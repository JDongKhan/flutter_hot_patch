// provider 包｜`patch/provider.js` 的**库自有片段**（追加在该 package 模块尾部）。
//
// 为什么在这里：`patch/provider.js` 是 provider 这个 **package 的模块**（内含
// `ChangeNotifierProvider` / `Consumer` / `MultiProvider` 的 JS 类，见
// `js_class_defs.dart` 的 `widgetPackages`）。provider 对运行时提出的额外要求
// （作用域声明 + `extension BuildContextX` 的 watch/read）属于**这个包自己的
// 知识**，因此跟它的类放在同一个模块里，模块求值即生效。
//
// 与 runtime.js 的分工：
//   - runtime.js（mini-react 核心）只提供**通用的**作用域机制
//     （`registerScope` / `scopeOf` / `subscribeListenable`）与 BuildContext
//     代理，不含任何 provider 知识；
//   - 本片段把 provider 包**自己的**知识注册进去：
//     「ChangeNotifierProvider 宿主结点通过 props.model / props.notifier 对外
//       提供一个类型键控的作用域」+ `context.watch/read`。
//
// 于是 `context.watch<T>()` 全程只认类型名 T，与 T 是不是 ChangeNotifier 无关
// —— 对齐 Dart 的 `dependOnInheritedWidgetOfExactType<T>()`。将来引入别的
// 作用域族（其他三方库的 Provide 类）只需在**各自的 package 模块**里再
// `registerScope` 一个类型，核心与查表逻辑零改动，多族共存、同名就近遮蔽天然成立。
//
// props 键名与同模块 JS 类一字不差（见 widget_module_builder 的
// jsChangeNotifierProviderComponent：
// `__h('ChangeNotifierProvider', { model: this.props.model, notifier: this.__value }, …)`）。
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
  var registerScope = __core.registerScope;
  var scopeOf = __core.scopeOf;
  var subscribeListenable = __core.subscribeListenable;
  var JsBuildContext = __core.JsBuildContext;

  // model    = 类型名（生成器在翻译期写入，源自 `ChangeNotifierProvider<T>` 的 T）；
  // notifier = JS 侧 provider 组件 build 时创建/复用的实例（活对象）。
  registerScope('ChangeNotifierProvider', function (props) {
    if (!props || props.model == null) { return null; }
    var out = {};
    out[props.model] = props.notifier;
    return out;
  });

  // ---- extension BuildContextX on BuildContext ----
  // 对齐 Dart：`context.watch<T>()` / `context.read<T>()` 是 **provider 的**
  // extension，不是 BuildContext 的框架 API。故方法补丁归本模块，核心的
  // build_context 片段只提供代理与通用 op 转发（见其文件头）。
  //
  // 取值同步（渲染期 `model.count` 要直接读，而 JS→宿主只有异步桥）⇒ 值在本端
  // 按**类型名**沿 `__parent` 取最近作用域（核心通用机制 `scopeOf`，只认类型名，
  // 不关心 T 是模型还是别的）；值是否可订阅由 `subscribeListenable` 鸭子判型。
  // 「订阅谁」这半是库相关的，交宿主：op 经 `__host` 下发到真实 BuildContext，
  // 由 provider/context_ops.dart 解析成模型镜像并建立依赖。

  // `context.watch<T>()`：取最近提供 [type] 的值并订阅（notify 时只重建调用
  // watch 的那个位置）。
  JsBuildContext.prototype.watch = function (type) {
    var value = scopeOf(this.__anchor, type);
    // 把本端查找结果一并告知宿主：宿主据此区分「消费点在 provider 子树之外」
    // （真错误，宿主会告警）与「宿主侧本就没有该作用域的镜像」（正常，静默）。
    this.__host('watch', { type: type, found: value != null });
    if (value == null) { return undefined; }
    subscribeListenable(this.__anchor, value);
    return value;
  };

  // `context.read<T>()`：仅取实例，不订阅（按钮回调里的合法用法）。
  JsBuildContext.prototype.read = function (type) {
    var value = scopeOf(this.__anchor, type);
    this.__host('read', { type: type, found: value != null });
    return value == null ? undefined : value;
  };
''';
