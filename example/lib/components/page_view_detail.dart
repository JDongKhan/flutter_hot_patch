import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// PageView 详情：分页切换 + 指示点。页切换经 onPageChanged 回传页码
/// （值事件），JS 侧据此更新指示点。
@PatchEntry('PageViewDetail')
class PageViewDetail extends StatefulWidget {
  const PageViewDetail({super.key});

  @override
  State<PageViewDetail> createState() => _PageViewDetailState();
}

class _PageViewDetailState extends State<PageViewDetail> {
  /// 当前页（onPageChanged 回传）。
  int _page = 0;

  /// 外部 PageController：字段构造走 JS 同名代理类，PageView 按句柄桥接；
  /// 原生侧是真实 PageController，两边行为一致。
  final PageController _pageController = PageController(initialPage: 0);

  void _onPageChanged(int index) {
    setState(() => _page = index);
  }

  void _prevPage() {
    if (_page > 0) _pageController.jumpToPage(_page - 1);
  }

  void _nextPage() {
    if (_page < 2) _pageController.jumpToPage(_page + 1);
  }

  void _jumpToLast() => _pageController.jumpToPage(2);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PageView · 当前第 ${_page + 1} / 3 页',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 150,
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              Container(
                color: Colors.deepPurple.shade100,
                alignment: Alignment.center,
                child: const Text('第 1 页'),
              ),
              Container(
                color: Colors.teal.shade100,
                alignment: Alignment.center,
                child: const Text('第 2 页'),
              ),
              Container(
                color: Colors.orange.shade100,
                alignment: Alignment.center,
                child: const Text('第 3 页'),
              ),
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
                  color: i == _page
                      ? Colors.deepPurple
                      : const Color(0xFFBDBDBD),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: _prevPage, child: const Text('上一页')),
            TextButton(onPressed: _nextPage, child: const Text('下一页')),
            TextButton(onPressed: _jumpToLast, child: const Text('跳到第 3 页')),
          ],
        ),
      ],
    );
  }
}
