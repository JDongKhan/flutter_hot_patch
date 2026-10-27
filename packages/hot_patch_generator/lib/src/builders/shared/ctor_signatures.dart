/// 构造函数签名索引：`类名 + 构造名 → 位置形参名 / 具名形参名`。
///
/// 翻译层只做语法翻译（`A(args)` → `new A({...})`，`A.b(args)` → `A.b({...})`），
/// 位置实参要落成 props 键**必须**知道形参名。签名从 Dart 源码抽取，覆盖
/// 项目类、Flutter SDK 与全部依赖包——SDK / 三方包新增类或构造，重建即自动
/// 生效，翻译器与运行时都不需要登记任何类名。
///
/// 找不到源码的类返回 null（调用方按 `__pos` 下标兜底并出声），不静默丢弃。
library;

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';

import 'package_sources.dart';
import 'source_index.dart';

/// 单个构造的形参签名。
class CtorSignature {
  const CtorSignature(this.positional, this.named);

  /// 位置形参名，顺序与声明一致（`Text(this.data)` → `['data']`）。
  final List<String> positional;

  /// 具名形参名（`{this.style}` → `{'style'}`）。
  final Set<String> named;

  static const empty = CtorSignature([], {});
}

/// 构造签名索引（进程内单例，按需建立类名 → 源文件索引）。
class CtorSignatures {
  CtorSignatures._(this._sources);

  final PackageSources? _sources;

  /// `类名#构造名#位置实参个数` → 签名；null 表示源码里找不到匹配的类。
  final Map<String, CtorSignature?> _cache = {};

  /// 类名 → 候选源文件绝对路径（按包优先级排序；同名类可能存在于多个包）。
  Map<String, List<String>>? _classFiles;

  /// 源码里声明的 enum 名（与类索引同一次扫描建立）。
  final Set<String> _enumNames = {};

  /// 已解析的编译单元缓存（同一文件只读一次）。
  final Map<String, CompilationUnit?> _units = {};

  static CtorSignatures? _instance;

  static CtorSignatures? get instance {
    final sources = PackageSources.locate();
    if (sources == null) return null;
    return _instance ??= CtorSignatures._(sources);
  }

  /// 查询签名；[ctorName] 为空表示无名构造。
  ///
  /// [positionalCount] 是调用点的位置实参个数，用于在**同名类**之间挑出
  /// 真正匹配的那个（例如三方包与 dart:ui 都有 `Offset`，用形参个数区分），
  /// 从而不需要维护任何包/类白名单。
  ///
  /// 源码里找不到该类时返回 null（调用方兜底并告警）。
  CtorSignature? of(String className, {String? ctorName, int positionalCount = 0}) {
    final key = '$className#${ctorName ?? ''}#$positionalCount';
    if (_cache.containsKey(key)) return _cache[key];
    final files = _ensureIndex()[className];
    if (files == null || files.isEmpty) return _cache[key] = null;
    CtorSignature? fallback;
    for (final file in files) {
      final unit = _units.containsKey(file) ? _units[file] : _units[file] = parseUnitFile(file);
      if (unit == null) continue;
      for (final d in unit.declarations) {
        if (d is! ClassDeclaration || d.name.lexeme != className) continue;
        final sig = _signatureOf(d, ctorName);
        if (sig == null) continue;
        fallback ??= sig;
        // 形参个数必须容得下调用点的位置实参（Dart 位置形参可选，故用 >=）。
        if (sig.positional.length >= positionalCount) return _cache[key] = sig;
      }
    }
    return _cache[key] = fallback;
  }

  /// 该类在源码里声明的**命名构造**名（`ListView` → `builder` / `separated` / …）。
  ///
  /// 用于生成包装类上的同名静态方法（`ListView.separated({...})`），无需维护
  /// 任何类/构造名白名单：SDK 新增命名构造，重构建即自动补上静态方法。
  Set<String> ctorNamesOf(String className) {
    final names = <String>{};
    final files = _ensureIndex()[className];
    if (files == null) return names;
    for (final file in files) {
      final unit = _units.containsKey(file)
          ? _units[file]
          : _units[file] = parseUnitFile(file);
      if (unit == null) continue;
      for (final d in unit.declarations) {
        if (d is! ClassDeclaration || d.name.lexeme != className) continue;
        for (final m in d.members) {
          if (m is ConstructorDeclaration && m.name != null) {
            names.add(m.name!.lexeme);
          }
        }
      }
    }
    return names;
  }

  /// 源码索引：该名字是否是**枚举**（`Colors` 这类静态常量类是 class，不是 enum）。
  ///
  /// 翻译层用它区分 `Owner.member` 的两种语义：enum 成员 → 成员名字符串
  /// （产物协议），普通类的静态常量 → 1:1 原样引用（运行时注入同名类）。
  bool isEnum(String name) {
    _ensureIndex();
    return _enumNames.contains(name);
  }

  /// 源码索引：该名字是否有 **class** 声明（含 `abstract final class` 等多修饰符）。
  bool isClass(String name) => _ensureIndex().containsKey(name);

  /// 抽单个类的构造签名；[ctorName] 指定的构造不存在时返回 null。
  CtorSignature? _signatureOf(ClassDeclaration decl, String? ctorName) {
    for (final m in decl.members) {
      if (m is! ConstructorDeclaration) continue;
      if (m.name?.lexeme != ctorName) continue;
      final positional = <String>[];
      final named = <String>{};
      for (final p in m.parameters.parameters) {
        final inner = p is DefaultFormalParameter ? p.parameter : p;
        final name = _paramName(inner);
        if (name == null) continue;
        if (p.isNamed) {
          named.add(name);
        } else {
          positional.add(name);
        }
      }
      return CtorSignature(positional, named);
    }
    // 无名构造且没有显式声明：默认构造无参。
    if (ctorName == null) return CtorSignature.empty;
    return null;
  }

  String? _paramName(FormalParameter p) {
    if (p is SimpleFormalParameter) return p.name?.lexeme;
    if (p is FieldFormalParameter) return p.name.lexeme;
    if (p is SuperFormalParameter) return p.name.lexeme;
    if (p is FunctionTypedFormalParameter) return p.name.lexeme;
    return null;
  }

  Map<String, List<String>> _ensureIndex() {
    final existing = _classFiles;
    if (existing != null) return existing;
    final index = <String, List<String>>{};
    final sources = _sources;
    if (sources == null) return _classFiles = index;
    for (final root in sources.packages) {
      final dir = Directory(root.libDir);
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        for (final m in _classDecl.allMatches(content)) {
          final name = m.group(1);
          if (name != null) index.putIfAbsent(name, () => []).add(entity.path);
        }
        for (final m in _enumDecl.allMatches(content)) {
          final name = m.group(1);
          if (name != null) _enumNames.add(name);
        }
      }
    }
    return _classFiles = index;
  }

  /// `class Foo` / `abstract class Foo` / `abstract final class Foo` 等的类名
  /// （跳过注释里的）。修饰符可叠加，故用重复组。
  static final _classDecl = RegExp(
    r'^[ \t]*(?:(?:abstract|sealed|base|final|interface|augment)[ \t]+)*class[ \t]+([A-Za-z_$][\w$]*)',
    multiLine: true,
  );

  /// `enum Foo` / `sealed enum Foo` 的枚举名（跳过注释里的）。
  static final _enumDecl = RegExp(
    r'^[ \t]*(?:(?:sealed)[ \t]+)?enum[ \t]+([A-Za-z_$][\w$]*)',
    multiLine: true,
  );
}
