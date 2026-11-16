import 'package:flutter/foundation.dart';

/// 补丁包地址的唯一来源（demo 里所有 JsUiWidget 都从这里取）。
///
/// - debug：本地 patch 服务（`bash start_patch_server.sh` 启动的 127.0.0.1:8765）；
/// - release：GitHub Pages 上的静态包（由 start_patch_server.sh 同步到
///   `docs/blog/patch.zip`，随仓库发布到
///   https://jdongkhan.github.io/flutter_hot_patch/blog/ ）——别人装包后不需要
///   自己起本地服务。
/// - 需要指向别处（自己的 CDN / 灰度环境）时用编译期参数覆盖：
///   `fvm flutter build apk --dart-define=PATCH_ZIP=https://example.com/patch.zip`
const String _patchZipOverride = String.fromEnvironment('PATCH_ZIP');

const String _patchZipLocal = 'http://127.0.0.1:8765/patch/patch.zip';

const String _patchZipPublished =
    'https://jdongkhan.github.io/flutter_hot_patch/blog/patch.zip';

/// 当前生效的补丁 zip 地址。
String get patchZipUrl {
  if (_patchZipOverride.isNotEmpty) return _patchZipOverride;
  return kReleaseMode ? _patchZipPublished : _patchZipLocal;
}

/// 拼接单个组件的补丁 URL：组件名与入口路径都走 query 参数。
///   `<zip>?component=HelloCard&entry=components/hello_component.js`
String patchUrl(String component, [String? entry]) {
  final q = StringBuffer('component=$component');
  if (entry != null) q.write('&entry=${Uri.encodeComponent(entry)}');
  return '$patchZipUrl?$q';
}
