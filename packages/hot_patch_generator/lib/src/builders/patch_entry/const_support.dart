/// 顶层常量（数据文件）支持：识别、跨文件解析、数据产物渲染。
///
/// 与「静态单例类」（[singleton_support]）并列的第二类共享数据：
///   - 静态单例类：一个类把若干 static 字段收成一个 `export const X = {...}`；
///   - 顶层常量：每个 const 各出一条 `export const X = <值>;`，组件产物
///     import 后按名引用（`kBanners`），与 Dart 侧写法一一对应。
///
/// 只声明顶层常量、没有任何类的数据文件（如 `lib/app/service/app_data.dart`）
/// 也产出同名 JS 产物，组件产物才能 import 到这些值。
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../../translator/js_translator.dart';
import '../../translator/source_index.dart';
import 'class_table.dart';

/// 本文件可见的顶层常量表（值已在解析期翻译为 JS）。
class TopLevelConstResolver {
  /// 同文件顶层 const：名字 → JS 值表达式（含私有名，产物内模块级 const）。
  final Map<String, String> sameFile = {};

  /// 跨文件顶层 const：名字 → 声明所在源文件（只收能翻译的公共名）。
  final Map<String, String> importedFileOf = {};

  /// 同文件顶层常量引用到的**跨文件类**名（供数据产物生成 import）。
  final Set<String> sameFileConstClasses = {};

  /// 全部可见名字：注入 [FieldScope.globalConsts]。
  Set<String> get names => {...sameFile.keys, ...importedFileOf.keys};

  /// 跨文件顶层常量的声明源文件；同文件返回 null（直接内联，不 import）。
  String? sourceFileOf(String name) => importedFileOf[name];
}

/// 收集并**翻译**常量：同文件（顶层 const 含私有；外加类的私有 static const）
/// + import 文件（仅顶层公共）。
///
/// 翻译在解析期就完成（不延迟到产物渲染）：只有翻译成功的名字才进入
/// [TopLevelConstResolver.names]（→ 组件里的引用才会被译成同名 JS 常量）。
/// 失败的名字既不出现在产物里、也不会被引用——留一条构建期告警，而不是生成
/// 指向未定义变量的 JS（运行期 ReferenceError）。
TopLevelConstResolver buildTopLevelConstResolver(
  CompilationUnit unit,
  String sourcePath,
  Map<String, ClassInfo> classTable,
) {
  final resolver = TopLevelConstResolver();
  final exprs = <String, Expression>{};
  final importedOf = <String, String>{}; // name → 跨文件来源（同文件不登记）
  // 跨文件私有常量：只能被它自己文件里的公共常量引用，故**不登记为可引用
  // 常量**，但必须进 [exprs] 参与翻译——否则 `'$_img?x'` 这类引用了本文件私有
  // 常量的表达式的翻译会因作用域缺名而失败，并误报「插值片段无法翻译」。
  final foreignPrivate = <String>{};
  // 被解析的跨文件（常量声明文件）：其自身 import 的类也要能被常量值引用到
  // （如 `kMineMenu = [MenuEntry(...)]`——MenuEntry 在 app_models.dart，只被
  // app_data.dart import，组件文件本身不一定直接 import）。
  final foreignUnits = <(CompilationUnit, String)>[];

  void add(CompilationUnit u, String file, {required bool sameFile}) {
    for (final d in u.declarations.whereType<TopLevelVariableDeclaration>()) {
      for (final v in d.variables.variables) {
        final init = v.initializer;
        if (init == null) continue;
        final name = v.name.lexeme;
        if (!sameFile && name.startsWith('_')) {
          if (foreignPrivate.contains(name)) continue;
          foreignPrivate.add(name);
          exprs[name] = init;
          continue;
        }
        if (exprs.containsKey(name)) continue;
        exprs[name] = init;
        if (!sameFile) importedOf[name] = file;
      }
    }
    if (!sameFile) return;
    // 类的**私有 static const** 字段（`static const List<String> _steps = [...]`）：
    // 与顶层常量一样要参与表达式翻译（`_steps.length`、`_menuTints[i % …]`），
    // 产物顶部同样内联为模块级 `const _x = …`。私有名不可能跨文件引用，故只在
    // 同文件收集；跨文件同名常量不冲突。
    //
    // @PatchIgnore 类跳过：该类整体不产出 JS（不翻译、不注册），它的私有 static
    // const 没有任何产物内引用点；照收会让被忽略类的常量经这条旁路漏进产物。
    for (final c in u.declarations.whereType<ClassDeclaration>()) {
      if (findAnnotation(c.metadata, 'PatchIgnore') != null) continue;
      for (final m in c.members.whereType<FieldDeclaration>()) {
        if (!m.isStatic || !m.fields.isConst) continue;
        for (final v in m.fields.variables) {
          final init = v.initializer;
          final name = v.name.lexeme;
          if (init == null || !name.startsWith('_')) continue;
          if (exprs.containsKey(name)) continue;
          exprs[name] = init;
        }
      }
    }
  }

  add(unit, sourcePath, sameFile: true);
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final importUnit = parseUnitFile(file);
    if (importUnit == null) continue;
    add(importUnit, file, sameFile: false);
    foreignUnits.add((importUnit, file));
  }

  // 翻译跨文件常量时补齐「声明文件自身的可见类」：跨文件 const 的值可能引用
  // 其声明文件（而非本组件文件）import 的模型类，本文件的 [classTable] 里没有
  // 这些类，会导致整条常量被判为「不可翻译」。这里按需并入，已有条目优先。
  final effectiveTable = <String, ClassInfo>{...classTable};
  for (final (u, file) in foreignUnits) {
    for (final e in buildClassTable(u, file).entries) {
      effectiveTable.putIfAbsent(e.key, () => e.value);
    }
  }

  // 按依赖序翻译（被引用者先译）：已译成功的名字才作为可引用常量注入作用域，
  // 因此「引用了失败常量」的常量自身也会翻译失败，一并被丢掉。
  final translated = <String, String>{};
  for (final name in _dependencyOrder(exprs)) {
    final js = rhsToJs(
      exprs[name]!,
      FieldScope(globalConsts: translated.keys.toSet()),
      effectiveTable,
    );
    if (js == null) {
      // 跨文件常量由它的声明文件负责翻译与告警，本文件只跳过（避免同一条
      // 告警在每一个 import 它的文件里重复刷屏）。
      if (importedOf.containsKey(name)) continue;
      // ignore: avoid_print - 构建期日志
      print('[hot_patch_generator] 顶层常量 $name 无法翻译，已跳过：'
          '${exprs[name]!.toSource()}');
      continue;
    }
    translated[name] = js;
  }

  // 同文件常量里引用到的跨文件类：数据产物与组件产物都要 import 它们。
  final used = _IdentifierCollector();
  for (final e in translated.entries) {
    if (foreignPrivate.contains(e.key)) continue;
    if (!importedOf.containsKey(e.key)) exprs[e.key]!.accept(used);
  }
  resolver.sameFileConstClasses.addAll([
    for (final e in classTable.entries)
      if (!e.value.isComponent &&
          e.value.sourceFile != sourcePath &&
          used.names.contains(e.key))
        e.key,
  ]);

  for (final e in translated.entries) {
    if (foreignPrivate.contains(e.key)) continue; // 只作作用域，不进产物
    final file = importedOf[e.key];
    if (file == null) {
      resolver.sameFile[e.key] = e.value; // 同文件：内联（保持依赖序）
    } else {
      resolver.importedFileOf[e.key] = file; // 跨文件：import
    }
  }
  return resolver;
}

/// 本文件里**实际引用到**的跨文件顶层常量（按名匹配，用于生成 import）。
///
/// 按名匹配（而非精确到翻译结果）是有意的：多 import 一条无害，少 import
/// 一条会让产物在运行时 ReferenceError。
Set<String> referencedImportedConsts(
  CompilationUnit unit,
  TopLevelConstResolver resolver,
) {
  if (resolver.importedFileOf.isEmpty) return const {};
  final used = _IdentifierCollector();
  unit.accept(used);
  return resolver.importedFileOf.keys.where(used.names.contains).toSet();
}

/// 顶层常量 → 数据产物 JS 文本（无可用常量时返回空串）。
///
/// [consts] 为同文件顶层常量（名字 → 已译 JS 值）；[imports] 为已拼好的 import 行。
String renderTopLevelConstProduct(
  String sourcePath, {
  required Map<String, String> consts,
  List<String> imports = const [],
}) {
  final body = renderTopLevelConstBody(consts);
  if (body.isEmpty) return '';
  final head = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// 由 hot_patch_generator 从 $sourcePath 自动生成')
    ..writeln('// 重新生成：dart run build_runner build')
    ..writeln();
  for (final line in imports) {
    head.writeln(line);
  }
  head.writeln();
  return head.toString() + body;
}

/// 顶层常量 → JS 声明块（`export const X = <值>;`；`_` 开头的私有名不 export）。
String renderTopLevelConstBody(Map<String, String> consts) {
  final b = StringBuffer();
  for (final e in consts.entries) {
    final prefix = e.key.startsWith('_') ? '' : 'export ';
    b.writeln('${prefix}const ${e.key} = ${e.value};');
  }
  return b.toString();
}

/// 依赖序：被本文件其它常量引用到的先出（JS `const` 有 TDZ，Dart 的 const 前向
/// 引用合法，照搬声明序会在前向引用时抛 ReferenceError）。
List<String> _dependencyOrder(Map<String, Expression> consts) {
  final out = <String>[];
  final done = <String>{};
  void visit(String name) {
    if (done.contains(name)) return;
    done.add(name);
    final init = consts[name];
    if (init != null) {
      final refs = _IdentifierCollector();
      init.accept(refs);
      for (final dep in refs.names) {
        if (consts.containsKey(dep)) visit(dep);
      }
    }
    out.add(name);
  }

  for (final name in consts.keys) {
    visit(name);
  }
  return out;
}

/// 收集表达式 / 文件里出现的全部标识符名。
class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => names.add(node.name);
}