import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// PreferredSize 演示：把任意子树声明成 `PreferredSizeWidget`。
///
/// `Scaffold.appBar` / `bottomNavigationBar` 只接受 `PreferredSizeWidget`，而
/// 它们只用 `preferredSize.height` 决定占位高度——把普通 Container 套一层
/// `PreferredSize(preferredSize: Size.fromHeight(h))` 就能当自定义顶栏用。
///
/// 一比一翻译说明：
///   - `preferredSize` 是值对象 `Size`，产物下发 `{width, height}`（
///     `Size.fromHeight` 的 width 是 +∞，跨 JSON 时折叠为 null，宿主按 ∞ 还原）；
///   - 拖滑块改 `_height` → 顶栏高度随之变化（宿主按新 preferredSize 重新布局）。
@PatchEntry('PreferredSizeDetail')
class PreferredSizeDetail extends StatefulWidget {
  const PreferredSizeDetail({super.key});

  @override
  State<PreferredSizeDetail> createState() => _PreferredSizeDetailState();
}

class _PreferredSizeDetailState extends State<PreferredSizeDetail> {
  double _height = 64;

  @override
  Widget build(BuildContext context) {
    final label = _height.toStringAsFixed(0);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_height),
        child: Container(
          color: Colors.deepPurple,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SafeArea(
            child: Text(
              '自定义顶栏 · 高度 $label',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('PreferredSize', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Scaffold.appBar 只接受 PreferredSizeWidget；套一层 PreferredSize 就能让任意子树占用指定高度。拖下面的滑块，顶栏高度随之变化。',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Text(
            'preferredSize: Size(∞, $label)',
            style: const TextStyle(fontSize: 12),
          ),
          Slider(
            value: _height,
            min: 40,
            max: 120,
            divisions: 8,
            label: label,
            onChanged: (v) => setState(() => _height = v),
          ),
          const SizedBox(height: 8),
          const Text(
            '① 高度 40~120 之间变化；② 内容区始终紧贴顶栏下方（Scaffold 按 preferredSize.height 占位）。',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
