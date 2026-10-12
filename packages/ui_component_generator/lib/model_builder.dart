/// 非组件文件（无 @UIComponent）的产物渲染：把文件里的「可导出类」写成 JS。
library;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';

import 'class_table.dart';
import 'class_translator.dart';
import 'js_translator.dart';
import 'js_widget_defs.dart';
import 'module_renderer.dart';
import 'product_path.dart';
import 'singleton_support.dart';
import 'source_index.dart';
import 'widget2js.dart';

/// 非组件文件（无 @UIComponent）的产物渲染：把文件里的「可导出类」写成 JS。
///
/// 判定与目录无关（模型放哪个目录都行），只看内容：
///   - 静态单例类（含非私有 static 字段）→ `export const X = {...}`；
///   - 其余普通类（非私有、非抽象、非 widget 类）→ `export class X`；
///   - widget / State 与私有类跳过，避免 main.dart 这类文件产出无用 JS。
/// 无任何可导出类 → 不产出。
///
/// 普通类与组件走**同一个翻译入口** [translateClass]：方法体里返回自定义
/// 组件（如 CounterVm.buildText() → BannerCard()）同样译为 `__h(BannerCard,
/// {})` 并 import 该组件产物，不再有「模型渲染 / 组件渲染」两套逻辑。
Future<void> writeModelProduct(
  BuildStep buildStep,
  CompilationUnit unit,
  AssetId inputId,
  WidgetTranslatorRegistry registry,
  Map<String, Map<String, String>> hostMethods,
) async {
  // 全量类表（含组件 / widget 类，打 isComponent 标记）。
  final table = buildClassTable(unit, inputId.path);
  final ownProduct = productPath(inputId.path);
  final parsedNames = <String>{
    for (final d in unit.declarations)
      if (d is ClassDeclaration) d.name.lexeme,
  };
  // 组件名 → 依赖产物相对路径。本文件是模型文件（无 @UIComponent 根组件），
  // 同文件名一律无本产物组件；跨文件组件从 import directives 推导产物。
  final importProducts =
      resolveImportedComponentProducts(unit, inputId.path);
  String? importResolver(String name) {
    if (isIgnoredClass(unit, name)) return null;
    if (parsedNames.contains(name)) return null;
    final abs = importProducts[name];
    if (abs == null) return null;
    return relativeProduct(ownProduct, abs);
  }

  // 跨文件静态单例映射（build 树静态引用翻译用）；本文件单例类名集合。
  final singletonResolver = buildSingletonResolver(unit, inputId.path);
  final singletonNames = <String>{
    for (final d in findSingletonClasses(unit)) d.name.lexeme,
  };

  final declByName = <String, ClassDeclaration>{
    for (final d in unit.declarations.whereType<ClassDeclaration>())
      d.name.lexeme: d,
  };

  // 本文件可导出类：widget 类（无注解的页面 / 公共 StatelessWidget）跳过；
  // 单例收集为轻量条目（renderStaticConst 只需要 static 字段 + 初值 AST）；
  // 其余普通类一律走 translateClass 预渲染（与组件同一路径）。
  final singletons = <ClassInfo>[];
  final models = <ClassInfo>[];
  for (final entry in table.entries) {
    final info = entry.value;
    if (info.sourceFile != inputId.path) continue;
    if (info.isComponent) continue;
    if (singletonNames.contains(info.name)) {
      singletons.add(info);
      continue;
    }
    models.add(translateClass(
      declByName[info.name]!,
      unit,
      inputId.path,
      registry: registry,
      classTable: table,
      importResolver: importResolver,
      singletons: singletonResolver,
      hostMethods: hostMethods,
      jsClassWidgets: jsClassWidgetTypes,
      delegateClassWidgets: sliverBuilderTypes,
    ));
  }
  if (models.isEmpty && singletons.isEmpty) return;

  // 依赖 import（顺序：跨文件单例 → 跨文件模型 → 跨文件组件），与组件产物
  // 路径完全同一套规则。
  final dependencyImports = <String>[];
  final seenDeps = <String>{};
  for (final cls in singletonResolver.used) {
    final src = singletonResolver.sourceFileOf(cls);
    if (src == null || src == inputId.path) continue;
    dependencyImports.add(
      "import { $cls } from "
      "'${relativeProduct(ownProduct, productPath(src))}';",
    );
  }
  for (final cls in [...models, ...singletons]) {
    for (final dep in cls.dependencies) {
      if (singletonResolver.sourceFileOf(dep) != null) continue;
      final target = table[dep];
      if (target == null || target.isComponent) continue;
      if (target.sourceFile == inputId.path) continue;
      if (!seenDeps.add(dep)) continue;
      dependencyImports.add(
        "import { $dep } from "
        "'${relativeProduct(ownProduct, productPath(target.sourceFile))}';",
      );
    }
  }
  // 跨文件自定义组件（普通类方法体里 return BannerCard() 等）：import 后
  // 渲染成 __h(BannerCard, {})。
  for (final cls in models) {
    for (final dep in cls.dependencies) {
      if (seenDeps.contains(dep)) continue;
      final rel = importResolver(dep);
      if (rel == null) continue;
      seenDeps.add(dep);
      dependencyImports.add("import { $dep } from '$rel';");
    }
  }

  // 翻译期收集到的 package widget 类型与 __h 用途（模型方法体返回 widget 时
  // 同样需要 import 结点工厂）。
  final extraUsedWidgets = <String, Set<String>>{};
  for (final m in models) {
    mergeUsedWidgets(extraUsedWidgets, m.usedWidgetPackages);
  }
  await buildStep.writeAsString(
    buildStep.allowedOutputs.first,
    renderModuleJs(
      inputId.path,
      registry: registry,
      exportedClasses: models,
      singletons: singletons,
      classes: table,
      dependencyImports: dependencyImports,
      extraUsedWidgets: extraUsedWidgets,
      extraUsedNodeHelper: models.any((c) => c.usedNodeHelper),
      importResolver: importResolver,
      hostMethods: hostMethods,
    ),
  );
}