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

/// 运行时登记的**类型别名**（`__jsTypeAlias('BuildContext', JsBuildContext)`）。
///
/// 与 [runtimeGlobalTypes] 分开：别名类（BuildContext 代理）没有挂到
/// `G.<Name>`，不能用于 `instanceof` 判断；但 `extension X on BuildContext`
/// 这类目标类型在 JS 侧确实有构造函数，构建期校验需要知道它们。
Set<String> runtimeTypeAliases() => _RuntimeGlobalTypes.instance.aliases;

/// 运行时注入的**全局函数**名（`G.showDialog = function (…) {…}`）。
///
/// 用途：Dart 里的裸顶层调用（`showDialog<bool>(…)`）在 JS 侧没有 `this` 也没有
/// 宿主通道可映射，只有在运行时存在同名全局函数时才能翻译。与 [runtimeGlobalTypes]
/// 分开：函数名是小写开头，永远不能用于 `instanceof` / 静态成员解析。
///
/// 新增注入函数 = 在 JS 片段里写一行 `G.<name> = function …`，这里自动可见。
Set<String> runtimeGlobalFunctions() => _RuntimeGlobalTypes.instance.functions;

/// 进程内只扫描一次（build_runner 的多个 builder 共用）。
class _RuntimeGlobalTypes {
  const _RuntimeGlobalTypes(this.types, this.aliases, this.functions);

  final Set<String> types;

  /// 运行时登记的别名（`__jsTypeAlias('BuildContext', …)`）。
  final Set<String> aliases;

  /// 运行时注入的全局函数（`G.showDialog = function …`）。
  final Set<String> functions;

  /// 全局注入语句：`G.FocusNode = FocusNode;`。
  static final _globalAssign = RegExp(r'\bG\.([A-Z][A-Za-z0-9_$]*)\s*=');

  /// 全局函数注入语句：`G.showDialog = function (…) {`（关键词 `function`
  /// 排除 `G.foo = new Foo()` 这类同名对象注入，避免把对象当函数调用）。
  static final _globalFnAssign =
      RegExp(r'\bG\.([a-z][A-Za-z0-9_$]*)\s*=\s*function\b');

  /// 别名登记语句：`__jsTypeAlias('BuildContext', JsBuildContext);`。
  static final _typeAlias = RegExp(r"__jsTypeAlias\(\s*'([A-Za-z0-9_$]+)'");

  static final _RuntimeGlobalTypes instance = _scan();

  static _RuntimeGlobalTypes _scan() {
    final types = <String>{};
    final aliases = <String>{};
    final functions = <String>{};
    final sources = PackageSources.locate();
    final pkg = sources?.byName('hot_patch_generator');
    if (pkg == null) return _RuntimeGlobalTypes(<String>{}, <String>{}, <String>{});
    final dir = Directory('${pkg.libDir}${Platform.pathSeparator}src'
        '${Platform.pathSeparator}builders${Platform.pathSeparator}runtime'
        '${Platform.pathSeparator}js');
    if (!dir.existsSync()) {
      return _RuntimeGlobalTypes(<String>{}, <String>{}, <String>{});
    }
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();
      for (final m in _globalAssign.allMatches(src)) {
        types.add(m.group(1)!);
      }
      for (final m in _globalFnAssign.allMatches(src)) {
        functions.add(m.group(1)!);
      }
      for (final m in _typeAlias.allMatches(src)) {
        aliases.add(m.group(1)!);
      }
    }
    return _RuntimeGlobalTypes(types, aliases, functions);
  }
}
