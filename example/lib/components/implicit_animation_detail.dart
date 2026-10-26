import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 隐式动画演示（`Animated*` 家族）。
///
/// 隐式动画**全部由宿主插值**：Dart 侧只改一个目标值（宽高 / 透明度 / 缩放 /
/// 旋转 / 位移），Flutter 的 `AnimatedFoo` 内部用真实 `AnimationController`
/// 从旧值补间到新值。JS 热更侧只下发 `duration` / `curve` / 目标值，逐帧插值
/// 不过桥，所以这里没有任何显式 controller。
///
/// 与 JS 侧约定的值形态：
///   - `Duration(milliseconds: n)` → JS `Duration` 值 → 宿主 `durationFromJson`；
///   - `Curves.easeInOut` → 曲线成员名字符串 → 宿主 `curveFromJson`；
///   - `Offset(x, y)` → `{dx, dy}` JSON 值 → 宿主 `offsetFromJson`。
@PatchEntry('ImplicitAnimationDetail')
class ImplicitAnimationDetail extends StatefulWidget {
  const ImplicitAnimationDetail({super.key});

  @override
  State<ImplicitAnimationDetail> createState() =>
      _ImplicitAnimationDetailState();
}

class _ImplicitAnimationDetailState extends State<ImplicitAnimationDetail> {
  bool _big = false;
  bool _visible = true;
  bool _moved = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'AnimatedContainer · 尺寸 / 颜色 / 圆角',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: _big ? 220 : 110,
            height: _big ? 120 : 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _big ? Colors.deepPurple : Colors.teal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _big ? 'BIG' : 'small',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => _big = !_big),
          child: Text(_big ? '收缩到 small' : '放大到 BIG'),
        ),
        const Divider(),
        const Text(
          'AnimatedOpacity · AnimatedScale · AnimatedRotation · AnimatedSlide',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.2,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '透明度',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            AnimatedScale(
              scale: _big ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '缩放',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            AnimatedRotation(
              turns: _moved ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '旋转',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            AnimatedSlide(
              offset: _moved ? const Offset(0.25, 0) : const Offset(0, 0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.brown,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '位移',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _visible = !_visible),
                child: Text(_visible ? '暗下来' : '亮起来'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _moved = !_moved),
                child: Text(_moved ? '回到原位' : '旋转 + 位移'),
              ),
            ),
          ],
        ),
        const Divider(),
        const Text(
          'AnimatedCrossFade · 两子树交叉淡入淡出',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 450),
          crossFadeState:
              _visible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstCurve: Curves.easeOut,
          secondCurve: Curves.easeIn,
          alignment: Alignment.center,
          firstChild: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'A',
              style: TextStyle(color: Colors.white),
            ),
          ),
          secondChild: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'B',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _visible = !_visible),
          child: Text(_visible ? '切到 B' : '切回 A'),
        ),
      ],
    );
  }
}
