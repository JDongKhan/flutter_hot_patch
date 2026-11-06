import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 枚举语法 demo：Dart enum → JS 常量对象
/// （`E.member` / `E.values` / `e.name` / `e.index` / `byName` / `toString`），
/// 以及 `switch` 对枚举的全量分支。
@PatchEntry('EnumDetail')
class EnumDetail extends StatefulWidget {
  const EnumDetail({super.key});

  @override
  State<EnumDetail> createState() => _EnumDetailState();
}

enum TaskLevel { low, medium, high }

class _EnumDetailState extends State<EnumDetail> {
  TaskLevel _level = TaskLevel.medium;

  void _cycle() {
    setState(() {
      _level =
          TaskLevel.values[(_level.index + 1) % TaskLevel.values.length];
    });
  }

  String _levelText(TaskLevel level) {
    switch (level) {
      case TaskLevel.high:
        return '高';
      case TaskLevel.medium:
        return '中';
      case TaskLevel.low:
        return '低';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '枚举：values / name / index / byName / switch',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('枚举：${TaskLevel.values.length} 项，'
            '首个=${TaskLevel.values[0].name}，'
            'high.index=${TaskLevel.high.index}，'
            'byName=${TaskLevel.values.byName('high').name}，'
            'high=${TaskLevel.high.toString()}'),
        const SizedBox(height: 8),
        Text('当前等级：${_level.name}（${_levelText(_level)}）'),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _cycle, child: const Text('切换等级')),
      ],
    );
  }
}
