// ===== 能力：ChangeNotifier 状态基类（JS 侧）+ 响应式组件 =====
//
// 本能力包含三部分：
//   - JS 片段 [changeNotifierSource]：ChangeNotifier / ValueNotifier 基类本体；
//   - 句柄通道 [ensureChangeNotifierChannels]：JS 的 ChangeNotifier 实例 →
//     宿主通用镜像（change_notifier_bridge.dart）；
//   - 组件注册 [registerListenableWidgets]：ListenableBuilder /
//     ValueListenableBuilder 的宿主监听边界。
//
// 它是「模型类可被订阅」的前提（provider 的 VM、通用作用域的 subscribeListenable
// 都依赖它），故排在其它能力之前注入。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'change_notifier_bridge.dart';
import 'change_notifier_js.dart';
import 'listenable_builder_bridge.dart';

/// ChangeNotifier 基类 + 响应式组件的接入声明（provider / 任何状态库的共同地基）。
class ChangeNotifierLibrary extends JsUiLibrary {
  const ChangeNotifierLibrary();

  @override
  String get id => 'change-notifier';

  @override
  List<String> get jsFragments => const [changeNotifierSource];

  @override
  void ensureChannels() => ensureChangeNotifierChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerListenableWidgets(r);
}
