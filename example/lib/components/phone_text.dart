import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 演示：**自定义组件里再套自定义组件**（展开递归的第二层）。
///
/// `PhoneLabel` 的 build 结果里使用了它；值对象展开时由 `__descriptorOf`
/// 递归把这一层也摊成宿主可渲染的元素描述（最终是 Text）。
@PatchEntry()
class PhoneText extends StatelessWidget {
  const PhoneText({
    super.key,
    required this.text,
    this.color = Colors.deepPurple,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 14, color: color));
  }
}
