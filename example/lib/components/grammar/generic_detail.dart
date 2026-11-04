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

/// 单类型参数的泛型类，**真正使用 T**：`T` 在方法体里是类型值（`T == String`），
/// 运行时从实例保存的 `typeArguments` 元信息里读类型名，按类型转换 `raw`。
///
/// 产物形态：`new TypeCodec({typeArguments: {T: 'String'}})`；方法体里的 `T`
/// 译成 `this.__ta["T"]`，`T == String` 译成 `this.__ta["T"] == "String"`，
/// `as T` 擦除（类型断言在 JS 侧无运行时语义）。
class TypeCodec<T> {
  const TypeCodec();

  T parse(String raw) {
    if (T == String) {
      return raw as T;
    }
    if (T == int) {
      return int.tryParse(raw) as T;
    }
    if (T == double) {
      return double.tryParse(raw) as T;
    }
    if (T == num) {
      return num.tryParse(raw) as T;
    }
    throw ArgumentError('不支持的泛型类型');
  }

  String getType() {
    return T.toString();
  }

  String getEType<E> () {
    return E.toString();
  }
}

/// 多类型参数的泛型类：验证 `typeArguments` 的 key 是声明侧的 `K` / `V`。
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
    // 类泛型 + 真正使用 T：同一个 `TypeCodec` 类，靠构造时的泛型实参决定转换逻辑。
    const stringCodec = TypeCodec<String>();
    const intCodec = TypeCodec<int>();
    const doubleCodec = TypeCodec<double>();
    // 多类型实参：`typeArguments: {K: 'String', V: 'int'}`。
    final pair = Pair<String, int>('answer', 42);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('泛型：类泛型 / 方法泛型', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Dart 泛型在 JS 侧擦除：<T> 只作为 typeArguments 元信息下发，不占位置参数。',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),

        const Text('类泛型', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('TypeCodec<String>().parse("123") → ${stringCodec.parse('123')}'),
        Text('TypeCodec<int>().parse("42") → ${intCodec.parse('42')}'),
        Text('TypeCodec<double>().parse("3.14") → ${doubleCodec.parse('3.14')}'),
        Text('Pair<String, int> → ${pair.describe()}'),

        Text('stringCodec.getType() → ${stringCodec.getType()}'),
        Text('intCodec.getType() → ${intCodec.getType()}'),
        Text('doubleCodec.getType() → ${doubleCodec.getType()}'),

        Text('stringCodec.getEType() → ${stringCodec.getEType<String>()}'),
        Text('intCodec.getEType() → ${intCodec.getEType<int>()}'),
        Text('doubleCodec.getEType() → ${doubleCodec.getEType<double>()}'),

        const SizedBox(height: 6),
        const Text(
          '产物形态：new TypeCodec({typeArguments: {T: "String"}})；'
          '方法体 T → this.__ta["T"]，T == String → this.__ta["T"] == "String"。',
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
              // 方法泛型 + 订阅：T 并入调用尾参对象；实例方法拿不到声明参数名时
              // 元信息 key 用位置序号（消费方按第一个值取，与写法无关）。
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
