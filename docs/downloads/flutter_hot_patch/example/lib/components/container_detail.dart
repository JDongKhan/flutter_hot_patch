import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

@PatchEntry('ContainerDetail')
class ContainerDetail extends StatefulWidget {
  const ContainerDetail({super.key});

  @override
  State<ContainerDetail> createState() => _ContainerDetailState();
}

class _ContainerDetailState extends State<ContainerDetail> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Container · 颜色/圆角/Padding',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: const Text(
            '容器内容（teal 圆角）',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Container · 边框 + 阴影 + 渐变',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                offset: Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Text(
            '渐变 + 边框 + 阴影',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'DecoratedBox · 纯装饰',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            border: Border.all(color: Colors.amber, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('DecoratedBox 内容'),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Card · shape / clipBehavior',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Card(
          elevation: 4,
          shadowColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.deepPurple, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('圆角卡片 + 描边 + 阴影'),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'SizedBox · 尺寸约束',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          width: 120,
          height: 48,
          alignment: Alignment.center,
          color: Colors.blueGrey.shade100,
          child: const Text('固定 120×48'),
        ),
      ],
    );
  }
}
