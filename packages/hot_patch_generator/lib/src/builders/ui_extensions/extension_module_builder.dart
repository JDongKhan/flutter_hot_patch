/// 扩展注册产物 builder：**本地依赖包**里的 Dart `extension` → `patch/extensions.js`。
///
/// 为什么需要单独一个产物：项目文件由 `componentBuilder` 逐文件翻译，扩展随
/// **其声明文件的产物**发射；本地依赖包的源码不在构建目标包的输入范围里，
/// 没人翻译它们。这里用 [PackageSources] 直接扫盘（与 `ui_project_module`
/// 同一套本地包判定），把包内全部扩展集中注册到一个产物。
///
/// 加载时机由运行时保证（`JsRuntimeManager` 在首个模块求值完成、任何 mount
/// 之前求值本产物），因此本文件只需要**幂等注册**：`id` 用
/// `<源文件身份>#<扩展名>`，热更时同 id 再注册会先卸旧成员。
///
/// 已知限制（构建期出声，不静默降级）：扩展**目标类**若与扩展声明在同一个包里
/// 的另一个文件，类的 JS 实现只存在于 `patch/<package>.js`（由
/// `ui_project_module` 按「被组件引用」产出）；扩展注册的却是本产物里内联的
/// 那一份时，两者不是同一个构造函数。demo 与常见用法（扩展系统类型 / 值类型）
/// 不受影响。
library;

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';

import '../patch_entry/analysis/analyze_dart_class.dart';
import '../patch_entry/analysis/class_table.dart';
import '../patch_entry/analysis/const_support.dart';
import '../patch_entry/analysis/extension_support.dart';
import '../patch_entry/analysis/singleton_support.dart';
import '../patch_entry/class_info.dart';
import '../patch_entry/project_module_builder.dart' show localTranslationPackages;
import '../patch_entry/translator/dart2js.dart';
import '../shared/js_class_defs.dart';
import '../shared/js_format.dart';
import '../shared/package_sources.dart';
import '../shared/paths.dart';
import '../shared/source_index.dart';

/// `$package$` 输入 → 唯一产物 `patch/extensions.js`。
class ExtensionModuleBuilder implements Builder {
  const ExtensionModuleBuilder();

  static const String output = 'patch/extensions.js';

  @override
  Map<String, List<String>> get buildExtensions => const {
        r'$package$': [output],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    await buildStep.writeAsString(
      buildStep.allowedOutputs.first,
      canonicalizeJsIndent(renderExtensionsModule()),
    );
  }
}

/// 生成 `patch/extensions.js` 全文（无扩展时也产出，保持产物清单稳定）。
String renderExtensionsModule() {
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// Dart extension 注册（本地依赖包）：由 hot_patch_generator 生成')
    ..writeln('// 项目自身的扩展随各自源文件产物发射；本文件由运行时在首个模块')
    ..writeln('// 求值完成、任何组件 mount 之前求值，幂等注册。')
    ..writeln();

  final sources = PackageSources.instance;
  if (sources == null) {
    b.writeln('// 无法定位包信息，跳过。');
    return b.toString();
  }

  final imports = <String>{};
  final bodies = <String>[];
  for (final pkg in localTranslationPackages()) {
    final root = sources.byName(pkg);
    if (root == null) continue;
    for (final file in _dartFiles(root.libDir)) {
      final rel = file
          .substring(root.libDir.length + 1)
          .replaceAll(Platform.pathSeparator, '/');
      final identity = 'package:$pkg/$rel';
      final unit = parseUnitFile(identity);
      if (unit == null || !hasExtensionDeclaration(unit)) continue;

      final rendered = _renderPackageFile(identity, unit, imports);
      if (rendered.isNotEmpty) bodies.add(rendered);
    }
  }

  for (final line in imports.toList()..sort()) {
    b.writeln(line);
  }
  if (bodies.isEmpty) {
    b.writeln('// 本地依赖包里没有 Dart extension，空产物。');
    return b.toString();
  }
  for (final body in bodies) {
    b
      ..writeln()
      ..write(body);
  }
  return b.toString();
}

/// 一个源文件的扩展 + 它们引用到的**同文件**类 → JS 文本（import 行累加到
/// [imports]，由调用方统一排序写出）。
String _renderPackageFile(
  String identity,
  CompilationUnit unit,
  Set<String> imports,
) {
  final table = buildClassTable(unit, identity);
  final consts = buildTopLevelConstResolver(unit, identity, table);
  final localNames = <String>{
    for (final d in unit.declarations.whereType<ClassDeclaration>())
      d.name.lexeme,
  };

  String? importResolver(String name) {
    final info = table[name];
    if (info == null) return null;
    if (info.sourceFile == identity) return 'extensions.js';
    final pkg = packageNameOf(info.sourceFile);
    return pkg == null
        ? relativeProduct(ExtensionModuleBuilder.output,
            productPath(info.sourceFile))
        : relativeProduct(
            ExtensionModuleBuilder.output, packageModulePath(pkg));
  }

  final infos = <ExtensionInfo>[];
  for (final decl in extensionDeclarations(unit)) {
    final info = translateExtension(
      decl,
      unit,
      identity,
      ownProduct: ExtensionModuleBuilder.output,
      classTable: table,
      importResolver: importResolver,
      singletons: buildSingletonResolver(unit, identity),
      jsClassWidgets: jsClassWidgetTypes,
      delegateClassWidgets: builderFormTypes,
      ignoredTypes: ignoredClassNamesInScope(unit, identity),
      globalConsts: consts.names,
      classNamesInUnit: localNames,
    );
    if (info == null) continue;
    infos.add(info);
    if (info.targetImport != null) imports.add(info.targetImport!);
    for (final dep in info.dependencies) {
      if (localNames.contains(dep)) continue;
      final rel = importResolver(dep);
      if (rel != null && rel != 'extensions.js') {
        imports.add("import { $dep } from '$rel';");
      }
    }
    for (final e in info.usedWidgetPackages.entries) {
      imports.add("import { ${(e.value.toList()..sort()).join(', ')} } from "
          "'${relativeProduct(ExtensionModuleBuilder.output, packageModulePath(e.key))}';");
    }
  }
  if (infos.isEmpty) return '';

  // 同文件类：扩展成员体里 `Foo()` 需要一份 JS 类。产物里没有「同文件内联」
  // 之外的落点（本文件不是任何源文件的镜像产物），故按依赖 BFS 内联。
  final inline = <ClassInfo>[];
  final done = <String>{};
  final queue = <String>[for (final i in infos) ...i.dependencies];
  while (queue.isNotEmpty) {
    final dep = queue.removeLast();
    if (!done.add(dep)) continue;
    if (!localNames.contains(dep)) continue;
    final decl = unit.declarations
        .whereType<ClassDeclaration>()
        .where((d) => d.name.lexeme == dep)
        .firstOrNull;
    if (decl == null || decl.abstractKeyword != null) continue;
    if (decl.name.lexeme.startsWith('_')) {
      log.warning('[hot_patch_generator] $identity: 扩展引用到私有类 $dep，'
          '跨文件无法内联，跳过该类的 JS 实现。');
      continue;
    }
    final info = table[dep];
    if (info == null || info.isComponent) {
      // 组件类的产物由 ui_project_module 产出，本文件不可见：不重复内联一份
      // （两份构造函数会让扩展注册到错误的那一份上）。
      log.warning('[hot_patch_generator] $identity: 扩展引用到组件类 $dep，'
          '扩展产物里不内联组件，请确认它的实例来自组件产物。');
      continue;
    }
    final translated = translateClass(
      decl,
      unit,
      identity,
      classTable: table,
      importResolver: importResolver,
      singletons: buildSingletonResolver(unit, identity),
      jsClassWidgets: jsClassWidgetTypes,
      delegateClassWidgets: builderFormTypes,
      ignoredTypes: ignoredClassNamesInScope(unit, identity),
      globalConsts: consts.names,
      isComponent: false,
    );
    inline.add(translated);
    queue.addAll(translated.dependencies);
  }
  for (final cls in inline) {
    for (final dep in cls.dependencies) {
      if (localNames.contains(dep)) continue;
      final rel = importResolver(dep);
      if (rel != null && rel != 'extensions.js') {
        imports.add("import { $dep } from '$rel';");
      }
    }
    for (final e in cls.usedWidgetPackages.entries) {
      imports.add("import { ${(e.value.toList()..sort()).join(', ')} } from "
          "'${relativeProduct(ExtensionModuleBuilder.output, packageModulePath(e.key))}';");
    }
  }

  final b = StringBuffer();
  for (final cls in inline) {
    b
      ..writeln('// 同文件模型 ${cls.name}（扩展依赖，仅本产物内可见）')
      ..writeln(dart2js(cls, exported: false))
      ..writeln();
  }
  for (final info in infos) {
    b
      ..writeln('// 扩展 ${info.name.isEmpty ? '<unnamed>' : info.name}'
          '（$identity）')
      ..writeln(info.toJs());
  }
  return b.toString();
}

/// 目录下全部 `.dart` 文件（递归、按路径排序，产物稳定可复现）。
Iterable<String> _dartFiles(String dir) {
  final out = <String>[];
  final d = Directory(dir);
  if (!d.existsSync()) return out;
  for (final e in d.listSync(recursive: true, followLinks: false)) {
    if (e is File && e.path.endsWith('.dart')) out.add(e.path);
  }
  out.sort();
  return out;
}
