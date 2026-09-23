import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

import 'banner_component.dart';

/// 复合组件演示：build() 里使用**其他自定义 widget**。
///
/// 两种形态：
///   1. `BannerCard()` —— 有 @UIComponent 注解：JS 版递归渲染为
///      Component 节点（运行时 new 嵌套实例 + 事件回流），原生版直接嵌组件。
///   2. `_LabeledDivider()` —— 无注解的 lib 自定义 widget：原生版直接使用；
///      JS 版渲染为 Component 占位提示（__components 无该组件注册）。
@UIComponent('DashboardCard')
class DashboardCard extends StatefulWidget {
  const DashboardCard({super.key});

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  // 全量生成：_ticks → JS 属性 `_ticks`
  int _ticks = 0;

  // 全量生成：tick → JS 方法 `tick`
  void tick() {
    setState(() => _ticks++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Dashboard (JS)',
          style: const TextStyle(fontSize: 20),
        ),
        Text('ticks = $_ticks'),
        // 有注解的自定义组件：JS 版递归渲染 BannerCard（含其自身状态）
        const BannerCard(),
        const SizedBox(height: 12),
        // 无注解的自定义 widget：原生版直接使用，JS 版为 Component 占位
        const _LabeledDivider(text: 'no-annotation widget'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: tick,
          child: const Text('Tick'),
        ),
      ],
    );
  }
}

/// 无注解的 lib 自定义 widget（普通 Flutter 组件，生成器不认识）：
/// 原生场景直接使用；JS 场景翻译为 Component 节点，运行时渲染占位提示。
class _LabeledDivider extends StatelessWidget {
  const _LabeledDivider({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
