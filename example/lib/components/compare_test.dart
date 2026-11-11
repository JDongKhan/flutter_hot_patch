import 'package:flutter/material.dart';

/// 原生 vs JS 热更同屏对比：**左右两栏**，方便肉眼对照。
///
/// 供 Demo 列表页与「三方库」列表页共用（原先是 main.dart 里的私有实现）。
class CompareTest extends StatelessWidget {
  const CompareTest({super.key, required this.native, required this.js});

  final Widget native;
  final Widget js;

  @override
  Widget build(BuildContext context) {
    // 两栏各自可滚动：对比块里既有紧凑组件，也可能出现固定高度/多段区块，
    // 整页高度会超出一屏，需可滚动避免 RenderFlex 溢出。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _pane('原生组件', native)),
        const VerticalDivider(width: 1),
        Expanded(child: _pane('JS 热更（JsUiWidget）', js)),
      ],
    );
  }

  Widget _pane(String title, Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
