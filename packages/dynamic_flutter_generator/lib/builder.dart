/// build_runner 工厂入口（build.yaml 的 builder_factories 指向这里）。
///
/// 本文件是**对外入口**：只声明八个 builder 工厂与它们的默认选项；
/// 实现按功能分目录放在 `lib/src/` 下——`src/builders/shared/`（多 builder
/// 共用基础）、`src/builders/patch_entry/`（componentBuilder 的收集 + 翻译 +
/// 产物组装全链路）、`src/builders/core_js_builder/`（核心 JS 源码：runtime /
/// flutter 两个子目录，分别产出 `patch/runtime.js` 与 `patch/flutter.js`）、
/// `src/builders/ui_*/`（其余 builder 各自独立）。
/// 使用方只需依赖本包，即可通过 build_runner 获得全部产物。
library;

import 'package:build/build.dart';

import 'src/builders/core_js_builder/core_js_builder.dart';
import 'src/builders/patch_entry/component_builder.dart';
import 'src/builders/patch_entry/project_module_builder.dart';
import 'src/builders/ui_host_register/host_register_builder.dart';
import 'src/builders/ui_patch_archive/patch_archive_builder.dart';
import 'src/builders/ui_patch_manifest/patch_manifest_builder.dart';
import 'src/builders/ui_third_party_js/third_party_js_builder.dart';
import 'src/builders/ui_widget/widget_module_builder.dart';

/// 组件/模型 builder 工厂：`patch_entry`。
///
/// 把 lib/ 下的 Dart 源文件翻译为**同名** JS 产物（`lib/a/b.dart` →
/// `patch/a/b.js`）。按**文件内容**分流（与目录无关）：含 `@PatchEntry`
/// 类 → 组件产物；仅含普通类 → 模型/单例产物；都没有（如 main.dart）→ 不产出。
/// 本 builder 不读任何 options。
Builder componentBuilder(BuilderOptions _) => const ComponentBuilder();

/// package 模块 builder 工厂：`ui_widget`。
///
/// 每个 package → 一个共享 JS 模块 `patch/<package>.js`；产物清单由 translator
/// 注册表静态推导，挂在包根伪资产 `$package$` 下，使用方无需任何种子文件或配置。
Builder widgetModuleBuilder(BuilderOptions _) => const WidgetModuleBuilder();

/// 宿主三方 JS builder 工厂：`ui_third_party_js`。
///
/// 把宿主工程 `js/**.js` 原样拷贝到 `patch/packages/**.js`。文件名即 Dart
/// 包名（`js/provider.js` ↔ `package:provider`），业务产物依赖该模块时按
/// `patch/packages/<package>.js` 相对 import。三方 JS 由宿主维护，生成器不
/// 生成、不改写。本 builder 不读任何 options。
Builder thirdPartyJsBuilder(BuilderOptions _) => const ThirdPartyJsBuilder();

/// 跨包模块 builder 工厂：`ui_project_module`。
///
/// 每个**本地依赖包**（path 依赖 / workspace 成员）→ 一个共享 JS 模块
/// `patch/<package>.js`，内容是「被项目组件引用到」的该包类（跨包翻译）。
/// 挂在包根伪资产 `$package$` 下，输出清单由 [localTranslationPackages] 静态
/// 推导；没有本地依赖包时不产出任何文件。本 builder 不读任何 options。
Builder projectModuleBuilder(BuilderOptions _) => const ProjectModuleBuilder();

/// 核心 JS builder 工厂：`ui_runtime`。
///
/// 把核心 JS 源码（`src/builders/core_js_builder/js/runtime/`）写成
/// `patch/runtime.js`（构建期产物）。运行时 Dart 侧不再内置任何 JS 源码，
/// 只从补丁目录读取该文件——JS 修复随补丁发布生效，无需发版。
/// 本 builder 不读任何 options。
Builder coreJsBuilder(BuilderOptions _) => const CoreJsBuilder();

/// 宿主注入清单 builder 工厂：`ui_host_register`（不读任何 options）。
///
/// 扫描全包 `@HostInjected` static 方法，把「通道名 → 宿主实现」清单生成到
/// `lib/generated/host_methods.dart`（`List<Map<String, Object?>> get hostMethods`）。
/// 产物只有数据、不含注册 API，业务方把它交给运行时装配入口：
/// `initJsUi(hostMethods: hostMethods)`；换运行时也无需改生成器配置。
Builder hostRegisterBuilder(BuilderOptions _) => const HostRegisterBuilder();

/// patch 清单 builder 工厂：`ui_patch_manifest`。
///
/// 每次 build 在 `patch/manifest.json` 产出一份清单（基本信息 + 打包时间 +
/// 各 JS 资源的内容 hash）。它靠 `required_inputs: [".js"]` 被排到
/// `patch_entry` / `ui_widget` **之后**的阶段，从而读到它们的产物并计算 hash。
/// 基本信息可由使用方 `build.yaml` 覆盖（均为可选项，缺省取包名 / 省略版本）：
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       dynamic_flutter_generator:ui_patch_manifest:
///         options:
///           name: my_app
///           version: 1.2.3
/// ```
Builder patchManifestBuilder(BuilderOptions options) {
  final name = options.config['name'];
  final version = options.config['version'];
  return PatchManifestBuilder(
    name: name is String && name.isNotEmpty ? name : null,
    version: version is String && version.isNotEmpty ? version : null,
  );
}

/// patch 归档 builder 工厂：`ui_patch_archive`。
///
/// 把 `patch/` 下的全部文件（生成的 JS、`manifest.json` 与手工放置的静态资源）
/// 打成 `patch/patch.zip`。它靠 `required_inputs: [".json"]` 被排到
/// `ui_patch_manifest` **之后**的阶段，从而把最新清单一起打进包。
/// 本 builder 不读任何 options。
Builder patchArchiveBuilder(BuilderOptions _) => const PatchArchiveBuilder();