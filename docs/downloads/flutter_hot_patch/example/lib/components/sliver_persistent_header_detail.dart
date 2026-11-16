import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// SliverPersistentHeader 演示：把「会随滚动折叠 / 浮出」的头部钉在视口边缘。
///
/// 一比一翻译说明：
///   - `SliverPersistentHeader(delegate:)` 的 delegate 只在 JS 里（`build`
///     在布局阶段按 shrinkOffset 同步执行）——JS 侧同步读 `minExtent` /
///     `maxExtent`，`build` 登记成句柄由宿主布局时回调，子树经 patch 回填；
///   - 高度插值 minExtent → maxExtent 由 Flutter 原生按滚动量完成；
///   - ① `pinned: true`：向上滚时 120 → 56 并钉在顶部；
///   - ② `floating: true`：向下滚回头时浮出（固定 48 高）。
@PatchEntry('SliverPersistentHeaderDetail')
class SliverPersistentHeaderDetail extends StatelessWidget {
  const SliverPersistentHeaderDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SliverPersistentHeader')),
      body: CustomScrollView(
        slivers: [
          // ① pinned：滚动时从 120 折到 56，并一直钉在顶部。
          SliverPersistentHeader(
            pinned: true,
            delegate: const _PinnedDelegate(),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ListTile(
                leading: const Icon(Icons.list, color: Colors.deepPurple),
                title: Text('列表项 $index'),
                subtitle: const Text('向上滚：pinned 头折叠并钉住'),
              ),
              childCount: 20,
            ),
          ),
          // ② floating：向下滚回来时浮出（固定 48，不钉住）。
          SliverPersistentHeader(
            floating: true,
            delegate: const _FloatingDelegate(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'floating 头下方的内容：先向下滚过它，再向上滚一点就会浮出',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// pinned delegate：高度 120 → 56，内容随 shrinkOffset 淡出字幕。
class _PinnedDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedDelegate();

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 120;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double t = shrinkOffset > 64 ? 1 : shrinkOffset / 64;
    return Container(
      color: Colors.deepPurple,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'pinned header',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Opacity(
            opacity: 1 - t,
            child: Text(
              'shrinkOffset = ${shrinkOffset.toStringAsFixed(1)} · overlaps = $overlapsContent',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedDelegate oldDelegate) => true;
}

/// floating delegate：固定 48 高。
class _FloatingDelegate extends SliverPersistentHeaderDelegate {
  const _FloatingDelegate();

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.teal,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Text(
        'floating header（向上滚回时浮出）',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FloatingDelegate oldDelegate) => false;
}
