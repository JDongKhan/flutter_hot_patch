import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// TweenAnimationBuilder 演示：**隐式动画**（tween 目标变化时自动过渡）。
///
/// 单组件 demo：只返回组件本身（不带 Scaffold），由展示页与 JS 热更版对比。
///
/// 一比一翻译说明：
///   - 首帧不播动画，直接显示 `tween.begin`；
///   - 改 `tween.end` 时从**当前显示值**续到新目标（中途改目标不跳变）；
///   - 每帧按 `curve` 弯曲后用 `tween.lerp` 求值；`onEnd` 在进度到 1 时回调一次。
@PatchEntry('TweenAnimationBuilderDetail')
class TweenAnimationBuilderDetail extends StatefulWidget {
  const TweenAnimationBuilderDetail({super.key});

  @override
  State<TweenAnimationBuilderDetail> createState() =>
      _TweenAnimationBuilderDetailState();
}

class _TweenAnimationBuilderDetailState
    extends State<TweenAnimationBuilderDetail> {
  /// 动画目标（0 → 满格 1）。
  double _target = 1;

  /// 动画时长（毫秒）。
  int _ms = 800;

  /// 是否用 easeInOut（否则 linear）。
  bool _ease = true;

  /// `onEnd` 触发次数。
  int _ended = 0;

  /// 动画到目标后回调（`onEnd` 是一次性回调，非 builder）。
  void _onEnd() {
    setState(() => _ended++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tween<double>(begin: 0, end: _target) → 进度条',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: _target),
                duration: Duration(milliseconds: _ms),
                curve: _ease ? Curves.easeInOut : Curves.linear,
                onEnd: _onEnd,
                builder: (context, value, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 22,
                          color: Colors.grey.shade300,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: value,
                            heightFactor: 1,
                            child: Container(color: Colors.indigo),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'value = ${value.toStringAsFixed(3)}'
                        '   ·   onEnd 触发 $_ended 次',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _target = 0),
                    child: const Text('→ 0'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _target = 0.4),
                    child: const Text('→ 0.4'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _target = 1),
                    child: const Text('→ 1'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _ms = 300),
                    child: const Text('300ms'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _ms = 1500),
                    child: const Text('1500ms'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _ease = !_ease),
                    child: Text(_ease ? '曲线：easeInOut' : '曲线：linear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
