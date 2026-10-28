import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// SliverFillRemaining 演示：用一个合格的 sliver 把**视口剩余高度**填满。
///
/// 一比一翻译说明：
///   - `child` 单元素 slot；`hasScrollBody` 缺省 true（子级是可滚动体，如
///     NestedScrollView 的内层），false 时按子级自身尺寸参与剩余空间计算；
///   - `fillOverscroll`（缺省 false）配合 BouncingScrollPhysics：触底回弹时
///     子级**拉伸**填满回弹区，false 时整块跟着位移（底部露出滚动区背景）；
///   - 头部 sliver 高度可切换，剩余高度随之变化——但贴底按钮始终贴底，
///     这就是「填满剩余」的直接证据。
@PatchEntry('SliverFillRemainingDetail')
class SliverFillRemainingDetail extends StatefulWidget {
  const SliverFillRemainingDetail({super.key});

  @override
  State<SliverFillRemainingDetail> createState() =>
      _SliverFillRemainingDetailState();
}

class _SliverFillRemainingDetailState extends State<SliverFillRemainingDetail> {
  bool _hasScrollBody = true;
  bool _fillOverscroll = false;
  bool _tallHeader = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SliverFillRemaining')),
      body: CustomScrollView(
        // 允许回弹，才能看到 fillOverscroll 的差别。
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'child 填满视口剩余高度，贴底元素始终贴底',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '触底回弹：fillOverscroll=true 子级拉伸填满回弹区；false 整块位移',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'hasScrollBody（缺省 true）',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Switch(
                        value: _hasScrollBody,
                        onChanged: (v) => setState(() => _hasScrollBody = v),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'fillOverscroll（缺省 false）',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Switch(
                        value: _fillOverscroll,
                        onChanged: (v) => setState(() => _fillOverscroll = v),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '加高头部（观察剩余高度变化）',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Switch(
                        value: _tallHeader,
                        onChanged: (v) => setState(() => _tallHeader = v),
                      ),
                    ],
                  ),
                  // 额外的头部高度：切换后 SliverFillRemaining 的剩余空间变小。
                  SizedBox(height: _tallHeader ? 120 : 0),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: _hasScrollBody,
            fillOverscroll: _fillOverscroll,
            child: Container(
              width: double.infinity,
              color: Colors.teal.shade50,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '剩余空间区域',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'hasScrollBody = $_hasScrollBody · fillOverscroll = $_fillOverscroll',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const Center(
                    child: Text(
                      '整块绿色区域由 SliverFillRemaining 撑满\n改变窗口高度或切「加高头部」看它跟随变化',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  // 贴底元素：无论剩余高度怎么变，它都在底边。
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('贴底按钮'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
