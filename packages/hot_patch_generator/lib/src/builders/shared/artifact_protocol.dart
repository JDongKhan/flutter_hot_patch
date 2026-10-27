/// 产物协议版本。
///
/// 版本**直接取生成器包自身 `pubspec.yaml` 的 `version`**，发布新版即自动同步，
/// 无需再单独维护协议号。
///
/// 版本只写进 `patch/manifest.json` 的 `protocol` 字段（一个补丁包一份），
/// **不写进 JS 产物**：JS 一旦带上版本号，翻译器升级（版本变化）就会让所有 JS
/// 的 hash 跟着变，即便组件代码完全没改，增量更新与缓存都会失效。
library;

import 'dart:io';

import 'ctor_signatures.dart';

/// 当前协议版本（= 生成器包版本，如 `0.3.2`）。
String get patchProtocolVersion => _protocolVersion ??= _readPackageVersion();

String? _protocolVersion;

/// 从生成器包自身的 `pubspec.yaml` 读 `version`。
///
/// 生成器包自己的 pubspec 不是输入包的资产（build_runner 读不到别的包的
/// 文件），故按 `package_config.json` 定位包根后在磁盘上读。
///
/// 定位或解析失败直接抛错：协议号缺失会产出无法校验的产物，宁可构建失败也
/// 不能静默降级。
String _readPackageVersion() {
  final sources = PackageSources.locate();
  String? libDir;
  for (final pkg in sources?.packages ?? const <PackageRoot>[]) {
    if (pkg.name == 'hot_patch_generator') {
      libDir = pkg.libDir;
      break;
    }
  }
  if (libDir == null) {
    throw StateError('[hot_patch_generator] 无法从 .dart_tool/package_config.json '
        '定位生成器包，patch 协议版本（protocol）无从获取。');
  }
  final pubspec = File('${File(libDir).parent.path}/pubspec.yaml');
  final version = _pubspecVersion(pubspec);
  if (version == null) {
    throw StateError('[hot_patch_generator] ${pubspec.path} 中未找到 version，'
        '无法生成 patch 协议版本（protocol）。');
  }
  return version;
}

/// pubspec 顶层 `version:` 字段值（去掉引号）；缺失返回 null。
String? _pubspecVersion(File pubspec) {
  if (!pubspec.existsSync()) return null;
  for (final line in pubspec.readAsLinesSync()) {
    if (!line.startsWith('version:')) continue;
    final value = line
        .substring('version:'.length)
        .trim()
        .replaceAll(RegExp(r'''^["']|["']$'''), '');
    if (value.isNotEmpty) return value;
  }
  return null;
}
