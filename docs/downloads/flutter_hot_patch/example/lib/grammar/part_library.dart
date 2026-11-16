import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

part 'part_library_part.dart';

/// `part` / `part of` 覆盖：根文件声明组件，part 文件提供模型 / 常量 / 私有函数。
///
/// 同库共享命名空间（含私有名），产物统一写在**库根** `part_library.js`；
/// `part_library_part.dart` 的产物只是占位模块。
@PatchEntry('PartLibrary')
class PartLibrary extends StatelessWidget {
  const PartLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    final model = PartModel(3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'part / part of：同库共享命名空间与一份产物',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(partSummary(model)),
        Text('跨 part 私有函数：${_privatePartLabel()}'),
      ],
    );
  }
}
