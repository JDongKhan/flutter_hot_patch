/// build_runner 工厂入口（build.yaml 的 builder_factories 指向这里）。
///
/// 本文件只保留两个工厂函数，具体实现按功能拆分到同级文件：
///   - component_builder.dart：组件/模型 builder（ComponentBuilder），
///     `lib/**.dart` → 同名 `patch/**.js`（模型文件交给 model_builder.dart）；
///   - widget_module_builder.dart：package 模块 builder（WidgetModuleBuilder），
///     每个 package → 一个 `patch/<package>.js`。
library;

import 'package:build/build.dart';

import 'component_builder.dart';
import 'widget_module_builder.dart';

/// 组件/模型 builder 工厂。
///
/// 把 lib/ 下的 Dart 源文件翻译为**同名** JS 产物（`lib/a/b.dart` →
/// `patch/a/b.js`）：按**文件内容**分流（与目录无关），含 `@UIComponent`
/// 类 → 组件产物；仅含普通类 → 模型/单例产物；都没有（如 main.dart）→ 不产出。
/// 本 builder 不读任何 options。
Builder componentBuilder(BuilderOptions _) => const ComponentBuilder();

/// package 模块 builder 工厂：每个 package → 一个共享 JS 模块
/// `patch/<package>.js`（种子输入路径可由 `options: { seed_file: ... }` 覆盖）。
Builder widgetModuleBuilder(BuilderOptions options) =>
    WidgetModuleBuilder(seedPath: seedPathFrom(options));