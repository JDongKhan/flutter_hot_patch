import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

/// SingleChildScrollView 用法演示（ListView 的全部用法见 `ListViewDetail`）。
///
/// 横向滚动 + ScrollController：
///   - 原生侧由真实 controller 监听 offset；
///   - JS 热更侧同构翻译成 ScrollController 代理实例，宿主按 id 绑定真实
///     controller，滚动 metrics 镜像回传后触发 JS 闭包。
/// 「跳到底」演示 controller 的写能力（jumpTo）。
@PatchEntry('ScrollDetail')
class ScrollDetail extends StatefulWidget {
  const ScrollDetail({super.key});

  @override
  State<ScrollDetail> createState() => _ScrollDetailState();
}

class _ScrollDetailState extends State<ScrollDetail> {
  /// 横向 SingleChildScrollView 的滚动偏移（controller 监听演示）。
  double _ctrlOffset = 0;

  /// 横向滚动视图的控制器（controller 监听 + 按钮「写」能力演示）。
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _ctrlOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SingleChildScrollView · 横向滚动（ctrl offset: ${_ctrlOffset.toStringAsFixed(1)}）',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              for (var i = 1; i <= 12; i++)
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
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ListView 的各种用法（children / builder / separated / itemExtent 懒加载）'
            '已集中到「ListView」demo。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
