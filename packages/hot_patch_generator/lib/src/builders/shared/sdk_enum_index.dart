/// SDK 枚举索引：把 Flutter framework 里**公开的 `enum` 声明**连同成员名
/// 抽出来，供 `flutter.js` 生成同名 JS 值类。
///
/// 为什么要抽而不是手写：翻译层对 `Owner.member` 一律**原样引用**（见
/// value_forms.dart），产物里会出现 `CrossAxisAlignment.baseline`。JS 侧必须
/// 真的存在这个类与静态成员，否则运行期是 ReferenceError。这份「Dart 枚举 →
/// JS 类」的对应关系只能来自源码事实（SDK 源码里的 `enum` 声明），不能靠
/// 类名白名单维护，否则新增/变更枚举就要人肉跟改。
///
/// 判据与翻译层一致：`enum` 声明本身、成员按源码书写顺序（同 Dart 的
/// `index` 语义）。带常量参数的枚举（`enum E { a(1) }`）不生成——JS 侧无法
/// 还原参数语义，构建期出声，交由后续能力模块承接。
library;

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';

import 'package_sources.dart';
import 'source_index.dart';

/// 一个公开枚举：名字 → 成员名（源码顺序即 `index`）。
class SdkEnum {
  const SdkEnum(this.name, this.members, this.filePath);

  final String name;
  final List<String> members;

  /// 声明所在源文件（构建期日志用）。
  final String filePath;
}

Map<String, SdkEnum>? _cache;

/// Flutter framework 的公开枚举（名字 → 声明）。结果进程级缓存。
///
/// 只扫 `flutter` 包（framework 主体）；`dart:ui` 的枚举在 JS 侧没有对应宿主
/// 还原路径，传给宿主时仍需字符串，故不在此处生成（见 value_forms.dart 的
/// 说明）。
Map<String, SdkEnum> sdkPublicEnums() {
  final cached = _cache;
  if (cached != null) return cached;
  final result = <String, SdkEnum>{};
  final sources = PackageSources.instance;
  if (sources == null) return _cache = result;
  // 扫 framework 主体（`flutter`）与引擎的 `dart:ui`：`TextAlign` /
  // `TextBaseline` / `TextDirection` 这类核心枚举声明在 dart:ui 而非 flutter 包，
  // 只扫前者会漏掉它们（产物里同样是原样引用，必须都有 JS 类）。
  final libDirs = <String>[
    for (final p in sources.packages)
      if (p.name == 'flutter' || p.name == 'dart:ui') p.libDir,
  ];
  if (libDirs.isEmpty) return _cache = result;

  // 先按声明名定位文件（正则只判断文件里有无顶层 `enum`，成员靠 AST 读）。
  final decl = RegExp(
    r'^[ \t]*(?:@[\w.]+(?:[ \t]*\([^)]*\))?[ \t]*\r?\n[ \t]*)*'
    r'enum[ \t]+([A-Za-z_$][\w$]*)',
    multiLine: true,
  );
  for (final libDir in libDirs) {
    final dir = Directory(libDir);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      if (!decl.hasMatch(content)) continue;
      final unit = parseUnitFile(entity.path);
      if (unit == null) continue;
      for (final d in unit.declarations.whereType<EnumDeclaration>()) {
        final enumName = d.name.lexeme;
        if (enumName.startsWith('_')) continue;
        final members = d.constants;
        // 带常量参数的枚举（`a(1)`）无法在 JS 侧还原语义，出声跳过。
        if (members.any((m) => m.arguments != null)) {
          // ignore: avoid_print - 构建期日志
          print('[hot_patch_generator] 枚举 $enumName（${entity.path}）带常量参数，'
              '未生成 JS 值类：产物若引用其成员需补能力模块');
          continue;
        }
        result.putIfAbsent(
          enumName,
          () => SdkEnum(
            enumName,
            [for (final m in members) m.name.lexeme],
            entity.path,
          ),
        );
      }
    }
  }
  return _cache = result;
}
