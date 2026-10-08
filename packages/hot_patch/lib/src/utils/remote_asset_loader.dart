import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'hot_patch_log.dart';

/// 网络补丁包加载结果。
///
/// [entryJsAsset]：[component] 所在的 `.component.js` 的相对路径（虚拟路径，
/// 与内置 asset 布局一致，如 `components/components/hello_component.component.js`），
/// 后续模块加载 / 相对 import 解析全部基于它，与 asset 场景完全一致。
/// [localRoot]：本包解压后的本地唯一根目录（`<document>/hot_patch/<urlHash>/`）。
/// 模块读取时用「localRoot + 虚拟路径」拼出本地文件路径，判断文件存在即读本地，
/// 不存在回退内置 asset——**不需要任何虚拟路径映射表**，文件系统即索引。
class RemoteAssetBundle {
  const RemoteAssetBundle(this.entryJsAsset, this.localRoot);

  final String entryJsAsset;
  final String localRoot;
}

/// 网络补丁包加载器：`http(s)://` 开头的 jsAsset → 下载 zip → 校验格式 →
/// 解压到 `<document>/hot_patch/<urlHash>/`（URL 哈希即本地唯一路径）。
///
/// 幂等：无进程内缓存——URL 哈希目录即持久缓存。load 时先判断本地
/// 是否已有解压产物：有则直接复用（离线可用，进程重启后依然有效），
/// 没有则下载解压后落盘再返回。
class RemoteAssetLoader {
  RemoteAssetLoader._();

  /// 判断 [jsAsset] 是否为网络补丁包地址（http:// 或 https:// 开头）。
  static bool isRemote(String jsAsset) =>
      jsAsset.startsWith('http://') || jsAsset.startsWith('https://');

  /// URL 的本地唯一根目录：`<document>/hot_patch/<urlHash>/`。
  /// 同一 URL 永远映射到同一路径——「URL → 本地路径」是纯函数，
  /// 内容是否已存在直接用文件系统判断，无需维护映射表。
  static Future<String> localRootFor(String url) async {
    final doc = await getApplicationDocumentsDirectory();
    // sha256(url)：不同 URL 一定得到不同目录（base64 截断会碰撞）。
    final hash = sha256.convert(utf8.encode(url)).toString().substring(0, 24);
    return '${doc.path}/hot_patch/$hash';
  }

  /// 加载网络补丁包。
  ///
  /// [entryPath]：zip 内入口 .component.js 的相对路径（如
  /// `components/components/hello_component.component.js`）。指定时直接用它，
  /// 不指定则按 [component] 反查声明它的 .component.js。
  /// 失败（非 200 / 非 zip / 解压异常 / 包内无该组件或路径）返回 null。
  static Future<RemoteAssetBundle?> load(String url,
      {String? component, String? entryPath}) async {
    try {
      final root = await localRootFor(url);
      // 1. 本地已存在（此前下载解压过，URL 哈希目录即持久缓存）→ 直接
      //    复用，不联网（离线可用；进程重启后依然有效）。指定 entryPath
      //    直接用（先确认文件存在）；否则按组件名反查所在文件。
      final existing = _resolveEntry(root, component, entryPath);
      if (existing != null) {
        HotPatchLog.log('remote bundle reused: $url -> $existing');
        return RemoteAssetBundle(existing, root);
      }
      // 2. 下载（dart:io HttpClient，不引入额外 http 依赖）
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode != 200) {
          HotPatchLog.log('remote asset HTTP ${response.statusCode}: $url');
          return null;
        }
        final builder = BytesBuilder(copy: false);
        await response.forEach((chunk) => builder.add(chunk));
        final bytes = builder.takeBytes();
        // 3. 格式校验：必须是 zip（PK 魔数 0x50 0x4B）
        if (bytes.length < 4 ||
            bytes[0] != 0x50 ||
            bytes[1] != 0x4B) {
          HotPatchLog.log('remote asset is not a zip: $url');
          return null;
        }
        // 4. 解压到本地唯一根目录（zip 内相对路径原样落盘）
        final dir = Directory(root);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final file in archive) {
          if (!file.isFile) continue;
          final rel = file.name;
          final target = File('$root/$rel');
          if (!target.existsSync()) {
            target.parent.createSync(recursive: true);
            target.writeAsBytesSync(file.content as Uint8List);
          }
        }
        // 5. 入口：entryPath 直达 / 按组件名反查（zip 可能含多个组件产物）
        final entry = _resolveEntry(root, component, entryPath);
        if (entry == null) {
          HotPatchLog.log(
              'remote asset zip entry not found ($entryPath / $component): $url');
          return null;
        }
        HotPatchLog.log('remote bundle loaded: $url -> $entry');
        return RemoteAssetBundle(entry, root);
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      HotPatchLog.log('remote asset load failed: $url -> $e');
      return null;
    }
  }

  /// 解析入口：指定 [entryPath] 直接用（文件存在才返回）；否则按
  /// [component] 反查声明它的 .component.js。返回 zip 内相对路径。
  static String? _resolveEntry(String root, String? component, String? entryPath) {
    if (entryPath != null && entryPath.isNotEmpty) {
      return File('$root/$entryPath').existsSync() ? entryPath : null;
    }
    if (component == null || component.isEmpty) return null;
    return _findComponentFile(root, component);
  }

  /// 扫描本地根目录下的 .component.js，找声明了 [component] 类的那个
  /// （生成器产物类名 = @UIComponent 注解 name，匹配 `class <name>`）。
  /// 返回 zip 内相对路径；未找到返回 null。
  static String? _findComponentFile(String root, String component) {
    final dir = Directory(root);
    if (!dir.existsSync()) return null;
    for (final e in dir.listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.component.js')) continue;
      final rel = e.path.substring(root.length + 1);
      if (File(e.path).readAsStringSync().contains('class $component')) {
        return rel;
      }
    }
    return null;
  }

}
