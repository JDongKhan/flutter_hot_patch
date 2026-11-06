import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'constructor_detail.dart';

/// 模式匹配语法 demo：`if-case`、解构声明、关系 / 列表 / 对象模式、
/// `switch` 表达式与语句、pattern for、集合 `if-case` 元素。
@PatchEntry('PatternDetail')
class PatternDetail extends StatefulWidget {
  const PatternDetail({super.key});

  @override
  State<PatternDetail> createState() => _PatternDetailState();
}

class _PatternDetailState extends State<PatternDetail> {
  TaskItem? _task;
  List<int>? _scores;

  void _run() {
    setState(() {
      _task = TaskItem.highlight('阅读');
      _scores = [3, 1, 4];
    });
  }

  void _clear() {
    setState(() {
      _task = null;
      _scores = null;
    });
  }

  /// `if (x case P when g)`：对象模式 + 常量字段 + 守卫，绑定只在命中分支可见。
  String _matchText() {
    final task = _task;
    if (task case TaskItem(title: final title) when title.isNotEmpty) {
      return 'if-case 命中：$title / ${task.level.name}';
    }
    if (task case null) return 'if-case：null';
    return 'if-case：其它';
  }

  /// 解构声明：`final [a, b, c] = list;` → 三个绑定（先判空，避免 null 时抛错）。
  String _destructureText() {
    final scores = _scores;
    if (scores == null) return '解构：null';
    final [a, b, c] = scores;
    return '解构：$a / $b / $c';
  }

  /// 关系模式 + 逻辑与 + 列表模式（含 rest 绑定）。
  String _rangeText() {
    final score = _task?.score ?? 0;
    if (score case > 50 && < 200) return '关系模式：$score';
    final scores = _scores;
    if (scores case [final a, final b, ...final rest]) {
      return '列表模式：$a,$b +${rest.length}';
    }
    return '关系/列表：未命中';
  }

  /// pattern for 头：`for (final [a, b] in pairs)`（每轮解构，不匹配抛错）。
  String _patternForText() {
    final pairs = [
      [1, 2],
      [3, 4],
    ];
    var sum = 0;
    for (final [a, b] in pairs) {
      sum += a * b;
    }
    return 'pattern for：sum=$sum';
  }

  /// 集合 if-case 元素：`[if (x case P) a else b]`（绑定只在该元素内可见）。
  String _caseElementText() {
    final task = _task;
    final labels = [
      if (task case TaskItem(title: final t)) '标题:$t',
      if (task case null) '空',
    ];
    return '集合 if-case：${labels.join('，')}';
  }

  /// switch 表达式：对象模式 + guard。
  String _switchExprText() {
    final task = _task;
    final label = switch (task) {
      TaskItem(title: final title, score: final score) when score >= 100 =>
        '$title（满分 $score）',
      TaskItem(title: final title) => title,
      null => '未生成',
    };
    return 'switch 表达式：$label';
  }

  /// switch 语句：关系模式 + default（body 里直接 return）。
  String _switchStmtText() {
    final score = _task?.score ?? 0;
    switch (score) {
      case > 100 && < 200:
        return 'switch 语句：高分';
      case > 0:
        return 'switch 语句：普通';
      default:
        return 'switch 语句：无分';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '模式匹配：if-case / 解构 / 关系 / 列表 / switch',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_matchText()),
        Text(_destructureText()),
        Text(_rangeText()),
        Text(_patternForText()),
        Text(_caseElementText()),
        Text(_switchExprText()),
        Text(_switchStmtText()),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(onPressed: _run, child: const Text('生成')),
            const SizedBox(width: 12),
            OutlinedButton(onPressed: _clear, child: const Text('置空')),
          ],
        ),
      ],
    );
  }
}
