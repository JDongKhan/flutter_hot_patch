/// 组件/模型 builder 的**组件路径**：把含 @UIComponent 的 Dart 源文件翻译为
/// 同名 JS 产物。不含 @UIComponent 的文件交给 model_builder.dart 处理。
library;

import 'dart:async';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';

import '../../translator/builtin_translators.dart';
import '../../translator/class_translator.dart';
import '../../translator/js_translator.dart';
import '../../translator/widget2js.dart';

import '../js_widget_defs.dart';
import '../product_path.dart';
import '../source_index.dart';
import '../ui_host_register/host_method_scan.dart';
import 'class_table.dart';
import 'model_builder.dart';
import 'module_renderer.dart';
import 'singleton_support.dart';

/// 把 lib/ 下的 Dart 源文件翻译为**同名** JS 产物（`lib/a/b.dart` → `patch/a/b.js`）：
/// 文件名与 Dart 源文件一一对应，不区分组件/模型，也不预设目录结构——源码
/// 怎么组织、有哪些目录，由使用方决定，产物跟着走。
///
/// 按**文件内容**分流（与目录无关）：
///   - 含 `@UIComponent` 类 → 组件产物（Component 类 + build + 事件绑定）；
///   - 仅含普通类（非私有、非抽象、无 build()）→ 模型/单例产物
///     （`export class` / `export const`，供组件产物 import）；
///   - 都没有（如 main.dart）→ 不产出。
///
/// 组件本身 100% 正常可用（普通 StatefulWidget）；注解只是构建期元数据，
/// 生成器全程静态解析，不执行任何 Dart 代码。
///
/// # 架构
///
/// ComponentBuilder 只负责「总控」，不含任何翻译分叉：
///   - 扫描 @UIComponent 根类，调唯一入口 translateClass 翻译；
///   - 按 ClassInfo.dependencies 递归：同文件类内联、跨文件类生成 import；
///   - 组装并写出产物（package 模块由 WidgetModuleBuilder 另出）。
///
/// 翻译只有一个入口（class_translator.translateClass）：内部仅判断
/// 「StatefulWidget → 合并同文件 State 类」这一次分叉，组件与普通类的字段 /
/// 方法 / 依赖 / widget 树全部同一条路径。
///
/// 「某个 widget 怎么翻译成 JSON/JS」是策略，由 WidgetTranslator 实现：
///   - 抽象类与注册表见 widget2js.dart
///   - 内置 Column/Row/Text/ElevatedButton 见 builtin_translators.dart
///   - 新增/自定义 widget = 写一个 WidgetTranslator 并 register，
///     核心代码零改动。
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

    // 策略注册表：目前注册内置 widget；业务方可在此扩展自定义 translator。
    final registry = WidgetTranslatorRegistry();
    registerBuiltinTranslators(registry);

    // 按内容分流（与目录无关）：文件里没有 @UIComponent → 模型/单例产物
    // （模型放哪个目录都行）；有 → 组件产物。
    final hasComponent = parsed.unit.declarations
        .whereType<ClassDeclaration>()
        .any((d) => findAnnotation(d.metadata, 'UIComponent') != null);
    // 宿主注入方法表（类名 → {方法名 → 通道名}）：组件与模型两条路径都要用。
    final hostMethods = buildHostMethods(parsed.unit, inputId.path);
    if (!hasComponent) {
      await writeModelProduct(
          buildStep, parsed.unit, inputId, registry, hostMethods);
      return;
    }

    // 组件名 → 依赖产物 jsAsset 路径。规则：
    //   本文件注解组件 / 本文件私有组件 → 本文件产物（同产物注册）；
    //   本文件无注解非私有组件（如 MyCustomCard）→ null（运行时原生注入）；
    //   跨文件组件 → 从 import directives 推导源文件产物。
    // （提前于 components 收集构造：translateClass 内部翻译 Component
    //   节点时即会调用 importResolver，闭包必须已初始化）
    final parsedNames = <String>{
      for (final d in parsed.unit.declarations)
        if (d is ClassDeclaration) d.name.lexeme,
    };
    final annotatedNames = <String>{
      for (final d in parsed.unit.declarations)
        if (d is ClassDeclaration &&
            findAnnotation(d.metadata, 'UIComponent') != null)
          d.name.lexeme,
    };
    // 产物采用**相对路径**（相对当前产物所在目录，如 'bar_component.js'）：
    // 未来 JS 产物整体发布（CDN / 包内迁移）时，主产物与依赖产物的相对关系
    // 不变，运行时按当前 jsAsset 的目录解析即可，绝对路径会随部署位置失效。
    final ownProduct = productPath(inputId.path); // patch/.../x.js
    final ownName = ownProduct.substring(ownProduct.lastIndexOf('/') + 1);
    // 跨文件组件名 → 产物路径（按**类名**精确绑定；见 resolveImportedComponentProducts）。
    final importProducts =
        resolveImportedComponentProducts(parsed.unit, inputId.path);
    String? importResolver(String name) {
      // @UIComponentIgnore：显式「不参与连带转换」的类 → null
      // （保持 Component 节点，运行时原生注入，等价于无注解公共组件路径）。
      if (isIgnoredClass(parsed.unit, name)) return null;
      if (parsedNames.contains(name)) {
        if (annotatedNames.contains(name) || name.startsWith('_')) {
          return ownName;
        }
        return null;
      }
      final abs = importProducts[name];
      if (abs == null) return null;
      return relativeProduct(ownProduct, abs);
    }

    // 全量「类表」：同文件 + 跨文件 import 的所有 Dart 类（公共、非抽象、
    // 非 @HostInjected），组件 / widget 类打 isComponent 标记、普通类与静态
    // 单例不打标。翻译只按名字在这张表里解析依赖（见 class_translator.dart）。
    final classTable = buildClassTable(parsed.unit, inputId.path);

    // 跨文件「静态单例类」映射：照旧，供 build 树里 `MyColors.x` 静态引用
    // 翻译成 JS 表达式（见 style_translators）。产物渲染统一走
    // dart2js（singletonValueRenderer）。
    final singletons = buildSingletonResolver(parsed.unit, inputId.path);

    // 本文件声明的「静态单例类」→ inline 进本产物（const X = {...}，不 import）
    final sameFileSingletonInfos = <ClassInfo>[
      for (final d in findSingletonClasses(parsed.unit))
        if (classTable.containsKey(d.name.lexeme)) classTable[d.name.lexeme]!,
    ];

    // 统一翻译入口：收集本文件内全部 @UIComponent 根组件（支持单文件多组件 /
    // 文件内共享普通类）。JS 类名 = Dart 类名；State 合并与字段/方法/依赖
    // 处理全部在 translateClass 内部完成，builder 不做任何翻译分叉。
    final components = <ClassInfo>[];
    for (final declaration in parsed.unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      if (findAnnotation(declaration.metadata, 'UIComponent') == null) continue;

      components.add(translateClass(
        declaration,
        parsed.unit,
        inputId.path,
        registry: registry,
        classTable: classTable,
        importResolver: importResolver,
        singletons: singletons,
        hostMethods: hostMethods,
        jsClassWidgets: jsClassWidgetTypes,
        delegateClassWidgets: sliverBuilderTypes,
        isComponent: true,
      ));
    }

    // 按依赖关系递归：从根组件的 dependencies 做 BFS——
    //   - 同文件**有产物**的组件（@UIComponent / 私有 _Xxx）→ 翻译进同一产物；
    //   - 同文件普通类（模型/共享类）→ 翻译为产物内可见的 inline class；
    //   - @UIComponentIgnore / 无注解公共组件（importResolver 返回 null）→
    //     保持 Component 节点，运行时原生注入，不产出 JS 类；
    //   - 跨文件依赖 → 不翻译，后面统一生成 import。
    // 普通类里引用到的类与组件走同一套递归（dependencies 是翻译期统一收集的）。
    final inlineClasses = <String, ClassInfo>{};
    final sameFileSingletonNames = {
      for (final c in sameFileSingletonInfos) c.name,
    };
    final doneDeps = <String>{};
    final depQueue = <String>[
      for (final c in components) ...c.dependencies,
    ];
    while (depQueue.isNotEmpty) {
      final dep = depQueue.removeLast();
      if (doneDeps.contains(dep)) continue;
      doneDeps.add(dep);
      if (!parsedNames.contains(dep)) continue; // 跨文件 → import 阶段处理
      // 同文件静态单例类走 const 内联（sameFileSingletonInfos），不按类翻译。
      if (sameFileSingletonNames.contains(dep)) continue;
      if (components.any((c) => c.name == dep) ||
          inlineClasses.containsKey(dep)) {
        continue;
      }
      final decl = parsed.unit.declarations
          .whereType<ClassDeclaration>()
          .firstWhere((d) => d.name.lexeme == dep);
      final tableInfo = classTable[dep];
      final isWidgetDep = tableInfo?.isComponent ?? dep.startsWith('_');
      if (isWidgetDep && importResolver(dep) != ownName) {
        // 无 JS 产物的 widget（无注解公共组件 / @UIComponentIgnore）。
        continue;
      }
      final translated = translateClass(
        decl,
        parsed.unit,
        inputId.path,
        registry: registry,
        classTable: classTable,
        importResolver: importResolver,
        singletons: singletons,
        hostMethods: hostMethods,
        jsClassWidgets: jsClassWidgetTypes,
        delegateClassWidgets: sliverBuilderTypes,
        isComponent: isWidgetDep,
      );
      if (isWidgetDep) {
        components.add(translated);
      } else {
        inlineClasses[dep] = translated;
      }
      depQueue.addAll(translated.dependencies);
    }
    // ignore: avoid_print - 构建期日志
    print(
      '[ui_component_generator] $inputId: '
      '${components.map((c) => c.name).join(', ')}',
    );

    // 一次渲染合并产物：一个文件 → 一个同名 JS（注册多个组件）。
    // 跨文件依赖（模型/单例/组件）→ dependencyImports（ES module import）；
    // 同文件普通类上面已递归翻译为 inline class（不 export）。
    final crossModels = <String, ClassInfo>{};
    void collectModelDeps(ClassInfo c) {
      for (final name in c.dependencies) {
        if (singletons.sourceFileOf(name) != null) continue; // 单例 import 另算
        final model = classTable[name];
        if (model == null || model.isComponent) continue;
        if (model.sourceFile != inputId.path) crossModels[name] = model;
      }
    }

    components.forEach(collectModelDeps);
    inlineClasses.values.forEach(collectModelDeps);

    final dependencyImports = <String>[];
    // 跨文件静态单例类：import（export const 单例对象，运行时注入 __modules 共享）
    for (final cls in singletons.used) {
      final src = singletons.sourceFileOf(cls);
      if (src == null || src == inputId.path) continue;
      dependencyImports.add(
        "import { $cls } from "
        "'${relativeProduct(ownProduct, productPath(src))}';",
      );
    }
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
    void collectComponentImports(ClassInfo c) {
      for (final dep in c.dependencies) {
        if (importedComponents.contains(dep)) continue;
        final rel = importResolver(dep);
        if (rel == null || rel == ownName) continue;
        importedComponents.add(dep);
        dependencyImports.add("import { $dep } from '$rel';");
      }
    }

    components.forEach(collectComponentImports);
    inlineClasses.values.forEach(collectComponentImports);

    // 翻译阶段（含三目/if/for 内联渲染）已收集的类型并入渲染期总表。
    final allTranslated = [...components, ...inlineClasses.values];
    final extraUsedWidgets = <String, Set<String>>{};
    for (final c in allTranslated) {
      mergeUsedWidgets(extraUsedWidgets, c.usedWidgetPackages);
    }

    final jsOutput = buildStep.allowedOutputs.first;
    await buildStep.writeAsString(
      jsOutput,
      renderModuleJs(
        inputId.path,
        registry: registry,
        exportedClasses: components,
        inlineClasses: inlineClasses.values.toList(),
        singletons: sameFileSingletonInfos,
        classes: classTable,
        dependencyImports: dependencyImports,
        extraUsedWidgets: extraUsedWidgets,
        extraUsedNodeHelper: allTranslated.any((c) => c.usedNodeHelper),
        importResolver: importResolver,
        hostMethods: hostMethods,
      ),
    );
  }
}