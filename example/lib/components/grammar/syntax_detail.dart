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

  /// 可变字段：用于演示多层空安全赋值 `_task?.scores?[1] = 9`。
  List<int>? scores;

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
// setter + 运算符重载（`+` / `==` / 一元 `-`）：声明侧改写为 `__op$…` 成员
// ---------------------------------------------------------------------------

class Price {
  Price(this._cents);

  int _cents;

  int get cents => _cents;

  /// setter → JS 属性写访问器 `set cents(v)`；`p.cents = v` 原样生效。
  set cents(int v) => _cents = v;

  Price operator +(Price other) => Price(_cents + other._cents);

  Price operator -() => Price(-_cents);

  bool operator ==(Object other) => other is Price && other._cents == _cents;

  int get hashCode => _cents.hashCode;
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
  int? _cell;
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
      _task?.scores = [0, 0];
      _task?.scores?[1] = 9;
      _cell = _task?.scores?[1];
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
      _task?.scores?[1] = 9;
      _cell = _task?.scores?[1];
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

  /// setter + 运算符重载：`+` / 一元 `-` / `==` 走 `__op$` 分派，`p.cents = v` 走 setter。
  String _operatorText() {
    final Price a = Price(100);
    final Price b = Price(23);
    final Price total = a + b;
    total.cents = 150; // setter
    final bool same = total == Price(150);
    final Price neg = -b;
    return 'setter/运算符：sum=${total.cents} / 相等=$same / 取负=${neg.cents}';
  }

  /// 局部函数：表达式体 + 块体（块体内再用 if-case），两者都捕获外层字段。
  String _localFuncText() {
    int twice(int x) => x * 2;

    String grade(int score) {
      if (score case > 100 && < 200) return '高分';
      if (score case > 0) return '普通';
      return '无分';
    }

    final score = _task?.score ?? 0;
    return '局部函数：twice($score)=${twice(score)} / ${grade(score)}';
  }

  /// switch 表达式：对象模式 + guard（`_` / 常量之外的模式以前会被丢弃）。
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
    final task = _task;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '空安全 · 命名构造 · 枚举',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          Text('多层空安全赋值：_task?.scores?[1] = 9 → ${_cell ?? 'null'}'),
          Text(_matchText()),
          Text(_destructureText()),
          Text(_rangeText()),
          Text(_localFuncText()),
          Text(_switchExprText()),
          Text(_switchStmtText()),
          Text(_operatorText()),
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
