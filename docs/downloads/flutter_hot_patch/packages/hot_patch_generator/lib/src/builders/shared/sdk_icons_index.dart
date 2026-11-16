/// Material 图标常量索引：把 `Icons` 表从 SDK 源码抽出来，供 `flutter.js`
/// 生成同名 JS 常量（`IconData` 实例）。
///
/// 与枚举同一原则：翻译层对 `Icons.edit` 是**原样引用**（见 value_forms.dart），
/// 因此 JS 侧必须真的存在这些名字。表的来源只能是 SDK 源码，不能靠手写白名单
/// ——旧实现用一张几十条的手写表 + 未命中回退 `Icons.circle`，既漏图标又把
/// 失败变成了静默降级。
///
/// 读法用 **AST**（`Icons` 类的字段声明），不用正则：`Icons` 表里单行 / 多行
/// 两种书写混用，正则漏掉了 800 多个（`Icons.list` / `Icons.arrow_right` 这类
/// 多行声明的就整条丢失，产物里 `icon: undefined` 被静默丢弃）。
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'package_sources.dart';

/// 一个 IconData 常量：名字 → 码点 / 字体族 / 是否随文字方向翻转。
class SdkIcon {
  const SdkIcon(
    this.name,
    this.codePoint,
    this.fontFamily,
    this.matchTextDirection,
  );

  final String name;
  final int codePoint;
  final String fontFamily;
  final bool matchTextDirection;
}

Map<String, SdkIcon>? _cache;

/// `Icons` 常量表（名字 → IconData 参数）。结果进程级缓存。
Map<String, SdkIcon> sdkIcons() {
  final cached = _cache;
  if (cached != null) return cached;
  final result = <String, SdkIcon>{};
  final sources = PackageSources.instance;
  if (sources == null) return _cache = result;
  String? lib;
  for (final p in sources.packages) {
    if (p.name == 'flutter') {
      lib = p.libDir;
      break;
    }
  }
  if (lib == null) return _cache = result;
  final file = File('$lib/src/material/icons.dart');
  if (!file.existsSync()) return _cache = result;
  // 直接解析文本：SDK 文件在项目 package_config 之外，走项目级 parseUnitFile
  // 会拿不到编译单元（返回 null → 整表为空）。
  final unit = parseString(
    content: file.readAsStringSync(),
    path: file.path,
    throwIfDiagnostics: false,
  ).unit;

  final iconsClass = unit.declarations
      .whereType<ClassDeclaration>()
      .where((d) => d.name.lexeme == 'Icons')
      .firstOrNull;
  if (iconsClass == null) {
    // ignore: avoid_print - 构建期日志
    print('[hot_patch_generator] Icons 类未找到：${file.path}');
    return _cache = result;
  }

  for (final member in iconsClass.members) {
    if (member is! FieldDeclaration) continue;
    final type = member.fields.type;
    if (type is! NamedType || type.toSource() != 'IconData') continue;
    final variable = member.fields.variables.firstOrNull;
    final init = variable?.initializer;
    if (variable == null) continue;
    // SDK 里写作 `IconData(0xe384, ...)`（无 new）—— analyzer 解析成
    // `MethodInvocation`，不是 `InstanceCreationExpression`；两种形态都要认。
    final ArgumentList args;
    if (init is InstanceCreationExpression) {
      args = init.argumentList;
    } else if (init is MethodInvocation && init.methodName.name == 'IconData') {
      args = init.argumentList;
    } else {
      continue;
    }
    final positional = args.arguments.where((a) => a is! NamedExpression).firstOrNull;
    if (positional is! IntegerLiteral) continue;
    String family = 'MaterialIcons';
    var matchDirection = false;
    for (final a in args.arguments.whereType<NamedExpression>()) {
      final name = a.name.label.name;
      if (name == 'fontFamily') {
        final v = a.expression;
        if (v is SimpleStringLiteral) family = v.value;
      } else if (name == 'matchTextDirection') {
        final v = a.expression;
        if (v is BooleanLiteral) matchDirection = v.value;
      }
    }
    result[variable.name.lexeme] = SdkIcon(
      variable.name.lexeme,
      positional.value!,
      family,
      matchDirection,
    );
  }
  return _cache = result;
}
