import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// CustomScrollView 完整页面 demo：SliverAppBar（导航）+ SliverToBoxAdapter
/// （普通盒子）+ SliverPadding + SliverList（列表）+ SliverGrid（九宫格）+
/// SliverFillRemaining（底部），外加 controller 监听滚动与 FAB「跳到底」。
@PatchEntry('SliverDetail')
class SliverDetail extends StatefulWidget {
  const SliverDetail({super.key});

  @override
  State<SliverDetail> createState() => _SliverDetailState();
}

class _SliverDetailState extends State<SliverDetail> {
  /// CustomScrollView 的 controller（整页滚动监听 + FAB「写」能力演示）。
  final ScrollController _controller = ScrollController();

  /// 当前滚动偏移（controller 监听镜像）。
  double _offset = 0;

  /// 「SliverFixedExtentList · 固定高度」分区的 GlobalKey（挂在分区**盒子**上，
  /// 不是 sliver 上：`size` / `localToGlobal` 都是 RenderBox 语义）。
  ///
  /// 导航右侧两个按钮都据此拿到**结点身份**：
  ///   - 「定位」：currentContext → findRenderObject → showOnScreen（位置由
  ///     viewport 自己算，滚动过去）；
  ///   - 「测量」：位置与尺寸同样只能在宿主端算——`box.size` /
  ///     `box.localToGlobal(Offset.zero)` 在 Flutter 里是**同步属性**，而
  ///     JS→宿主只有异步桥，故单源里 await 宿主回填的结果。
  /// GlobalKey 的身份跨帧稳定（JS 侧是句柄、宿主持真实实例）。
  final GlobalKey _fixedKey = GlobalKey();

  /// 「测量」结果文案（宿主回填的位置 + 尺寸快照）。
  String _measureText = '未测量';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _offset = _controller.offset);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// FAB：跳到底（controller「写」能力）。
  void _scrollToEnd() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  /// 导航右侧按钮：用 GlobalKey 定位「固定高度」分区并滚动到它。
  ///
  /// 与 FAB 的 `controller.jumpTo`（直接给偏移）不同，这里给的是**结点身份**：
  /// showOnScreen 沿渲染树向上交给所在 viewport，由 viewport 自己算出该结点的
  /// 位置并滚动——位置在宿主端计算，JS 侧只交出 GlobalKey 句柄。
  void _scrollToFixed() {
    final ctx = _fixedKey.currentContext;
    if (ctx == null) {
      return;
    }
    final target = ctx.findRenderObject();
    if (target == null) {
      return;
    }
    target.showOnScreen();
  }

  /// 导航右侧按钮：用 GlobalKey 取「固定高度」分区的位置与尺寸。
  ///
  /// 与「定位」不同，这里要的是**值**：Flutter 侧 `box.localToGlobal(Offset.zero)`
  /// 与 `box.size` 都是同步属性，而 JS 侧 RenderObject 根本不存在（GlobalKey 只是
  /// 句柄、真实实例在宿主），JS→宿主又只有异步桥——故这一处 await 宿主回填的
  /// 测量结果（见 capabilities/key/key_bridge.dart 的 `measure` op）。
  ///
  /// 链路与 Flutter 原生一致：`currentContext → findRenderObject()` 拿到
  /// 「RenderObject 代理」再取位置尺寸（`measure` 挂在代理上，GlobalKey 本身没有
  /// 这个方法）。`dynamic` 中转在 findRenderObject 这一跳：原生端返回 RenderObject
  /// （没有 measure()），JS 端返回 KeyRef 代理（有 measure()）——同一份代码两端都
  /// 成立；本组件只在 JS 热更版展示（widget_showcase 走 JsUiWidget），原生端不执行。
  Future<void> _measureFixed() async {
    final ctx = _fixedKey.currentContext;
    if (ctx == null) {
      return;
    }
    final dynamic box = ctx.findRenderObject();
    if (box == null) {
      return;
    }
    final dynamic rect = await box.measure();
    if (rect == null) {
      setState(() => _measureText = '量不到（未布局）');
      return;
    }
    setState(() {
      _measureText =
          'x=${rect.dx.toStringAsFixed(1)} y=${rect.dy.toStringAsFixed(1)}'
          ' · ${rect.width.toStringAsFixed(0)} × ${rect.height.toStringAsFixed(0)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            title: Text(
              'SliverAppBar 导航 · offset ${_offset.toStringAsFixed(0)}',
            ),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            pinned: true,
            floating: true,
            actions: [
              // 导航右侧按钮：用 GlobalKey 定位「固定高度」分区并滚动过去。
              IconButton(
                icon: const Icon(Icons.center_focus_strong),
                tooltip: '定位到「固定高度」分区',
                onPressed: _scrollToFixed,
              ),
              // 导航右侧按钮：用 GlobalKey 取该分区的位置与尺寸（宿主端计算回填）。
              IconButton(
                icon: const Icon(Icons.straighten),
                tooltip: '测量「固定高度」分区的位置与尺寸',
                onPressed: _measureFixed,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'CustomScrollView 整页 · SliverToBoxAdapter 盒子',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // 「测量」结果展示：点导航右侧直尺按钮 → GlobalKey 取位置 + 尺寸。
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'GlobalKey 测量：「固定高度」分区 $_measureText',
                style: const TextStyle(fontSize: 13, color: Colors.teal),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                for (var i = 1; i <= 5; i++)
                  ListTile(
                    leading: const Icon(Icons.list, color: Colors.deepPurple),
                    title: Text('SliverList item $i'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'SliverList.builder · 懒构建列表',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList.builder(
              itemCount: 8,
              itemBuilder: (context, index) => ListTile(
                leading: Icon(Icons.build, color: Colors.orange.shade700),
                title: Text('builder item $index'),
                subtitle: Text('index * 10 = ${index * 10}'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'SliverList.separated · 分隔列表',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList.separated(
              itemCount: 5,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                leading: const Icon(
                  Icons.arrow_right,
                  color: Colors.deepPurple,
                ),
                title: Text('separated item $index'),
              ),
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverToBoxAdapter(
              // 导航两个按钮的目标：GlobalKey 挂在**盒子**（RenderBox）上而不是
              // sliver 上——showOnScreen 两种都能用，但 size / localToGlobal 只有
              // RenderBox 才有（sliver 是 RenderSliver）。
              child: Container(
                key: _fixedKey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SliverFixedExtentList · 固定高度',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverFixedExtentList(
              itemExtent: 44,
              delegate: SliverChildBuilderDelegate(
                (context, index) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.height, color: Colors.teal),
                  title: Text('fixed item $index'),
                ),
                childCount: 6,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'SliverOpacity + SliverGrid.builder · MaxCrossAxisExtent 九宫格',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverOpacity(
            opacity: 0.6,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: 9,
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '格 $index',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          SliverSafeArea(
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  '底部 · SliverSafeArea + SliverFillRemaining',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToEnd,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        tooltip: '跳到底',
        child: const Icon(Icons.arrow_downward),
      ),
    );
  }
}
