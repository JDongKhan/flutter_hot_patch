import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

// ---------------------------------------------------------------------------
// 枚举：Dart enum → JS 常量对象（E.member / E.values / e.name / e.index）
// ---------------------------------------------------------------------------

enum TaskLevel { low, medium, high }

// ---------------------------------------------------------------------------
// 普通类：命名构造（生成式 + factory）与初始化列表
// ---------------------------------------------------------------------------

/// 任务数据：三个命名构造分别走「this.x 形参」「非 this 形参 + 初始化列表」
/// 「factory 委托」三种形态。
class TaskItem {
  final String title;
  final int score;
  final TaskLevel level;

  /// 生成式命名构造：`this.title` 形参。
  TaskItem.highlight(this.title)
      : score = 100,
        level = TaskLevel.high;

  /// 生成式命名构造：非 this 形参，字段在初始化列表里赋值。
  TaskItem.scored(String title, {required int score})
      : title = title,
        score = score,
        level = TaskLevel.medium;

  /// factory 命名构造：委托给另一个命名构造。
  factory TaskItem.fromLevel(String title, TaskLevel level) =>
      TaskItem.scored(title, score: level.index * 10);

  String describe() => '$title · ${level.name} · $score';
}

// ---------------------------------------------------------------------------
// 页面
// ---------------------------------------------------------------------------

@PatchEntry('SyntaxDetail')
class SyntaxDetail extends StatefulWidget {
  const SyntaxDetail({super.key});

  @override
  State<SyntaxDetail> createState() => _SyntaxDetailState();
}

class _SyntaxDetailState extends State<SyntaxDetail> {
  TaskItem? _task;
  String? _note;
  List<int>? _scores;
  String? _upper;
  int? _first;
  int? _second;
  String? _chain;

  /// 三个命名构造 + 空安全调用 / 空安全下标 / 空安全链。
  void _run() {
    setState(() {
      _task = TaskItem.highlight('阅读');
      _note = 'hello';
      _scores = [3, 1, 4];
      _upper = _note?.toUpperCase();
      _first = _scores?[0];
      _scores?[1] = 1;
      _second = _scores?[1];
      _chain = _task?.level.name;
    });
  }

  /// 接收者为 null：`?.` 整条链为 null（`a?.b.c` 不会再去取 `b.c`），
  /// 空安全赋值同样整条跳过。
  void _clear() {
    setState(() {
      _task = null;
      _note = null;
      _scores = null;
      _upper = _note?.toUpperCase();
      _first = _scores?[0];
      _scores?[1] = 1;
      _second = _scores?[1];
      _chain = _task?.level.name;
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
    final task = _task;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '空安全 · 命名构造 · 枚举',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('枚举：${TaskLevel.values.length} 项，'
              '首个=${TaskLevel.values[0].name}，'
              'high.index=${TaskLevel.high.index}，'
              'high=${TaskLevel.high.toString()}'),
          const SizedBox(height: 8),
          Text('命名构造：${task == null ? '(点击按钮生成)' : task.describe()}'),
          Text('当前等级：${task == null ? '-' : _levelText(task.level)}'),
          const SizedBox(height: 8),
          Text('空安全调用：_note?.toUpperCase() = ${_upper ?? 'null'}'),
          Text('空安全下标：_scores?[0] = ${_first ?? 'null'}'),
          Text('空安全赋值：_scores?[1] = 1 → ${_second ?? 'null'}'),
          Text('空安全链：_task?.level.name = ${_chain ?? 'null'}'),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(onPressed: _run, child: const Text('生成')),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: _clear, child: const Text('置空')),
            ],
          ),
        ],
      ),
    );
  }
}
