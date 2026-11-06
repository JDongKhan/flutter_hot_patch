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
    this.typeParams = const <String>[],
    this.functionParams = const <String>{},
    this.nonFunctionParams = const <String>{},
  });

  /// 位置形参名，顺序与声明一致（`Text(this.data)` → `['data']`）。
  final List<String> positional;

  /// 类声明的**类型参数名**（`class Provider<T>` → `['T']`）。
  ///
  /// 泛型实参按它映射成 `typeArguments: {T: 'CounterVm'}`（key 是源码里开发者
  /// 写的类型参数名，按声明顺序与实参一一对应），多泛型天然支持。
  final List<String> typeParams;

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
  /// 与 [functionParams] 区分开，保留「类型不可得」这一第三态：两集合都不含
  /// 的名字由调用方按表达式形态兜底（不再按 `on*` 命名猜）。
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

  /// enum 名 → 候选源文件绝对路径（与 [classFiles] 同一次扫描建立）。
  ///
  /// 只用于「该类型名是不是源码里的枚举」判定（字段类型可翻译性）：枚举在
  /// JS 侧是同名值对象（声明文件产物 `export const X`），不是类，[of] 查不到。
  final Map<String, List<String>> _enumFiles = {};

  /// typedef 名 → 是否函数类型别名（解析结果缓存，每个名字只解析一次）。
  final Map<String, bool> _typedefIsFunction = {};

  /// **泛型方法声明**索引：方法名 → 候选源文件。
  ///
  /// 由 [_ensureIndex] 的正则扫描建立（`T watch<T>(…)` / `List<T> map<T>(…)`）。
  /// 同一个方法名可能在多个包里有声明（如 Flutter 的 `read<P>` 与 provider 的
  /// `read<T>`），因此实际类型参数名在 [methodTypeParamsOfName] 里按需解析这些
  /// 文件的 AST：优先**extension 声明**（代理方法族），仍歧义则返回空、退化
  /// 为位置序号键，绝不猜。
  final Map<String, Set<String>> _genericMethodFiles = {};

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

  /// 该类**所有构造**里「可能声明为函数类型」的具名形参并集（宿主包装类的
  /// `__fnProps` 名单，产物在运行时只查这几个键，避免遍历全部 props）。
  ///
  /// 包含第三态（类型不可得，`super.x` 解不出 / `dynamic`）：运行时会再按
  /// `typeof` 过滤，名单里多一个非函数名只是多一次判断，不会误包成句柄。
  ///
  /// 找不到类源码返回 null（调用方生成 `static __fnProps = null`，运行时回退
  /// 全量扫描）；类存在但没有构造 → 空集合（确实没有函数形参）。
  Set<String>? functionParamsOf(String className) {
    final files = _ensureIndex()[className];
    if (files == null || files.isEmpty) return null;
    final out = <String>{};
    var found = false;
    for (final file in files) {
      final unit = _units.containsKey(file)
          ? _units[file]
          : _units[file] = parseUnitFile(file);
      if (unit == null) continue;
      for (final d in unit.declarations) {
        if (d is! ClassDeclaration || d.name.lexeme != className) continue;
        found = true;
        final fieldTypes = _instanceFieldTypes(d);
        for (final m in d.members) {
          if (m is! ConstructorDeclaration) continue;
          for (final p in m.parameters.parameters) {
            if (!p.isNamed) continue;
            final inner = p is DefaultFormalParameter ? p.parameter : p;
            final name = _paramName(inner);
            if (name == null) continue;
            if (_paramIsFunction(inner, fieldTypes, d) != false) out.add(name);
          }
        }
      }
    }
    return found ? out : null;
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

  /// 源码索引：该名字是否有 **class** 声明（含 `abstract final class` 等多修饰符）。
  bool isClass(String name) => _ensureIndex().containsKey(name);

  /// 源码索引：该名字是否是**会产出 JS 值对象的枚举**。
  ///
  /// 判据只看源码事实：存在同名 `enum` 声明，且它是**简单枚举**（成员不带
  /// 构造实参）。增强枚举（`enum E { a(1) }`）在 JS 侧不生成值对象
  /// （见 const_support 的 `_enumJs`），故不算「有 JS 值」，避免字段判定
  /// 放行后产出悬空引用。
  bool isEnum(String name) {
    _ensureIndex();
    for (final file in _enumFiles[name] ?? const <String>[]) {
      final unit =
          _units.containsKey(file) ? _units[file] : _units[file] = parseUnitFile(file);
      if (unit == null) continue;
      for (final d in unit.declarations.whereType<EnumDeclaration>()) {
        if (d.name.lexeme != name) continue;
        if (d.constants.every((c) => c.arguments == null)) return true;
      }
    }
    return false;
  }

  /// 该名字的类声明**所在包**（同名类可能存在于多个包，全部返回）。
  ///
  /// 只读源码事实（类声明文件 → 包），用于判定「这个类型是否由宿主的三方
  /// JS 模块提供」；找不到源码时返回空集合。
  Set<String> declaringPackagesOf(String className) {
    final out = <String>{};
    for (final file in _ensureIndex()[className] ?? const <String>[]) {
      final pkg = _sources?.packageOfFile(file);
      if (pkg != null) out.add(pkg);
    }
    return out;
  }

  /// 类声明的类型参数名（`class Provider<T>` → `['T']`）；查不到返回空。
  List<String> typeParamsOf(String className) {
    for (final file in _ensureIndex()[className] ?? const <String>[]) {
      final unit = _units.containsKey(file)
          ? _units[file]
          : _units[file] = parseUnitFile(file);
      if (unit == null) continue;
      for (final d in unit.declarations) {
        if (d is ClassDeclaration && d.name.lexeme == className) {
          return classTypeParamsOf(d);
        }
      }
    }
    return const [];
  }

  /// 类上**静态方法**的类型参数名（`static T parse<T>(...)` → `['T']`）。
  List<String> staticMethodTypeParamsOf(String className, String methodName) {
    for (final file in _ensureIndex()[className] ?? const <String>[]) {
      final unit = _units.containsKey(file)
          ? _units[file]
          : _units[file] = parseUnitFile(file);
      if (unit == null) continue;
      for (final d in unit.declarations) {
        if (d is! ClassDeclaration || d.name.lexeme != className) continue;
        for (final m in d.members) {
          if (m is MethodDeclaration &&
              m.isStatic &&
              m.name.lexeme == methodName) {
            return [
              for (final t
                  in m.typeParameters?.typeParameters ?? const <TypeParameter>[])
                t.name.lexeme,
            ];
          }
        }
      }
    }
    return const [];
  }


  /// 泛型**方法名** → 声明侧类型参数名（`watch` → `['T']`）。
  ///
  /// 用于调用点无法定位接收者类型的方法（`context.watch<T>()` 这类代理方法）。
  /// 同名方法可能在多个包里声明（Flutter `read<P>` / provider `read<T>`），故
  /// 按候选文件解析 AST：
  ///   1. 所有候选参数名一致 → 采用；
  ///   2. 不一致时优先 **extension 声明**（代理方法族；普通调用不会消费这些元信息，
  ///      key 仅供需要它的库读取）；
  ///   3. 仍不可判定 → 空，调用方退化为位置序号键。
  List<String> methodTypeParamsOfName(String methodName) {
    _ensureIndex();
    final candidates = <_GenericMethodDecl>[];
    for (final file in _genericMethodFiles[methodName] ?? const <String>{}) {
      final unit = _units.containsKey(file)
          ? _units[file]
          : _units[file] = parseUnitFile(file);
      if (unit == null) continue;
      for (final d in unit.declarations) {
        if (d is ExtensionDeclaration) {
          for (final m in d.members.whereType<MethodDeclaration>()) {
            if (m.name.lexeme != methodName) continue;
            final tps = _typeParamNames(m);
            if (tps.isNotEmpty) candidates.add(_GenericMethodDecl(tps, true));
          }
        } else if (d is ClassDeclaration) {
          _collectMembers(d.members, methodName, candidates);
        } else if (d is MixinDeclaration) {
          _collectMembers(d.members, methodName, candidates);
        } else if (d is FunctionDeclaration && d.name.lexeme == methodName) {
          final tps = [
            for (final t
                in d.functionExpression.typeParameters?.typeParameters ??
                    const <TypeParameter>[])
              t.name.lexeme,
          ];
          if (tps.isNotEmpty) candidates.add(_GenericMethodDecl(tps, false));
        }
      }
    }
    final all = candidates.map((c) => c.names.join(',')).toSet();
    if (all.length == 1) return all.first.split(',');
    final ext = candidates
        .where((c) => c.isExtension)
        .map((c) => c.names.join(','))
        .toSet();
    if (ext.length == 1) return ext.first.split(',');
    return const [];
  }

  static List<String> _typeParamNames(MethodDeclaration m) => [
        for (final t
            in m.typeParameters?.typeParameters ?? const <TypeParameter>[])
          t.name.lexeme,
      ];

  static void _collectMembers(
    Iterable<ClassMember> members,
    String methodName,
    List<_GenericMethodDecl> out,
  ) {
    for (final m in members.whereType<MethodDeclaration>()) {
      if (m.name.lexeme != methodName) continue;
      final tps = _typeParamNames(m);
      if (tps.isNotEmpty) out.add(_GenericMethodDecl(tps, false));
    }
  }

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
          final isFn = _paramIsFunction(inner, fieldTypes, decl);
          if (isFn == true) functionParams.add(name);
          if (isFn == false) nonFunctionParams.add(name);
        } else {
          positional.add(name);
        }
      }
      return CtorSignature(
        positional,
        named,
        typeParams: classTypeParamsOf(decl),
        functionParams: functionParams,
        nonFunctionParams: nonFunctionParams,
      );
    }
    // 无名构造且没有显式声明：默认构造无参。
    if (ctorName == null) {
      return CtorSignature(const [], const {}, typeParams: classTypeParamsOf(decl));
    }
    return null;
  }

  /// 类声明里的类型参数名（`class Pair<K, V>` → `['K', 'V']`）。
  static List<String> classTypeParamsOf(ClassDeclaration decl) => [
        for (final t in decl.typeParameters?.typeParameters ?? const <TypeParameter>[])
          t.name.lexeme,
      ];

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

  /// 该形参是否**声明为函数类型**；null = 类型不可得（交给表达式形态兜底）。
  ///
  /// 判定只看类型标注本身（语法），不需要类型解析：
  ///   - `void Function(T)` 这类 `GenericFunctionType` → 函数；
  ///   - 裸 `Function` → 函数；
  ///   - typedef（`VoidCallback` / `ValueChanged<T>` / `ConfirmDismissCallback` …）
  ///     → 查源码里的 typedef 声明，右侧是函数类型即函数；
  ///   - `super.x`（`required super.onPressed`）在语法上无类型标注，沿 `extends`
  ///     链找父类的同名字段 / 构造形参（Flutter 全生态用这种写法，`TextButton`
  ///     的 `onPressed` 类型只在 `ButtonStyleButton` 的字段声明处）；
  ///   - 其余具名类型 / 内置类型 → 非函数。
  bool? _paramIsFunction(
    FormalParameter p,
    Map<String, TypeAnnotation> fieldTypes,
    ClassDeclaration decl,
  ) {
    // 老式「函数形参」写法（`void onDone(int v)`）本身就是函数类型。
    if (p is FunctionTypedFormalParameter) return true;
    TypeAnnotation? type;
    if (p is SimpleFormalParameter) {
      type = p.type;
    } else if (p is FieldFormalParameter) {
      type = p.type ?? fieldTypes[p.name.lexeme];
    } else if (p is SuperFormalParameter) {
      type = p.type ?? _superDeclaredType(decl, p.name.lexeme);
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

  /// `super.x` 形参的类型：父类同名字段声明 / 父类构造形参 / 再上一层父类。
  ///
  /// 只沿 `extends` 链查源码（不解析泛型实参），找不到返回 null。
  TypeAnnotation? _superDeclaredType(ClassDeclaration decl, String name) {
    var current = decl;
    final seen = <String>{};
    while (true) {
      final sup = current.extendsClause?.superclass.name2.lexeme;
      if (sup == null || !seen.add(sup)) return null;
      ClassDeclaration? target;
      for (final file in _ensureIndex()[sup] ?? const <String>[]) {
        final unit = _units.containsKey(file)
            ? _units[file]
            : _units[file] = parseUnitFile(file);
        if (unit == null) continue;
        for (final d in unit.declarations) {
          if (d is ClassDeclaration && d.name.lexeme == sup) {
            target = d;
            break;
          }
        }
        if (target != null) break;
      }
      if (target == null) return null;
      final fromField = _instanceFieldTypes(target)[name];
      if (fromField != null) return fromField;
      for (final m in target.members) {
        if (m is! ConstructorDeclaration) continue;
        for (final p in m.parameters.parameters) {
          final inner = p is DefaultFormalParameter ? p.parameter : p;
          if (_paramName(inner) != name) continue;
          if (inner is SimpleFormalParameter) {
            if (inner.type != null) return inner.type;
          } else if (inner is FieldFormalParameter) {
            if (inner.type != null) return inner.type;
          } else if (inner is SuperFormalParameter) {
            if (inner.type != null) return inner.type;
          }
        }
      }
      current = target;
    }
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
        for (final m in _typedefDecl.allMatches(content)) {
          final name = m.group(1);
          if (name != null) typedefs.putIfAbsent(name, () => []).add(entity.path);
        }
        for (final m in _enumDecl.allMatches(content)) {
          final name = m.group(1);
          if (name != null) {
            _enumFiles.putIfAbsent(name, () => []).add(entity.path);
          }
        }
        for (final m in _genericMethodDecl.allMatches(content)) {
          final name = m.group(1);
          if (name == null) continue;
          _genericMethodFiles.putIfAbsent(name, () => {}).add(entity.path);
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

  /// `typedef Foo = …` / 老式 `typedef void Foo(…)` 的别名名（跳过注释里的）。
  static final _typedefDecl = RegExp(
    r'^[ \t]*(?:(?:abstract|sealed|base|final|interface|augment)[ \t]+)*typedef[ \t]+([A-Za-z_$][\w$]*)',
    multiLine: true,
  );

  /// `enum Foo { … }` 的枚举名（允许上方有注解行）。
  static final _enumDecl = RegExp(
    r'^[ \t]*(?:@[\w.]+(?:[ \t]*\([^)]*\))?[ \t]*\r?\n[ \t]*)*'
    r'enum[ \t]+([A-Za-z_$][\w$]*)',
    multiLine: true,
  );

  /// **泛型方法声明**：`T watch<T>(…)` / `List<T> map<T>(…)`。
  ///
  /// 要求方法名前有一个「返回类型 + 空白」，据此把调用形态（`x.watch<T>(…)` /
  /// `= Foo<T>(…)`）排除在外：调用前是 `.` / `=`，不是标识符 + 空白。
  static final _genericMethodDecl = RegExp(
    r'[A-Za-z_$][\w$<>?, ]*[ \t]+([A-Za-z_$][\w$]*)[ \t]*<[ \t]*([A-Za-z_$][\w$]*(?:[ \t]*,[ \t]*[A-Za-z_$][\w$]*)*)[ \t]*>[ \t]*\(',
  );
}

/// 一个泛型方法声明的候选事实（[methodTypeParamsOfName] 歧义判定用）。
class _GenericMethodDecl {
  const _GenericMethodDecl(this.names, this.isExtension);

  /// 声明侧类型参数名，按声明顺序。
  final List<String> names;

  /// 是否声明在 `extension` 里（代理方法族优先采用）。
  final bool isExtension;
}
