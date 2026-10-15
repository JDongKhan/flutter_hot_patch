import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// ReorderableListView（长按拖拽重排）demo。
///
/// 重点验证**多参事件**链路：`onReorder: (oldIndex, newIndex)` 是双参回调，
/// 生成器把回调表达式绑成句柄写进 `props.event`，宿主侧用 `on2<int,int>`
/// 还原，经统一「参数数组」ABI 回传 → JS 侧 `__bind` 的 wrapper 用 apply
/// 摊开成两个位置实参 → `_onReorder(oldIndex, newIndex)`。
///
/// 重排算法用 `removeAt + insert`（生成器翻译为 JS 数组的
/// `splice(i,1)[0]` 与 `splice(i,0,v)`）；`add` 翻译为 `push`。
@PatchEntry('ReorderListDemo')
class ReorderListDemo extends StatefulWidget {
  const ReorderListDemo({super.key});

  @override
  State<ReorderListDemo> createState() => _ReorderListDemoState();
}

class _ReorderListDemoState extends State<ReorderListDemo> {
  final List<String> _items = ['北京', '上海', '广州', '深圳', '杭州', '成都'];

  /// 双参事件：拖拽结束后 Flutter 回传 (oldIndex, newIndex)。
  void _onReorder(int oldIndex, int newIndex) {
    print("$oldIndex - $newIndex");
    setState(() {
      final item = _items.removeAt(oldIndex);
      // Flutter 语义：向下拖时 newIndex 是「插入到目标项之前」的下标，
      // 需先扣掉被移走的自己那一格。
      final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
      _items.insert(target, item);
    });
  }

  void _add() {
    setState(() {
      _items.add('城市 ${_items.length + 1}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '长按拖拽调整顺序（onReorder 双参事件）',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              ElevatedButton(onPressed: _add, child: const Text('添加')),
            ],
          ),
        ),
        // 固定高度：本组件可被放进任意父容器（如 demo 的 Column 对比布局），
        // 不能依赖父级给出有界高度，故这里自带一个高度盒。
        SizedBox(
          height: 320,
          child: ReorderableListView(
            onReorder: _onReorder,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final item in _items)
                Card(
                  key: ValueKey(item),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle),
                    title: Text(item),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
