import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

import '../base/note_object.dart';

/// 自定义实例对象绑定 demo（左原生 / 右 JS 热更，**两侧源码同一份**）：
///
/// ```dart
/// final NoteObject _note = NoteObject(title: '演示对象');
/// final g = await _note.greet('豆包');
/// ```
///
/// - 原生侧：`NoteObject` 就是 `lib/base/note_object.dart` 里的真实实例；
/// - JS 侧：`NoteObject` 由 `example/js/NoteObject.js` 承接，构造与成员
///   调用都经句柄 `obj/NoteObject` 打到**宿主同一个实例**上（返回值由宿主回填）。
@PatchEntry('NoteObjectCard')
class NoteObjectCard extends StatefulWidget {
  const NoteObjectCard({super.key});

  @override
  State<NoteObjectCard> createState() => _NoteObjectCardState();
}

class _NoteObjectCardState extends State<NoteObjectCard> {
  final NoteObject _note = NoteObject(title: '演示对象');

  String _greet = '尚未调用';
  String _bump = '—';
  String _title = '—';

  Future<void> _run() async {
    setState(() {
      _greet = '调用中…';
    });
    try {
      final g = await _note.greet('豆包');
      final b = await _note.bump();
      final t = await _note.readTitle();
      setState(() {
        _greet = '${g}';
        _bump = '${b}';
        _title = '${t}';
      });
    } catch (e) {
      setState(() {
        _greet = '失败：$e';
      });
    }
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
            Text(
              'new NoteObject(...) → js/NoteObject.js → obj/NoteObject',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5E35B1),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'greet("豆包")：$_greet',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'bump()：$_bump',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'readTitle()：$_title',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _run,
              child: Text('调用宿主实例的三个成员'),
            ),
            SizedBox(height: 8),
            Text(
              'JS 侧每一次成员调用都是一次 jsHandle op（call / get / set），'
              '宿主按成员名分派到真实实例——不是 JS 里另建一份状态。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
