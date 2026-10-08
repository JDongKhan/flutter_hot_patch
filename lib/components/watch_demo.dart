import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_component/ui_component.dart';

import '../model/counter_model.dart';

/// context.watch / context.read demo：
/// - `context.watch<T>()`：取 provider 链最近实例 + 订阅（模型 notify →
///   lbWatch → 本页面整体 rebuild），与原生 watch 语义一致；
/// - `context.read<T>()`：仅取实例，不订阅（按钮回调里用）。
///
/// 生成器把两者分别翻译成 `this.__watch('CounterModel')` /
/// `this.__read('CounterModel')`，运行时挂载在 JS 实例上。
@UIComponent('WatchDemo')
class WatchDemo extends StatefulWidget {
  const WatchDemo({super.key});

  @override
  State<WatchDemo> createState() => _WatchDemoState();
}

class _WatchDemoState extends State<WatchDemo> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ChangeNotifierProvider<CounterModel>(
          create: (_) => CounterModel(),
          child: Builder(
            builder: (context) {
              // watch：订阅局部刷新（模型 notify → 本组件重建）
              final model = context.watch<CounterModel>();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('context.watch<CounterModel>'),
                  Text(
                    'count = ${model.count}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => model.inc(),
                        child: const Text('+1'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        // read：仅取实例（不订阅），按钮回调里合法用法
                        onPressed: () {
                          context.read<CounterModel>().reset();
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
