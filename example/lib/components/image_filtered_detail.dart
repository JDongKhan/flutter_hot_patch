import 'dart:typed_data' show Float64List;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// ImageFiltered 演示：对子树整体做图片级滤镜（不是给单色上滤镜）。
///
/// 四块对比：原样 / blur / dilate / 矩阵旋转 + compose（先转再糊）。
///
/// 一比一翻译说明：`ImageFilter` 是**值对象**，产物里由翻译层按构造名下发：
///   - `ImageFilter.blur(sigmaX:, sigmaY:)` → `{kind:'blur', sigmaX, sigmaY}`
///     （tileMode 可选，默认 clamp）；
///   - `ImageFilter.dilate/erode(radiusX:, radiusY:)` → `{kind, radiusX, radiusY}`；
///   - `ImageFilter.matrix([16 项])` → `{kind:'matrix', matrix:[…]}`（4×4）；
///   - `ImageFilter.compose(outer:, inner:)` → `{kind:'compose', outer, inner}`（递归）。
/// 宿主按同一份协议还原成原生 ImageFilter，因此模糊半径、矩阵、组合顺序与原生完全一致。
@PatchEntry('ImageFilteredDetail')
class ImageFilteredDetail extends StatelessWidget {
  const ImageFilteredDetail({super.key});

  static const LinearGradient _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.deepPurple, Colors.pinkAccent, Colors.orangeAccent],
  );

  /// 被滤镜处理的原始内容：横向渐变 + 大字，便于观察模糊/膨胀/旋转。
  Widget _panel(String label) {
    return Container(
      width: 210,
      height: 100,
      alignment: Alignment.center,
      decoration: const BoxDecoration(gradient: _gradient),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _row(String title, Widget filtered) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          filtered,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ImageFiltered', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '整棵子树作为图片处理：模糊 / 膨胀 / 矩阵 / 组合',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        _row('① 原样', _panel('A')),
        _row(
          '② blur(sigmaX: 3, sigmaY: 3)',
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: _panel('B'),
          ),
        ),
        _row(
          '③ dilate(radiusX: 3, radiusY: 3)',
          ImageFiltered(
            imageFilter: ImageFilter.dilate(radiusX: 3, radiusY: 3),
            child: _panel('C'),
          ),
        ),
        _row(
          '④ compose(outer: blur(2), inner: matrix(旋转 20°))',
          ImageFiltered(
            imageFilter: ImageFilter.compose(
              outer: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              inner: ImageFilter.matrix(Float64List.fromList(const [
                0.9397, 0.3420, 0.0, 0.0, //
                -0.3420, 0.9397, 0.0, 0.0, //
                0.0, 0.0, 1.0, 0.0, //
                0.0, 0.0, 0.0, 1.0, //
              ])),
            ),
            child: _panel('D'),
          ),
        ),
      ],
    );
  }
}
