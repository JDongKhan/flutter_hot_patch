/// 全量类表：把文件（同文件 + 跨文件 import）的全部公共 Dart 类收集成
/// ClassInfo 索引——**包含** @UIComponent 组件与 widget 类（打 isComponent
/// 标记）。翻译只有一个入口（translateClass）在这张表里按名字解析依赖。
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import '../../translator/dart2js.dart';
import '../../translator/host_injected.dart';
import '../../translator/js_translator.dart';
import '../../translator/source_index.dart';

/// 全量「类表」：把一个文件（同文件 + 跨文件 import）的全部公共 Dart 类
/// （非私有 / 非抽象 / 非 @HostInjected）收集成 ClassInfo 索引——**包含**
/// @UIComponent 组件与 widget 类（打 [ClassInfo.isComponent] 标记）。
///
/// 翻译只有一个入口（[translateClass]）：任意类引用到的名字（字段类型、
/// 方法体构造、build 树自定义组件）都在这张表里按同一规则解析；widget 类
/// 条目标记 isComponent，不作为模型内联、组件类型字段不当模型构造。
Map<String, ClassInfo> buildClassTable(CompilationUnit unit, String sourcePath) {
  // 两阶段：先收集类声明，再据**全量类名表**求每个类的依赖
  // （referencedClassNames 统一在 dart2js 层，builder 不自行计算）。
  final decls = <String, (ClassDeclaration, String, bool)>{};
  void addFile(ClassDeclaration d, String file) {
    final name = d.name.lexeme;
    if (name.startsWith('_') || decls.containsKey(name)) return;
    if (d.abstractKeyword != null) return;
    // @HostInjected 类：方法实现留在 Dart，不产出 JS（调用点被翻译为
    // __jsui.host，见 buildHostMethods 与 js_translator.methodCallExprJs）。
    if (classHasHostInjectedMethod(d)) return;
    decls[name] = (d, file, isWidgetClassDecl(d));
  }

  for (final d in unit.declarations.whereType<ClassDeclaration>()) {
    addFile(d, sourcePath);
  }
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final f = File(file);
    if (!f.existsSync()) continue;
    final parsed = parseString(content: f.readAsStringSync());
    for (final d in parsed.unit.declarations.whereType<ClassDeclaration>()) {
      addFile(d, file);
    }
  }

  final names = decls.keys.toSet();
  return {
    for (final e in decls.entries)
      e.key: classInfoOf(
        e.value.$1,
        e.value.$2,
        isComponent: e.value.$3,
        dependencies: referencedClassNames(e.value.$1).intersection(names),
      ),
  };
}

/// 类是否为 widget / 组件类：带 @UIComponent 注解，或继承
/// StatefulWidget / StatelessWidget / State（State 子类通常私有，已在收集处
/// 排除，这里仅作兜底）。
///
/// 产物判定（本文件根类收集、跨文件产物解析）与翻译层共用这一个口径。
bool isWidgetClassDecl(ClassDeclaration d) {
  if (findAnnotation(d.metadata, 'UIComponent') != null) return true;
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