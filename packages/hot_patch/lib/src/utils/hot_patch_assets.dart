import 'dart:io';

import 'package:flutter/services.dart';

import 'hot_patch_log.dart';

/// 当前活跃补丁包的 assets 解析入口。
///
/// 资源 key 与 Flutter assets 完全同名（如 `assets/images/a.jpg`），补丁包根下
/// 保留同名路径：`<localRoot>/assets/images/a.jpg`。命中则读补丁包文件，缺失或
/// 读取失败回退 `rootBundle`——与 JS 模块加载「文件存在读本地、否则回退
/// Flutter assets」同一口径。
class HotPatchAssets {
  HotPatchAssets._();

  static HotPatchAssetBundle _bundle = HotPatchAssetBundle(null);

  /// 当前补丁包对应的 bundle；无远程补丁包时全部回退 Flutter assets。
  static AssetBundle get bundle => _bundle;

  /// 切换到 [localRoot] 对应的补丁包；同一根复用实例（保持图片缓存 key 稳定）。
  static void activate(String? localRoot) {
    if (localRoot == null || localRoot == _bundle.localRoot) return;
    _bundle = HotPatchAssetBundle(localRoot);
  }

  /// 回到纯 Flutter assets（运行时切换为无包版本时）。
  static void reset() {
    if (_bundle.localRoot != null) _bundle = HotPatchAssetBundle(null);
  }
}

/// 补丁包优先的 [AssetBundle]：同名文件存在则读本地，否则委托 [rootBundle]。
///
/// 实例身份即当前补丁包身份：切换补丁包时创建新实例，`AssetImage` 的缓存 key
/// 随之变化，避免旧包图片被复用。
class HotPatchAssetBundle extends CachingAssetBundle {
  HotPatchAssetBundle(this.localRoot);

  /// 补丁包解压根（绝对路径）；null = 只用 Flutter assets。
  final String? localRoot;

  @override
  Future<ByteData> load(String key) async {
    final root = localRoot;
    if (root != null) {
      final file = _patchFile(root, key);
      if (file != null) {
        try {
          return ByteData.sublistView(await file.readAsBytes());
        } catch (e, s) {
          HotPatchLog.warn(
            '补丁资源读取失败，回退 Flutter assets：$key（$e）',
            error: e,
            stackTrace: s,
          );
        }
      }
    }
    return rootBundle.load(key);
  }

  /// 补丁包内与 [key] 同路径的文件；不存在或路径非法时返回 null。
  File? _patchFile(String root, String key) {
    if (key.isEmpty) return null;
    final normalized = key.replaceAll('\\', '/');
    if (normalized.startsWith('/') || normalized.split('/').contains('..')) {
      HotPatchLog.warn('补丁资源路径非法，已忽略：$key');
      return null;
    }
    final file = File('$root/$normalized');
    return file.existsSync() ? file : null;
  }
}
