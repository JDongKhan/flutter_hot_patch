import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// Stream 能力 demo：`async*` 惰性流、`listen` 订阅、`await for`、
/// `StreamController`（单订阅 / broadcast）、转换与终止操作。
@PatchEntry('StreamDetail')
class StreamDetail extends StatefulWidget {
  const StreamDetail({super.key});

  @override
  State<StreamDetail> createState() => _StreamDetailState();
}

class _StreamDetailState extends State<StreamDetail> {
  String _listen = '未订阅';
  String _controller = '未启动';
  String _broadcast = '未启动';
  String _awaitFor = '未启动';
  String _transformed = '未启动';
  StreamSubscription<int>? _sub;

  /// `async*`：惰性流，首次 listen / 迭代才开跑。
  Stream<int> _ticks(int count) async* {
    for (var i = 1; i <= count; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      yield i;
    }
  }

  /// listen：onData / onError / onDone 三个回调 + 取消旧订阅。
  void _startListen() {
    _sub?.cancel();
    final values = <int>[];
    setState(() => _listen = '订阅中…');
    _sub = _ticks(3).listen(
      (v) {
        values.add(v);
        setState(() => _listen = '收到 ${values.join(',')}');
      },
      onError: (Object e) {
        setState(() => _listen = '错误：$e');
      },
      onDone: () {
        setState(() => _listen = '完成：${values.join(',')}');
      },
    );
  }

  /// pause / resume：单订阅流在暂停期间缓冲事件，恢复后按序补发。
  Future<void> _pauseResume() async {
    _sub?.cancel();
    final values = <int>[];
    final sub = _ticks(3).listen((v) {
      values.add(v);
      setState(() => _listen = '缓冲中：${values.join(',')}');
    });
    _sub = sub;
    sub.pause();
    await Future.delayed(const Duration(milliseconds: 650));
    sub.resume();
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() => _listen = 'resume：${values.join(',')}');
  }

  /// StreamController + map + toList + close。
  Future<void> _runController() async {
    final controller = StreamController<int>();
    final answer = controller.stream.map((v) => v * 2).toList();
    controller.add(10);
    controller.add(20);
    await controller.close();
    final values = await answer;
    setState(() {
      _controller = '${values.join(',')} / isClosed=${controller.isClosed}';
    });
  }

  /// broadcast：每个订阅者独立收到同一批事件（事件异步投递，close 后 await
  /// 再读结果，与 Dart 的事件队列时序一致）。
  Future<void> _runBroadcast() async {
    final controller = StreamController<int>.broadcast();
    final a = <int>[];
    final b = <int>[];
    controller.stream.listen((v) => a.add(v));
    controller.stream.listen((v) => b.add(v));
    controller.add(1);
    controller.add(2);
    await controller.close();
    setState(() => _broadcast = 'A=${a.join(',')} / B=${b.join(',')}');
  }

  /// await for：异步迭代整条流。
  Future<void> _runAwaitFor() async {
    final parts = <String>[];
    await for (final v in _ticks(3)) {
      parts.add('#$v');
    }
    setState(() => _awaitFor = parts.join(' '));
  }

  /// 静态工厂 + 转换链 + 终止操作（返回 Future）。
  Future<void> _runTransformed() async {
    final list = await Stream.fromIterable([1, 2, 3, 4])
        .where((v) => v.isEven)
        .map((v) => v * 10)
        .toList();
    final first = await Stream.value(7).first;
    setState(() => _transformed = 'list=${list.join(',')} / first=$first');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Stream：async* / listen / await for / Controller',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('listen / pause / resume：$_listen'),
        Text('controller：$_controller'),
        Text('broadcast：$_broadcast'),
        Text('await for：$_awaitFor'),
        Text('转换：$_transformed'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(onPressed: _startListen, child: const Text('listen')),
            OutlinedButton(
              onPressed: _pauseResume,
              child: const Text('pause/resume'),
            ),
            ElevatedButton(
              onPressed: _runController,
              child: const Text('Controller'),
            ),
            OutlinedButton(
              onPressed: _runBroadcast,
              child: const Text('broadcast'),
            ),
            ElevatedButton(
              onPressed: _runAwaitFor,
              child: const Text('await for'),
            ),
            OutlinedButton(
              onPressed: _runTransformed,
              child: const Text('转换/终止'),
            ),
          ],
        ),
      ],
    );
  }
}
