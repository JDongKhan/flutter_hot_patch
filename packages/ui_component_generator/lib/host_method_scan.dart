import 'package:analyzer/dart/ast/ast.dart';

// ===========================================================================
// @HostInjected 的统一扫描口径
//
// 「哪些声明算宿主注入、通道名怎么取、能不能落地」只有这一份实现：
//   - 组件/模型翻译（builder.dart 的 hostMethods 表）
//   - 注册清单生成（host_register_builder.dart）
// 都调 [scanHostMethods]，避免两套逻辑分叉导致「翻译了但没注册」。
//
// 不支持参数个数 / 返回值类型的差异：调用点整体换成 __jsui.host(通道, [参数])，
// 宿主注册用 Function.apply，故任意形参与返回类型都成立。
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

/// 元数据里是否/哪个注解的「简单名」为 [simpleName]（忽略 import 前缀）。
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

/// 注解的第 [index] 个位置参数，是字符串字面量时取其值。
String? positionalString(Annotation a, [int index = 0]) {
  final args = a.arguments;
  if (args == null || index >= args.arguments.length) return null;
  final e = args.arguments[index];
  return e is StringLiteral ? e.stringValue : null;
}