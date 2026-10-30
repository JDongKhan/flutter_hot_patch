import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 列表行：状态**只有** `_count` 一个字段——正因如此，key 校准的作用可以直接
/// 量出来：计数跟着「行」还是跟着「位置」。
///
/// label 由父级按当前顺序给出（key 里也是同一个值），这样换序后一眼就能看出
/// 状态到底留在了行上还是位置上了。
@PatchEntry('KeyTile')
class KeyTile extends StatefulWidget {
  const KeyTile({super.key, required this.index, required this.label});

  /// 行在列表里的位置（仅用于展示）。
  final int index;

  /// 行标签（ValueKey 场景下与该行 key 的值同源）。
  final String label;

  @override
  State<KeyTile> createState() => _KeyTileState();
}

class _KeyTileState extends State<KeyTile> {
  int _count = 0;

  void bump() {
    setState(() => _count++);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final caption = '$label · 计数 $_count';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(child: Text(caption, style: const TextStyle(fontSize: 13))),
          TextButton(onPressed: bump, child: const Text('+1')),
        ],
      ),
    );
  }
}
