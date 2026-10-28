import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// NestedScrollView 演示：外层头部 slivers 与内层 body 联动滚动。
///
/// - ① 折叠头部（`pinned` + `expandedHeight`）：先滚外层折叠 AppBar，折叠完
///   才滚内层列表；
/// - ② 浮动头部（`floating` + `floatHeaderSlivers: true`）：内层列表滑回顶部时
///   头部自动浮出；
/// - ③ 头部带横向 TabBar（头部 slivers 里放 `SliverPersistentHeader` 之外的
///   普通 sliver），验证「头部是 sliver 列表」这一形态。
///
/// 一比一翻译说明：
///   - `headerSliverBuilder` 是**返回 sliver 列表的闭包**，JS 侧由
///     NestedScrollView 组件自己调用展开（第二参 `innerBoxIsScrolled`）；
///   - 头部 sliver 与 `body` 都以插槽下发宿主，宿主还原原生 NestedScrollView。
@PatchEntry('NestedScrollViewDetail')
class NestedScrollViewDetail extends StatelessWidget {
  const NestedScrollViewDetail({super.key});

  Widget _title(String s) => Text(
        s,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      );

  /// 内层列表：固定 12 行，行内标出序号。
  Widget _innerList(String tag, Color color) {
    return ListView.builder(
      itemCount: 12,
      itemBuilder: (context, index) => ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 12,
          backgroundColor: color,
          child: Text(
            '${index + 1}',
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
        title: Text('$tag 内层第 ${index + 1} 行'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NestedScrollView',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          '头部 slivers 与内层 body 联动：先折叠头部，再滚内层',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        _title('① pinned 折叠头部（expandedHeight 120）'),
        const SizedBox(height: 6),
        SizedBox(
          height: 240,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                title: const Text('pinned 头部'),
                flexibleSpace: Container(
                  color: Colors.teal.shade300,
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    '折叠区（flexibleSpace）',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('这段文字属于外层头部 sliver，随外层一起滚走'),
                ),
              ),
            ],
            body: _innerList('①', Colors.teal),
          ),
        ),
        const SizedBox(height: 12),
        _title('② floating + floatHeaderSlivers（内层滑回顶部时头部浮出）'),
        const SizedBox(height: 6),
        SizedBox(
          height: 240,
          child: NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: true,
                snap: true,
                title: const Text('floating 头部'),
                backgroundColor: Colors.deepOrange.shade300,
              ),
            ],
            body: _innerList('②', Colors.deepOrange),
          ),
        ),
      ],
    );
  }
}
