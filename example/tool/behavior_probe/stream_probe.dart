// CLI 行为探针：输出即断言，故允许 print。
// ignore_for_file: avoid_print

import 'dart:async';

/// Dart 侧行为基线：与 `stream_probe.mjs` 的用例逐条对应。
///
/// 用法（在 example/ 下）：
///   fvm dart tool/behavior_probe/stream_probe.dart
///   node tool/behavior_probe/stream_probe.mjs patch
///
/// 两份输出必须逐字一致；改 Stream / extension 语义时两边都要跑。
Future<void> main() async {
  // A 广播 pause：add / addError / close 期间缓冲，resume 后按序补发；close 等消费。
  {
    final log = <String>[];
    final c = StreamController<int>.broadcast();
    final sub = c.stream.listen(
      (v) => log.add('data:$v'),
      onError: (Object e) => log.add('err:$e'),
      onDone: () => log.add('done'),
    );
    sub.pause();
    c.add(1);
    c.addError('e1');
    var closed = false;
    unawaited(c.close().then((_) => closed = true));
    log.add('afterCloseCall');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    log.add('closeDone=$closed');
    sub.resume();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    print('A ${log.join('|')}');
  }

  // B 单订阅：首个订阅前 add 的事件被缓冲。
  {
    final got = <int>[];
    final c = StreamController<int>();
    c.add(1);
    await Future<void>.delayed(Duration.zero);
    c.stream.listen(got.add);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    print('B ${got.join(',')}');
  }

  // C map：上游 error 不终止下游流。
  {
    final out = <Object>[];
    final c = StreamController<int>();
    c.stream.map((x) => x * 2).listen(
          out.add,
          onError: (Object e) => out.add('err:$e'),
          onDone: () => out.add('done'),
        );
    c.add(1);
    c.addError('boom');
    c.add(2);
    unawaited(c.close());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    print('C ${out.join(',')}');
  }

  // D cancelOnError：提供 onError 时依然取消。
  {
    final out = <Object>[];
    final c = StreamController<int>();
    c.stream.listen(
      out.add,
      onError: (Object e) => out.add('err'),
      cancelOnError: true,
    );
    c.add(1);
    c.addError('x');
    c.add(2);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    print('D ${out.join(',')}');
  }

  // E await for break：取消传播到上游（只生产一项）。
  {
    var produced = 0;
    Stream<int> gen() async* {
      for (var i = 0; i < 20; i++) {
        produced++;
        yield i;
      }
    }

    await for (final _ in gen()) {
      break;
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    print('E $produced');
  }

  // F 同目标同名扩展的显式分派。
  print('F ${TagA('x').tag()} / ${TagB('x').tag()} / ${TagA('y').loud()}');
}

extension TagA on String {
  String tag() => 'A';

  /// 同名成员必须显式写出扩展（Dart 里 `this.tag()` 是歧义编译错误）。
  String loud() => '${TagA(this).tag()}!';
}

extension TagB on String {
  String tag() => 'B';
}
