import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// SliverFillViewport 演示：按「视口高度 × viewportFraction」给每项定高。
///
/// 覆盖：
///   - 主体页面：5 项 = 5 屏，fraction 可切 1.0 / 0.8 / 0.5；
///   - 下方固定高度区：fraction 0.5 + `padEnds: false`（首尾不留白，与主体
///     的 `padEnds: true` 对比）。
///
/// 一比一翻译说明：
///   - 每项高度由**视口**强制（不是内容撑出来的），所以 5 项 = 5 屏，滚动
///     一屏一屏翻；
///   - `viewportFraction < 1` 时相邻两屏露出（`padEnds` 控制首尾是否留白）；
///   - 子项可懒加载：视口 inflate 到该屏时才执行 itemBuilder。
@PatchEntry('SliverFillViewportDetail')
class SliverFillViewportDetail extends StatefulWidget {
  const SliverFillViewportDetail({super.key});

  @override
  State<SliverFillViewportDetail> createState() =>
      _SliverFillViewportDetailState();
}

class _SliverFillViewportDetailState extends State<SliverFillViewportDetail> {
  /// 每屏占视口的比例：1.0 整屏、0.8 / 0.5 露下一屏。
  double _fraction = 1.0;

  void _setFraction(double value) {
    setState(() {
      _fraction = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SliverFillViewport')),
      body: Column(
        children: [
          // 控制区：固定高度，不参与滚动。
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'viewportFraction = $_fraction',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '每屏高度 = 视口高度 × fraction；滚动按屏翻页',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _setFraction(1.0),
                      child: const Text('1.0 整屏'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _setFraction(0.8),
                      child: const Text('0.8'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _setFraction(0.5),
                      child: const Text('0.5'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 主体：delegate 形态。5 项 = 5 屏。
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverFillViewport(
                  viewportFraction: _fraction,
                  padEnds: true,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: index % 2 == 0
                            ? Colors.teal.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '第 $index 屏 / 共 5 屏',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SliverChildBuilderDelegate · fraction = $_fraction',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    childCount: 5,
                  ),
                ),
              ],
            ),
          ),
          // padEnds 对比：固定 160 高度，fraction 0.5 → 每项 80。
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey.shade200,
            child: const Text(
              'padEnds: false · fraction 0.5 · 3 项（首屏贴顶，不留白）',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          SizedBox(
            height: 160,
            child: CustomScrollView(
              slivers: [
                SliverFillViewport(
                  viewportFraction: 0.5,
                  padEnds: false,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Container(
                      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'padEnds false 第 $index 项',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    childCount: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
