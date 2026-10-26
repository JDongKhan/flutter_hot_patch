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

  // 主色值常量：`static const int _redPrimaryValue = 0xFFF44336;`
  final primaryByName = <String, int>{};
  for (final m in _primaryConst.allMatches(src)) {
    final v = _parseHex(m.group(2)!);
    if (v != null) primaryByName[m.group(1)!] = v;
  }

  final palettes = <String, _Palette>{};
  // MaterialColor（普通色板）：primary 可能是常量名或字面量。
  for (final m in _materialColor.allMatches(src)) {
    final primary = _resolvePrimary(m.group(2)!, primaryByName);
    if (primary == null) continue;
    palettes[m.group(1)!] = _Palette(primary, _parseShades(m.group(3)!));
  }
  // MaterialAccentColor（accent 色板）。
  final accents = <String, _Palette>{};
  for (final m in _materialAccent.allMatches(src)) {
    final primary = _resolvePrimary(m.group(2)!, primaryByName);
    if (primary == null) continue;
    accents[m.group(1)!] = _Palette(primary, _parseShades(m.group(3)!));
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
    ..writeln('// 全局注入：产物里 `Colors.red` / `Colors.red[400]` 原样求值，')
    ..writeln('// 翻译层不含任何色值表。')
    ..writeln('globalThis.Colors = (function () {')
    ..writeln('  function __c(v) { return new Color({ value: v }); }')
    ..writeln('  function __mc(primary, shades) {')
    ..writeln('    var m = new MaterialColor({ primary: primary });')
    ..writeln('    for (var k in shades) {')
    ..writeln("      m[k] = __c(shades[k]);")
    ..writeln("      m['shade' + k] = m[k];")
    ..writeln('    }')
    // SDK 里 500 档写作 `Color(_red500Value)`（常量引用），正则抽不到；它的值
    // 恒等于主色，这里按 Dart 语义补齐 `shade500` / `[500]`。
    ..writeln("    if (m['shade500'] === undefined) {")
    ..writeln("      m['500'] = m;")
    ..writeln("      m['shade500'] = m;")
    ..writeln('    }')
    ..writeln('    return m;')
    ..writeln('  }')
    ..writeln('  function __mac(primary, shades) {')
    ..writeln('    var m = new MaterialAccentColor({ primary: primary });')
    ..writeln('    for (var k in shades) {')
    ..writeln("      m[k] = __c(shades[k]);")
    ..writeln("      m['shade' + k] = m[k];")
    ..writeln('    }')
    ..writeln('    return m;')
    ..writeln('  }')
    ..writeln('  return {');
  final entries = <String>[];
  for (final e in palettes.entries) {
    entries.add('    ${e.key}: __mc(${_hex(e.value.primary)}, '
        '{${_shadesLiteral(e.value.shades)}})');
  }
  for (final e in accents.entries) {
    entries.add('    ${e.key}: __mac(${_hex(e.value.primary)}, '
        '{${_shadesLiteral(e.value.shades)}})');
  }
  for (final e in plain.entries) {
    entries.add('    ${e.key}: __c(${_hex(e.value)})');
  }
  b
    ..writeln(entries.join(',\n'))
    ..writeln('  };')
    ..writeln('})();');
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

Map<int, int> _parseShades(String body) {
  final out = <int, int>{};
  for (final m in _shadeEntry.allMatches(body)) {
    final shade = int.tryParse(m.group(1)!);
    final value = _parseHex(m.group(2)!);
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

final _primaryConst =
    RegExp(r'static const int (_\w*[Pp]rimaryValue) = (0x[0-9A-Fa-f]+)');
final _materialColor = RegExp(
  r'static const MaterialColor (\w+) = MaterialColor\(\s*([\w]+),\s*<int, Color>\{(.*?)\}\s*,?\s*\)',
  multiLine: true,
  dotAll: true,
);
final _materialAccent = RegExp(
  r'static const MaterialAccentColor (\w+) = MaterialAccentColor\(\s*([\w]+),\s*<int, Color>\{(.*?)\}\s*,?\s*\)',
  multiLine: true,
  dotAll: true,
);
final _plainColor =
    RegExp(r'static const Color (\w+) = Color\((0x[0-9A-Fa-f]+)\)');
final _shadeEntry = RegExp(r'(\d+):\s*Color\((0x[0-9A-Fa-f]+)\)');
