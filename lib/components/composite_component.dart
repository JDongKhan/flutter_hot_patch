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
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        Text('ticks = $_ticks'),
        // 有注解的自定义组件：JS 版递归渲染 BannerCard（含其自身状态）
        const BannerCard(),
        const SizedBox(height: 12),
        // 私有组件（_ 开头）：生成器递归翻译成 JS 注册进同一产物
        const _LabeledDivider(text: 'private widget'),
        const SizedBox(height: 8),
        // 非私有组件：原生直接可用；JS 版运行时由 nativeComponents 注入
        const LabeledDivider(text: 'public widget'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: tick,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Tick'),
        ),
      ],
    );
  }
}

/// 私有组件（_ 开头）：生成器递归翻译成 JS 注册进同一产物，
/// 运行时 ComponentHost 递归渲染 JS 版本。
class _LabeledDivider extends StatelessWidget {
  const _LabeledDivider({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('— $text —', style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// 非私有组件：原生直接可用；JS 场景运行时由 nativeComponents
/// 注入 Flutter widget（hot_patch 包不 import 业务类）。
class LabeledDivider extends StatelessWidget {
  const LabeledDivider({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      '★ $text ★',
      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
    );
  }
}
