/// `@HostInjected` 的**唯一**识别口径：哪些声明算宿主注入、通道名怎么取。
///
/// 语义由「声明侧」承担，调用点不再改写：
///   - **声明侧**：被标注的 static 方法在 JS 侧仍是普通方法（方法名、形参、
///     类结构照常翻译），只是**方法体**整体换成
///     `_app_host_.invoke("通道", 实参载荷)`（见 `hostMethodBodyJs`）；Dart
///     方法体不翻译，因此它引用到的类型 / import 也不会进入 JS 产物。
///   - **调用侧**：与 Dart 一比一——`AccountCenter.getUserName(a)` 依然产出
///     `AccountCenter.getUserName(a)`，由上面的 JS 方法体桥回宿主。
///   - **顶层函数**是唯一例外：顶层函数没有可承载的 JS 类，产物里不存在同名
///     函数，调用点仍按通道翻译（`_app_host_.invoke(...)`）。判据是「有没有
///     JS 载体」这一源码事实，不是按名字特判。
///
/// 同一份扫描口径还被 `ui_host_register/host_register_builder.dart` 用来生成
/// 宿主侧注册清单（通道 → Dart 实现），保证「JS 里调用的通道一定被注册」。
///
/// 不支持参数个数 / 是否具名 / 返回值类型的差异：实参载荷按调用点的通用约定
/// （位置实参在前、具名实参合并成尾参对象）原样交给宿主，宿主侧用
/// `Function.apply(impl, 位置, 具名)` 还原，故任意形参与返回类型都成立。
library;

import 'package:analyzer/dart/ast/ast.dart';

import 'source_index.dart';

/// 一个被 `@HostInjected` 标注的可调用实体：static 方法 / 实例方法 / 顶层函数。
class HostMethodDecl {
  /// 所属类名；顶层函数为空串。
  final String owner;
  final String name;

  /// 通道名：注解的位置参数（`@HostInjected('通道')`），缺省为 [name]。
  final String channel;

  /// static 方法或顶层函数（可静态引用）为 true；实例方法为 false。
  final bool isStatic;

  /// 私有类成员 / 私有函数：产物与生成文件在其他库里，跨库不可见。
  final bool isPrivate;

  const HostMethodDecl({
    required this.owner,
    required this.name,
    required this.channel,
    required this.isStatic,
    required this.isPrivate,
  });

  /// 宿主侧注册时引用的表达式：`Class.method` / `topLevelFunc`。
  String get targetExpr => owner.isEmpty ? name : '$owner.$name';

  /// 是否可用于宿主注入（翻译与注册口径必须一致，故只有这一个判定）：
  ///   - 实例方法：JS 侧 receiver 是 JS 对象，回不到宿主实例，无法定位实现；
  ///   - 私有声明：跨库引用不到。
  bool get usable => isStatic && !isPrivate;
}

/// 扫描一个编译单元里全部 `@HostInjected` 标注（顶层函数 + 类的方法）。
void scanHostMethods(
  CompilationUnit unit,
  void Function(HostMethodDecl decl) sink,
) {
  for (final d in unit.declarations) {
    if (d is FunctionDeclaration) {
      final a = findAnnotation(d.metadata, 'HostInjected');
      if (a == null) continue;
      final n = d.name.lexeme;
      sink(HostMethodDecl(
        owner: '',
        name: n,
        channel: _positionalString(a) ?? n,
        isStatic: true,
        isPrivate: n.startsWith('_'),
      ));
      continue;
    }
    if (d is ClassDeclaration) {
      final owner = d.name.lexeme;
      final ownerPrivate = owner.startsWith('_');
      for (final m in d.members.whereType<MethodDeclaration>()) {
        final a = findAnnotation(m.metadata, 'HostInjected');
        if (a == null) continue;
        final n = m.name.lexeme;
        sink(HostMethodDecl(
          owner: owner,
          name: n,
          channel: _positionalString(a) ?? n,
          isStatic: m.isStatic,
          isPrivate: ownerPrivate || n.startsWith('_'),
        ));
      }
    }
  }
}

/// 方法声明上的宿主通道名；未标注 `@HostInjected` 返回 null。
///
/// 翻译层用它把「哪些方法的方法体改为 `_app_host_.invoke`」判定在声明处做掉
/// （见 `analyze_dart_class` 的 `classInfoOf`），调用点不再需要通道表。
String? hostChannelOf(MethodDeclaration m) {
  final a = findAnnotation(m.metadata, 'HostInjected');
  if (a == null) return null;
  return _positionalString(a) ?? m.name.lexeme;
}

/// 收集可见的**顶层** `@HostInjected` 函数名（本文件 + import 源文件）。
///
/// 只有顶层函数需要调用点改写：类上的宿主方法由 JS 类里的同名方法承接，调用点
/// 与 Dart 一比一；顶层函数没有 JS 载体，调用点仍翻译成
/// `_app_host_.invoke(通道, 载荷)`。
Set<String> buildHostFunctions(CompilationUnit unit, String sourcePath) {
  final out = <String>{};
  void scan(CompilationUnit u, String file, {required bool sameFile}) {
    scanHostMethods(u, (h) {
      if (!h.usable || h.owner.isNotEmpty) return;
      // import 的 show / hide：被隐藏的顶层函数在本文件里不可调用。
      if (!sameFile && !importedSymbolVisible(unit, sourcePath, file, h.name)) {
        return;
      }
      out.add(h.name);
    });
  }

  scan(unit, sourcePath, sameFile: true);
  for (final e in libraryUnitsOf(unit, sourcePath)) {
    if (e.$1 != sourcePath) scan(e.$2, e.$1, sameFile: true);
  }
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final importUnit = parseUnitFile(file);
    if (importUnit == null) continue;
    scan(importUnit, file, sameFile: false);
  }
  return out;
}

/// 注解的第 [index] 个位置参数，是字符串字面量时取其值。
String? _positionalString(Annotation a, [int index = 0]) {
  final args = a.arguments;
  if (args == null || index >= args.arguments.length) return null;
  final e = args.arguments[index];
  return e is StringLiteral ? e.stringValue : null;
}
