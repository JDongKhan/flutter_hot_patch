import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';
import 'package:uuid/uuid.dart';

/// 「必须先构造才能用」的三方库 demo（左原生 / 右 JS 热更）。
///
/// uuid 不是纯静态工具：调用前必须先构造实例。这类库没法收口成宿主工具类，
/// 因此在 `js/` 下提供一套同名类（`js/uuid.js`），JS 侧构造与调用点与 Dart
/// 一比一（`final id = Uuid(); id.v4()`）。
@PatchEntry('ConstructOnlyCard')
class ConstructOnlyCard extends StatefulWidget {
  const ConstructOnlyCard({super.key});

  @override
  State<ConstructOnlyCard> createState() => _ConstructOnlyCardState();
}

class _ConstructOnlyCardState extends State<ConstructOnlyCard> {
  final Uuid _uuid = Uuid();

  String _uuidText = '未生成';

  void _newUuid() {
    setState(() => _uuidText = _uuid.v4());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'final id = Uuid();  id.v4()',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 8),
            Text('uuid：$_uuidText', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _newUuid,
                  child: const Text('Uuid.v4 生成'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'JS 侧由 js/uuid.js 提供同名类：构造、方法调用与 Dart 一比一',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
