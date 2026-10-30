/// 运行时注入的全局类型名：构建期从生成器 `runtime/js/**` 源码自动抽取
/// （`G.<Name> = …` 与值类区的 `export class` / `export const`，如
/// `G.KeyEvent` / `export class Color`）。
///
/// 用途：① 翻译 `x is T` 时判断 T 在 JS 侧是否真的存在——`instanceof` 遇到未定义
/// 的构造函数会直接抛 ReferenceError；② 产物按实际出现的运行时名字补
/// `import { … } from '../flutter.js'`（值类不再是全局，靠 import 解析）。
///
/// 新增注入类 = 在 JS 片段里写一行 `G.X = …`（runtime.js 核心）或
/// `export class X`（flutter.js 值类区），这里自动可见，无需登记。
library;

import 'dart:io';

import 'package_sources.dart';
import 'sdk_enum_index.dart';

/// 运行时注入的全局类型名集合（`G.X` 全局 + `export` 值类，供 `is T` 与静态调用）。
Set<String> runtimeGlobalTypes() => _RuntimeGlobalTypes.instance.types;

/// `flutter.js` **实际导出**的类型/常量名（`export class` / `export const`）。
///
/// 与 [runtimeGlobalTypes] 分开的唯一原因：产物 import 只能指向模块导出。
/// `G.StateError` 这类只存在于 runtime.js（IIFE，globalThis）上的名字由
/// 裸引用解析，绝不能写进 `import { … } from '../flutter.js'`（会 import
/// 不存在的导出直接语法报错）。
Set<String> flutterExportTypes() => _RuntimeGlobalTypes.instance.exports;

/// 运行时登记的**类型别名**（`__jsTypeAlias('BuildContext', JsBuildContext)`）。
///
/// 与 [runtimeGlobalTypes] 分开：别名类（BuildContext 代理）没有挂到
/// `G.<Name>`，不能用于 `instanceof` 判断；但 `extension X on BuildContext`
/// 这类目标类型在 JS 侧确实有构造函数，构建期校验需要知道它们。
Set<String> runtimeTypeAliases() => _RuntimeGlobalTypes.instance.aliases;

/// 运行时注入的**全局函数**名（`export function showDialog(…) {…}`）。
///
/// 用途：Dart 里的裸顶层调用（`showDialog<bool>(…)`）在 JS 侧没有 `this` 也没有
/// 宿主通道可映射，只有在 JS 侧存在同名函数时才能翻译。与 [runtimeGlobalTypes]
/// 分开：函数名是小写开头，永远不能用于 `instanceof` / 静态成员解析。
///
/// 新增注入函数 = 在 `flutter.js` 片段里写一行 `export function <name>(…)`，
/// 这里自动可见（同时进 [flutterExportTypes]，产物按名 import）。
Set<String> runtimeGlobalFunctions() => _RuntimeGlobalTypes.instance.functions;

/// 进程内只扫描一次（build_runner 的多个 builder 共用）。
class _RuntimeGlobalTypes {
  const _RuntimeGlobalTypes(this.types, this.aliases, this.functions, this.exports);

  final Set<String> types;

  /// `flutter.js` 的模块导出名（`export class` / `export const`）。
  final Set<String> exports;

  /// 运行时登记的别名（`__jsTypeAlias('BuildContext', …)`）。
  final Set<String> aliases;

  /// 运行时注入的全局函数（`export function showDialog …`）。
  final Set<String> functions;

  /// 全局注入语句：`G.FocusNode = FocusNode;`。
  static final _globalAssign = RegExp(r'\bG\.([A-Z][A-Za-z0-9_$]*)\s*=');

  /// 值类片段的导出声明：`export class Color {`。
  ///
  /// 值类（Color / Duration / 控制器 / Key …）迁移到 `flutter.js` 后不再挂
  /// `G.X`（组件产物按名 import）。抽取口径必须同时覆盖两种写法，否则
  /// `is T` 的类型判断与产物 import 收集都会漏。
  static final _exportClass = RegExp(r'\bexport class ([A-Z][A-Za-z0-9_$]*)');

  /// 值片段的导出常量 / 控制器：`export const MediaQuery = {`、
  /// `export const AnimationController = defineController(...)`。
  static final _exportConst = RegExp(r'\bexport const ([A-Z][A-Za-z0-9_$]*)');

  /// 全局函数注入语句：`G.foo = function (…) {`（关键词 `function` 排除
  /// `G.foo = new Foo()` 这类同名对象注入，避免把对象当函数调用）。
  static final _globalFnAssign =
      RegExp(r'\bG\.([a-z][A-Za-z0-9_$]*)\s*=\s*function\b');

  /// `flutter.js` 的顶层函数导出：`export function showDialog(options) {`。
  ///
  /// Flutter SDK 的顶层 API（showDialog / showModalBottomSheet …）在 JS 侧就是
  /// 模块导出的普通函数——产物按名 import 后裸调用，与 Dart 一比一。
  static final _exportFunction =
      RegExp(r'\bexport function ([a-z][A-Za-z0-9_$]*)');

  /// 别名登记语句：`__jsTypeAlias('BuildContext', JsBuildContext);`。
  static final _typeAlias = RegExp(r"__jsTypeAlias\(\s*'([A-Za-z0-9_$]+)'");

  static final _RuntimeGlobalTypes instance = _scan();

  static _RuntimeGlobalTypes _scan() {
    final types = <String>{};
    final aliases = <String>{};
    final functions = <String>{};
    final exports = <String>{};
    const empty = _RuntimeGlobalTypes(<String>{}, <String>{}, <String>{}, <String>{});
    final sources = PackageSources.locate();
    final pkg = sources?.byName('hot_patch_generator');
    if (pkg == null) return empty;
    final root = pkg.libDir;
    // 运行时片段目录：`builders/runtime/js/**`。
    final dir = Directory('$root${Platform.pathSeparator}src'
        '${Platform.pathSeparator}builders${Platform.pathSeparator}runtime'
        '${Platform.pathSeparator}js');
    if (!dir.existsSync()) return empty;
    // 片段之外的「值类源码」：由生成器按 Flutter SDK 自动抽取后拼进
    // `flutter.js`（`export class Colors` 就写在这些模板字符串里），
    // 同一套导出名必须可见，否则 `Colors` 这类值类不会被产物 import。
    final extras = <File>[
      File('$root${Platform.pathSeparator}src'
          '${Platform.pathSeparator}builders${Platform.pathSeparator}shared'
          '${Platform.pathSeparator}color_constants.dart'),
    ];
    final files = <File>[
      for (final entity in dir.listSync(followLinks: false))
        if (entity is File && entity.path.endsWith('.dart')) entity,
      for (final f in extras)
        if (f.existsSync()) f,
    ];
    for (final file in files) {
      final src = file.readAsStringSync();
      for (final m in _globalAssign.allMatches(src)) {
        types.add(m.group(1)!);
      }
      for (final m in _exportClass.allMatches(src)) {
        types.add(m.group(1)!);
        exports.add(m.group(1)!);
      }
      for (final m in _exportConst.allMatches(src)) {
        types.add(m.group(1)!);
        exports.add(m.group(1)!);
      }
      for (final m in _globalFnAssign.allMatches(src)) {
        functions.add(m.group(1)!);
      }
      for (final m in _exportFunction.allMatches(src)) {
        functions.add(m.group(1)!);
        exports.add(m.group(1)!);
      }
      for (final m in _typeAlias.allMatches(src)) {
        aliases.add(m.group(1)!);
      }
    }
    // 按源码自动生成的 SDK 枚举值类：它们的 `export class X` 不存在于任何
    // `.dart` 片段文本里（`enumValuesJsSource()` 在构建期按 SDK `enum` 声明
    // 动态产出），但同样是 `flutter.js` 的模块导出。口径必须一致——否则产物
    // 引用 `CrossAxisAlignment.baseline` 却不会 import 它（运行期 ReferenceError）。
    for (final name in sdkPublicEnums().keys) {
      types.add(name);
      exports.add(name);
    }
    // 同口径：`IconData` 类与 `Icons` 常量表也是构建期按 SDK 源码生成的
    // （`iconValuesJsSource()`），不在片段文本里。
    types.add('IconData');
    exports.add('IconData');
    types.add('Icons');
    exports.add('Icons');
    return _RuntimeGlobalTypes(types, aliases, functions, exports);
  }
}
