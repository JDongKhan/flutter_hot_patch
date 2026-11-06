import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 数组 / List 语法 demo（「基础语法 · 列表」页点击进入）：
/// 原生与 JS 热更并排对比，覆盖运行时补齐的同名成员与构建期成员映射表。
///
/// 重点验证：
///   - `sort()` 无比较器 → `_sort`（Dart Comparable，而不是 JS 字符串序）；
///   - `join()` 默认分隔符 → `_join`（空串，而不是 JS 的 `','`）；
///   - `indexOf()` → `_indexOf`（对象按 `==` 比较，start 为负按 0、超长返回 -1）；
///   - `length = n` → `_setLength`（截断 / 补 null）；
///   - 其余同名成员（`fold` / `any` / `expand` / `take` / `skip` / `asMap` 等）
///     由运行时在同名原型上补齐；自定义类 / String 上的同名方法不改名。

/// `indexOf` 的对象相等用例：声明 `operator ==`，生成侧改写成 `__op$eq`。
class Coord {
  const Coord(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) => other is Coord && other.x == x && other.y == y;

  @override
  int get hashCode => x * 31 + y;
}

/// 成员链用例：`bucket.nums` 的静态类型从字段声明解析，`sort` / `indexOf`
/// 仍按 List 映射，不按方法名全局替换。
class Bucket {
  Bucket(this.nums);

  final List<int> nums;
}

@PatchEntry('ArrayDetail')
class ArrayDetail extends StatefulWidget {
  const ArrayDetail({super.key});

  @override
  State<ArrayDetail> createState() => _ArrayDetailState();
}

class _ArrayDetailState extends State<ArrayDetail> {
  @override
  Widget build(BuildContext context) {
    final nums = <int>[10, 9, 1];

    // sort：默认 Comparable（数值序）与自定义比较器；用副本，避免影响后续用例。
    final sortedDefault = [...nums]..sort();
    final sortedDesc = [...nums]..sort((a, b) => b - a);

    // join：默认分隔符是空串（JS 原生默认是 ','）。
    final letters = <String>['a', 'b', 'c'];
    final joinedDefault = letters.join();
    final joinedDash = letters.join('-');

    // indexOf：对象按 == 比较；start 语义（负数按 0、超长返回 -1）。
    final coords = <Coord>[const Coord(1, 2), const Coord(3, 4), const Coord(1, 2)];
    final idxEqual = coords.indexOf(const Coord(1, 2));
    final idxFrom = coords.indexOf(const Coord(1, 2), 2);
    final idxMiss = coords.indexOf(const Coord(5, 6));

    // 增删改：contains / remove / removeWhere / insert / addAll / removeAt。
    final bag = <int>[1, 2, 2, 3];
    final hasTwo = bag.contains(2);
    final removed = [...bag]..remove(2);
    final filtered = [...bag]..removeWhere((v) => v.isEven);
    final inserted = [...bag]..insert(1, 9);
    final appended = [...bag]..addAll(<int>[7, 8]);
    final removedAt = [...bag]..removeAt(0);

    // 迭代 / 查询：fold / any / every / expand / take / skip / firstWhere。
    final total = bag.fold<int>(0, (sum, v) => sum + v);
    final hasLarge = bag.any((v) => v > 2);
    final allPositive = bag.every((v) => v > 0);
    final doubled = bag.expand((v) => <int>[v, v]).toList();
    // map 在 List 接收者上按映射表改名为 `_map`（原生 map 立即求值，Dart 惰性）。
    final mapped = <int>[1, 2, 3].map((v) => v * 2).toList();
    final firstTwo = bag.take(2);
    final skipped = bag.skip(1);
    final found = bag.firstWhere((v) => v > 5, orElse: () => -1);

    // 下标 / 切片 / 填充 / asMap / elementAt。
    final atOne = bag.elementAt(1);
    final sub = bag.sublist(1, 3);
    final filled = <int>[0, 0, 0]..fillRange(0, 2, 7);
    final map = bag.asMap();

    // length 写：growable list 语义（截断 / 补 null）。
    final growable = <int?>[1, 2];
    growable.length = 4;
    // join 在语句位置走 `_join`（元素为 null 时按 Dart 输出 "null"）。
    final growableText = growable.join('-');

    // 成员链：`bucket.nums` 仍是 List，`sort` / `indexOf` 按映射表改写。
    final bucket = Bucket(<int>[3, 1, 2]);
    bucket.nums.sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('数组 · List 语义',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'JS 侧同名成员由运行时补齐；同名但语义不一致的走构建期映射表'
          '（sort → _sort、join → _join、indexOf → _indexOf、length 写 → _setLength），'
          '只对可判定为 List 的接收者生效。',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),

        Text('sort() 默认 → ${sortedDefault.join('-')}'),
        Text('sort((a, b) => b - a) → ${sortedDesc.join('-')}'),
        Text('join() 默认 → "$joinedDefault"'),
        Text('join("-") → "$joinedDash"'),
        const SizedBox(height: 8),

        Text('indexOf(Coord(1, 2)) → $idxEqual'),
        Text('indexOf(Coord(1, 2), start: 2) → $idxFrom'),
        Text('indexOf(Coord(5, 6)) → $idxMiss'),
        Text('contains(2) → $hasTwo'),
        const SizedBox(height: 8),

        Text('remove(2) → ${removed.join('-')}'),
        Text('removeWhere(偶数) → ${filtered.join('-')}'),
        Text('insert(1, 9) → ${inserted.join('-')}'),
        Text('addAll([7, 8]) → ${appended.join('-')}'),
        Text('removeAt(0) → ${removedAt.join('-')}'),
        const SizedBox(height: 8),

        Text('fold(0, +) → $total'),
        Text('any(> 2) → $hasLarge / every(> 0) → $allPositive'),
        Text('expand((v) => [v, v]) → ${doubled.join('-')}'),
        Text('map((v) => v * 2) → ${mapped.join('-')}'),
        Text('take(2) → ${firstTwo.join('-')} / skip(1) → ${skipped.join('-')}'),
        Text('firstWhere(> 5, orElse: -1) → $found'),
        const SizedBox(height: 8),

        Text('elementAt(1) → $atOne'),
        Text('sublist(1, 3) → ${sub.join('-')}'),
        Text('fillRange(0, 2, 7) → ${filled.join('-')}'),
        Text('asMap()[1] → ${map[1]}'),
        Text('length = 4 → $growableText'),
        Text('bucket.nums.sort() → ${bucket.nums.join('-')}'),
      ],
    );
  }
}
