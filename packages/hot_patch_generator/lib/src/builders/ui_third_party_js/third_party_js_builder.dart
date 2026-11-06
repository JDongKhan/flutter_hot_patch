/// 宿主三方 JS builder：把宿主工程 `js/**.js` 原样拷贝到
/// `patch/packages/**.js`。
///
/// 三方库的 JS **不在生成器 / 运行时包内维护**：宿主在项目根建 `js/` 目录，
/// 文件名即对应的 Dart 包名（`js/provider.js` ↔ `package:provider`）。构建时
/// 原样拷贝到补丁包的 `packages/` 下，业务产物按相对路径
/// `import { X } from '../packages/provider.js'` 消费——与本地依赖包产物
/// （`patch/packages/<package>/<rel>.js`）共用同一个 `packages/` 前缀，
/// 但互不覆盖（前者是 `<package>.js` 单文件，后者在 `<package>/` 目录下）。
library;

import 'package:build/build.dart';

/// 输入 `js/{{}}.js` → 输出 `patch/packages/{{}}.js`（原样拷贝，不做任何改写）。
class ThirdPartyJsBuilder implements Builder {
  const ThirdPartyJsBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const {
        '^js/{{}}.js': ['patch/packages/{{}}.js'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final content = await buildStep.readAsString(buildStep.inputId);
    await buildStep.writeAsString(buildStep.allowedOutputs.single, content);
  }
}
