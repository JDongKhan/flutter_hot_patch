import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 布局 / 交互补充组件演示：
/// `Tooltip` / `FittedBox` / `RotatedBox` / `IntrinsicHeight` / `IgnorePointer` /
/// `RepaintBoundary` / `Baseline` / `InteractiveViewer`。
@PatchEntry('LayoutMoreDetail')
class LayoutMoreDetail extends StatefulWidget {
  const LayoutMoreDetail({super.key});

  @override
  State<LayoutMoreDetail> createState() => _LayoutMoreDetailState();
}

class _LayoutMoreDetailState extends State<LayoutMoreDetail> {
  double _scale = 1;

  void _tap(String who) {
    setState(() => _lastTap = who);
  }

  String _lastTap = '（没点过）';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('布局 / 交互补充', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Tooltip：长按 / 悬停显示提示。
        Tooltip(
          message: '这是 Tooltip 的提示文字',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: const Text('长按 / 悬停看提示'),
          ),
        ),
        const SizedBox(height: 12),

        // FittedBox：父给的空间不够时按 fit 缩放子项（这里固定 100x40）。
        const Text('FittedBox（100x40 内放整行文字）', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        SizedBox(
          width: 100,
          height: 40,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              'ABCDEFGHIJKLMN',
              style: TextStyle(fontSize: 24, color: Colors.deepPurple.shade300),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // RotatedBox：按 90° 整数倍旋转，且**参与布局**（占位尺寸随旋转变化）。
        Row(
          children: [
            RotatedBox(
              quarterTurns: 1,
              child: Container(
                width: 60,
                height: 24,
                color: Colors.orange.shade200,
                alignment: Alignment.center,
                child: const Text('旋转 90°', style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 12),
            const Text('RotatedBox 参与布局', style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),

        // IntrinsicHeight：让 Row 里两个卡片等高（高度取最高的那个）。
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.green.shade50,
                  child: const Text('短文本'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.green.shade100,
                  child: const Text('长文本\n两行\n三行'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Baseline：两个不同字号的文本按基线（而非顶边）对齐。
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('大字', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            const Text('小字', style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),

        // IgnorePointer：透明遮罩 ignoring=true 时不拦截点击，事件穿透到按钮。
        Stack(
          children: [
            FilledButton(onPressed: () => _tap('可点按钮'), child: const Text('可点击')),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('最近点击：$_lastTap', style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 12),

        // RepaintBoundary：把子树隔离到独立图层（动画/频繁重绘时减少重绘范围）。
        RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: Text('当前缩放：$_scale', style: const TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 8),

        // InteractiveViewer：双指 / 鼠标滚轮缩放 + 拖动平移，倍率回传 JS。
        SizedBox(
          height: 160,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 3,
            boundaryMargin: const EdgeInsets.all(20),
            onInteractionUpdate: (details) =>
                setState(() => _scale = details.scale),
            child: Container(
              width: 320,
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: const Text('缩放 / 拖动我'),
            ),
          ),
        ),
      ],
    );
  }
}
