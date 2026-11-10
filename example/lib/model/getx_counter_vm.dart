import 'package:get/get.dart';

/// GetX 控制器：`GetxController.update()` 手动通知，`RxInt` 供 `Obx` 自动追踪。
///
/// JS 侧实现见宿主 `js/get.js`（构建拷贝到 `patch/packages/get.js`）：
/// - `count` 是普通字段，改动后必须调 `update()` 才会重建 `GetBuilder`；
/// - `reactiveCount` 是响应式变量，`Obx` 闭包内读 `.value` 即自动建立依赖。
class GetxCounterVm extends GetxController {
  int count = 0;

  final reactiveCount = RxInt(0);

  void inc() {
    count++;
    if (count >= 10) {
      count = 0;
    }
    update();
  }

  void reset() {
    while (count > 0) {
      count--;
    }
    update();
  }

  void incReactive() {
    reactiveCount.value++;
    if (reactiveCount.value >= 10) {
      reactiveCount.value = 0;
    }
  }
}
