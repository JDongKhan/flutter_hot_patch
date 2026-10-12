// GENERATED CODE - DO NOT EDIT
// 模型模块：由 ui_component_generator 从 lib/model/network_vm.dart 生成
// export class / export const 供组件产物 import（运行时按相对路径加载）

// 模型 NetworkVm
export class NetworkVm extends ChangeNotifier {
  constructor() {
    super();
  }
  async loadUserInfo(params) { var data = await __jsui.host("post", {"params": params}); console.log("获取数据:" + data); return data; }
}
