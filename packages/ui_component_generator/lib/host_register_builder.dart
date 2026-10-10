import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'host_method_scan.dart';

/// 注册目标的默认值：本生成器配套的运行时（hot_patch）自带的注册 API。
/// 使用方**无需任何配置**即可零配置工作。
const String _defaultRegisterImport = 'package:hot_patch/hot_patch.dart';
const String _defaultRegisterCall = 'JsRuntimeManager.registerHostMethod';

/// build_runner 工厂入口（build.yaml 的 builder_factories 指向这里）。
///
/// 注册目标默认指向配套运行时（见 [_defaultRegisterImport] / [_defaultRegisterCall]），
/// 使用方**开箱即用、不必写任何 build.yaml**。换用别的运行时实现时，才需要
/// 在自己的 build.yaml 里覆盖这两项（属于少数派场景，故不作强制）：
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       ui_component_generator:ui_host_register:
///         options:
///           register_import: "package:<runtime>/<runtime>.dart"
///           register_call: "<Runtime>.registerHostMethod"
/// ```
Builder hostRegisterBuilder(BuilderOptions options) {
  final import = options.config['register_import'];
  final call = options.config['register_call'];
  return HostRegisterBuilder(
    registerImport:
        import is String && import.isNotEmpty ? import : _defaultRegisterImport,
    registerCall:
        call is String && call.isNotEmpty ? call : _defaultRegisterCall,
  );
}

/// 宿主注入注册 builder：扫描全包的 `@HostInjected` static 方法，把它们对应的
/// 注册调用集中生成到**一个 Dart 文件**里，业务方在 `main()` 里调用一次即可：
///
/// ```dart
/// registerHostMethods();
/// ```
///
/// # 与另外两个 builder 的区别
///
/// 另外两个 builder（`ui_component` / `ui_widget`）的产物是 **assets/ 下的 JS**
/// （运行期被 JS 引擎加载），本 builder 的产物是**参与编译的 Dart 源码**，
/// 因此单独成一个 builder：输入是包根伪资产（无种子文件）、产物落在 lib/ 下。
///
/// # 输出稳定性
///
/// 产物路径固定（不随发现的注解动态变化），build_extensions 里静态声明即可；
/// 即使一个注解都没有也照常产出（空方法体）——它被 `main()` import，缺文件会
/// 直接断编译，与可跳过的 JS 资产不同。
class HostRegisterBuilder implements Builder {
  const HostRegisterBuilder({
    required this.registerImport,
    required this.registerCall,
  });

  /// 运行时包入口（如 `package:hot_patch/hot_patch.dart`）：产物会 import 它。
  final String registerImport;

  /// 运行时注册函数表达式（如 `JsRuntimeManager.registerHostMethod`）：
  /// 产物按 `调用(通道名, impl)` 逐个调用。
  final String registerCall;

  /// 产物路径（相对包根）：被 main() import 的 Dart 源码。
  static const String outputPath = 'lib/generated/host_methods.dart';

  /// 扫描范围：包内全部 Dart 源码。
  static final Glob _dartSources = Glob('lib/**.dart');

  @override
  Map<String, List<String>> get buildExtensions => const {
        // `$package$`：build_runner 的包根伪资产输入键，用于「输入是整包」的
        // builder——无需为每个包准备种子文件。
        r'$package$': [outputPath],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final entries = <_HostEntry>[];
    await for (final id in buildStep.findAssets(_dartSources)) {
      // 跳过自己的产物：它没有注解，读了还会给本步骤凭空添一条自依赖。
      if (id.path == outputPath) continue;
      // readAsString 同时登记依赖：该文件改动会触发本步骤重跑。
      final content = await buildStep.readAsString(id);
      scanHostMethods(
        parseString(
          content: content,
          throwIfDiagnostics: false,
          path: id.path,
        ).unit,
        (h) {
          if (!h.usable) {
            // 与翻译口径一致（都不支持），但不能静默：让使用方看到原因。
            log.warning('[ui_component_generator] 跳过 @HostInjected '
                '${h.targetExpr}（${id.path}）：'
                '${h.isPrivate ? '私有声明跨库不可见' : '实例方法无法定位宿主实例'}——'
                '宿主注入只支持 static 方法 / 顶层函数');
            return;
          }
          entries.add(_HostEntry(
            targetExpr: h.targetExpr,
            channel: h.channel,
            sourcePath: id.path,
          ));
        },
      );
    }

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, outputPath),
      _render(entries),
    );
  }

  /// 装配产物：import 运行时库 + 各声明文件，再逐个注册。
  String _render(List<_HostEntry> entries) {
    final sorted = [...entries]..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    final deduped = <String, _HostEntry>{
      for (final e in sorted) '${e.sourcePath}|${e.targetExpr}': e,
    }.values.toList();

    final imports = <String>{
      for (final e in deduped) _relativeImport(e.sourcePath),
    }.toList()
      ..sort();

    final b = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('//')
      ..writeln('// 由 ui_component_generator 的 hostRegisterBuilder 扫描全包')
      ..writeln('// `@HostInjected` 方法生成。用法（main() 里调用一次）：')
      ..writeln('//')
      ..writeln('//   registerHostMethods();')
      ..writeln('//')
      ..writeln('// 注册目标默认指向配套运行时（$registerImport），')
      ..writeln('// 需要换运行时实现时用 build.yaml 的 register_import / register_call 覆盖。')
      ..writeln()
      ..writeln("import '$registerImport';");
    if (imports.isNotEmpty) {
      b.writeln();
      for (final i in imports) {
        b.writeln("import '$i';");
      }
    }
    b
      ..writeln()
      ..writeln('/// 注册本包全部 `@HostInjected` 宿主方法（无注解时为空实现）。')
      ..writeln('void registerHostMethods() {');
    if (deduped.isEmpty) {
      b.writeln('  // 本包没有 @HostInjected 方法。');
    }
    for (final e in deduped) {
      // Function.apply 免去参数个数/类型推断（JS 侧透传的参数个数是运行期才知道的），
      // 故 static 方法 / 顶层函数、任意形参与返回类型都同一套注册。
      b.writeln(
        "  $registerCall('${e.channel}', "
        '(args) => Function.apply(${e.targetExpr}, args));',
      );
    }
    b.writeln('}');
    return b.toString();
  }
}

/// 一条宿主注入注册：宿主侧目标表达式（`Class.method` / `顶层函数名`）
/// + 通道名 + 声明它的源文件。
class _HostEntry {
  final String targetExpr;
  final String channel;
  final String sourcePath;
  const _HostEntry({
    required this.targetExpr,
    required this.channel,
    required this.sourcePath,
  });

  /// 稳定排序键（产物内容与扫描顺序无关）。
  String get sortKey => '$sourcePath|$targetExpr';
}

/// 从产物所在目录（`lib/generated/`）指向 [sourcePath] 的相对 import 路径。
String _relativeImport(String sourcePath) {
  final from = HostRegisterBuilder.outputPath.split('/')..removeLast();
  final to = sourcePath.split('/');
  var common = 0;
  while (common < from.length &&
      common < to.length - 1 &&
      from[common] == to[common]) {
    common++;
  }
  final up = List.filled(from.length - common, '..');
  return [...up, ...to.sublist(common)].join('/');
}

