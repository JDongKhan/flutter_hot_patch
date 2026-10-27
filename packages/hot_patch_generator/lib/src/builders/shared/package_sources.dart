/// Dart 源码包定位：从 `.dart_tool/package_config.json` 解析各依赖包的 lib 目录。
///
/// 两处共用同一份定位结果：
///   - **构造签名抽取**（ctor_signatures）：项目类 / Flutter SDK / 全部依赖包；
///   - **跨包 import 解析**（source_index）：把 `package:foo/x.dart` 映射成真实
///     源文件，并区分「本地包」与「三方宿主包」。
///
/// **本地包**（path 依赖 / workspace 成员）的 `rootUri` 是相对 URI，参与跨包
/// 翻译；**三方宿主包**（pub cache）只用于抽签名，不翻译（其类型在 JS 侧没有
/// 等价实现，仍走宿主注入 / 原生占位）。
library;

import 'dart:convert';
import 'dart:io';

/// 一个包：包名 + 包根目录 + lib 目录 + 是否本地包。
class PackageRoot {
  const PackageRoot(
    this.name,
    this.libDir, {
    this.rootDir = '',
    this.isLocal = false,
  });

  final String name;

  /// 包根目录（lib 的上级），用于判断「构建目标包」。
  final String rootDir;

  /// lib 目录绝对路径。
  final String libDir;

  /// 本地包：`rootUri` 是相对 URI（path 依赖 / workspace 成员）。
  final bool isLocal;

  /// 包内有 lib 目录（可参与翻译 / 构造签名抽取）。workspace 根包这类
  /// 「无 lib 的聚合包」不满足，需排除——否则会被当成跨包翻译目标白产一个空模块。
  bool get hasLib => Directory(libDir).existsSync();
}

/// Dart 源码包定位（进程级单例）。
///
/// build_runner 在**构建目标包**目录运行，故以入口脚本
/// （`<包根>/.dart_tool/build/entrypoint/build.dart`）为准定位包根，
/// `Directory.current` 仅作兜底——隔离区里 current 可能是临时目录。
class PackageSources {
  PackageSources._(this.projectName, this.projectRoot, this.packages);

  /// 构建目标包名（产物 `lib/...` 身份所属的包）。
  final String projectName;

  /// 构建目标包根目录（绝对路径）。
  final String projectRoot;

  /// 全部可见包（项目 + 依赖，含 dart:core / dart:ui），按优先级排序。
  final List<PackageRoot> packages;

  static PackageSources? _instance;

  static PackageSources? get instance => _instance ??= locate();

  static PackageSources? locate() {
    // build_runner 的入口脚本位于 `<包根>/.dart_tool/build/entrypoint/build.dart`。
    final roots = <String>[];
    final scriptRoot = _projectRootFromScript();
    if (scriptRoot != null) roots.add(scriptRoot);
    roots.add(Directory.current.path);
    for (final root in roots) {
      var dir = Directory(root);
      for (var i = 0; i < 6; i++) {
        final config = File(_join(dir.path, '.dart_tool/package_config.json'));
        if (config.existsSync()) return _read(config, root, dir.path);
        if (dir.parent.path == dir.path) break;
        dir = dir.parent;
      }
    }
    return null;
  }

  /// 入口脚本路径反推构建目标包根；取不到返回 null。
  static String? _projectRootFromScript() {
    if (Platform.script.scheme != 'file') return null;
    try {
      final path = File.fromUri(Platform.script).parent.path;
      const suffix = '.dart_tool/build/entrypoint';
      final i = path.lastIndexOf(suffix);
      if (i <= 0) return null;
      var root = path.substring(0, i);
      while (root.endsWith('/')) {
        root = root.substring(0, root.length - 1);
      }
      return root.isEmpty ? null : root;
    } catch (_) {
      return null;
    }
  }

  static PackageSources? _read(File config, String projectRootHint, String configDir) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
    // rootUri 是相对 **package_config.json 自身**解析的 URI 引用（pub 规范）：
    // 工作区里 `../packages/hot_patch` 相对 `.dart_tool/` 才是仓库根，
    // 故基准必须是配置文件 URI，而不是它的上级目录。
    final base = config.uri;
    final roots = <PackageRoot>[];
    for (final p in (json['packages'] as List<dynamic>? ?? const [])) {
      if (p is! Map<String, dynamic>) continue;
      final name = p['name'] as String? ?? '';
      final rootUri = p['rootUri'] as String? ?? '';
      if (name.isEmpty || rootUri.isEmpty) continue;
      // 本地包判据：rootUri 是相对引用（path 依赖 / workspace 成员）；
      // pub cache 里的宿主包是绝对 file: URI。
      final isLocal = !rootUri.contains(':');
      final resolved =
          base.resolve(rootUri.endsWith('/') ? rootUri : '$rootUri/');
      if (resolved.scheme != 'file') continue;
      final root = resolved.toFilePath();
      roots.add(PackageRoot(
        name,
        _join(root, 'lib'),
        rootDir: _stripTrailingSlash(root),
        isLocal: isLocal,
      ));
    }
    // Dart SDK 与 dart:ui（sky_engine）：`Size` / `Color` / `StateError` 等核心库
    // 类型不在 package_config 里，按 SDK 路径补充。它们排最后，同名类以项目 /
    // flutter 包为准。
    final exe = File(Platform.resolvedExecutable);
    final dartSdk = exe.parent.parent.path;
    roots.add(PackageRoot('dart:core', _join(dartSdk, 'lib'),
        rootDir: dartSdk));
    roots.add(PackageRoot('dart:ui', _join(dartSdk, '../pkg/sky_engine/lib'),
        rootDir: dartSdk));
    // 构建目标包：其包根 = package_config 所在目录树的「构建目标目录」
    // （构建目标目录总是 package_config 所在目录的子孙）。
    final projectRoot = _resolveProjectRoot(roots, projectRootHint, configDir);
    var projectName = '';
    for (final r in roots) {
      if (r.rootDir == projectRoot) {
        projectName = r.name;
        break;
      }
    }
    if (projectName.isEmpty) projectName = _pubspecName(projectRoot);
    roots.sort((a, b) {
      int rank(PackageRoot r) => r.name == projectName
          ? 0
          : r.name == 'flutter'
              ? 1
              : r.name.startsWith('dart:')
                  ? 2
                  : 3;
      return rank(a).compareTo(rank(b));
    });
    return PackageSources._(projectName, projectRoot, roots);
  }

  /// 构建目标包根：优先入口脚本所在目录；否则取「package_config 所在目录」
  /// （无工作区时二者相同）。
  static String _resolveProjectRoot(
    List<PackageRoot> roots,
    String projectRootHint,
    String configDir,
  ) {
    for (final r in roots) {
      if (r.rootDir == projectRootHint) return r.rootDir;
    }
    // 无工作区：包根即 `.dart_tool/` 的上级目录。
    final parent = Directory(configDir).path;
    for (final r in roots) {
      if (r.rootDir == parent) return r.rootDir;
    }
    return parent;
  }

  static String _pubspecName(String root) {
    final pubspec = File(_join(root, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return '';
    for (final line in pubspec.readAsLinesSync()) {
      if (line.startsWith('name:')) return line.substring(5).trim();
    }
    return '';
  }

  /// 按包名取包信息。
  PackageRoot? byName(String name) {
    for (final r in packages) {
      if (r.name == name) return r;
    }
    return null;
  }

  /// 该包是否参与跨包翻译（本地包）。
  bool isLocalPackage(String name) => byName(name)?.isLocal ?? false;

  /// `package:foo/bar.dart` → 源文件绝对路径；非 package URI / 解析不到返回 null。
  String? fileOfPackageUri(String uri) {
    if (!uri.startsWith('package:')) return null;
    final slash = uri.indexOf('/', 'package:'.length);
    if (slash <= 'package:'.length || slash >= uri.length - 1) return null;
    final pkg = uri.substring('package:'.length, slash);
    final rel = uri.substring(slash + 1);
    final root = byName(pkg);
    if (root == null) return null;
    return _join(root.libDir, rel);
  }
}

String _join(String a, String b) =>
    a.endsWith(Platform.pathSeparator) ? '$a$b' : '$a${Platform.pathSeparator}$b';

String _stripTrailingSlash(String p) =>
    p.endsWith(Platform.pathSeparator) ? p.substring(0, p.length - 1) : p;
