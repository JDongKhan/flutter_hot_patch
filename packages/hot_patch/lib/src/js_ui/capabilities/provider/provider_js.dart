// provider 包｜JS 侧「作用域声明」片段（能力内聚，见 capabilities/ 设计规范）。
//
// 核心（mini-react【7】）只提供**通用的**「按类型名查作用域」机制
// （`registerScope` / `applyScope` / `scopeOf`），不含任何 provider 知识。
// 本片段把 provider 包**自己的**知识注册进去：
//   「ChangeNotifierProvider 宿主结点通过 props.model / props.notifier 对外提供
//     一个类型键控的作用域」。
// 于是 `context.watch<T>()` 全程只认类型名 T，与 T 是不是 ChangeNotifier 无关
// —— 对齐 Dart 的 `dependOnInheritedWidgetOfExactType<T>()`。将来引入别的
// 作用域族（其他三方库的 Provide 类）只需再 `registerScope` 一个类型，
// 核心与查表逻辑零改动，多族共存、同名就近遮蔽天然成立。
//
// props 键名与生成器产出的 JS provider 组件**一字不差**（见
// widget_module_builder 的 jsChangeNotifierProviderComponent：
// `__h('ChangeNotifierProvider', { model: this.props.model, notifier: this.__value }, …)`）。
// 本片段属**运行时注入代码**，改动随 App 编译，热更/热重启不生效。
//
// **依赖顺序**：本片段在 build_context 片段（JsBuildContext 定义处）之后注入，
// 故可安全给 `JsBuildContext.prototype` 补方法。
const String providerJsSource = r'''
  // ===== 【10.8】provider 包｜作用域声明 + context 扩展 =================
  // model   = 类型名（生成器在翻译期写入，源自 `ChangeNotifierProvider<T>` 的 T）；
  // notifier = JS 侧 provider 组件 build 时创建/复用的实例（活对象）。
  registerScope('ChangeNotifierProvider', function (props) {
    if (!props || props.model == null) { return null; }
    var out = {};
    out[props.model] = props.notifier;
    return out;
  });

  // ---- extension BuildContextX on BuildContext ----
  // 对齐 Dart：`context.watch<T>()` / `context.read<T>()` 是 **provider 的**
  // extension，不是 BuildContext 的框架 API。故方法补丁归本库，核心的
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
