// ===== 三方库接入：provider =====
//
// **本文件 + 同目录三件（provider_bridge / provider_js / vm_bridge）= provider
// 支持的全部落点**。把 provider 当「新引入的三方库」看待后可以看清：接入一个库
// 只需要一个 [JsUiLibrary] 子类 + 它自己的若干实现文件，基座（runtime_source /
// js_ui_capabilities / build_context_bridge / js_ui_widget / mini_react /
// handle_registry）零改动。
//
// 四个落点在本库的对应关系：
//   jsFragments     → provider_js.dart：作用域声明（`registerScope`）+ context 扩展
//                     方法（`JsBuildContext.prototype.watch/read`，对齐 Dart 的
//                     `extension BuildContextX on BuildContext`）
//   ensureChannels  → vm_bridge.dart：JS 的 ChangeNotifier 实例 → 宿主通用镜像；
//                     另经 `registerContextOp`（context_ops.dart）把 watch/read 的
//                     宿主处理注册进核心的通用分发缝
//   registerWidgets → provider_bridge.dart：三个组件类型的宿主映射
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'context_ops.dart';
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
  void ensureChannels() {
    ensureVmChannels();
    // `context.watch/read` 属 provider（对齐 `extension BuildContextX`）：
    // JS 侧方法补丁见 provider_js.dart，宿主侧处理在此注册。
    ensureProviderContextOps();
  }

  @override
  void registerWidgets(JsWidgetRegistry r) => registerProviderWidgets(r);
}
