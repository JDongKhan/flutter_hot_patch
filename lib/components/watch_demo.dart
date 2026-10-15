import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_component/ui_component.dart';

import '../model/counter_vm.dart';

/// context.watch / context.read demo：
/// - `context.watch<T>()`：取 provider 链最近实例 + 订阅（模型 notify →
///   只重建调用 watch 的那个位置），与原生 watch 语义一致；
/// - `context.read<T>()`：仅取实例，不订阅（按钮回调里用）。
///
/// 生成器把两者分别翻译成 `this.watch('CounterVm')` /
/// `this.read('CounterVm')`（类型名原样传给 JS），运行时挂载在 JS 实例上。
///
/// provider 下挂**两处 watch 消费者**，验证 watch 换位置仍然正确：
///   1. `Builder` + `context.watch`：builder 方法定义在 WatchDemo 上，
///      但订阅锚点是 Builder 自身（按**构建位置**，不按方法定义处）；
///   2. `WatchCountLabel`：独立 StatefulWidget，在自己的 State.build 里
///      watch —— 锚点是它自己，notify 只重建它。两者互不影响。
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
        child: ChangeNotifierProvider<CounterVm>(
          create: (_) => CounterVm(),
          // 两个消费者都在 provider 子树内，各自按位置订阅：
          // Builder（委托 builder）与 WatchCountLabel（独立 State）。
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) {
                  // watch：订阅局部刷新（模型 notify → 本组件重建）
                  final model = context.watch<CounterVm>();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('context.watch<CounterModel>'),
                      Text(
                        'count = ${model.count}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(onPressed: () => model.inc(), child: const Text('+1')),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            // read：仅取实例（不订阅），按钮回调里合法用法
                            onPressed: () {
                              context.read<CounterVm>().reset();
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // 独立 StatefulWidget：在自己的 State.build 里 watch 同一个模型。
              const WatchCountLabel(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 验证 `context.watch` 在「另一个组件 / 另一个 State」里使用是否正确。
///
/// 本组件是独立的自定义 StatefulWidget，位于 provider 子树内；在**自己的
/// State.build** 里调用 `context.watch<CounterModel>()`。订阅锚点应是本组件
/// 自身（而非定义 watch 的 WatchDemo），模型 notify 时只重建本组件。
@UIComponent('WatchCountLabel')
class WatchCountLabel extends StatefulWidget {
  const WatchCountLabel({super.key});

  @override
  State<WatchCountLabel> createState() => _WatchCountLabelState();
}

class _WatchCountLabelState extends State<WatchCountLabel> {
  @override
  Widget build(BuildContext context) {
    final model = context.watch<CounterVm>();
    return Text('another State: count = ${model.count}', style: const TextStyle(fontSize: 16, color: Colors.blue));
  }
}
