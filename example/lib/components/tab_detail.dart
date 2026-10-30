import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// Tab 家族详情，两段：
///   1) DefaultTabController 官方惯用法——TabBar / TabBarView 不传 controller，
///      由祖先 DefaultTabController 提供；
///   2) 显式 TabController——JS 侧 `new TabController({length: 3, vsync: this})`
///      与宿主真实 TabController 按 id 绑定（同 ScrollController 模式）：
///      用户点 tab 经 invoke 回传页码更新 index，按钮经 animateTo 驱动宿主切页。
@PatchEntry('TabDetail')
class TabDetail extends StatefulWidget {
  const TabDetail({super.key});

  @override
  State<TabDetail> createState() => _TabDetailState();
}

class _TabDetailState extends State<TabDetail>
    with SingleTickerProviderStateMixin {
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
                  tabs: const [
                    Tab(text: '广场'),
                    Tab(text: '推荐'),
                    Tab(text: '关注'),
                  ],
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
        Text(
          '显式 TabController · index = $_index',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 170,
          child: Column(
            children: [
              TabBar(
                controller: _controller,
                tabs: const [
                  Tab(text: '首页'),
                  Tab(text: '社区'),
                  Tab(text: '我的'),
                ],
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
          child: TextButton(
            onPressed: _next,
            child: const Text('下一 tab · controller.animateTo'),
          ),
        ),
      ],
    );
  }
}
