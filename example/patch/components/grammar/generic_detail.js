// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/generic_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../../model/counter_vm.js';
import { ArgumentError, Builder, Colors, Column, CrossAxisAlignment, ElevatedButton, FontWeight, Row, SizedBox, StatefulWidget, Text, TextStyle, double, int, num } from '../../flutter.js';
import { ChangeNotifierProvider } from '../../provider.js';

// 模型 Pair
export class Pair {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.key = (args && args.key !== undefined) ? args.key : null;
    this.value = (args && args.value !== undefined) ? args.value : null;
    this.__ta = (args && args.typeArguments) || {};
  }
  describe() {
    return this.key + " → " + this.value;
  }
}

// 模型 TypeCodec
export class TypeCodec {
  constructor(args) {
    this.__ta = (args && args.typeArguments) || {};
  }
  parse(raw) {
    if ((this.__ta["T"] == "String")) {
      return raw;
    }
    if ((this.__ta["T"] == "int")) {
      return int.tryParse(raw);
    }
    if ((this.__ta["T"] == "double")) {
      return double.tryParse(raw);
    }
    if ((this.__ta["T"] == "num")) {
      return num.tryParse(raw);
    }
    throw new ArgumentError({message: "不支持的泛型类型"});
  }
  getType() {
    return this.__ta["T"].toString();
  }
  getEType() {
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
    var stringCodec = new TypeCodec({
      "typeArguments": {"T": "String"}
    });
    var intCodec = new TypeCodec({
      "typeArguments": {"T": "int"}
    });
    var doubleCodec = new TypeCodec({
      "typeArguments": {"T": "double"}
    });
    var pair = new Pair({
      "key": "answer",
      "value": 42,
      "typeArguments": {"K": "String", "V": "int"}
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
          "data": "TypeCodec<String>().parse(\"123\") → " + stringCodec.parse("123")
        }),
        new Text({
          "data": "TypeCodec<int>().parse(\"42\") → " + intCodec.parse("42")
        }),
        new Text({
          "data": "TypeCodec<double>().parse(\"3.14\") → " + doubleCodec.parse("3.14")
        }),
        new Text({
          "data": "Pair<String, int> → " + pair.describe()
        }),
        new Text({
          "data": "stringCodec.getType() → " + stringCodec.getType()
        }),
        new Text({
          "data": "intCodec.getType() → " + intCodec.getType()
        }),
        new Text({
          "data": "doubleCodec.getType() → " + doubleCodec.getType()
        }),
        new Text({
          "data": "stringCodec.getEType() → " + stringCodec.getEType({ typeArguments: {"E": "String"} })
        }),
        new Text({
          "data": "intCodec.getEType() → " + intCodec.getEType({ typeArguments: {"E": "int"} })
        }),
        new Text({
          "data": "doubleCodec.getEType() → " + doubleCodec.getEType({ typeArguments: {"E": "double"} })
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        (this.__k6 || (this.__k6 = new Text({
          "data": "产物形态：new TypeCodec({typeArguments: {T: \"String\"}})；" + "方法体 T → this.__ta[\"T\"]，T == String → this.__ta[\"T\"] == \"String\"。",
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
              var model = context.watch({ typeArguments: {"T": "CounterVm"} });
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
                        "onPressed": () => { return this._snapshot(context.read({ typeArguments: {"0": "CounterVm"} })); },
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
          "typeArguments": {"T": "CounterVm"}
        })
      ]
    });
  }
}

