/// 核心 JS builder：把 JS 运行时（mini-react / 句柄表 / 各能力片段）写成
/// **一个** `patch/runtime.js`。
///
/// 本目录（`builders/core_js_builder/`）承载**全部核心 JS 源码**，与具体
/// 产物形态无关，按目标产物分目录：
///   - `js/runtime/`：拼进 `patch/runtime.js` 的框架代码（本 builder 产出）；
///   - `js/flutter/`：拼进 `patch/flutter.js` 的 Flutter SDK 面（值类 /
///     Controller / 导航 / 弹层等，由 `ui_widget` builder 产出）。
/// 未来出现新的核心 JS 产物，只需在同一目录下新增子目录，不另起 builder 命名。
///
/// 产物是构建期生成的普通 JS 文件，随补丁包发布；运行时包（dynamic_flutter）只负责
/// 读取并求值。因此 JS 侧的修复/优化**只需要重出产物**，不用发版 App。
library;

import 'package:build/build.dart';

import 'js/runtime/runtime_js.dart';

/// 运行时产物路径（补丁根目录，与 `patch/<package>.js` 同级）。
const String runtimeJsPath = 'patch/runtime.js';

/// 核心 JS builder：输入为包根伪资产 `$package$`（整包一个输入，输出路径静态，
/// 无需任何种子文件），输出固定为 [runtimeJsPath]。
class CoreJsBuilder implements Builder {
  const CoreJsBuilder();

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
