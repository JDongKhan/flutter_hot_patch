// ===== 宿主能力聚合入口 =====
//
// js_ui_widget 只依赖本文件两个函数 + 一个注册表单例访问器。**本文件是「能力」
// 与核心的唯一接缝**：除两块地基（通用句柄层、Flutter 基础视觉组件）显式登记外，
// 其余**所有能力**——无论 Flutter 等价物（Key / 各 Controller / BuildContext
// 代理 / NotificationListener）还是三方库（provider / GetX / …）——统一由
// capabilities/js_ui_library.dart 的注册表驱动，机制完全一致。
//
// 因此「新增一个能力」= 建目录 + 写一个 JsUiLibrary 子类 + 在 _seedBuiltins
// 里加一行；**本文件与 runtime_source / js_widget_registry / js_ui_widget
// 从此不再变动**。
//
// 目录结构：**一个能力一个目录**，内有宿主侧 `<x>_bridge.dart`（通道 +
// 宿主组件）、JS 侧 `<x>_js.dart`（片段）、接入声明 `<x>_library.dart`。
// 留在本层的只有两样：能力模板 js_ui_library.dart、本聚合入口；地基（句柄
// 注册表的 Dart 侧与 JS 侧两端，刻意不是 JsUiLibrary 子类，理由见其文件头）
// 独立成 core/。
import '../js_widget_registry.dart';
import 'core/handle_registry.dart';
import 'js_ui_library.dart';

/// 全部能力通道（幂等）：在 JS 组件 mount（new XxxController → host 登记）
/// 前调用。JsUiWidget 启动时调用一次；顺序上必须先于 ensureJsUiRuntime（见
/// js_runtime_manager.ensureJsUiRuntime），因为 [jsUiRuntimeSource] 要拼各能力片段。
void ensureJsUiCapabilities() {
  // 地基：句柄注册表本身，必须先于一切能力就绪。
  ensureHandleChannels();
  // 其余能力（内建 + 三方库）各自内聚，遍历注册表即可。
  for (final library in jsUiLibraries) {
    library.ensureChannels();
  }
}

/// 全部组件注册 = Flutter 基础组件（核心本体）+ 各能力/三方库的自注册。
void registerAllJsWidgets(JsWidgetRegistry r) {
  // 地基：Text/Column 等基础视觉组件，不属于任何可插拔能力。
  registerBuiltinJsWidgets(r);
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
/// 这与 `registerNativeComponent`（原生注入表）本就是全局一份同因。
///
/// **懒建**：首次访问时构建并**一次性**注册全部内建/能力/三方库组件；因此
/// `registerJsUiLibrary(...)` 必须在首个 [JsUiWidget] 构造前调用（约定：App 的
/// `main()` 里、`runApp` 之前，与 `registerHostMethods` / `registerNativeComponent`
/// 同一位置）。
final JsWidgetRegistry _jsWidgetRegistry = _createJsWidgetRegistry();

JsWidgetRegistry _createJsWidgetRegistry() {
  final registry = JsWidgetRegistry();
  registerAllJsWidgets(registry);
  return registry;
}

/// 全局唯一的宿主 widget 注册表（见 [_jsWidgetRegistry]）。
JsWidgetRegistry get jsWidgetRegistry => _jsWidgetRegistry;
