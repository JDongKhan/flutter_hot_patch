/// build_runner 工厂入口（build.yaml 的 builder_factories 指向这里）。
///
/// 本文件是**对外入口**：只声明三个 builder 工厂与它们的默认选项；
/// 实现按功能分目录放在 `lib/src/` 下——`src/builders/`（Builder 实现与
/// 产物组装）与 `src/translator/`（Dart AST → JS 翻译内核）。
/// 使用方只需依赖本包，即可通过 build_runner 获得全部产物。
library;

import 'package:build/build.dart';

import 'src/builders/ui_component/component_builder.dart';
import 'src/builders/ui_host_register/host_register_builder.dart';
import 'src/builders/ui_widget/widget_module_builder.dart';

/// 组件/模型 builder 工厂：`ui_component`。
///
/// 把 lib/ 下的 Dart 源文件翻译为**同名** JS 产物（`lib/a/b.dart` →
/// `patch/a/b.js`）。按**文件内容**分流（与目录无关）：含 `@UIComponent`
/// 类 → 组件产物；仅含普通类 → 模型/单例产物；都没有（如 main.dart）→ 不产出。
/// 本 builder 不读任何 options。
Builder componentBuilder(BuilderOptions _) => const ComponentBuilder();

/// package 模块 builder 工厂：`ui_widget`。
///
/// 每个 package → 一个共享 JS 模块 `patch/<package>.js`；种子输入路径可由
/// `build.yaml` 的 `options: { seed_file: ... }` 覆盖（默认 `lib/js_widgets.dart`，
/// 是必需项）。
Builder widgetModuleBuilder(BuilderOptions options) =>
    WidgetModuleBuilder(seedPath: seedPathFrom(options));

/// 宿主注入注册 builder 工厂：`ui_host_register`。
///
/// 扫描全包 `@HostInjected` static 方法，把注册调用集中生成到
/// `lib/generated/host_methods.dart`。注册目标默认指向配套运行时
/// （[defaultRegisterImport] / [defaultRegisterCall]），**开箱即用**；
/// 换用别的运行时实现时用 build.yaml 覆盖：
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       ui_component_generator:ui_host_register:
///         options:
///           register_import: "package:<runtime>/<runtime>.dart"
///           register_call: "<Runtime>.registerHostMethod"
/// ```
Builder hostRegisterBuilder(BuilderOptions options) {
  final import = options.config['register_import'];
  final call = options.config['register_call'];
  return HostRegisterBuilder(
    registerImport:
        import is String && import.isNotEmpty ? import : defaultRegisterImport,
    registerCall:
        call is String && call.isNotEmpty ? call : defaultRegisterCall,
  );
}