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

  /// 可选位置形参（默认值）：JS 签名保留为位置形参，函数体开头补缺省。
  int plus([int extra = 1]) => _cents + extra;

  /// 具名形参（默认值）：具名实参合并成尾参对象 `__o`，函数体开头解构。
  int scaled({int factor = 2, int bonus = 0}) => _cents * factor + bonus;

  /// 静态方法的具名形参走同一套签名规则。
  static Price fromCents(int cents, {int discount = 0}) =>
      Price(cents - discount);
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
  ///
  /// hashCode 只验证**契约**（`a == b` ⇒ hash 相等），不比较原生 / JS 的原始
  /// 散列值——Dart 只保证同一执行内一致，跨运行时数值本来就不同。
  String _operatorText() {
    final Price a = Price(100);
    final Price b = Price(23);
    final Price total = a + b;
    total.cents = 150; // setter
    final Price sameValue = Price(150);
    final bool same = total == sameValue;
    final bool hashSame = total.hashCode == sameValue.hashCode;
    final Price neg = -b;
    return 'setter/运算符：sum=${total.cents} / 相等=$same / hash一致=$hashSame '
        '/ 取负=${neg.cents}';
  }

  /// 多 catch 子句 + `on Type` 过滤（`int.parse('x')` 抛 FormatException）。
  String _tryText() {
    final parts = <String>[];
    for (final raw in ['12', 'x']) {
      try {
        parts.add('解析=${int.parse(raw)}');
      } on FormatException {
        parts.add('格式错误');
      } catch (e) {
        parts.add('其它:$e');
      }
    }
    return 'try/catch：${parts.join('，')}';
  }

  /// 集合元素：`if` 元素 / `for` 元素 / `...` 展开。
  String _collectionText() {
    final scores = _scores ?? const [0, 0, 0];
    final base = [10, 20];
    final merged = [
      1,
      if (scores.isNotEmpty) scores.first,
      ...base,
      for (final s in scores) s * 2,
    ];
    return '集合元素：${merged.join('/')}';
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

  /// 三段式 for 集合元素：`[for (var i = 0; i < n; i++) f(i)]`。
  String _forPartsText() {
    final cells = [
      for (var i = 0; i < 3; i++) i * i,
    ];
    return '三段式集合：${cells.join('/')}';
  }

  /// label 语句：外层标签 + `break outer`（JS 原生同形）。
  String _labelText() {
    final scores = _scores;
    var hit = 0;
    outer:
    for (final v in scores ?? const [0]) {
      for (final w in [v, v + 1]) {
        if (w >= 4) {
          hit = w;
          break outer;
        }
      }
    }
    return 'label：hit=$hit';
  }

  /// rethrow：catch 内原样重抛原始异常，外层继续捕获。
  String _rethrowText() {
    var trace = '';
    try {
      try {
        int.parse('x');
      } on FormatException {
        trace = '内层';
        rethrow;
      }
    } on FormatException {
      trace = '$trace → 外层捕获';
    }
    return 'rethrow：$trace';
  }

  /// 空安全级联：目标为 null 时整条级联短路（返回 null，section 不执行）。
  String _cascadeText() {
    final nums = <int>[]
      ..add(1)
      ..add(2);
    final List<int>? alias = nums;
    final List<int>? nothing = null;
    final live = alias?..add(3);
    final dead = nothing?..add(9)..add(8);
    return '级联：列表=${nums.join('/')} / 非空分支=${live?.length ?? 0} '
        '/ 空分支=${dead?.length ?? 'null'}';
  }

  /// 位运算 / 移位 / 一元 `~` / 复合赋值（含 JS 没有的 `~/=`）。
  String _bitwiseText() {
    final a = 6; // 110
    final b = 3; // 011
    final bAnd = a & b; // 2
    final bOr = a | b; // 7
    final bXor = a ^ b; // 5
    final lsh = a << 2; // 24
    final rsh = -8 >> 1; // -4（算术右移，符号保留）
    final lrsh = -8 >>> 1; // 32 位无符号右移
    final inv = ~a; // -7
    var quot = 6;
    quot ~/= 4; // 1（向零截断）
    var mask = 6;
    mask &= ~2; // 4（清位：6 & ~2）
    final nums = [8, 16];
    final idx = 1;
    nums[idx] ~/= 3; // 16 ~/ 3 = 5（下标单次求值）
    final cells = [10, 20];
    cells[0] += 5; // 15（下标复合赋值）
    var counter = 1;
    counter <<= 2; // 4
    return '位运算：and=$bAnd or=$bOr xor=$bXor lsh=$lsh rsh=$rsh '
        'lrsh=$lrsh not=$inv ~/=$quot mask=$mask idx-num=${nums[idx]} '
        'cells=${cells[0]} shl=$counter';
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

  /// 形参签名：类方法 / 局部函数 / 闭包的「可选位置 + 默认值」与「具名」。
  String _paramsText() {
    int localScale(int v, [int factor = 3]) => v * factor;
    int localPack(int v, {int step = 2, int times = 1}) => v + step * times;

    final namedClosure = ({int a = 1, int b = 2}) => a + b;
    final optionalClosure = (int v, [int k = 10]) => v + k;

    final base = _task?.score ?? 20;
    final price = Price(base);
    return '形参：方法可选=${price.plus()}/${price.plus(4)} '
        '/ 方法具名=${price.scaled(factor: 2, bonus: base)} '
        '/ 局部可选=${localScale(4)} '
        '/ 局部具名=${localPack(1, step: 3, times: 2)} '
        '/ 闭包具名=${namedClosure(b: 5)} '
        '/ 闭包可选=${optionalClosure(1)} '
        '/ 静态具名=${Price.fromCents(base, discount: 3).cents}';
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
          Text(_paramsText()),
          Text(_switchExprText()),
          Text(_switchStmtText()),
          Text(_operatorText()),
          Text(_tryText()),
          Text(_collectionText()),
          Text(_patternForText()),
          Text(_caseElementText()),
          Text(_forPartsText()),
          Text(_labelText()),
          Text(_bitwiseText()),
          Text(_rethrowText()),
          Text(_cascadeText()),
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
