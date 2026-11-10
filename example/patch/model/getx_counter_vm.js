// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/model/getx_counter_vm.dart 自动生成
// 重新生成：dart run build_runner build

import { GetxController, RxInt } from '../packages/get.js';

// 模型 GetxCounterVm
export class GetxCounterVm extends GetxController {
  constructor(args) {
    super(args);
    this.count = 0;
    this.reactiveCount = new RxInt({initial: 0});
  }
  inc() {
    this.count += 1;
    if ((this.count >= 10)) {
      this.count = 0;
    }
    this.update();
  }
  reset() {
    while ((this.count > 0)) {
      this.count += -1;
    }
    this.update();
  }
  incReactive() {
    this.reactiveCount.value += 1;
    if ((this.reactiveCount.value >= 10)) {
      this.reactiveCount.value = 0;
    }
  }
}

