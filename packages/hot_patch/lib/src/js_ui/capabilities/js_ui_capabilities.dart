// ===== 宿主能力聚合入口 =====
//
// js_ui_widget 只依赖本文件两个函数，未来新增能力（controller 桥接、组件
// 注册、JS 运行时片段）只改本文件 + 新增 capabilities/xxx_bridge.dart，
// **不碰** js_widget_registry（核心注册表）、js_ui_widget（生命周期）、
// runtime_source（运行时骨架）三个核心文件。
//
// 能力文件规范（见 capabilities/ 各文件）：一个能力 = 桥接表 + 通道 +
// 桥接组件 + 组件注册，全部内聚；Dart 侧 ensureXxxChannels + registerXxxWidgets
// 在此聚合，JS 侧片段由 runtime_source 拼接（见 capabilities/*_js.dart）。
import '../js_widget_registry.dart';
import 'notification_listener_bridge.dart';
import 'scroll_controller_bridge.dart';
import 'tab_drawer_bridge.dart';
import 'text_editing_controller_bridge.dart';

/// 全部能力通道（幂等）：在 JS 组件 mount（new XxxController → host 登记）
/// 前调用。JsUiWidget 启动时调用一次。
void ensureJsUiCapabilities() {
  ensureScrollControllerChannels();
  ensureTextEditingControllerChannels();
  ensureTabControllerChannels();
}

/// 全部组件注册 = 核心注册（js_widget_registry）+ 各能力域注册。
void registerAllJsWidgets(JsWidgetRegistry r) {
  registerBuiltinJsWidgets(r);
  registerScrollWidgets(r);
  registerTextWidgets(r);
  registerNotificationWidgets(r);
  registerTabDrawerWidgets(r);
}
