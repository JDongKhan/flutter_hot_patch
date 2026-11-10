import 'package:flutter/material.dart';
import 'package:hot_module_base/hot_module_base.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 时刻表日期选择器：年 / 月 / 日 / 周 四列联动滚轮。
///
/// 组件本体在 `hot_module_base`（跨包翻译）：原生页直接用；
/// JS 热更页由生成器把 [TimetableDatePicker] 的状态与 build 翻译成 JS，
/// 单列滚轮 `TimetableWheelColumn` 走 `@PatchIgnore` + 宿主原生注入。
@PatchEntry('TimetablePickerDetail')
class TimetablePickerDetail extends StatelessWidget {
  const TimetablePickerDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // 先算成局部变量：生成器对「嵌套在构造实参里的位置构造」不做形参名映射，
    // 语句层的位置构造会正常译成 new DateTime({year: …, month: …, day: …})。
    final initialDate = DateTime(today.year, today.month, today.day);
    final firstDate = today.subtract(const Duration(days: 30));
    final lastDate = today.add(const Duration(days: 365));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('时刻表日期选择器', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '年 / 月 / 日 / 周四列联动滚轮，周列随日期自动居中',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0), width: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TimetableDatePicker(
            initialDate: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
            itemHeight: 44,
            count: 4,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '拖动任一列可修改日期；周列只读，会自动跟随选择居中。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
