/// 源码索引：注解识别与 import 源文件解析（Dart 源码静态解析的公共基础）。
///
/// 识别类上的注解、把 import directive 解析成 lib 相对源文件路径——翻译入口
/// （[translateClass]）与 `@HostInjected` 扫描（host_injected.dart）都复用这里的
/// 实现，避免各自重复解析。产物路径推导等构建层逻辑也复用同一份。
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'package_sources.dart';

/// 源文件身份的两种形态：
///   - `lib/a/b.dart`：**本项目包内**的包相对路径（顶层数字字面量身份）；
///   - `package:foo/a/b.dart`：**跨包**源文件身份（本地依赖包里的文件），
///     由 [PackageSources] 经 `.dart_tool/package_config.json` 定位。
///
/// 产物路径（[productPath]）与 import 发射都按这两种身份各自推导。
bool isPackageIdentity(String path) => path.startsWith('package:');

/// `package:foo/x.dart` → 包名；非跨包身份返回 null。
String? packageNameOf(String path) {
  if (!isPackageIdentity(path)) return null;
  final slash = path.indexOf('/');
  if (slash <= 'package:'.length) return null;
  return path.substring('package:'.length, slash);
}

/// lib 相对路径 → (mtime, CompilationUnit) 进程级备忘。
///
/// 一个组件文件的翻译里，类表（class_table）、@HostInjected 扫描
/// （host_injected）、跨文件常量（const_support）、静态单例
/// （singleton_support）、产物路径（product_path）会对**同一份** import 源
/// 文件各自 parseString——多组件构建时是 O(组件数 × 扫描器数 × import数）
/// 的重复解析。这里统一按路径缓存，消除重复。
///
/// mtime 兜底 watch 模式的正确性：源文件变更后修改时间变化，缓存自动失效
/// （AST 本身不可变，同一份内容可安全共享）。
final Map<String, (DateTime, CompilationUnit)> _unitFileCache = {};

/// 源文件身份 → 磁盘绝对路径；定位不到返回 null。
///
/// 本项目包内身份（`lib/...`）直接用（构建工作目录即包根）；跨包身份
/// （`package:foo/x.dart`）经 package_config 里的该包 lib 目录解析。
String? sourceFileOf(String path) {
  if (!isPackageIdentity(path)) return path;
  return PackageSources.instance?.fileOfPackageUri(path);
}

/// 按源文件身份解析 Dart 源文件（带缓存）；文件不存在返回 null。
CompilationUnit? parseUnitFile(String path) {
  final file = sourceFileOf(path);
  if (file == null) return null;
  final f = File(file);
  if (!f.existsSync()) return null;
  final mtime = f.lastModifiedSync();
  final cached = _unitFileCache[path];
  if (cached != null && cached.$1 == mtime) return cached.$2;
  final unit = parseString(content: f.readAsStringSync()).unit;
  _unitFileCache[path] = (mtime, unit);
  return unit;
}

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

/// 解析类 `with` 子句的 mixin 声明：同文件优先，其次 import 文件（与类表
/// 同一套文件解析与缓存）。返回顺序保持 `with A, B` 的书写顺序（**前者
/// 线性化优先级低**），找不到声明的名字直接跳过（无声丢弃会导致 mixin
/// 方法静默缺失，调用方按需告警）。
///
/// 泛型实参与 `on` 约束不校验：本层只有 parseString 语法树（无 resolution），
/// JS 侧类型已擦除，成员合并即可（见 classInfoOf 的 mixins 参数）。
List<MixinDeclaration> resolveMixinDecls(
  ClassDeclaration decl,
  CompilationUnit unit,
  String sourcePath,
) {
  final wc = decl.withClause;
  if (wc == null) return const [];
  final byName = <String, MixinDeclaration>{};
  void collect(CompilationUnit u) {
    for (final d in u.declarations.whereType<MixinDeclaration>()) {
      byName.putIfAbsent(d.name.lexeme, () => d);
    }
  }

  collect(unit);
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final u = parseUnitFile(file);
    if (u != null) collect(u);
  }
  return [
    for (final t in wc.mixinTypes)
      if (byName.containsKey(t.name2.lexeme)) byName[t.name2.lexeme]!,
  ];
}

/// 不参与翻译的框架包：SDK `flutter` 与运行时 / 注解 / 生成器包——它们的类型
/// 在 JS 侧另有实现（宿主注册表 / 注入类），源码不需要跨包翻译。
const Set<String> nonTranslatedPackages = {
  'flutter',
  'hot_patch',
  'hot_patch_annotations',
  'hot_patch_generator',
};

/// 组件文件的业务 import → 源文件身份列表（见 [isPackageIdentity]）。
///
///   - 相对导入 → 本项目包内身份（`lib/...`）；
///   - `package:<本项目>/...` → 本项目包内身份（同一份文件，身份必须一致）；
///   - `package:<本地依赖包>/...` → 跨包身份；**本地包**（path 依赖 / workspace
///     成员）参与跨包翻译；
///   - 三方宿主包（pub cache）与框架包跳过：其类型在 JS 侧没有等价实现，
///     仍走宿主注入 / 原生占位（用到又无法解析的类在翻译期由调用方出声）。
///
/// `export` 转发（barrel）**递归展开**：barrel 自身没有声明，其可见符号全在
/// export 目标里；不展开的话「经 barrel 引用的类」在类表 / 可见性表里查不到
/// （组件产物会照旧翻译出 `new User(...)` 却没有对应的 JS 类与 import）。
/// import 目标自身不再作为依赖深入（闭包由调用方逐层展开），但它的 export
/// 转发同样展开——`import 'package:x/x.dart'`（barrel）是最常见的引用方式。
List<String> resolveImportFiles(CompilationUnit unit, String sourcePath) {
  final out = <String>[];
  final visited = <String>{};
  // 已扫描过 export 的文件（防循环 barrel）。
  final scanned = <String>{};
  // 加入一个直接依赖（import / export 目标）；与 followExports 相互递归。
  late final void Function(String target) addTarget;

  // 展开一个文件的 export 转发链：barrel 自身没有声明，其可见符号全在
  // export 目标里。import 目标的 export 同样要展开（`import` 一个 barrel
  // 是常见写法，不展开就查不到经 barrel 暴露的类）。
  void followExports(CompilationUnit u, String path) {
    if (!scanned.add(path)) return;
    for (final uri in _directiveUris(u, isExport: true)) {
      final target = _resolveDirective(uri, path);
      if (target != null) addTarget(target);
    }
  }

  // import 目标：直接依赖，本层不深入（依赖闭包由调用方逐层展开），
  // 但其 export 转发要展开。
  addTarget = (target) {
    if (!visited.add(target)) return;
    out.add(target);
    final t = parseUnitFile(target);
    if (t != null) followExports(t, target);
  };

  for (final uri in _directiveUris(unit, isExport: false)) {
    final target = _resolveDirective(uri, sourcePath);
    if (target != null) addTarget(target);
  }
  followExports(unit, sourcePath);
  return out;
}

/// 本文件的 import（[isExport] 为 false）或 export（true）目标 URI。
List<String> _directiveUris(CompilationUnit unit, {required bool isExport}) {
  final out = <String>[];
  for (final d in unit.directives) {
    if (isExport ? d is! ExportDirective : d is! ImportDirective) continue;
    final uri = (d as NamespaceDirective).uri.stringValue;
    if (uri != null) out.add(uri);
  }
  return out;
}

/// import / export URI → 源文件身份；不参与翻译的（`dart:` / 框架包 / 三方
/// 宿主包 / 非法 URI）返回 null。
String? _resolveDirective(String uri, String sourcePath) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:')) {
    final idx = uri.indexOf('/');
    if (idx <= 0 || idx >= uri.length - 1) return null;
    final pkg = uri.substring('package:'.length, idx);
    if (nonTranslatedPackages.contains(pkg)) return null;
    final rel = uri.substring(idx + 1);
    if (!rel.endsWith('.dart')) return null;
    // 本项目包自身的 `package:` 引用：身份必须与相对导入一致（`lib/...`）。
    if (pkg == PackageSources.instance?.projectName) return 'lib/$rel';
    if (PackageSources.instance?.isLocalPackage(pkg) != true) return null;
    return 'package:$pkg/$rel';
  }
  return _relativeSource(uri, sourcePath);
}

/// 相对 URI（`'foo.dart'` / `'./foo.dart'` / `'../x.dart'`）→ 源文件身份。
///
/// 本项目包内身份为 `lib/...`，跨包身份为 `package:<pkg>/...`——两者都按
/// 「目录逐级」回退（`..` 一级一级删，不能把整段目录当一个 segment）。
String? _relativeSource(String uri, String sourcePath) {
  var prefix = 'lib/';
  var rel = sourcePath;
  if (isPackageIdentity(sourcePath)) {
    final slash = sourcePath.indexOf('/', 'package:'.length);
    if (slash <= 0) return null;
    prefix = sourcePath.substring(0, slash + 1);
    rel = sourcePath.substring(slash + 1);
  } else if (rel.startsWith('lib/')) {
    rel = rel.substring('lib/'.length);
  }
  final slash = rel.lastIndexOf('/');
  final dir = slash >= 0 ? rel.substring(0, slash + 1) : '';
  final segments = <String>[
    for (final s in dir.split('/'))
      if (s.isNotEmpty) s,
  ];
  for (final part in uri.split('/')) {
    if (part == '.' || part.isEmpty) continue;
    if (part == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else {
      segments.add(part);
    }
  }
  final path = segments.join('/');
  return path.endsWith('.dart') ? '$prefix$path' : null;
}