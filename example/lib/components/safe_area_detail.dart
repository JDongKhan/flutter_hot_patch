import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// SafeArea 演示：按系统安全区（刘海 / 状态栏 / 手势条）自动加内边距。
///
/// macOS 窗口的 `MediaQuery.padding` 全为 0，所以 SafeArea 默认不产生可见间距；
/// 这里用 `minimum`（每边取 `max(系统 padding, minimum)`）造出可见留白，用来
/// 验证 SafeArea 确实生效。
///
/// 一比一翻译说明：
///   - `left/top/right/bottom` 是开关（false 时该边归零）；
///   - `minimum` 是 `EdgeInsets` 值对象，产物下发 `{left, top, right, bottom}`；
///   - `maintainBottomViewPadding` 控制底部用 `padding.bottom` 还是
///     `viewPadding.bottom`（手势条区域，键盘弹出时不跟随变化）；
///   - 下方同时显示 `MediaQuery.paddingOf(context)` 的实时数值。
@PatchEntry('SafeAreaDetail')
class SafeAreaDetail extends StatefulWidget {
  const SafeAreaDetail({super.key});

  @override
  State<SafeAreaDetail> createState() => _SafeAreaDetailState();
}

class _SafeAreaDetailState extends State<SafeAreaDetail> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SafeArea', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '系统安全区 padding 全为 0 时 SafeArea 默认无可见间距；用 minimum 强制留白即可验证生效',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('minimum 留白', style: TextStyle(fontSize: 12)),
            Switch(
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 外层灰底：露出的灰色就是 SafeArea 加出来的间距。
        Container(
          color: Colors.grey.shade300,
          child: SafeArea(
            // 四边开关决定是否采用系统 padding（本机 padding 全 0，故开关无可见差异，
            // 但 minimum 恒生效：每边取 max(系统 padding, minimum)）。
            left: true,
            top: true,
            right: true,
            bottom: true,
            minimum: _enabled
                ? EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 12)
                : EdgeInsets.zero,
            // 键盘弹出时底部不跟随 padding 变化（改用固定 viewPadding）。
            maintainBottomViewPadding: false,
            child: Container(
              height: 56,
              color: Colors.teal,
              alignment: Alignment.center,
              child: const Text(
                'SafeArea 内区域',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'padding: L${padding.left.toStringAsFixed(0)} T${padding.top.toStringAsFixed(0)} '
                'R${padding.right.toStringAsFixed(0)} B${padding.bottom.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                _enabled ? 'minimum: 每边 12（灰色即为留白）' : 'minimum: 0（本机系统 padding 为 0，故无留白）',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
