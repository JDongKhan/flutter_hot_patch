import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

/// 共享模型：一个普通 ChangeNotifier，持有可变计数并通知刷新。
/// 用于验证 builder widget（ListenableBuilder）在 codegen 下能否翻译。
class CounterModel extends ChangeNotifier {
  int _n = 0;
  int get n => _n;
  void inc() {
    _n++;
    notifyListeners();
  }

  void reset() {
    _n = 0;
    notifyListeners();
  }
}

/// Demo：ChangeNotifier + ListenableBuilder。
/// 目标：让「由共享模型驱动、局部重建」的子树也能走 JS 热更。
@UIComponent('ListenableDemo')
class ListenableDemo extends StatefulWidget {
  const ListenableDemo({super.key});

  @override
  State<ListenableDemo> createState() => _ListenableDemoState();
}

class _ListenableDemoState extends State<ListenableDemo> {
  // 可变的 ChangeNotifier 实例（对象类型字段；static 单例亦可，见后）。
  final CounterModel _model = CounterModel();

  void _inc() => _model.inc();
  void _reset() => _model.reset();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('ListenableBuilder 局部重建'),
        ListenableBuilder(
          listenable: _model,
          builder: (context, _) => Text('n = ${_model.n}'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(onPressed: _inc, child: const Text('+1')),
            ElevatedButton(onPressed: _reset, child: const Text('Reset')),
          ],
        ),
      ],
    );
  }
}