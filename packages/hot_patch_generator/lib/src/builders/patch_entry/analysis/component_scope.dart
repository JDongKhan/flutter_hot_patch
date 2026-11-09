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
/// 文件级遍历在 `@PatchIgnore` 文件处停止（显式退出翻译，产物里保留其类型名
/// 结点、无 JS 类）。
///
/// 符号级闭包从根类出发；`@HostInjected` 类照常参与（类与方法签名仍产出 JS），
/// 其**标注方法的方法体**不参与引用传播——Dart 实现留在宿主，JS 侧只有
/// `_app_host_.invoke(...)`，方法体里 `new Foo()` 的页面不会被连带翻译。
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'analyze_dart_class.dart';
import '../../shared/host_injected.dart';
import '../../shared/source_index.dart';
import '../../shared/source_location.dart';

/// 包内全部 Dart 源码（与 host_register builder 同一扫描口径）。
final Glob _libDartSources = Glob('lib/**.dart');

/// 一次全局扫描的两份结论（同一遍解析得出，避免重复扫包）。
typedef TranslationScope = ({
  /// 文件级可达（asset 路径，如 `lib/app/pages/home_page.dart`）。
  Set<String> reachableFiles,
  /// 符号级「需要产出的类」：文件 → 该类名集合。
  Map<String, Set<String>> neededClasses,
  /// 符号级「需要写进产物的顶层常量」：文件 → 常量名集合。
  /// 只有被会产出的产物引用到的常量才写入，纯数据文件据此决定是否产出。
  Map<String, Set<String>> neededConsts,
  /// 符号级「需要发射的顶层函数」：文件 → 函数名集合。
  /// 只发射被会产出的类 / 常量 / 其它函数引用到的函数，纯应用文件不产出空壳。
  Map<String, Set<String>> neededFunctions,
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
    final parsed = parseString(
      content: content,
      throwIfDiagnostics: false,
      path: id.path,
    );
    registerSource(id.path, content, parsed.lineInfo);
    units[id.path] = parsed.unit;
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
  var needed = _neededClasses(units, reachable);
  var neededFunctions = _neededFunctions(units, reachable, needed);
  var neededConsts = _neededConsts(units, reachable, needed,
      neededFunctions: neededFunctions);
  // 类 / 顶层常量 / 顶层函数互相引用：常量初始化器里 `new M()`、函数体里
  // 构造类或引用常量，而这些类的方法体又可能引用新的常量。「已发射的值」
  // 都要纳入传播，迭代到三个集合不再增长为止（有限集，最多几轮）。
  //
  // 这一步替代了旧实现里「可达文件的**所有**顶层常量都先按依赖标记类」的
  // 保守做法：那个做法会让没人引用的常量（如 App 基础设施的 Zone 配置）
  // 把整个文件拖进产物（app_log_console 就是被这样带出来的）。
  for (var i = 0; i < 10; i++) {
    final nextClasses = _neededClasses(units, reachable,
        neededConsts: neededConsts, neededFunctions: neededFunctions);
    final nextFunctions = _neededFunctions(units, reachable, nextClasses);
    final nextConsts = _neededConsts(units, reachable, nextClasses,
        neededFunctions: nextFunctions);
    final stable = _neededSetsEqual(nextClasses, needed) &&
        _neededSetsEqual(nextConsts, neededConsts) &&
        _neededSetsEqual(nextFunctions, neededFunctions);
    needed = nextClasses;
    neededFunctions = nextFunctions;
    neededConsts = nextConsts;
    if (stable) break;
  }
  return (
    reachableFiles: reachable,
    neededClasses: needed,
    neededConsts: neededConsts,
    neededFunctions: neededFunctions,
  );
}

/// 两个「文件 → 名字集合」产物的等价判断（迭代收敛用）。
bool _neededSetsEqual(Map<String, Set<String>> a, Map<String, Set<String>> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    final other = b[e.key];
    if (other == null || other.length != e.value.length) return false;
    for (final name in e.value) {
      if (!other.contains(name)) return false;
    }
  }
  return true;
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

/// 符号级「需要产出的类」：从根类（+ 已确认要产出的顶层常量 / extension）出发，
/// 沿**类引用**递归——只把真的被会产出的类引用到的类标记为需要。
///
/// 同文件私有类也会入队（产物内 inline 承载，但仍要继续传播它的跨文件引用）。
Map<String, Set<String>> _neededClasses(
  Map<String, CompilationUnit> units,
  Set<String> reachableFiles, {
  /// 已确认要写进产物的顶层常量（文件 → 常量名）。只对它们传播「常量初始化器
  /// 里引用到的类」，避免可达文件里没人引用的常量把整个文件拖进产物。
  Map<String, Set<String>> neededConsts = const {},
  /// 已确认要发射的顶层函数（文件 → 函数名）：函数体里构造 / 引用的类同样要产出。
  Map<String, Set<String>> neededFunctions = const {},
}) {
  // 类声明索引：file → 类名 → 声明（可翻译的类，含私有类）。
  final ownDecls = <String, Map<String, ClassDeclaration>>{};
  // mixin 声明索引：file → mixin 名 → 声明（`mixin` 与 `mixin class` 都算）。
  final ownMixins = <String, Map<String, AstNode>>{};
  // 可见性：file → 类名 → 声明所在文件（本文件含私有 + import 文件的公共类）。
  final visible = <String, Map<String, String>>{};
  for (final e in units.entries) {
    final file = e.key;
    final own = <String, ClassDeclaration>{
      for (final d in e.value.declarations.whereType<ClassDeclaration>())
        if (_translatableDecl(d)) d.name.lexeme: d,
    };
    ownDecls[file] = own;
    final ownMixinMap = <String, AstNode>{
      for (final d in e.value.declarations.whereType<MixinDeclaration>())
        d.name.lexeme: d,
      for (final d in e.value.declarations.whereType<ClassDeclaration>())
        if (d.mixinKeyword != null) d.name.lexeme: d,
    };
    ownMixins[file] = ownMixinMap;
    final owners = <String, String>{
      for (final n in own.keys) n: file,
      for (final n in ownMixinMap.keys) n: file,
    };
    for (final imported in resolveImportFiles(e.value, file)) {
      final unit = units[imported];
      if (unit == null) continue;
      for (final d in unit.declarations.whereType<ClassDeclaration>()) {
        final name = d.name.lexeme;
        // 私有名不可能跨文件引用（与类表同口径）；import 的 show / hide 同样生效。
        if (name.startsWith('_') ||
            !_translatableDecl(d) ||
            !importedSymbolVisible(e.value, file, imported, name)) {
          continue;
        }
        owners.putIfAbsent(name, () => imported);
      }
      for (final d in unit.declarations.whereType<MixinDeclaration>()) {
        final name = d.name.lexeme;
        if (name.startsWith('_') ||
            !importedSymbolVisible(e.value, file, imported, name)) {
          continue;
        }
        owners.putIfAbsent(name, () => imported);
      }
      for (final d in unit.declarations.whereType<ClassDeclaration>()) {
        if (d.mixinKeyword == null) continue;
        final name = d.name.lexeme;
        if (name.startsWith('_') ||
            !importedSymbolVisible(e.value, file, imported, name)) {
          continue;
        }
        owners.putIfAbsent(name, () => imported);
      }
    }
    visible[file] = owners;
  }

  final needed = <String, Set<String>>{};
  final visited = <String>{};
  final queue = <(AstNode, String)>[];

  void mark(String owner, String name, AstNode decl) {
    (needed[owner] ??= <String>{}).add(name);
    if (visited.add('$owner#$name')) queue.add((decl, owner));
  }

  void markVisible(String file, String name) {
    final owner = visible[file]?[name];
    if (owner == null) return;
    final decl = ownDecls[owner]?[name] ?? ownMixins[owner]?[name];
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

  // 种子 2：可达文件里的 **extension**——有 extension 的文件一定产出产物
  // （`registerExtension(...)` 写在声明处，见 component_builder），其方法体引用
  // 到的类必须一起产出，否则注册语句里的 `new M()` 指向不存在的模块。
  for (final file in reachableFiles) {
    final unit = units[file];
    if (unit == null) continue;
    for (final d in unit.declarations.whereType<ExtensionDeclaration>()) {
      for (final name in dependenciesOf(d)) {
        markVisible(file, name);
      }
    }
  }

  // 种子 3：**已经被引用的顶层常量**所依赖的类——常量初始化器里的 `new M()` /
  // 静态调用（如 `kMenu = [MenuEntry(...)]`）需要 M 的产物。
  //
  // 只遍历 [neededConsts] 里的常量：可达文件里没人引用的常量（如 App 基础设施
  // 的 Zone 配置）不能把整个文件拖进产物。枚举没有初始化器依赖，其产出由
  // neededConsts 自身记录，这里不需要传播。
  for (final e in neededConsts.entries) {
    final unit = units[e.key];
    if (unit == null) continue;
    for (final d in unit.declarations.whereType<TopLevelVariableDeclaration>()) {
      for (final v in d.variables.variables) {
        if (!e.value.contains(v.name.lexeme)) continue;
        for (final name in dependenciesOf(v)) {
          markVisible(e.key, name);
        }
      }
    }
  }

  // 种子 4：**已经被发射的顶层函数**体里构造 / 引用的类（`Foo make() => Foo()`）。
  // 与常量同一口径，只看真正会进产物的函数。
  for (final e in neededFunctions.entries) {
    final unit = units[e.key];
    if (unit == null) continue;
    for (final d in unit.declarations.whereType<FunctionDeclaration>()) {
      if (!e.value.contains(d.name.lexeme)) continue;
      for (final name in dependenciesOf(d)) {
        markVisible(e.key, name);
      }
    }
  }

  // 引用闭包：类引用到的其它类（字段类型 / 构造 / 静态调用 / `is`）同样要产出。
  // 每个类只入队一次，有限集，不会无限展开。
  while (queue.isNotEmpty) {
    final (decl, file) = queue.removeLast();
    final unit = units[file];
    if (unit == null) continue;
    // StatefulWidget 的字段 / 方法分布在 widget 类与 State 类两处，合并扫描；
    // mixin 声明本身就是单个节点。
    final nodes = decl is ClassDeclaration
        ? classAndStateDecls(decl, unit)
        : <AstNode>[decl];
    for (final node in nodes) {
      for (final name in dependenciesOf(node)) {
        markVisible(file, name);
      }
      if (node is! ClassDeclaration) continue;
      // mixin 的引用必须按 **mixin 声明所在文件** 的可见表解析，并且 mixin 本身
      // 也要作为「需要产出的类」标记（它在自己的原文件产物里是一个 export class）。
      for (final (ref, mixinFile) in
          resolveMixinDeclRefs(node, unit, file)) {
        (needed[mixinFile] ??= <String>{}).add(ref.name);
        if (visited.add('$mixinFile#${ref.name}')) {
          queue.add((ref.node, mixinFile));
        }
        for (final name in dependenciesOf(ref.node)) {
          markVisible(mixinFile, name);
        }
      }
    }
  }
  return needed;
}

/// 类是否参与翻译与依赖传播：非 `@PatchIgnore`（原生注入）。
///
/// 抽象类**参与**翻译（`abstract class` → 普通 JS class，抽象成员抛错兜底）：
/// 被具体类 `extends` 时，父类的字段初始化器与具体方法必须在 JS 侧存在。
/// `@HostInjected` 类照常参与——类与方法签名仍产出 JS，只有标注方法的**方法体**
/// 改为 `_app_host_.invoke`（其方法体里引用到的类型由 `dependenciesOf` 跳过，
/// 不会进入依赖传播）。
bool _translatableDecl(ClassDeclaration d) =>
    findAnnotation(d.metadata, 'PatchIgnore') == null;

/// 文件里有 `@PatchEntry` 类 → 根文件。
bool _hasComponentAnnotation(CompilationUnit unit) => unit.declarations
    .whereType<ClassDeclaration>()
    .any((d) => findAnnotation(d.metadata, 'PatchEntry') != null);

/// 本文件**产出为空**（没有任何会进产物的承载物）→ 它的 import 不会被任何 JS
/// 产物引用，遍历到此为止。
///
/// 判据与 builder 自身的产出条件对齐，复用 [_translatableDecl]（文件级 / 符号级
/// 同一个类判据，不另写一套）：
///   - 声明了 `extension` → 注册语句就写在声明处，产出；
///   - 有公认可翻译的类（含 `@PatchEntry` 根类）→ 产出；
///   - 其余（`@PatchIgnore` 页）→ 不产出。
bool _isTranslationStop(CompilationUnit unit) =>
    unit.declarations.whereType<ExtensionDeclaration>().isEmpty &&
    unit.declarations.whereType<MixinDeclaration>().isEmpty &&
    !unit.declarations
        .whereType<ClassDeclaration>()
        .any((d) => !d.name.lexeme.startsWith('_') && _translatableDecl(d));

/// 符号级「需要写进产物的顶层常量」：文件 → 常量名集合。
///
/// 与 [_neededClasses] 同一判据（文件可达 + 符号被引用）：从会产出的类与
/// extension 注册语句出发，沿常量引用闭包收集。私有常量只能被同文件引用，
/// 故只有同文件可见表中能查到才算被引用。
///
/// 纯数据文件（无类、只有顶层常量）据此决定是否产出：没有被任何产物引用的
/// 常量不再生成空壳产物（如 `main.dart` 里只被同文件宿主代码使用的常量）。
Map<String, Set<String>> _neededConsts(
  Map<String, CompilationUnit> units,
  Set<String> reachableFiles,
  Map<String, Set<String>> neededClasses, {
  /// 已确认要发射的顶层函数：函数体里引用的常量 / 枚举必须一起进产物，
  /// 否则函数产物里是未定义引用。
  Map<String, Set<String>> neededFunctions = const {},
}) {
  // 可见常量表：同文件含私有名（产物内联）；import 文件只收公共名（私有名
  // 不可能被跨文件引用，与类可见性同口径）。枚举与顶层常量同一口径，
  // 值用 null 初始器表示（枚举值不依赖其它常量）。
  final visible = <String, Map<String, (String, Expression?)>>{};
  for (final e in units.entries) {
    final file = e.key;
    final visibleHere = <String, (String, Expression?)>{};
    for (final d in e.value.declarations.whereType<EnumDeclaration>()) {
      final name = d.name.lexeme;
      visibleHere.putIfAbsent(name, () => (file, null));
    }
    for (final d in e.value.declarations.whereType<TopLevelVariableDeclaration>()) {
      for (final v in d.variables.variables) {
        final init = v.initializer;
        final name = v.name.lexeme;
        if (init == null) continue;
        visibleHere.putIfAbsent(name, () => (file, init));
      }
    }
    for (final imported in resolveImportFiles(e.value, file)) {
      final unit = units[imported];
      if (unit == null) continue;
      for (final d in unit.declarations.whereType<EnumDeclaration>()) {
        final name = d.name.lexeme;
        if (name.startsWith('_') ||
            !importedSymbolVisible(e.value, file, imported, name)) {
          continue;
        }
        visibleHere.putIfAbsent(name, () => (imported, null));
      }
      for (final d in unit.declarations.whereType<TopLevelVariableDeclaration>()) {
        for (final v in d.variables.variables) {
          final init = v.initializer;
          final name = v.name.lexeme;
          if (init == null || name.startsWith('_')) continue;
          if (!importedSymbolVisible(e.value, file, imported, name)) continue;
          visibleHere.putIfAbsent(name, () => (imported, init));
        }
      }
    }
    visible[file] = visibleHere;
  }

  final needed = <String, Set<String>>{};
  final visited = <String>{};

  // 常量引用闭包：被引用的常量写入其声明文件，并继续传播它的初始化器引用
  // （`kA = kB.length` / `kB = [MenuEntry(...)]`）。
  void mark(String file, String name) {
    final hit = visible[file]?[name];
    if (hit == null) return;
    final (owner, init) = hit;
    if (!visited.add('$owner#$name')) return;
    (needed[owner] ??= <String>{}).add(name);
    // 枚举值没有初始化器表达式（不再传播）；顶层常量继续传播其引用。
    if (init == null) return;
    final refs = _ConstRefCollector();
    init.accept(refs);
    for (final dep in refs.names) {
      mark(owner, dep);
    }
  }

  void markAll(String file, AstNode node) {
    final refs = _ConstRefCollector();
    node.accept(refs);
    for (final name in refs.names) {
      mark(file, name);
    }
  }

  // 种子 1：会产出的类（含 `@PatchEntry` 根类）——与 [neededClasses] 同一集合。
  // StatefulWidget 的字段 / 方法分布在 widget 与 State 两处，合并扫描。
  for (final e in neededClasses.entries) {
    final unit = units[e.key];
    if (unit == null) continue;
    for (final d in unit.declarations.whereType<ClassDeclaration>()) {
      if (!e.value.contains(d.name.lexeme)) continue;
      for (final cls in classAndStateDecls(d, unit)) {
        markAll(e.key, cls);
      }
    }
  }

  // 种子 2：extension 注册语句随产物求值（`registerExtension(...)` 写在声明处）。
  for (final file in reachableFiles) {
    final unit = units[file];
    if (unit == null) continue;
    for (final d in unit.declarations.whereType<ExtensionDeclaration>()) {
      markAll(file, d);
    }
  }

  // 种子 3：会发射的顶层函数体里引用的常量 / 枚举（函数产物按名引用它们）。
  for (final e in neededFunctions.entries) {
    final unit = units[e.key];
    if (unit == null) continue;
    for (final d in unit.declarations.whereType<FunctionDeclaration>()) {
      if (!e.value.contains(d.name.lexeme)) continue;
      markAll(e.key, d.functionExpression.body);
    }
  }

  return needed;
}

/// 顶层函数引用闭包：从会产出的类 / 常量出发，只标记真正被引用到的函数。
///
/// 与 [neededConsts] 同一口径：函数体继续向其它函数传播；`main` 入口不参与。
Map<String, Set<String>> _neededFunctions(
  Map<String, CompilationUnit> units,
  Set<String> reachableFiles,
  Map<String, Set<String>> neededClasses,
) {
  // 可见性：file → 函数名 → (声明文件, 声明)。本文件含私有，import 只收公共。
  final visible = <String, Map<String, (String, FunctionDeclaration)>>{};
  for (final e in units.entries) {
    final file = e.key;
    final owners = <String, (String, FunctionDeclaration)>{};
    for (final d in e.value.declarations.whereType<FunctionDeclaration>()) {
      final n = d.name.lexeme;
      if (n == 'main') continue;
      owners[n] = (file, d);
    }
    for (final imported in resolveImportFiles(e.value, file)) {
      final unit = units[imported];
      if (unit == null) continue;
      for (final d in unit.declarations.whereType<FunctionDeclaration>()) {
        final n = d.name.lexeme;
        if (n.startsWith('_') || n == 'main') continue;
        if (!importedSymbolVisible(e.value, file, imported, n)) continue;
        owners.putIfAbsent(n, () => (imported, d));
      }
    }
    visible[file] = owners;
  }

  final needed = <String, Set<String>>{};
  final visited = <String>{};
  void mark(String file, String name) {
    final hit = visible[file]?[name];
    if (hit == null) return;
    final (owner, decl) = hit;
    if (!visited.add('$owner#$name')) return;
    (needed[owner] ??= <String>{}).add(name);
    // 只扫函数体，不扫声明名，避免“自己引用自己”把所有函数都标记进来。
    final refs = _ConstRefCollector();
    decl.functionExpression.body.accept(refs);
    for (final dep in refs.names) {
      mark(owner, dep);
    }
  }

  void markAll(String file, AstNode node) {
    final refs = _ConstRefCollector();
    node.accept(refs);
    for (final name in refs.names) {
      mark(file, name);
    }
  }

  // 种子 1：会产出的类（含 @PatchEntry 根类，State 合并扫描）。
  // neededClasses 已经是「符号级真正要产出的类」；不在产物里的应用壳类不会进来。
  for (final e in neededClasses.entries) {
    final unit = units[e.key];
    if (unit == null) continue;
    for (final d in unit.declarations.whereType<ClassDeclaration>()) {
      if (!e.value.contains(d.name.lexeme)) continue;
      for (final cls in classAndStateDecls(d, unit)) {
        markAll(e.key, cls);
      }
    }
  }
  // 种子 2：顶层常量初始化器不参与函数引用：
  //   Dart const 初始化器不能调用普通顶层函数；把 neededConsts 当种子会把
  //   应用壳（main.dart / app_log_console.dart）里从未进入 JS 的引用拖进来。
  return needed;
}

/// 常量引用收集器：声明 / 表达式里出现的全部标识符名，与常量可见表求交。
///
/// 与 [dependenciesOf] 同口径跳过 `@HostInjected` 方法体——JS 侧方法体只有
/// `_app_host_.invoke(...)`，其中的常量引用不会出现在产物里。
class _ConstRefCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (hostChannelOf(node) != null) return;
    super.visitMethodDeclaration(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => names.add(node.name);
}
