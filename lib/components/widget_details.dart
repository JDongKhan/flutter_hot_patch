import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

import '../model/counter_vm.dart';

/// 常用组件详情页集合（widget_showcase 列表页点击进入）。
///
/// 每个详情组件都是 @UIComponent 注解组件：同一份代码
///   - 原生：直接当正常 StatefulWidget 用（widget_showcase 里 new 使用）；
///   - JS 热更：build_runner 翻译成 widget_details.js，
///     WidgetDetailPage 用 JsUiWidget 加载，原生 vs JS 同屏对比。
/// 单文件多组件：所有详情类在同一个产物里，运行时按组件名实例化。
///
/// 覆盖的 Flutter 常用组件与属性：
///   Text / TextStyle（maxLines、overflow、textAlign、decoration…）
///   ElevatedButton / TextButton / OutlinedButton + ButtonStyle 全属性
///   Row / Column / Expanded / Flexible / Stack / Positioned / Wrap / Spacer / SafeArea
///   Align / Padding / Center / SizedBox / Opacity / ConstrainedBox / AspectRatio / FractionallySizedBox
///   Image / Icon / CircleAvatar
///   Container / Card / Divider / DecoratedBox
///   ListView / SingleChildScrollView
///   Scaffold / AppBar / FloatingActionButton / BottomNavigationBar
///   TextField / Radio / DropdownButton / Switch / Checkbox / Slider
///   CircularProgressIndicator / LinearProgressIndicator
///   TabBar / TabBarView / Tab（DefaultTabController 与显式 TabController id-bridge）
///   PageView / Drawer / DrawerHeader

// ---------------------------------------------------------------------------
// Text 详情
// ---------------------------------------------------------------------------

@UIComponent('TextDetail')
class TextDetail extends StatefulWidget {
  const TextDetail({super.key});

  @override
  State<TextDetail> createState() => _TextDetailState();
}

class _TextDetailState extends State<TextDetail> {
  int _count = 0;

  void bump() {
    setState(() => _count++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('基础文案 + TextStyle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('普通文本，count = $_count（状态插值）', style: const TextStyle(color: Colors.blue, fontSize: 16)),
        const SizedBox(height: 6),
        Text('maxLines+overflow 测试：这是一段很长的文字会被截断成省略号显示', maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Text('textScaler.linear(1.6) 放大', textScaler: TextScaler.linear(1.6)),
        const SizedBox(height: 6),
        Text(
          'textAlign 居中',
          textAlign: TextAlign.center,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.orange,
            decorationStyle: TextDecorationStyle.wavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'softWrap=false 不换行测试',
          softWrap: false,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            wordSpacing: 2,
            letterSpacing: 1,
            backgroundColor: Color(0xFFFFE082),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(onPressed: bump, child: const Text('Bump count')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Button 详情
// ---------------------------------------------------------------------------

@UIComponent('ButtonDetail')
class ButtonDetail extends StatefulWidget {
  const ButtonDetail({super.key});

  @override
  State<ButtonDetail> createState() => _ButtonDetailState();
}

class _ButtonDetailState extends State<ButtonDetail> {
  int _pressed = 0;

  void onTap() {
    setState(() => _pressed++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('点击次数 = $_pressed', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(180, 48),
            maximumSize: const Size(240, 56),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 6,
            shadowColor: Colors.deepPurple,
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: const Text('Elevated · Styled'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(120, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: const TextStyle(fontSize: 14, letterSpacing: 1),
            foregroundColor: Colors.indigo,
          ),
          child: const Text('TextButton'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.orange, width: 2),
            minimumSize: const Size(120, 40),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            foregroundColor: Colors.deepOrange,
          ),
          child: const Text('OutlinedButton'),
        ),
        const SizedBox(height: 8),
        // 无 onPressed：禁用态
        const ElevatedButton(onPressed: null, child: Text('Disabled')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Layout 详情
// ---------------------------------------------------------------------------

@UIComponent('LayoutDetail')
class LayoutDetail extends StatefulWidget {
  const LayoutDetail({super.key});

  @override
  State<LayoutDetail> createState() => _LayoutDetailState();
}

class _LayoutDetailState extends State<LayoutDetail> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Row + Expanded / Flexible / Spacer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.blue.shade100,
                padding: const EdgeInsets.all(8),
                child: const Text('A', textAlign: TextAlign.center),
              ),
            ),
            const Spacer(flex: 1),
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.green.shade100,
                padding: const EdgeInsets.all(8),
                child: const Text('B（flex=2）', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Center / Align / Padding / SizedBox', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Center(
          child: Container(
            color: Colors.amber.shade100,
            padding: const EdgeInsets.all(12),
            child: const Text('Center 居中'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            color: Colors.purple.shade50,
            padding: const EdgeInsets.all(8),
            child: const Text('Align centerLeft'),
          ),
        ),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: const Text('Padding 包裹文案')),
        const SizedBox(height: 12),
        const Text('Stack + Positioned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 100,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Container(color: Colors.grey.shade200),
              Positioned.fill(
                child: Center(
                  child: Text(
                    'FILL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Positioned(left: 12, top: 12, child: Text('TL')),
              const Positioned(right: 12, bottom: 12, child: Text('BR')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text('Wrap · 自动换行', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Wrap(
          direction: Axis.horizontal,
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [for (var i = 1; i <= 5; i++) Chip(label: Text('chip $i'), backgroundColor: Colors.teal.shade50)],
        ),
        const SizedBox(height: 12),
        const Text(
          'Opacity / ConstrainedBox / AspectRatio / FractionallySizedBox',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Opacity(
          opacity: 0.5,
          child: Container(color: Colors.red, padding: const EdgeInsets.all(8), child: const Text('50% 透明')),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          child: Container(
            color: Colors.orange.shade100,
            padding: const EdgeInsets.all(8),
            child: const Text('ConstrainedBox 宽度 120-200'),
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1.78,
          child: Container(color: Colors.indigo.shade100, alignment: Alignment.center, child: const Text('16:9 比例')),
        ),
        const SizedBox(height: 8),
        FractionallySizedBox(
          widthFactor: 0.6,
          alignment: Alignment.center,
          child: Container(
            color: Colors.pink.shade100,
            padding: const EdgeInsets.all(8),
            child: const Text('60% 宽度', textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Image / Icon 详情
// ---------------------------------------------------------------------------

@UIComponent('ImageDetail')
class ImageDetail extends StatefulWidget {
  const ImageDetail({super.key});

  @override
  State<ImageDetail> createState() => _ImageDetailState();
}

class _ImageDetailState extends State<ImageDetail> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Image · 网络图片', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network('https://picsum.photos/seed/hotpatch/400/160', height: 120, fit: BoxFit.cover),
        ),
        const SizedBox(height: 12),
        const Text('Icon / CircleAvatar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            const Icon(Icons.home, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            const Icon(Icons.favorite, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.teal,
              child: Text('AV', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Container 详情
// ---------------------------------------------------------------------------

@UIComponent('ContainerDetail')
class ContainerDetail extends StatefulWidget {
  const ContainerDetail({super.key});

  @override
  State<ContainerDetail> createState() => _ContainerDetailState();
}

class _ContainerDetailState extends State<ContainerDetail> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Container · 颜色/圆角/Padding', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.all(Radius.circular(12))),
          child: const Text('容器内容（teal 圆角）', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 12),
        const Text('Container · 边框 + 阴影 + 渐变', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), offset: Offset(0, 4), blurRadius: 12, spreadRadius: 1),
            ],
          ),
          child: const Text('渐变 + 边框 + 阴影', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 12),
        const Text('DecoratedBox · 纯装饰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            border: Border.all(color: Colors.amber, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Padding(padding: EdgeInsets.all(12), child: Text('DecoratedBox 内容')),
        ),
        const SizedBox(height: 12),
        const Text('Card · shape / clipBehavior', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Card(
          elevation: 4,
          shadowColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.deepPurple, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: const Padding(padding: EdgeInsets.all(16), child: Text('圆角卡片 + 描边 + 阴影')),
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        const Text('SizedBox · 尺寸约束', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          width: 120,
          height: 48,
          alignment: Alignment.center,
          color: Colors.blueGrey.shade100,
          child: const Text('固定 120×48'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scroll 详情
// ---------------------------------------------------------------------------

@UIComponent('ScrollDetail')
class ScrollDetail extends StatefulWidget {
  const ScrollDetail({super.key});

  @override
  State<ScrollDetail> createState() => _ScrollDetailState();
}

class _ScrollDetailState extends State<ScrollDetail> {
  /// 当前滚动偏移（ListView，NotificationListener 演示）。
  /// 原生侧由 NotificationListener 直接更新；
  /// JS 热更侧同一份 build 源码经生成器翻译，宿主桥接组件把 metrics
  /// 快照 invoke 回传 `_onListScroll`，JS 里同样落到 this.offset。
  double _offset = 0;

  /// 横向 SingleChildScrollView 的滚动偏移（controller 监听演示）。
  /// 原生侧由 initState 的 addListener 匿名闭包更新；
  /// JS 热更侧同一份源码翻译成 `this._scrollController.addListener(
  /// function(){ this._ctrlOffset = this._scrollController.offset; })`——
  /// JS 侧也有 ScrollController 代理类（new ScrollController()），
  /// 宿主按 id 绑定真实 controller，滚动回传 metrics 镜像后触发该闭包。
  double _ctrlOffset = 0;

  /// 横向滚动视图的 controller（controller 监听 + 按钮「写」能力演示）：
  /// 原生侧真实持有；JS 热更侧翻译成 `this._scrollController =
  /// new ScrollController()`（JS 代理实例，方法/属性一比一）。
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 匿名闭包监听：原生侧直接挂真实 controller；
    // JS 热更侧同构翻译成 JS 闭包挂到代理实例（匿名天然支持，无需合成方法名）。
    _scrollController.addListener(() {
      setState(() => _ctrlOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _onListScroll(ScrollNotification n) {
    setState(() => _offset = n.metrics.pixels);
    return false;
  }

  /// 按钮：横向滚动视图跳到底（controller 的「写」能力）。
  /// 原生侧直接 jumpTo；JS 热更侧翻译成 `this._scrollController.jumpTo(
  /// this._scrollController.position.maxScrollExtent)`，JS 代理实例经
  /// 通用句柄 op（handleOp 'call' jumpTo，载荷带句柄 id）控制真实 controller。
  void _scrollToEnd() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('ListView.builder · 懒构建列表（offset: $_offset）', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        NotificationListener<ScrollNotification>(
          onNotification: _onListScroll,
          child: SizedBox(
            height: 160,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemExtent: 56,
              physics: const BouncingScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.list),
                title: Text('builder item $index'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'ListView.separated · 分隔列表',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: 6,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => ListTile(
              dense: true,
              leading: Icon(Icons.arrow_right, color: Colors.teal.shade300),
              title: Text('separated item $index'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'SingleChildScrollView · 长内容滚动（ctrl offset: $_ctrlOffset）',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              for (var i = 1; i <= 8; i++)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Chip(label: Text('横向 $i')),
                ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: _scrollToEnd, child: const Text('横向 · 跳到底')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sliver 详情（CustomScrollView 整页：sliver 全家桶，仅 JS 热更版展示）
// ---------------------------------------------------------------------------

/// CustomScrollView 完整页面 demo：SliverAppBar（导航）+ SliverToBoxAdapter
/// （普通盒子）+ SliverPadding + SliverList（列表）+ SliverGrid（九宫格）+
/// SliverFillRemaining（底部），外加 controller 监听滚动与 FAB「跳到底」。
@UIComponent('SliverDetail')
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
  /// 测量结果（见 capabilities/key_bridge.dart 的 `measure` op）。
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
      _measureText = 'x=${rect.dx.toStringAsFixed(1)} y=${rect.dy.toStringAsFixed(1)}'
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
            title: Text('SliverAppBar 导航 · offset ${_offset.toStringAsFixed(0)}'),
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
              decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(12)),
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
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList.separated(
              itemCount: 5,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                leading: const Icon(Icons.arrow_right, color: Colors.deepPurple),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SliverFixedExtentList · 固定高度',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                  decoration: BoxDecoration(color: Colors.teal.shade100, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Text('格 $index', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
          SliverSafeArea(
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('底部 · SliverSafeArea + SliverFillRemaining', style: const TextStyle(color: Colors.grey)),
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

// ---------------------------------------------------------------------------
// Grid 详情（GridView 懒加载验证，仅 JS 热更版展示）
// ---------------------------------------------------------------------------

@UIComponent('GridDetail')
class GridDetail extends StatefulWidget {
  const GridDetail({super.key});

  @override
  State<GridDetail> createState() => _GridDetailState();
}

class _GridDetailState extends State<GridDetail> {
  /// 挂在上方 GridView.builder 上的 controller（offset 镜像 + FAB 跳到底）。
  final ScrollController _controller = ScrollController();
  double _offset = 0;

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

  void _jumpBottom() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('GridView 懒加载验证'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: _jumpBottom,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        tooltip: '跳到底',
        child: const Icon(Icons.arrow_downward),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'controller offset: ${_offset.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'GridView.builder · 固定 3 列 · 30 项（懒加载）',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 5,
            child: GridView.builder(
              controller: _controller,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: 30,
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(color: Colors.teal.shade100, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text('格 $index', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'GridView.builder · MaxCrossAxisExtent 120 · 20 项（懒加载）',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: 20,
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text('项 $index', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scaffold 详情（页面级，仅 JS 热更版展示）
// ---------------------------------------------------------------------------

@UIComponent('ScaffoldDetail')
class ScaffoldDetail extends StatefulWidget {
  const ScaffoldDetail({super.key});

  @override
  State<ScaffoldDetail> createState() => _ScaffoldDetailState();
}

class _ScaffoldDetailState extends State<ScaffoldDetail> {
  int _navIndex = 0;

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
  }

  void _onFab() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text('Scaffold / AppBar / FAB / BottomNav'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        toolbarHeight: 56,
        actions: const [
          Icon(Icons.search, color: Colors.white),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.extension, size: 48, color: Colors.deepPurple),
              const SizedBox(height: 12),
              const Text('页面骨架组件演示'),
              Text('BottomNav 选中：$_navIndex'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFab,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        tooltip: '添加',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜索'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input 详情（TextField / Radio / DropdownButton / Switch / Checkbox / Slider）
// ---------------------------------------------------------------------------

@UIComponent('InputDetail')
class InputDetail extends StatefulWidget {
  const InputDetail({super.key});

  @override
  State<InputDetail> createState() => _InputDetailState();
}

class _InputDetailState extends State<InputDetail> {
  // TextEditingController 走 id-bridge（JS 代理类 ↔ 宿主真实实例）：
  // 输入经 textFn 回传镜像触发 listeners，JS 侧 _controller.text 可读、
  // _controller.clear() 可写，与 ScrollController 同款设计。
  final TextEditingController _controller = TextEditingController();
  String _text = '';
  String _choice = 'A';
  String _dropdown = '苹果';
  bool _switchOn = false;
  bool? _checked = false;
  double _slider = 0.4;

  @override
  void initState() {
    super.initState();
    // controller 监听：输入回传（__onHostText）与 clear() 都会触发，
    // 从 controller.text 镜像取值驱动 _text 显示（与 Dart 写法一致）。
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() => _text = _controller.text);
  }

  void _onTextChanged(String v) {
    setState(() => _text = v);
  }

  void _onChoiceChanged(Object? v) {
    setState(() => _choice = '$v');
  }

  void _onDropdownChanged(Object? v) {
    setState(() => _dropdown = '$v');
  }

  void _onSwitchChanged(bool? v) {
    setState(() => _switchOn = v ?? false);
  }

  void _onCheckChanged(bool? v) {
    setState(() => _checked = v);
  }

  void _onSliderChanged(double v) {
    setState(() => _slider = v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('TextField', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        TextField(
          controller: _controller,
          onChanged: _onTextChanged,
          decoration: const InputDecoration(hintText: '请输入文本', labelText: '用户名'),
          maxLines: 1,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text('输入内容：$_text', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        // 验证 JS 侧读 controller.text 镜像（经 __onHostText 回传），
        // 插值写法与 Dart 侧源码一比一。
        Text('controller.text：${_controller.text}', style: const TextStyle(fontSize: 14, color: Colors.deepPurple)),
        const SizedBox(height: 8),
        // 验证 JS 侧写 controller（clear() → host 通道清空宿主真实 controller）。
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(onPressed: () => _controller.clear(), child: const Text('清空输入')),
        ),
        const SizedBox(height: 12),
        const Text('Radio 单选', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            // Radio groupValue/onChanged 已废弃（RadioGroup 方案暂无 translator），
            // demo 先用旧 API 验证协议。
            // ignore: deprecated_member_use
            Radio(value: 'A', groupValue: _choice, onChanged: _onChoiceChanged, activeColor: Colors.deepPurple),
            const Text('选项 A'),
            // ignore: deprecated_member_use
            Radio(value: 'B', groupValue: _choice, onChanged: _onChoiceChanged, activeColor: Colors.deepPurple),
            const Text('选项 B'),
          ],
        ),
        Text('当前选择：$_choice', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 12),
        const Text('DropdownButton', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        DropdownButton(
          value: _dropdown,
          isExpanded: true,
          onChanged: _onDropdownChanged,
          items: const [
            DropdownMenuItem(value: '苹果', child: Text('苹果')),
            DropdownMenuItem(value: '香蕉', child: Text('香蕉')),
            DropdownMenuItem(value: '橙子', child: Text('橙子')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Switch(
              value: _switchOn,
              onChanged: _onSwitchChanged,
              // 协议键为 activeColor（生成器按此名提取），运行时映射到 activeThumbColor
              // ignore: deprecated_member_use
              activeColor: Colors.white,
              activeTrackColor: Colors.deepPurple,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.shade300,
            ),
            const SizedBox(width: 8),
            Text('Switch：${_switchOn ? "开" : "关"}'),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _checked,
              onChanged: _onCheckChanged,
              activeColor: Colors.deepPurple,
              checkColor: Colors.white,
            ),
            const SizedBox(width: 8),
            Text('Checkbox：${_checked ?? false}'),
          ],
        ),
        const SizedBox(height: 8),
        Text('Slider 值：$_slider', style: const TextStyle(fontSize: 14)),
        Slider(
          value: _slider,
          min: 0,
          max: 1,
          divisions: 10,
          label: '${(_slider * 100).round()}%',
          activeColor: Colors.deepPurple,
          inactiveColor: Colors.grey.shade300,
          onChanged: _onSliderChanged,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Progress 详情（指示器）
// ---------------------------------------------------------------------------

@UIComponent('ProgressDetail')
class ProgressDetail extends StatefulWidget {
  const ProgressDetail({super.key});

  @override
  State<ProgressDetail> createState() => _ProgressDetailState();
}

class _ProgressDetailState extends State<ProgressDetail> {
  final double _progress = 0.65;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('CircularProgressIndicator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            CircularProgressIndicator(
              value: _progress,
              color: Colors.deepPurple,
              backgroundColor: Colors.deepPurple.shade50,
              strokeWidth: 6,
            ),
            const SizedBox(width: 24),
            const CircularProgressIndicator(),
          ],
        ),
        const SizedBox(height: 16),
        const Text('LinearProgressIndicator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _progress,
          color: Colors.deepPurple,
          backgroundColor: Colors.deepPurple.shade50,
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        const LinearProgressIndicator(),
        const SizedBox(height: 8),
        Text('进度值：$_progress', style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier 详情（ChangeNotifier + ListenableBuilder 局部重建）
// ---------------------------------------------------------------------------

/// ChangeNotifier + ListenableBuilder 响应式热更 demo。
///
/// 原生：CounterModel 是真 ChangeNotifier，ListenableBuilder 注册监听，
/// notifyListeners → 局部重建。
/// JS 热更：CounterModel 翻译成 JS class（带 addListener/notifyListeners），
/// ListenableBuilder 翻译成 {type: ListenableBuilder, listenable: _model,
/// builder: _lbBuilder0} 节点，运行时挂 JS 监听，notify → 局部重建。
@UIComponent('NotifierCard')
class NotifierCard extends StatefulWidget {
  const NotifierCard({super.key});

  @override
  State<NotifierCard> createState() => _NotifierCardState();
}

class _NotifierCardState extends State<NotifierCard> {
  final _model = CounterVm();

  void _inc() => _model.inc();
  void _reset() => _model.reset();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenableBuilder(
              listenable: _model,
              builder: (context, _) =>
                  Text('count = ${_model.count}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _inc, child: const Text('+1')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }
}

/// StatelessWidget 详情：无 State、无 createState，build 在 widget 类自身
/// （生成器自动识别：有 createState 用 State 类承载 build，否则用 widget
/// 类自身）。构造参数（title / subtitle / badge）→ JS constructor(args)，
/// 由 JsUiWidget.props 传入。
@UIComponent('StatelessCard')
class StatelessCard extends StatelessWidget {
  const StatelessCard({super.key, required this.title, this.subtitle = '', this.badge = 'NEW'});

  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('$badge · $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TabBar / TabBarView 详情（tab 家族：DefaultTabController 与显式 TabController）
// ---------------------------------------------------------------------------

/// Tab 家族详情，两段：
///   1) DefaultTabController 官方惯用法——TabBar / TabBarView 不传 controller，
///      由祖先 DefaultTabController 提供；
///   2) 显式 TabController——JS 侧 `new TabController({length: 3, vsync: this})`
///      与宿主真实 TabController 按 id 绑定（同 ScrollController 模式）：
///      用户点 tab 经 invoke 回传页码更新 index，按钮经 animateTo 驱动宿主切页。
@UIComponent('TabDetail')
class TabDetail extends StatefulWidget {
  const TabDetail({super.key});

  @override
  State<TabDetail> createState() => _TabDetailState();
}

class _TabDetailState extends State<TabDetail> with SingleTickerProviderStateMixin {
  /// 显式 TabController（vsync 由 JS 代理类忽略，length/initialIndex 下发宿主建实例）。
  late final TabController _controller = TabController(length: 3, vsync: this);

  /// 当前页（controller 监听镜像）。
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _index = _controller.index);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// controller 驱动切页（「写」能力）。
  void _next() {
    _controller.animateTo((_index + 1) % 3);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'DefaultTabController · 官方惯用法（controller 由祖先提供）',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 180,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  indicatorColor: Colors.deepPurple,
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [Tab(text: '广场'), Tab(text: '推荐'), Tab(text: '关注')],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      Center(child: Text('TabBarView · 广场')),
                      Center(child: Text('TabBarView · 推荐')),
                      Center(child: Text('TabBarView · 关注')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('显式 TabController · index = $_index', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        SizedBox(
          height: 170,
          child: Column(
            children: [
              TabBar(
                controller: _controller,
                tabs: const [Tab(text: '首页'), Tab(text: '社区'), Tab(text: '我的')],
              ),
              Expanded(
                child: TabBarView(
                  controller: _controller,
                  children: [
                    Center(child: Text('第 1 页（index 0）')),
                    Center(child: Text('第 2 页（index 1）')),
                    Center(child: Text('第 3 页（index 2）')),
                  ],
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: _next, child: const Text('下一 tab · controller.animateTo')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PageView 详情
// ---------------------------------------------------------------------------

/// PageView 详情：分页切换 + 指示点。页切换经 onPageChanged 回传页码
/// （值事件），JS 侧据此更新指示点。
@UIComponent('PageViewDetail')
class PageViewDetail extends StatefulWidget {
  const PageViewDetail({super.key});

  @override
  State<PageViewDetail> createState() => _PageViewDetailState();
}

class _PageViewDetailState extends State<PageViewDetail> {
  /// 当前页（onPageChanged 回传）。
  int _page = 0;

  void _onPageChanged(int index) {
    setState(() => _page = index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('PageView · 当前第 ${_page + 1} / 3 页', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        SizedBox(
          height: 150,
          child: PageView(
            onPageChanged: _onPageChanged,
            children: [
              Container(color: Colors.deepPurple.shade100, alignment: Alignment.center, child: const Text('第 1 页')),
              Container(color: Colors.teal.shade100, alignment: Alignment.center, child: const Text('第 2 页')),
              Container(color: Colors.orange.shade100, alignment: Alignment.center, child: const Text('第 3 页')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page ? Colors.deepPurple : const Color(0xFFBDBDBD),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Key 家族详情（页面级，仅 JS 热更版展示）
// ---------------------------------------------------------------------------
//
// Key 的五类语义各一个「看得见」的用例（全部落在同一个列表页）：
//   ValueKey       —— 列表按**值**匹配。轮换顺序后，带 key 的行连状态一起搬家；
//                     不带 key 的列表按位置匹配，状态留在位置上（经典对照实验）。
//   ObjectKey      —— 按**对象身份**相等。同一批对象引用跨帧稳定（状态保留）；
//                     换成等值的新对象即被视为「新行」（状态重建）。
//   UniqueKey      —— 每次 build 都是新身份，等于强制重建该子树。
//   PageStorageKey —— 值相等，额外让宿主把滚动位置存进 PageStorage（切走再切回）。
//   GlobalKey      —— 身份跨帧稳定；宿主据此拿真实 BuildContext / RenderObject
//                     （本页演示「取位置 + 尺寸」与「滚动定位」，位置只在宿主算）。

/// 列表行：状态**只有** `_count` 一个字段——正因如此，key 校准的作用可以直接
/// 量出来：计数跟着「行」还是跟着「位置」。
///
/// label 由父级按当前顺序给出（key 里也是同一个值），这样换序后一眼就能看出
/// 状态到底留在了行上还是位置上了。
@UIComponent('KeyTile')
class KeyTile extends StatefulWidget {
  const KeyTile({super.key, required this.index, required this.label});

  /// 行在列表里的位置（仅用于展示）。
  final int index;

  /// 行标签（ValueKey 场景下与该行 key 的值同源）。
  final String label;

  @override
  State<KeyTile> createState() => _KeyTileState();
}

class _KeyTileState extends State<KeyTile> {
  int _count = 0;

  void bump() {
    setState(() => _count++);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final caption = '$label · 计数 $_count';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(child: Text(caption, style: const TextStyle(fontSize: 13))),
          TextButton(onPressed: bump, child: const Text('+1')),
        ],
      ),
    );
  }
}

/// Key 家族全员用例页（仅 JS 热更版展示：GlobalKey 的量测必须由宿主端算）。
@UIComponent('KeyDetail')
class KeyDetail extends StatefulWidget {
  const KeyDetail({super.key});

  @override
  State<KeyDetail> createState() => _KeyDetailState();
}

class _KeyDetailState extends State<KeyDetail> {
  // ---- ValueKey：列表按值匹配 ----
  final List<String> _names = ['A', 'B', 'C', 'D'];

  // ---- ObjectKey：按对象身份相等 ----
  /// 对象引用（每次 build 都是同一批实例 → key 稳定）。
  final List<List<int>> _rows = [
    [1, 1],
    [2, 2],
  ];
  /// 等值但**不同身份**的另一批对象（切过去即「新行」）。
  final List<List<int>> _rowsCopy = [
    [1, 1],
    [2, 2],
  ];
  bool _sameRef = true;

  // ---- UniqueKey：每次都是新身份（强制重建）----
  int _uniqueSeq = 0;

  // ---- PageStorageKey：滚动位置持久化 ----
  bool _storeA = true;

  // ---- GlobalKey：宿主端量测 + 定位 ----
  final GlobalKey _targetKey = GlobalKey();
  String _measureText = '未测量';

  // ===== 卡片 1：ValueKey vs 无 key =====

  void _rotateNames() {
    setState(() {
      final head = _names[0];
      _names.removeAt(0);
      _names.add(head);
    });
  }

  void _resetNames() {
    setState(() {
      _names.clear();
      _names.add('A');
      _names.add('B');
      _names.add('C');
      _names.add('D');
    });
  }

  Widget _valueKeyRows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('① 带 key：key: ValueKey(name)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        for (var i = 0; i < _names.length; i++) KeyTile(key: ValueKey(_names[i]), index: i, label: '${_names[i]}（key）'),
        const SizedBox(height: 10),
        const Text('② 不带 key：按位置匹配', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        for (var i = 0; i < _names.length; i++) KeyTile(index: i, label: '${_names[i]}（无 key）'),
      ],
    );
  }

  // ===== 卡片 2：ObjectKey =====

  void _flipRef() {
    setState(() => _sameRef = !_sameRef);
  }

  Widget _objectKeyRows() {
    if (_sameRef) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _rows.length; i++)
            KeyTile(key: ObjectKey(_rows[i]), index: i, label: '行${i + 1} · 同一对象引用'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _rowsCopy.length; i++)
          KeyTile(key: ObjectKey(_rowsCopy[i]), index: i, label: '行${i + 1} · 等值新对象'),
      ],
    );
  }

  // ===== 卡片 3：UniqueKey =====

  void _bumpUnique() {
    setState(() => _uniqueSeq++);
  }

  // ===== 卡片 4：PageStorageKey =====

  void _flipStore() {
    setState(() => _storeA = !_storeA);
  }

  Widget _storageView() {
    if (_storeA) {
      return SizedBox(
        height: 150,
        child: ListView(
          key: const PageStorageKey('key-page-a'),
          children: [
            for (var i = 0; i < 12; i++) ListTile(dense: true, title: Text('A 行 $i')),
          ],
        ),
      );
    }
    return SizedBox(
      height: 150,
      child: ListView(
        key: const PageStorageKey('key-page-b'),
        children: [
          for (var i = 0; i < 12; i++) ListTile(dense: true, title: Text('B 行 $i')),
        ],
      ),
    );
  }

  // ===== 卡片 5：GlobalKey =====

  /// 用 GlobalKey 取目标盒子的位置与尺寸。
  ///
  /// 与 SliverDetail 里同款链路：`currentContext → findRenderObject` 拿到
  /// 「RenderObject 代理」再测——`measure` 挂在代上（GlobalKey 本身没有）。
  /// `dynamic` 中转在这一跳（原生返回 RenderObject、没有 measure()）。
  Future<void> _measureTarget() async {
    final ctx = _targetKey.currentContext;
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
      _measureText = 'x=${rect.dx.toStringAsFixed(1)} y=${rect.dy.toStringAsFixed(1)}'
          ' · ${rect.width.toStringAsFixed(0)} × ${rect.height.toStringAsFixed(0)}';
    });
  }

  void _scrollToTarget() {
    final ctx = _targetKey.currentContext;
    if (ctx == null) {
      return;
    }
    final target = ctx.findRenderObject();
    if (target == null) {
      return;
    }
    target.showOnScreen();
  }

  // ===== 页面装配 =====

  // 卡片外壳直接写在每个 `_cardXxx()` 里：生成器只支持**无参已声明方法**在
  // widget 位置内联（`_valueKeyRows()` 可以），带实参的 helper 方法无法翻译
  // （会整张卡片降级成占位结点），故不做 `_card(title, desc, child)` 这种共用壳。
  Widget _cardValueKey() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ValueKey · 列表按值匹配',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 4),
          const Text(
            '换序后看两列计数：① 的状态跟着「行（值）」走，② 的状态留在「位置」上——'
            'reconciler 取 keySig（v:值）做「带 key 优先、无 key 按位置」的匹配。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          _valueKeyRows(),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: _rotateNames, child: const Text('轮换顺序（A→末尾）')),
              const SizedBox(width: 8),
              TextButton(onPressed: _resetNames, child: const Text('重置')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardObjectKey() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ObjectKey · 按对象身份相等',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 4),
          const Text(
            '行 key 包的是 _rows 里的对象引用：跨帧同一实例 → 状态保留；'
            '换成等值但不同身份的 _rowsCopy → 视为新行，状态重建。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          _objectKeyRows(),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _flipRef,
                child: Text(_sameRef ? '换成等值的新对象' : '换回原对象'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardUniqueKey() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'UniqueKey · 每次都是新身份',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 4),
          const Text(
            '点「重建」触发 setState：子树的 UniqueKey 每次都是新实例（身份新 → 元素不匹配），'
            '整棵子树重建、内部计数归零。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          KeyTile(key: UniqueKey(), index: 0, label: '唯一身份行 #$_uniqueSeq'),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: _bumpUnique, child: const Text('重建（setState 一次）')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardStorageKey() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PageStorageKey · 滚动位置持久化',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 4),
          const Text(
            '把 A 列表滚到中间 → 切到 B → 切回 A：位置应回到原处。'
            '值本体走值 codec（__psk），宿主造真实 PageStorageKey，位置由宿主端 PageStorage 存取。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          _storageView(),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _flipStore,
                child: Text(_storeA ? '切到 B 列表' : '切回 A 列表'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardGlobalKey() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'GlobalKey · 宿主端量测 / 定位',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 4),
          const Text(
            'currentContext → findRenderObject 这条链两端同形，但「值」只能在宿主算：'
            '位置与尺寸经异步桥回填（box.measure()），定位用真实 RenderObject 的 showOnScreen。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            key: _targetKey,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6)),
            child: const Text('目标盒子（GlobalKey 挂在这里）', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 8),
          Text('测量：$_measureText', style: const TextStyle(fontSize: 13, color: Colors.teal)),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton(onPressed: _measureTarget, child: const Text('测量位置与尺寸')),
              const SizedBox(width: 8),
              TextButton(onPressed: _scrollToTarget, child: const Text('定位（showOnScreen）')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Key 家族 · 全部用例'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Text(
              '每一张卡片一种 key 的语义；「计数」是 KeyTile 的内部 State，'
              '用它来观察状态是跟着行走还是跟着位置走。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          _cardValueKey(),
          _cardObjectKey(),
          _cardUniqueKey(),
          _cardStorageKey(),
          _cardGlobalKey(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer 详情（页面级，仅 JS 热更版展示）
// ---------------------------------------------------------------------------

/// Drawer / endDrawer 详情：drawer 接进真实 Scaffold 后 AppBar 左侧自动出现
/// 汉堡按钮，右侧为 endDrawer 入口；点菜单项回写选中项。
@UIComponent('DrawerDetail')
class DrawerDetail extends StatefulWidget {
  const DrawerDetail({super.key});

  @override
  State<DrawerDetail> createState() => _DrawerDetailState();
}

class _DrawerDetailState extends State<DrawerDetail> {
  /// 当前选中的菜单项（-1 = 未选）。
  int _picked = -1;

  void _pickOrders() {
    setState(() => _picked = 0);
  }

  void _pickFavorites() {
    setState(() => _picked = 1);
  }

  void _pickSettings() {
    setState(() => _picked = 2);
  }

  void _pickHelp() {
    setState(() => _picked = 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Drawer / endDrawer'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text('左侧抽屉', style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
            ),
            ListTile(leading: const Icon(Icons.receipt_long), title: const Text('我的订单'), onTap: _pickOrders),
            ListTile(leading: const Icon(Icons.favorite_border), title: const Text('我的收藏'), onTap: _pickFavorites),
          ],
        ),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text('右侧抽屉', style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
            ),
            ListTile(leading: const Icon(Icons.settings), title: const Text('设置'), onTap: _pickSettings),
            ListTile(leading: const Icon(Icons.help_outline), title: const Text('帮助与关于'), onTap: _pickHelp),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_open, size: 48, color: Colors.indigo),
            const SizedBox(height: 12),
            const Text('AppBar 左侧为汉堡按钮，右侧为 endDrawer 入口'),
            const SizedBox(height: 8),
            Text(_picked < 0 ? '尚未选择菜单项' : '选中菜单项 #$_picked'),
          ],
        ),
      ),
    );
  }
}
