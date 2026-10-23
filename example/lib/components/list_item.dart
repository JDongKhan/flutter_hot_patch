import 'package:flutter/material.dart';

/// @author jd

/// 验证用调色板。放在**顶层常量**：生成器会把常量颜色表译成产物里的色值数组，
/// `TextStyle(color: _listItemPalette[...])` 可直接索引（局部 const 表不支持）。
const List<Color> _listItemPalette = [
  Colors.blueGrey,
  Colors.teal,
  Colors.indigo,
  Colors.deepOrange,
  Colors.purple,
  Colors.brown,
];

class CommonListItem extends StatefulWidget {
  const CommonListItem({super.key, required this.index, this.salt = 0});

  final int index;

  /// 父级「真实变化」的验证信号：ScrollDetail 里点「列表换色」时自增。
  /// 滚动不会改它——所以滚动期间 item 的颜色不应变化。
  final int salt;

  @override
  State<CommonListItem> createState() => _CommonListItemState();
}

class _CommonListItemState extends State<CommonListItem> {
  /// 本实例被父级更新的次数。滚动过程中若短路生效，这个值不应增长。
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    print("listItem initState - ${widget.index}");
  }

  @override
  void didUpdateWidget(covariant CommonListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCount += 1;
    print("listItem didUpdateWidget- ${widget.index}");
  }

  @override
  Widget build(BuildContext context) {
    // 颜色只由「真实更新次数」和父级 salt 决定：滚动时两者都不变 →
    // 颜色不动；点「列表换色」/ item 被重新构建 → 颜色才变。
    return Text(
      'builder item ${widget.index}',
      style: TextStyle(
        color: _listItemPalette[(widget.salt + _updateCount) % _listItemPalette.length],
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
