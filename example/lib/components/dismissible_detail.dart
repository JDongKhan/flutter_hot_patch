import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// Dismissible 演示：滑动删除 + 方向确认。
///
/// - 左滑（endToStart）：`confirmDismiss` 放行 → 条目收缩消失，`onDismissed`
///   从列表移除；
/// - 右滑（startToEnd）：`confirmDismiss` 返回 false → 条目弹回原位；
/// - `background` / `secondaryBackground` 分别是左右滑动时露出的底层内容。
///
/// 一比一翻译说明：
///   - `key: ValueKey(item)` 原样下发为结点 key，宿主还原成等值 ValueKey；
///   - `direction: DismissDirection.horizontal`、`confirmDismiss` 里的
///     `DismissDirection.endToStart` 都翻成同名字符串，比较语义不变；
///   - `confirmDismiss` 是 async 方法 → JS 侧返回 Promise，宿主的「异步回程」
///     通道会等它完成后再决定放行（见 dismissible_bridge.dart）。
@PatchEntry('DismissibleDetail')
class DismissibleDetail extends StatefulWidget {
  const DismissibleDetail({super.key});

  @override
  State<DismissibleDetail> createState() => _DismissibleDetailState();
}

class _DismissibleDetailState extends State<DismissibleDetail> {
  List<String> _items = <String>[
    '第一条：左滑删除，右滑弹回',
    '第二条：试试右滑，会被拒绝',
    '第三条：删光后点「重置」',
  ];

  String _last = '还没有条目被删除';

  /// 只放行 endToStart（左滑），其余方向拒绝。
  /// async：验证宿主的异步回程（JS 侧 Promise）。
  Future<bool> _confirm(DismissDirection direction) async {
    return direction == DismissDirection.endToStart;
  }

  void _reset() {
    setState(() {
      _items = <String>[
        '第一条：左滑删除，右滑弹回',
        '第二条：试试右滑，会被拒绝',
        '第三条：删光后点「重置」',
      ];
      _last = '还没有条目被删除';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Dismissible',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          '左滑删除；右滑被 confirmDismiss 拒绝后弹回',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        for (final item in _items)
          Dismissible(
            key: ValueKey<String>(item),
            direction: DismissDirection.horizontal,
            confirmDismiss: _confirm,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.blueGrey,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.block, color: Colors.white),
            ),
            onDismissed: (direction) {
              setState(() {
                _items.remove(item);
                _last = '已删除：$item';
              });
            },
            child: Container(color: Colors.white, child: ListTile(title: Text(item))),
          ),
        const SizedBox(height: 12),
        Text(
          _last,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(onPressed: _reset, child: const Text('重置')),
        ),
      ],
    );
  }
}
