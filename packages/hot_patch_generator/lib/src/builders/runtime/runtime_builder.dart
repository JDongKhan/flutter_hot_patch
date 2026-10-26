/// 运行时 builder：把 JS 运行时（mini-react / 句柄表 / 各能力片段）写成
/// **一个** `patch/runtime.js`。
///
/// 产物是构建期生成的普通 JS 文件，随补丁包发布；运行时包（hot_patch）只负责
/// 读取并求值。因此 JS 侧的修复/优化**只需要重出产物**，不用发版 App。
library;

import 'package:build/build.dart';

import 'js/runtime_js.dart';

/// 运行时产物路径（补丁根目录，与 `patch/<package>.js` 同级）。
const String runtimeJsPath = 'patch/runtime.js';

/// 运行时 builder：输入为包根伪资产 `$package$`（整包一个输入，输出路径静态，
/// 无需任何种子文件），输出固定为 [runtimeJsPath]。
class RuntimeJsBuilder implements Builder {
  const RuntimeJsBuilder();

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$package$': [runtimeJsPath],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, runtimeJsPath),
      runtimeJsSource(),
    );
  }
}
