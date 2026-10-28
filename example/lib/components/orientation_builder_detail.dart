import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// OrientationBuilder / MediaQuery 演示：方向与窗口尺寸驱动的布局。
///
/// - ① `MediaQuery.of(context)` 直接读取：方向 / 逻辑尺寸 / 像素比 / 安全区；
/// - ② `OrientationBuilder` 按方向切换排列（竖屏纵向、横屏横向）；
/// - ③ `OrientationBuilder` 按方向切换属性值；
/// - ④ `LayoutBuilder` 直接读父约束（③ 的 `OrientationBuilder` 内部就是它）。
///
/// macOS 上窗口**宽 > 高** 即为 landscape；把窗口拉成高瘦即可看到 portrait
/// 分支，两侧（原生 / JS）应同步切换。
@PatchEntry('OrientationBuilderDetail')
class OrientationBuilderDetail extends StatelessWidget {
  const OrientationBuilderDetail({super.key});

  Widget _tile(String label, Color color) => Container(
        width: 52,
        height: 52,
        color: color,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
      );

  Widget _line(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(s, style: const TextStyle(fontSize: 12)),
      );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isPortrait = mq.orientation == Orientation.portrait;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OrientationBuilder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          '拉高窗口（高 > 宽）切到 portrait，压扁切回 landscape',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 10),

        // ① 直接读 MediaQuery：值与原生同一份 MediaQueryData。
        _line('orientation：${isPortrait ? 'portrait' : 'landscape'}'),
        _line('size：${mq.size.width.toStringAsFixed(0)} x '
            '${mq.size.height.toStringAsFixed(0)}'),
        _line('devicePixelRatio：${mq.devicePixelRatio.toStringAsFixed(2)}'),
        _line('padding.top：${mq.padding.top.toStringAsFixed(0)}'),
        const SizedBox(height: 10),

        // ② 按方向切换排列方式。
        const Text(
          '② 方向 → 排列',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.teal.shade50,
          child: OrientationBuilder(
            builder: (context, o) {
              final tiles = [
                _tile('A', Colors.teal),
                _tile('B', Colors.orange),
                _tile('C', Colors.indigo),
              ];
              if (o == Orientation.portrait) {
                return Column(mainAxisSize: MainAxisSize.min, children: tiles);
              }
              return Row(mainAxisSize: MainAxisSize.min, children: tiles);
            },
          ),
        ),
        const SizedBox(height: 10),

        // ③ 按方向切换属性值（内边距）。
        const Text(
          '③ 方向 → 属性值',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        OrientationBuilder(
          builder: (context, o) {
            if (o == Orientation.portrait) {
              return Container(
                color: Colors.orange.shade50,
                padding: const EdgeInsets.all(16),
                child: const Text('portrait：内边距 16'),
              );
            }
            return Container(
              color: Colors.orange.shade50,
              padding: const EdgeInsets.all(6),
              child: const Text('landscape：内边距 6'),
            );
          },
        ),
        const SizedBox(height: 10),

        // ④ LayoutBuilder：直接拿到父约束（OrientationBuilder 内部就是它）。
        const Text(
          '④ LayoutBuilder → 父约束',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 420;
            final tiles = [
              _tile('X', Colors.indigo),
              _tile('Y', Colors.pink),
            ];
            return Container(
              color: Colors.indigo.shade50,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'maxWidth：${c.maxWidth.toStringAsFixed(0)}   '
                    'maxHeight：${c.maxHeight.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'hasBoundedWidth：${c.hasBoundedWidth}   '
                    'hasBoundedHeight：${c.hasBoundedHeight}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'biggest：${c.biggest.width.toStringAsFixed(0)} x '
                    '${c.biggest.height.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  wide
                      ? Row(mainAxisSize: MainAxisSize.min, children: tiles)
                      : Column(mainAxisSize: MainAxisSize.min, children: tiles),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
