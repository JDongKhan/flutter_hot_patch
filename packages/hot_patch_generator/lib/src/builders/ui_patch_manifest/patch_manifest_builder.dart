/// patch 清单 builder：每次 build 在 `patch/manifest.json` 产出一份清单，
/// 记录基本信息、打包时间与各 JS 资源的内容 hash。
///
/// # 为什么能读到前面的产物
///
/// build_runner 里一个 builder 读不到**同一阶段**其他 builder 的产物，但能读
/// **更早阶段**的产物（见 build_runner：`isReadable(knowledge) == 更早阶段`）。
/// 本 builder 通过 `required_inputs: [".js"]` 声明「依赖所有产出 .js 的 builder」
/// （`patch_entry` / `ui_widget`），从而被排到它们**之后**的阶段；再用
/// `findAssets(Glob('patch/**.js'))` 列出全部已生成 JS（glob 只匹配更早阶段
/// 的产物）逐个读取、计算 hash。因此无需关心具体有哪些产物文件，新增产物
/// 会自动进清单。
library;

import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

import '../shared/artifact_protocol.dart';

/// patch 协议版本：**产物 JS 与宿主 Dart 之间的契约版本**（`__h` / 元素
/// `element: true` / `__delegate` / `factory` / `itemBuilder` / 句柄信封
/// `{ch,data}` / 颜色 `#AARRGGBB`）。
///
/// 取值见 [patchProtocolVersion]（= 生成器包版本），只写进清单的 `protocol`
/// 字段（一个补丁包一份），**不写进 JS 产物**——JS 带版本号会让翻译器升级时
/// 无改动文件的 hash 也跟着变，破坏增量更新与缓存。
///
/// 规则：
///   - **主版本**变化 = 破坏性改动（改字段语义 / 删字段），老 App 不能加载新
///     产物，新 App 也不保证能加载老产物；
///   - **次版本 / 修订号**只做加法（新增可选字段），老 App 应能忽略未知字段
///     继续工作。
///
/// 运行时（`RemoteAssetLoader`）加载远程包时校验清单里的主版本，不匹配就拒绝
/// 挂载并在日志里出声，避免「产物协议变了但 App 还是老代码」导致的静默错乱。

/// patch 清单 builder。
///
/// 产物固定在 [outputPath]，挂在包根伪资产 `$package$` 下（与 `ui_host_register`
/// 同款：输入是整包、产物路径静态），因此每个包至多一份清单。
///
/// 基本信息可由使用方 `build.yaml` 覆盖（均为可选项）：
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       hot_patch_generator:ui_patch_manifest:
///         options:
///           name: my_app
///           version: 1.2.3
/// ```
///
/// 未配置时 `name` 取当前包名、`version` 省略。
class PatchManifestBuilder implements Builder {
  const PatchManifestBuilder({this.name, this.version});

  /// 清单里的应用名（基本信息）。为空时取 `buildStep.inputId.package`。
  final String? name;

  /// 清单里的版本号（基本信息）。为空时清单里省略该字段。
  final String? version;

  /// 清单产物路径（相对包根）：与其它产物同落在 `patch/` 下便于随包分发。
  static const String outputPath = 'patch/manifest.json';

  /// patch/ 根目录下的全部 JS 资源（package 模块 + 组件/模型产物）。
  /// `**` 跨目录，`patch/flutter.js` 与 `patch/app/pages/home_page.js` 都能命中。
  static final Glob _jsResources = Glob('patch/**.js');

  /// 资源路径前缀（清单里以 `patch/` 为根，键去掉该前缀，如 `app/pages/home_page.js`）。
  static const String _patchPrefix = 'patch/';

  @override
  Map<String, List<String>> get buildExtensions => const {
        // `$package$`：整包伪资产，输入一个包、产出一份清单（无种子文件）。
        r'$package$': [outputPath],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    // findAssets 只返回「更早阶段且真正产出成功」的产物；逐个读取得内容 hash。
    // readAsString 同时登记为输入依赖：任一 JS 内容变化都会让本步骤重跑。
    final resources = <String, String>{};
    await for (final id in buildStep.findAssets(_jsResources)) {
      final content = await buildStep.readAsString(id);
      final rel = id.path.substring(_patchPrefix.length);
      resources[rel] = sha256.convert(utf8.encode(content)).toString();
    }

    final manifest = <String, Object?>{
      'name': name ?? buildStep.inputId.package,
      if (version != null && version!.isNotEmpty) 'version': version,
      // 产物协议版本：运行时据此判断老 App 能否消费这份产物（主版本必须一致）。
      'protocol': patchProtocolVersion,
      'buildTime': DateTime.now().toIso8601String(),
      'resources': resources,
    };

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, outputPath),
      const JsonEncoder.withIndent('  ').convert(manifest),
    );
  }
}
