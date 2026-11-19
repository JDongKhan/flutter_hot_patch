import 'package:flutter/material.dart';

import 'cycle_import_b.dart';

/// 循环 import demo · A 侧：模块级 `import 'cycle_import_b.dart'`，
/// B 侧同样 `import 'cycle_import_a.dart'`，产物形成 A ↔ B 的环。
///
/// 只允许**延迟引用**：对方类只出现在方法体内（不能用 `extends` / 静态字段 /
/// 顶层 `new`），运行期靠「占位导出 + 命名绑定回填」正常加载。
class CycleImportA {
  const CycleImportA._();

  static String name() => '模块 A';

  /// 真正跨模块的引用发生在方法体里：加载期 B 的绑定可能还未回填，
  /// 调用发生在页面渲染时，此时已经就绪。
  static String callB() => CycleImportB.name();

  static Widget card() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A · cycle_import_a.js',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('A.callB() →'),
            Text(callB(), style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
