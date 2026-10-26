import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 显式动画演示（`AnimationController` + `AnimatedBuilder` / `*Transition`）。
///
/// 显式动画的**真实控制器带 Ticker 跑在宿主侧**（JS 侧是镜像 + 句柄）：
///   - `forward / reverse / repeat / stop / reset` 由 JS 经句柄调到宿主控制器；
///   - 宿主每帧把 value 回传到 JS 镜像 → `AnimatedBuilder` 的监听触发局部重建；
///   - `*Transition` 直接消费 `Animation` 句柄，逐帧插值全在宿主完成。
///
/// `CurvedAnimation` 刻意**内联在 props 里**而不存字段：字段类型 `Animation<T>`
/// 是SDK 接口、生成器不建同名 JS 类；内联构造只要求 `CurvedAnimation` 值对象
/// （宿主按 `{__handle, __curve}` 还原，同控制器同曲线复用一个派生动画）。
@PatchEntry('ExplicitAnimationDetail')
class ExplicitAnimationDetail extends StatefulWidget {
  const ExplicitAnimationDetail({super.key});

  @override
  State<ExplicitAnimationDetail> createState() =>
      _ExplicitAnimationDetailState();
}

class _ExplicitAnimationDetailState extends State<ExplicitAnimationDetail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'AnimationController.value 驱动 AnimatedBuilder',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              children: [
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _controller.value < 0.5
                        ? Colors.teal
                        : Colors.deepPurple,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _controller.value < 0.5 ? '前半程' : '后半程',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                LinearProgressIndicator(value: _controller.value),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => _controller.forward(),
                child: const Text('forward'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => _controller.reverse(),
                child: const Text('reverse'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => _controller.repeat(reverse: true),
                child: const Text('repeat'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => _controller.stop(),
                child: const Text('stop'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => _controller.reset(),
                child: const Text('reset'),
              ),
            ),
          ],
        ),
        const Divider(),
        const Text(
          '*Transition · 由 CurvedAnimation 驱动',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ),
              child: Center(
                child: Container(
                  width: 120,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Fade + Scale',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 90,
          child: RotationTransition(
            turns: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
            child: Center(
              child: Container(
                width: 130,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Rotation',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
