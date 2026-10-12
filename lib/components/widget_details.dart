import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

import '../model/counter_model.dart';

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
        Text(
          'maxLines+overflow 测试：这是一段很长的文字会被截断成省略号显示',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          'textScaler.linear(1.6) 放大',
          textScaler: TextScaler.linear(1.6),
        ),
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
        const Text('Row + Expanded / Flexible / Spacer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        const Text('Center / Align / Padding / SizedBox',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: const Text('Padding 包裹文案'),
        ),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
          children: [
            for (var i = 1; i <= 5; i++)
              Chip(
                label: Text('chip $i'),
                backgroundColor: Colors.teal.shade50,
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Opacity / ConstrainedBox / AspectRatio / FractionallySizedBox',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Opacity(
          opacity: 0.5,
          child: Container(
            color: Colors.red,
            padding: const EdgeInsets.all(8),
            child: const Text('50% 透明'),
          ),
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
          child: Container(
            color: Colors.indigo.shade100,
            alignment: Alignment.center,
            child: const Text('16:9 比例'),
          ),
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
          child: Image.network(
            'https://picsum.photos/seed/hotpatch/400/160',
            height: 120,
            fit: BoxFit.cover,
          ),
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
          decoration: const BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
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
              BoxShadow(
                color: Color(0x66000000),
                offset: Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
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
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('DecoratedBox 内容'),
          ),
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
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('圆角卡片 + 描边 + 阴影'),
          ),
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
  /// 实例级 host 通道（scrollControllerJumpTo，载荷带 id）控制真实 controller。
  void _scrollToEnd() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('ListView · 列表（offset: $_offset）',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        NotificationListener<ScrollNotification>(
          onNotification: _onListScroll,
          child: SizedBox(
            height: 160,
            child: ListView(
              padding: const EdgeInsets.all(8),
              itemExtent: 56,
              physics: const BouncingScrollPhysics(),
              children: const [
                ListTile(leading: Icon(Icons.list), title: Text('item A')),
                ListTile(leading: Icon(Icons.list), title: Text('item B')),
                ListTile(leading: Icon(Icons.list), title: Text('item C')),
                ListTile(leading: Icon(Icons.list), title: Text('item D')),
                ListTile(leading: Icon(Icons.list), title: Text('item E')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('SingleChildScrollView · 长内容滚动（ctrl offset: $_ctrlOffset）',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          child: TextButton(
            onPressed: _scrollToEnd,
            child: const Text('横向 · 跳到底'),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            title: const Text('SliverAppBar 导航'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            pinned: true,
            floating: true,
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
                'SliverChildBuilderDelegate · 懒构建列表',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ListTile(
                  leading: Icon(Icons.build, color: Colors.orange.shade700),
                  title: Text('builder item $index'),
                  subtitle: Text('index * 10 = ${index * 10}'),
                ),
                childCount: 8,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'SliverFixedExtentList · 固定高度',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                'SliverOpacity + SliverGrid · MaxCrossAxisExtent 九宫格',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverOpacity(
            opacity: 0.6,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Container(
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
                  childCount: 9,
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
      appBar: AppBar(
        title: const Text('GridView 懒加载验证'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
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
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '项 $index',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
  // TextField 原生侧用 controller；JS 热更侧为受控封装（见 _JsTextField），
  // value 不下发时为非受控模式，onChanged 回传照常驱动 _text。
  final TextEditingController _controller = TextEditingController();
  String _text = '';
  String _choice = 'A';
  String _dropdown = '苹果';
  bool _switchOn = false;
  bool? _checked = false;
  double _slider = 0.4;

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
          decoration: const InputDecoration(
            hintText: '请输入文本',
            labelText: '用户名',
          ),
          maxLines: 1,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text('输入内容：$_text', style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
  final _model = CounterModel();

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
              builder: (context, _) => Text(
                'count = ${_model.count}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
  const StatelessCard({
    super.key,
    required this.title,
    this.subtitle = '',
    this.badge = 'NEW',
  });

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
                  child: Text(
                    '$badge · $title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
