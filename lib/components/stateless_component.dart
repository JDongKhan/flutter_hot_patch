import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

/// 演示 StatelessWidget 支持：
///   - 无 State、无 createState，build 在 widget 类自身（生成器自动识别：
///     有 createState 用 State 类承载 build，否则用 widget 类自身）；
///   - 构造参数（this.title / this.subtitle / this.badge）→ JS
///     constructor(args) 的 args（JsUiWidget.props 传入）；
///   - 实例方法（_tag）→ JS 方法一比一翻译。
///
/// 组件本体是 100% 正常的 Flutter StatelessWidget，原生可直接使用；
/// 线上出 bug 时切换 JsUiWidget 加载 JS 版本即可热修复。
@UIComponent('StatelessCard')
class StatelessCard extends StatelessWidget {
  const StatelessCard({
    super.key,
    required this.title,
    this.subtitle = '',
    this.badge = 'NEW',
  });

  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$badge · $title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
