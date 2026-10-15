// provider 包｜JS 侧「作用域声明」片段（能力内聚，见 capabilities/ 设计规范）。
//
// 核心（mini-react【7】）只提供**通用的**「按类型名查作用域」机制
// （`registerScope` / `applyScope` / `scopeOf`），不含任何 provider 知识。
// 本片段把 provider 包**自己的**知识注册进去：
//   「ChangeNotifierProvider 宿主结点通过 props.model / props.vm 对外提供一个
//     类型键控的作用域」。
// 于是 `context.watch<T>()` 全程只认类型名 T，与 T 是不是 ChangeNotifier 无关
// —— 对齐 Dart 的 `dependOnInheritedWidgetOfExactType<T>()`。将来引入别的
// 作用域族（其他三方库的 Provide 类）只需再 `registerScope` 一个类型，
// 核心与查表逻辑零改动，多族共存、同名就近遮蔽天然成立。
//
// props 键名与生成器产出的 JS provider 组件**一字不差**（见
// widget_module_builder 的 jsChangeNotifierProviderComponent：
// `__h('ChangeNotifierProvider', { model: this.props.model, vm: this.__value }, …)`）。
// 本片段属**运行时注入代码**，改动随 App 编译，热更/热重启不生效。
const String providerJsSource = r'''
  // ===== 【10.8】provider 包｜作用域声明（props → __provides）===========
  // model = 类型名（生成器在翻译期写入，源自 `ChangeNotifierProvider<T>` 的 T）；
  // vm    = JS 侧 provider 组件 build 时创建/复用的实例（活对象）。
  registerScope('ChangeNotifierProvider', function (props) {
    if (!props || props.model == null) { return null; }
    var out = {};
    out[props.model] = props.vm;
    return out;
  });
''';
