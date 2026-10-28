/// 运行时注入的全局类型名：构建期从生成器 `runtime/js/**` 源码自动抽取
/// （`G.<Name> = …`，如 `G.KeyEvent` / `G.FocusNode`）。
///
/// 用途：翻译 `x is T` 时判断 T 在 JS 侧是否真的存在——`instanceof` 遇到未定义
/// 的构造函数会直接抛 ReferenceError，因此只对**确实注入**的类型生成判断，
/// 其余（三方包类型 / 只有签名表的类型）保持「不可翻译」。
///
/// 新增注入类 = 在 JS 片段里写一行 `G.X = …`，这里自动可见，无需登记。
library;

import 'dart:io';

import 'package_sources.dart';

/// 运行时注入的全局类型名集合。
Set<String> runtimeGlobalTypes() => _RuntimeGlobalTypes.instance.types;

/// 进程内只扫描一次（build_runner 的多个 builder 共用）。
class _RuntimeGlobalTypes {
  const _RuntimeGlobalTypes(this.types);

  final Set<String> types;

  /// 全局注入语句：`G.FocusNode = FocusNode;`。
  static final _globalAssign = RegExp(r'\bG\.([A-Z][A-Za-z0-9_$]*)\s*=');

  static final _RuntimeGlobalTypes instance = _scan();

  static _RuntimeGlobalTypes _scan() {
    final types = <String>{};
    final sources = PackageSources.locate();
    final pkg = sources?.byName('hot_patch_generator');
    if (pkg == null) return const _RuntimeGlobalTypes(<String>{});
    final dir = Directory('${pkg.libDir}${Platform.pathSeparator}src'
        '${Platform.pathSeparator}builders${Platform.pathSeparator}runtime'
        '${Platform.pathSeparator}js');
    if (!dir.existsSync()) return const _RuntimeGlobalTypes(<String>{});
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();
      for (final m in _globalAssign.allMatches(src)) {
        types.add(m.group(1)!);
      }
    }
    return _RuntimeGlobalTypes(types);
  }
}
