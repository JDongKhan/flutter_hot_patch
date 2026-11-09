import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// Map 语法 demo（「基础语法 · 映射」页点击进入）。
///
/// Dart `Map` 字面量在 JS 侧是原生 `Map`（`new Map([[...]])`）：成员由运行时
/// 在 `Map.prototype` 上补齐；`keys` / `values` / `entries` 因 JS 同名成员是
/// 方法，按 `_keys` / `_values` / `_entries` 改写（仅接收者可判定为 Map 时生效）。
/// 下标 `m[k]` / `m[k] = v` 按接收者类型改写成 `__idx` / `__idxSet`，兼容原生
/// Map 与宿主回包的普通对象；自定义类上的同名成员原样保留。

@PatchEntry('MapDetail')
class MapDetail extends StatefulWidget {
  const MapDetail({super.key});

  @override
  State<MapDetail> createState() => _MapDetailState();
}

class _MapDetailState extends State<MapDetail> {
  @override
  Widget build(BuildContext context) {
    final scores = <String, int>{'语文': 88, '数学': 96, '英语': 79};

    // length / keys / values / entries（属性读取 → 运行时自由函数）。
    final count = scores.length;
    final keys = scores.keys.toList();
    final values = scores.values.toList();
    final entries = scores.entries.toList();
    final entryText = entries.map((e) => '${e.key}=${e.value}').join('，');

    // forEach：Dart 回调形参顺序是 (key, value)。
    final visited = <String>[];
    scores.forEach((k, v) => visited.add('$k=$v'));

    // containsKey / containsValue。
    final hasMath = scores.containsKey('数学');
    final hasHundred = scores.containsValue(100);

    // remove：返回被删除的值，键不存在返回 null。
    final removed = Map<String, int>.of(scores);
    final removedEnglish = removed.remove('英语');
    final removedChem = removed.remove('化学');

    // putIfAbsent：存在返回旧值，不存在则计算并写入。
    final cached = Map<String, int>.of(scores);
    final cachedMath = cached.putIfAbsent('数学', () => 0);
    final cachedArt = cached.putIfAbsent('美术', () => 60);

    // update：存在则更新；不存在时走 ifAbsent。
    final updated = Map<String, int>.of(scores);
    final mathPlus = updated.update('数学', (v) => v + 2);
    final artAdded = updated.update('美术', (v) => v, ifAbsent: () => 70);

    // addAll / removeWhere。
    final merged = Map<String, int>.of(scores);
    merged.addAll(<String, int>{'物理': 66, '化学': 54});
    merged.removeWhere((k, v) => v < 80);

    // clear / isEmpty / isNotEmpty。
    final cleared = Map<String, int>.of(scores);
    final sizeBefore = cleared.length;
    cleared.clear();
    final emptyAfter = cleared.isEmpty;
    final nonEmptyBefore = scores.isNotEmpty;

    // 下标读取未命中归一 null；`??` 取缺省；写回；`Map.from` 浅拷贝。
    final math = scores['数学'];
    final missing = scores['化学'] ?? -1;
    scores['物理'] = 66;
    final copied = Map<String, int>.from(scores);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Map · 映射语义',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Map 字面量是原生 JS Map（new Map([[...]])）：成员由运行时在 Map.prototype '
          '补齐，keys / values / entries 改名为 _keys / _values / _entries；下标读写按'
          '接收者类型改写，只对可判定为 Map 的接收者生效。',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),

        Text('length → $count'),
        Text('keys → ${keys.join('/')}'),
        Text('values → ${values.join('/')}'),
        Text('entries → $entryText'),
        Text('forEach → ${visited.join('/')}'),
        const SizedBox(height: 8),

        Text('containsKey(数学) → $hasMath / containsValue(100) → $hasHundred'),
        Text('remove(英语) → ${removedEnglish ?? 'null'}，'
            'remove(化学) → ${removedChem ?? 'null'}'),
        Text('putIfAbsent → 数学=$cachedMath / 美术=$cachedArt'),
        Text('update → 数学=$mathPlus / 美术(ifAbsent)=$artAdded'),
        const SizedBox(height: 8),

        Text('addAll + removeWhere(< 80) → ${merged.keys.join('/')}'),
        Text('clear → $sizeBefore → $emptyAfter（isEmpty）'
            ' / 原 Map isNotEmpty=$nonEmptyBefore'),
        Text('scores[数学]=${math ?? 'null'} / scores[化学]??-1=$missing'),
        Text('copied（Map.from）→ ${copied.keys.join('/')}'),
      ],
    );
  }
}
