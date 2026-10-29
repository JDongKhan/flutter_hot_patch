// ===== 能力：BuildContext 代理（JS `this.context`）=====
//
// 片段提供 JS 侧代理类（机制本体），通道登记 `ctx/BuildContext` 句柄（句柄 id →
// 宿主结点 id → 真值 BuildContext）。宿主侧无专属组件。
//
// **本能力不含任何库的 API 语义**：`context.watch<T>()` / `read<T>()` 是 provider
// 那类 `extension BuildContextX on BuildContext`，其 JS 方法补丁在各库自己的模块里
// （patch/provider.js ← provider_module_js.dart），宿主侧处理经核心通用缝
// `registerContextOp` 注册
// （provider/context_ops.dart）。核心只把 op 分发给注册者。
import '../js_ui_library.dart';
import 'build_context_bridge.dart';

/// BuildContext 代理能力接入声明。
class BuildContextLibrary extends JsUiLibrary {
  const BuildContextLibrary();

  @override
  String get id => 'build-context';

  @override
  void ensureChannels() => ensureBuildContextChannels();
}
