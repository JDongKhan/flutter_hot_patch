// ===== 三方库接入：provider =====
//
// **本文件 + 同目录三件（provider_bridge / provider_js / vm_bridge）= provider
// 支持的全部落点**。把 provider 当「新引入的三方库」看待后可以看清：接入一个库
// 只需要一个 [JsUiLibrary] 子类 + 它自己的若干实现文件，基座（runtime_source /
// js_ui_capabilities / build_context_bridge / js_ui_widget / mini_react /
// handle_registry）零改动。
//
// 四个钩子在本库的对应关系：
//   jsFragments         → provider_js.dart：把 provider 的「作用域声明」注册进
//                         JS 核心的通用机制（`registerScope('ChangeNotifierProvider')`）
//   ensureChannels      → vm_bridge.dart：JS 的 ChangeNotifier 实例 → 宿主通用镜像
//   registerWidgets     → provider_bridge.dart：三个组件类型的宿主映射
//   resolveWatchTarget  → provider_bridge.dart：`context.watch<T>()` 按类型精确解析
import 'package:flutter/widgets.dart';

import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'provider_bridge.dart';
import 'provider_js.dart';
import 'vm_bridge.dart';

/// provider（`ChangeNotifierProvider` / `Consumer` / `ListenableBuilder`）接入。
class ProviderLibrary extends JsUiLibrary {
  const ProviderLibrary();

  @override
  String get id => 'provider';

  @override
  List<String> get jsFragments => const [providerJsSource];

  @override
  void ensureChannels() => ensureVmChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerProviderWidgets(r);

  /// `context.watch<T>()` 的宿主侧权威解析：按 `jsType == T` 精确匹配，
  /// **不能取「最近的那个」provider**（嵌套不同类型时会订错）。
  /// 返回值是 [JsVm]（`Listenable` 子类），核心只当它是可订阅对象用。
  @override
  Listenable? resolveWatchTarget(BuildContext context, String type) =>
      jsVmOfTypeAt(context, type);
}
