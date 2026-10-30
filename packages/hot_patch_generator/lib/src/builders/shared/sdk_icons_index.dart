/// Material 图标常量索引：把 `Icons` 表从 SDK 源码抽出来，供 `flutter.js`
/// 生成同名 JS 常量（`IconData` 实例）。
///
/// 与枚举同一原则：翻译层对 `Icons.edit` 是**原样引用**（见 value_forms.dart），
/// 因此 JS 侧必须真的存在这些名字。表的来源只能是 SDK 源码（
/// `material/icons.dart` 里的 `static const IconData xxx = IconData(0xe000, ...)`），
/// 不能靠手写白名单——旧实现用一张几十条的手写表 + 未命中回退 `Icons.circle`，
/// 既漏图标又把失败变成了静默降级。
library;

import 'dart:io';

import 'package_sources.dart';

/// 一个 IconData 常量：名字 → 码点 / 字体族 / 是否随文字方向翻转。
class SdkIcon {
  const SdkIcon(this.name, this.codePoint, this.fontFamily, this.matchTextDirection);

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

  // `static const IconData name = IconData(0xe000, fontFamily: 'MaterialIcons'
  // , matchTextDirection: true);`——参数顺序在 SDK 里固定为码点在前、其余具名。
  final decl = RegExp(
    r'static const IconData (\w+) = IconData\((0x[0-9a-fA-F]+)'
    r"(?:[^;]*?fontFamily: '([^']+)')?"
    r'([^;]*?)\);',
  );
  for (final m in decl.allMatches(file.readAsStringSync())) {
    final name = m.group(1)!;
    final code = int.tryParse(m.group(2)!.substring(2), radix: 16);
    if (code == null) continue;
    result.putIfAbsent(
      name,
      () => SdkIcon(
        name,
        code,
        m.group(3) ?? 'MaterialIcons',
        m.group(4)?.contains('matchTextDirection: true') ?? false,
      ),
    );
  }
  return _cache = result;
}
