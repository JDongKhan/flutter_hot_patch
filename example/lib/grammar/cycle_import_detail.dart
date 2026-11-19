import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

import 'cycle_import_a.dart';
import 'cycle_import_b.dart';

/// 循环 import demo：`cycle_import_a.dart` ↔ `cycle_import_b.dart` 模块级互相
/// import，两侧都只在方法体里使用对方。
///
/// 加载顺序 `detail → A → B → A` 命中环：运行期只打印一条
/// 「模块循环 import：… 已按占位导出继续加载」告警，然后通过
/// `__onImportReady` / `__flushImportFixups` 回填绑定，页面照常渲染。
/// 模块顶层 `extends` / 静态字段 / `new` 使用环对面会失败（与原生 ESM 一致）。
@PatchEntry('CycleImportDetail')
class CycleImportDetail extends StatelessWidget {
  const CycleImportDetail({super.key});

  @override
  Widget build(BuildContext context) {
    // 详情页外层已经是 SingleChildScrollView（见 WidgetDetailPage），这里用
    // Column；再套 ListView 会拿到无界高度，触发 viewport 断言。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '循环 import · A ↔ B',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '两个模块级互相 import，两侧都只在方法体里调用对方。',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        const Text(
          '加载时 A → B → A 形成环：告警一次并继续加载，B 的方法在 A 求值完成后'
          '通过绑定回填拿到 A。',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        CycleImportA.card(),
        const SizedBox(height: 8),
        CycleImportB.card(),
        const SizedBox(height: 12),
        const Text(
          '两张卡片分别调用 A.callB() / B.callA()，渲染时就已回填完成。',
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }
}
