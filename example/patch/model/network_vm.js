// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/model/network_vm.dart 自动生成
// 重新生成：dart run build_runner build

import { Network } from '../hot_module_base.js';
import { ChangeNotifier } from '../flutter.js';

// 模型 NetworkVm
export class NetworkVm extends ChangeNotifier {
  constructor(args) {
    super(args);
  }
  async loadUserInfo(__o) {
    var params = (__o && __o.params !== undefined) ? __o.params : null;
    var data = await Network.post({ "url": "loadUserInfo", "params": params });
    print("获取数据:" + data);
    return data;
  }
}

