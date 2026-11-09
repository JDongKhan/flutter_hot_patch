/// 顶层常量（数据文件）支持：识别、跨文件解析、数据产物渲染。
///
/// Dart 里「可在 JS 侧共享的数据」有两种来源，本文件负责第二种：
///   - 类（含纯 static 字段的类）：一律翻译成 JS `class`，静态成员就写在
///     类体内（`static f = <init>` / `static m(...)`，见 dart2js 的类声明）；
///   - 顶层常量：每个 const 各出一条 `export const X = <值>;`，组件产物
///     import 后按名引用（`kBanners`），与 Dart 侧写法一一对应。
///
/// 只声明顶层常量、没有任何类的数据文件（如 `lib/app/service/app_data.dart`）
/// 也产出同名 JS 产物，组件产物才能 import 到这些值。
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:build/build.dart' show log;

import '../class_info.dart';
import '../translator/js_translator.dart';
import '../translator/js_value.dart';
import '../../shared/source_index.dart';
import '../../shared/source_location.dart';
import '../../shared/host_injected.dart';
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

  /// 本文件产出的顶层函数名（用于「只有函数的文件」仍产出模块）。
  final Set<String> functionNames = {};

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
  // 枚举：Dart `enum E { a, b }` → 同形 JS 常量对象（成员带 name/index/values）。
  // 枚举值不依赖其它常量，单独收集后并入 translated（同文件内联 / 跨文件 import）。
  final enumJs = <String, String>{};
  final enumFileOf = <String, String>{}; // 跨文件枚举来源
  final importedOf = <String, String>{}; // name → 跨文件来源（同文件不登记）
  // 跨文件私有常量：只能被它自己文件里的公共常量引用，故**不登记为可引用
  // 常量**，但必须进 [exprs] 参与翻译——否则 `'$_img?x'` 这类引用了本文件私有
  // 常量的表达式的翻译会因作用域缺名而失败，并误报「插值片段无法翻译」。
  final foreignPrivate = <String>{};
  // 被解析的跨文件（常量声明文件）：其自身 import 的类也要能被常量值引用到
  // （如 `kMineMenu = [MenuEntry(...)]`——MenuEntry 在 app_models.dart，只被
  // app_data.dart import，组件文件本身不一定直接 import）。
  final foreignUnits = <(CompilationUnit, String)>[];
  // 顶层函数：同文件参与发射；跨文件只登记名字 / 来源，由声明文件自己发射。
  final sameFileFunctions = <String, FunctionDeclaration>{};
  final importedFunctions = <String, String>{};

  void add(CompilationUnit u, String file, {required bool sameFile}) {
    // 枚举 → JS 常量对象。可见性口径与顶层常量一致：同文件含私有名，
    // 跨文件只收公共名。枚举值不依赖其它常量，单独登记后并入 translated。
    for (final d in u.declarations.whereType<EnumDeclaration>()) {
      final name = d.name.lexeme;
      if (!sameFile && name.startsWith('_')) continue;
      if (enumJs.containsKey(name)) continue;
      final js = _enumJs(d, file);
      if (js == null) continue;
      enumJs[name] = js;
      if (!sameFile) enumFileOf[name] = file;
    }
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
    for (final d in u.declarations.whereType<FunctionDeclaration>()) {
      final name = d.name.lexeme;
      // Dart 入口函数不参与补丁翻译（宿主已经启动；翻译它只会产出无效代码）。
      if (name == 'main') continue;
      if (!sameFile && name.startsWith('_')) continue;
      if (exprs.containsKey(name) || enumJs.containsKey(name)) continue;
      if (sameFile) {
        sameFileFunctions.putIfAbsent(name, () => d);
      } else if (!importedOf.containsKey(name)) {
        importedFunctions[name] = file;
      }
    }
    if (!sameFile) return;
    // 类的 static 字段**不在这里**收集：Dart 的类一律翻译成 JS `class`，static
    // const 与 static final 一样是类的静态成员（见 analyze_dart_class /
    // dart2js 的类声明）。本文件只负责**顶层**常量（含私有 `_x`）。
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
  // 枚举值先入可见常量表：顶层常量初始化器可能引用 `E.member`
  // （`const x = TaskLevel.high`），翻译常量时名字必须已经可见。
  translated.addAll(enumJs);
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
      log.warning(
          '[hot_patch_generator] ${sourceAt(sourcePath, exprs[name])}: '
          '顶层常量 $name 无法翻译，已跳过：${exprs[name]!.toSource()}');
      continue;
    }
    translated[name] = js;
  }

  // 同文件常量里引用到的跨文件类：数据产物与组件产物都要 import 它们。
  final used = _IdentifierCollector();
  for (final e in translated.entries) {
    if (foreignPrivate.contains(e.key)) continue;
    if (importedOf.containsKey(e.key)) continue;
    final init = exprs[e.key]; // 枚举没有初始化器表达式
    if (init != null) init.accept(used);
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
    final file = importedOf[e.key] ?? enumFileOf[e.key];
    if (file == null) {
      resolver.sameFile[e.key] = e.value; // 同文件：内联（保持依赖序）
    } else {
      resolver.importedFileOf[e.key] = file; // 跨文件：import
    }
  }

  // 顶层函数：与成员函数共用 closureToJs 的形参计划 / 语句翻译。同文件函数
  // 落成 `export const name = <closure>`；跨文件只登记来源，由声明文件自己发射。
  final functionNames = <String>{...sameFileFunctions.keys};
  final allNames = {...translated.keys, ...functionNames};
  final hostFunctions = buildHostFunctions(unit, sourcePath);
  for (final e in sameFileFunctions.entries) {
    final js = translateTopLevelFunctionJs(
      e.value,
      FieldScope(
        sourcePath: sourcePath,
        globalConsts: allNames,
        hostFunctions: hostFunctions,
      ),
      classTable,
    );
    if (js == null) {
      log.warning('[hot_patch_generator] ${sourceAt(sourcePath, e.value)}: '
          '顶层函数 ${e.key} 无法翻译，已跳过');
      continue;
    }
    resolver.sameFile[e.key] = js;
    resolver.functionNames.add(e.key);
  }
  for (final e in importedFunctions.entries) {
    if (resolver.importedFileOf.containsKey(e.key)) continue;
    resolver.importedFileOf[e.key] = e.value;
  }
  // 函数体里构造 / 引用的跨文件类：与常量初始化器同一口径补 import。
  final fnUsed = _IdentifierCollector();
  for (final d in sameFileFunctions.values) {
    d.functionExpression.body.accept(fnUsed);
  }
  resolver.sameFileConstClasses.addAll([
    for (final e in classTable.entries)
      if (!e.value.isComponent &&
          e.value.sourceFile != sourcePath &&
          fnUsed.names.contains(e.key))
        e.key,
  ]);
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

/// 指定顶层常量初始化器里出现的全部标识符名。
///
/// 纯数据产物只写「被引用到」的部分常量（见 componentTranslationScope 的
/// neededConsts），此时 import 也必须只按这些常量的初始化器计算——否则会
/// import 到未被引用的常量依赖的跨文件常量 / 类，目标产物本身不产出，
/// 运行时模块解析失败。
Set<String> constRefNames(CompilationUnit unit, Set<String> names) {
  if (names.isEmpty) return const {};
  final used = _IdentifierCollector();
  for (final d in unit.declarations.whereType<TopLevelVariableDeclaration>()) {
    for (final v in d.variables.variables) {
      final init = v.initializer;
      if (init == null || !names.contains(v.name.lexeme)) continue;
      init.accept(used);
    }
  }
  return used.names;
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

/// 简单枚举 → JS 常量对象表达式。
///
/// `enum E { a, b }` →
/// ```
/// export const E = (function () {
///   const __values = [];
///   function __mk(name, index) {
///     return { name: name, index: index,
///       toString: function () { return "E." + name; } };
///   }
///   const a = __mk("a", 0);
///   __values.push(a);
///   const b = __mk("b", 1);
///   __values.push(b);
///   return {
///     a: a,
///     b: b,
///     values: __values,
///     byName: function (name) { ... }
///   };
/// })();
/// ```
///
/// 覆盖 Dart 枚举的公共形态：`E.a` 常量、`switch (e) { case E.a: }`（同一对象
/// 身份）、`e.name` / `e.index` / `E.values` / `e.toString()`。
///
/// 增强枚举（带成员或构造实参）在 JS 侧没有对应承载位，显式告警并跳过（不生成
/// 悬空引用）。
String? _enumJs(EnumDeclaration d, String file) {
  final name = d.name.lexeme;
  if (d.members.isNotEmpty) {
    log.warning('[hot_patch_generator] ${sourceAt(file, d)}: enum $name '
        '含成员 / 构造函数（增强枚举），JS 侧暂不支持，已跳过。');
    return null;
  }
  for (final c in d.constants) {
    if (c.arguments != null &&
        c.arguments!.argumentList.arguments.isNotEmpty) {
      log.warning('[hot_patch_generator] ${sourceAt(file, c)}: '
          'enum $name.${c.name.lexeme} 带构造实参（增强枚举），'
          'JS 侧暂不支持，已跳过。');
      return null;
    }
  }
  final b = StringBuffer('(function () {\n');
  b.write('  const __values = [];\n');
  b.write('  function __mk(name, index) {\n');
  b.write('    return {\n');
  b.write('      name: name,\n');
  b.write('      index: index,\n');
  b.write('      toString: function () { return ${jsString('$name.')} + name; }\n');
  b.write('    };\n');
  b.write('  }\n');
  for (final (i, c) in d.constants.indexed) {
    final n = c.name.lexeme;
    b.write('  const $n = __mk(${jsString(n)}, $i);\n');
    b.write('  __values.push($n);\n');
  }
  b.write('  return {\n');
  for (final c in d.constants) {
    b.write('    ${c.name.lexeme}: ${c.name.lexeme},\n');
  }
  b.write('    values: __values,\n');
  // Dart `E.values.byName('x')`（EnumByName 扩展）→ `E.byName('x')`：
  // 生成侧把 byName 挂到枚举常量对象上（找不到抛错，与 Dart 的 ArgumentError 同义）。
  b.write('    byName: function (name) {\n');
  b.write('      for (var i = 0; i < __values.length; i++) {\n');
  b.write('        if (__values[i].name === name) { return __values[i]; }\n');
  b.write('      }\n');
  b.write('      throw new Error("Invalid argument(s): Invalid value: " + name);\n');
  b.write('    }\n');
  b.write('  };\n');
  b.write('})()');
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