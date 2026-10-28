import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// Spacer 演示：Row / Column 里的**弹性空隙**（`flex` 默认 1）。
///
/// 这是**单组件** demo，不涉及页面骨架：只返回组件本身（不带 Scaffold），
/// 由展示页把它和 JS 热更版同屏对比（原生 / JS 左右或上下并排）。
@PatchEntry('SpacerDetail')
class SpacerDetail extends StatefulWidget {
  const SpacerDetail({super.key});

  @override
  State<SpacerDetail> createState() => _SpacerDetailState();
}

class _SpacerDetailState extends State<SpacerDetail> {
  /// 中间空隙的 flex（1 份 / 2 份 / 3 份）。
  int _flex = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ① Row 里按 flex 比例分配剩余宽度。
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Row：Spacer(flex: $_flex) 在中间，右侧 1 份',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    color: Colors.indigo,
                    alignment: Alignment.center,
                    child: const Text('A', style: TextStyle(color: Colors.white)),
                  ),
                  Spacer(flex: _flex),
                  Container(
                    width: 40,
                    height: 40,
                    color: Colors.teal,
                    alignment: Alignment.center,
                    child: const Text('B', style: TextStyle(color: Colors.white)),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    color: Colors.orange,
                    alignment: Alignment.center,
                    child: const Text('C', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _flex = 1),
                    child: const Text('flex 1'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _flex = 2),
                    child: const Text('flex 2'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _flex = 3),
                    child: const Text('flex 3'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ② Column 里把底部内容顶到最下面（Spacer 吃满剩余高度）。
        // 固定高度区域：单组件 demo 不依赖页面剩余空间。
        SizedBox(
          height: 220,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Column：中间一个 Spacer()，底部按钮被顶到底',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('贴底按钮（由 Spacer 顶下来）'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
