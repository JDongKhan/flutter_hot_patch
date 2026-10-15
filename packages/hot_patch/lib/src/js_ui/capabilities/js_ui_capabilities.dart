// ===== 宿主能力聚合入口 =====
//
// js_ui_widget 只依赖本文件两个函数。**本文件是核心与三方库的唯一接缝**：
// 核心能力（Flutter 等价物：句柄、Key、各 Controller、BuildContext 代理）在此
// 直接登记；三方库（provider / GetX / …）由 capabilities/js_ui_library.dart 的
// 注册表驱动，本文件**不再逐个列出库名**——新增库只需写一个 JsUiLibrary 子类
// 并 register（内建库见 js_ui_library.dart 的 _seedBuiltins；外部库可在 App 的
// main() 里注册），本文件与 runtime_source / js_widget_registry / js_ui_widget
// 三个核心文件从此不再变动。
//
// 目录结构：**一个能力一个目录**（宿主侧 `<x>_bridge.dart` + JS 侧 `<x>_js.dart`，
// 如 build_context/、key/、scroll_controller/、text_editing_controller/、
// tab_drawer/、notification_listener/；三方库见 provider/）。留在本层的只有：
// 通用句柄地基 handle_registry.dart、三方库模板 js_ui_library.dart、本聚合入口。
//
// 核心能力文件规范：一个能力 = 桥接表 + 通道 + 桥接组件 + 组件注册，全部内聚。
import '../js_widget_registry.dart';
import 'build_context/build_context_bridge.dart';
import 'handle_registry.dart';
import 'js_ui_library.dart';
import 'key/key_bridge.dart';
import 'notification_listener/notification_listener_bridge.dart';
import 'scroll_controller/scroll_controller_bridge.dart';
import 'tab_drawer/tab_drawer_bridge.dart';
import 'text_editing_controller/text_editing_controller_bridge.dart';

/// 全部能力通道（幂等）：在 JS 组件 mount（new XxxController → host 登记）
/// 前调用。JsUiWidget 启动时调用一次；顺序上必须先于 ensureJsUiRuntime（见
/// js_runtime_manager.ensureJsUiRuntime），因为 [jsUiRuntimeSource] 要拼各库片段。
void ensureJsUiCapabilities() {
  // ── 核心能力（Flutter 等价物，非三方库）──
  ensureHandleChannels();
  ensureKeyChannels();
  ensureScrollControllerChannels();
  ensureTextEditingControllerChannels();
  ensureTabControllerChannels();
  // BuildContext 代理（JS `this.context` → 宿主真值 BuildContext）
  ensureBuildContextChannels();
  // ── 三方库（各自内聚，见 JsUiLibrary）──
  for (final library in jsUiLibraries) {
    library.ensureChannels();
  }
}

/// 全部组件注册 = 核心注册（js_widget_registry）+ 各核心能力域 + 各三方库。
void registerAllJsWidgets(JsWidgetRegistry r) {
  registerBuiltinJsWidgets(r);
  registerScrollWidgets(r);
  registerTextWidgets(r);
  registerNotificationWidgets(r);
  registerTabDrawerWidgets(r);
  for (final library in jsUiLibraries) {
    library.registerWidgets(r);
  }
}
