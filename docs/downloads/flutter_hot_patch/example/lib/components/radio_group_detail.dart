import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// RadioGroup 演示：由 RadioGroup 统一提供选中值与回调，子级 Radio 不再传
/// `groupValue` / `onChanged`（两者是被 `RadioGroup` 取代的旧 API）。
///
/// 一比一翻译说明：
///   - `RadioGroup<int>(groupValue: …, onChanged: …, child: …)`：`groupValue` 与
///     `value` 走普通属性下发（`int` 原样传），`onChanged` 以句柄下发、宿主在
///     Radio 被点选时回传新值（一参事件）；
///   - 子级 `Radio<int>(value: n)` 只声明自己的值，选中状态由上方 RadioGroup 决定
///     （宿主用真值 `RadioGroup` 承载，继承关系天然生效）；
///   - 键盘方向键在 RadioGroup 内切选项由 Flutter 自己处理，无需额外实现。
@PatchEntry('RadioGroupDetail')
class RadioGroupDetail extends StatefulWidget {
  const RadioGroupDetail({super.key});

  @override
  State<RadioGroupDetail> createState() => _RadioGroupDetailState();
}

class _RadioGroupDetailState extends State<RadioGroupDetail> {
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RadioGroup', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '子级 Radio 只声明 value，选中值与回调统一由上方 RadioGroup 提供',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        RadioGroup<int>(
          groupValue: _selected,
          onChanged: (int? v) => setState(() => _selected = v ?? _selected),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _option(0, '选项 A'),
              _option(1, '选项 B'),
              _option(2, '选项 C'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
          child: Text(
            '当前选中：$_selected',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '① 点圆点切换选中项；② 焦点在组内时按方向键可上下切换；③ 选中值实时显示在下方。',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _option(int value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<int>(value: value),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
