/// hot_patch —— Flutter 热更新运行时包。
///
/// 面向「线上出 bug → 运行时切换到 JS 补丁修复」的场景：
/// 构建期由 ui_component_generator 把带注解的正常 widget 静态翻译成
/// `.component.js` + `.component.schema.json`，运行时用 [HotPatchWidget]
/// 加载 JS 补丁渲染组件、由 JS 驱动逻辑。
///
/// 渲染走策略注册表（[WidgetRendererRegistry]）：
/// 支持更多/自定义 widget = 实现 [WidgetRenderer] 并注册，核心类零改动。
///
/// JS→原生能力走服务注册表（[NativeServiceRegistry]）：
/// 支持各种原生服务 = 实现 [NativeService] 并注入，核心类零改动。
library;

export 'src/builtin_renderers.dart';
export 'src/builtin_services.dart';
export 'src/hot_patch_widget.dart';
export 'src/native_service.dart';
export 'src/widget_renderer.dart';
