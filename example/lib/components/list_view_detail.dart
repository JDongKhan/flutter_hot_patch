import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

/// ListView 用法集中演示。
///
/// 懒加载（JS 热更侧）：
///   - `ListView.builder` / `.separated`（有无 `itemExtent` 都一样）→ 懒：
///     宿主布局到某个槽位时才向 JS 拉取该项，只构建可见项（含 cacheExtent）；
///   - `ListView(children: …)` → 静态子项，进入页面即全部构建。
///
/// 每个子项的 `initState` / `dispose` 都打日志。两个验证入口：
///   - 顶部「模拟接口刷新」：条目数不变、只换内容，看可见项是否立即更新；
///   - item 短按改父组件模型（跨滚动验证），长按只刷新自身（验证局部更新）。
@PatchEntry('ListViewDetail')
class ListViewDetail extends StatefulWidget {
  const ListViewDetail({super.key});

  @override
  State<ListViewDetail> createState() => _ListViewDetailState();
}

class _ListViewDetailState extends State<ListViewDetail> {
  /// 懒列表的滚动偏移（NotificationListener 演示）。
  double _lazyOffset = 0;

  /// 父级 build 次数：item 本地刷新时不应变化。
  int _listBuilds = 0;

  /// 模型数据：条目数固定 20，演示「条目不变但内容变」。
  final List<String> _rows = [for (var i = 0; i < 20; i++) 'row-$i'];

  /// 模拟接口版本号（每次刷新 +1）。
  int _apiTick = 0;

  bool _onLazyScroll(ScrollNotification n) {
    setState(() => _lazyOffset = n.metrics.pixels);
    return false;
  }

  /// 模拟接口返回：条目数不变，只换每项内容。
  void _refreshFromApi() {
    _apiTick += 1;
    setState(() {
      for (var i = 0; i < _rows.length; i++) {
        _rows[i] = '接口 v$_apiTick · 行 $i';
      }
    });
    print('[ListView] api refresh v$_apiTick（条目数 ${_rows.length} 未变）');
  }

  /// item 短按：改父组件模型（跨滚动可见性验证）。
  void _onRowTap(int index) {
    setState(() => _rows[index] = '已点击 · 行 $index · v$_apiTick');
    print('[ListView] model change #$index -> "${_rows[index]}"');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '父级 build 次数：$_listBuilds（item 长按刷新时不应变化）。'
                '日志：initState = 首次挂载，dispose = 滚出缓存被回收。',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: _refreshFromApi,
                child: const Text('模拟接口刷新（条目数不变，只换内容）'),
              ),
            ],
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
          'ListView.builder（无 itemExtent）：同样懒 · 接模型数据',
          '短按改父级模型（滚走再滚回应显示新值）；长按只刷新自身。',
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _rows.length,
            itemBuilder: (context, index) => _ListProbeItem(
              tag: 'auto',
              index: index,
              label: _rows[index],
              onTap: () => _onRowTap(index),
            ),
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

/// 列表探针：挂载 / 回收打日志。
///
/// 短按 = 触发 [onTap]（改父级模型）；长按 = 只 setState 自身。
class _ListProbeItem extends StatefulWidget {
  const _ListProbeItem({
    required this.tag,
    required this.index,
    this.label,
    this.onTap,
  });

  final String tag;
  final int index;

  /// 父级模型里的内容（条目不变、内容变化的验证入口）。
  final String? label;

  /// 短按回调：由父级改模型并 setState。
  final VoidCallback? onTap;

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
  void _localRefresh() {
    setState(() => _refreshes += 1);
    print(
      '[ListView][${widget.tag}] local refresh #${widget.index} '
      '(refreshes=$_refreshes, builds=${_builds + 1})',
    );
  }

  /// 短按：有父级回调就交给模型，否则只刷新自身。
  ///
  /// 不用 `widget.onTap ?? _localRefresh` 直接做默认值：该混合表达式在翻译
  /// 阶段会被丢弃（onTap 键直接消失），点击静默失效。
  void _handleTap() {
    final onTap = widget.onTap;
    if (onTap != null) {
      onTap();
    } else {
      _localRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    _builds += 1;
    return InkWell(
      onTap: _handleTap,
      onLongPress: _localRefresh,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label ?? '${widget.tag} #${widget.index}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'build $_builds · 长按刷新 $_refreshes',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
