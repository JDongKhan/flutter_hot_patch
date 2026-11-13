// ===== 宿主能力聚合入口 =====
//
// js_ui_widget 只依赖本文件两个函数 + 一个注册表单例访问器。**本文件是「能力」
// 与核心的唯一接缝**：除两块地基（通用句柄层、Flutter 基础视觉组件）显式登记外，
// 其余**所有能力**——无论 Flutter 等价物（Key / 各 Controller / BuildContext
// 代理 / NotificationListener）还是三方库（provider / GetX / …）——统一由
// capabilities/js_ui_library.dart 的注册表驱动，机制完全一致。
//
// 因此「新增一个能力」= 建目录 + 写一个 JsUiLibrary 子类 + 在 _seedBuiltins
// 里加一行；**本文件与 runtime_js / js_widget_registry / js_ui_widget
// 从此不再变动**。Flutter 基础视觉组件的宿主映射属框架地基，见
// base_widget/base_widget_bridge.dart。
//
// 目录结构：**一个能力一个目录**，内有宿主侧 `<x>_bridge.dart`（通道 +
// 宿主组件）、JS 侧 `<x>_js.dart`（片段）、接入声明 `<x>_library.dart`。
// 留在本层的只有两样：能力模板 js_ui_library.dart、本聚合入口；地基（句柄
// 注册表的 Dart 侧与 JS 侧两端，刻意不是 JsUiLibrary 子类，理由见其文件头）
// 独立成 core/。
import '../js_widget_registry.dart';
import 'base_widget/base_widget_bridge.dart';
import 'core/handle_registry.dart';
import 'js_ui_library.dart';

/// 全部能力通道（幂等）：在 JS 组件 mount（new XxxController → host 登记）
/// 前调用。由 UI 能力装配入口 `initJsUi(...)`（见 js_ui_bootstrap.dart）调用，
/// 且必须先于 `ensureJsUiRuntime`（runtime.js 里各能力片段的宿主侧登记依赖这里
/// 已注册的 kind / context op）。
///
/// 只由装配入口 [initJsUi] 调用（App `main()` 里、`runApp` 之前）；幂等靠各库
/// 自己的 `ensureChannels`（`_handleChannelsRegistered` 等内建标记）。
void ensureJsUiCapabilities() {
  // 地基：句柄注册表本身，必须先于一切能力就绪。
  ensureHandleChannels();
  // 其余能力（内建 + 三方库）各自内聚，遍历注册表即可。
  for (final library in jsUiLibraries) {
    library.ensureChannels();
  }
}

/// 触发宿主组件注册表建表（幂等：首次访问时一次性注册全部能力组件）。
///
/// 由装配入口 [initJsUi] 显式触发，让首帧渲染不再承担建表工作；之后新增的
/// `registerJsUiLibrary(...)` 因 `jsWidgetRegistryBuilt` 已置位而告警（该库的
/// `registerWidgets` 不会再被回调）。
JsWidgetRegistry ensureJsWidgetRegistry() => jsWidgetRegistry;

/// 全部组件注册 = Flutter 基础组件（核心本体）+ 各能力/三方库的自注册。
void registerAllJsWidgets(JsWidgetRegistry r) {
  // 地基：Text/Column 等基础视觉组件，不属于任何可插拔能力。
  registerBaseWidgets(r);
  for (final library in jsUiLibraries) {
    library.registerWidgets(r);
  }
}

/// 宿主 widget 注册表**进程内单例**：所有 [JsUiWidget] 实例共用同一张
/// `type → Flutter widget` 表，不再按实例重复注册（原实现每个实例都 new 一份
/// 并把近百条 builder 重注册一遍）。
///
/// 安全性：注册表内容只是「类型名 → builder」——builder 均为**无状态纯函数**
/// （只读传入的 `JsRenderContext`，不持有任何实例状态），故进程内共享完全等价。
///
/// **懒建**：首次访问时构建并**一次性**注册全部内建/能力/三方库组件；因此
/// `registerJsUiLibrary(...)` 必须在建表前完成——由装配入口
/// `initJsUi(libraries: [...])`（js_ui_bootstrap.dart）在 `main()` 里
/// `runApp` 之前一次做完（App 必须显式调用，`JsUiWidget` 不代劳）。
/// 建表之后仍可用 `jsWidgetRegistry.register(type, build)` 补单个类型
/// （表可变、查表在渲染时），但新库的 `registerWidgets` 不会再被回调。
final JsWidgetRegistry _jsWidgetRegistry = _createWidgetRegistry();

JsWidgetRegistry _createWidgetRegistry() {
  final registry = JsWidgetRegistry();
  registerAllJsWidgets(registry);
  // 建表完成：此后新增的 JsUiLibrary 拿不到 registerWidgets 回调，注册入口
  // 据此告警（见 js_widget_registry.dart 的 jsWidgetRegistryBuilt）。
  jsWidgetRegistryBuilt = true;
  return registry;
}

/// 全局唯一的宿主 widget 注册表（见 [_jsWidgetRegistry]）。
///
/// 外部自定义组件（含 `@PatchIgnore` / 无注解私有组件保留的具体类型名结点）
/// 只需在 App 的 `main()` 里 `jsWidgetRegistry.register(type, (c) => ...)` 注册，
/// 与内建能力共用同一张表，无需额外的原生组件注入入口。
JsWidgetRegistry get jsWidgetRegistry => _jsWidgetRegistry;
