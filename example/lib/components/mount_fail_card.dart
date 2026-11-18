import 'package:flutter/widgets.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

/// 挂载失败回滚 demo（仅用于验证生命周期，不参与常规页面）。
///
/// `initState` 里先注册一个持久帧回调（归属当前页面根），再抛错：
/// 整个根在 `__openRoot` 阶段失败 → `__abortRoot` 回滚，并向各生命周期实现
/// 广播 `onRootClose`，持久帧回调随根一起丢弃；页面停在 boot 失败态，返回列表
/// 后 `leak-check` 应为 clean。
@PatchEntry('MountFailCard')
class MountFailCard extends StatefulWidget {
  const MountFailCard({super.key});

  @override
  State<MountFailCard> createState() => _MountFailCardState();
}

class _MountFailCardState extends State<MountFailCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPersistentFrameCallback((_) {});
    throw StateError('mount fail demo（预期错误：验证挂载失败回滚）');
  }

  @override
  Widget build(BuildContext context) => const Text('unreachable');
}
