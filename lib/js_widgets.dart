/// 构建期**种子文件**：不含任何运行时代码，也不应被其它文件 import。
///
/// build_runner 的输出路径必须在 builder 的 buildExtensions 里静态声明，无法
/// 按构建期「发现的类型」动态命名文件。因此「每个 widget 一个共享 JS 模块」
/// （`assets/components/<package>/<Type>.js`）的全部输出统一挂在本文件下，由
/// `ui_component_generator` 的 WidgetModuleBuilder 产出；类型清单由 translator
/// 注册表静态推导（见 `_registeredWidgetPackages`）。
///
/// 新增一个需要翻译的 widget 时，在注册表里登记 translator 即可，本文件无需改动。
library;