/// 全量类表：把文件（同文件 + 跨文件 import）的全部公共 Dart 类收集成
/// ClassInfo 索引——**包含** @PatchEntry 组件与 widget 类（打 isComponent
/// 标记）。翻译只有一个入口（translateClass）在这张表里按名字解析依赖。
library;

import 'package:analyzer/dart/ast/ast.dart';

import '../../translator/analyze_dart_class.dart';
import '../../translator/class_info.dart';
import '../../translator/host_injected.dart';
import '../../translator/js_value.dart';
import '../../translator/source_index.dart';

/// 全量「类表」：把一个文件（同文件 + 跨文件 import）的全部公共 Dart 类
/// （非私有 / 非抽象 / 非 @HostInjected）收集成 ClassInfo 索引——**包含**
/// @PatchEntry 组件与 widget 类（打 [ClassInfo.isComponent] 标记）。
///
/// 翻译只有一个入口（[translateClass]）：任意类引用到的名字（字段类型、
/// 方法体构造、build 树自定义组件）都在这张表里按同一规则解析；widget 类
/// 条目标记 isComponent，不作为模型内联、组件类型字段不当模型构造。
Map<String, ClassInfo> buildClassTable(CompilationUnit unit, String sourcePath) {
  // 两阶段：先收集类声明，再据**全量类名表**求每个类的依赖
  // （referencedClassNames 统一在 dart2js 层，builder 不自行计算）。
  // 值里的 CompilationUnit 是类的声明单元（本类 / 所在 import 文件）——
  // 解析 with 子句的 mixin 声明需要它（resolveMixinDecls）。
  final decls = <String, (ClassDeclaration, String, bool, CompilationUnit)>{};
  void addFile(ClassDeclaration d, String file, CompilationUnit from) {
    final name = d.name.lexeme;
    if (name.startsWith('_') || decls.containsKey(name)) return;
    if (d.abstractKeyword != null) return;
    // @HostInjected 类：方法实现留在 Dart，不产出 JS（调用点被翻译为
    // _app_host_.invoke，见 buildHostMethods 与 js_translator.methodCallExprJs）。
    if (classHasHostInjectedMethod(d)) return;
    decls[name] = (d, file, isWidgetClassDecl(d), from);
  }

  for (final d in unit.declarations.whereType<ClassDeclaration>()) {
    addFile(d, sourcePath, unit);
  }
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final importUnit = parseUnitFile(file);
    if (importUnit == null) continue;
    for (final d in importUnit.declarations.whereType<ClassDeclaration>()) {
      addFile(d, file, importUnit);
    }
  }

  final names = decls.keys.toSet();
  final out = <String, ClassInfo>{};
  for (final e in decls.entries) {
    // 普通类同样可能 with mixin：成员合并与依赖发现都按线性化展开，
    // 与组件 State 类同一条路径。
    final mixins = resolveMixinDecls(e.value.$1, e.value.$4, e.value.$2);
    out[e.key] = classInfoOf(
      e.value.$1,
      e.value.$2,
      isComponent: e.value.$3,
      mixins: mixins,
      dependencies:
          referencedClassNames(e.value.$1, mixins: mixins).intersection(names),
    );
  }
  return out;
}

/// 类是否为 widget / 组件类：带 @PatchEntry 注解，或继承
/// StatefulWidget / StatelessWidget / State（State 子类通常私有，已在收集处
/// 排除，这里仅作兜底）。
///
/// 产物判定（本文件根类收集、跨文件产物解析）与翻译层共用这一个口径。
bool isWidgetClassDecl(ClassDeclaration d) {
  if (findAnnotation(d.metadata, 'PatchEntry') != null) return true;
  final sup = d.extendsClause?.superclass;
  if (sup != null) {
    switch (eraseType(sup.toSource())) {
      case 'StatefulWidget':
      case 'StatelessWidget':
      case 'State':
        return true;
    }
  }
  return false;
}