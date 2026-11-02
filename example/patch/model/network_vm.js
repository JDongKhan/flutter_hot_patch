// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/model/network_vm.dart 自动生成
// 重新生成：dart run build_runner build

import { ChangeNotifier } from '../flutter.js';

// 模型 NetworkVm
export class NetworkVm extends ChangeNotifier {
  constructor(args) {
    super(args);
  }
  async loadUserInfo(params) {
    var data = await _app_host_.invoke("post", {"url": "loadUserInfo", "params": params});
    print("获取数据:" + data);
    return data;
  }
}

