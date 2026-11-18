import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

/// MediaQuery 演示：完整打印 `MediaQuery.of(context)` 的每个字段，
/// 方便在「原生渲染」与「JS 热更」两种模式下逐项对比取值是否一致；
/// 同时展示方向 / 尺寸的常见直接读取、`MediaQuery.removePadding` 与
/// `MediaQuery(data: ...)` 的覆盖效果。
@PatchEntry('MediaQueryDetail')
class MediaQueryDetail extends StatefulWidget {
  const MediaQueryDetail({super.key});

  @override
  State<MediaQueryDetail> createState() => _MediaQueryDetailState();
}

class _MediaQueryDetailState extends State<MediaQueryDetail> {
  /// 控制 aspect 粒度验证demo 里被覆盖的 textScaler。
  bool _scaled = false;

  Widget _line(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(s, style: const TextStyle(fontSize: 12)),
      );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
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
        _line(
          'orientation：${mq.orientation == Orientation.portrait ? 'portrait' : 'landscape'}',
        ),
        _line('size：${mq.size.width.toStringAsFixed(0)} x '
            '${mq.size.height.toStringAsFixed(0)}'),
        _line('devicePixelRatio：${mq.devicePixelRatio.toStringAsFixed(2)}'),
        _line('padding.top：${mq.padding.top.toStringAsFixed(0)}'),
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
        const SizedBox(height: 14),
        const Text(
          'aspect 粒度：无关字段变化不重建',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          '切换 textScaler 时，只读 size 的探针 build 次数不应增加，只读 textScaler 的探针应 +1；原生与 JS 两侧计数应一致。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => setState(() => _scaled = !_scaled),
          child: Text('切换 textScaler（当前 ${_scaled ? '1.60' : '1.00'}）'),
        ),
        const SizedBox(height: 8),
        MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(_scaled ? 1.6 : 1.0),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SizeProbe(),
              _TextScalerProbe(),
            ],
          ),
        ),
      ],
    );
  }
}

/// 探针（只读 size）：父级重建不重建它，只有 size 变化才重建。
///
/// 挂在 const 子树上，所以父级 setState 不会触发它；用来验证
/// `MediaQuery.sizeOf` 的 aspect 粒度（textScaler 变化时 build 次数不变）。
class _SizeProbe extends StatefulWidget {
  const _SizeProbe();

  @override
  State<_SizeProbe> createState() => _SizeProbeState();
}

class _SizeProbeState extends State<_SizeProbe> {
  int _builds = 0;

  @override
  Widget build(BuildContext context) {
    _builds += 1;
    final size = MediaQuery.sizeOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '只读 size   值=${size.width.toStringAsFixed(0)} × '
        '${size.height.toStringAsFixed(0)}   build=$_builds',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

/// 探针（只读 textScaler）：textScaler 变化时 build 次数应 +1。
class _TextScalerProbe extends StatefulWidget {
  const _TextScalerProbe();

  @override
  State<_TextScalerProbe> createState() => _TextScalerProbeState();
}

class _TextScalerProbeState extends State<_TextScalerProbe> {
  int _builds = 0;

  @override
  Widget build(BuildContext context) {
    _builds += 1;
    final scale = MediaQuery.textScalerOf(context).scale(1).toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '只读 textScaler   值=$scale   build=$_builds',
        style: const TextStyle(fontSize: 12),
      ),
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
          _row('orientation', _enumText('${mq.orientation}')),
          _row('platformBrightness', _enumText('${mq.platformBrightness}')),
          _row('navigationMode', _enumText('${mq.navigationMode}')),
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

  /// 枚举 `toString()` 原生是 `Orientation.landscape`、跨桥后是 `landscape`；
  /// 去掉类型前缀，左右两栏才好逐项对比。
  String _enumText(String s) {
    final dot = s.indexOf('.');
    return dot >= 0 ? s.substring(dot + 1) : s;
  }

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
