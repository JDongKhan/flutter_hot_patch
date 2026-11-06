import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// record 语法 demo：
///   - 字面量：positional / named / mixed；
///   - 返回值：箭头体 / 语句体 / 局部函数 / 闭包；
///   - record 模式：位置 `(a, b)` / 命名 `(x: a, y: b)` 解构。
@PatchEntry('RecordDetail')
class RecordDetail extends StatelessWidget {
  const RecordDetail({super.key});

  /// record 作为返回值：箭头体。
  (int, String) _pairValue() => (5, 'e');

  /// record 作为返回值：语句体。
  ({int x, String y}) _namedPairValue() {
    return (x: 6, y: 'f');
  }

  /// record：positional / named / mixed 三种字面量形态 + 四种返回值来源。
  String _recordText() {
    final pos = (1, 'a');
    final named = (x: 2, y: 'b');
    final mixed = (3, ok: true);
    final arrow = _pairValue();
    final block = _namedPairValue();
    (int, String) localPair() => (7, 'g');
    final local = localPair();
    final (int, String) Function(int) make = (v) => (v, 'h');
    final closure = make(8);
    return 'record：${pos.$1}/${pos.$2} / '
        '${named.x}${named.y} / ${mixed.$1}:${mixed.ok} / '
        '返回值：${arrow.$1}${arrow.$2} ${block.x}${block.y} '
        '${local.$1}${local.$2} ${closure.$1}${closure.$2}';
  }

  /// 记录模式：位置 / 命名 → 解构 record 的统一对象表示。
  String _recordPatternText() {
    final pair = (1, 'a');
    final named = (x: 2, y: 3);
    if (pair case (final first, final second)) {
      return 'record 模式：$first / $second，命名：${named.x}+${named.y}';
    }
    return 'record 模式：未命中';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'record：字面量 · 返回值 · 模式解构',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_recordText()),
        Text(_recordPatternText()),
      ],
    );
  }
}
