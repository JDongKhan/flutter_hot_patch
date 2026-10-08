import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_component/ui_component.dart';

import '../model/counter_model.dart';

/// MultiProvider 响应式热更 demo。
///
/// 原生：MultiProvider 同时管理两个 CounterModel（providers 数组平级），
/// Consumer 分别订阅局部重建。
/// JS 热更：转换**一一对应**生成一个 `MultiProvider` 节点，providers 保持
/// 平级数组（每个条目是 ChangeNotifierProvider 节点，model + create）。
/// 运行时 MultiProviderRenderer 把所有条目模型按序登记进
/// `__providerChain[key]`（栈），Consumer 挂监听时取「最近」实例 —— 与
/// 原生 MultiProvider 的嵌套 Provider.of 语义一致。notify → lbNotify →
/// 仅该 Consumer 节点局部重建（与 ListenableBuilder 同一回调表）。
@UIComponent('ProviderCard')
class ProviderCard extends StatefulWidget {
  const ProviderCard({super.key});

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
  final _modelA = CounterModel();
  final _modelB = CounterModel();

  void _incA() => _modelA.inc();
  void _resetA() => _modelA.reset();
  void _incB() => _modelB.inc();
  void _resetB() => _modelB.reset();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MultiProvider(
          providers: [
            // create：模型由 provider 销毁时自动 dispose（State 不手动释放）。
            ChangeNotifierProvider<CounterModel>(
              create: (_) => _modelA,
            ),
            // value：provider **不**负责释放，_modelB 由本 State dispose
            // 手动释放（见下方 dispose）。生成器把 value 构造翻译成
            // create.ref 语义（复用实例、__dispose:false，归用户）。
            ChangeNotifierProvider<CounterModel>.value(
              value: _modelB,
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('MultiProvider · 两个模型各自局部重建'),
              const SizedBox(height: 8),
              Consumer<CounterModel>(
                builder: (context, value, child) => Text(
                  'A = ${value.count}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: _incA, child: const Text('A +1')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _resetA, child: const Text('A Reset')),
                ],
              ),
              const SizedBox(height: 8),
              Consumer<CounterModel>(
                builder: (context, value, child) => Text(
                  'B = ${value.count}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: _incB, child: const Text('B +1')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _resetB, child: const Text('B Reset')),
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
    // _modelA：ChangeNotifierProvider(create:) 创建的，provider 销毁时
    // 自动 dispose（子树先于 State unmount，无重复释放）。
    // _modelB：ChangeNotifierProvider.value 传入的，provider 不负责释放，
    // 必须在此手动 dispose；不释放会泄漏。
    _modelB.dispose();
    super.dispose();
  }
}
