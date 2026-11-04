// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/generic_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../../model/counter_vm.js';
import { Builder, Colors, Column, CrossAxisAlignment, ElevatedButton, FontWeight, Row, SizedBox, StatefulWidget, Text, TextStyle, int } from '../../flutter.js';
import { ChangeNotifierProvider } from '../../provider.js';

// 模型 Pair
export class Pair {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.key = (args && args.key !== undefined) ? args.key : null;
    this.value = (args && args.value !== undefined) ? args.value : null;
  }
  describe() {
    return this.key + " → " + this.value;
  }
}

// 模型 GenericBox
export class GenericBox {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.value = (args && args.value !== undefined) ? args.value : null;
    this.label = (args && args.label !== undefined) ? args.label : "box";
  }
  describe() {
    return this.label + ": " + this.value;
  }
}

// 组件 GenericDetail
export class GenericDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._readCount = 0;
  }
  _snapshot(model) {
    this.setState(() => { this._readCount = model.count; });
  }
  build(context) {
    var stringBox = new GenericBox({
      "label": "string box",
      "value": "Dart 泛型是编译期事实",
      "typeArguments": [
        "String"
      ]
    });
    var intBox = new GenericBox({
      "label": "int box",
      "value": 42,
      "typeArguments": [
        "int"
      ]
    });
    var pair = new Pair({
      "key": "answer",
      "value": 42,
      "typeArguments": [
        "String",
        "int"
      ]
    });
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "泛型：类泛型 / 方法泛型",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "Dart 泛型在 JS 侧擦除：<T> 只作为 typeArguments 元信息下发，不占位置参数。",
          "style": new TextStyle({
            "fontSize": 13,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 16
        }))),
        (this.__k4 || (this.__k4 = new Text({
          "data": "类泛型",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "data": "GenericBox<String> → " + stringBox.describe()
        }),
        new Text({
          "data": "GenericBox<int> → " + intBox.describe()
        }),
        new Text({
          "data": "Pair<String, int> → " + pair.describe()
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        (this.__k6 || (this.__k6 = new Text({
          "data": "产物形态：new GenericBox({value: …, typeArguments: ['String']})；" + "new Pair({key: …, value: …, typeArguments: ['String', 'int']})",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black45
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 16
        }))),
        (this.__k7 || (this.__k7 = new Text({
          "data": "方法泛型",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        (this.__k8 || (this.__k8 = new Text({
          "data": "context.watch<T>() / context.read<T>()：零位置实参的泛型方法，" + "T 并入调用尾参对象，运行时按类型名定位作用域。",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black45
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new ChangeNotifierProvider({
          "create": (_) => { return new CounterVm(); },
          "child": new Builder({
            "builder": (context) => {
              var model = context.watch({ typeArguments: ["CounterVm"] });
              return new Column({
                "crossAxisAlignment": CrossAxisAlignment.stretch,
                "children": [
                  new Text({
                    "style": (this.__k9 || (this.__k9 = new TextStyle({
                      "color": Colors.deepOrange,
                      "fontSize": 16,
                      "fontWeight": FontWeight.bold
                    }))),
                    "data": "context.watch<CounterVm>() → count = " + model.count
                  }),
                  (this.__k1 || (this.__k1 = new SizedBox({
                    "height": 8
                  }))),
                  new Row({
                    "children": [
                      new ElevatedButton({
                        "onPressed": (...__a) => model.inc(...__a),
                        "child": (this.__k10 || (this.__k10 = new Text({
                          "data": "+1"
                        })))
                      }),
                      (this.__k11 || (this.__k11 = new SizedBox({
                        "width": 12
                      }))),
                      new ElevatedButton({
                        "onPressed": () => { return this._snapshot(context.read({ typeArguments: ["CounterVm"] })); },
                        "child": (this.__k12 || (this.__k12 = new Text({
                          "data": "read 快照"
                        })))
                      })
                    ]
                  }),
                  (this.__k5 || (this.__k5 = new SizedBox({
                    "height": 6
                  }))),
                  new Text({
                    "data": "context.read<CounterVm>() 快照 = " + this._readCount
                  })
                ]
              });
            }
          }),
          "typeArguments": [
            "CounterVm"
          ]
        })
      ]
    });
  }
}

