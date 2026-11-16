/// 产物路径推导（纯路径函数，无源码分析）：源文件 → JS 产物路径、产物间相对路径。
///
///   - **本项目包**源文件（`lib/a/b.dart`）→ `patch/a/b.js`：镜像 lib 路径、
///     文件名与源文件同名，不预设固定目录名，也不区分组件/模型；
///   - **本地依赖包**源文件（`package:foo/src/a.dart`）→
///     `patch/packages/foo/src/a.js`：按原文件同名镜像到包目录下，一个源文件
///     一份产物（包内 `lib/` 结构互相隔离在各自的包目录里）；
///   - **框架包**（`package:flutter/...` 等不参与跨包翻译的包）→
///     `patch/flutter.js`：整包一个模块，由 `ui_widget` 产出。
library;

import 'js_class_defs.dart' show packageModulePath;
import 'package_sources.dart';
import 'source_index.dart';

/// 参与「按原文件镜像」的依赖包产物根目录：`patch/packages/<package>/...`。
///
/// 加一层 `packages/` 是为了与本项目 `patch/<lib 相对路径>.js` 彻底隔离：
/// 若项目 `lib/` 下恰好存在与依赖包同名的目录，直接放 `patch/<package>/`
/// 会与项目产物撞名。
const String packageProductsRoot = 'patch/packages';

/// 本地依赖包是否按原文件路径镜像产物（判据与跨包翻译范围同口径）：
/// 本地包（path 依赖 / workspace 成员）、有 lib、非构建目标包、非框架包。
///
/// 结果按包名缓存：build_runner 进程内包集合稳定，避免每次产物路径推导都
/// 遍历包列表。
final Map<String, bool> _fileLayoutPackages = {};

bool isFileLayoutPackage(String package) => _fileLayoutPackages.putIfAbsent(
      package,
      () {
        final sources = PackageSources.instance;
        if (sources == null) return false;
        if (package == sources.projectName) return false;
        if (nonTranslatedPackages.contains(package)) return false;
        for (final r in sources.packages) {
          if (r.name == package) return r.isLocal && r.hasLib;
        }
        return false;
      },
    );

/// 依赖包源文件 → 产物路径 `patch/packages/<package>/<lib 内相对路径>.js`。
///
/// 只对满足 [isFileLayoutPackage] 的包调用。`package:` URI 的 path 是
/// `<package>/<lib 内相对路径>`（如 `package:foo/src/a.dart` 的 path 为
/// `foo/src/a.dart`），故先去掉包名前缀，再去 `.dart` 后缀。
String packageSourceProductPath(String sourcePath) {
  final pkg = packageNameOf(sourcePath);
  if (pkg == null) return sourcePath;
  final path = Uri.parse(sourcePath).path;
  final prefix = '$pkg/';
  if (!path.startsWith(prefix)) return packageModulePath(pkg);
  var rel = path.substring(prefix.length);
  if (rel.endsWith('.dart')) {
    rel = rel.substring(0, rel.length - '.dart'.length);
  }
  if (rel.isEmpty) return packageModulePath(pkg);
  return '$packageProductsRoot/$pkg/$rel.js';
}

/// 源文件身份 → 产物路径（与 build.yaml 的 build_extensions 一致）。
String productPath(String sourcePath) {
  if (sourcePath.startsWith('package:')) {
    final pkg = packageNameOf(sourcePath);
    if (pkg == null) return sourcePath;
    return isFileLayoutPackage(pkg)
        ? packageSourceProductPath(sourcePath)
        : packageModulePath(pkg);
  }
  if (!sourcePath.startsWith('lib/')) return sourcePath;
  final rel = sourcePath.substring('lib/'.length); // a/b.dart
  if (!rel.endsWith('.dart')) return sourcePath;
  return 'patch/${rel.substring(0, rel.length - '.dart'.length)}.js';
}

/// 产物相对路径 → 产物绝对路径（按 [base] 所在目录解析 `.` / `..`）。
///
/// [relativeProduct] 的逆运算：解析器 / 生成器给出相对路径后，需要还原成
/// 「产物身份」（`patch/a/b.js`）才能比较「是不是同一个产物」。
String productJoin(String base, String relative) {
  final dir = base.substring(0, base.lastIndexOf('/') + 1);
  final segs = <String>[for (final p in dir.split('/')) if (p.isNotEmpty) p];
  for (final part in relative.split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (segs.isNotEmpty) segs.removeLast();
    } else {
      segs.add(part);
    }
  }
  return segs.join('/');
}

/// 两个产物绝对路径 → 相对路径（相对第一个产物所在目录）。
/// 如 'patch/foo_component.js' → 'patch/sub/bar_component.js'
/// 得 'sub/bar_component.js'；跨目录时含 '../'。
String relativeProduct(String from, String to) {
  final fromDir = from.substring(0, from.lastIndexOf('/') + 1);
  final fromSegs = fromDir.split('/').where((p) => p.isNotEmpty).toList();
  final toSegs = to.split('/').where((p) => p.isNotEmpty).toList();
  // 公共前缀长度
  var common = 0;
  while (common < fromSegs.length &&
      common < toSegs.length - 1 &&
      fromSegs[common] == toSegs[common]) {
    common++;
  }
  final ups = List.filled(fromSegs.length - common, '..');
  final downs = toSegs.skip(common).toList();
  return [...ups, ...downs].join('/');
}
