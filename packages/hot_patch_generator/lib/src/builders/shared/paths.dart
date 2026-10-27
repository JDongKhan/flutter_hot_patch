/// 产物路径推导（纯路径函数，无源码分析）：源文件 → JS 产物路径、产物间相对路径。
///
///   - **本项目包**源文件（`lib/a/b.dart`）→ `patch/a/b.js`：镜像 lib 路径、
///     文件名与源文件同名，不预设固定目录名，也不区分组件/模型；
///   - **跨包**源文件（`package:foo/a/b.dart`）→ `patch/foo.js`：一个本地依赖包
///     的所有被引用类集中在**一个包模块**里（与 [packageModulePath] 同一约定），
///     避免不同包的 `lib/` 结构互相撞名，也让跨包产物天然只有一份实现。
library;

import 'source_index.dart';

/// 源文件身份 → 产物路径（与 build.yaml 的 build_extensions 一致）。
String productPath(String sourcePath) {
  if (sourcePath.startsWith('package:')) {
    final pkg = packageNameOf(sourcePath);
    return pkg == null ? sourcePath : 'patch/$pkg.js';
  }
  if (!sourcePath.startsWith('lib/')) return sourcePath;
  final rel = sourcePath.substring('lib/'.length); // a/b.dart
  if (!rel.endsWith('.dart')) return sourcePath;
  return 'patch/${rel.substring(0, rel.length - '.dart'.length)}.js';
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
