import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_component/ui_component.dart';

import '../model/counter_vm.dart';
import '../model/network_vm.dart';

/// MultiProvider 响应式热更 demo。
///
/// 原生：MultiProvider 同时管理两个 CounterModel（providers 数组平级），
/// Consumer 分别订阅局部重建。
/// JS 热更：转换**一一对应**生成一个 `MultiProvider` 节点，providers 保持
/// 平级数组（每个条目是 ChangeNotifierProvider 节点，model + create/value）。
/// 状态处理全在 JS 侧（assets/provider.js，由 JsUiWidget 新
/// 运行时渲染，宿主不实现任何 provider 语义）：MultiProvider 把 providers
/// 逆序包裹成嵌套 provider 结点，Consumer 沿祖先链取「最近」VM 并订阅 ——
/// 与原生 MultiProvider 的嵌套 Provider.of 语义一致。VM notify → 仅该
/// Consumer 结点局部重建。
@UIComponent('ProviderCard')
class ProviderCard extends StatefulWidget {
  const ProviderCard({super.key});

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
  final _modelA = CounterVm();
  final _modelB = NetworkVm();

  void _incA() => _modelA.inc();
  void _resetA() => _modelA.reset();
  void _loadUser() => _modelB.loadUserInfo(params: {"h": 1});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MultiProvider(
          providers: [
            // create：模型由 provider 销毁时自动 dispose（State 不手动释放）。
            ChangeNotifierProvider<CounterVm>(create: (_) => _modelA),
            // value：provider **不**负责释放，_modelB 由本 State dispose
            // 手动释放（见下方 dispose）。生成器把 value 构造翻译成
            // create.ref 语义（复用实例、__dispose:false，归用户）。
            ChangeNotifierProvider<NetworkVm>.value(value: _modelB),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildText(),
              _modelA.buildText(),
              Consumer<CounterVm>(builder: (context, value, child) => _buildBadge()),
              const Text('MultiProvider · 两个模型各自局部重建'),
              const SizedBox(height: 8),
              Consumer<NetworkVm>(
                builder: (context, value, child) => Text(
                  '加载用户信息：',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [ElevatedButton(onPressed: _loadUser, child: const Text('加载用户信息'))],
              ),
              const SizedBox(height: 8),
              Consumer<CounterVm>(
                builder: (context, value, child) => Text(
                  'B = ${value.count}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: _incA, child: const Text('B +1')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _resetA, child: const Text('B Reset')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return Text("test 1");
  }

  /// 语句级 switch + for 演示：按计数档位给档位名、按计数拼重复标记。
  /// 挂载时求值一次（不在 Consumer 内，计数变化由下方 Consumer 行实时展示）。
  Widget _buildBadge() {
    var label = '';
    // 语句级 switch：case 1 / case 2 空体贯穿共用一段，default 兜底
    //（Dart 无贯穿语义，生成器为非空 case 自动补 break）。
    switch (_modelA.count) {
      case 0:
        label = 'B·零';
        break;
      case 1:
      case 2:
        label = 'B·少';
        break;
      case 3:
      case 4:
        label = 'B·多';
        break;
      default:
        label = 'B·爆表';
    }
    // 语句级 for：循环变量 i 直接参与拼接（for 头声明的 i 由生成器登记为局部变量）。
    var dots = '';
    for (var i = 0; i < _modelA.count; i++) {
      dots = '$dots·';
    }
    return Text('$label$dots');
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
