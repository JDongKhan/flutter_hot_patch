import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// assets 覆盖 demo：
///
/// - 图片走 `Image.asset`（宿主统一经 `HotPatchAssets.bundle` 解析）；
/// - JSON 走 `rootBundle.loadString`（JS 侧同名顶层对象 → 宿主 `assetLoadString`）。
///
/// 补丁包（`patch.zip`）根下放同路径文件即可覆盖：
/// `assets/images/<同名>.jpg`、`assets/data/asset_override_demo.json`。
@PatchEntry('AssetOverrideDetail')
class AssetOverrideDetail extends StatefulWidget {
  const AssetOverrideDetail({super.key});

  @override
  State<AssetOverrideDetail> createState() => _AssetOverrideDetailState();
}

class _AssetOverrideDetailState extends State<AssetOverrideDetail> {
  static const String _imageAsset =
      'assets/images/photo-1519681393784-d120267933ba.jpg';
  static const String _jsonAsset = 'assets/data/asset_override_demo.json';

  String _jsonText = '加载中…';

  @override
  void initState() {
    super.initState();
    _loadJson();
  }

  Future<void> _loadJson() async {
    try {
      final text = await rootBundle.loadString(_jsonAsset);
      if (!mounted) return;
      setState(() => _jsonText = text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _jsonText = '读取失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'assets 图片 · 补丁包同名优先',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(_imageAsset, height: 160, fit: BoxFit.cover),
        ),
        const SizedBox(height: 8),
        Text(
          _imageAsset,
          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 16),
        const Text(
          'assets JSON · 补丁包同名优先',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _jsonText,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _jsonAsset,
          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
        ),
      ],
    );
  }
}
