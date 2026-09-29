import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

import '../model/counter_model.dart';

/// ChangeNotifier + ListenableBuilder 响应式热更 demo。
///
/// 原生：CounterModel 是真 ChangeNotifier，ListenableBuilder 注册监听，
/// notifyListeners → 局部重建。
/// JS 热更：CounterModel 翻译成 JS class（带 addListener/notifyListeners），
/// ListenableBuilder 翻译成 {type: ListenableBuilder, listenable: _model,
/// builder: _lbBuilder0} 节点，运行时挂 JS 监听，notify → lbNotify → 局部重建。
@UIComponent('NotifierCard')
class NotifierCard extends StatefulWidget {
  const NotifierCard({super.key});

  @override
  State<NotifierCard> createState() => _NotifierCardState();
}

class _NotifierCardState extends State<NotifierCard> {
  final _model = CounterModel();

  void _inc() => _model.inc();
  void _reset() => _model.reset();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenableBuilder(
              listenable: _model,
              builder: (context, _) => Text(
                'count = ${_model.count}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _inc, child: const Text('+1')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }
}
