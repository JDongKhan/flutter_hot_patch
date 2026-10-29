/// 组件/模型 builder：把 lib/ 下的 Dart 源文件翻译为同名 JS 产物。
///
/// 组件文件与非组件（模型/单例）文件走**同一个入口**：先收集本文件「根类」，
/// 再统一调 [translateClass] 翻译；两处的差别只是传给 translateClass 的
/// `isComponent` 参数。翻译与产物组装逻辑组件/普通类完全共用。
library;

import 'dart:async';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';

import 'analysis/analyze_dart_class.dart';
import 'analysis/class_table.dart';
import 'analysis/component_scope.dart';
import 'analysis/const_support.dart';
import 'analysis/extension_support.dart';
import 'analysis/imported_components.dart';
import 'class_info.dart';
import 'translator/dart2js.dart';
import 'translator/js_value.dart';
import '../shared/js_format.dart';
import '../shared/js_class_defs.dart';
import '../shared/paths.dart';
import '../shared/source_index.dart';
import '../ui_widget/widget_module_builder.dart' show hostWrapperSource;

/// 把 lib/ 下的 Dart 源文件翻译为**同名** JS 产物（`lib/a/b.dart` → `patch/a/b.js`）：
/// 文件名与 Dart 源文件一一对应，不区分组件/模型，也不预设目录结构——源码
/// 怎么组织、有哪些目录，由使用方决定，产物跟着走。
///
/// 按**文件内容**分「根类」收集（与目录无关），分支只体现在 `isComponent`：
///   - 含 `@PatchEntry` 类 → 根类 = 这些注解类（组件产物：Component 类 + build）；
///   - 否则 → 根类 = 本文件「可导出普通类」（非私有、非抽象、非组件）
///     → 模型产物（`export class`，供组件产物 import）；
///   - 都没有（如 main.dart）→ 不产出。
///
/// 组件本身 100% 正常可用（普通 StatefulWidget）；注解只是构建期元数据，
/// 生成器全程静态解析，不执行任何 Dart 代码。
///
/// # 架构
///
/// ComponentBuilder 只负责「总控」，不含任何翻译逻辑：
///   - 收集本文件根类（组件或普通类），调唯一入口 translateClass 翻译；
///   - 按 ClassInfo.dependencies 递归：同文件类内联、跨文件类生成 import；
///   - 组装并写出产物（package 模块由 WidgetModuleBuilder 另出）。
///
/// 翻译只有一个入口（analyze_dart_class.translateClass）：内部仅判断
/// 「StatefulWidget → 合并同文件 State 类」这一次分叉，组件与普通类的字段 /
/// 方法 / 依赖 / widget 树全部同一条路径。
///
/// 「widget 怎么翻译成 JSON/JS」只有一条**统一路径**（见 translator/element_json.dart）：
/// 判断依据是**值的形态**与**通用参数名**，不看 widget 类型——内建、自定义、
/// 三方组件同一套规则，接入新组件零实现、无需注册表。
class ComponentBuilder implements Builder {
  const ComponentBuilder();

  /// JS widget 模块（`patch/flutter.js` / `patch/provider.js` …）
  /// 由 WidgetModuleBuilder 产出；本 builder 只产出与源文件同名的产物。
  ///
  /// 输出路径**直接镜像 lib 源码路径**（`lib/a/b.dart` → `patch/a/b.js`），
  /// 文件名与 Dart 源文件一致，不预设目录名、不区分组件/模型。
  @override
  Map<String, List<String>> get buildExtensions => const {
        '^lib/{{}}.dart': [
          'patch/{{}}.js',
        ],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final source = await buildStep.readAsString(inputId);
    final parsed = parseString(
      content: source,
      throwIfDiagnostics: false,
      path: inputId.path,
    );

    // 组件名 → 依赖产物 jsAsset 路径。规则：
    //   本文件类（注解组件 / public 或私有 widget 类）→ 本文件产物（同产物注册）；
    //   @PatchIgnore(isComponent: true) → 声明它的源文件产物（包装类在那里生成）；
    //   @PatchIgnore()（isComponent 非 true）→ null（整类不翻译）；
    //   跨文件组件 → 从 import directives 推导源文件产物（见
    //   resolveImportedComponentProducts，口径与根类收集一致）。
    // （提前于根类收集构造：translateClass 内部翻译 Component
    //   节点时即会调用 importResolver，闭包必须已初始化）
    final parsedNames = <String>{
      for (final d in parsed.unit.declarations)
        if (d is ClassDeclaration) d.name.lexeme,
    };
    // 本文件可见的「整类忽略」类（`@PatchIgnore` 且 isComponent 非 true）：
    // 使用方引用它们的结点直接丢弃（不产出半截代码）。
    final ignoredTypes = ignoredClassNamesInScope(parsed.unit, inputId.path);
    // 本文件声明的 `@PatchIgnore(isComponent: true)` 类：在本产物末尾生成包装类。
    final wrapperClasses = ignoredComponentClassNames(parsed.unit).toList();
    // 产物采用**相对路径**（相对当前产物所在目录，如 'bar_component.js'）：
    // 未来 JS 产物整体发布（CDN / 包内迁移）时，主产物与依赖产物的相对关系
    // 不变，运行时按当前 jsAsset 的目录解析即可，绝对路径会随部署位置失效。
    final ownProduct = productPath(inputId.path); // patch/.../x.js
    final ownName = ownProduct.substring(ownProduct.lastIndexOf('/') + 1);
    // 跨文件组件名 → 产物路径（按**类名**精确绑定；见 resolveImportedComponentProducts）。
    final importProducts =
        resolveImportedComponentProducts(parsed.unit, inputId.path);

    // 全量「类表」：同文件 + 跨文件 import 的所有 Dart 类（公共、非抽象、
    // 非 @HostInjected），组件 / widget 类打 isComponent 标记、普通类不打标。
    // 翻译只按名字在这张表里解析依赖（见 analyze_dart_class.dart）。
    // 提前于 importResolver 声明：后者要用类表兜底解析「经 mixin 带入」的
    // 跨文件组件依赖。
    final classTable = buildClassTable(parsed.unit, inputId.path);

    String? importResolver(String name) {
      // `@PatchIgnore(isComponent: true)` 的包装类就在**声明它的源文件产物**里；
      // 其余的 @PatchIgnore（isComponent 非 true）整类不翻译 → null。
      if (isIgnoredClass(parsed.unit, name) &&
          !isIgnoredComponentType(parsed.unit, name)) {
        return null;
      }
      if (parsedNames.contains(name)) return ownName;
      final abs = importProducts[name];
      if (abs != null) return relativeProduct(ownProduct, abs);
      // 经由 mixin 带入的组件依赖：mixin 声明文件的 import 图不在本文件的
      // import directives 里（类表已并入，见 buildClassTable），按类表定位
      // 其声明文件的产物。判据与「有产物」同口径：公共 widget 类 / @PatchEntry
      // 打 isComponent 标记；@PatchIgnore / @HostInjected 不进类表或被上面拦掉。
      final info = classTable[name];
      if (info != null && info.isComponent && info.sourceFile != inputId.path) {
        return relativeProduct(ownProduct, productPath(info.sourceFile));
      }
      return null;
    }

    // 类名 → **产物身份**（`patch/a/b.js`）：扩展注册要判断目标是「本产物内」
    // 还是「另一个产物」（同产物内传裸类名，跨产物才 import）。
    String? productOf(String name) {
      if (isIgnoredClass(parsed.unit, name) &&
          !isIgnoredComponentType(parsed.unit, name)) {
        return null;
      }
      if (parsedNames.contains(name)) return ownProduct;
      return importProducts[name];
    }

    // 根类收集——两种文件走同一入口，差别只在 isComponent 参数：
    //   - 有 @PatchEntry 类 → 根文件：根类 = 全部注解类（组件产物）；
    //   - 否则 → 双重判据（见 componentTranslationScope）：文件级可达 + 符号级
    //     「被引用」——根类 = 本文件里**真的被会产出的类引用到**的类
    //     （public 的 widget 类与普通类）。数据的可翻译性由「被引用」决定
    //     （`model/user.dart` 同理）——入口页 / 展示页（main.dart、
    //     widget_showcase.dart）不被任何注解组件引用、不产出；`detail_pages.dart`
    //     只有三个 tab 页订单卡真的用到的 MiniButton 产出，只在 @HostInjected
    //     宿主方法体里 `new` 出来的详情页不翻译（依赖链在 @HostInjected 处断掉）。
    //     @PatchIgnore / @HostInjected 亦不翻译。
    final roots = <(ClassDeclaration, bool)>[];
    // 本文件是否声明了 `extension`：纯扩展文件没有根类，但也必须产出产物
    // （`__jsExtension(...)` 注册语句就写在声明处），故「无根类 → 不产出」的
    // 早返回要让它让位。是否产出仍由**文件级可达**决定（component_scope 把声明
    // 扩展的文件视为有产出，因此被 import 的扩展文件一定可达；没人 import 的
    // 扩展文件在 JS 侧永远不会被加载，不产出）。
    final hasExtensions = hasExtensionDeclaration(parsed.unit);
    final annotated = <ClassDeclaration>[
      for (final d in parsed.unit.declarations.whereType<ClassDeclaration>())
        if (findAnnotation(d.metadata, 'PatchEntry') != null) d,
    ];
    if (annotated.isNotEmpty) {
      roots.addAll([for (final d in annotated) (d, true)]);
    } else {
      final scope = await componentTranslationScope(buildStep);
      if (!scope.reachableFiles.contains(inputId.path)) return;
      final neededHere = scope.neededClasses[inputId.path] ?? const <String>{};
      for (final d in parsed.unit.declarations.whereType<ClassDeclaration>()) {
        final name = d.name.lexeme;
        if (name.startsWith('_') || d.abstractKeyword != null) continue;
        if (!neededHere.contains(name)) continue;
        if (isIgnoredClass(parsed.unit, name)) continue;
        final info = classTable[name];
        if (info == null) continue;
        // isComponent=true → 组件根类（build 树 / export class）；
        // false → 普通类根类（模型，export class）。
        roots.add((d, info.isComponent));
      }
    }
    // 没有根类但有 `@PatchIgnore(isComponent: true)` 包装类：仍按常规路径产出
    // （包装类 + 顶层常量一起写），否则使用方的 `new X(...)` 缺类定义。
    if (roots.isEmpty &&
        wrapperClasses.isEmpty &&
        !hasExtensions) {
      // 纯数据文件（如 lib/app/service/app_data.dart）：文件里没有任何可翻译的类，
      // 只有顶层常量 → 产出「顶层常量」产物（`export const kBanners = [...]`），
      // 组件产物才能 import 到这些值（与类产物同一个文件级产物路径）。
      if (!_hasOwnTopLevelConst(parsed.unit)) return;
      final constResolver =
          buildTopLevelConstResolver(parsed.unit, inputId.path, classTable);
      if (constResolver.sameFile.isEmpty) return;
      final importByFile = <String, Set<String>>{};
      _addConstImports(importByFile, constResolver,
          referencedImportedConsts(parsed.unit, constResolver));
      _addClassImports(
          importByFile, classTable, constResolver.sameFileConstClasses);
      final text = renderTopLevelConstProduct(
        inputId.path,
        consts: constResolver.sameFile,
        imports: _importLines(importByFile, ownProduct),
      );
      if (text.isEmpty) return;
      await buildStep.writeAsString(buildStep.allowedOutputs.first, text);
      return;
    }

    // 顶层常量（数据文件）解析：把本文件可见的顶层 const（同文件 + import 文件）
    // 在解析期翻译成 JS 值。同文件的 inline 进本产物，跨文件的 import——与类
    // 同一套「同文件内联 / 跨文件 import」规则。globalConsts 是「已译成功」的
    // 常量名集合，注入翻译作用域后组件里的 `kBanners` 才能解析为同名 JS 常量。
    final constResolver =
        buildTopLevelConstResolver(parsed.unit, inputId.path, classTable);
    final globalConsts = constResolver.names;

    // 逐个根类翻译：JS 类名 = Dart 类名；State 合并、字段 / 方法 / 依赖处理
    // 全部在 translateClass 内部完成，builder 只决定「以组件身份还是普通类身份」。
    final exportedClasses = <ClassInfo>[];
    for (final (decl, isComponent) in roots) {
      exportedClasses.add(translateClass(
        decl,
        parsed.unit,
        inputId.path,
        classTable: classTable,
        importResolver: importResolver,
        jsClassWidgets: jsClassWidgetTypes,
        delegateClassWidgets: builderFormTypes,
        ignoredTypes: ignoredTypes,
        globalConsts: globalConsts,
        isComponent: isComponent,
      ));
    }

    // 本文件声明的 `extension`：注册语句**写在声明处**（该文件自身的产物里），
    // 调用点与 Dart 一对一（成员由运行时装到目标类型原型上）。
    final extensions = <ExtensionInfo>[];
    for (final decl in extensionDeclarations(parsed.unit)) {
      final info = translateExtension(
        decl,
        parsed.unit,
        inputId.path,
        ownProduct: ownProduct,
        classTable: classTable,
        importResolver: importResolver,
        productOf: productOf,
        jsClassWidgets: jsClassWidgetTypes,
        delegateClassWidgets: builderFormTypes,
        ignoredTypes: ignoredTypes,
        globalConsts: globalConsts,
        classNamesInUnit: parsedNames,
      );
      if (info != null) extensions.add(info);
    }

    // 按依赖关系递归：从根类的 dependencies 做 BFS（组件与普通类同一套）——
    //   - 同文件**有产物**的组件（@PatchEntry / 私有 _Xxx）→ 翻译进同一产物；
    //   - 同文件普通类（模型/共享类）→ 翻译为产物内可见的 inline class；
    //   - `@PatchIgnore(isComponent: true)` → 类本身不翻译（产物里已有包装类）；
    //   - @PatchIgnore() / 无注解公共组件（importResolver 返回 null）→
    //     产物保留其类型名结点，运行时原生注入，不产出 JS 类；
    //   - 跨文件依赖 → 不翻译，后面统一生成 import。
    // 普通类里引用到的类与组件走同一套递归（dependencies 是翻译期统一收集的）。
    final inlineClasses = <String, ClassInfo>{};
    final doneDeps = <String>{};
    final depQueue = <String>[
      for (final c in exportedClasses) ...c.dependencies,
      // 扩展成员体里构造/引用的类走同一条递归：同文件的内联、跨文件的 import。
      for (final e in extensions) ...e.dependencies,
    ];
    while (depQueue.isNotEmpty) {
      final dep = depQueue.removeLast();
      if (doneDeps.contains(dep)) continue;
      doneDeps.add(dep);
      if (!parsedNames.contains(dep)) continue; // 跨文件 → import 阶段处理
      // `@PatchIgnore(isComponent: true)`：类不翻译，产物里是包装类（上面已生成）。
      if (isIgnoredComponentType(parsed.unit, dep)) continue;
      if (exportedClasses.any((c) => c.name == dep) ||
          inlineClasses.containsKey(dep)) {
        continue;
      }
      final decl = parsed.unit.declarations
          .whereType<ClassDeclaration>()
          .firstWhere((d) => d.name.lexeme == dep);
      final tableInfo = classTable[dep];
      final isWidgetDep = tableInfo?.isComponent ?? dep.startsWith('_');
      if (isWidgetDep && importResolver(dep) != ownName) {
        // 无 JS 产物的 widget（无注解公共组件 / @PatchIgnore）。
        continue;
      }
      final translated = translateClass(
        decl,
        parsed.unit,
        inputId.path,
        classTable: classTable,
        importResolver: importResolver,
        jsClassWidgets: jsClassWidgetTypes,
        delegateClassWidgets: builderFormTypes,
        ignoredTypes: ignoredTypes,
        globalConsts: globalConsts,
        isComponent: isWidgetDep,
      );
      if (isWidgetDep) {
        exportedClasses.add(translated);
      } else {
        inlineClasses[dep] = translated;
      }
      depQueue.addAll(translated.dependencies);
    }
    // ignore: avoid_print - 构建期日志
    print(
      '[hot_patch_generator] $inputId: '
      '${exportedClasses.map((c) => c.name).join(', ')}',
    );

    // 一次渲染合并产物：一个文件 → 一个同名 JS（注册多个组件）。
    // 跨文件依赖（模型/组件）→ dependencyImports（ES module import）；
    // 同文件普通类上面已递归翻译为 inline class（不 export）。
    final crossModels = <String, ClassInfo>{};
    void collectModelDeps(Iterable<String> deps) {
      for (final name in deps) {
        final model = classTable[name];
        if (model == null || model.isComponent) continue;
        if (model.sourceFile != inputId.path) crossModels[name] = model;
      }
    }

    for (final c in exportedClasses) {
      collectModelDeps(c.dependencies);
    }
    for (final c in inlineClasses.values) {
      collectModelDeps(c.dependencies);
    }
    for (final e in extensions) {
      collectModelDeps(e.dependencies);
    }

    final dependencyImports = <String>[];
    // 跨文件模型（export class，运行时按相对路径加载并全局共享一份）
    for (final m in crossModels.values) {
      dependencyImports.add(
        "import { ${m.name} } from "
        "'${relativeProduct(ownProduct, productPath(m.sourceFile))}';",
      );
    }
    // 跨文件组件：build 树 / 普通类方法体里的自定义组件、且产物在其他文件。
    // 同文件组件（importResolver 返回本产物名）已是产物内 export class，无需
    // import；null（无 JS 产物的普通组件）走原生注入。
    final importedComponents = <String>{};
    void collectComponentImports(Iterable<String> deps) {
      for (final dep in deps) {
        if (importedComponents.contains(dep)) continue;
        final rel = importResolver(dep);
        if (rel == null || rel == ownName) continue;
        importedComponents.add(dep);
        dependencyImports.add("import { $dep } from '$rel';");
      }
    }

    for (final c in exportedClasses) {
      collectComponentImports(c.dependencies);
    }
    for (final c in inlineClasses.values) {
      collectComponentImports(c.dependencies);
    }
    for (final e in extensions) {
      collectComponentImports(e.dependencies);
    }

    // 扩展目标类的 import（目标类在别的产物里时，注册语句直接传构造函数）。
    for (final e in extensions) {
      if (e.targetImport != null) dependencyImports.add(e.targetImport!);
    }

    // 本文件**使用**到的扩展：注册语句在扩展声明文件的产物里，因此那个产物
    // 必须被加载——Dart 里要用扩展就得 import 声明它的库，这里按同一套 import
    // 图（含 barrel 的 export 转发）反查声明了 extension 的源文件，import 其扩展
    // 常量（导入即触发 `__jsExtension(...)`）。
    //   - 项目文件 → 该文件自身的产物（`patch/a/b.js`）；
    //   - 本地依赖包 → `patch/extensions/<pkg>.js`（一包一个，按需加载）。
    //
    // **只用「用到」的扩展**：import 了扩展文件但整个文件没调用它时，不产生
    // 任何 import（否则每次加载本模块都要白注册一批原型成员）。判据见
    // [extensionCallSiteNames] / [identifierNamesIn]——宽松命中，多导入不会漏。
    final usedIdentifiers =
        identifierNamesInProduct(parsed.unit, inputId.path);
    final extNamesByProduct = <String, Set<String>>{};
    for (final file in extensionScopeFiles(parsed.unit, inputId.path)) {
      final imported = parseUnitFile(file);
      if (imported == null) continue;
      // 扩展声明就在本文件里：产物自己会注册，无需 import 自己。
      final names = <String>{
        for (final decl in extensionDeclarations(imported))
          if (decl.name?.lexeme case final n?
              when n.isNotEmpty &&
                  file != inputId.path &&
                  extensionCallSiteNames(decl).intersection(usedIdentifiers)
                      .isNotEmpty)
            n,
      };
      if (names.isEmpty) continue;
      final owner = packageNameOf(file);
      final product =
          owner == null ? productPath(file) : extensionModulePath(owner);
      (extNamesByProduct[product] ??= <String>{}).addAll(names);
    }
    for (final e in extNamesByProduct.entries) {
      final names = e.value.toList()..sort();
      dependencyImports.add("import { ${names.join(', ')} } from "
          "'${relativeProduct(ownProduct, e.key)}';");
    }

    // 顶层常量：本文件常量内联进产物（见 _renderJsProduct），引用到的跨文件常量
    // 与「常量里构造的跨文件模型」→ import。按源文件聚合，与上面的 import 合并
    // 后统一去重。
    final constImportsByFile = <String, Set<String>>{};
    _addConstImports(constImportsByFile, constResolver,
        referencedImportedConsts(parsed.unit, constResolver));
    _addClassImports(
        constImportsByFile, classTable, constResolver.sameFileConstClasses);
    dependencyImports.addAll(_importLines(constImportsByFile, ownProduct));
    final dedupedImports = <String>[];
    for (final line in dependencyImports) {
      if (!dedupedImports.contains(line)) dedupedImports.add(line);
    }

    // 翻译阶段（含三目/if/for 内联渲染）已收集的类型并入渲染期总表。
    final allTranslated = [...exportedClasses, ...inlineClasses.values];
    final extraUsedWidgets = <String, Set<String>>{};
    for (final c in allTranslated) {
      _mergeUsedWidgets(extraUsedWidgets, c.usedWidgetPackages);
    }
    for (final e in extensions) {
      _mergeUsedWidgets(extraUsedWidgets, e.usedWidgetPackages);
    }

    final jsOutput = buildStep.allowedOutputs.first;
    await buildStep.writeAsString(
      jsOutput,
      _renderJsProduct(
        inputId.path,
        exportedClasses: exportedClasses,
        inlineClasses: inlineClasses.values.toList(),
        consts: constResolver.sameFile,
        globalConsts: globalConsts,
        dependencyImports: dedupedImports,
        extraUsedWidgets: extraUsedWidgets,
        wrapperClasses: wrapperClasses,
        importResolver: importResolver,
        extensions: extensions,
        baseClassOf: (c) => jsBaseClassOf(c, classTable),
      ),
    );
  }
}

/// 文件级产物入口：一个 Dart 源文件的全部类 → 一个同名 JS 产物（ES module 文本）。
///
/// 组件文件与非组件（模型）文件走**同一入口**，差异全部数据驱动：
///   - [inlineClasses]：本产物内共享的类（不 export），组件文件里的同文件模型；
///   - [exportedClasses]：对外产出的类（`export class`）——组件与普通模型类
///     走同一条渲染路径；
///   - [dependencyImports]：跨文件依赖的 import 行（组件文件与模型文件都可能非空）；
///   - [consts]：本文件顶层常量（名字 → 已译 JS 值）→ `export const X = ...;`
///     内联在产物顶部，`_` 开头的私有名不 export；[globalConsts] 为全部可见常量名
///     （同文件 + import 文件），供方法体内的常量引用解析。
/// 所有类统一由 [dart2js] 渲染：字段初值、方法体、getter、builder 子树都已由
/// [translateClass] 在收集阶段译好，因此没有「组件渲染 / 模型渲染」两条分支——
/// 新增类结构能力只改收集层与渲染层各一处。
String _renderJsProduct(
  String sourcePath, {
  required List<ClassInfo> exportedClasses,
  List<ClassInfo> inlineClasses = const [],
  Map<String, String> consts = const {},
  Set<String> globalConsts = const {},
  List<String> dependencyImports = const [],
  Map<String, Set<String>> extraUsedWidgets = const {},
  List<String> wrapperClasses = const [],
  String? Function(String component)? importResolver,
  List<ExtensionInfo> extensions = const [],
  String? Function(ClassInfo cls)? baseClassOf,
}) {
  // 头部（注释 + import 区）：package widget 产物的 import 依赖「实际用到的
  // 类型」，只能在各组件渲染完成后得知，所以先渲染 body 再拼装 import，
  // 见函数末尾。
  final head = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// 由 hot_patch_generator 从 $sourcePath 自动生成')
    ..writeln('// 重新生成：dart run build_runner build')
    ..writeln();

  // 跨文件依赖：import（ES module 语法；flutter_js 无原生 module 支持，
  // 运行时 JsRuntimeManager 模块加载器按相对路径解析并预置 __modules）。
  for (final line in dependencyImports) {
    head.writeln(line);
  }

  // body：各类主体（不动 import 区；末尾拼装）。
  final b = StringBuffer();

  // 各 package 实际用到的 widget 类型（渲染期收集）：末尾据此为每个 package
  // 拼一条 import（`import { Text } from '../flutter.js'`）。
  final usedWidgets = <String, Set<String>>{};
  _mergeUsedWidgets(usedWidgets, extraUsedWidgets);

  // 本文件顶层常量：内联在产物顶部（`export const kBanners = [...]`），供本产物
  // 内的类与其它产物按名引用。私有常量不 export（仅本产物内可见）。
  if (consts.isNotEmpty) {
    b
      ..writeln()
      ..write(renderTopLevelConstBody(consts));
  }

  // 本产物内的全部类：inline（不 export）+ 对外类，按**基类在前**排序输出。
  // `class` 声明有 TDZ（`class A extends B` 在 B 之前求值会 ReferenceError），
  // 而 Dart 不要求基类先声明，故渲染前做一次稳定拓扑排序——编译期解决，
  // 运行时不引入任何装配函数。
  final orderedClasses = orderClassesByBase(
    [...inlineClasses, ...exportedClasses],
    (c) => baseClassOf?.call(c),
  );
  final exportedNames = {for (final c in exportedClasses) c.name};
  for (final cls in orderedClasses) {
    final exported = exportedNames.contains(cls.name);
    b
      ..writeln()
      ..writeln(
        '// ${cls.isComponent ? '组件' : '模型'} ${cls.name}'
        '${exported ? '' : '（同文件，仅本产物内可见）'}',
      )
      ..writeln(dart2js(
        cls,
        exported: exported,
        baseClass: baseClassOf?.call(cls),
      ));
  }

  // 本文件声明的 `extension`：注册语句写在声明处（求值本产物即注册成员）。
  for (final ext in extensions) {
    b
      ..writeln()
      ..writeln('// 扩展 ${ext.name.isEmpty ? '<unnamed>' : ext.name}')
      ..writeln(ext.toJs());
  }

  // `@PatchIgnore(isComponent: true)`：类本身不翻译，但在**它自己的源文件产物**
  // 里生成同名包装类（构造即 `__h('类名', props)`，宿主持久化后由原生实现渲染），
  // 使用方按 Dart 一比一 `new 类名({...})` 构造。私有类不 export（只在本产物可见）。
  for (final type in wrapperClasses) {
    b
      ..writeln()
      ..writeln('// 原生组件包装 $type（@PatchIgnore(isComponent: true)）')
      ..writeln(hostWrapperSource(type, exported: !type.startsWith('_')));
  }

  // 按 package 拼装模块 import：只 import **有 JS 类的类型**（`Builder` /
  // `ChangeNotifierProvider` / sliver 代理等），元素写成 `__h(Builder, ...)`
  // 需要类引用。宿主 widget 的元素 type 是字符串字面量（`__h('Text', ...)`），
  // 由宿主注册表映射，无需 import。
  final importsByPackage = <String, Set<String>>{};
  for (final entry in usedWidgets.entries) {
    (importsByPackage[entry.key] ??= <String>{}).addAll(entry.value);
  }
  // 结点工厂 `__h`：只有本产物的 `@PatchIgnore(isComponent: true)` 包装类需要
  // （构造即 `__h('类名', props)`）；其它类统一 `new X(props)`。
  if (wrapperClasses.isNotEmpty) {
    (importsByPackage[nodeHelperPackage] ??= <String>{}).add('__h');
  }
  final ownProduct = productPath(sourcePath);
  final importLines = <String>[
    for (final entry in importsByPackage.entries)
      "import { ${(entry.value.toList()..sort()).join(', ')} } from "
          "'${relativeProduct(ownProduct, packageModulePath(entry.key))}';",
  ]..sort();
  for (final line in importLines) {
    head.writeln(line);
  }

  b.writeln();
  // 写出前统一重排缩进：产物文本只由括号嵌套决定，翻译层改动不再引发
  // 无关产物的纯格式 diff。
  return canonicalizeJsIndent(head.toString() + b.toString());
}

/// 合并「用到的 widget 类型」：dst[package] ∪= src[package]。
void _mergeUsedWidgets(
  Map<String, Set<String>> dst,
  Map<String, Set<String>> src,
) {
  if (src.isEmpty) return;
  for (final e in src.entries) {
    (dst[e.key] ??= <String>{}).addAll(e.value);
  }
}

/// 跨文件顶层常量名 → 按声明源文件归集 import 名（dst[源文件] ∪= {名字}）。
void _addConstImports(
  Map<String, Set<String>> dst,
  TopLevelConstResolver resolver,
  Set<String> names,
) {
  for (final name in names) {
    final file = resolver.sourceFileOf(name);
    if (file != null) (dst[file] ??= <String>{}).add(name);
  }
}

/// 跨文件类名 → 按声明源文件归集 import 名（供数据产物 import 常量里构造的模型）。
void _addClassImports(
  Map<String, Set<String>> dst,
  Map<String, ClassInfo> classTable,
  Set<String> names,
) {
  for (final name in names) {
    final info = classTable[name];
    if (info != null) (dst[info.sourceFile] ??= <String>{}).add(name);
  }
}

/// 按源文件归集的 import 表 → ES module import 行（`import { a, b } from 'x.js';`）。
List<String> _importLines(Map<String, Set<String>> byFile, String ownProduct) => [
      for (final entry in byFile.entries)
        "import { ${(entry.value.toList()..sort()).join(', ')} } from "
            "'${relativeProduct(ownProduct, productPath(entry.key))}';",
    ]..sort();

/// 本文件是否声明了带初始化器的顶层变量（数据文件判据；先探后建，避免为
/// 没有任何常量、也没有类的文件白跑一遍常量解析）。
bool _hasOwnTopLevelConst(CompilationUnit unit) => unit.declarations
    .whereType<TopLevelVariableDeclaration>()
    .expand((d) => d.variables.variables)
    .any((v) => v.initializer != null);