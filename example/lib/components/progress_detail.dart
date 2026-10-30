import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

@PatchEntry('ProgressDetail')
class ProgressDetail extends StatefulWidget {
  const ProgressDetail({super.key});

  @override
  State<ProgressDetail> createState() => _ProgressDetailState();
}

class _ProgressDetailState extends State<ProgressDetail> {
  final double _progress = 0.65;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'CircularProgressIndicator',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircularProgressIndicator(
              value: _progress,
              color: Colors.deepPurple,
              backgroundColor: Colors.deepPurple.shade50,
              strokeWidth: 6,
            ),
            const SizedBox(width: 24),
            const CircularProgressIndicator(),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'LinearProgressIndicator',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _progress,
          color: Colors.deepPurple,
          backgroundColor: Colors.deepPurple.shade50,
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        const LinearProgressIndicator(),
        const SizedBox(height: 8),
        Text(
          '进度值：$_progress',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
