// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/vm/mine_vm.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { MineFeed } from '../model/app_models.js';
import { ChangeNotifier } from '../../flutter.js';

// 模型 MineVm
export class MineVm extends ChangeNotifier {
  constructor(args) {
    super(args);
    this._service = new AppService();
    this.feed = null;
    this.loading = true;
    this.error = null;
  }
  async load() {
    this.loading = true;
    this.error = null;
    this.notifyListeners();
    try {
      this.feed = await this._service.fetchMine();
      this.error = null;
    } catch (__e) {
      const e = __e;
      print("MineVm 加载失败: " + e);
      this.error = e.toString();
    }
    this.loading = false;
    this.notifyListeners();
  }
}

