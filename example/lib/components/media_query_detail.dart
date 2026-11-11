import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// MediaQuery.removePadding 演示：按方向把系统安全区 padding 归零。
///
/// macOS 窗口的 `MediaQuery.padding` 全为 0，所以这里同时显示「外层」与
/// 「removePadding 子树」的实时值：桌面端两侧都是 0；移动端（刘海 / 手势条）
/// 能直观看到被移除的那一侧变成 0、其余侧保持原值。
@PatchEntry('MediaQueryDetail')
class MediaQueryDetail extends StatelessWidget {
  const MediaQueryDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MediaQuery.removePadding',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          '按方向移除安全区 padding，子树读到的是移除后的 MediaQueryData；本机 padding 全 0，移动端可见差异',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        const _PaddingReadout(label: '外层（原始 padding）', accent: Colors.orange),
        const SizedBox(height: 8),
        Container(
          color: Colors.grey.shade300,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            removeLeft: true,
            removeRight: true,
            child: const _PaddingReadout(label: 'removePadding 四边移除', accent: Colors.teal),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          color: Colors.grey.shade300,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: const _PaddingReadout(label: 'removePadding 仅移除 top', accent: Colors.indigo),
          ),
        ),
      ],
    );
  }
}

/// 读取**自己所在位置**的 padding（放在 removePadding 子树里即读到被移除后的值）。
class _PaddingReadout extends StatelessWidget {
  const _PaddingReadout({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = MediaQuery.paddingOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: L${p.left.toStringAsFixed(0)} T${p.top.toStringAsFixed(0)} '
            'R${p.right.toStringAsFixed(0)} B${p.bottom.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: p.top == 0 ? 4 : p.top,
            color: accent,
          ),
        ],
      ),
    );
  }
}
