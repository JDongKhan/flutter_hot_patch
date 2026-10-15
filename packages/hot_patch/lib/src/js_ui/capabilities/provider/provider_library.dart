// ===== 三方库接入：provider =====
//
// **本文件 + 同目录两件（provider_bridge / provider_js）+ context_ops = provider
// 支持的全部落点**。把 provider 当「新引入的三方库」看待后可以看清：接入一个库
// 只需要一个 [JsUiLibrary] 子类 + 它自己的若干实现文件，基座（runtime_source /
// js_ui_capabilities / build_context_bridge / js_ui_widget / mini_react /
// handle_registry）零改动。
//
// 落点在本库的对应关系：
//   jsFragments     → provider_js.dart：作用域声明（`registerScope`）+ context 扩展
//                     方法（`JsBuildContext.prototype.watch/read`，对齐 Dart 的
//                     `extension BuildContextX on BuildContext`）
//   ensureChannels  → context_ops.dart：经核心的通用缝 `registerContextOp` 把
//                     watch/read 的宿主处理注册进去
//   registerWidgets → provider_bridge.dart：ChangeNotifierProvider / Consumer
//
// 注意依赖方向：provider **依赖** change_notifier（ChangeNotifier 宿主镜像、
// Listenable 监听边界都在那里），反之不成立。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'context_ops.dart';
import 'provider_bridge.dart';
import 'provider_js.dart';

/// provider（`ChangeNotifierProvider` / `Consumer`）接入。
class ProviderLibrary extends JsUiLibrary {
  const ProviderLibrary();

  @override
  String get id => 'provider';

  @override
  List<String> get jsFragments => const [providerJsSource];

  @override
  void ensureChannels() {
    // `context.watch/read` 属 provider（对齐 `extension BuildContextX`）：
    // JS 侧方法补丁见 provider_js.dart，宿主侧处理在此注册。
    // ChangeNotifier 句柄通道（notifier/ChangeNotifier）归 change_notifier 能力。
    ensureProviderContextOps();
  }

  @override
  void registerWidgets(JsWidgetRegistry r) => registerProviderWidgets(r);
}
