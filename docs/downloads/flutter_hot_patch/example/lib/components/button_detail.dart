import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

@PatchEntry('ButtonDetail')
class ButtonDetail extends StatefulWidget {
  const ButtonDetail({super.key});

  @override
  State<ButtonDetail> createState() => _ButtonDetailState();
}

class _ButtonDetailState extends State<ButtonDetail> {
  int _pressed = 0;

  void onTap() {
    setState(() => _pressed++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '点击次数 = $_pressed',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(180, 48),
            maximumSize: const Size(240, 56),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 6,
            shadowColor: Colors.deepPurple,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: const Text('Elevated · Styled'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(120, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: const TextStyle(fontSize: 14, letterSpacing: 1),
            foregroundColor: Colors.indigo,
          ),
          child: const Text('TextButton'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.orange, width: 2),
            minimumSize: const Size(120, 40),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            foregroundColor: Colors.deepOrange,
          ),
          child: const Text('OutlinedButton'),
        ),
        const SizedBox(height: 8),
        // 无 onPressed：禁用态
        const ElevatedButton(onPressed: null, child: Text('Disabled')),
      ],
    );
  }
}
