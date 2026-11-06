import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'constructor_detail.dart';

/// 空安全语法 demo：`?.` 调用、`?[i]` 下标、空安全赋值、多层空安全链。
///
/// 接收者为 null 时，`?.` 整条链为 null（`a?.b.c` 不会再去取 `b.c`），
/// 空安全赋值同样整条跳过。
@PatchEntry('NullSafetyDetail')
class NullSafetyDetail extends StatefulWidget {
  const NullSafetyDetail({super.key});

  @override
  State<NullSafetyDetail> createState() => _NullSafetyDetailState();
}

class _NullSafetyDetailState extends State<NullSafetyDetail> {
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

  /// 接收者为 null：空安全链与空安全赋值全部短路。
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

  @override
  Widget build(BuildContext context) {
    final task = _task;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '空安全：?. / ?[] / 空安全赋值 / 多层链',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('命名构造：${task == null ? '(点击按钮生成)' : task.describe()}'),
        const SizedBox(height: 8),
        Text('空安全调用：_note?.toUpperCase() = ${_upper ?? 'null'}'),
        Text('空安全下标：_scores?[0] = ${_first ?? 'null'}'),
        Text('空安全赋值：_scores?[1] = 1 → ${_second ?? 'null'}'),
        Text('多层空安全赋值：_task?.scores?[1] = 9 → ${_cell ?? 'null'}'),
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
    );
  }
}
