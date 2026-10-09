/// 构建期**种子文件**：不含任何运行时代码，也不应被其它文件 import。
///
/// build_runner 的输出路径必须在 builder 的 buildExtensions 里静态声明，无法
/// 按构建期「发现的类型」动态命名文件。因此「每个 package 一个共享 JS 文件」
/// （`assets/<package>.js`）的全部输出统一挂在本文件下，由
/// `ui_component_generator` 的 WidgetModuleBuilder 产出；包清单/类型清单由
/// translator 注册表静态推导（见 `_registeredWidgetPackages`）。
///
/// **使用方必须提供该文件**（生成器已无降级路径）：默认路径即本文件
/// （`lib/js_widgets.dart`），也可在使用方 `build.yaml` 里用
/// `options: { seed_file: <path> }` 覆盖。缺失该种子输入时不会产出任何
/// package 模块，组件产物的 import 会因此悬空。
///
/// 新增一个需要翻译的 widget 时，在注册表里登记 translator 即可，本文件无需改动。
library;