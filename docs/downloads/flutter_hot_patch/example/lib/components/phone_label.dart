import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'phone_text.dart';

/// 演示：值对象（`InputDecoration.label`）里放**自定义 JS 组件**。
///
/// 它是 StatelessWidget 子类 → 产物里是重写了 build 的 JS 类。放进
/// InputDecoration 的 Widget 字段后随 decoration 的字段 JSON 下发；运行时
/// `__descriptorOf` 会就地执行一次 build，并把结果（含再嵌套的 `PhoneText`）
/// 递归摊成宿主可渲染的元素描述——不挂载、不参与 diff、状态不刷新。
@PatchEntry()
class PhoneLabel extends StatelessWidget {
  const PhoneLabel({
    super.key,
    required this.text,
    this.color = Colors.deepPurple,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.phone_iphone, size: 14),
        const SizedBox(width: 4),
        // 第二层自定义组件：展开递归继续处理。
        PhoneText(text: text, color: color),
      ],
    );
  }
}
