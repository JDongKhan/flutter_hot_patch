// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/listenable_demo.dart 自动生成
// 重新生成：dart run build_runner build


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

export class ListenableDemo {
  constructor() {
    this._model = new CounterModel({});
  }
  _inc() { this._model.inc(); }
  _reset() { this._model.reset(); }
  build() {
    return {
      "type": "Column",
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "ListenableBuilder 局部重建"
          }
        },
        {
          "type": "ListenableBuilder",
          "props": {
            "listenable": "_model",
            "builder": "_lbBuilder0"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 8
          }
        },
        {
          "type": "Row",
          "children": [
            {
              "type": "Button",
              "props": {
                "kind": "elevated",
                "label": "+1",
                "event": "_inc"
              }
            },
            {
              "type": "Button",
              "props": {
                "kind": "elevated",
                "label": "Reset",
                "event": "_reset"
              }
            }
          ]
        }
      ]
    };
  }
  _lbBuilder0() {
      return {
      "type": "Text",
      "props": {
        "data": "n = " + this._model.n
      }
    };
  }
}

