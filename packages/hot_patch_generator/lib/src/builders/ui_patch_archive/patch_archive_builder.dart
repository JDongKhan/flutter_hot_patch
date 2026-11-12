/// patch 归档 builder：每次 build 把 `patch/` 下的全部文件打成 `patch/patch.zip`。
///
/// # 内容来源
///
/// 归档必须包含两类文件：
///   - **构建图资产**：各 builder 生成的 JS 与 `patch/manifest.json`。它们在本阶段
///     尚未落盘，只能经 [BuildStep] 读（`findAssets(Glob('patch/**'))`），读取同时
///     登记输入依赖——任一产物变化都会让归档重跑；
///   - **静态资源**：手工放在 `patch/` 下的文件（如 `patch/assets/...`）。它们不是
///     构建图资产（build_runner 默认 sources 不含 `patch/`），`findAssets` 列不到，
///     因此直接按包根读磁盘。
///
/// # 为什么排在最后
///
/// 同一阶段读不到彼此的产物、更早阶段可以，因此 `required_inputs` 声明 `".json"`
/// 让本 builder 位于 `ui_patch_manifest` **之后**，zip 里带的是最新清单。
library;

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

import '../shared/package_sources.dart';

/// patch 归档 builder。
///
/// 产物固定在 [outputPath]，挂在包根伪资产 `$package$` 下（与
/// `ui_host_register` / `ui_patch_manifest` 同款：输入是整包、产物路径静态）。
class PatchArchiveBuilder implements Builder {
  const PatchArchiveBuilder();

  /// 归档产物路径（相对包根）：与其余产物同在 `patch/` 下，静态服务直接可取。
  static const String outputPath = 'patch/patch.zip';

  /// patch/ 根目录下的构建图资产（生成的产物）。
  static final Glob _patchAssets = Glob('patch/**');

  /// 资源路径前缀（zip 内条目以 `patch/` 为根，去掉该前缀）。
  static const String _patchPrefix = 'patch/';

  /// 产物目录（相对包根）。
  static const String _patchDir = 'patch';

  /// 不进归档的文件名：zip 自身（避免自我包含），以及 macOS 目录元数据。
  static const String _archiveName = 'patch.zip';
  static const String _dsStore = '.DS_Store';

  @override
  Map<String, List<String>> get buildExtensions => const {
        r'$package$': [outputPath],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final entries = <String, List<int>>{};
    // 1) 构建图资产：生成的产物以构建图内容为准（磁盘上可能还是上一次的）。
    await for (final id in buildStep.findAssets(_patchAssets)) {
      final rel = id.path.substring(_patchPrefix.length);
      if (_isExcluded(rel)) continue;
      entries[rel] = await buildStep.readAsBytes(id);
    }
    // 2) 静态资源：不在构建图里，按包根读磁盘补齐（已收录的产物不重复读，避免
    //    拿到上一次的旧内容）。
    final root = PackageSources.instance?.projectRoot;
    if (root == null) {
      log.warning('$outputPath: 定位不到构建目标包根，$_patchDir 下的静态资源未进归档');
    } else {
      final dir = Directory('$root/$_patchDir');
      if (dir.existsSync()) {
        for (final file in dir.listSync(recursive: true)) {
          if (file is! File) continue;
          final rel = file.path.substring(dir.path.length + 1);
          if (_isExcluded(rel) || entries.containsKey(rel)) continue;
          entries[rel] = file.readAsBytesSync();
        }
      }
    }
    if (entries.isEmpty) {
      throw StateError('$outputPath: $_patchPrefix 下没有任何产物，归档失败');
    }

    // 条目顺序固定（按路径排序），同一批产物打出字节一致的 zip。
    final paths = entries.keys.toList()..sort();
    final archive = Archive();
    for (final rel in paths) {
      final bytes = entries[rel]!;
      archive.addFile(ArchiveFile(rel, bytes.length, bytes));
    }
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('$outputPath: zip 编码失败');
    }
    await buildStep.writeAsBytes(
      AssetId(buildStep.inputId.package, outputPath),
      encoded,
    );
  }

  /// zip 自身与 macOS 目录元数据不进包。
  bool _isExcluded(String rel) => rel == _archiveName || rel.endsWith(_dsStore);
}
