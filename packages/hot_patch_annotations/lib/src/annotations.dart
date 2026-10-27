/// 标记一个类为可动态下发的 UI 组件（正常 Flutter widget）。
///
/// 生成器（hot_patch_generator）据此把该组件翻译为同名的 JS 模块：
///   - [name]：组件名，**可省略**；不传时即**类名**（JS 类名与 Dart 类名
///     始终一致，客户端通过 `JsUiWidget` 的 jsAsset query
///     `?component=类名` 实例化 JS 版本）
///
/// 热更是**基于整个 widget** 的，不做字段/方法级标注：
/// 生成器默认全量收集——
///   所有非 static 字段 → JS 状态 __state（_count → count）
///   所有方法（除 build/生命周期）→ JS 事件方法（构建期以 this.__bindFn 绑定）
///   build()           → JS 渲染入口（原封不动翻译为 build 函数）
///   SnackBar 形式的方法 → 自动识别为 native 通道（_app_host_.invoke）
///
/// 注解只是构建期元数据，不影响组件正常运行：
/// 线上出 bug 时，运行时切换到 JsUiWidget 加载 JS 版本即可热修复，无需发版。
class PatchEntry {
  /// 组件名；null 表示取类名（`@PatchEntry()` 与 `@PatchEntry(类名)` 等价）。
  final String? name;

  const PatchEntry([this.name]);
}

/// 标记一个组件「不参与连带转换」。
///
/// 默认情况下，@PatchEntry 组件的 build 里用到的本文件私有组件
/// （如 `_MyCustomCard`）或无注解公共组件，会被生成器**连带翻译**成
/// JS 类注册进同一产物。标上本注解后：
///   - 生成器跳过该组件（不生成该类的翻译产物、不注册）；
///   - build 树里引用它的位置仍按 Dart 一比一翻译成 `new 类型名({...})`，
///     `isComponent: true` 时由**声明它的源文件产物**里的同名包装类承接，运行时
///     由业务方在 `main()` 里注册的原生实现渲染（`registerNativeComponent`）。
///
/// 适用场景：某组件逻辑复杂/含原生依赖、不适合翻译成 JS，希望线上
/// 热更时始终使用原生实现；或临时下线某个嵌套组件的 JS 版本。
///
/// [isComponent] 决定使用方怎么翻译：
///   - `true`：不翻译该类，但在声明它的源文件产物里生成同名**包装类**
///     （`constructor(props) { return __h('类名', props); }`），使用方仍按 Dart
///     一比一翻译成 `new 类名({...})`，宿主按 `registerNativeComponent` 注册的
///     原生实现渲染；
///   - `false`（默认）：整类忽略——不翻译、不生成任何类，使用方引用它的结点
///     直接丢弃（构建期告警）。
///
/// 注解只是构建期元数据，不影响组件正常运行。
class PatchIgnore {
  /// 是否为「组件」：true → 生成同名包装类，使用方 `new X(...)`。
  final bool isComponent;

  const PatchIgnore({this.isComponent = false});
}

/// 标记一个 **static 方法 / 顶层函数**为「宿主注入」（Host Injected）能力。
///
/// 这类方法的实现留在 Dart 侧（可访问缓存、网络、原生能力等），**不翻译成
/// JS、不产出任何 JS 产物**；当 @PatchEntry 组件的方法体（或模型方法体）里
/// 调用到被标注的 static 方法时，生成器只把**调用点**替换为宿主编排的调用：
///
///   AccountCenter.getUserName(a, b)
///     →  _app_host_.invoke("getUserName", [a, b])            // Promise，可 await
///   Network.post(params: m)
///     →  _app_host_.invoke("post", {"params": m})
///
/// [name] 为消息通道名；缺省（不传）时取方法名本身。
/// 参数载荷按实参形态给：纯位置→数组、纯具名→对象、混合→对象 + `"@args"`
/// 键装位置实参。载荷经单桥通道以 `{id, args}` 交回宿主，宿主用
/// `JsRuntimeManager.registerHostMethod(channel, fn)` 接回调（宿主按
/// `Function.apply(fn, 位置实参, 具名实参)` 还原 Dart 调用语义，故位置/具名
/// 实参个数不限、未传参数走默认值），fn 完成后返回值被 resolve 回 JS 的 Promise。
///
/// 注解只是构建期元数据，不影响方法正常运行。
class HostInjected {
  /// 消息通道名；缺省（null）时用方法名。
  final String? name;
  const HostInjected([this.name]);
}
