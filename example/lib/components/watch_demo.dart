import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import '../model/counter_vm.dart';

/// context.watch / context.read / Selector demo：
/// - `context.watch<T>()`：按**类型名**取最近作用域的值 + 订阅（模型 notify →
///   只重建调用 watch 的那个位置），与原生 watch 语义一致；
/// - `context.read<T>()`：仅取实例，不订阅（按钮回调里用）；
/// - `Selector<T, R>`：订阅模型但只暴露 `selector` 折算出的选中值，选中值不变
///   就不重建 builder 子树（provider 的过滤重建语义）。
///
/// 生成器把 watch/read 译成 `context.watch({typeArguments: ['CounterVm']})` /
/// `context.read({typeArguments: ['CounterVm']})` —— 泛型实参统一以元信息
/// 并入调用尾参对象（与构造 props 同形）；事件等延迟作用域里形参不可见，
/// 译成 `this.context.read({typeArguments: ['CounterVm']})` —— 同一个 context
/// 代理，按**绑定位置**解析（`_builderN` 由 JS 的 Builder 以 owner 为 this 调用，
/// 事件里 `this.context` 仍取到 Builder 自身的代理，与 Dart 闭包捕获 `context`
/// 形参同语义）。
///
/// provider 下挂**三处 watch 消费者**，验证 watch 换位置仍然正确：
///   1. `Builder` + `context.watch`：builder 方法定义在 WatchDemo 上，
///      但订阅锚点是 Builder 自身（按**构建位置**，不按方法定义处）；
///   2. `WatchCountLabel`：独立 StatefulWidget，在自己的 State.build 里
///      watch —— 锚点是它自己，notify 只重建它。两者互不影响；
///   3. `Selector`：notify 时先重算选中值（count 是否 ≥ 5），选中值不变则
///      builder 完全不重跑；`child` 作为固定子树跨重建复用。紧跟一个
///      `Consumer` 并排对比：两者各自显示 builder 执行次数，点击 `+1` 时
///      Consumer 的次数每次都涨，Selector 只在 0↔5 的边界上跳一次。
@PatchEntry('WatchDemo')
class WatchDemo extends StatefulWidget {
  const WatchDemo({super.key});

  @override
  State<WatchDemo> createState() => _WatchDemoState();
}

class _WatchDemoState extends State<WatchDemo> {
  // 仅用于 demo：统计两个 builder 各执行了多少次（build 内自增，本次渲染即显示）。
  int _consumerBuilds = 0;
  int _selectorBuilds = 0;

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
              const SizedBox(height: 12),
              // Consumer：订阅整个模型——count 每变一次 builder 就重跑一次，
              // 下面的次数会跟着 +1 增长。
              Consumer<CounterVm>(
                builder: (context, model, child) {
                  _consumerBuilds++;
                  return Text(
                    'Consumer 的 builder 执行 $_consumerBuilds 次（count = ${model.count}）',
                    style: const TextStyle(fontSize: 14, color: Colors.purple),
                  );
                },
              ),
              const SizedBox(height: 8),
              // Selector：只订阅「选中值」（count 是否 ≥ 5）。模型每次 notify 都会
              // 重算 selector，但选中值没变时 builder 不重跑——次数只跨越 5 的边界
              // 或归零时增长，与上面的 Consumer 形成对比。
              Selector<CounterVm, bool>(
                selector: (_, model) => model.count >= 5,
                // child 是固定子树：builder 重建时直接复用，不重新创建。
                child: const Text('child：跨重建复用的固定子树', style: TextStyle(fontSize: 12, color: Colors.grey)),
                builder: (context, isHigh, child) {
                  _selectorBuilds++;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selector 的 builder 执行 $_selectorBuilds 次'
                        '（选中值：count ≥ 5 为 ${isHigh ? 'true' : 'false'}）',
                        style: const TextStyle(fontSize: 14, color: Colors.green),
                      ),
                      child ?? const SizedBox(),
                    ],
                  );
                },
              ),
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
@PatchEntry('WatchCountLabel')
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
