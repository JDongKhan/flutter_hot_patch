import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// MediaQuery 演示：完整打印 `MediaQuery.of(context)` 的每个字段，
/// 方便在「原生渲染」与「JS 热更」两种模式下逐项对比取值是否一致；
/// 同时展示 `MediaQuery.removePadding` 与 `MediaQuery(data: ...)` 的覆盖效果。
@PatchEntry('MediaQueryDetail')
class MediaQueryDetail extends StatelessWidget {
  const MediaQueryDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MediaQuery',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          '下面逐项显示 MediaQuery.of(context) 的全部字段：原生模式与 JS 热更模式各看一次即可对比。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        const _MediaQueryDump(label: '外层 MediaQuery.of(context)', accent: Colors.orange),
        const SizedBox(height: 8),
        Container(
          color: Colors.grey.shade300,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            removeLeft: true,
            removeRight: true,
            child: const _MediaQueryDump(label: 'removePadding 四边移除', accent: Colors.teal),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          color: Colors.grey.shade300,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: const _MediaQueryDump(label: 'removePadding 仅移除 top', accent: Colors.indigo),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'MediaQuery(data: ...)：覆盖子树读到的数据',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          '下面这段文字被 MediaQuery 覆盖了 textScaler（1.6x），其余字段沿用外层；下方 dump 里可看到 textScaler 变化。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('被 MediaQuery 放大的文字（1.6x）'),
              SizedBox(height: 8),
              _MediaQueryDump(label: 'MediaQuery(textScaler: 1.6)', accent: Colors.purple),
            ],
          ),
        ),
      ],
    );
  }
}

/// 把 `MediaQuery.of(context)`（= `MediaQueryData`）的全部字段逐行打印。
class _MediaQueryDump extends StatelessWidget {
  const _MediaQueryDump({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
          ),
          const SizedBox(height: 4),
          _row('size', '${mq.size.width.toStringAsFixed(1)} × ${mq.size.height.toStringAsFixed(1)}'),
          _row('padding', _edges(mq.padding)),
          _row('viewPadding', _edges(mq.viewPadding)),
          _row('viewInsets', _edges(mq.viewInsets)),
          _row('devicePixelRatio', mq.devicePixelRatio.toStringAsFixed(2)),
          _row('textScaler', mq.textScaler.scale(1).toStringAsFixed(2)),
          _row('orientation', '${mq.orientation}'),
          _row('platformBrightness', '${mq.platformBrightness}'),
          _row('navigationMode', '${mq.navigationMode}'),
          _row('alwaysUse24HourFormat', '${mq.alwaysUse24HourFormat}'),
          _row('accessibleNavigation', '${mq.accessibleNavigation}'),
          _row('disableAnimations', '${mq.disableAnimations}'),
          _row('invertColors', '${mq.invertColors}'),
          _row('highContrast', '${mq.highContrast}'),
          _row('boldText', '${mq.boldText}'),
        ],
      ),
    );
  }

  String _edges(EdgeInsets e) =>
      'L${e.left.toStringAsFixed(1)} T${e.top.toStringAsFixed(1)} '
      'R${e.right.toStringAsFixed(1)} B${e.bottom.toStringAsFixed(1)}';

  Widget _row(String name, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(name, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
