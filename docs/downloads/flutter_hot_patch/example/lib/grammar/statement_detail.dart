import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 语句语法 demo：多 catch 子句 + `on Type` 过滤、`rethrow`、label + `break`。
@PatchEntry('StatementDetail')
class StatementDetail extends StatelessWidget {
  const StatementDetail({super.key});

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

  /// label 语句：外层标签 + `break outer`（JS 原生同形）。
  String _labelText() {
    final scores = [3, 1, 4];
    var hit = 0;
    outer:
    for (final v in scores) {
      for (final w in [v, v + 1]) {
        if (w >= 4) {
          hit = w;
          break outer;
        }
      }
    }
    return 'label：hit=$hit';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '语句：try/catch · rethrow · label',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_tryText()),
        Text(_rethrowText()),
        Text(_labelText()),
      ],
    );
  }
}
