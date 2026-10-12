// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/model/network_vm.dart 自动生成
// 重新生成：dart run build_runner build


// 模型 NetworkVm
export class NetworkVm extends ChangeNotifier {
  constructor() {
    super();
  }
  async loadUserInfo(params) { var data = await __jsui.host("post", {"params": params}); console.log("获取数据:" + data); return data; }
}

