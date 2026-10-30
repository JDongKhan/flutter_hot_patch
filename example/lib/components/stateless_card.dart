import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// StatelessWidget 详情：无 State、无 createState，build 在 widget 类自身
/// （生成器自动识别：有 createState 用 State 类承载 build，否则用 widget
/// 类自身）。构造参数（title / subtitle / badge）→ JS constructor(args)，
/// 由 JsUiWidget.props 传入。
@PatchEntry('StatelessCard')
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
