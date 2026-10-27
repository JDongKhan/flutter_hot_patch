import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// ColorFiltered 演示：同一份彩色内容套不同 ColorFilter，直观对比颜色变化。
///
/// 覆盖 ColorFilter 的两种取值形态：
///   - `ColorFilter.mode(color, blendMode)`：按混合模式给子树着色
///     （multiply 压暗叠加、modulate 相乘）；
///   - `ColorFilter.matrix(List<double>)`：20 项颜色矩阵，这里用 BT.709
///     亮度系数做灰度。
///
/// 一比一翻译说明：`colorFilter` 是**值对象**（不是 widget），产物里翻成
/// `{kind:'mode', color, blendMode}` / `{kind:'matrix', matrix:[20 项]}` 普通
/// 对象，宿主 `colorFilterFromJson` 还原成原生 ColorFilter 后交给
/// ColorFiltered 渲染；子树照常由 `__h` 挂载。
@PatchEntry('ColorFilteredDetail')
class ColorFilteredDetail extends StatelessWidget {
  const ColorFilteredDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ColorFiltered',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          '四块内容完全相同，只有 colorFilter 不同',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        const _Sample(label: '① 原样（无滤镜）'),
        const SizedBox(height: 8),
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.deepOrange, BlendMode.multiply),
          child: const _Sample(label: '② mode · deepOrange × multiply'),
        ),
        const SizedBox(height: 8),
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.deepPurple, BlendMode.modulate),
          child: const _Sample(label: '③ mode · deepPurple × modulate'),
        ),
        const SizedBox(height: 8),
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0, 0, 0, 1, 0, //
          ]),
          child: const _Sample(label: '④ matrix · 灰度（BT.709）'),
        ),
      ],
    );
  }
}

/// 彩色样例：四色横向渐变 + 居中白字，滤镜效果一眼可见。
class _Sample extends StatelessWidget {
  const _Sample({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Colors.red, Colors.amber, Colors.green, Colors.blue],
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
