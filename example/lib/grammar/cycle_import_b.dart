import 'package:flutter/material.dart';

import 'cycle_import_a.dart';

/// 循环 import demo · B 侧：与 A 互 import，只在方法体里调用 [CycleImportA]。
///
/// 加载顺序 A → B → A 时，B 先求值、A 的命名绑定还是 `undefined`；
/// A 求值完成后 `__flushImportFixups` 回填，B 的方法在渲染时已能正常使用 A。
class CycleImportB {
  const CycleImportB._();

  static String name() => '模块 B';

  static String callA() => CycleImportA.name();

  static Widget card() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'B · cycle_import_b.js',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('B.callA() →'),
            Text(callA(), style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
