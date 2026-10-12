/// 文件级产物渲染：一个 Dart 源文件的全部类 → 一个同名 JS（ES module）。
///
/// 组件文件与非组件（模型）文件走**同一入口**，差异全部数据驱动——本文件
/// 是「Dart 类 → JS 文本」的最终拼装层，统一委托 [dart2js] 渲染各类声明。
library;

import '../../translator/dart2js.dart';
import '../../translator/js_translator.dart';
import '../../translator/widget2js.dart';

import '../js_widget_defs.dart';
import '../product_path.dart';
import 'singleton_support.dart';

/// 文件级产物入口：一个 Dart 源文件 → 一个同名 JS（ES module）。
///
/// 组件文件与非组件（模型）文件走**同一入口**，差异全部数据驱动：
///   - [inlineClasses]：本产物内共享的类（不 export），组件文件里的同文件模型；
///   - [singletons]：静态单例类 → `export const`；
///   - [exportedClasses]：对外产出的类（`export class`）——组件与普通模型类
///     走同一条渲染路径；
///   - [dependencyImports]：跨文件依赖的 import 行（仅组件文件非空）。
/// 所有类统一由 [dart2js] 渲染、统一带 [WidgetExprRenderer] 上下文：方法体里
/// `return Container(...)` 一律走 widget 翻译路径（普通类里返回 widget 的方法
/// 同样生效），用到的 widget 类型统一收集成 package import。因此没有
/// 「组件渲染 / 模型渲染」两条分支——新增类结构能力只改这一处。
String renderModuleJs(
  String sourcePath, {
  required WidgetTranslatorRegistry registry,
  required List<ClassInfo> exportedClasses,
  List<ClassInfo> inlineClasses = const [],
  List<ClassInfo> singletons = const [],
  Map<String, ClassInfo> classes = const {},
  List<String> dependencyImports = const [],
  Map<String, Set<String>> extraUsedWidgets = const {},
  bool extraUsedNodeHelper = false,
  String? Function(String component)? importResolver,
  Map<String, Map<String, String>> hostMethods = const {},
}) {
  // 头部（注释 + import 区）：widget 模块 import 依赖「实际用到的类型」，
  // 只能在各组件渲染完成后得知，所以先渲染 body 再拼装 import，见函数末尾。
  final head = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// 由 ui_component_generator 从 $sourcePath 自动生成')
    ..writeln('// 重新生成：dart run build_runner build')
    ..writeln();

  // 跨文件依赖：import（ES module 语法；flutter_js 无原生 module 支持，
  // 运行时 JsRuntimeManager 模块加载器按相对路径解析并预置 __modules）。
  for (final line in dependencyImports) {
    head.writeln(line);
  }

  // 统一翻译上下文：所有类共用（组件动作、模型方法同一套）。方法体里
  // `return Container(...)` 走 widget 树翻译路径。
  final ctx = WidgetTranslateContext(
    registry: registry,
    propByField: const {},
    actionByMethod: const {},
    sourcePath: sourcePath,
    importResolver: importResolver,
    jsClassWidgets: jsClassWidgetTypes,
    delegateClassWidgets: sliverBuilderTypes,
  );

  // body：各类主体（不动 import 区；末尾拼装）。
  final b = StringBuffer();

  // 各 package 实际用到的 widget 类型（渲染期收集）：末尾据此为每个 package
  // 拼一条 import（`import { Text } from '../flutter.js'`）。
  final usedWidgets = <String, Set<String>>{};
  mergeUsedWidgets(usedWidgets, extraUsedWidgets);

  // 本产物内共享的类：inline class（不 export，本产物内可见）。
  for (final cls in inlineClasses) {
    b
      ..writeln()
      ..writeln('// 模型 ${cls.name}（同文件，仅本产物内可见）')
      ..writeln(dart2js(cls,
          exported: false,
          classes: classes,
          hostMethods: hostMethods,
          widgetCtx: ctx));
    mergeUsedWidgets(usedWidgets, ctx.usedWidgetPackages);
  }

  // 静态单例类：`export const X = {...}`（运行时按 export 名收集并注册进
  // __modules，跨文件组件才能 `import { MyColors }` 解构拿到；仅 const 会被漏掉）
  for (final cls in singletons) {
    b
      ..writeln()
      ..writeln('// 静态单例类 ${cls.name}')
      ..writeln(dart2js(
        cls,
        exported: true,
        singletonValueRenderer: (f) => singletonFieldValue(f.initializer, ctx),
      ));
  }

  // 对外产出的类：组件与普通类同一条渲染路径。
  // 组件类 export（= Dart 类名）：既作本产物 build 树的元素 type，也供其它
  // 产物 import 后引用；与普通类共用统一入口 dart2js，无工厂包装。
  for (final cls in exportedClasses) {
    b
      ..writeln()
      ..writeln('// ${cls.isComponent ? '组件' : '模型'} ${cls.name}')
      ..writeln(dart2js(
        cls,
        exported: true,
        classes: classes,
        hostMethods: hostMethods,
        widgetCtx: ctx,
      ));
    mergeUsedWidgets(usedWidgets, ctx.usedWidgetPackages);
  }

  // 按 package 拼装模块 import：只 import **有 JS 类的类型**（`Builder` /
  // `ChangeNotifierProvider` / sliver 代理等），元素写成 `__h(Builder, ...)`
  // 需要类引用。宿主 widget 的元素 type 是字符串字面量（`__h('Text', ...)`），
  // 由宿主注册表映射，无需 import。
  final importsByPackage = <String, Set<String>>{};
  for (final entry in usedWidgets.entries) {
    (importsByPackage[entry.key] ??= <String>{}).addAll(entry.value);
  }
  // 结点工厂 `__h`：产物里有元素树（组件 build 树 / 方法体里返回 widget）
  // 才需要，并入其宿主 package（flutter）那一条；纯模型产物不产生多余 import。
  // 组件方法体在生成期译好（标志经 [extraUsedNodeHelper] 带出），内联模型则
  // 由渲染期 [ctx] 收集，两者取「或」。
  if (extraUsedNodeHelper || ctx.usedNodeHelper || usedWidgets.isNotEmpty) {
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
  return head.toString() + b.toString();
}

/// 合并「用到的 widget 类型」：dst[package] ∪= src[package]。
void mergeUsedWidgets(
  Map<String, Set<String>> dst,
  Map<String, Set<String>> src,
) {
  if (src.isEmpty) return;
  for (final e in src.entries) {
    (dst[e.key] ??= <String>{}).addAll(e.value);
  }
}