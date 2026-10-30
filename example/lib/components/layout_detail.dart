import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

@PatchEntry('LayoutDetail')
class LayoutDetail extends StatefulWidget {
  const LayoutDetail({super.key});

  @override
  State<LayoutDetail> createState() => _LayoutDetailState();
}

class _LayoutDetailState extends State<LayoutDetail> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Row + Expanded / Flexible / Spacer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.blue.shade100,
                padding: const EdgeInsets.all(8),
                child: const Text('A', textAlign: TextAlign.center),
              ),
            ),
            const Spacer(flex: 1),
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.green.shade100,
                padding: const EdgeInsets.all(8),
                child: const Text('B（flex=2）', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Center / Align / Padding / SizedBox',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Center(
          child: Container(
            color: Colors.amber.shade100,
            padding: const EdgeInsets.all(12),
            child: const Text('Center 居中'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            color: Colors.purple.shade50,
            padding: const EdgeInsets.all(8),
            child: const Text('Align centerLeft'),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: const Text('Padding 包裹文案'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Stack + Positioned',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 100,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Container(color: Colors.grey.shade200),
              Positioned.fill(
                child: Center(
                  child: Text(
                    'FILL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Positioned(left: 12, top: 12, child: Text('TL')),
              const Positioned(right: 12, bottom: 12, child: Text('BR')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Wrap · 自动换行',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Wrap(
          direction: Axis.horizontal,
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              Chip(
                label: Text('chip $i'),
                backgroundColor: Colors.teal.shade50,
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Opacity / ConstrainedBox / AspectRatio / FractionallySizedBox',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Opacity(
          opacity: 0.5,
          child: Container(
            color: Colors.red,
            padding: const EdgeInsets.all(8),
            child: const Text('50% 透明'),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          child: Container(
            color: Colors.orange.shade100,
            padding: const EdgeInsets.all(8),
            child: const Text('ConstrainedBox 宽度 120-200'),
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1.78,
          child: Container(
            color: Colors.indigo.shade100,
            alignment: Alignment.center,
            child: const Text('16:9 比例'),
          ),
        ),
        const SizedBox(height: 8),
        FractionallySizedBox(
          widthFactor: 0.6,
          alignment: Alignment.center,
          child: Container(
            color: Colors.pink.shade100,
            padding: const EdgeInsets.all(8),
            child: const Text('60% 宽度', textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
