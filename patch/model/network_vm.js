// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/model/network_vm.dart 自动生成
// 重新生成：dart run build_runner build


// 模型 NetworkVm
export class NetworkVm extends ChangeNotifier {
  constructor() {
    super();
  }
  async loadUserInfo(params) {
    var data = await _app_host_.invoke("post", {"params": params});
    console.log("获取数据:" + __str(data));
    return data;
  }
}

