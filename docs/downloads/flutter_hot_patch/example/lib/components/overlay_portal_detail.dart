import 'package:flutter/material.dart';
import 'package:hot_module_base/hot_module_base.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// OverlayPortal 三件套演示：
/// `OverlayPortal` + `CompositedTransformTarget` + `CompositedTransformFollower`。
///
/// 组件本体是 `hot_module_base` 里的 [GuideBubbleWidget]（跨包翻译验证）：
/// 气泡挂在 Overlay 上，位置靠 LayerLink 锚点跟随被锚定的按钮——切换按钮、
/// 滚动、重排时气泡自动跟着走；到时淡出并卸载。
@PatchEntry('OverlayPortalDetail')
class OverlayPortalDetail extends StatefulWidget {
  const OverlayPortalDetail({super.key});

  @override
  State<OverlayPortalDetail> createState() => _OverlayPortalDetailState();
}

class _OverlayPortalDetailState extends State<OverlayPortalDetail> {
  String _alignment = 'right';
  int _round = 0;

  /// 换一个 key 就重建气泡（重新 show + 重新计时），用来反复观察效果。
  void _replay() {
    setState(() => _round += 1);
  }

  void _switchAlignment(String value) {
    setState(() {
      _alignment = value;
      _round += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OverlayPortal / CompositedTransform', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('对齐方式：$_alignment', style: const TextStyle(fontSize: 12)),

        Row(
          children: [
            FilledButton(onPressed: () => _switchAlignment('left'), child: const Text('left')),
            const SizedBox(width: 8),
            FilledButton(onPressed: () => _switchAlignment('center'), child: const Text('center')),
            const SizedBox(width: 8),
            FilledButton(onPressed: () => _switchAlignment('right'), child: const Text('right')),
          ],
        ),
        const SizedBox(height: 16),

        // 气泡锚定在按钮下方；alignment 决定箭头贴左 / 居中 / 贴右。
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            GuideBubbleWidget(
              key: ValueKey('b1-$_round'),
              text: '点这里开始',
              alignment: _alignment,
              duration: const Duration(seconds: 3),
              child: OutlinedButton(onPressed: _replay, child: const Text('目标 A')),
            ),
            GuideBubbleWidget(
              key: ValueKey('b2-$_round'),
              text: '这是第二个锚点，气泡会自动跟随它',
              alignment: _alignment,
              duration: const Duration(seconds: 3),
              gap: 12,
              backgroundColor: const Color(0xE6307AF0),
              child: OutlinedButton(onPressed: _replay, child: const Text('目标 B')),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 气泡跟随滚动的验证：目标放在可滚动区域里，滚动时气泡跟着走。
        SizedBox(
          height: 180,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GuideBubbleWidget(
                    key: ValueKey('b3-$_round'),
                    text: '我在滚动区里，滚一下看我跟着走',
                    alignment: _alignment,
                    duration: const Duration(seconds: 3),
                    child: const Chip(label: Text('滚动里的锚点')),
                  ),
                ),
                const SizedBox(height: 300),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('第 $_round 次播放', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
