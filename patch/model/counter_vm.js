// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/model/counter_vm.dart 自动生成
// 重新生成：dart run build_runner build

import { BannerCard } from '../components/banner_component.js';
import { __h } from '../flutter.js';

// 模型 CounterVm
export class CounterVm extends ChangeNotifier {
  constructor() {
    super();
    this._count = 0;
  }
  get count() { return this._count; }
  async inc() {
    this._count += 1;
    this.notifyListeners();
  }
  reset() {
    this._count = 0;
    this.notifyListeners();
  }
  async getUserName() {
    return "22";
  }
  buildText() {
    return __h(BannerCard, {});
  }
}

