/// 跨包模块 builder：把**本地依赖包**里被项目组件引用到的类翻译成一个包模块
/// `patch/<package>.js`。
///
/// 一个本地依赖包一个文件（与 [packageModulePath] 同一约定）：包内被引用的
/// 全部类集中在这一个模块里 `export class`；引用它的组件产物按
/// `import { Foo } from '../<package>.js'` 取用——与「跨文件模型产物」同一套
/// ES module import 协议，运行时不新增任何机制，产物也天然只有一份实现
/// （不像按源文件镜像产物那样，不同包的 `lib/` 结构会互相撞名）。
///
/// **谁产出**：「被引用」判定复用 [componentTranslationScope]（文件级可达 +
/// 符号级引用闭包），只有项目组件真的引用到的类才产出，依赖包不会被无差别
/// 翻译。**哪些包参与**：只认**本地包**（path 依赖 / workspace 成员，见
/// [PackageSources.isLocalPackage]），排除框架包（[nonTranslatedPackages]）
/// ——三方宿主包的类型在 JS 侧没有等价实现，仍走宿主注册表 / 原生注入。
///
/// 尚未覆盖（构建期出声，不静默降级）：本地依赖包里的**顶层常量**与
/// **静态单例类**产物（跨包常量引用与单例值不会随本模块产出）。
///
/// **归属唯一**：`patch/<package>.js` 只能有一个产出方——框架包（flutter /
/// provider 之流）归 `ui_widget`（宿主包装类 + 逻辑组件），本地依赖包归本
/// builder，两者按「包是否是本地包」天然互斥（见 [localTranslationPackages]）。
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';

import '../shared/js_widget_defs.dart';
import '../shared/package_sources.dart';
import '../shared/paths.dart';
import '../shared/source_index.dart';
import 'analysis/analyze_dart_class.dart';
import 'analysis/class_table.dart';
import 'analysis/component_scope.dart';
import 'analysis/const_support.dart';
import 'analysis/singleton_support.dart';
import 'class_info.dart';
import 'translator/dart2js.dart';

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

/// 跨包模块 builder：`$package$` 输入 → 每个本地依赖包一个
/// `patch/<package>.js`。输出清单由 [localTranslationPackages] 静态推导，
/// 与 `ui_widget` 同款（无需种子文件）；即使包内没有任何被引用的类也照常产出
/// （空模块 + 一句注释），因为 build_runner 要求写全声明的产物。
class ProjectModuleBuilder implements Builder {
  const ProjectModuleBuilder();

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$package$': [
          for (final p in localTranslationPackages()) packageModulePath(p),
        ],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final outputs = <String, AssetId>{};
    for (final o in buildStep.allowedOutputs) {
      final pkg = _packageOfModulePath(o.path);
      if (pkg != null) outputs[pkg] = o;
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
        renderProjectPackageModule(e.key, scope.neededClasses, ownerOf),
      );
    }
  }
}

/// `patch/<package>.js` → 包名；不是包模块路径返回 null。
String? _packageOfModulePath(String path) {
  const prefix = 'patch/';
  if (!path.startsWith(prefix) || !path.endsWith('.js')) return null;
  final name = path.substring(prefix.length, path.length - '.js'.length);
  if (name.isEmpty || name.contains('/')) return null;
  return name;
}

/// 一个本地依赖包的模块产物（`patch/<package>.js`）。
///
/// [neededClasses] 是全局「需要产出的类」（文件身份 → 类名集合），只取属于
/// [package] 的文件；[ownerOf] 是类名 → 声明文件身份（依赖产物路径解析用）。
String renderProjectPackageModule(
  String package,
  Map<String, Set<String>> neededClasses,
  Map<String, String> ownerOf,
) {
  final ownProduct = packageModulePath(package);
  // 本包需要产出的类：名字必须唯一（模块内一个类一份实现），重名出声。
  final decls = <String, (ClassDeclaration, String)>{};
  for (final e in neededClasses.entries) {
    if (packageNameOf(e.key) != package) continue;
    final unit = parseUnitFile(e.key);
    if (unit == null) {
      // ignore: avoid_print - 构建期日志
      print('[hot_patch_generator] 无法解析跨包源文件 ${e.key}（包 $package）：'
          '${e.value.join(', ')} 未产出');
      continue;
    }
    for (final name in e.value) {
      final decl = unit.declarations
          .whereType<ClassDeclaration>()
          .where((d) => d.name.lexeme == name)
          .firstOrNull;
      if (decl == null) continue;
      if (decls.containsKey(name)) {
        // ignore: avoid_print - 构建期日志
        print('[hot_patch_generator] 跨包模块 $package 里类名 $name 重复'
            '（${decls[name]!.$2} 与 ${e.key}），只保留前者');
        continue;
      }
      decls[name] = (decl, e.key);
    }
  }

  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// 跨包模块（package: $package）：由 hot_patch_generator 生成')
    ..writeln('// 本包内被项目组件引用到的类集中于此文件（跨包翻译）')
    ..writeln();

  if (decls.isEmpty) {
    b.writeln('// 本包没有被项目组件引用的类，空模块。');
    return b.toString();
  }

  // 依赖产物路径：同模块的类直接内联引用（本模块已 export），其余按
  // 「类名 → 声明文件身份 → 产物路径」推导（项目产物 / 其它跨包模块）。
  String? importResolver(String name) {
    final owner = ownerOf[name];
    if (owner == null) return null;
    if (packageNameOf(owner) == package) {
      return decls.containsKey(name) ? packageModulePath(package) : null;
    }
    return relativeProduct(ownProduct, productPath(owner));
  }

  final classInfos = <ClassInfo>[];
  final deps = <String>{};
  final usedWidgets = <String, Set<String>>{};
  var usedNodeHelper = false;
  for (final e in decls.entries) {
    final (decl, file) = e.value;
    final unit = parseUnitFile(file)!;
    final table = buildClassTable(unit, file);
    final consts = buildTopLevelConstResolver(unit, file, table);
    // 跨包文件里的顶层常量产物不在本模块内（同文件常量已内联），出声提示。
    final foreignConsts = referencedImportedConsts(unit, consts);
    if (foreignConsts.isNotEmpty) {
      // ignore: avoid_print - 构建期日志
      print('[hot_patch_generator] 跨包类 ${e.key}（$file）引用了包内其它文件的'
          '顶层常量 ${foreignConsts.join(', ')}：暂未随跨包模块产出');
    }
    final info = translateClass(
      decl,
      unit,
      file,
      classTable: table,
      importResolver: importResolver,
      singletons: buildSingletonResolver(unit, file),
      jsClassWidgets: jsClassWidgetTypes,
      delegateClassWidgets: builderFormTypes,
      globalConsts: consts.names,
      isComponent: table[e.key]?.isComponent ?? false,
    );
    classInfos.add(info);
    // 依赖：跨模块的类走 import，宿主 widget 走 package 模块 import
    // （与组件产物同一套拼装规则）。
    for (final d in info.dependencies) {
      if (decls.containsKey(d)) continue;
      if (importResolver(d) != null) deps.add(d);
    }
    info.usedWidgetPackages.forEach((pkg, types) {
      (usedWidgets[pkg] ??= <String>{}).addAll(types);
    });
    usedNodeHelper = usedNodeHelper || info.usedNodeHelper;
  }

  final imports = <String>[
    for (final d in deps.toList()..sort())
      "import { $d } from '${importResolver(d)}';",
  ];
  for (final e in usedWidgets.entries) {
    imports.add("import { ${(e.value.toList()..sort()).join(', ')} } from "
        "'${relativeProduct(ownProduct, packageModulePath(e.key))}';");
  }
  if (usedNodeHelper) {
    imports.add("import { __h } from "
        "'${relativeProduct(ownProduct, packageModulePath(nodeHelperPackage))}';");
  }
  final deduped = <String>[];
  for (final line in imports..sort()) {
    if (!deduped.contains(line)) deduped.add(line);
  }
  for (final line in deduped) {
    b.writeln(line);
  }
  for (final info in classInfos) {
    b
      ..writeln()
      ..writeln('// ${info.isComponent ? '组件' : '模型'} ${info.name}')
      ..writeln(dart2js(info, exported: true));
  }
  return b.toString();
}
