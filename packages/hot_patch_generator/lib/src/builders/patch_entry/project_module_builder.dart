/// 跨包模块 builder：把**本地依赖包**里的 Dart 源文件翻译成
/// `patch/packages/<package>/<lib 内相对路径>.js`。
///
/// **一个源文件一份产物**（与 [productPath] 同一约定）：包内文件按原路径镜像
/// 到自己的包目录下，`export class` / mixin / `registerExtension(...)` 都写在
/// 声明它的文件产物里；引用方按 `import { Foo } from
/// '../packages/<package>/<rel>.js'` 取用——与「跨文件模型产物」同一套
/// ES module import 协议，运行时不新增任何机制。
///
/// 为什么要独立的 `packages/` 前缀：本项目产物是 `patch/<lib 相对路径>.js`，
/// 若直接放 `patch/<package>/`，项目 `lib/` 下恰好存在同名目录时会撞名。
///
/// **谁产出**：「被引用」判定复用 [componentTranslationScope]（文件级可达 +
/// 符号级引用闭包），只有项目组件真的引用到的类才翻译；但产物按**文件**存在，
/// 未被引用的文件写空模块（build_runner 要求写全声明的产物）。**哪些包参与**：
/// 只认**本地包**（path 依赖 / workspace 成员，见 [PackageSources.isLocalPackage]），
/// 排除框架包（[nonTranslatedPackages]）——三方宿主包的类型在 JS 侧没有等价
/// 实现，仍走宿主注册表 / 原生注入。
///
/// **归属唯一**：`patch/packages/<package>/**` 只能有一个产出方——本地依赖包
/// 归本 builder，框架包（flutter / provider 之流）仍归 `ui_widget` 的单文件
/// 模块 `patch/<package>.js`，两者按「包是否是本地包」天然互斥
/// （见 [localTranslationPackages]）。
library;

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';

import '../shared/js_format.dart';
import '../shared/js_class_defs.dart';
import '../shared/package_sources.dart';
import '../shared/paths.dart';
import '../shared/runtime_global_types.dart';
import '../shared/source_index.dart';
import 'analysis/analyze_dart_class.dart';
import 'analysis/class_table.dart';
import 'analysis/component_scope.dart';
import 'analysis/const_support.dart';
import 'analysis/extension_support.dart';
import 'class_info.dart';
import 'translator/dart2js.dart';
import 'translator/js_value.dart';

/// 参与跨包翻译的本地依赖包（按包名排序；不含构建目标包自身与框架包）。
///
/// 要求包内有 lib 目录：workspace 根包这类「无 lib 的聚合包」虽在
/// package_config 里是本地包，但没有源码可翻译，必须排除（否则会白产一个空模块）。
List<String> localTranslationPackages() {
  final sources = PackageSources.instance;
  if (sources == null) return const [];
  return [
    for (final r in sources.packages)
      if (r.isLocal &&
          r.hasLib &&
          r.name != sources.projectName &&
          !nonTranslatedPackages.contains(r.name))
        r.name,
  ]..sort();
}

/// 参与产出的本地依赖包源文件（`package:<pkg>/<lib 内相对路径>`）。
///
/// build_runner 的 buildExtensions 必须在建图阶段给出完整输出清单，而跨包
/// 文件不在构建输入范围内、拿不到引用分析，故按包**全量扫描**；结果进程级
/// 缓存（包集合与文件列表在一次构建内稳定）。
List<String> localTranslationPackageFiles() =>
    _localPackageFiles ??= _scanPackageFiles();

List<String>? _localPackageFiles;

List<String> _scanPackageFiles() {
  final sources = PackageSources.instance;
  if (sources == null) return const [];
  final out = <String>[];
  for (final pkg in localTranslationPackages()) {
    final root = sources.byName(pkg);
    if (root == null) continue;
    final libDir = root.libDir;
    if (!Directory(libDir).existsSync()) continue;
    for (final f in Directory(libDir).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final rel =
          f.path.substring(libDir.length + 1).replaceAll(Platform.pathSeparator, '/');
      out.add('package:$pkg/$rel');
    }
  }
  out.sort();
  return out;
}

/// 跨包模块 builder：`$package$` 输入 → 每个本地依赖包源文件一份
/// `patch/packages/<package>/<rel>.js`。输出清单由
/// [localTranslationPackageFiles] 静态推导（无需种子文件）。
class ProjectModuleBuilder implements Builder {
  const ProjectModuleBuilder();

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$package$': [
          for (final f in localTranslationPackageFiles()) productPath(f),
        ],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final outputs = <String, AssetId>{};
    for (final o in buildStep.allowedOutputs) {
      final source = _sourceFileOfProductPath(o.path);
      if (source != null) outputs[source] = o;
    }
    if (outputs.isEmpty) return;
    final scope = await componentTranslationScope(buildStep);
    // 类名 → 声明它的源文件身份（跨包与项目内一视同仁）：解析依赖产物路径用。
    final ownerOf = <String, String>{};
    for (final e in scope.neededClasses.entries) {
      for (final name in e.value) {
        ownerOf.putIfAbsent(name, () => e.key);
      }
    }
    for (final e in outputs.entries) {
      await buildStep.writeAsString(
        e.value,
        canonicalizeJsIndent(
          renderProjectPackageFile(
            e.key,
            neededNames: scope.neededClasses[e.key] ?? const {},
            neededConsts: scope.neededConsts[e.key] ?? const {},
            neededFunctions: scope.neededFunctions[e.key] ?? const {},
            emittedScope: scope,
            ownerOf: ownerOf,
          ),
        ),
      );
    }
  }
}

/// `patch/packages/<package>/<rel>.js` → `package:<package>/<rel>.dart`；
/// 不是依赖包产物路径返回 null。
String? _sourceFileOfProductPath(String path) {
  const prefix = '$packageProductsRoot/';
  if (!path.startsWith(prefix) || !path.endsWith('.js')) return null;
  final rest = path.substring(prefix.length);
  final slash = rest.indexOf('/');
  if (slash <= 0) return null;
  final pkg = rest.substring(0, slash);
  final rel = rest.substring(slash + 1, rest.length - '.js'.length);
  if (rel.isEmpty) return null;
  return 'package:$pkg/$rel.dart';
}

/// 一个依赖包源文件的产物（`patch/packages/<package>/<rel>.js`）。
///
/// [neededNames] / [neededConsts] / [neededFunctions] 是本文件里**真正被引用**的
/// 类 / 顶层常量 / 顶层函数（来自 [componentTranslationScope]）；产物同时承载本
/// 文件声明的 `extension` 注册语句（与声明处一对一，见 [translateExtension]）。
/// [emittedScope] 用于判断跨文件依赖（类 / 常量 / 函数）是否真的被产出——
/// barrel re-export 与 const import 都只指向已产出的符号，避免引用空模块。
/// [ownerOf] 是类名 → 声明文件身份（跨文件 import 用）。
String renderProjectPackageFile(
  String sourceFile, {
  required Set<String> neededNames,
  required Set<String> neededConsts,
  required Set<String> neededFunctions,
  required TranslationScope emittedScope,
  required Map<String, String> ownerOf,
}) {
  final package = packageNameOf(sourceFile) ?? '';
  final ownProduct = productPath(sourceFile);
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// 跨包产物（package: $package）：由 hot_patch_generator 生成')
    ..writeln('// 源文件：$sourceFile（一个源文件一份产物）')
    ..writeln();

  final unit = parseUnitFile(sourceFile);
  if (unit == null) {
    b.writeln('// 无法解析该源文件，空模块。');
    return b.toString();
  }
  final table = buildClassTable(unit, sourceFile);
  final consts = buildTopLevelConstResolver(
    unit,
    sourceFile,
    table,
    emitFunctions: neededFunctions,
  );
  final extensionOperators = extensionOperatorsInScope(unit, sourceFile);
  final extensionNames = extensionScopesInScope(unit, sourceFile);
  warnExtensionConflicts(extensionNames, sourceFile);
  final localNames = <String>{
    for (final d in unit.declarations.whereType<ClassDeclaration>())
      d.name.lexeme,
    for (final d in unit.declarations.whereType<MixinDeclaration>())
      d.name.lexeme,
  };

  // 本文件真正写进产物的顶层常量 / 枚举 / 函数（只取被引用到的）。初始化器
  // 引用同文件类的常量必须排在类声明之后（`const k = Foo()` → `new Foo()`，
  // 类有 TDZ），其余常量先写，保证类的静态字段引用顶层常量时不触发 TDZ。
  final emittedConsts = <String, String>{
    for (final e in consts.sameFile.entries)
      if (neededConsts.contains(e.key) || neededFunctions.contains(e.key))
        e.key: e.value,
  };
  final earlyConsts = <String, String>{};
  final deferredConsts = <String, String>{};
  for (final e in emittedConsts.entries) {
    final refs = <String>{
      ...constRefNames(unit, {e.key}),
      ...topLevelFunctionRefNames(unit, {e.key}),
    };
    (refs.any(localNames.contains) ? deferredConsts : earlyConsts)[e.key] =
        e.value;
  }

  // 本文件里被引用到的类 / mixin：只取本文件声明，跨文件由 import 承接。
  final decls = <String, AstNode>{};
  // StatefulWidget 的 State 类已随 widget 类合并产出（见 translateClass 的
  // 唯一分叉），不能在这里再单独产出一个模型类——否则同一份实现会出现两遍，
  // 且独立类没有宿主初始化上下文。
  final stateNames = <String>{
    for (final d in unit.declarations.whereType<ClassDeclaration>())
      if (stateClassNameOf(d) case final n?) n,
  };
  for (final name in neededNames) {
    if (!localNames.contains(name) || stateNames.contains(name)) continue;
    final decl = unit.declarations
            .whereType<ClassDeclaration>()
            .where((d) => d.name.lexeme == name)
            .firstOrNull ??
        unit.declarations
            .whereType<MixinDeclaration>()
            .where((d) => d.name.lexeme == name)
            .firstOrNull;
    if (decl != null) decls[name] = decl;
  }

  // 依赖产物路径：本文件已产出 → 本产物；跨文件 → 该文件的产物。
  String? productOf(String name) {
    final owner = ownerOf[name];
    if (owner == null) return null;
    if (owner == sourceFile) {
      return decls.containsKey(name) ? ownProduct : null;
    }
    return productPath(owner);
  }

  String? importResolver(String name) {
    final product = productOf(name);
    return product == null ? null : relativeProduct(ownProduct, product);
  }

  // 本文件声明的 extension：注册语句写在本文件产物里，调用方 import 即注册。
  final extensions = <ExtensionInfo>[];
  for (final decl in extensionDeclarations(unit)) {
    final info = translateExtension(
      decl,
      unit,
      sourceFile,
      ownProduct: ownProduct,
      classTable: table,
      importResolver: importResolver,
      productOf: productOf,
      jsClassWidgets: jsClassWidgetTypes,
      delegateClassWidgets: builderFormTypes,
      ignoredTypes: ignoredClassNamesInScope(unit, sourceFile),
      globalConsts: consts.names,
      classNamesInUnit: localNames,
      extensionOperators: extensionOperators,
      extensionNames: extensionNames,
    );
    if (info != null) extensions.add(info);
  }

  // barrel（只有 export 转发、没有声明，如包入口 `lib/hot_module_base.dart`）：
  // 产物负责把目标文件的符号 re-export 出来，供 `import ... as p` 的命名空间
  // 引用（`p.User` / `p.moduleTag()`）继续可用。只转发**目标产物真的导出**的
  // 名字：跨包产物按「被引用」决定符号，转发一个没产出的名字会让运行时
  // `__modules[...]` 里缺少绑定。
  bool emittedInFile(String file, String name) {
    if (file == sourceFile) {
      return neededNames.contains(name) || emittedConsts.containsKey(name);
    }
    return emittedScope.neededClasses[file]?.contains(name) == true ||
        emittedScope.neededConsts[file]?.contains(name) == true ||
        emittedScope.neededFunctions[file]?.contains(name) == true;
  }

  final barrelExports =
      _barrelExportLines(unit, sourceFile, ownProduct, emittedInFile);

  if (decls.isEmpty &&
      extensions.isEmpty &&
      barrelExports.isEmpty &&
      emittedConsts.isEmpty) {
    b.writeln('// 本文件没有被项目引用的类 / mixin / 顶层常量 / 函数，'
        '也没有 extension，空模块。');
    return b.toString();
  }

  final classInfos = <ClassInfo>[];
  final applications = <MixinApplication>[];
  final deps = <String>{};
  final usedWidgets = <String, Set<String>>{};
  // 类名 → JS 基类名：渲染前按类名汇总，供「基类在前」排序与 extends 渲染共用。
  final baseClassByName = <String, String?>{};
  for (final e in decls.entries) {
    final node = e.value;
    // 跨包文件里的顶层常量产物不在本产物内（同文件常量已内联），出声提示。
    final foreignConsts = referencedImportedConsts(unit, consts);
    if (foreignConsts.isNotEmpty) {
      // ignore: avoid_print - 构建期日志
      print('[hot_patch_generator] 跨包类 ${e.key}（$sourceFile）引用了包内其它'
          '文件的顶层常量 ${foreignConsts.join(', ')}：暂未随跨包产物产出');
    }
    final info = node is MixinDeclaration
        ? translateMixin(
            node,
            unit,
            sourceFile,
            classTable: table,
            importResolver: importResolver,
            jsClassWidgets: jsClassWidgetTypes,
            delegateClassWidgets: builderFormTypes,
            ignoredTypes: ignoredClassNamesInScope(unit, sourceFile),
            globalConsts: consts.names,
            extensionOperators: extensionOperators,
            extensionNames: extensionNames,
          )
        : translateClass(
            node as ClassDeclaration,
            unit,
            sourceFile,
            classTable: table,
            importResolver: importResolver,
            jsClassWidgets: jsClassWidgetTypes,
            delegateClassWidgets: builderFormTypes,
            ignoredTypes: ignoredClassNamesInScope(unit, sourceFile),
            globalConsts: consts.names,
            isComponent: table[e.key]?.isComponent ?? false,
            extensionOperators: extensionOperators,
            extensionNames: extensionNames,
          );
    classInfos.add(info);
    baseClassByName[info.name] = jsBaseClassOf(info, table);
    applications.addAll(info.mixinApplications);
    if (info.mixinApplications.isNotEmpty) {
      baseClassByName[info.name] = info.mixinApplications.last.layer.name;
    }
    for (final a in info.mixinApplications) {
      baseClassByName[a.layer.name] = a.layer.superType;
      // mixin 类本身按声明源文件产物 import；同模块内的 mixin 已在 decls 里。
      final mixinProduct = importResolver(a.mixinName);
      if (!decls.containsKey(a.mixinName) &&
          mixinProduct != null &&
          mixinProduct != ownProduct) {
        deps.add(a.mixinName);
      }
      for (final d in a.layer.dependencies) {
        if (decls.containsKey(d)) continue;
        if (importResolver(d) != null) deps.add(d);
      }
      a.layer.usedWidgetPackages.forEach((pkg, types) {
        (usedWidgets[pkg] ??= <String>{}).addAll(types);
      });
    }
    // 依赖：跨模块的类走 import，宿主 widget 走 package 模块 import
    // （与组件产物同一套拼装规则）。
    for (final d in info.dependencies) {
      if (decls.containsKey(d)) continue;
      if (importResolver(d) != null) deps.add(d);
    }
    info.usedWidgetPackages.forEach((pkg, types) {
      (usedWidgets[pkg] ??= <String>{}).addAll(types);
    });
  }

  // 本文件扩展的依赖与 widget 引用并入产物 import 区。
  final namespaceImports = <String, String>{};
  for (final e in extensions) {
    for (final d in e.dependencies) {
      if (decls.containsKey(d)) continue;
      if (importResolver(d) != null) deps.add(d);
    }
    e.usedWidgetPackages.forEach((pkg, types) {
      (usedWidgets[pkg] ??= <String>{}).addAll(types);
    });
    namespaceImports.addAll(e.namespaceImports);
  }

  // 顶层常量 / 函数体依赖：跨文件类走 `deps`，跨文件常量单独按「目标产物真的
  // 导出」过滤后 import；与 barrel re-export 同一可见性口径。
  final importedConstRefs = <String, Set<String>>{};
  if (emittedConsts.isNotEmpty) {
    for (final name in consts.sameFileConstClasses) {
      if (decls.containsKey(name)) continue;
      final owner = ownerOf[name];
      if (owner == null || !emittedInFile(owner, name)) continue;
      if (importResolver(name) != null) deps.add(name);
    }
    final valueRefs = <String>{
      ...constRefNames(unit, emittedConsts.keys.toSet()),
      ...topLevelFunctionRefNames(unit, neededFunctions),
    };
    for (final name in valueRefs) {
      final owner = consts.importedFileOf[name];
      if (owner == null || !emittedInFile(owner, name)) continue;
      (importedConstRefs[owner] ??= <String>{}).add(name);
    }
  }

  final appLayers = [for (final a in applications) a.layer];
  final layerNames = {for (final a in applications) a.layer.name};

  // 类体先写进独立缓冲：import 需要按**实际出现的名字**收集（见下 usedValues）。
  final body = StringBuffer();
  // 不引用同文件类的顶层常量 / 枚举 / 函数先写（与项目产物同一形态）；
  // 引用同文件类的常量在类声明之后补写（类有 TDZ）。
  if (earlyConsts.isNotEmpty) {
    body
      ..writeln()
      ..write(renderTopLevelConstBody(earlyConsts));
  }
  // 基类在前（class 有 TDZ；Dart 不要求基类先声明）。
  for (final info in orderClassesByBase(
    [...classInfos, ...appLayers],
    (c) => baseClassByName[c.name],
  )) {
    body
      ..writeln()
      ..writeln('// ${info.isComponent ? '组件' : '模型'} ${info.name}')
      ..writeln(dart2js(
        info,
        exported: !layerNames.contains(info.name),
        baseClass: baseClassByName[info.name],
      ));
  }
  // `__mixinHard` 统一放在全部类声明之后（mixin 类可能声明得比 application
  // 类晚，类之间调用会触发 TDZ）。
  for (final a in applications) {
    body.writeln('__mixinHard(${a.layer.name}, ${a.mixinName});');
  }
  // 引用同文件类的顶层常量（构造 / 静态调用）：类声明之后再求值。
  if (deferredConsts.isNotEmpty) {
    body
      ..writeln()
      ..write(renderTopLevelConstBody(deferredConsts));
  }
  // 扩展注册语句：与 Dart 声明处一对一，调用方 import 本产物即完成注册。
  for (final e in extensions) {
    body
      ..writeln()
      ..writeln(e.toJs());
  }
  // barrel 的 re-export：把转发目标的产物符号透出，维持模块命名空间引用。
  for (final line in barrelExports) {
    body.writeln(line);
  }

  final imports = <String>[
    for (final d in deps.toList()..sort())
      "import { $d } from '${importResolver(d)}';",
  ];
  // 运行时值类（`flutter.js` 里 `export class` 的值对象 / 控制器）在值位置直接
  // 写 `new Duration(...)` / `new OverlayPortalController()`，它们不是元素，
  // 不进 usedWidgetPackages，必须按实际出现的名字补 import（与组件产物
  // `_renderJsProduct` 同一口径）。
  final bodyText = body.toString();
  final usedValues = <String>{
    for (final name in flutterExportTypes())
      if (RegExp('\\b${RegExp.escape(name)}\\b').hasMatch(bodyText)) name,
  };
  (usedWidgets[nodeHelperPackage] ??= <String>{}).addAll(usedValues);
  for (final e in usedWidgets.entries) {
    if (e.value.isEmpty) continue;
    imports.add("import { ${(e.value.toList()..sort()).join(', ')} } from "
        "'${relativeProduct(ownProduct, packageModulePath(e.key))}';");
  }
  // 扩展成员体里的 `p.Foo`（import 前缀）→ 模块命名空间 import。
  for (final e in namespaceImports.entries) {
    if (e.value.isEmpty) continue;
    imports.add("import * as ${e.key} from "
        "'${relativeProduct(ownProduct, e.value)}';");
  }
  // 顶层常量 / 函数体引用的跨文件常量（同文件常量已内联）。
  for (final e in importedConstRefs.entries) {
    final names = e.value.toList()..sort();
    imports.add("import { ${names.join(', ')} } from "
        "'${relativeProduct(ownProduct, productPath(e.key))}';");
  }
  final deduped = <String>[];
  for (final line in imports..sort()) {
    if (!deduped.contains(line)) deduped.add(line);
  }
  for (final line in deduped) {
    b.writeln(line);
  }
  return b.toString() + body.toString();
}

/// barrel 文件的 re-export 行：`export { A, B } from './src/a.js';`
///
/// 只对本地依赖包内的目标生效（框架包 / `dart:` 由宿主模块承接，不在这里
/// 转发）；`show` / `hide` 按声明名过滤，私有名不导出。转发集合覆盖产物里
/// 真正导出的**类 / mixin / extension / 枚举 / 顶层常量 / 顶层函数**；
/// [emitted] 用于剔除「声明了但本次没被引用、产物里不存在」的名字（extension
/// 例外：声明处一定会写 `registerExtension`，故始终转发）。
List<String> _barrelExportLines(
  CompilationUnit unit,
  String sourceFile,
  String ownProduct,
  bool Function(String file, String name) emitted,
) {
  final out = <String>[];
  for (final d in unit.directives.whereType<ExportDirective>()) {
    final uri = d.uri.stringValue;
    if (uri == null || uri.startsWith('dart:')) continue;
    final target = resolveDirectiveTarget(uri, sourceFile);
    if (target == null) continue;
    final pkg = packageNameOf(target);
    if (pkg != null && !isFileLayoutPackage(pkg)) continue;
    final targetUnit = parseUnitFile(target);
    if (targetUnit == null) continue;
    final extensionNames = {
      for (final e in targetUnit.declarations.whereType<ExtensionDeclaration>())
        if (e.name?.lexeme case final n?) n,
    };
    var shown = {
      for (final n in _exportedDeclarationNames(targetUnit))
        if (extensionNames.contains(n) || emitted(target, n)) n,
    };
    for (final c in d.combinators) {
      if (c is ShowCombinator) {
        shown = shown.where((n) => c.shownNames.any((s) => s.name == n)).toSet();
      } else if (c is HideCombinator) {
        shown = shown.where((n) => !c.hiddenNames.any((s) => s.name == n)).toSet();
      }
    }
    if (shown.isEmpty) continue;
    final sorted = shown.toList()..sort();
    out.add("export { ${sorted.join(', ')} } from "
        "'${relativeProduct(ownProduct, productPath(target))}';");
  }
  return out;
}

/// 文件里可被 re-export 的公共顶层声明：类 / mixin / 具名 extension / 枚举 /
/// 顶层常量 / 顶层函数（`main` 除外）。typedef 只参与类型检查，不进产物。
Set<String> _exportedDeclarationNames(CompilationUnit unit) {
  final out = <String>{};
  for (final d in unit.declarations) {
    Iterable<String> names = const [];
    if (d is ClassDeclaration || d is MixinDeclaration || d is EnumDeclaration) {
      names = [(d as NamedCompilationUnitMember).name.lexeme];
    } else if (d is ExtensionDeclaration) {
      final n = d.name?.lexeme;
      names = n == null ? const [] : [n];
    } else if (d is FunctionDeclaration) {
      names = d.name.lexeme == 'main' ? const [] : [d.name.lexeme];
    } else if (d is TopLevelVariableDeclaration) {
      names = [for (final v in d.variables.variables) v.name.lexeme];
    }
    out.addAll(names.where((n) => !n.startsWith('_')));
  }
  return out;
}
