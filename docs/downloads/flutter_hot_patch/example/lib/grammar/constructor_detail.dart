import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'enum_detail.dart';

/// 构造语法 demo：命名构造（生成式 / 非 this 形参 + 初始化列表）、factory 委托、
/// 默认构造的「初始化列表 + 构造体」执行顺序。
@PatchEntry('ConstructorDetail')
class ConstructorDetail extends StatelessWidget {
  const ConstructorDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final byThis = TaskItem.highlight('阅读');
    final byInit = TaskItem.scored('算术', score: 75);
    final byFactory = TaskItem.fromLevel('实验', TaskLevel.low);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '命名构造 · factory · 初始化列表',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'TaskItem 三个命名构造分别走 this.x 形参、初始化列表、factory 委托；'
          'Stamp 演示默认构造的执行顺序。',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Text('this.x 形参：${byThis.describe()}'),
        Text('初始化列表：${byInit.describe()}'),
        Text('factory 委托：${byFactory.describe()}'),
        Text('默认构造：${Stamp(7).describe()}'),
      ],
    );
  }
}

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

/// 默认构造（无名构造）：非 `this.x` 形参 + 初始化列表 + 构造体，
/// 三者都在实例创建时执行。
class Stamp {
  final int base;
  final int doubled;
  String trace = '';

  Stamp(int base)
      : base = base,
        doubled = base * 2 {
    trace = 'built:$base';
  }

  String describe() => 'base=$base doubled=$doubled trace=$trace';
}
