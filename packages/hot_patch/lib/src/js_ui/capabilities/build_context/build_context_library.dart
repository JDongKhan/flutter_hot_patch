// ===== 能力：BuildContext 代理（JS `this.context`）=====
//
// 片段提供 JS 侧代理类，通道登记 `ctx/BuildContext` 句柄（句柄 id → 宿主结点 id
// → 真值 BuildContext）。宿主侧无专属组件：`context.watch<T>()` 的**订阅**由核心
// 经 [JsUiLibrary.resolveWatchTarget] 解析（本能力自身不提供作用域，故不重写）。
import '../js_ui_library.dart';
import 'build_context_bridge.dart';
import 'build_context_js.dart';

/// BuildContext 代理能力接入声明。
class BuildContextLibrary extends JsUiLibrary {
  const BuildContextLibrary();

  @override
  String get id => 'build-context';

  @override
  List<String> get jsFragments => const [buildContextJsSource];

  @override
  void ensureChannels() => ensureBuildContextChannels();
}
