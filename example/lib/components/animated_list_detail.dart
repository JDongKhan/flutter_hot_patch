import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// AnimatedList 演示：列表项的插入 / 移除带有补间，而不是整体重建。
///
/// 一比一翻译说明：
///   - `AnimatedList(itemBuilder:, initialItemCount:)` 的 `itemBuilder` 是 tear-off，
///     生成器按 builder 协议把它展开成有序子结点（与 `ListView.builder` 同一机制）；
///   - `GlobalKey.currentState.insertItem / removeItem` 在 JS 侧是**句柄 + 同名
///     方法**，签名与 Flutter 完全一致（`Duration` 按值下发），宿主把
///     「GlobalKey → AnimatedListState」的真实语义补全；
///   - `itemBuilder` 未消费 `animation`（与 Flutter 官方示例里「不写过渡」一致）：
///     增删瞬间生效。JS 的 builder 拿不到 Animation 对象，宿主也不额外补插值，
///     两边口径完全相同。
@PatchEntry('AnimatedListDetail')
class AnimatedListDetail extends StatefulWidget {
  const AnimatedListDetail({super.key});

  @override
  State<AnimatedListDetail> createState() => _AnimatedListDetailState();
}

class _AnimatedListDetailState extends State<AnimatedListDetail> {
  /// GlobalKey 跨帧稳定（JS 侧是句柄，宿主持真实实例）。
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  int _seq = 3;
  final List<String> _items = ['条目 1', '条目 2', '条目 3'];

  static const Duration _insertDuration = Duration(milliseconds: 350);
  static const Duration _removeDuration = Duration(milliseconds: 300);

  Widget _itemBuilder(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) {
    if (index < 0 || index >= _items.length) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.indigo.shade50,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 12,
          backgroundColor: Colors.indigo,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
        title: Text(_items[index]),
      ),
    );
  }

  /// 在末尾插入：`insertItem(index, {duration})`。
  void _insert() {
    final index = _items.length;
    setState(() {
      _items.add('条目 ${++_seq}');
    });
    final state = _listKey.currentState;
    state?.insertItem(index, duration: _insertDuration);
  }

  /// 移除第一项：`removeItem(index, builder, {duration})`。
  void _removeFirst() {
    if (_items.isEmpty) return;
    final removed = _items.removeAt(0);
    setState(() {});
    final state = _listKey.currentState;
    state?.removeItem(
      0,
      (context, animation) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.red.shade50,
        child: ListTile(dense: true, title: Text(removed)),
      ),
      duration: _removeDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'AnimatedList · 增删补间（GlobalKey.currentState）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 260,
          child: AnimatedList(
            key: _listKey,
            initialItemCount: _items.length,
            itemBuilder: _itemBuilder,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _insert,
                child: const Text('插入末尾（350ms）'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: _removeFirst,
                child: const Text('移除第一项（300ms）'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
