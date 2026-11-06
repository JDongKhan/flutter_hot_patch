import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 集合字面量语法 demo：`if` 元素 / `for` 元素 / `...` 展开、三段式 `for` 元素。
@PatchEntry('CollectionDetail')
class CollectionDetail extends StatelessWidget {
  const CollectionDetail({super.key});

  /// 集合元素：`if` 元素 / `for` 元素 / `...` 展开。
  String _collectionText() {
    final scores = [3, 1, 4];
    final base = [10, 20];
    final merged = [
      1,
      if (scores.isNotEmpty) scores.first,
      ...base,
      for (final s in scores) s * 2,
    ];
    return '集合元素：${merged.join('/')}';
  }

  /// 三段式 for 集合元素：`[for (var i = 0; i < n; i++) f(i)]`。
  String _forPartsText() {
    final cells = [
      for (var i = 0; i < 3; i++) i * i,
    ];
    return '三段式集合：${cells.join('/')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '集合字面量：if / for / 展开',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_collectionText()),
        Text(_forPartsText()),
      ],
    );
  }
}
