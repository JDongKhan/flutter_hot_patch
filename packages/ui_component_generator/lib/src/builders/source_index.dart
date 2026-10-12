/// 源码索引：注解识别、@HostInjected 方法表、import 源文件解析。
///
/// 这些能力是**构建期静态解析**的公共基础——识别类上的注解、扫描宿主注入
/// 方法、把 import directive 解析成 lib 相对源文件路径。翻译、类表、单例
/// 解析、产物路径推导都复用这里的实现，避免各自重复解析。
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'host_method_scan.dart';

// 注解按简单名查找的实现在最底层的 host_method_scan.dart（@HostInjected 扫描
// 也用它），这里只做再导出，避免同名声明被 barrel 同时导出造成 ambiguous_export。
export 'host_method_scan.dart' show findAnnotation;

/// 类是否声明了带 @HostInjected 的方法（static 宿主注入能力）。
bool classHasHostInjectedMethod(ClassDeclaration d) {
  for (final m in d.members.whereType<MethodDeclaration>()) {
    if (findAnnotation(m.metadata, 'HostInjected') != null) return true;
  }
  return false;
}

/// 收集宿主注入方法表：`类名 → {方法名 → 通道名}`（见 @HostInjected）；
/// 顶层函数挂在空串 key 下（`'' → {函数名 → 通道名}`）。
///
/// 扫描本文件 + import 源文件（调用点能写出来，就必然 import 得到）；
/// 只有 [HostMethodDecl.usable] 的声明进表——与注册清单（host_register_builder）
/// 用同一个扫描器、同一个判定，保证「翻译了的都注册了」，不因两套逻辑分叉。
///
/// 供翻译上下文把调用点整体替换为 `__jsui.host("通道", 参数载荷)`
/// （参数个数、是否具名、返回值类型都不参与判定）。
Map<String, Map<String, String>> buildHostMethods(
  CompilationUnit unit,
  String sourcePath,
) {
  final out = <String, Map<String, String>>{};
  void scan(CompilationUnit u) {
    scanHostMethods(u, (h) {
      if (!h.usable) return;
      (out[h.owner] ??= {})[h.name] = h.channel;
    });
  }

  scan(unit);
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final f = File(file);
    if (!f.existsSync()) continue;
    scan(parseString(content: f.readAsStringSync()).unit);
  }
  return out;
}

/// 判断本文件里名为 [className] 的类是否带 @UIComponentIgnore。
/// 带注解 → 不参与连带转换（生成器跳过翻译，运行时原生注入）。
bool isIgnoredClass(CompilationUnit unit, String className) {
  for (final d in unit.declarations) {
    if (d is ClassDeclaration && d.name.lexeme == className) {
      return findAnnotation(d.metadata, 'UIComponentIgnore') != null;
    }
  }
  return false;
}

/// 组件文件的业务 import → lib 相对 dart 路径列表。
/// 相对导入优先；package: 跳过 dart:/flutter 与注解包（ui_component / generator）。
List<String> resolveImportFiles(CompilationUnit unit, String sourcePath) {
  final slash = sourcePath.lastIndexOf('/');
  final dir = slash >= 0 ? sourcePath.substring(0, slash + 1) : '';
  final out = <String>[];
  for (final d in unit.directives.whereType<ImportDirective>()) {
    final uri = d.uri.stringValue;
    if (uri == null) continue;
    // 精确匹配：'package:flutter/' 才是 SDK 包，'package:my_app/' 是业务包
    if (uri.startsWith('package:flutter/') ||
        uri.startsWith('package:ui_component/') ||
        uri.startsWith('package:ui_component_generator/') ||
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
    final rel = relativeToLib(uri, dir);
    if (rel != null && rel.endsWith('.dart')) out.add('lib/$rel');
  }
  return out;
}

/// 相对导入 uri（'foo.dart' / './foo.dart' / '../x.dart'）→ lib 相对路径。
String? relativeToLib(String uri, String dir) {
  final segments = <String>[];
  if (dir.startsWith('lib/')) {
    // dir 含尾斜杠（'lib/components/'），去掉尾 / 再入段
    final rel = dir.substring('lib/'.length);
    if (rel.endsWith('/')) {
      segments.add(rel.substring(0, rel.length - 1));
    } else {
      segments.add(rel);
    }
  } else {
    segments.add(dir.endsWith('/') ? dir.substring(0, dir.length - 1) : dir);
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