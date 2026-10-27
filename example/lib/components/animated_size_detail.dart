import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// AnimatedSize 演示：子组件尺寸变化时由宿主按 duration / curve 自动补间。
///
/// JS 侧只下发目标尺寸与动画参数，逐帧插值不过桥；`alignment` 控制尺寸变化时
/// 子组件的对齐方式（默认居中）。
@PatchEntry('AnimatedSizeDetail')
class AnimatedSizeDetail extends StatefulWidget {
  const AnimatedSizeDetail({super.key});

  @override
  State<AnimatedSizeDetail> createState() => _AnimatedSizeDetailState();
}

class _AnimatedSizeDetailState extends State<AnimatedSizeDetail> {
  bool _expanded = false;
  bool _slow = false;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: _slow ? 1200 : 300);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'AnimatedSize · 尺寸自动补间',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueGrey.shade200),
            ),
            child: AnimatedSize(
              duration: duration,
              curve: Curves.easeInOut,
              alignment: Alignment.center,
              child: Container(
                width: _expanded ? 240 : 120,
                height: _expanded ? 120 : 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _expanded ? Colors.deepPurple : Colors.teal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _expanded ? '已展开' : '已收起',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? '收起尺寸' : '展开尺寸'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _slow = !_slow),
                child: Text(_slow ? '切回 300ms' : '切到 1200ms'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '当前时长：${duration.inMilliseconds}ms',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
