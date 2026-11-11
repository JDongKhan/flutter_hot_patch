import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 泄漏演示：定时创建「永不释放」的 GlobalKey。
///
/// JS 侧关键点：`GlobalKey()` 在 **Timer 回调**里创建——既不在组件构造期、也不在
/// build / 事件执行期，句柄无法归属组件实例（scope 退化为 `global`），页面销毁
/// 时也不会被回收。退出本页后，右侧日志会出现：
///
/// ```
/// leak-check LeakDemoCard（jsui_N）: N 项残留
///   多余（JS）：js:key/Global#…（kind: key/Global, scope: global, obj: GlobalKey）
/// ```
///
/// 左侧原生版没有句柄表这个概念，`dispose` 后列表随 State 一起回收，不会告警——
/// 这正是「JS 侧资源必须显式释放」的对照。
@PatchEntry('LeakDemoCard')
class LeakDemoCard extends StatefulWidget {
  const LeakDemoCard({super.key});

  @override
  State<LeakDemoCard> createState() => _LeakDemoCardState();
}

class _LeakDemoCardState extends State<LeakDemoCard> {
  /// 故意持有：模拟「业务把 Key 存进缓存 / 单例」的写法。
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
    // 只停定时器；已经创建的 GlobalKey 仍然留在 JS 句柄表里（这正是泄漏点）。
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
              '泄漏演示 · GlobalKey 未释放',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '本页已创建：$_count 个 GlobalKey',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              '每 300ms 在 Timer 回调里 new GlobalKey() 并持有。JS 侧句柄 scope=global，'
              '退出本页后不会释放；左侧原生版随 State 回收，不会告警。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '退出后看右侧日志的 leak-check：会出现「多余（JS）：js:key/Global#…」。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
