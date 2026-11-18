// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/app/vm/user_center_vm.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { UserProfile } from '../model/app_models.js';
import { ChangeNotifier } from '../../flutter.js';

// 模型 UserCenterVm
export class UserCenterVm extends ChangeNotifier {
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
      this.feed = await this._service.fetchUserProfile();
      this.error = null;
    } catch (__e) {
      const e = __e;
      print("UserCenterVm 加载失败: " + e);
      this.error = e.toString();
    }
    this.loading = false;
    this.notifyListeners();
  }
}

