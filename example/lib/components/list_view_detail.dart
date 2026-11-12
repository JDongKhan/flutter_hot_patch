import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// ListView 用法集中演示。
///
/// 懒加载（JS 热更侧）：
///   - `ListView.builder` / `.separated`（有无 `itemExtent` 都一样）→ 懒：
///     宿主布局到某个槽位时才向 JS 拉取该项，只构建可见项（含 cacheExtent）；
///   - `ListView(children: …)` → 静态子项，进入页面即全部构建。
///
/// 每个子项的 `initState` / `dispose` 都打日志，可直接在日志台观察懒加载的
/// 挂载与回收。子项内的「点击刷新」只 `setState` 自身，用于验证 item 局部
/// 刷新不会带动整个 ListView 重建（看顶部「父级 build 次数」是否变化）。
@PatchEntry('ListViewDetail')
class ListViewDetail extends StatefulWidget {
  const ListViewDetail({super.key});

  @override
  State<ListViewDetail> createState() => _ListViewDetailState();
}

class _ListViewDetailState extends State<ListViewDetail> {
  /// 懒列表的滚动偏移（NotificationListener 演示）。
  double _lazyOffset = 0;

  /// 父级 build 次数：item 点击刷新时若保持不变，说明只有该项在重建。
  int _listBuilds = 0;

  bool _onLazyScroll(ScrollNotification n) {
    setState(() => _lazyOffset = n.metrics.pixels);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _listBuilds += 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.amber.shade50,
          child: Text(
            '父级 build 次数：$_listBuilds（点击 item 刷新时不应变化）。'
            '日志：initState = 首次挂载，dispose = 滚出缓存被回收。'
            '现在 builder / separated 无论有没有 itemExtent 都是懒的。',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        _section(
          'ListView.builder + itemExtent：懒加载（offset: ${_lazyOffset.toStringAsFixed(1)}）',
          '只构建可见项；滚动时逐项 initState，离屏回收 dispose。',
        ),
        SizedBox(
          height: 180,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onLazyScroll,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemExtent: 64,
              itemCount: 40,
              itemBuilder: (context, index) =>
                  _ListProbeItem(tag: 'lazy', index: index),
            ),
          ),
        ),
        _section(
          'ListView.builder（无 itemExtent）：同样懒',
          '宿主布局到该项时才向 JS 拉取；进入页面只构建可见的几条。',
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 20,
            itemBuilder: (context, index) =>
                _ListProbeItem(tag: 'auto', index: index),
          ),
        ),
        _section(
          'ListView.separated：同样懒',
          'item / separator 分槽拉取；separator 只在对应项进入视口时才构造。',
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
          '子项在 build 时已确定，原生与 JS 都一次性构建全部 18 项。',
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
          '横向 ListView.builder + itemExtent：懒加载',
          '横向滚动同样只构建可见项。',
        ),
        SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemExtent: 132,
            itemCount: 26,
            itemBuilder: (context, index) =>
                _ListProbeItem(tag: 'h-lazy', index: index),
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

/// 列表探针：挂载 / 回收打日志；点击只刷新自身，便于验证局部更新。
class _ListProbeItem extends StatefulWidget {
  const _ListProbeItem({super.key, required this.tag, required this.index});

  final String tag;
  final int index;

  @override
  State<_ListProbeItem> createState() => _ListProbeItemState();
}

class _ListProbeItemState extends State<_ListProbeItem> {
  int _builds = 0;
  int _refreshes = 0;

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

  /// 只改本项状态：父级 `_listBuilds` 不变 = ListView 没有整体重建。
  void _refresh() {
    setState(() => _refreshes += 1);
    print(
      '[ListView][${widget.tag}] item refresh #${widget.index} '
      '(refreshes=$_refreshes, builds=${_builds + 1})',
    );
  }

  @override
  Widget build(BuildContext context) {
    _builds += 1;
    return InkWell(
      onTap: _refresh,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.tag} #${widget.index}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'build $_builds · 点击刷新 $_refreshes',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
