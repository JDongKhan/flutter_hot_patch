import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// RichText 演示：`text` 是 `TextSpan` 树，不是字符串。
///
/// 一比一翻译说明：
///   - `TextSpan` 是 **值对象**（不是 Widget），产物按统一构造规则发射
///     `new TextSpan({text, style, children, semanticsLabel})`；
///   - `children` 递归同构，跨桥时由 JSON 序列化成普通对象，宿主
///     `textSpanFromJson` 再还原成真正的 `TextSpan` 树后交给 `RichText`；
///   - `textDirection` / `textAlign` / `overflow` 等枚举按同名常量下发，
///     与 `Text` 共用同一套 `*FromJson`。
@PatchEntry('RichTextDetail')
class RichTextDetail extends StatefulWidget {
  const RichTextDetail({super.key});

  @override
  State<RichTextDetail> createState() => _RichTextDetailState();
}

class _RichTextDetailState extends State<RichTextDetail> {
  bool _highlight = false;
  bool _clampLines = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'RichText · TextSpan 富文本树',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: '一段文字里可以混排：',
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            children: [
              TextSpan(
                text: '不同颜色',
                style: TextStyle(
                  color: _highlight ? Colors.deepPurple : Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '、'),
              const TextSpan(
                text: '更大字号',
                style: TextStyle(fontSize: 20, color: Colors.orange),
              ),
              const TextSpan(text: '、'),
              const TextSpan(
                text: '下划线',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,
                  decorationStyle: TextDecorationStyle.wavy,
                ),
              ),
              const TextSpan(text: '，并且可以逐级嵌套。'),
            ],
          ),
        ),
        const Divider(height: 24),
        const Text(
          'RichText · maxLines + ellipsis 截断',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.start,
          textDirection: TextDirection.ltr,
          maxLines: _clampLines ? 1 : null,
          overflow: _clampLines ? TextOverflow.ellipsis : TextOverflow.clip,
          text: const TextSpan(
            text: '这是一段足够长的文字，用来验证 RichText 在多行与单行之间的'
                '截断行为：开启单行截断后，超出宽度的部分会以省略号结尾，'
                '而关闭截断时文字会自然折行显示完整内容。',
            style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _highlight = !_highlight),
                child: Text(_highlight ? '还原子串颜色' : '切换子串颜色'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _clampLines = !_clampLines),
                child: Text(_clampLines ? '关闭单行截断' : '开启单行截断'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
