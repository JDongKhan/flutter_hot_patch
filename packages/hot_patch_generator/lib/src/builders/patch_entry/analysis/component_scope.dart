/// 「翻译范围」全局扫描：**文件级可达** + **符号级引用闭包**——确定「哪些文件
/// 的哪些类产出 JS 产物」的唯一判据。
///
/// 两条判据都要满足：
///   1. **[文件级] 可达**：文件里有 `@PatchEntry` 类（根文件，产出全部注解类），
///      或沿 import 链被某个根文件依赖。没被任何注解组件引用的入口页 / 展示页
///      （`main.dart`、`widget_showcase.dart`）不产出 JS，否则会凭空多出空
///      `build()` 的坏产物与大把告警。
///   2. **[符号级] 被引用**：非根文件里**只有真的被「会产出的类」引用到的类**
///      才产出（字段类型 / 方法体构造 / build 树里的自定义组件）。数据的可翻译性
///      由「被引用」决定，与模型类（`model/user.dart`）同理。
///
/// 文件级遍历在两类文件处停止（它们不会出现在任何 JS 产物里，其 import 自然
/// 无需深入）：
///   - `@PatchIgnore` 文件（显式退出翻译，产物里保留其类型名结点、无 JS 类）；
///   - `@HostInjected` 类所在文件（跨库不可见，只在宿主侧实现）。
///
/// 符号级闭包从根类出发，且**不经过 `@HostInjected` 类**（这类类不进类表，其方法
/// 体里 `new Foo()` 在 JS 侧是 `_app_host_.invoke(...)`，不产生 JS 引用）。因此「只在
/// 宿主路由（`AppRouter` 的 @HostInjected 方法）里 `new` 出来的页面」不会被翻译
/// ——依赖链在 @HostInjected 处断掉：`detail_pages.dart` 只有三个 tab 页订单卡
/// 真的用到的 `MiniButton` 与 `kBrand` / `kPrice` 两个常量会产出，`SearchPage` /
/// `PostDetailPage` 等只在宿主方法体里出现的详情页不再跟着翻译。
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'analyze_dart_class.dart';
import '../../shared/host_injected.dart';
import '../../shared/source_index.dart';

/// 包内全部 Dart 源码（与 host_register builder 同一扫描口径）。
final Glob _libDartSources = Glob('lib/**.dart');

/// 一次全局扫描的两份结论（同一遍解析得出，避免重复扫包）。
typedef TranslationScope = ({
  /// 文件级可达（asset 路径，如 `lib/app/pages/home_page.dart`）。
  Set<String> reachableFiles,
  /// 符号级「需要产出的类」：文件 → 该类名集合。
  Map<String, Set<String>> neededClasses,
});

/// 计算当前包内全部源文件（+ 跨包依赖）的翻译范围。
///
/// 每次调用会扫描整包 `lib/**.dart`（`readAsString` 同时登记依赖：被扫描的文件
/// 改动会触发本步骤重跑），因此调用方应只在确实需要判定时调用——带
/// `@PatchEntry` 的根文件不必调用。
Future<TranslationScope> componentTranslationScope(BuildStep buildStep) async {
  final units = <String, CompilationUnit>{};
  await for (final id in buildStep.findAssets(_libDartSources)) {
    // 生成代码（*.g.dart 等）不参与依赖图。
    if (id.path.endsWith('.g.dart')) continue;
    final content = await buildStep.readAsString(id);
    units[id.path] = parseString(
      content: content,
      throwIfDiagnostics: false,
      path: id.path,
    ).unit;
  }
  // 跨包源文件（本地依赖包，见 [resolveImportFiles] 的身份约定）：它们不是本包
  // 资产，`readAsString` 读不到，直接按 package_config 定位读盘（[parseUnitFile]）。
  // 一并纳入依赖图后，「经 barrel 引用的跨包模型 / 组件」才能进入类表与可见性表，
  // 跨包模块（ui_project_module）也正是据此产出 `patch/<package>.js`。
  for (final file in _crossPackageDeps(units)) {
    final unit = parseUnitFile(file);
    if (unit == null) {
      log.warning('[hot_patch_generator] 无法解析跨包源文件 $file：'
          '其中的类不会产出（跨包翻译需保证 package_config 里该包可定位）');
      continue;
    }
    units[file] = unit;
  }

  final reachable = _reachableFiles(units);
  return (
    reachableFiles: reachable,
    neededClasses: _neededClasses(units, reachable),
  );
}

/// 跨包依赖闭包：从项目文件的 import 出发，收集本地依赖包里的源文件身份
/// （跨包文件自身的 import 继续逐层展开）。
///
/// 只收**跨包**文件：项目内文件已由上面的资产扫描读入；三方宿主包与框架包由
/// [resolveImportFiles] 直接过滤掉（其类型在 JS 侧没有等价实现）。
Set<String> _crossPackageDeps(Map<String, CompilationUnit> units) {
  final out = <String>{};
  final seen = <String>{...units.keys};
  final queue = <(CompilationUnit, String)>[
    for (final e in units.entries) (e.value, e.key),
  ];
  while (queue.isNotEmpty) {
    final (unit, path) = queue.removeLast();
    for (final dep in resolveImportFiles(unit, path)) {
      if (!seen.add(dep)) continue;
      if (!isPackageIdentity(dep)) continue; // 项目内文件已读入
      out.add(dep);
      final depUnit = parseUnitFile(dep);
      if (depUnit != null) queue.add((depUnit, dep));
    }
  }
  return out;
}

/// 文件级可达集合：根文件（有 `@PatchEntry` 类）+ 沿 import 链可达的文件。
Set<String> _reachableFiles(Map<String, CompilationUnit> units) {
  final queue = <String>[
    for (final e in units.entries)
      if (_hasComponentAnnotation(e.value)) e.key,
  ];
  final reachable = <String>{};
  while (queue.isNotEmpty) {
    final file = queue.removeLast();
    if (!reachable.add(file)) continue;
    final unit = units[file];
    // 「不参与翻译」的文件仍算可达（自身产出为空，会自行退出），
    // 但不再沿它的 import 深入。
    if (unit == null || _isTranslationStop(unit)) continue;
    for (final imported in resolveImportFiles(unit, file)) {
      if (units.containsKey(imported)) queue.add(imported);
    }
  }
  return reachable;
}

/// 符号级「需要产出的类」：从根类（+ 可达文件的顶层常量初始化器）出发，沿
///**类引用**递归——只把真的被会产出的类引用到的类标记为需要。
///
/// 同文件私有类也会入队（产物内 inline 承载，但仍要继续传播它的跨文件引用）。
Map<String, Set<String>> _neededClasses(
  Map<String, CompilationUnit> units,
  Set<String> reachableFiles,
) {
  // 类声明索引：file → 类名 → 声明（可翻译的类，含私有类）。
  final ownDecls = <String, Map<String, ClassDeclaration>>{};
  // 可见性：file → 类名 → 声明所在文件（本文件含私有 + import 文件的公共类）。
  final visible = <String, Map<String, String>>{};
  for (final e in units.entries) {
    final file = e.key;
    final own = <String, ClassDeclaration>{
      for (final d in e.value.declarations.whereType<ClassDeclaration>())
        if (_translatableDecl(d)) d.name.lexeme: d,
    };
    ownDecls[file] = own;
    final owners = <String, String>{for (final n in own.keys) n: file};
    for (final imported in resolveImportFiles(e.value, file)) {
      final unit = units[imported];
      if (unit == null) continue;
      for (final d in unit.declarations.whereType<ClassDeclaration>()) {
        final name = d.name.lexeme;
        // 私有名不可能跨文件引用（与类表同口径）。
        if (name.startsWith('_') || !_translatableDecl(d)) continue;
        owners.putIfAbsent(name, () => imported);
      }
    }
    visible[file] = owners;
  }

  final needed = <String, Set<String>>{};
  final visited = <String>{};
  final queue = <(ClassDeclaration, String)>[];

  void mark(String owner, String name, ClassDeclaration decl) {
    (needed[owner] ??= <String>{}).add(name);
    if (visited.add('$owner#$name')) queue.add((decl, owner));
  }

  void markVisible(String file, String name) {
    final owner = visible[file]?[name];
    if (owner == null) return;
    final decl = ownDecls[owner]?[name];
    if (decl != null) mark(owner, name, decl);
  }

  // 种子 1：根类（@PatchEntry 注解类）——与 builder 的根类收集同口径。
  for (final e in units.entries) {
    for (final d in e.value.declarations.whereType<ClassDeclaration>()) {
      if (findAnnotation(d.metadata, 'PatchEntry') != null) {
        mark(e.key, d.name.lexeme, d);
      }
    }
  }

  // 种子 2：可达文件顶层常量初始化器里构造的模型类。常量在可达文件里一律产出
  // （见 component_builder 的顶层常量产物路径），其构造出的模型必须跟着产出，
  // 否则数据产物的 import 会指向不存在的类。
  for (final file in reachableFiles) {
    final unit = units[file];
    if (unit == null) continue;
    for (final variable in unit.declarations
        .whereType<TopLevelVariableDeclaration>()
        .expand((d) => d.variables.variables)) {
      for (final name in ctorClassNames(variable.initializer)) {
        markVisible(file, name);
      }
    }
  }

  // 种子 3：可达文件里 extension 的成员引用。扩展的注册语句就写在声明处、
  // 成员体与类方法体走同一条翻译路径，其中构造 / 字段类型引用到的类必须一并
  // 产出——否则扩展产物里的 `import { X }` 会指向不存在的模块。
  // 扩展不能有实例字段，静态字段本身会被译为 JS 静态成员，故一并计入。
  for (final file in reachableFiles) {
    final unit = units[file];
    if (unit == null) continue;
    for (final ext in unit.declarations.whereType<ExtensionDeclaration>()) {
      for (final name in referencedClassNamesInMembers(
        ext.members,
        includeStaticFields: true,
      )) {
        markVisible(file, name);
      }
    }
  }

  // 引用闭包：类里引用到的其它类（字段类型 / 方法体构造 / build 树）同样要产出，
  // 有限集（每个类只入队一次），不会无限展开。
  while (queue.isNotEmpty) {
    final (decl, file) = queue.removeLast();
    final unit = units[file];
    if (unit == null) continue;
    // StatefulWidget 的字段 / 方法分布在 widget 类与 State 类两处，合并扫描。
    for (final cls in classAndStateDecls(decl, unit)) {
      for (final name in referencedClassNames(cls)) {
        markVisible(file, name);
      }
      // mixin 的成员引用必须按 **mixin 声明所在文件** 的可见表解析：`with A`
      // 的类看不见 A 所在文件 import 的模型，但 A 的方法体会被线性化进本产物，
      // 其中的 `new M()` 需要 M 的产物（按本文件的可见表查会漏标）。
      for (final (mixinDecl, mixinFile) in
          resolveMixinDeclRefs(cls, unit, file)) {
        for (final name in referencedClassNamesInMembers(
          mixinDecl.members,
          includeStaticFields: true,
        )) {
          markVisible(mixinFile, name);
        }
      }
    }
  }
  return needed;
}

/// 类是否参与翻译与依赖传播：非抽象、非 `@HostInjected`（方法实现留在宿主侧，
/// 调用点是 `_app_host_.invoke`，不产生 JS 引用）、非 `@PatchIgnore`（原生注入）。
bool _translatableDecl(ClassDeclaration d) =>
    d.abstractKeyword == null &&
    !classHasHostInjectedMethod(d) &&
    findAnnotation(d.metadata, 'PatchIgnore') == null;

/// 文件里有 `@PatchEntry` 类 → 根文件。
bool _hasComponentAnnotation(CompilationUnit unit) => unit.declarations
    .whereType<ClassDeclaration>()
    .any((d) => findAnnotation(d.metadata, 'PatchEntry') != null);

/// 本文件**产出为空**（没有任何 public 可翻译类）→ 它的 import 不会被任何 JS
/// 产物引用，遍历到此为止。判据与 builder 自身的产出条件对齐：
///   - 有 `@PatchEntry` 类 → 根文件，产出；
///   - 有 public 且未被 `@PatchIgnore` / `@HostInjected` 标记的类 → 产出；
///   - 其余（三个 tab 页这类 `@PatchIgnore` 页、宿主能力门面）→ 不产出。
bool _isTranslationStop(CompilationUnit unit) {
  // 声明了 `extension` → 有产出（注册语句就写在声明处），沿它的 import 继续
  // 深入：扩展成员体里可能用到别的类 / 别的扩展文件。
  if (unit.declarations.whereType<ExtensionDeclaration>().isNotEmpty) {
    return false;
  }
  for (final d in unit.declarations.whereType<ClassDeclaration>()) {
    if (findAnnotation(d.metadata, 'PatchEntry') != null) return false;
    final name = d.name.lexeme;
    if (name.startsWith('_') || d.abstractKeyword != null) continue;
    if (_isIgnoredOrHostInjected(d)) continue;
    return false;
  }
  return true;
}

/// 类是否显式退出翻译（`@PatchIgnore`）或只在宿主侧实现
/// （类级 / 方法级 `@HostInjected`）。
bool _isIgnoredOrHostInjected(ClassDeclaration d) =>
    findAnnotation(d.metadata, 'PatchIgnore') != null ||
    findAnnotation(d.metadata, 'HostInjected') != null ||
    d.members
        .whereType<MethodDeclaration>()
        .any((m) => findAnnotation(m.metadata, 'HostInjected') != null);
