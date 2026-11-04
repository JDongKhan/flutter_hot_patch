// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/vm/app_shell_vm.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { AppTabConfig } from '../model/app_models.js';
import { ChangeNotifier } from '../../flutter.js';

// 模型 AppShellVm
export class AppShellVm extends ChangeNotifier {
  constructor(args) {
    super(args);
    this._service = new AppService();
    this.tabs = [];
    this.loading = true;
    this.error = null;
  }
  async load() {
    this.loading = true;
    this.error = null;
    this.notifyListeners();
    try {
      this.tabs = await this._service.fetchAppTabs();
      this.error = null;
    } catch (e) {
      print("AppShellVm 底部配置加载失败: " + e);
      this.error = e.toString();
    }
    this.loading = false;
    this.notifyListeners();
  }
}

