import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import '../source_index.dart';

// ===========================================================================
// @HostInjected 的统一扫描口径
//
// 「哪些声明算宿主注入、通道名怎么取、能不能落地」只有这一份实现：
//   - 组件/模型翻译（component_builder 的 hostMethods 表）
//   - 注册清单生成（host_register_builder.dart）
// 都调 [scanHostMethods]，避免两套逻辑分叉导致「翻译了但没注册」。
//
// 不支持参数个数 / 是否具名 / 返回值类型的差异：调用点整体换成
// __jsui.host(通道, 参数载荷)（纯位置→数组、纯具名→对象、混合→数组+具名），
// 宿主侧用 Function.apply(impl, 位置, 具名) 还原，故任意形参与返回类型都成立。
// ===========================================================================

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
        channel: positionalString(a) ?? n,
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
          channel: positionalString(a) ?? n,
          isStatic: m.isStatic,
          isPrivate: ownerPrivate || n.startsWith('_'),
        ));
      }
    }
  }
}

/// 类是否声明了带 @HostInjected 的方法（static 宿主注入能力）→ 不产出 JS。
bool classHasHostInjectedMethod(ClassDeclaration d) {
  for (final m in d.members.whereType<MethodDeclaration>()) {
    if (findAnnotation(m.metadata, 'HostInjected') != null) return true;
  }
  return false;
}

/// 收集宿主注入方法表：`类名 → {方法名 → 通道名}`（见 @HostInjected）；
/// 顶层函数挂在空串 key 下（`'' → {函数名 → 通道名}`）。
///
/// 扫描本文件 + import 源文件（调用点能写出来，就必然 import 得到）；
/// 只有 [HostMethodDecl.usable] 的声明进表——与注册清单（host_register_builder）
/// 用同一个扫描器、同一个判定，保证「翻译了的都注册了」，不因两套逻辑分叉。
///
/// 供翻译上下文把调用点整体替换为 `__jsui.host("通道", 参数载荷)`
/// （参数个数、是否具名、返回值类型都不参与判定）。
Map<String, Map<String, String>> buildHostMethods(
  CompilationUnit unit,
  String sourcePath,
) {
  final out = <String, Map<String, String>>{};
  void scan(CompilationUnit u) {
    scanHostMethods(u, (h) {
      if (!h.usable) return;
      (out[h.owner] ??= {})[h.name] = h.channel;
    });
  }

  scan(unit);
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final f = File(file);
    if (!f.existsSync()) continue;
    scan(parseString(content: f.readAsStringSync()).unit);
  }
  return out;
}

/// 注解的第 [index] 个位置参数，是字符串字面量时取其值。
String? positionalString(Annotation a, [int index = 0]) {
  final args = a.arguments;
  if (args == null || index >= args.arguments.length) return null;
  final e = args.arguments[index];
  return e is StringLiteral ? e.stringValue : null;
}