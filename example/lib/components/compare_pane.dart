import 'package:flutter/material.dart';

/// 对比页的窄屏 / 宽屏分界（逻辑宽度，与「常用组件」详情页一致）。
const double kCompareWideBreakpoint = 700;

/// 统一的「左 vs 右」对比页外壳。
///
/// 宽屏：左右两栏并列（每栏带标题），一眼对照；
/// 窄屏：只显示一栏，标题栏右侧的按钮在两栏之间切换（默认右栏）。
///
/// 「原生组件 vs JS 热更」的所有入口共用这一套外壳（含列表页入口与
/// 「三方库」「常用组件」内部的详情页），保证宽窄屏行为一致。
class ComparePane extends StatefulWidget {
  const ComparePane({
    super.key,
    required this.title,
    required this.left,
    required this.right,
    this.leftLabel = '原生组件',
    this.rightLabel = 'JS 热更（JsUiWidget）',
    this.initialShowRight = true,
    this.fillPane = false,
    this.innerAppBar = false,
  });

  /// 页面标题（宽屏 / 窄屏都显示；[innerAppBar] 时用于窄屏切换条）。
  final String title;

  /// 左栏内容。
  final Widget left;

  /// 右栏内容。
  final Widget right;

  final String leftLabel;
  final String rightLabel;

  /// 窄屏默认显示右栏（与「常用组件」详情页一致：默认 JS 热更版）。
  final bool initialShowRight;

  /// 两侧内容自带滚动容器 / Scaffold 的整页 demo：外层不再套滚动容器，
  /// 直接铺满一栏（否则会拿到无界高度）。
  final bool fillPane;

  /// 两侧内容各自带 AppBar（如「完整 App」的 AppShell / AppShellJsPage）：
  /// 窄屏不再叠一层外层 AppBar，改用一条紧凑切换条。
  final bool innerAppBar;

  @override
  State<ComparePane> createState() => _ComparePaneState();
}

class _ComparePaneState extends State<ComparePane> {
  late bool _showRight = widget.initialShowRight;

  /// 窄屏切换按钮（AppBar / 紧凑条共用）。
  Widget _switchButton(bool showRight) {
    return TextButton.icon(
      onPressed: () => setState(() => _showRight = !_showRight),
      icon: Icon(
        showRight ? Icons.construction : Icons.bolt,
        size: 18,
      ),
      label: Text(showRight ? 'JS 热更' : '原生组件'),
    );
  }

  /// 左右栏的标题 + 内容。
  Widget _pane(String label, Widget child) {
    final header = Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: child,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (widget.fillPane) Expanded(child: body) else body,
      ],
    );
  }

  /// 窄屏且两侧自带 AppBar 时的紧凑切换条（标题 + 当前侧 + 切换 + 返回）。
  Widget _narrowBar(bool showRight) {
    final canPop = Navigator.of(context).canPop();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            if (canPop)
              IconButton(
                tooltip: '返回',
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            Expanded(
              child: Text(
                '${widget.title} · ${showRight ? widget.rightLabel : widget.leftLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            _switchButton(showRight),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kCompareWideBreakpoint;

        if (wide) {
          // 宽屏：固定左右两栏（无论初始侧），两栏各自滚动 / 铺满。
          return Scaffold(
            appBar: widget.innerAppBar
                ? null
                : AppBar(title: Text(widget.title)),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: widget.fillPane
                      ? _paneFilled(widget.leftLabel, widget.left)
                      : SingleChildScrollView(
                          child: _pane(widget.leftLabel, widget.left),
                        ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: widget.fillPane
                      ? _paneFilled(widget.rightLabel, widget.right)
                      : SingleChildScrollView(
                          child: _pane(widget.rightLabel, widget.right),
                        ),
                ),
              ],
            ),
          );
        }

        // 窄屏：只显示当前一栏，标题栏右侧按钮切换。
        final showRight = _showRight;
        final child = showRight ? widget.right : widget.left;
        final label = showRight ? widget.rightLabel : widget.leftLabel;
        return Scaffold(
          appBar: widget.innerAppBar
              ? null
              : AppBar(
                  title: Text(widget.title),
                  actions: [_switchButton(showRight)],
                ),
          body: Column(
            children: [
              if (widget.innerAppBar) _narrowBar(showRight),
              Expanded(
                child: widget.fillPane
                    ? child
                    : SingleChildScrollView(
                        child: _pane(label, child),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 整页 demo（自带滚动 / Scaffold）：标题 + 直接铺满剩余空间。
  Widget _paneFilled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: child,
          ),
        ),
      ],
    );
  }
}
