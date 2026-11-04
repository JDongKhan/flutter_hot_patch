import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import '../../model/counter_vm.dart';

/// 泛型 demo（「基础语法 · 列表」页点击进入）：类泛型 / 方法泛型。
///
/// Dart 泛型在编译到 JS 时**擦除**（与 dart2js 一致）：类型实参不参与运行结构，
/// 只以 `typeArguments: ['T', ...]` 元信息随**构造 props**或**调用尾参对象**下发，
/// 谁需要谁读（provider 用它做类型键控的作用域、GlobalKey 用它决定 currentState
/// 的代理类），翻译层不按类名 / 方法名做任何判断。
///
/// 本页验证两类形态：
///   - 类泛型：`GenericBox<T>` / `Pair<K, V>` 的构造、字段、方法调用；单 / 多类型
///     实参都按位置顺序完整保留（旧实现只留第一个）。
///   - 方法泛型：`context.watch<T>()` / `context.read<T>()` 是零位置实参的泛型
///     方法，T 并入尾参对象，运行时按类型名沿父级链定位最近作用域。
///
/// 页面上原生与 JS 热更的结果应当一致——擦除不改变行为，类型实参只是元信息。

// ---------------------------------------------------------------------------
// 类泛型：单类型参数 / 多类型参数
// ---------------------------------------------------------------------------

/// 单类型参数的泛型类：构造、字段、方法都由 T 约束，但运行行为由**值**决定。
class GenericBox<T> {
  GenericBox(this.value, {this.label = 'box'});

  final T value;
  final String label;

  String describe() => '$label: $value';
}

/// 多类型参数的泛型类：验证 `typeArguments` 按位置顺序保留两个类型名。
class Pair<K, V> {
  Pair(this.key, this.value);

  final K key;
  final V value;

  String describe() => '$key → $value';
}

// ---------------------------------------------------------------------------
// 页面
// ---------------------------------------------------------------------------

@PatchEntry('GenericDetail')
class GenericDetail extends StatefulWidget {
  const GenericDetail({super.key});

  @override
  State<GenericDetail> createState() => _GenericDetailState();
}

class _GenericDetailState extends State<GenericDetail> {
  /// `context.read<T>()` 取到的快照（read 不订阅，不触发重建）。
  int _readCount = 0;

  void _snapshot(CounterVm model) {
    setState(() => _readCount = model.count);
  }

  @override
  Widget build(BuildContext context) {
    // 类泛型：`GenericBox<String>` / `GenericBox<int>` 是同一个 JS 类，
    // 类型实参以 `typeArguments: ['String']` / `['int']` 随构造下发。
    final stringBox = GenericBox<String>('Dart 泛型是编译期事实', label: 'string box');
    final intBox = GenericBox<int>(42, label: 'int box');
    // 多类型实参：`typeArguments: ['String', 'int']`。
    final pair = Pair<String, int>('answer', 42);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '泛型：类泛型 / 方法泛型',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Dart 泛型在 JS 侧擦除：<T> 只作为 typeArguments 元信息下发，不占位置参数。',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),

        const Text('类泛型', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('GenericBox<String> → ${stringBox.describe()}'),
        Text('GenericBox<int> → ${intBox.describe()}'),
        Text('Pair<String, int> → ${pair.describe()}'),
        const SizedBox(height: 6),
        const Text(
          "产物形态：new GenericBox({value: …, typeArguments: ['String']})；"
          "new Pair({key: …, value: …, typeArguments: ['String', 'int']})",
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),

        const SizedBox(height: 16),
        const Text('方法泛型', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          'context.watch<T>() / context.read<T>()：零位置实参的泛型方法，'
          'T 并入调用尾参对象，运行时按类型名定位作用域。',
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 8),
        ChangeNotifierProvider<CounterVm>(
          create: (_) => CounterVm(),
          child: Builder(
            builder: (context) {
              // 方法泛型 + 订阅：T 以 {typeArguments: ['CounterVm']} 下发。
              final model = context.watch<CounterVm>();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'context.watch<CounterVm>() → count = ${model.count}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(onPressed: model.inc, child: const Text('+1')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        // read：仅取实例，不订阅；事件作用域里 context 形参仍可用。
                        onPressed: () => _snapshot(context.read<CounterVm>()),
                        child: const Text('read 快照'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('context.read<CounterVm>() 快照 = $_readCount'),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
