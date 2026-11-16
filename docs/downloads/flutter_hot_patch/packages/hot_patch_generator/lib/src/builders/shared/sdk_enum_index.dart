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
/// 还原参数语义；它们记入 [sdkUnsupportedEnums]，**只有产物真的引用其成员时**
/// 才由翻译层出声（避免对整包 SDK 枚举逐条刷告警）。
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

/// 带常量参数、**未生成 JS 值类**的枚举：名字 → 声明文件。
///
/// 翻译层在产物里引用到这些枚举成员时出声（见 js_translator），索引阶段保持
/// 安静——整包 SDK 里这类枚举不少，但绝大多数项目根本不引用。
Map<String, String> _unsupported = const {};

/// 带常量参数、未生成 JS 值类的 SDK 枚举（名字 → 声明文件）。
Map<String, String> sdkUnsupportedEnums() {
  sdkPublicEnums(); // 确保索引已建立
  return _unsupported;
}

/// Flutter framework 的公开枚举（名字 → 声明）。结果进程级缓存。
///
/// 只扫 `flutter` 包（framework 主体）；`dart:ui` 的枚举在 JS 侧没有对应宿主
/// 还原路径，传给宿主时仍需字符串，故不在此处生成（见 value_forms.dart 的
/// 说明）。
Map<String, SdkEnum> sdkPublicEnums() {
  final cached = _cache;
  if (cached != null) return cached;
  final result = <String, SdkEnum>{};
  final unsupported = <String, String>{};
  final sources = PackageSources.instance;
  if (sources == null) {
    _unsupported = unsupported;
    return _cache = result;
  }
  // 扫 framework 主体（`flutter`）与引擎的 `dart:ui`：`TextAlign` /
  // `TextBaseline` / `TextDirection` 这类核心枚举声明在 dart:ui 而非 flutter 包，
  // 只扫前者会漏掉它们（产物里同样是原样引用，必须都有 JS 类）。
  final libDirs = <String>[
    for (final p in sources.packages)
      if (p.name == 'flutter' || p.name == 'dart:ui') p.libDir,
  ];
  if (libDirs.isEmpty) {
    _unsupported = unsupported;
    return _cache = result;
  }

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
        // 带常量参数的枚举（`a(1)`）无法在 JS 侧还原语义：不生成值类，记入
        // unsupported，等翻译层真的引用到它时再出声（见 sdkUnsupportedEnums）。
        if (members.any((m) => m.arguments != null)) {
          unsupported.putIfAbsent(enumName, () => entity.path);
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
  _unsupported = unsupported;
  return _cache = result;
}
