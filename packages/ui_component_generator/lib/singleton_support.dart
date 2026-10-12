/// 静态单例类：识别、跨文件解析、单例字段取值。
///
/// 「静态单例类」= 普通类（无 @UIComponent、非私有、非抽象）且含至少一个
/// 非私有 static 字段；产物渲染为 `export const X = {...}`，供其它产物 import。
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'js_translator.dart';
import 'source_index.dart';
import 'style_translators.dart';
import 'widget2js.dart';

/// 判断是否「静态单例类」：普通类（无 @UIComponent、非 private、非抽象）、
/// 且含至少一个非 private **static** 字段。
bool isSingletonClass(ClassDeclaration decl) {
  final name = decl.name.lexeme;
  if (name.startsWith('_')) return false;
  if (decl.abstractKeyword != null) return false;
  if (findAnnotation(decl.metadata, 'UIComponent') != null) return false;
  // @HostInjected 类不产出 JS（无同名产物可 import），不登记为静态单例。
  if (classHasHostInjectedMethod(decl)) return false;
  for (final m in decl.members) {
    if (m is FieldDeclaration && m.isStatic) {
      for (final v in m.fields.variables) {
        if (!v.name.lexeme.startsWith('_')) return true;
      }
    }
  }
  return false;
}

/// 收集某文件里声明的全部「静态单例类」（用于无组件文件的单例产物产出）。
List<ClassDeclaration> findSingletonClasses(CompilationUnit unit) => [
      for (final d in unit.declarations.whereType<ClassDeclaration>())
        if (isSingletonClass(d)) d,
    ];

/// 收集类里全部非私有 static 字段名。
Set<String> publicStaticFieldNames(ClassDeclaration decl) {
  final fields = <String>{};
  for (final m in decl.members) {
    if (m is FieldDeclaration && m.isStatic) {
      for (final v in m.fields.variables) {
        if (!v.name.lexeme.startsWith('_')) fields.add(v.name.lexeme);
      }
    }
  }
  return fields;
}

/// 解析「静态单例类」映射（类名 → {非私有 static 字段, sourceFile}）：
/// 同文件的单例类（sourceFile == 当前文件，inline 不 import）与本文件
/// import 的其它文件单例类（独立产物 + import）一并登记。
/// 供 build 树里 `MyColors.background` 这类静态引用翻译与依赖登记使用。
SingletonResolver buildSingletonResolver(
  CompilationUnit unit,
  String sourcePath,
) {
  final resolver = SingletonResolver();
  // 同文件 static 单例类：inline 进本产物（sourceFile == sourcePath，不 import）
  for (final decl in unit.declarations.whereType<ClassDeclaration>()) {
    if (!isSingletonClass(decl)) continue;
    resolver.add(decl.name.lexeme, publicStaticFieldNames(decl), sourcePath);
  }
  // 跨文件 static 单例类：独立产物 + import
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final f = File(file);
    if (!f.existsSync()) continue;
    final parsed = parseString(content: f.readAsStringSync());
    for (final decl in parsed.unit.declarations.whereType<ClassDeclaration>()) {
      if (!isSingletonClass(decl)) continue;
      resolver.add(decl.name.lexeme, publicStaticFieldNames(decl), file);
    }
  }
  return resolver;
}

/// 静态单例字段初始值 → JS 值（返回带引号的 JS 字面量，如字符串
/// `'demo'`、颜色 `'#f5f5f5'`、数字/布尔原样）。支持类型：
/// Color(...) / Colors.xxx（复用颜色求值）、String / int / double / bool
/// 及简单字面量表达式；求不出（如复杂对象）→ 抛 FormatException，
/// 让开发者构建期看到错误，而不是静默得到 undefined（与 Dart 语义一致）。
String singletonFieldValue(Expression? init, WidgetTranslateContext ctx) {
  if (init == null) {
    throw FormatException('static 字段缺少初始化表达式，无法翻译');
  }
  // 颜色：Color(...) / Colors.xxx → '#...'（复用现有颜色求值）
  final c = colorToJson(init, ctx);
  if (c != null) return c;
  // 字符串：单引号字面量（与单例对象内其它值一致）
  if (init is SimpleStringLiteral) return singletonString(init.value);
  // 简单字面量：int / double / bool / 简单二元运算
  final lit = literalToJs(init);
  if (lit != null) return lit;
  throw FormatException(
    '无法把 static 字段初始值翻译成 JS 值: ${init.toSource()}',
  );
}

/// Js单引号字符串字面量。
String singletonString(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  return "'$escaped'";
}