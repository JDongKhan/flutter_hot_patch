/// 扩展注册产物 builder：**本地依赖包**里的 Dart `extension` →
/// `patch/extensions/<package>.js`（一包一个）。
///
/// 为什么需要单独一个产物：项目文件由 `componentBuilder` 逐文件翻译，扩展随
/// **其声明文件的产物**发射；本地依赖包的源码不在构建目标包的输入范围里，
/// 没人翻译它们。这里用 [PackageSources] 直接扫盘（与 `ui_project_module`
/// 同一套本地包判定），把包内全部扩展集中注册成一个产物。
///
/// **按需加载，不预热**：产物不是启动时统一求值的。项目里哪个文件 import 了
/// 该包的扩展声明库（Dart 里必须 import 才能用扩展），那个文件的产物就会
/// `import { ExtName } from '../extensions/<package>.js'`——加载即注册，没用到的
/// 包一次都不会被求值（真实项目扩展可能很多，预热是纯浪费）。
///
/// 注册是幂等的：`id` 用 `<源文件身份>#<扩展名>`，热更时同 id 再注册会先卸旧成员。
///
/// 已知限制（构建期出声，不静默降级）：扩展**目标类**若是同包另一个文件里的类，
/// 该类的 JS 实现在包模块 `patch/<package>.js` 里，且只含「被项目组件引用到」
/// 的类；未被引用到的类在扩展产物里不可得，注册会跳过。
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

/// 声明了 `extension` 的本地依赖包（输出清单据此静态推导；无扩展的包零产物）。
///
/// 只做一次进程级扫描：`buildExtensions` 在建图阶段被调用，不能每次都遍历
/// 所有包的 lib（读文件很便宜但与构建规模成正比）。判据是**语法级**的
/// `extension` 关键字——注释里出现会多产一个空产物，不影响正确性。
List<String> localExtensionPackages() => _localExtensionPackages ??= _scanPackages();

List<String>? _localExtensionPackages;

/// 源文件里是否出现 `extension` 声明（快速文本判据，用于包级筛选）。
final RegExp _extensionDeclRe =
    RegExp(r'^\s*(?:abstract\s+)?extension\s', multiLine: true);

List<String> _scanPackages() {
  final sources = PackageSources.instance;
  if (sources == null) return const [];
  final out = <String>[];
  for (final pkg in localTranslationPackages()) {
    final root = sources.byName(pkg);
    if (root == null) continue;
    for (final file in _dartFiles(root.libDir)) {
      if (_extensionDeclRe.hasMatch(File(file).readAsStringSync())) {
        out.add(pkg);
        break;
      }
    }
  }
  return out;
}

/// 扩展注册 builder：`$package$` 输入 → 每个有扩展的本地依赖包一个
/// `patch/extensions/<package>.js`。输出清单由 [localExtensionPackages] 静态
/// 推导，与 `ui_project_module` 同款（无种子文件）。
class ExtensionModuleBuilder implements Builder {
  const ExtensionModuleBuilder();

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$package$': [
          for (final p in localExtensionPackages()) extensionModulePath(p),
        ],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final sources = PackageSources.instance;
    if (sources == null) return;
    for (final output in buildStep.allowedOutputs) {
      // 产物名即包名：`patch/extensions/<package>.js`。
      final pkg = output.path.substring(
          'patch/extensions/'.length, output.path.length - '.js'.length);
      final root = sources.byName(pkg);
      final text =
          root == null ? '' : renderPackageExtensions(pkg, root.libDir, output.path);
      await buildStep.writeAsString(
        output,
        canonicalizeJsIndent(text.isEmpty ? _emptyModule(pkg) : text),
      );
    }
  }
}

String _emptyModule(String pkg) =>
    '// GENERATED CODE - DO NOT EDIT\n'
    '// $pkg 里没有 Dart extension，空产物。\n';

/// 一个包的全部扩展 → JS 全文（每个声明文件一段 + 依赖 import）。
String renderPackageExtensions(String pkg, String libDir, String output) {
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// Dart extension 注册（package:$pkg）：由 hot_patch_generator 生成')
    ..writeln('// 使用方 import 本文件即完成注册（`__jsExtension(...)`），无需预热。')
    ..writeln();

  final imports = <String>{};
  final bodies = <String>[];
  for (final file in _dartFiles(libDir)) {
    final rel =
        file.substring(libDir.length + 1).replaceAll(Platform.pathSeparator, '/');
    final identity = 'package:$pkg/$rel';
    final unit = parseUnitFile(identity);
    if (unit == null || !hasExtensionDeclaration(unit)) continue;
    final rendered = _renderFile(identity, unit, output, imports);
    if (rendered.isNotEmpty) bodies.add(rendered);
  }

  for (final line in imports.toList()..sort()) {
    b.writeln(line);
  }
  if (bodies.isEmpty) return '';
  for (final body in bodies) {
    b
      ..writeln()
      ..write(body);
  }
  return b.toString();
}

/// 一个源文件的扩展 + 它引用到的**同文件**类 → JS 文本（import 行累加到
/// [imports]，由调用方统一排序写出）。
String _renderFile(
  String identity,
  CompilationUnit unit,
  String output,
  Set<String> imports,
) {
  final table = buildClassTable(unit, identity);
  final consts = buildTopLevelConstResolver(unit, identity, table);
  final localNames = <String>{
    for (final d in unit.declarations.whereType<ClassDeclaration>())
      d.name.lexeme,
  };

  // 类名 → 产物身份：本文件内联（返回本产物）；同包其它文件 → 包模块；
  // 跨包 / 项目文件 → 其自身产物（本 builder 只处理本地包，正常不会出现）。
  String? productOf(String name) {
    final info = table[name];
    if (info == null) return null;
    if (info.sourceFile == identity) return output;
    final owner = packageNameOf(info.sourceFile);
    return owner == null ? productPath(info.sourceFile) : packageModulePath(owner);
  }

  String? importResolver(String name) {
    final product = productOf(name);
    if (product == null) return null;
    return relativeProduct(output, product);
  }

  final infos = <ExtensionInfo>[];
  for (final decl in extensionDeclarations(unit)) {
    final info = translateExtension(
      decl,
      unit,
      identity,
      ownProduct: output,
      classTable: table,
      importResolver: importResolver,
      productOf: productOf,
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
      _addClassImport(imports, dep, productOf, output);
    }
    _addWidgetImports(imports, info.usedWidgetPackages, output);
  }
  if (infos.isEmpty) return '';

  // 同文件类：扩展成员体里 `Foo()` 需要一份 JS 类。本产物不是任何源文件的
  // 镜像产物，故按依赖闭包内联同文件类。
  final inline = <ClassInfo>[];
  final done = <String>{};
  final queue = <String>[for (final i in infos) ...i.dependencies];
  while (queue.isNotEmpty) {
    final dep = queue.removeLast();
    if (!done.add(dep) || !localNames.contains(dep)) continue;
    final decl = unit.declarations
        .whereType<ClassDeclaration>()
        .where((d) => d.name.lexeme == dep)
        .firstOrNull;
    if (decl == null || decl.abstractKeyword != null) continue;
    if (dep.startsWith('_')) {
      log.warning('[hot_patch_generator] $identity: 扩展引用到私有类 $dep，'
          '扩展产物里不内联私有类，跳过它的 JS 实现。');
      continue;
    }
    final info = table[dep];
    if (info == null || info.isComponent) {
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
      _addClassImport(imports, dep, productOf, output);
    }
    _addWidgetImports(imports, cls.usedWidgetPackages, output);
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

/// 跨文件的类依赖 → import 行（同产物内的不 import）。
void _addClassImport(
  Set<String> imports,
  String name,
  String? Function(String name) productOf,
  String output,
) {
  final product = productOf(name);
  if (product == null || product == output) return;
  imports.add(
      "import { $name } from '${relativeProduct(output, product)}';");
}

/// 成员体里用到的框架 widget → 各自的包模块 import。
void _addWidgetImports(
  Set<String> imports,
  Map<String, Set<String>> used,
  String output,
) {
  for (final e in used.entries) {
    final names = (e.value.toList()..sort()).join(', ');
    imports.add("import { $names } from "
        "'${relativeProduct(output, packageModulePath(e.key))}';");
  }
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
