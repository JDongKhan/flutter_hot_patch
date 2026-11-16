import 'dart:async';

import 'package:flutter/material.dart';

/// 引导气泡（OverlayPortal + LayerLink 封装的 demo 组件）。
///
/// 在 [child] 下方锚定一个气泡：[duration] 后淡出并卸载。气泡挂在最近的 Overlay
/// 上（`OverlayPortal`），位置由 `CompositedTransformFollower` 跟随 `child` 的
/// `CompositedTransformTarget` 锚点——滚动 / 布局变化时自动跟着走。
///
/// 与原始设计的差异（受本仓库能力约束）：
///   - 无 `storageKey`（本仓库没有本地存储能力，是否只弹一次由调用方控制）；
///   - 不做子组件测宽（JS→宿主测尺寸是异步的，无法在 build 里同步使用），
///     箭头按 [alignment] 相对气泡本体定位；
///   - 箭头用「旋转 45° 的方块 + Stack 裁剪」拼出三角形（不支持 CustomPaint）。
class GuideBubbleWidget extends StatefulWidget {
  const GuideBubbleWidget({
    super.key,
    required this.child,
    required this.text,
    this.duration = const Duration(seconds: 5),
    this.alignment = 'right',
    this.gap = 8.0,
    this.backgroundColor = const Color(0xE6161616),
    this.textColor = Colors.white,
    this.textFontSize = 16.0,
  });

  /// 被锚定的子组件（气泡出现在它的下方）。
  final Widget child;

  /// 气泡文案。
  final String text;

  /// 显示时长（到时淡出并隐藏）。
  final Duration duration;

  /// 横向对齐：`'left'` / `'center'` / `'right'`（气泡与箭头跟着变）。
  final String alignment;

  /// 气泡与 [child] 的间距。
  final double gap;

  final Color backgroundColor;
  final Color textColor;
  final double textFontSize;

  @override
  State<GuideBubbleWidget> createState() => _GuideBubbleWidgetState();
}

class _GuideBubbleWidgetState extends State<GuideBubbleWidget> {
  static const Duration _fadeDuration = Duration(milliseconds: 200);
  static const double _arrowWidth = 24;
  static const double _arrowHeight = 9;
  static const double _arrowInset = 20;

  /// 旋转 45° 的方块边长：对角线 = 三角的底边宽（`_arrowSide * 1.4142`），
  /// 方块高的一半恰好 = 露出的三角高度（`_arrowHeight`）。
  static const double _arrowSide = _arrowHeight * 1.4142;
  static const double _arrowAngle = 0.7853981633974483;

  final OverlayPortalController _controller = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  Timer? _timer;
  Timer? _fadeTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  /// 重新开始一轮显示：立刻 show，并在 [GuideBubbleWidget.duration] 后淡出卸载。
  ///
  /// 控制器在 attach 前也会记住显示意图（Flutter 侧在 attach 时接管），故不需要
  /// post-frame 回调。
  void _schedule() {
    _cancelTimers();
    _visible = true;
    _controller.show();
    _timer = Timer(widget.duration, () {
      setState(() {
        _visible = false;
      });
      _fadeTimer = Timer(_fadeDuration, () {
        _controller.hide();
      });
    });
  }

  void _cancelTimers() {
    final timer = _timer;
    if (timer != null) {
      timer.cancel();
    }
    _timer = null;
    final fadeTimer = _fadeTimer;
    if (fadeTimer != null) {
      fadeTimer.cancel();
    }
    _fadeTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: _buildOverlayChild,
      child: CompositedTransformTarget(link: _layerLink, child: widget.child),
    );
  }

  Widget _buildOverlayChild(BuildContext context) {
    final centered = widget.alignment == 'center';
    final right = widget.alignment == 'right';
    return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      offset: Offset(0, widget.gap),
      targetAnchor: centered
          ? Alignment.bottomCenter
          : (right ? Alignment.bottomRight : Alignment.bottomLeft),
      followerAnchor: centered
          ? Alignment.topCenter
          : (right ? Alignment.topRight : Alignment.topLeft),
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: _fadeDuration,
          child: _buildBubbleContent(),
        ),
      ),
    );
  }

  Widget _buildBubbleContent() {
    final children = <Widget>[
      // 气泡在左 / 中 / 右时，箭头分别贴左 / 居中 / 贴右。
      _arrowRow(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: widget.textFontSize,
            color: widget.textColor,
            height: 1.2,
          ),
        ),
      ),
    ];
    // 枚举成员不能写在三元表达式里（生成器在表达式位置按静态引用直出，
    // 而 JS 侧没有 `CrossAxisAlignment` 类）；这里按分支各给一个字面枚举值，
    // 产物才能落到 `"center"` / `"end"` / `"start"` 的协议形态。
    if (widget.alignment == 'center') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
    }
    if (widget.alignment == 'right') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: children,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// 箭头行：按对齐方式给自己留出贴边间距。
  Widget _arrowRow() {
    if (widget.alignment == 'right') {
      return Padding(
        padding: const EdgeInsets.only(right: _arrowInset),
        child: _buildArrow(),
      );
    }
    if (widget.alignment == 'center') {
      return _buildArrow();
    }
    return Padding(
      padding: const EdgeInsets.only(left: _arrowInset),
      child: _buildArrow(),
    );
  }

  /// 向上指的三角尖：把方块旋转 45°，顶点对齐裁剪框上沿，露出来的就是三角形。
  ///
  /// 两个定位必须与裁剪框严格对齐，否则三角会一侧压边、一侧留空（看起来像
  /// 「被削掉半边」）：
  ///   - 水平：菱形中心放在框的**正中**（`(_arrowWidth - _arrowSide) / 2`）；
  ///   - 垂直：菱形中心落在框的**底边**（= 气泡顶边），恰好露出上半块。
  Widget _buildArrow() {
    return SizedBox(
      width: _arrowWidth,
      height: _arrowHeight,
      child: Stack(
        children: [
          Positioned(
            left: (_arrowWidth - _arrowSide) / 2,
            top: _arrowHeight - _arrowSide / 2,
            child: Transform.rotate(
              angle: _arrowAngle,
              child: Container(
                width: _arrowSide,
                height: _arrowSide,
                color: widget.backgroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
