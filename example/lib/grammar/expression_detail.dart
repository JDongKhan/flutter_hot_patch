import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'operator_detail.dart';

/// 返回可空列表：让 `?[` / 空安全赋值演示保持「目标可能为空」的静态类型，
/// 避免分析器把局部变量收窄成非空后把演示代码判成无效。
List<int>? _maybeCells(List<int> xs, bool present) => present ? xs : null;

/// 表达式语法 demo：位运算 / 移位 / 复合赋值、赋值作为表达式、级联、
/// `throw` 作为表达式。
@PatchEntry('ExpressionDetail')
class ExpressionDetail extends StatelessWidget {
  const ExpressionDetail({super.key});

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

  /// 赋值作为表达式：`while ((i = i + 1) < 4)` / 下标目标（接收者与下标各求值
  /// 一次）/ 空安全赋值（目标为空时值为 null）。
  String _assignExprText() {
    var i = 0;
    final steps = <int>[];
    while ((i = i + 1) < 4) {
      steps.add(i);
    }

    final cells = [9, 9];
    var slot = 0;
    final added = cells[(slot = 1)] += 3;
    final truncated = cells[(slot = 1)] ~/= 4;
    cells[(slot = 0)] ~/= 3;

    List<int>? maybe = _maybeCells(cells, true);
    final List<int>? missing = _maybeCells(cells, false);
    var hit = 0;
    final assigned = maybe?[0] = (hit = 7);
    final skipped = missing?[0] = 99;
    maybe = null;

    return '赋值表达式：steps=${steps.join('/')} / added=$added '
        '/ 整除=$truncated / 列表=${cells.join('/')} / slot=$slot '
        '/ assigned=${assigned ?? 'null'} / hit=$hit '
        '/ 空目标=${skipped ?? 'null'}';
  }

  /// 级联：空安全短路 + 级联内赋值（属性 setter / 下标 / 复合赋值）。
  String _cascadeText() {
    final nums = <int>[]
      ..add(1)
      ..add(2);
    final List<int>? alias = nums;
    final List<int>? nothing = null;
    final live = alias?..add(3);
    final dead = nothing?..add(9)..add(8)..[0] = 7;
    final price = Price(1)
      ..cents = 5
      ..cents += 2;
    final map = <String, int>{}
      ..['a'] = 1
      ..['b'] = 2;
    return '级联：列表=${nums.join('/')} / 非空分支=${live?.length ?? 0} '
        '/ 空分支=${dead?.length ?? 'null'} / setter=${price.cents} '
        '/ map=${map['b']}';
  }

  /// `throw` 作为表达式（`a ?? throw e` / 箭头体 `() => throw e`）。
  String _throwExprText() {
    int requireValue(List<int>? xs) =>
        xs?.first ?? (throw StateError('空列表'));
    final int Function() boom = () => throw StateError('箭头体');

    var caught = '';
    try {
      requireValue(null);
    } on StateError {
      caught += '空值';
    }
    try {
      boom();
    } on StateError {
      caught += '/箭头';
    }
    return 'throw 表达式：捕获=$caught';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '表达式：位运算 · 赋值表达式 · 级联 · throw',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_bitwiseText()),
        Text(_assignExprText()),
        Text(_cascadeText()),
        Text(_throwExprText()),
      ],
    );
  }
}
