import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// Visibility / Offstage 演示：两种「隐藏」语义的差别。
///
/// 单组件 demo：只返回组件本身（不带 Scaffold），由展示页与 JS 热更版对比。
///
/// - `Visibility`：可见性开关，`maintain*` 决定隐藏时是否**仍占位**、是否
///   保留 State / 动画 / 语义 / 命中测试，`replacement` 是隐藏时顶替的子树；
/// - `Offstage`：`offstage: true` 时**彻底退出**布局与绘制（不占位），但
///   State 与 Ticker 仍在跑（与 Visibility 的 maintainState 组合语义不同）。
@PatchEntry('VisibilityDetail')
class VisibilityDetail extends StatefulWidget {
  const VisibilityDetail({super.key});

  @override
  State<VisibilityDetail> createState() => _VisibilityDetailState();
}

class _VisibilityDetailState extends State<VisibilityDetail> {
  bool _visible = true;

  /// 隐藏时是否仍占原尺寸（Opacity 0 + 保留布局）。
  bool _maintainSize = false;

  /// 隐藏时是否保留语义（屏幕阅读器仍可读）。
  bool _maintainSemantics = false;

  /// 隐藏时是否仍可点击。
  bool _maintainInteractivity = false;

  bool _offstage = false;

  /// 藏起来的那块内部的计数器：用来验证「隐藏后仍可点击 / State 未丢」。
  int _taps = 0;

  void _show() {
    setState(() {
      _visible = true;
      _maintainSize = false;
      _maintainSemantics = false;
      _maintainInteractivity = false;
    });
  }

  /// 隐藏且**不占位**：不留 State / 动画 / 尺寸。
  void _hideTight() {
    setState(() {
      _visible = false;
      _maintainSize = false;
      _maintainSemantics = false;
      _maintainInteractivity = false;
    });
  }

  /// 隐藏但**占位**：maintainSize 隐含 maintainAnimation + maintainState。
  void _hideKeepSpace() {
    setState(() {
      _visible = false;
      _maintainSize = true;
      _maintainSemantics = false;
      _maintainInteractivity = false;
    });
  }

  /// 隐藏、占位、且仍可点击（maintainInteractivity 隐含 maintainSize）。
  void _hideKeepTap() {
    setState(() {
      _visible = false;
      _maintainSize = true;
      _maintainSemantics = true;
      _maintainInteractivity = true;
    });
  }

  void _toggleOffstage() {
    setState(() => _offstage = !_offstage);
  }

  void _onTap() {
    setState(() => _taps++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Visibility ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Visibility（visible=$_visible，maintainSize=$_maintainSize）',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Visibility(
                visible: _visible,
                maintainState: _maintainSize,
                maintainAnimation: _maintainSize,
                maintainSize: _maintainSize,
                maintainSemantics: _maintainSemantics,
                maintainInteractivity: _maintainInteractivity,
                replacement: const Center(
                  child: Text('replacement 顶替显示', style: TextStyle(fontSize: 12)),
                ),
                child: Container(
                  height: 64,
                  color: Colors.teal.shade100,
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: _onTap,
                    child: Text('点我（已点 $_taps 次）'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '↓ 下面这行用来观察是否仍占位',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(onPressed: _show, child: const Text('显示')),
                  const SizedBox(width: 6),
                  OutlinedButton(onPressed: _hideTight, child: const Text('隐藏·不占位')),
                  const SizedBox(width: 6),
                  OutlinedButton(onPressed: _hideKeepSpace, child: const Text('隐藏·占位')),
                  const SizedBox(width: 6),
                  OutlinedButton(onPressed: _hideKeepTap, child: const Text('隐藏·仍可点')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Offstage ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Offstage（offstage=$_offstage）',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Offstage(
                offstage: _offstage,
                child: Container(
                  height: 56,
                  color: Colors.orange.shade100,
                  alignment: Alignment.center,
                  child: Text('Offstage 内容（点我 $_taps 次）'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '↑ offstage 时不占位、不绘制、不响应点击（State 仍保留）',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _toggleOffstage,
                    child: Text(_offstage ? '关闭 offstage' : '打开 offstage'),
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
