import 'package:flutter/material.dart';

/// 原生 vs JS 热更同屏对比：一页上下两块，方便肉眼对照。
///
/// 供 Demo 列表页与「三方库」列表页共用（原先是 main.dart 里的私有实现）。
class CompareTest extends StatelessWidget {
  const CompareTest({super.key, required this.native, required this.js});

  final Widget native;
  final Widget js;

  @override
  Widget build(BuildContext context) {
    // 可滚动：对比块里既有紧凑组件，也可能出现固定高度/多段区块，整页高度
    // 会超出一屏，需可滚动避免 RenderFlex 溢出。
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '原生组件',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          native,
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text(
            'JS 热更（JsUiWidget）',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          js,
        ],
      ),
    );
  }
}
