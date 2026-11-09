/// 源码索引：注解识别与 import 源文件解析（Dart 源码静态解析的公共基础）。
///
/// 识别类上的注解、把 import directive 解析成 lib 相对源文件路径——翻译入口
/// （[translateClass]）与 `@HostInjected` 扫描（host_injected.dart）都复用这里的
/// 实现，避免各自重复解析。产物路径推导等构建层逻辑也复用同一份。
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart' show log;

import 'package_sources.dart';
import 'source_location.dart';

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
/// （host_injected）、跨文件常量（const_support）、产物路径（product_path）
/// 会对**同一份** import 源文件各自 parseString——多组件构建时是
/// O(组件数 × 扫描器数 × import数) 的重复解析。这里统一按路径缓存，消除重复。
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
  final content = f.readAsStringSync();
  final parsed = parseString(content: content);
  // 登记行号信息：构建期告警 / 报错按 AST 结点换算成 `文件:行 | 源码行`。
  registerSource(path, content, parsed.lineInfo);
  // 重新解析过的文件可能改变 import / export 可见性（watch 模式）：让基于
  // 文件命名空间的缓存整体失效，避免沿用旧符号表。
  _parseGeneration++;
  _unitFileCache[path] = (mtime, parsed.unit);
  return parsed.unit;
}

/// 源文件重新解析计数：命名空间类缓存（[exportedSymbolsOf] 等）按它失效。
int _parseGeneration = 0;

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

/// 类是否带 `@PatchIgnore(isComponent: true)`。
///
/// true = 不翻译该类，但在**声明它的源文件产物**里生成同名包装类
/// （`class X extends Component {}`，构造即宿主元素），使用方按 Dart 一比一 `new 类名({...})` 构造；
/// false = 整类忽略（不产出任何 JS 类，引用它的结点直接丢弃）。
bool isIgnoredComponentClass(ClassDeclaration decl) {
  final a = findAnnotation(decl.metadata, 'PatchIgnore');
  if (a == null) return false;
  final args = a.arguments?.arguments;
  if (args == null) return false;
  for (final arg in args) {
    if (arg is NamedExpression && arg.name.label.name == 'isComponent') {
      final value = arg.expression;
      return value is BooleanLiteral && value.value;
    }
  }
  return false;
}

/// 本文件里名为 [className] 的类是否带 `@PatchIgnore(isComponent: true)`。
bool isIgnoredComponentType(CompilationUnit unit, String className) {
  for (final d in unit.declarations.whereType<ClassDeclaration>()) {
    if (d.name.lexeme == className) return isIgnoredComponentClass(d);
  }
  return false;
}

/// 本文件里全部 `@PatchIgnore(isComponent: true)` 的类名（含私有类：包装类
/// 与使用方在同一产物里解析，类名必须原样一致）。
///
/// 给出 [sourcePath] 时扫描**整个库**（根 + part），因为同库声明共享一份产物。
Set<String> ignoredComponentClassNames(
  CompilationUnit unit, [
  String? sourcePath,
]) {
  final out = <String>{};
  final units = sourcePath == null
      ? [(sourcePath ?? '', unit)]
      : libraryUnitsOf(unit, sourcePath);
  for (final e in units) {
    for (final d in e.$2.declarations.whereType<ClassDeclaration>()) {
      if (isIgnoredComponentClass(d)) out.add(d.name.lexeme);
    }
  }
  return out;
}

/// 本文件**可见**（同库 + import 源文件）的「整类忽略」类名：带 `@PatchIgnore`
/// 但 `isComponent` 非 true（不产出任何 JS 类，引用它的结点丢弃）。
///
/// 同库（根 + part）含私有名；跨库只收公共类（私有名不可能被别的库引用）。
Set<String> ignoredClassNamesInScope(CompilationUnit unit, String sourcePath) {
  final out = <String>{};
  void collect(CompilationUnit u, String file, {required bool sameLibraryFile}) {
    for (final d in u.declarations.whereType<ClassDeclaration>()) {
      final name = d.name.lexeme;
      if (!sameLibraryFile) {
        if (name.startsWith('_')) continue;
        if (!importedSymbolVisible(unit, sourcePath, file, name)) continue;
      }
      if (isIgnoredComponentClass(d)) continue; // isComponent: true 有包装类
      if (findAnnotation(d.metadata, 'PatchIgnore') != null) out.add(name);
    }
  }

  for (final e in libraryUnitsOf(unit, sourcePath)) {
    collect(e.$2, e.$1, sameLibraryFile: true);
  }
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final importUnit = parseUnitFile(file);
    if (importUnit != null) collect(importUnit, file, sameLibraryFile: false);
  }
  return out;
}

/// `with` 子句可应用的声明视图（`mixin M {…}` 与 `mixin class M {…}`）。
///
/// 两者 AST 节点不同（[MixinDeclaration] / [ClassDeclaration] + `mixinKeyword`），
/// 但线性化只需要「名字 + 成员 + 原始节点（依赖扫描）」；`mixin class` 同时仍按
/// 普通类产出 JS，两条身份互不影响。
class MixinDeclRef {
  const MixinDeclRef(this.name, this.members, this.node);

  final String name;
  final NodeList<ClassMember> members;
  final AstNode node;
}

/// 解析类 `with` 子句的 mixin 声明：同文件优先，其次 import 文件（与类表
/// 同一套文件解析与缓存）。返回顺序保持 `with A, B` 的书写顺序（**前者
/// 线性化优先级低**），找不到声明的名字直接跳过（无声丢弃会导致 mixin
/// 成员静默缺失，调用方按需告警）。
///
/// 泛型实参与 `on` 约束不校验：本层只有 parseString 语法树（无 resolution），
/// JS 侧类型已擦除，成员按原文件独立产出、由 `with` 的 application 链应用。
///
/// `mixin class`（`ClassDeclaration.mixinKeyword != null`）与 `mixin` 一样可被
/// `with`，故一并收；普通类不参与（Dart 不允许把普通 class 当 mixin）。
List<(MixinDeclRef, String)> resolveMixinDeclRefs(
  ClassDeclaration decl,
  CompilationUnit unit,
  String sourcePath,
) {
  final wc = decl.withClause;
  if (wc == null) return const [];
  final byName = <String, (MixinDeclRef, String)>{};
  void collect(CompilationUnit u, String file, {required bool sameFile}) {
    for (final d in u.declarations) {
      final MixinDeclRef? ref;
      if (d is MixinDeclaration) {
        ref = MixinDeclRef(d.name.lexeme, d.members, d);
      } else if (d is ClassDeclaration && d.mixinKeyword != null) {
        ref = MixinDeclRef(d.name.lexeme, d.members, d);
      } else {
        ref = null;
      }
      if (ref == null) continue;
      // import 的 show / hide：被隐藏的 mixin 无法出现在使用方的 with 子句里。
      if (!sameFile && !importedSymbolVisible(unit, sourcePath, file, ref.name)) {
        continue;
      }
      final entry = (ref, file);
      byName.putIfAbsent(ref.name, () => entry);
    }
  }

  collect(unit, sourcePath, sameFile: true);
  for (final e in libraryUnitsOf(unit, sourcePath)) {
    if (e.$1 != sourcePath) collect(e.$2, e.$1, sameFile: true);
  }
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final u = parseUnitFile(file);
    if (u != null) collect(u, file, sameFile: false);
  }
  return [
    for (final t in wc.mixinTypes)
      if (byName.containsKey(t.name2.lexeme)) byName[t.name2.lexeme]!,
  ];
}

/// 宿主工程的三方 JS 目录（项目根下）：`js/<package>.js`。
///
/// 三方库的 JS 由宿主自己维护（不在生成器 / 运行时包内），文件名即对应的
/// Dart 包名；构建时由 `ui_third_party_js` 原样拷贝到
/// `patch/packages/<package>.js`，业务产物按相对路径 import 该模块。
const String thirdPartyJsRoot = 'js';

/// 三方 JS 模块产物根目录：与本地依赖包产物共用一个 `packages/` 前缀。
const String thirdPartyJsProductsRoot = 'patch/packages';

/// 宿主工程 `js/` 目录下声明的三方包名（= 文件名去掉 `.js`，仅顶层文件）。
///
/// 进程内只扫描一次：构建期间该目录不会变化。
Set<String> get thirdPartyJsPackages =>
    _thirdPartyJsPackages ??= _scanThirdPartyJsPackages();
Set<String>? _thirdPartyJsPackages;

Set<String> _scanThirdPartyJsPackages() {
  final out = <String>{};
  for (final rel in thirdPartyJsFiles) {
    if (rel.contains('/')) continue; // 仅顶层 `<package>.js` 作为包模块
    out.add(rel.substring(0, rel.length - '.js'.length));
  }
  return out;
}

/// 宿主工程 `js/` 下的全部 JS 文件（相对 `js/` 的 POSIX 路径，递归）。
///
/// 构建期由 `ui_third_party_js` 原样拷贝到 `patch/packages/`；用文件系统即索引，
/// 不要求宿主动 `build.yaml` 的 `sources`。进程内只扫描一次。
List<String> get thirdPartyJsFiles => _thirdPartyJsFiles ??= _scanThirdPartyJsFiles();
List<String>? _thirdPartyJsFiles;

List<String> _scanThirdPartyJsFiles() {
  final root = PackageSources.instance?.projectRoot;
  if (root == null) return const [];
  final dir = Directory('$root${Platform.pathSeparator}$thirdPartyJsRoot');
  if (!dir.existsSync()) return const [];
  final out = <String>[];
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.js')) continue;
    final rel = entity.path
        .substring(dir.path.length + 1)
        .replaceAll(Platform.pathSeparator, '/');
    out.add(rel);
  }
  out.sort();
  return out;
}

/// 三方包对应的 JS 模块产物路径（`ui_third_party_js` 的拷贝目标）。
String thirdPartyJsModulePath(String package) =>
    '$thirdPartyJsProductsRoot/$package.js';

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
/// 库视图（`part` / `part of`）按 Dart 语义处理：一个库 = 根文件 + 它的全部
/// `part` 文件，三者共享同一命名空间（含私有名），产物统一落在**根文件**产物；
/// 本函数只返回**跨库**可达文件（库内文件由各 helper 以 sameFile 口径单独扫描）。
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
  // 已扫描过 export 的库根（防循环 barrel）。
  final scanned = <String>{};
  final rootPath = libraryRootPathOf(unit, sourcePath);
  final rootUnit = rootPath == sourcePath ? unit : parseUnitFile(rootPath);
  if (rootUnit == null) return const [];
  // 当前库的文件集合（含私有）：这些文件由调用方按 sameFile 口径处理，
  // 不作为「导入文件」返回，避免私有符号被跨库规则过滤掉。
  final ownLibrary = {
    for (final e in libraryUnitsOf(rootUnit, rootPath)) e.$1,
  };
  late final void Function(String target) addTarget;
  // 加入一个导入目标的**整个库**（根 + parts）；跨库才返回。
  void addLibrary(String targetRoot, CompilationUnit targetUnit) {
    for (final e in libraryUnitsOf(targetUnit, targetRoot)) {
      if (ownLibrary.contains(e.$1)) continue;
      if (visited.add(e.$1)) out.add(e.$1);
    }
  }

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
    final t = parseUnitFile(target);
    if (t == null) return;
    final tRoot = libraryRootPathOf(t, target);
    final tRootUnit = tRoot == target ? t : parseUnitFile(tRoot);
    if (tRootUnit == null) return;
    addLibrary(tRoot, tRootUnit);
    followExports(tRootUnit, tRoot);
  };

  for (final uri in _directiveUris(rootUnit, isExport: false)) {
    final target = _resolveDirective(uri, rootPath);
    if (target != null) addTarget(target);
  }
  followExports(rootUnit, rootPath);
  return out;
}

/// 该文件所属库的根文件身份：`part of` 文件沿声明回推，普通文件即自身。
///
/// `part of 'a.dart'` 按 URI 解析；`part of libName;` 在项目 / 本地依赖包的
/// lib 目录里按 `library libName;` 反查（结果按构建代缓存）。定位失败出声，
/// 该文件按独立库处理，不静默丢弃。
String libraryRootPathOf(CompilationUnit unit, String sourcePath) {
  final hit = _libraryRoots[sourcePath];
  if (hit != null && hit.$1 == _parseGeneration) return hit.$2;
  var root = sourcePath;
  final po = unit.directives.whereType<PartOfDirective>().firstOrNull;
  if (po != null) {
    final uri = po.uri?.stringValue;
    final name = po.libraryName?.name;
    final found = uri != null
        ? _relativeSource(uri, sourcePath)
        : _libraryPathNamed(name);
    if (found == null) {
      log.warning('[hot_patch_generator] $sourcePath: 无法定位 part of 所属库'
          '（${uri ?? name ?? '?'}），按独立库处理');
    } else if (parseUnitFile(found) == null) {
      log.warning('[hot_patch_generator] $sourcePath: part of 指向的库根 $found '
          '无法解析，按独立库处理');
    } else {
      root = found;
    }
  }
  _libraryRoots[sourcePath] = (_parseGeneration, root);
  return root;
}

/// 该文件所属库的全部文件（根在前，part 按声明顺序；含当前文件）。
///
/// 库内文件共享命名空间：调用方扫描声明时应把这里的每个单元都按「同文件」
/// 口径处理（含私有名），而不是按 import 可见性规则过滤。
List<(String, CompilationUnit)> libraryUnitsOf(
  CompilationUnit unit,
  String sourcePath,
) {
  final hit = _libraryUnits[sourcePath];
  if (hit != null && hit.$1 == _parseGeneration) return hit.$2;
  final rootPath = libraryRootPathOf(unit, sourcePath);
  final rootUnit = rootPath == sourcePath ? unit : parseUnitFile(rootPath);
  if (rootUnit == null) {
    final only = [(sourcePath, unit)];
    _libraryUnits[sourcePath] = (_parseGeneration, only);
    return only;
  }
  final out = <(String, CompilationUnit)>[(rootPath, rootUnit)];
  for (final d in rootUnit.directives.whereType<PartDirective>()) {
    final uri = d.uri.stringValue;
    if (uri == null) continue;
    final target = _relativeSource(uri, rootPath);
    if (target == null) {
      log.warning('[hot_patch_generator] $rootPath: part 指令 $uri 无法解析为'
          '源文件，已跳过');
      continue;
    }
    if (out.any((e) => e.$1 == target)) continue;
    final partUnit = parseUnitFile(target);
    if (partUnit == null) {
      log.warning('[hot_patch_generator] $rootPath: part 目标 $target 无法解析，'
          '已跳过');
      continue;
    }
    out.add((target, partUnit));
  }
  _libraryUnits[sourcePath] = (_parseGeneration, out);
  return out;
}

/// 两个文件是否属于同一个库（根相同）。
bool sameLibrary(String a, String b) {
  if (a == b) return true;
  final ua = parseUnitFile(a);
  final ub = parseUnitFile(b);
  if (ua == null || ub == null) return false;
  return libraryRootPathOf(ua, a) == libraryRootPathOf(ub, b);
}

final Map<String, (int, String)> _libraryRoots = {};
final Map<String, (int, List<(String, CompilationUnit)>)> _libraryUnits = {};
final Map<String, (int, String?)> _libraryByName = {};

/// `part of libName;` → 声明该库名的源文件（项目 + 本地依赖包 lib 目录）。
String? _libraryPathNamed(String? name) {
  if (name == null || name.isEmpty) return null;
  final hit = _libraryByName[name];
  if (hit != null && hit.$1 == _parseGeneration) return hit.$2;
  String? found;
  final sources = PackageSources.instance;
  if (sources != null) {
    for (final pkg in sources.packages) {
      final isProject = pkg.name == sources.projectName;
      if (!isProject && !pkg.isLocal) continue;
      if (!pkg.hasLib) continue;
      final dir = Directory(pkg.libDir);
      if (!dir.existsSync()) continue;
      for (final f in dir.listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final rel = f.path
            .substring(pkg.libDir.length + 1)
            .replaceAll(Platform.pathSeparator, '/');
        final id = isProject ? 'lib/$rel' : 'package:${pkg.name}/$rel';
        final u = parseUnitFile(id);
        final lib = u?.directives.whereType<LibraryDirective>().firstOrNull;
        if (lib?.name2?.name == name) {
          found = id;
          break;
        }
      }
      if (found != null) break;
    }
  }
  _libraryByName[name] = (_parseGeneration, found);
  return found;
}

/// 本文件**直接** import / export 的 `package:` 归属包名（含三方宿主包与框架包）。
///
/// 与 [resolveImportFiles] 的口径不同：后者只保留参与跨包翻译的本地包，这里
/// 保留全部 package 名。用途是「源文件 import 了 package:X → X 的 JS 模块必须
/// 被求值」这类产物依赖判定——Dart 里要用某个库的扩展 / 顶层 API，前提就是
/// import 它，所以这是纯源码事实（import 链 + package 归属），与具体成员名无关。
Set<String> importedPackageNames(CompilationUnit unit) => {
      for (final d in unit.directives)
        if (d is NamespaceDirective) ?packageNameOf(d.uri.stringValue ?? ''),
    };

/// 一个**库**导出的公共顶层符号：名字 → 声明文件身份（根文件或 part 文件）。
///
/// 库命名空间 = 根文件声明 + 全部 part 文件声明 + `export` 转发，转发逐层应用
/// `show` / `hide`（见 [directiveAllowsSymbol]）；私有名（`_x`）不导出。barrel 的
/// 转发目标会归到**声明文件**，调用方据此判断符号真正来自哪个源文件。
Map<String, String> exportedSymbolsOf(String file, [CompilationUnit? unit]) {
  final u = unit ?? parseUnitFile(file);
  if (u == null) return const {};
  final rootPath = libraryRootPathOf(u, file);
  final hit = _exportNamespaces[rootPath];
  if (hit != null && hit.$1 == _parseGeneration) return hit.$2;
  final rootUnit = rootPath == file ? u : (parseUnitFile(rootPath) ?? u);
  final out = _libraryNamespace(rootUnit, rootPath, <String>{rootPath});
  _exportNamespaces[rootPath] = (_parseGeneration, out);
  return out;
}

/// 本**库**经 **import** 可见的顶层符号：名字 → 声明文件身份。
///
/// 与 [resolveImportFiles] 的文件级可达性互补：这里回答「名字能不能用」。
///   - 库内声明（根 + part）不在表里（调用方按 [libraryUnitsOf] 先扫同库）；
///   - 私有名不跨库可见；
///   - `import ... show / hide` 按组合子过滤（[directiveAllowsSymbol]）；
///   - barrel 的 `export ... show / hide` 逐层过滤，值落到声明文件；
///   - `import ... as p` 的符号不进入未限定名表（调用点按 `p.name` 走模块
///     命名空间，见 `component_builder` 的 prefixProducts）。
Map<String, String> importedSymbolsOf(CompilationUnit unit, String sourcePath) {
  final rootPath = libraryRootPathOf(unit, sourcePath);
  final hit = _importedSymbols[rootPath];
  if (hit != null && hit.$1 == _parseGeneration) return hit.$2;
  final rootUnit = rootPath == sourcePath ? unit : (parseUnitFile(rootPath) ?? unit);
  final out = <String, String>{};
  for (final d in rootUnit.directives.whereType<ImportDirective>()) {
    if (d.prefix != null) continue;
    final uri = d.uri.stringValue;
    if (uri == null) continue;
    final target = resolveDirectiveTarget(uri, rootPath);
    if (target == null) continue;
    final targetUnit = parseUnitFile(target);
    if (targetUnit == null) continue;
    for (final e in exportedSymbolsOf(target, targetUnit).entries) {
      if (!directiveAllowsSymbol(d.combinators, e.key)) continue;
      out.putIfAbsent(e.key, () => e.value);
    }
  }
  _importedSymbols[rootPath] = (_parseGeneration, out);
  return out;
}

/// [name] 是否经 import 对 [sourcePath] 可见，且声明在 [declaringFile]。
///
/// 同一库内的文件（根 ↔ part）共享命名空间，含私有名，恒为 true；跨库按
/// [importedSymbolsOf] 的名字 → 声明文件映射判定。
bool importedSymbolVisible(
  CompilationUnit unit,
  String sourcePath,
  String declaringFile,
  String name,
) {
  if (declaringFile == sourcePath) return true;
  if (sameLibrary(sourcePath, declaringFile)) return true;
  return importedSymbolsOf(unit, sourcePath)[name] == declaringFile;
}

/// `show` / `hide` 组合子是否放行 [name]（Dart 语义：show 是白名单，
/// hide 是黑名单；两种情况都不看清单里的符号是否存在）。
bool directiveAllowsSymbol(NodeList<Combinator> combinators, String name) {
  for (final c in combinators) {
    if (c is ShowCombinator) {
      if (!c.shownNames.any((s) => s.name == name)) return false;
    } else if (c is HideCombinator) {
      if (c.hiddenNames.any((s) => s.name == name)) return false;
    }
  }
  return true;
}

/// 每个源文件（含 export 转发链）的公共顶层符号：名字 → 声明文件身份。
/// 随 [_parseGeneration] 失效，watch 模式下被改动的文件不会沿用旧命名空间。
final Map<String, (int, Map<String, String>)> _exportNamespaces = {};

/// 每个导入方文件的可见符号表，失效规则同 [_exportNamespaces]。
final Map<String, (int, Map<String, String>)> _importedSymbols = {};

/// 符号名缓存（单位 = 一份 AST，AST 变更即失效）。
final Expando<Set<String>> _declaredNamesCache = Expando<Set<String>>();

Set<String> _publicTopLevelNames(CompilationUnit unit) =>
    _declaredNamesCache[unit] ??= {
      for (final d in unit.declarations)
        for (final n in _declaredNames(d))
          if (!n.startsWith('_')) n,
    };

/// 一个顶层声明引入的名字（顶层变量可一次声明多个）。
Iterable<String> _declaredNames(CompilationUnitMember d) sync* {
  if (d is ClassDeclaration) {
    yield d.name.lexeme;
  } else if (d is MixinDeclaration) {
    yield d.name.lexeme;
  } else if (d is EnumDeclaration) {
    yield d.name.lexeme;
  } else if (d is ExtensionDeclaration) {
    final n = d.name?.lexeme;
    if (n != null && n.isNotEmpty) yield n;
  } else if (d is TypeAlias) {
    yield d.name.lexeme;
  } else if (d is FunctionDeclaration) {
    yield d.name.lexeme;
  } else if (d is TopLevelVariableDeclaration) {
    for (final v in d.variables.variables) {
      yield v.name.lexeme;
    }
  }
}

/// 一个**库**的导出命名空间：根文件 + 全部 part 的公共声明，再加 `export`
/// 转发（逐层过滤）。每个名字的值是它的**声明文件**（根或某个 part）。
///
/// [visiting] 防 export 环；环上的库只保留本层已收集的声明。
Map<String, String> _libraryNamespace(
  CompilationUnit rootUnit,
  String rootPath,
  Set<String> visiting,
) {
  final out = <String, String>{};
  for (final e in libraryUnitsOf(rootUnit, rootPath)) {
    for (final n in _publicTopLevelNames(e.$2)) {
      out.putIfAbsent(n, () => e.$1);
    }
  }
  for (final d in rootUnit.directives.whereType<ExportDirective>()) {
    final uri = d.uri.stringValue;
    if (uri == null) continue;
    final target = resolveDirectiveTarget(uri, rootPath);
    if (target == null) continue;
    final targetUnit = parseUnitFile(target);
    if (targetUnit == null) continue;
    final targetRoot = libraryRootPathOf(targetUnit, target);
    if (!visiting.add(targetRoot)) continue;
    final targetRootUnit =
        targetRoot == target ? targetUnit : parseUnitFile(targetRoot);
    if (targetRootUnit != null) {
      final ns = _libraryNamespace(targetRootUnit, targetRoot, visiting);
      for (final e in ns.entries) {
        if (!directiveAllowsSymbol(d.combinators, e.key)) continue;
        out.putIfAbsent(e.key, () => e.value);
      }
    }
    visiting.remove(targetRoot);
  }
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
///
/// 供构建层判断「带 import 前缀的引用最终落在哪个产物」时复用，避免另写
/// 一套 URI 解析。
String? resolveDirectiveTarget(String uri, String sourcePath) =>
    _resolveDirective(uri, sourcePath);

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