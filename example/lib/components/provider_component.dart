import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

import '../model/counter_vm.dart';
import '../model/network_vm.dart';

/// provider 使用面 demo（左原生 / 右 JS 热更）。
///
/// 两侧只展示 provider 的用法，状态处理全在 JS 侧
/// （宿主 js/provider.js → patch/packages/provider.js），宿主不实现任何
/// provider 语义：
/// - `MultiProvider`：providers 平级数组 → 逆序包裹成嵌套 provider 结点，
///   Consumer 沿祖先链取「最近」实例——与原生嵌套 Provider.of 语义一致；
/// - `ChangeNotifierProvider(create:)` 由 provider 销毁时 dispose；
///   `ChangeNotifierProvider.value` 不负责释放，归调用方 State 手动 dispose；
/// - `context.watch` 按**构建位置**订阅（Builder 的订阅锚点是 Builder 自己），
///   `context.read` 仅取实例、不订阅；
/// - `Consumer`：订阅整个模型，notify 即重跑 builder；
/// - `Selector`：只暴露 selector 折算出的选中值，选中值不变时 builder 完全不重跑。
@PatchEntry('ProviderCard')
class ProviderCard extends StatefulWidget {
  const ProviderCard({super.key});

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
  final _counter = CounterVm();
  final _network = NetworkVm();

  // demo 计数：两个订阅点的 builder 各执行了多少次（build 内自增，当次渲染即显示）。
  int _consumerBuilds = 0;
  int _selectorBuilds = 0;

  void _loadUser() => _network.loadUserInfo(params: {"h": 1});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MultiProvider(
          providers: [
            // create：模型随 provider 销毁自动 dispose（State 不手动释放）。
            ChangeNotifierProvider<CounterVm>(create: (_) => _counter),
            // value：provider 不负责释放，_network 由本 State dispose（见下方）。
            ChangeNotifierProvider<NetworkVm>.value(value: _network),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // watch / read：订阅锚点是构建位置（Builder 自身）；事件里 read 不订阅。
              Builder(
                builder: (context) {
                  final model = context.watch<CounterVm>();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'context.watch：count = ${model.count}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      // Wrap：窄屏自动折行，避免按钮行溢出。
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () => model.inc(),
                            child: const Text('+1'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // read：只取实例，不建立订阅（事件回调里用）。
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
              // Consumer：整模型订阅——count 每变一次 builder 就重跑一次。
              Consumer<CounterVm>(
                builder: (context, model, child) {
                  _consumerBuilds++;
                  return Text(
                    'Consumer：builder 执行 $_consumerBuilds 次'
                    '（count = ${model.count}）',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Selector：只订阅「选中值」（count 是否 ≥ 5）。模型每次 notify 都会
              // 重算 selector，但选中值没变时 builder 不重跑——次数只在跨越 5 或
              // 归零时增长，与上面的 Consumer 形成对比。
              Selector<CounterVm, bool>(
                selector: (_, model) => model.count >= 5,
                // child 是固定子树：builder 重建时直接复用，不重新创建。
                child: const Text(
                  'child：跨重建复用的固定子树',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                builder: (context, isHigh, child) {
                  _selectorBuilds++;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selector：builder 执行 $_selectorBuilds 次'
                        '（count ≥ 5 为 ${isHigh ? 'true' : 'false'}）',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      child ?? const SizedBox(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // .value 传入的模型：订阅在 Consumer，实例释放归本 State。
              Consumer<NetworkVm>(
                builder: (context, model, child) => const Text(
                  'NetworkVm：ChangeNotifierProvider.value 由 State 手动 dispose',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _loadUser,
                    child: const Text('加载用户信息'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // _counter：create 创建，provider 销毁时自动 dispose。
    // _network：value 传入，provider 不负责释放，必须在此手动 dispose。
    _network.dispose();
    super.dispose();
  }
}
