/// 宿主三方 JS builder：把宿主工程 `js/**.js` 原样拷贝到
/// `patch/packages/**.js`。
///
/// 三方库的 JS **不在生成器 / 运行时包内维护**：宿主在项目根建 `js/` 目录，
/// 文件名即对应的 Dart 包名（`js/provider.js` ↔ `package:provider`）。构建时
/// 原样拷贝到补丁包的 `packages/` 下，业务产物按相对路径
/// `import { X } from '../packages/provider.js'` 消费——与本地依赖包产物
/// （`patch/packages/<package>/<rel>.js`）共用同一个 `packages/` 前缀。
///
/// 输入用包根伪资产 `$package$`、输出清单由文件系统扫描静态推导（与
/// `ui_project_module` 同款）：不要求宿主动 `build.yaml` 的 `sources`，
/// 放文件即生效。扫描不到任何 JS 时零产物。
library;

import 'dart:io';

import 'package:build/build.dart';

import '../shared/package_sources.dart';
import '../shared/source_index.dart';

/// 输入整包、输出宿主 `js/` 下每个文件的同名拷贝。
class ThirdPartyJsBuilder implements Builder {
  const ThirdPartyJsBuilder();

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$package$': [
          for (final rel in thirdPartyJsFiles) '$thirdPartyJsProductsRoot/$rel',
        ],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final root = PackageSources.instance?.projectRoot;
    if (root == null) {
      log.warning('[hot_patch_generator] 无法定位宿主工程根，三方 JS 未拷贝');
      return;
    }
    const prefix = '$thirdPartyJsProductsRoot/';
    for (final out in buildStep.allowedOutputs) {
      if (!out.path.startsWith(prefix)) continue;
      final rel = out.path.substring(prefix.length);
      final source =
          File('$root${Platform.pathSeparator}$thirdPartyJsRoot'
              '${Platform.pathSeparator}$rel');
      if (!source.existsSync()) {
        // 输出清单来自构建期扫描，正常不会缺；文件在构建中被删就出声，不静默产空模块。
        log.warning('[hot_patch_generator] 三方 JS 源文件不存在，已跳过：'
            '${source.path}');
        continue;
      }
      await buildStep.writeAsString(out, source.readAsStringSync());
    }
  }
}
