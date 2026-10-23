import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final List<int> updates = [];
final List<int> inits = [];

class Probe extends StatefulWidget {
  const Probe(this.index, {super.key});
  final int index;
  @override
  State<Probe> createState() => _ProbeState();
}

class _ProbeState extends State<Probe> {
  @override
  void initState() {
    inits.add(widget.index);
  }

  @override
  void didUpdateWidget(covariant Probe oldWidget) {
    updates.add(widget.index);
  }

  @override
  Widget build(BuildContext context) => Text('item ${widget.index}');
}

class Host extends StatefulWidget {
  const Host({super.key});
  @override
  State<Host> createState() => HostState();
}

class HostState extends State<Host> {
  int tick = 0;

  void bump() => setState(() => tick++);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        itemExtent: 56,
        itemCount: 20,
        itemBuilder: (_, i) => Probe(i),
      ),
    );
  }
}

void main() {
  testWidgets('ListView.builder 父级 setState 会重建已挂载子项', (tester) async {
    final key = GlobalKey<HostState>();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Host(key: key))));
    print('initState(mounted)=${inits.length} $inits');

    updates.clear();
    key.currentState!.bump();
    await tester.pump();
    print('单次 setState 后 didUpdateWidget=${updates.length} $updates');

    updates.clear();
    key.currentState!.bump();
    await tester.pump();
    print('再次 setState 后 didUpdateWidget=${updates.length} $updates');
  });
}
