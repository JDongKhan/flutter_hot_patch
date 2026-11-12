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
export 'src/utils/env_flags.dart';
export 'src/utils/hot_patch_assets.dart';
export 'src/utils/hot_patch_log.dart';
export 'src/js_ui/capabilities/dialog/dialog_api.dart';
export 'src/js_ui/js_ui_widget.dart';
export 'src/js_ui/js_widget_registry.dart';
// 全局宿主 widget 注册表：外部自定义组件（含保留具体类型名的纯原生结点）
// 在 main() 里 `widgetRegistry.register(type, build)` 即可，与内建能力同表。
export 'src/js_ui/capabilities/js_ui_capabilities.dart' show widgetRegistry;
export 'src/js_ui/capabilities/js_ui_library.dart';
// 自定义能力（App 侧实现，如三方包的 Controller 句柄桥）需要的通用构件：
// 句柄桥基类。
export 'src/js_ui/capabilities/core/controller_bridge.dart'
    show JsControllerBridge;
// 宿主 JSON 还原：外部自定义 register 时直接按键从 `JsRenderContext` 取值，
// 例如 `c.color('color')` / `c.textStyle('style')` / `c.edgeInsets('padding')`，
// 不必再 import 各 from_json 实现文件。
//
// 原始 `*FromJson` 函数是扩展方法的实现层，同时供无渲染上下文路径（Controller
// 实参、弹层 options、绘制指令等）复用；这里只额外导出外部已有的
// `curveFromJson` / `durationFromJson`。
export 'src/js_ui/capabilities/core/from_json/dart_values_from_json.dart'
    show JsRenderContextDartValues, durationFromJson;
export 'src/js_ui/capabilities/core/from_json/layout_from_json.dart'
    show JsRenderContextLayout;
export 'src/js_ui/capabilities/core/from_json/painting_from_json.dart'
    show JsRenderContextPainting;
export 'src/js_ui/capabilities/core/from_json/widget_enum_from_json.dart'
    show JsRenderContextWidgetEnums;
export 'src/js_ui/capabilities/base_widget/text_from_json.dart'
    show JsRenderContextText;
export 'src/js_ui/capabilities/base_widget/icon_from_json.dart'
    show JsRenderContextIcon;
export 'src/js_ui/capabilities/base_widget/button_from_json.dart'
    show JsRenderContextButtonStyle;
export 'src/js_ui/capabilities/canvas/canvas_from_json.dart'
    show JsRenderContextCanvas;
export 'src/js_ui/capabilities/animation/animation_from_json.dart'
    show JsRenderContextAnimation, curveFromJson;
export 'src/js_ui/capabilities/tab/tab_from_json.dart'
    show JsRenderContextTab;
