/// 产物路径推导：源文件 → JS 产物路径、产物间相对路径、跨文件组件产物解析。
///
/// 产物路径与 build.yaml 的 build_extensions 保持一致（`lib/a/b.dart` →
/// `patch/a/b.js`，直接镜像 lib 路径、文件名与源文件同名），不预设固定目录名。
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import '../translator/class_translator.dart';

import 'source_index.dart';

/// 源文件路径 → 产物路径（与 build.yaml 的 build_extensions 一致）：
/// `lib/a/b.dart` → `patch/a/b.js`（**直接镜像 lib 路径、文件名与源文件
/// 同名**，不预设 `components` 之类固定目录名，也不区分组件/模型）。
String productPath(String sourcePath) {
  if (!sourcePath.startsWith('lib/')) return sourcePath;
  final rel = sourcePath.substring('lib/'.length); // a/b.dart
  if (!rel.endsWith('.dart')) return sourcePath;
  return 'patch/${rel.substring(0, rel.length - '.dart'.length)}.js';
}

/// 两个产物绝对路径 → 相对路径（相对第一个产物所在目录）。
/// 如 'patch/foo_component.js' → 'patch/sub/bar_component.js'
/// 得 'sub/bar_component.js'；跨目录时含 '../'。
String relativeProduct(String from, String to) {
  final fromDir = from.substring(0, from.lastIndexOf('/') + 1);
  final fromSegs = fromDir.split('/').where((p) => p.isNotEmpty).toList();
  final toSegs = to.split('/').where((p) => p.isNotEmpty).toList();
  // 公共前缀长度
  var common = 0;
  while (common < fromSegs.length &&
      common < toSegs.length - 1 &&
      fromSegs[common] == toSegs[common]) {
    common++;
  }
  final ups = List.filled(fromSegs.length - common, '..');
  final downs = toSegs.skip(common).toList();
  return [...ups, ...downs].join('/');
}

/// 扫描当前文件 import 的源文件，收集「有 JS 产物的组件类名 → 产物路径」。
///
/// 与 [translateClass] 的连带转换规则一致，「有产物」判定为：
///   - 类带 @UIComponent 注解；或
///   - 私有类（_Xxx）且声明了 build() 方法。
/// 按**类名**绑定（而非「第一条 import」），多 import 文件不会串台；
/// 命中即让 build 树里的 Component 节点渲染成类引用元素并 import 该产物。
Map<String, String> resolveImportedComponentProducts(
  CompilationUnit unit,
  String sourcePath,
) {
  final out = <String, String>{};
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final f = File(file);
    if (!f.existsSync()) continue;
    final parsed = parseString(content: f.readAsStringSync());
    for (final decl in parsed.unit.declarations.whereType<ClassDeclaration>()) {
      final name = decl.name.lexeme;
      final annotated = findAnnotation(decl.metadata, 'UIComponent') != null;
      final privateWithBuild =
          name.startsWith('_') && hasBuildMethod(decl);
      if (!annotated && !privateWithBuild) continue;
      out[name] = productPath(file);
    }
  }
  return out;
}

/// 类（或其 State 类）是否声明了 build() 方法。
bool hasBuildMethod(ClassDeclaration decl) {
  for (final m in decl.members) {
    if (m is MethodDeclaration && m.name.lexeme == 'build') return true;
  }
  return stateClassNameOf(decl) != null;
}