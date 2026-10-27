import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'hot_patch_log.dart';

/// 网络补丁包加载结果。
///
/// [entryJsAsset]：[component] 所在的 `.js` 的相对路径（虚拟路径，
/// 与内置 asset 布局一致，如 `components/hello_component.js`），
/// 后续模块加载 / 相对 import 解析全部基于它，与 asset 场景完全一致。
/// [localRoot]：本包解压后的本地唯一根目录（`<document>/hot_patch/<urlHash>/`）。
/// 模块读取时用「localRoot + 虚拟路径」拼出本地文件路径，判断文件存在即读本地，
/// 不存在回退内置 asset——**不需要任何虚拟路径映射表**，文件系统即索引。
class RemoteAssetBundle {
  const RemoteAssetBundle(this.entryJsAsset, this.localRoot,
      {this.fresh = false, this.buildTime, this.protocol});

  final String entryJsAsset;
  final String localRoot;

  /// true = 本次是重新下载解压（zip 有更新）；false = 304 复用本地缓存。
  /// JsUiWidget 据此决定是否清除 JsRuntimeManager 的模块缓存。
  final bool fresh;

  /// 包根 `manifest.json` 里的 `buildTime`（补丁打包时间）；无清单时为 null。
  /// 仅供调试展示（JsUiWidget 的 `showBuildTime`），不影响加载。
  final String? buildTime;

  /// 包根 `manifest.json` 里的 `protocol`（该补丁包自身的产物协议版本，如
  /// `0.3.2`）；无清单 / 无该字段时为 null。
  ///
  /// **按包读取**而不是全局共用一个值：不同来源的补丁包（不同 zip、不同批次
  /// 打出）版本可以各不相同。
  final String? protocol;
}

/// 网络补丁包加载器：`http(s)://` 开头的 jsAsset → 下载 zip → 校验格式 →
/// 解压到 `<document>/hot_patch/<urlHash>/`（URL 哈希即本地唯一路径）。
///
/// 幂等：无进程内缓存——URL 哈希目录即持久缓存。load 时先判断本地
/// 是否已有解压产物：有则直接复用（离线可用，进程重启后依然有效），
/// 没有则下载解压后落盘再返回。
class RemoteAssetLoader {
  RemoteAssetLoader._();

  /// 网络超时（连接 / 响应头 / 响应体读取统一上限）：不设超时，网络
  /// 挂起会让启动永久卡在加载页。
  static const Duration _timeout = Duration(seconds: 15);

  /// 下载 zip 的**压缩体积**上限：超限直接拒绝并回退旧缓存，避免超大包
  /// 占满内存 / 磁盘。
  static const int _maxDownloadBytes = 50 * 1024 * 1024;

  /// 解压后的**总大小**上限：防 zip bomb（压缩比可任意大，只看下载体积不够）。
  static const int _maxUncompressedBytes = 100 * 1024 * 1024;

  /// zip 条目数量上限：防大量小文件拖垮解压与后续递归扫描。
  static const int _maxArchiveEntries = 10000;

  /// zip 条目名是否安全（防 zip-slip）。
  ///
  /// 只接受普通相对路径：拒绝绝对路径、盘符（`C:`）、反斜杠、空段与
  /// `.` / `..`。任何一条命中即整个包判为非法，回退旧缓存而不是部分解压。
  static bool _isSafeZipEntryName(String name) {
    if (name.isEmpty || name.startsWith('/') || name.contains('\\')) {
      return false;
    }
    // 盘符前缀（`C:` / `c:`）一律拒绝。
    final c0 = name.codeUnitAt(0);
    final isLetter = (c0 >= 0x41 && c0 <= 0x5A) || (c0 >= 0x61 && c0 <= 0x7A);
    if (name.length >= 2 && isLetter && name[1] == ':') return false;
    for (final seg in name.split('/')) {
      if (seg.isEmpty || seg == '.' || seg == '..') return false;
    }
    return true;
  }

  /// 宿主支持的 **patch 协议主版本**（对应生成器 `patchProtocolVersion` 的主版本）。
  ///
  /// `patchProtocolVersion` 直接取生成器包 `pubspec.yaml` 的 `version`，故本常量
  /// 取与之配套的 [hot_patch] 包版本主版本（当前 `0.3.x` → `0`）。产物 JS 与宿主
  /// Dart 之间的契约（`__h` / `element` / `__delegate` / `factory` / 句柄信封 /
  /// 颜色序列化）出现破坏性改动并升主版本时，本常量同步跟到新主版本；次版本 /
  /// 修订号只做加法，老 App 可继续消费未知字段。
  static const String _supportedProtocolMajor = '0';

  /// 组包并读取包根清单里的打包时间（`manifest.json` 由 build_runner 产出、
  /// 随 zip 分发；缺失/解析失败一律返回 null，不影响加载）。
  ///
  /// 同时校验 `protocol`：**主版本不一致就拒绝**（返回 null）。否则老 App 会
  /// 拿着不认识的新协议产物静默错乱，比直接失败更难排查。清单里没有该字段
  /// （历史产物）按兼容处理。
  static RemoteAssetBundle? _bundle(String entry, String root, {bool fresh = false}) {
    final protocol = _readProtocol(root);
    if (protocol != null && _majorOf(protocol) != _supportedProtocolMajor) {
      HotPatchLog.warn('patch protocol mismatch: bundle=$protocol, '
          'app=$_supportedProtocolMajor.x — refusing to mount');
      return null;
    }
    return RemoteAssetBundle(entry, root,
        fresh: fresh, buildTime: _readBuildTime(root), protocol: protocol);
  }

  /// 读包根 `manifest.json` 的 `protocol` 字段（如 `"0.3.2"`）；缺失 / 非法返回 null。
  ///
  /// 供调用方按包读取「当前资源对应的版本」：不同 zip / 不同批次打出的包各自
  /// 独立，版本可以不同。
  static String? readProtocol(String root) => _readProtocol(root);

  static String? _readProtocol(String root) {
    try {
      final file = File('$root/manifest.json');
      if (!file.existsSync()) return null;
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) return null;
      final protocol = decoded['protocol'];
      return protocol is String && protocol.isNotEmpty ? protocol : null;
    } catch (_) {
      return null;
    }
  }

  /// 版本号的主版本段：`"1.3"` → `"1"`，`"1"` → `"1"`。
  static String _majorOf(String version) => version.split('.').first.trim();

  /// 读包根 `manifest.json` 的 `buildTime` 字段；无清单 / 非 JSON / 字段缺失返回 null。
  static String? _readBuildTime(String root) {
    try {
      final file = File('$root/manifest.json');
      if (!file.existsSync()) return null;
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map) return null;
      final buildTime = decoded['buildTime'];
      return buildTime is String && buildTime.isNotEmpty ? buildTime : null;
    } catch (_) {
      return null;
    }
  }

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

  /// 清除本地**全部**补丁缓存：删除 `<document>/hot_patch/` 整棵目录
  /// （各 URL 的解压产物与协商缓存记录 `_last_modified.txt`）。
  ///
  /// 调试用：清掉后本地无缓存 → 下次加载不带 `If-Modified-Since` 直接重新
  /// 下载 zip（服务端 200 → fresh 更新），从而强制拉到最新产物。
  static Future<void> clearCache() async {
    final doc = await getApplicationDocumentsDirectory();
    final dir = Directory('${doc.path}/hot_patch');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }

  /// 加载网络补丁包。
  ///
  /// [entryPath]：zip 内入口 .js 的相对路径（如
  /// `components/hello_component.js`）。指定时直接用它，
  /// 不指定则按 [component] 反查声明它的 .js。
  /// 失败（非 200 / 非 zip / 解压异常 / 包内无该组件或路径）返回 null。
  ///
  /// 缓存策略（HTTP 标准协商缓存）：记录上次响应的 `Last-Modified`，
  /// 下次请求带 `If-Modified-Since`——服务端返回 304 则复用本地解压产物；
  /// 返回 200 则下载到同级临时目录，校验通过（zip 魔数 + 入口存在）后
  /// rename 原子替换旧目录——任何一步失败旧缓存完好，可降级回退。通用，
  /// 任意 zip 包都适用。
  static Future<RemoteAssetBundle?> load(String url,
      {String? component, String? entryPath}) async {
    try {
      final root = await localRootFor(url);
      final lmFile = File('$root/_last_modified.txt');
      final cachedLm = lmFile.existsSync() ? lmFile.readAsStringSync().trim() : null;

      // 本地已有解压产物（304 复用 / 各失败分支降级回退共用）。
      final existing = _resolveEntry(root, component, entryPath);
      final client = HttpClient();
      try {
        final uri = Uri.parse(url);
        final request = await client.getUrl(uri).timeout(_timeout);
        if (cachedLm != null && cachedLm.isNotEmpty) {
          request.headers.set(HttpHeaders.ifModifiedSinceHeader, cachedLm);
        }
        final response = await request.close().timeout(_timeout);

        // 2. 304 Not Modified：zip 未变，验证本地缓存完整性后复用。
        if (response.statusCode == HttpStatus.notModified && existing != null) {
          final cached = _cachedBundle(root, existing);
          if (cached != null) {
            HotPatchLog.log('remote bundle reused (304): $url -> $existing');
            return cached;
          }
          // 本地缓存损坏（文件丢失/空文件）→  fallthrough 到 200 重新下载。
          HotPatchLog.warn('remote bundle cache corrupted, re-downloading: $url');
        }
        if (response.statusCode != HttpStatus.ok) {
          HotPatchLog.error('remote asset HTTP ${response.statusCode}: $url');
          // 非 200 且本地有旧缓存 → 降级回退用旧缓存。
          return _fallback(root, url, existing, 'HTTP ${response.statusCode}');
        }

        // 3. 200：zip 有更新。先读完响应体并校验 zip 格式，解压到同级临时
        // 目录、验证入口存在，最后 rename 原子替换旧目录——任何一步失败，
        // 旧缓存完好无损，可直接回退。
        final declaredLength = response.contentLength;
        if (declaredLength > _maxDownloadBytes) {
          HotPatchLog.error(
              'remote asset too large ($declaredLength bytes): $url');
          return _fallback(root, url, existing, 'too large');
        }
        final builder = BytesBuilder(copy: false);
        var received = 0;
        await response.forEach((chunk) {
          received += chunk.length;
          if (received > _maxDownloadBytes) {
            throw StateError(
                'remote zip exceeds $_maxDownloadBytes bytes: $url');
          }
          builder.add(chunk);
        }).timeout(_timeout);
        final bytes = builder.takeBytes();
        // 格式校验：必须是 zip（PK 魔数 0x50 0x4B）
        if (bytes.length < 4 ||
            bytes[0] != 0x50 ||
            bytes[1] != 0x4B) {
          HotPatchLog.error('remote asset is not a zip: $url');
          return _fallback(root, url, existing, 'bad zip');
        }
        final archive = ZipDecoder().decodeBytes(bytes);

        // 临时目录与 root 同级（同文件系统），保证 rename 原子。
        final tmp = Directory('$root.new');
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
        tmp.createSync(recursive: true);
        try {
          var entryCount = 0;
          var uncompressedBytes = 0;
          for (final file in archive) {
            if (!file.isFile) continue;
            entryCount += 1;
            if (entryCount > _maxArchiveEntries) {
              throw StateError(
                  'remote zip has more than $_maxArchiveEntries entries: $url');
            }
            final rel = file.name;
            if (!_isSafeZipEntryName(rel)) {
              throw StateError('unsafe zip entry "$rel": $url');
            }
            uncompressedBytes += file.size;
            if (uncompressedBytes > _maxUncompressedBytes) {
              throw StateError(
                  'remote zip expands beyond $_maxUncompressedBytes bytes: $url');
            }
            final target = File('${tmp.path}/$rel');
            target.parent.createSync(recursive: true);
            target.writeAsBytesSync(file.content as Uint8List);
          }
          // 入口：entryPath 直达 / 按组件名反查（在临时目录上验证）。
          final entry = _resolveEntry(tmp.path, component, entryPath);
          if (entry == null) {
            HotPatchLog.error(
                'remote asset zip entry not found ($entryPath / $component): $url');
            tmp.deleteSync(recursive: true);
            return _fallback(root, url, existing, 'entry not found');
          }
          // 记录新的 Last-Modified（随临时目录一起原子替换过去），下次协商用。
          final lm = response.headers.value(HttpHeaders.lastModifiedHeader);
          if (lm != null && lm.isNotEmpty) {
            File('${tmp.path}/_last_modified.txt').writeAsStringSync(lm);
          }
          // 原子替换：root → root.old，tmp → root，再清理 root.old。
          final old = Directory('$root.old');
          if (old.existsSync()) old.deleteSync(recursive: true);
          final current = Directory(root);
          if (current.existsSync()) current.renameSync(old.path);
          tmp.renameSync(root);
          if (old.existsSync()) old.deleteSync(recursive: true);
          HotPatchLog.log('remote bundle loaded (fresh): $url -> $entry');
          return _bundle(entry, root, fresh: true);
        } catch (_) {
          if (tmp.existsSync()) tmp.deleteSync(recursive: true);
          rethrow;
        }
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      HotPatchLog.error('remote asset load failed: $url -> $e', error: e);
      // 网络异常（含超时 / 坏 zip / 解压失败）时回退本地旧缓存（有且完整才用）。
      try {
        final root = await localRootFor(url);
        final fallback = _fallback(
            root, url, _resolveEntry(root, component, entryPath), 'network error');
        if (fallback != null) return fallback;
      } catch (_) {
        // 回退也失败，忽略。
      }
      return null;
    }
  }

  /// 本地缓存中的入口文件完整（存在且非空）时返回其 bundle，否则 null。
  static RemoteAssetBundle? _cachedBundle(String root, String entry) {
    final entryFile = File('$root/$entry');
    if (entryFile.existsSync() && entryFile.lengthSync() > 0) {
      return _bundle(entry, root);
    }
    return null;
  }

  /// 失败降级：本地旧缓存完整则回退使用并留痕，否则 null。
  static RemoteAssetBundle? _fallback(
      String root, String url, String? entry, String reason) {
    if (entry == null) return null;
    final cached = _cachedBundle(root, entry);
    if (cached != null) {
      HotPatchLog.warn('remote asset fallback to cached ($reason): $url -> $entry');
    }
    return cached;
  }

  /// 解析入口：指定 [entryPath] 直接用（文件存在才返回）；否则按
  /// [component] 反查声明它的 .js。返回 zip 内相对路径。
  static String? _resolveEntry(String root, String? component, String? entryPath) {
    if (entryPath != null && entryPath.isNotEmpty) {
      return File('$root/$entryPath').existsSync() ? entryPath : null;
    }
    if (component == null || component.isEmpty) return null;
    return _findComponentFile(root, component);
  }

  /// 扫描本地根目录下的 .js，找声明了 [component] 类的那个
  /// （生成器产物类名 = @PatchEntry 注解 name，匹配 `class <name>`）。
  /// 返回 zip 内相对路径；未找到返回 null。
  static String? _findComponentFile(String root, String component) {
    final dir = Directory(root);
    if (!dir.existsSync()) return null;
    for (final e in dir.listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.js')) continue;
      final rel = e.path.substring(root.length + 1);
      if (File(e.path).readAsStringSync().contains('class $component')) {
        return rel;
      }
    }
    return null;
  }

}
