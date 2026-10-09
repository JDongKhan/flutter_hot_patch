// GENERATED CODE - DO NOT EDIT
// 模型模块：由 ui_component_generator 从 lib/model/counter_model.dart 生成
// export class / export const 供组件产物 import（运行时按相对路径加载）

// 模型 CounterModel
export class CounterModel extends ChangeNotifier {
  constructor(args) {
    super();
    this._count = 0;
  }
  get count() { return this._count; }
  inc() { this._count += 1; this.notifyListeners(); }
  reset() { this._count = 0; this.notifyListeners(); }
  async getUserName() { return "22"; }
}
