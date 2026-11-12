import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// ListView 用法集中演示。
///
/// 懒加载判定（JS 热更侧）：
///   - `ListView.builder` 带 `itemExtent` → 懒容器：只构建可见项；
///   - 不带 `itemExtent` 的 builder / `ListView.separated` / `ListView(children:)`
///     → 非懒：进入页面时一次性构建全部子项。
///
/// 原生侧 Flutter 的 builder / separated 本身是懒的，因此两栏日志条数会不同。
/// 每个子项的 `initState` / `dispose` 都打日志，可直接在右侧日志台观察懒加载
/// 的挂载与回收。
@PatchEntry('ListViewDetail')
class ListViewDetail extends StatefulWidget {
  const ListViewDetail({super.key});

  @override
  State<ListViewDetail> createState() => _ListViewDetailState();
}

class _ListViewDetailState extends State<ListViewDetail> {
  /// 懒列表的滚动偏移（NotificationListener 演示）。
  double _lazyOffset = 0;

  bool _onLazyScroll(ScrollNotification n) {
    setState(() => _lazyOffset = n.metrics.pixels);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.amber.shade50,
          child: const Text(
            '日志说明：initState = 首次挂载，dispose = 滚出缓存被回收。'
            'JS 侧只有带 itemExtent 的 builder 是懒的；原生 Flutter 的 builder / '
            'separated 本身懒，因此两栏日志条数不同。',
            style: TextStyle(fontSize: 12),
          ),
        ),
        _section(
          'ListView.builder + itemExtent：JS 懒加载（offset: ${_lazyOffset.toStringAsFixed(1)}）',
          '只构建可见项；滚动时逐项 initState，离屏回收 dispose。',
        ),
        SizedBox(
          height: 180,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onLazyScroll,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemExtent: 56,
              itemCount: 40,
              itemBuilder: (context, index) =>
                  _ListProbeItem(tag: 'lazy', index: index),
            ),
          ),
        ),
        _section(
          'ListView.builder（无 itemExtent）：JS 非懒',
          '进入页面即构建全部 20 项：日志台会连续出现 20 条 initState。',
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 20,
            itemBuilder: (context, index) =>
                _ListProbeItem(tag: 'eager', index: index),
          ),
        ),
        _section(
          'ListView.separated：JS 非懒',
          'separatorBuilder 不参与懒判定；进入页面即构建全部 12 项。',
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 22,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _ListProbeItem(tag: 'separated', index: index),
          ),
        ),
        _section(
          'ListView(children: …)：静态子项',
          '子项在 build 时已确定，原生与 JS 都一次性构建全部 8 项。',
        ),
        SizedBox(
          height: 140,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (var i = 0; i < 18; i++) _ListProbeItem(tag: 'static', index: i),
            ],
          ),
        ),
        _section(
          '横向 ListView.builder + itemExtent：JS 懒加载',
          '横向滚动同样只构建可见项。',
        ),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemExtent: 96,
            itemCount: 26,
            itemBuilder: (context, index) =>
                _ListProbeItem(tag: 'lazy-horizontal', index: index),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _section(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// 列表探针：只负责在挂载 / 回收时打日志，方便观察懒加载效果。
class _ListProbeItem extends StatefulWidget {
  const _ListProbeItem({super.key, required this.tag, required this.index});

  final String tag;
  final int index;

  @override
  State<_ListProbeItem> createState() => _ListProbeItemState();
}

class _ListProbeItemState extends State<_ListProbeItem> {
  @override
  void initState() {
    super.initState();
    print('[ListView][${widget.tag}] initState #${widget.index}');
  }

  @override
  void dispose() {
    print('[ListView][${widget.tag}] dispose #${widget.index}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print('[ListView][${widget.tag}] build #${widget.index}');
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 20),
      child: Text(
        '${widget.tag} #${widget.index}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
