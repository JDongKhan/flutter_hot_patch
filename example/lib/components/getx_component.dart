import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

import '../model/getx_counter_vm.dart';

/// GetX 使用面 demo（左原生 / 右 JS 热更）。
///
/// 两侧只展示 GetX 的状态管理用法，状态处理全在 JS 侧
/// （宿主 js/get.js → patch/packages/get.js），宿主不实现任何 GetX 语义：
/// - `Get.put/find/delete`：进程内全局实例表，不依赖 widget 树；
/// - `GetBuilder`：普通字段 + 显式 `update()` 重建（手动通知）；
/// - `Obx` + `Rx`：闭包内读 `.value` 自动登记依赖，赋值即重建（自动追踪）。
@PatchEntry('GetXCard')
class GetXCard extends StatefulWidget {
  const GetXCard({super.key});

  @override
  State<GetXCard> createState() => _GetXCardState();
}

class _GetXCardState extends State<GetXCard> {
  final _vm = GetxCounterVm();

  // demo 计数：两个订阅点的 builder 各执行了多少次（build 内自增，当次渲染即显示）。
  int _builderBuilds = 0;
  int _obxBuilds = 0;

  @override
  void initState() {
    super.initState();
    // DI：注册实例，GetBuilder 与事件回调都按类型名取同一个实例。
    // 不写显式泛型：JS 侧按实例的类名登记，与 `Get.find<T>()` 下发的类型名一致。
    Get.put(_vm);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // GetBuilder：手动通知——只有 update() 才重跑 builder。
            GetBuilder<GetxCounterVm>(
              builder: (vm) {
                _builderBuilds++;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GetBuilder：builder 执行 $_builderBuilds 次'
                      '（count = ${vm.count}）',
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
                          onPressed: () => vm.inc(),
                          child: const Text('+1'),
                        ),
                        ElevatedButton(
                          // Get.find：事件里按类型取实例，不经过 context。
                          onPressed: () => Get.find<GetxCounterVm>().reset(),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            // Obx：自动追踪——闭包里读了 reactiveCount.value，赋值即重建。
            Obx(() {
              _obxBuilds++;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Obx：builder 执行 $_obxBuilds 次'
                    '（reactiveCount = ${_vm.reactiveCount.value}）',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _vm.incReactive(),
                    child: const Text('响应式 +1'),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            const Text(
              'GetxController.update() 只重建 GetBuilder；'
              'RxInt 赋值只重建 Obx',
              style: TextStyle(fontSize: 14, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 实例由 Get 全局表持有：页面销毁时显式移除，避免跨页面残留。
    Get.delete<GetxCounterVm>();
    super.dispose();
  }
}
