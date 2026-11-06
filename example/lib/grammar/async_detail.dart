import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 异步语法 demo：`async` / `await` + `Future.delayed`，以及 `Completer` 手动完成
/// （`complete` / `completeError` / `isCompleted` / `future`）。
///
/// JS 侧 `Completer` 由 `flutter.js` 的同名类承接：内部持有一个 Promise，
/// `future` 是 Future 实例，`await` / `then` 走与 Future 相同的通道。
@PatchEntry('AsyncDetail')
class AsyncDetail extends StatefulWidget {
  const AsyncDetail({super.key});

  @override
  State<AsyncDetail> createState() => _AsyncDetailState();
}

class _AsyncDetailState extends State<AsyncDetail> {
  String _status = '未启动';
  String _error = '未触发';
  bool _busy = false;

  /// Completer 正常完成：延迟 300ms 后 `complete(42)`，再 `await future`。
  Future<void> _run() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = '等待 complete…';
    });
    final completer = Completer<int>();
    Future.delayed(
      const Duration(milliseconds: 300),
      () => completer.complete(42),
    );
    final value = await completer.future;
    setState(() {
      _status = '收到 $value，isCompleted=${completer.isCompleted}';
      _busy = false;
    });
  }

  /// Completer 异常完成：`completeError(StateError(...))`，await 侧按类型捕获。
  Future<void> _runError() async {
    final completer = Completer<int>();
    Future.delayed(
      const Duration(milliseconds: 200),
      () => completer.completeError(StateError('演示错误')),
    );
    try {
      await completer.future;
    } on StateError catch (e) {
      setState(() => _error = '捕获：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '异步：Future / await / Completer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('状态：$_status'),
        Text('异常分支：$_error'),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(onPressed: _run, child: const Text('complete(42)')),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _runError,
              child: const Text('completeError'),
            ),
          ],
        ),
      ],
    );
  }
}
