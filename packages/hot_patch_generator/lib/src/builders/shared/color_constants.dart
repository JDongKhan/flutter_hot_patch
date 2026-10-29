/// `Colors` 常量注入：从 Flutter SDK 的 `material/colors.dart` **自动抽取**，
/// 生成为 JS 全局对象源码。
///
/// 翻译层不再持有任何色值表：`Colors.red` / `Colors.red.shade300` /
/// `Colors.red[400]` 一律原样发射为字段访问（1:1）。SDK 新增或调整颜色常量，
/// 重新构建即生效，翻译器与运行时框架都不需要改动。
///
/// 运行时契约（`capabilities/core/color_js.dart`）：
///   - `new Color({value:int})` → `toJSON()` 输出 `'#AARRGGBB'`；
///   - `MaterialColor` 同时带 `shadeNN` 属性与数字下标（`m[400]`），
///     这样 `Colors.red[400]` 在 JS 里能正常取值。
library;

import 'dart:convert';
import 'dart:io';

/// 生成 `G.Colors = (...)()` 片段；SDK 源码不可读时返回 null（调用方告警）。
String? colorsJsSource() {
  final file = _locateColorsDart();
  if (file == null) return null;
  final src = file.readAsStringSync();

  // 色值常量表：`static const int _redPrimaryValue = 0xFFF44336;` 以及
  // accent 的 `static const int _redAccentValue = 0xFFFF5252;`。
  // 不按名字形态筛选（早期只认 `...PrimaryValue`，导致 accent 色板整体抽不到，
  // 产物里 `Colors.pinkAccent` 是 undefined → 渐变里颜色丢失 → 背景消失）。
  final primaryByName = <String, int>{};
  for (final m in _intConst.allMatches(src)) {
    final v = _parseHex(m.group(2)!);
    if (v != null) primaryByName[m.group(1)!] = v;
  }

  final palettes = <String, _Palette>{};
  // MaterialColor（普通色板）：primary 可能是常量名或字面量。
  for (final m in _materialColor.allMatches(src)) {
    final primary = _resolvePrimary(m.group(2)!, primaryByName);
    if (primary == null) continue;
    palettes[m.group(1)!] =
        _Palette(primary, _parseShades(m.group(3)!, primaryByName));
  }
  // MaterialAccentColor（accent 色板）。
  final accents = <String, _Palette>{};
  for (final m in _materialAccent.allMatches(src)) {
    final primary = _resolvePrimary(m.group(2)!, primaryByName);
    if (primary == null) continue;
    accents[m.group(1)!] =
        _Palette(primary, _parseShades(m.group(3)!, primaryByName));
  }
  // 单值常量：`static const Color black87 = Color(0xDD000000);`
  final plain = <String, int>{};
  for (final m in _plainColor.allMatches(src)) {
    final v = _parseHex(m.group(2)!);
    if (v != null) plain[m.group(1)!] = v;
  }

  if (palettes.isEmpty && accents.isEmpty && plain.isEmpty) {
    return null;
  }

  final b = StringBuffer()
    ..writeln('// ===== Colors 常量（由 Flutter SDK colors.dart 自动生成）=====')
    ..writeln('// Dart 侧 `Colors` 是 `class Colors { static const MaterialColor red = … }`，')
    ..writeln('// 产物一比一：class + static 字段（不是对象字面量）。`Colors.red[400]`')
    ..writeln('// 原样求值，翻译层不含任何色值表，重构建即跟随 SDK。')
    ..writeln('function __c(v) { return new Color({ value: v }); }')
    ..writeln('function __mc(primary, shades) {')
    ..writeln('  const m = new MaterialColor({ primary: primary });')
    ..writeln('  for (const k in shades) {')
    ..writeln('    m[k] = __c(shades[k]);')
    ..writeln('    m["shade" + k] = m[k];')
    ..writeln('  }')
    // SDK 里 500 档写作 `Color(_red500Value)`（常量引用），正则抽不到；它的值
    // 恒等于主色，这里按 Dart 语义补齐 `shade500` / `[500]`。
    ..writeln('  if (m["shade500"] === undefined) {')
    ..writeln('    m["500"] = m;')
    ..writeln('    m["shade500"] = m;')
    ..writeln('  }')
    ..writeln('  return m;')
    ..writeln('}')
    ..writeln('function __mac(primary, shades) {')
    ..writeln('  const m = new MaterialAccentColor({ primary: primary });')
    ..writeln('  for (const k in shades) {')
    ..writeln('    m[k] = __c(shades[k]);')
    ..writeln('    m["shade" + k] = m[k];')
    ..writeln('  }')
    ..writeln('  return m;')
    ..writeln('}')
    ..writeln('export class Colors {');
  final entries = <String>[];
  for (final e in palettes.entries) {
    entries.add('  static ${e.key} = __mc(${_hex(e.value.primary)}, '
        '{${_shadesLiteral(e.value.shades)}});');
  }
  for (final e in accents.entries) {
    entries.add('  static ${e.key} = __mac(${_hex(e.value.primary)}, '
        '{${_shadesLiteral(e.value.shades)}});');
  }
  for (final e in plain.entries) {
    entries.add('  static ${e.key} = __c(${_hex(e.value)});');
  }
  b
    ..writeln(entries.join('\n'))
    ..writeln('}')
    // 组件产物里 `Colors.red` 是裸引用（不带 import），沿用 G 注入约定。
    ..writeln('globalThis.Colors = Colors;');
  return b.toString();
}

/// 一个色板：主色值 + 各档位。
class _Palette {
  const _Palette(this.primary, this.shades);

  final int primary;
  final Map<int, int> shades;
}

String _shadesLiteral(Map<int, int> shades) {
  final parts = <String>[];
  for (final e in shades.entries) {
    parts.add("'${e.key}': ${_hex(e.value)}");
  }
  return parts.join(', ');
}

String _hex(int v) => '0x${v.toRadixString(16).toUpperCase().padLeft(8, '0')}';

int? _parseHex(String s) {
  final t = s.trim();
  if (t.startsWith('0x') || t.startsWith('0X')) {
    return int.tryParse(t.substring(2), radix: 16);
  }
  return int.tryParse(t);
}

int? _resolvePrimary(String raw, Map<String, int> byName) {
  final t = raw.trim();
  if (t.startsWith('0x') || t.startsWith('0X')) return _parseHex(t);
  return byName[t];
}

/// 档位值：`400: Color(0xFFFF1744)` 或 `200: Color(_redAccentValue)`。
/// 常量引用按 [byName] 还原——不认引用会让该档缺失（accent 的 200 档就是这样）。
Map<int, int> _parseShades(String body, Map<String, int> byName) {
  final out = <int, int>{};
  for (final m in _shadeEntry.allMatches(body)) {
    final shade = int.tryParse(m.group(1)!);
    final value = _resolvePrimary(m.group(2)!, byName);
    if (shade != null && value != null) out[shade] = value;
  }
  return out;
}

File? _locateColorsDart() {
  // 1) Dart 可执行文件推断 SDK：<sdk>/bin/dart → <sdk>。
  final candidates = <String>[];
  final exe = File(Platform.resolvedExecutable).parent.parent.path;
  candidates.add('$exe/packages/flutter/lib/src/material/colors.dart');
  // 2) 环境变量。
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null) {
    candidates.add('$env/packages/flutter/lib/src/material/colors.dart');
  }
  // 3) `.dart_tool/package_config.json` 里 flutter 包的根目录（最可靠：无论
  //    是 fvm / 全局 SDK 还是自定义路径，构建时一定有这份配置）。
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final cfg = File('${dir.path}/.dart_tool/package_config.json');
    if (cfg.existsSync()) {
      final root = _flutterPackageRoot(cfg);
      if (root != null) {
        candidates.add('$root/lib/src/material/colors.dart');
      }
      break;
    }
    if (dir.parent.path == dir.path) break;
    dir = dir.parent;
  }
  for (final path in candidates) {
    final f = File(path);
    if (f.existsSync()) return f;
  }
  return null;
}

/// package_config.json → flutter 包的绝对根目录；解析失败返回 null。
String? _flutterPackageRoot(File cfg) {
  try {
    final json = jsonDecode(cfg.readAsStringSync());
    final packages = json is Map ? json['packages'] : null;
    if (packages is! List) return null;
    for (final p in packages) {
      if (p is! Map || p['name'] != 'flutter') continue;
      final uri = p['rootUri'];
      if (uri is! String) return null;
      final base = cfg.parent.parent.uri; // .dart_tool/ 的上一级
      return base.resolve(uri).toFilePath();
    }
  } catch (_) {
    return null;
  }
  return null;
}

/// 色值 int 常量（普通色板主色、accent 主色、各档位引用都从这里取值）。
final _intConst = RegExp(r'static const int (\w+)\s*=\s*(0x[0-9A-Fa-f]+)');
// 声明体允许跨行（SDK 里 `pinkAccent =` 与 `MaterialAccentColor(...)` 常分行写，
// 只按单空格匹配会让整条色板被漏掉）。
final _materialColor = RegExp(
  r'static const MaterialColor (\w+)\s*=\s*MaterialColor\(\s*([\w]+),\s*'
  r'<int,\s*Color>\s*\{(.*?)\}\s*,?\s*\)',
  multiLine: true,
  dotAll: true,
);
final _materialAccent = RegExp(
  r'static const MaterialAccentColor (\w+)\s*=\s*MaterialAccentColor\(\s*([\w]+),\s*'
  r'<int,\s*Color>\s*\{(.*?)\}\s*,?\s*\)',
  multiLine: true,
  dotAll: true,
);
final _plainColor = RegExp(
  r'static const Color (\w+)\s*=\s*Color\((0x[0-9A-Fa-f]+)\)',
);
final _shadeEntry = RegExp(r'(\d+):\s*Color\((0x[0-9A-Fa-f]+|\w+)\)');
