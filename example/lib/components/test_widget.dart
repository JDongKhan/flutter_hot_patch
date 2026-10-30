import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'stateless_card.dart';

/// 局部 widget 变量 / 列表演示：验证 `Text text = Text();` 这类写法也按
/// 元素翻译（`var text = __h('Text', {...})`），而不是被当成模型构造丢弃。
@PatchEntry('TestWidget')
class TestWidget extends StatelessWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    Text text = const Text('局部变量 widget');
    // 自定义组件（非 Text）：类声明可见 → classTable 的 isComponent 命中，
    // 同样按元素翻译，而不是当成模型构造。
    StatelessCard card = const StatelessCard(
      title: '局部自定义组件',
      subtitle: 'StatelessCard 变量',
      badge: 'VAR',
    );
    final items = <Widget>[const Text('列表项 A'), const Text('列表项 B')];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          text,
          const SizedBox(height: 8),
          card,
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }
}
