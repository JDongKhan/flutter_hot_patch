import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 生成器语法 demo：`sync*` / `yield` / `yield*`。
///
/// JS 侧一比一产出 `function*` / `*method`；生成器对象本身不是数组，
/// 运行时在共享的 %GeneratorPrototype% 上补了 `toList` / `map` / `first`
/// 等 Dart Iterable 同名成员（先物化为数组再复用 Array 语义）。
@PatchEntry('GeneratorDetail')
class GeneratorDetail extends StatelessWidget {
  const GeneratorDetail({super.key});

  /// sync* 方法：惰性产出 0..n-1 的平方。
  Iterable<int> _squares(int n) sync* {
    for (var i = 0; i < n; i++) {
      yield i * i;
    }
  }

  /// yield* 委托：先产出 -1，再接住另一个生成器，最后补 99。
  Iterable<int> _chain(int n) sync* {
    yield -1;
    yield* _squares(n);
    yield 99;
  }

  String _generatorText() {
    // 局部生成器函数。
    Iterable<String> tags() sync* {
      yield 'a';
      yield 'b';
    }

    // 生成器闭包。
    final Iterable<int> Function(int) evens = (int n) sync* {
      for (var i = 0; i < n; i++) {
        yield i * 2;
      }
    };

    final List<int> chained = _chain(3).toList();
    final List<String> tagList = tags().toList();
    var sum = 0;
    for (final v in evens(4)) {
      sum += v;
    }
    return '生成器：chain=${chained.join('/')} / tags=${tagList.join(',')} '
        '/ 闭包求和=$sum / first=${_squares(4).first}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '生成器：sync* / yield / yield*',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_generatorText()),
      ],
    );
  }
}
