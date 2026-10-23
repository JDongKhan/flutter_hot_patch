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
  /// 本实例被父级更新的次数。滚动时父级每帧重建，已挂载项会持续 +1（与原生一致）。
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
    print("listItem didUpdateWidget- ${widget.index} -$_updateCount");
  }

  @override
  Widget build(BuildContext context) {
    // 颜色只由「真实数据」决定（下标基色 + 父级 salt），**不含更新次数**：
    //   - 符合预期：滚动不会真实改变 item 内容 → 两边颜色都不变；
    //   - 点「列表换色」→ salt 变 → 两边同时换色（真实更新行为一致）。
    // 文本里的 `uN` 是诊断计数器：本实例被父级更新过几次。
    //   - 滚动时父级每帧重建，已挂载项每帧 +1（原生与 JS 侧语义一致）；
    //   - 滚出缓存被销毁、滚回来是新实例，uN 从 0 重新开始。
    return Text(
      'builder item ${widget.index} · u$_updateCount',
      style: TextStyle(
        color: _listItemPalette[(widget.index + widget.salt) % _listItemPalette.length],
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
