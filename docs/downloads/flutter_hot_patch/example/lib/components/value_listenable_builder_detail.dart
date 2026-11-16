import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// ValueListenableBuilder 演示：订阅 `ValueNotifier`，值变化时**只重建该子树**。
///
/// 单组件 demo：只返回组件本身（不带 Scaffold），由展示页与 JS 热更版对比。
///
/// 一比一翻译说明：
///   - `valueListenable` 是 ValueNotifier 状态字段，JS 侧同构实现
///     （订阅 → 局部 setState，`value` setter 用 `===` 守卫）；
///   - `builder(context, value, child)` 的 `value` 取订阅时的最新值，`child`
///     是原样透传的插槽子树（值变化不重建 `child`）；
///   - 切换订阅对象（`_useA`）走 `didUpdateWidget` 重订阅，不必重建组件。
@PatchEntry('ValueListenableBuilderDetail')
class ValueListenableBuilderDetail extends StatefulWidget {
  const ValueListenableBuilderDetail({super.key});

  @override
  State<ValueListenableBuilderDetail> createState() =>
      _ValueListenableBuilderDetailState();
}

class _ValueListenableBuilderDetailState
    extends State<ValueListenableBuilderDetail> {
  final ValueNotifier<int> _a = ValueNotifier<int>(0);
  final ValueNotifier<int> _b = ValueNotifier<int>(100);

  /// 当前订阅哪一个 notifier（演示 didUpdateWidget 重订阅）。
  bool _useA = true;

  /// builder 被执行了多少次（值不变时不会增加，可直观看到「不重建」）。
  int _builds = 0;

  ValueNotifier<int> get _active => _useA ? _a : _b;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _inc() {
    final n = _active;
    n.value = n.value + 1;
  }

  void _dec() {
    final n = _active;
    n.value = n.value - 1;
  }

  /// 赋同一个值：ValueNotifier 的 `===` 守卫会直接 return，不 notify。
  void _same() {
    final n = _active;
    n.value = n.value;
  }

  void _toggle() {
    setState(() => _useA = !_useA);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _useA ? '订阅：_a（初值 0）' : '订阅：_b（初值 100）',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: _active,
            builder: (context, value, child) {
              _builds++;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$value',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'builder 已执行 $_builds 次',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  child ?? const SizedBox.shrink(),
                ],
              );
            },
            child: const Text(
              'child 插槽：值变化时不重建这段子树',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(onPressed: _dec, child: const Text('-1')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _inc, child: const Text('+1')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _same, child: const Text('赋相同值')),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              OutlinedButton(onPressed: _toggle, child: const Text('切换订阅对象')),
            ],
          ),
        ],
      ),
    );
  }
}
