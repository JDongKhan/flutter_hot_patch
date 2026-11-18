import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

/// 异步归属验证：定时创建 GlobalKey（业务常见的「回调里 new 对象」写法）。
///
/// 覆盖点：`Timer` 在 `initState` 创建时会捕获当前组件归属；回调执行时恢复该
/// 归属，所以回调里 `new GlobalKey()` 归本组件，页面退出随实例释放——不再像
/// 以前那样退化成永不释放的 `global` 句柄。
///
/// 预期日志（退出本页后）：
///
/// ```
/// leak-check LeakDemoCard（jsui_N）: clean
/// ```
///
/// 若仍出现「多余（JS）：js:key/Global#…（scope: global）」，说明异步归属
/// 继承出现回归。
@PatchEntry('LeakDemoCard')
class LeakDemoCard extends StatefulWidget {
  const LeakDemoCard({super.key});

  @override
  State<LeakDemoCard> createState() => _LeakDemoCardState();
}

class _LeakDemoCardState extends State<LeakDemoCard> {
  /// 模拟业务把 Key 存进局部缓存（生命周期跟着页面走）。
  final List<GlobalKey> _leakedKeys = <GlobalKey>[];

  Timer? _timer;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    // 每 300ms 创建一个 GlobalKey 并持有，永不释放。
    _timer = Timer.periodic(const Duration(milliseconds: 300), _leakOne);
  }

  void _leakOne(Timer timer) {
    _leakedKeys.add(GlobalKey());
    // 定时器已取消，但排队的回调可能在卸载后到达：只更新存活实例。
    if (!mounted) return;
    setState(() => _count = _leakedKeys.length);
  }

  @override
  void dispose() {
    // 定时器停掉；回调里已创建的 GlobalKey 由异步归属随实例一并释放（无需业务手动清）。
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '验证异步归属 · Timer 里 new GlobalKey()',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '本页已创建：$_count 个 GlobalKey',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              '每 300ms 在 Timer 回调里 new GlobalKey() 并持有。回调创建时捕获了本组件的归属，'
              '退出本页应随实例释放；左侧原生版同样随 State 回收。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '退出后看右侧日志：应为 leak-check … clean；若出现「多余（JS）：js:key/Global#…」即回归。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
