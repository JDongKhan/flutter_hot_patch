// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/listenable_demo.dart 自动生成
// 重新生成：dart run build_runner build

import { Button, Column, ListenableBuilder, Row, SizedBox, Text, __h } from '../flutter.js';

// 模型 CounterModel（同文件，仅本产物内可见）
class CounterModel extends ChangeNotifier {
  constructor(args) {
    super();
    this._n = 0;
  }
  get n() { return this._n; }
  inc() { this._n += 1; this.notifyListeners(); }
  reset() { this._n = 0; this.notifyListeners(); }
}

class ListenableDemoComponent {
  constructor() {
    this._model = new CounterModel({});
  }
  _inc() { this._model.inc(); }
  _reset() { this._model.reset(); }
  build() {
    return Column({}, [
        Text({
            "data": "ListenableBuilder 局部重建"
          }),
        ListenableBuilder({
            "listenable": "_model",
            "builder": "_lbBuilder0"
          }),
        SizedBox({
            "height": 8
          }),
        Row({}, [
            Button({
                "kind": "elevated",
                "label": "+1",
                "event": this.__bind("_inc")
              }),
            Button({
                "kind": "elevated",
                "label": "Reset",
                "event": this.__bind("_reset")
              })
          ])
      ]);
  }
  _lbBuilder0() {
      return Text({
        "data": "n = " + this._model.n
      });
  }
}
export function ListenableDemo(props, children) {
  return __h(ListenableDemoComponent, props, children);
}

