/// hot_patch —— Flutter 热更新运行时包。
///
/// 面向「线上出 bug → 运行时切换到 JS 补丁修复」的场景：
/// 构建期由 ui_component_generator 把带注解的正常 widget 静态翻译成
/// 同名 `.js`（与 dart 源文件对应），运行时用 [JsUiWidget]
/// 加载 JS 补丁渲染组件、由 JS 驱动逻辑。
///
/// 渲染入口是 [JsUiWidget]（宿主）+ JS 侧 `__jsui` 运行时（element /
/// component / reconciler / context / commit 协议）；状态语义（provider /
/// setState 等）全部在 JS 侧实现，宿主只做「JS 结点 → Flutter widget」映射
/// （[JsWidgetRegistry]）+ 增量补丁应用（[JsUiStore]）。
///
/// JS→原生能力走服务注册表（[NativeService] / [JsRuntimeManager]）：
/// 支持各种原生服务 = 实现 [NativeService] 并注入，核心类零改动。
library;

export 'src/services/builtin_services.dart';
export 'src/services/js_runtime_manager.dart';
export 'src/services/native_service.dart';
export 'src/utils/hot_patch_log.dart';
export 'src/json/flutter_from_json.dart';
export 'src/js_ui/js_ui_widget.dart';
export 'src/js_ui/js_ui_store.dart';
export 'src/js_ui/js_widget_registry.dart';