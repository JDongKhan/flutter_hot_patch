import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

@PatchEntry('TextDetail')
class TextDetail extends StatefulWidget {
  const TextDetail({super.key});

  @override
  State<TextDetail> createState() => _TextDetailState();
}

class _TextDetailState extends State<TextDetail> {
  int _count = 0;

  void bump() {
    setState(() => _count++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '基础文案 + TextStyle',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          '普通文本，count = $_count（状态插值）',
          style: const TextStyle(color: Colors.blue, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          'maxLines+overflow 测试：这是一段很长的文字会被截断成省略号显示',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text('textScaler.linear(1.6) 放大', textScaler: TextScaler.linear(1.6)),
        const SizedBox(height: 6),
        Text(
          'textAlign 居中,He said "hi"',
          textAlign: TextAlign.center,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.orange,
            decorationStyle: TextDecorationStyle.wavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'softWrap=false 不换行测试',
          softWrap: false,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            wordSpacing: 2,
            letterSpacing: 1,
            backgroundColor: Color(0xFFFFE082),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(onPressed: bump, child: const Text('Bump count')),
      ],
    );
  }
}
