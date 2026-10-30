import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'list_item.dart';

@PatchEntry('ScrollDetail')
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

  /// 横向滚动视图的控制器（controller 监听 + 按钮「写」能力演示）：
  /// 原生侧真实持有；JS 热更侧翻译成 `this._scrollController =
  /// new ScrollController()`（JS 代理实例，方法/属性一比一）。
  final ScrollController _scrollController = ScrollController();

  /// ListView.builder 的「真实变化」验证信号：点「列表换色」时自增。
  /// 它参与 itemBuilder 的产出（决定 item 颜色）；滚动只改 _offset，颜色不变，
  /// 但已挂载项仍会随父级重建每帧收到 didUpdateWidget（与原生一致）。
  int _listSalt = 0;

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
        Text(
          'ListView.builder · 懒构建列表（offset: $_offset）',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        NotificationListener<ScrollNotification>(
          onNotification: _onListScroll,
          child: SizedBox(
            height: 160,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemExtent: 56,
              physics: const BouncingScrollPhysics(),
              itemCount: 20,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.list),
                title: CommonListItem(index: index, salt: _listSalt),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _listSalt += 1),
            child: const Text('列表换色（真实更新）'),
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
          child: TextButton(
            onPressed: _scrollToEnd,
            child: const Text('横向 · 跳到底'),
          ),
        ),
      ],
    );
  }
}
