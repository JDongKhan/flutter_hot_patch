/// 源码索引：注解识别与 import 源文件解析（Dart 源码静态解析的公共基础）。
///
/// 识别类上的注解、把 import directive 解析成 lib 相对源文件路径——翻译入口
/// （[translateClass]）与 `@HostInjected` 扫描（host_injected.dart）都复用这里的
/// 实现，避免各自重复解析。产物路径推导等构建层逻辑也复用同一份。
library;

import 'package:analyzer/dart/ast/ast.dart';

/// 在注解列表里按**简单名**查找注解（支持 `@Foo` 与 `@a.Foo` 两种写法）。
Annotation? findAnnotation(List<Annotation> metadata, String simpleName) {
  for (final a in metadata) {
    final name = a.name;
    if (name is SimpleIdentifier && name.name == simpleName) return a;
    if (name is PrefixedIdentifier && name.identifier.name == simpleName) {
      return a;
    }
  }
  return null;
}

/// 判断本文件里名为 [className] 的类是否带 @PatchIgnore。
/// 带注解 → 不参与连带转换（生成器跳过翻译，运行时原生注入）。
bool isIgnoredClass(CompilationUnit unit, String className) {
  for (final d in unit.declarations) {
    if (d is ClassDeclaration && d.name.lexeme == className) {
      return findAnnotation(d.metadata, 'PatchIgnore') != null;
    }
  }
  return false;
}

/// 组件文件的业务 import → lib 相对 dart 路径列表。
/// 相对导入优先；package: 跳过 dart:/flutter 与注解包（hot_patch_annotations / generator）。
List<String> resolveImportFiles(CompilationUnit unit, String sourcePath) {
  final slash = sourcePath.lastIndexOf('/');
  final dir = slash >= 0 ? sourcePath.substring(0, slash + 1) : '';
  final out = <String>[];
  for (final d in unit.directives.whereType<ImportDirective>()) {
    final uri = d.uri.stringValue;
    if (uri == null) continue;
    // 精确匹配：'package:flutter/' 才是 SDK 包，'package:my_app/' 是业务包
    if (uri.startsWith('package:flutter/') ||
        uri.startsWith('package:hot_patch_annotations/') ||
        uri.startsWith('package:hot_patch_generator/') ||
        uri.startsWith('dart:')) {
      continue;
    }
    if (uri.startsWith('package:')) {
      final idx = uri.indexOf('/');
      if (idx <= 0 || idx >= uri.length - 1) continue;
      final rel = uri.substring(idx + 1);
      if (rel.endsWith('.dart')) out.add('lib/$rel');
      continue;
    }
    final rel = _relativeToLib(uri, dir);
    if (rel != null && rel.endsWith('.dart')) out.add('lib/$rel');
  }
  return out;
}

/// 相对导入 uri（'foo.dart' / './foo.dart' / '../x.dart'）→ lib 相对路径。
String? _relativeToLib(String uri, String dir) {
  // 目录按 '/' 拆成**逐级** segment，`..` 才能一级一级回退
  // （否则 'lib/app/pages/' 会整段算作一个 segment，`..` 一次删掉 'app/pages'）。
  final segments = <String>[];
  final base = dir.startsWith('lib/') ? dir.substring('lib/'.length) : dir;
  for (final s in base.split('/')) {
    if (s.isNotEmpty) segments.add(s);
  }
  for (final part in uri.split('/')) {
    if (part == '.' || part.isEmpty) continue;
    if (part == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else {
      segments.add(part);
    }
  }
  return segments.join('/');
}