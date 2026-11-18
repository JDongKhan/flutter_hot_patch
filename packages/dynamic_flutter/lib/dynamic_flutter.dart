/// dynamic_flutter —— Flutter 热更新运行时包。
///
/// 面向「线上出 bug → 运行时切换到 JS 补丁修复」的场景：
/// 构建期由 dynamic_flutter_generator 把带注解的正常 widget 静态翻译成
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
/// **接入一个新能力**：继承 [JsUiLibrary] 重写需要的钩子，把实例放进 App
/// `main()` 里的 [initJsUi] `libraries` 清单（内建能力见
/// capabilities/js_ui_library.dart 的 `_seedBuiltins`）——一次调用即完成
/// 「注册 + 通道就位 + 宿主组件建表」，本包与 App 核心文件都零改动。
/// [initJsUi] 是**必须由 App 调用**的启动前置：`JsUiWidget` 不再自动装配，
/// 漏调会在 debug 断言失败 / release 记 error；`@HostInjected` 的生成清单
/// （生成文件的 `hostMethods`）作为 `hostMethods` 参数一次交给它，无需再逐个
/// `registerHostMethod`。
///
/// JS→原生能力统一走「宿主方法」：JS 侧唯一出口 `_app_host_.invoke`，宿主侧唯一
/// 入口 [JsRuntimeManager.registerHostMethod]（业务方法用 @HostInjected 注解生成
/// `hostMethods` 清单、随 [initJsUi] 一起注册，框架内建通道由 [initJsUi] 注册），
/// 核心类零改动。
library;

export 'src/services/js_runtime_manager.dart';
export 'src/utils/env_flags.dart';
export 'src/utils/dynamic_flutter_assets.dart';
export 'src/utils/dynamic_flutter_log.dart';
export 'src/js_ui/capabilities/dialog/dialog_api.dart';
export 'src/js_ui/js_ui_widget.dart';
export 'src/js_ui/js_widget_registry.dart';
// 全局宿主 widget 注册表：外部自定义组件（含保留具体类型名的纯原生结点）
// 在 main() 里 `jsWidgetRegistry.register(type, build)` 即可，与内建能力同表。
export 'src/js_ui/capabilities/js_ui_capabilities.dart' show jsWidgetRegistry;
// UI 能力装配唯一入口：`initJsUi(libraries: [...], hostMethods: [...])` 一次完成
// 「注册能力 + 通道就位 + 宿主组件建表 + 内建与业务宿主方法」。**必须**在 main() 里
// runApp 之前调用（JsUiWidget 只校验、不代劳）；`assertJsUiInitialized()` 供自定义
// 入口校验契约。
export 'src/js_ui/capabilities/js_ui_bootstrap.dart'
    show initJsUi, jsUiInitialized, assertJsUiInitialized;
export 'src/js_ui/capabilities/js_ui_library.dart';
// 自定义能力（App 侧实现，如三方包的 Controller 句柄桥、自定义实例对象绑定）
// 需要的通用构件：句柄桥基类 + 「按成员名分派」契约（类实现 JsHandleMembers 后，
// 桥的 onOp 直接传 dispatchJsMember，不必为每个类再写 switch）。
export 'src/js_ui/capabilities/core/object_bridge.dart'
    show JsObjectBridge, JsHandleMembers, dispatchJsMember;
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
// 可选能力开关（**默认关闭**）：Ticker 跟随渲染位置的 TickerMode 暂停 / 续跑。
// 启用时在 `main()`（runApp 之前、任何 JS 控制器构造之前）写
// `jsTickerModeBindingEnabled = true;`；关闭态为「裸 Ticker 不静音」（现状）。
export 'src/js_ui/capabilities/core/ticker_mode_binding.dart'
    show jsTickerModeBindingEnabled;
