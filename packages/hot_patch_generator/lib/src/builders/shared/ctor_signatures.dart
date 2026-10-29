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
  const CtorSignature(
    this.positional,
    this.named, {
    this.functionParams = const <String>{},
    this.nonFunctionParams = const <String>{},
  });

  /// 位置形参名，顺序与声明一致（`Text(this.data)` → `['data']`）。
  final List<String> positional;

  /// 具名形参名（`{this.style}` → `{'style'}`）。
  final Set<String> named;

  /// 具名形参中**声明类型是函数类型**的名字。
  ///
  /// 翻译层据此判定「这个实参是回调还是普通值」——与属性名无关，因此
  /// `Dismissible.confirmDismiss` 这类不以 `on` 开头的回调无需登记，
  /// 而恰好同名但声明为 `bool` 的属性也不会被误判成回调。
  final Set<String> functionParams;

  /// 具名形参中**声明类型明确不是函数**的名字（`bool` / `String` / 数据类…）。
  ///
  /// 与 [functionParams] 区分开，是为了保留「类型不可得」这一第三态：
  /// 两集合都不含的名字（`super.onPressed` 转发、找不到源码）由调用方
  /// 退回命名约定兜底。
  final Set<String> nonFunctionParams;

  static const empty = CtorSignature([], {});
}

/// 单个静态方法的源码事实。
class StaticMethodInfo {
  const StaticMethodInfo(this.returnType, {this.takesContext = false});

  /// 返回类型名（非具名类型 / 无返回类型 → null）。
  final String? returnType;

  /// 形参里是否出现 `BuildContext`。
  ///
  /// `X.of(context)` / `X.createBorderSide(context, color)` 这类是**运行期上下文
  /// 查找**，不是值构造；据此与「值工厂」（`ElevatedButton.styleFrom`）区分。
  /// 判据是源码形参类型，不按方法名判断。
  final bool takesContext;
}

/// 构造签名索引（进程内单例，按需建立类名 → 源文件索引）。
class CtorSignatures {
  CtorSignatures._(this._sources);

  final PackageSources? _sources;

  /// `类名#构造名#位置实参个数` → 签名；null 表示源码里找不到匹配的类。
  final Map<String, CtorSignature?> _cache = {};

  /// 类名 → 候选源文件绝对路径（按包优先级排序；同名类可能存在于多个包）。
  Map<String, List<String>>? _classFiles;

  /// typedef 名 → 候选源文件绝对路径（与 [classFiles] 同一次扫描建立）。
  Map<String, List<String>>? _typedefFiles;

  /// typedef 名 → 是否函数类型别名（解析结果缓存，每个名字只解析一次）。
  final Map<String, bool> _typedefIsFunction = {};

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

  /// 该类在源码里声明的**静态方法**名 → 源码事实（返回类型 / 是否要上下文）。
  ///
  /// 只用于「静态工厂落点」判定：`ElevatedButton.styleFrom(...)` 在 Dart 里是
  /// 静态方法，语法形态与命名构造同形（`X.m(...)`），JS 侧必须有同名静态方法。
  /// 返回类型决定落点——返回**镜像值类**时，落点就是构造该值类。
  /// 判据全部来自源码声明，不登记任何类名 / 方法名：SDK 新增同类静态工厂，
  /// 重构建即自动补齐。
  Map<String, StaticMethodInfo> staticMethodsOf(String className) {
    final out = <String, StaticMethodInfo>{};
    final files = _ensureIndex()[className];
    if (files == null) return out;
    for (final file in files) {
      final unit = _units.containsKey(file)
          ? _units[file]
          : _units[file] = parseUnitFile(file);
      if (unit == null) continue;
      for (final d in unit.declarations) {
        if (d is! ClassDeclaration || d.name.lexeme != className) continue;
        for (final m in d.members) {
          if (m is! MethodDeclaration || !m.isStatic) continue;
          if (m.isGetter || m.isSetter) continue;
          final type = m.returnType;
          final params = m.parameters?.parameters ?? const <FormalParameter>[];
          out[m.name.lexeme] = StaticMethodInfo(
            type is NamedType ? type.name2.lexeme : null,
            takesContext: _takesContext(params),
          );
        }
      }
    }
    return out;
  }

  /// 形参里是否出现 `BuildContext`（`X.of(context)` 这类上下文查找的判据）。
  static bool _takesContext(List<FormalParameter> params) {
    for (final p in params) {
      final inner = p is DefaultFormalParameter ? p.parameter : p;
      final TypeAnnotation? type = switch (inner) {
        SimpleFormalParameter() => inner.type,
        FieldFormalParameter() => inner.type,
        SuperFormalParameter() => inner.type,
        _ => null,
      };
      if (type is NamedType && type.name2.lexeme == 'BuildContext') return true;
    }
    return false;
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
      final fieldTypes = _instanceFieldTypes(decl);
      final positional = <String>[];
      final named = <String>{};
      final functionParams = <String>{};
      final nonFunctionParams = <String>{};
      for (final p in m.parameters.parameters) {
        final inner = p is DefaultFormalParameter ? p.parameter : p;
        final name = _paramName(inner);
        if (name == null) continue;
        if (p.isNamed) {
          named.add(name);
          final isFn = _paramIsFunction(inner, fieldTypes);
          if (isFn == true) functionParams.add(name);
          if (isFn == false) nonFunctionParams.add(name);
        } else {
          positional.add(name);
        }
      }
      return CtorSignature(
        positional,
        named,
        functionParams: functionParams,
        nonFunctionParams: nonFunctionParams,
      );
    }
    // 无名构造且没有显式声明：默认构造无参。
    if (ctorName == null) return CtorSignature.empty;
    return null;
  }

  /// 类里**实例字段**的名字 → 声明类型。
  ///
  /// 构造里大量使用 `this.onPressed` 这种**不写类型**的字段形参（Flutter
  /// 全生态的写法），其类型只在字段声明处；不看这里就只能把回调当普通值。
  Map<String, TypeAnnotation> _instanceFieldTypes(ClassDeclaration decl) {
    final out = <String, TypeAnnotation>{};
    for (final m in decl.members) {
      if (m is! FieldDeclaration || m.isStatic) continue;
      final type = m.fields.type;
      if (type == null) continue;
      for (final v in m.fields.variables) {
        out[v.name.lexeme] = type;
      }
    }
    return out;
  }

  /// 该形参是否**声明为函数类型**；null = 类型不可得（交给命名约定兜底）。
  ///
  /// 判定只看类型标注本身（语法），不需要类型解析：
  ///   - `void Function(T)` 这类 `GenericFunctionType` → 函数；
  ///   - 裸 `Function` → 函数；
  ///   - typedef（`VoidCallback` / `ValueChanged<T>` / `ConfirmDismissCallback` …）
  ///     → 查源码里的 typedef 声明，右侧是函数类型即函数；
  ///   - 其余具名类型 / 内置类型 → 非函数。
  bool? _paramIsFunction(
    FormalParameter p,
    Map<String, TypeAnnotation> fieldTypes,
  ) {
    // 老式「函数形参」写法（`void onDone(int v)`）本身就是函数类型。
    if (p is FunctionTypedFormalParameter) return true;
    TypeAnnotation? type;
    if (p is SimpleFormalParameter) {
      type = p.type;
    } else if (p is FieldFormalParameter) {
      type = p.type ?? fieldTypes[p.name.lexeme];
    } else if (p is SuperFormalParameter) {
      type = p.type;
    }
    if (type == null) return null;
    if (type is GenericFunctionType) return true;
    if (type is NamedType) {
      final name = type.name2.lexeme;
      if (name == 'Function') return true;
      return _isFunctionTypedef(name);
    }
    return false;
  }

  /// 源码里的 typedef 是否是**函数类型别名**。
  ///
  /// 只解析该 typedef 所在文件（按需，缓存），不做全局解析——`VoidCallback`
  /// 这类名字全生态都在用，必须能从源码判定，而不是维护名字表。
  bool _isFunctionTypedef(String name) {
    final cached = _typedefIsFunction[name];
    if (cached != null) return cached;
    var result = false;
    _ensureIndex();
    for (final file in _typedefFiles![name] ?? const <String>[]) {
      final unit =
          _units.containsKey(file) ? _units[file] : _units[file] = parseUnitFile(file);
      if (unit == null) continue;
      for (final d in unit.declarations) {
        if (d is GenericTypeAlias && d.name.lexeme == name) {
          // `typedef X<T> = R Function(…)` 的右侧才是真正的类型。
          result = d.functionType != null;
        } else if (d is FunctionTypeAlias && d.name.lexeme == name) {
          // 老式 `typedef void X(int v);` 本身就是函数类型。
          result = true;
        }
      }
    }
    return _typedefIsFunction[name] = result;
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
    final typedefs = <String, List<String>>{};
    _typedefFiles = typedefs;
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
        for (final m in _typedefDecl.allMatches(content)) {
          final name = m.group(1);
          if (name != null) typedefs.putIfAbsent(name, () => []).add(entity.path);
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

  /// `typedef Foo = …` / 老式 `typedef void Foo(…)` 的别名名（跳过注释里的）。
  static final _typedefDecl = RegExp(
    r'^[ \t]*(?:(?:abstract|sealed|base|final|interface|augment)[ \t]+)*typedef[ \t]+([A-Za-z_$][\w$]*)',
    multiLine: true,
  );
}
