// ===== 三方库接入：provider =====
//
// provider 的**状态、作用域与订阅全部在 JS 侧**：JS 模块 `patch/provider.js`
// 含 `ChangeNotifierProvider` / `Consumer` / `MultiProvider` 的类、作用域登记
// （`__inheritedElements`）与 `context.watch/read` 扩展。
//
// 宿主侧只剩**模块资源声明**：provider 没有宿主 widget 映射，也不再注册
// `context.watch/read` 的宿主 op（取值与订阅都在 JS 内闭环）。因此本文件只负责
// 让运行时在就绪点加载 `provider.js`。
//
// 依赖方向：provider **依赖** runtime 的通用继承机制（`G.__core`），反之不成立。
import '../js_ui_library.dart';

/// provider（`ChangeNotifierProvider` / `Consumer`）接入。
class ProviderLibrary extends JsUiLibrary {
  const ProviderLibrary();

  @override
  String get id => 'provider';

  @override
  List<String> get jsModuleAssets => const ['provider.js'];
}
