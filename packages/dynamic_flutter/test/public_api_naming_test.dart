import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 公开 API 命名约定（见 `docs/项目架构文档.md` §5.1）：
/// `dynamic_flutter.dart` 导出的类型名统一以 `Js` 开头；小驼峰全局入口（函数 /
/// 变量）不受此约束。被一比一翻译的组件 / 值类 / 三方库类不在本包公开面内。
void main() {
  test('dynamic_flutter 公开类型统一使用 Js 前缀', () {
    final root = _packageRoot();
    final barrel = File('${root.path}/lib/dynamic_flutter.dart').readAsStringSync();
    final exports = _exportsOf(barrel, root.path);
    expect(exports, isNotEmpty, reason: '未解析到任何 export，检查 barrel 解析逻辑');
    final violations = <String>{};

    for (final export in exports) {
      final path = export.path;
      final shown = export.shown;
      if (shown != null) {
        for (final name in shown) {
          if (_isTypeName(name) && !name.startsWith('Js')) {
            violations.add('$path → $name');
          }
        }
        continue;
      }
      for (final name in _publicTypesOf(File(path).readAsStringSync())) {
        if (!name.startsWith('Js')) violations.add('$path → $name');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: '以下公开类型未使用 Js 前缀：\n${violations.join('\n')}',
    );
  });
}

/// 测试可能从仓库根或包目录启动，向上找到 `name: dynamic_flutter` 的 pubspec。
Directory _packageRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync() &&
        pubspec.readAsStringSync().contains(
          RegExp(r'^name:\s*dynamic_flutter$', multiLine: true),
        )) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('未找到 dynamic_flutter 包根（cwd: ${Directory.current.path}）');
    }
    dir = parent;
  }
}

/// 解析 barrel 里的 `export 'path' [show a, b];`，并递归展开 re-export。
List<({String path, List<String>? shown})> _exportsOf(
  String source,
  String packageRoot,
) {
  final out = <({String path, List<String>? shown})>[];
  final seen = <String>{};
  void walk(String src, String baseDir) {
    for (final m in _exportPattern.allMatches(src)) {
      final path = '$baseDir/${m.group(1)!}';
      if (!seen.add(path)) continue;
      final shownRaw = m.group(2);
      final shown = shownRaw
          ?.split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      out.add((path: path, shown: shown));
      if (shown == null && File(path).existsSync()) {
        walk(File(path).readAsStringSync(), baseDir);
      }
    }
  }

  walk(source, '$packageRoot/lib');
  return out;
}

final _exportPattern = RegExp(
  r"export\s+'([^']+)'\s*(?:show\s+([^;]+))?;",
  multiLine: true,
);

final _typePattern = RegExp(
  r'^(?:abstract\s+|final\s+|sealed\s+|base\s+|interface\s+)?'
  r'(?:class|enum|mixin|typedef|extension)\s+([A-Za-z_]\w*)',
  multiLine: true,
);

List<String> _publicTypesOf(String source) => [
  for (final m in _typePattern.allMatches(source))
    if (!m.group(1)!.startsWith('_')) m.group(1)!,
];

bool _isTypeName(String name) =>
    name.isNotEmpty && name[0].toUpperCase() == name[0];
