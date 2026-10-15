/// hot_patch —— Flutter 热更新运行时包。
///
/// 面向「线上出 bug → 运行时切换到 JS 补丁修复」的场景：
/// 构建期由 hot_patch_generator 把带注解的正常 widget 静态翻译成
/// 同名 `.js`（与 dart 源文件对应），运行时用 [JsUiWidget]
/// 加载 JS 补丁渲染组件、由 JS 驱动逻辑。
///
/// 渲染入口是 [JsUiWidget]（宿主）+ JS 侧 `__jsui` 运行时（element /
/// component / reconciler / context / commit 协议）；**每一项能力**——无论
/// Flutter 等价物（Key / 各 Controller / BuildContext 代理 /
/// NotificationListener）还是三方状态库（provider / GetX / …）——都通过
/// [JsUiLibrary] 子类接入；宿主只做「JS 结点 → Flutter widget」映射
/// （[JsWidgetRegistry]）+ 增量补丁应用（[JsUiStore]）。
///
/// **接入一个新能力**：继承 [JsUiLibrary] 重写需要的钩子，再
/// `registerJsUiLibrary(...)`（内建能力见 capabilities/js_ui_library.dart 的
/// `_seedBuiltins`；也可在 App 的 `main()` 里注册，从而完全不改本包）。
/// 宿主核心文件零改动。
///
/// JS→原生能力统一走「宿主方法」：JS 侧唯一出口 `_app_host_.invoke`，宿主侧唯一
/// 入口 [JsRuntimeManager.registerHostMethod]（业务方法用 @HostInjected 注解
/// 由生成器注册，框架内建通道由 JsUiWidget 启动时注册），核心类零改动。
library;

export 'src/services/js_runtime_manager.dart';
export 'src/js_ui/js_ui_widget.dart';
export 'src/js_ui/js_widget_registry.dart';