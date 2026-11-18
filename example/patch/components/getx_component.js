// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/getx_component.dart 自动生成
// 重新生成：dart run build_runner build

import { GetxCounterVm } from '../model/getx_counter_vm.js';
import { Card, Colors, Column, EdgeInsets, ElevatedButton, FontWeight, MainAxisSize, Padding, SizedBox, StatefulWidget, Text, TextStyle, Wrap, WrapAlignment } from '../flutter.js';
import { Get, GetBuilder, Obx } from '../packages/get.js';

// 组件 GetXCard
export class GetXCard extends StatefulWidget {
  constructor(args) {
    super(args);
    this._vm = new GetxCounterVm();
    this._builderBuilds = 0;
    this._obxBuilds = 0;
  }
  initState() {
    super.initState();
    Get.put(this._vm);
  }
  build(context) {
    return new Card({
      "child": new Padding({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
          "value": 16
        }))),
        "child": new Column({
          "mainAxisSize": MainAxisSize.min,
          "children": [
            new GetBuilder({
              "builder": (vm) => { this._builderBuilds++;
                return new Column({
                  "mainAxisSize": MainAxisSize.min,
                  "children": [
                    new Text({
                      "style": (this.__k1 || (this.__k1 = new TextStyle({
                        "color": Colors.orange,
                        "fontSize": 20,
                        "fontWeight": FontWeight.bold
                      }))),
                      "data": "GetBuilder：builder 执行 " + this._builderBuilds + " 次" + "（count = " + vm.count + "）"
                    }),
                    new Wrap({
                      "alignment": WrapAlignment.center,
                      "spacing": 12,
                      "runSpacing": 8,
                      "children": [
                        new ElevatedButton({
                          "onPressed": () => { return vm.inc(); },
                          "child": (this.__k2 || (this.__k2 = new Text({
                            "data": "+1"
                          })))
                        }),
                        new ElevatedButton({
                          "onPressed": () => { return Get.find({ typeArguments: {"S": "GetxCounterVm"} }).reset(); },
                          "child": (this.__k3 || (this.__k3 = new Text({
                            "data": "Reset"
                          })))
                        })
                      ]
                    })
                  ]
                }); },
              "typeArguments": {"T": "GetxCounterVm"}
            }),
            (this.__k4 || (this.__k4 = new SizedBox({
              "height": 12
            }))),
            new Obx({
              "builder": () => { this._obxBuilds++;
                return new Column({
                  "mainAxisSize": MainAxisSize.min,
                  "children": [
                    new Text({
                      "style": (this.__k5 || (this.__k5 = new TextStyle({
                        "color": Colors.green,
                        "fontSize": 20,
                        "fontWeight": FontWeight.bold
                      }))),
                      "data": "Obx：builder 执行 " + this._obxBuilds + " 次" + "（reactiveCount = " + this._vm.reactiveCount.value + "）"
                    }),
                    (this.__k6 || (this.__k6 = new SizedBox({
                      "height": 8
                    }))),
                    new ElevatedButton({
                      "onPressed": () => { return this._vm.incReactive(); },
                      "child": (this.__k7 || (this.__k7 = new Text({
                        "data": "响应式 +1"
                      })))
                    })
                  ]
                }); }
            }),
            (this.__k4 || (this.__k4 = new SizedBox({
              "height": 12
            }))),
            (this.__k8 || (this.__k8 = new Text({
              "data": "GetxController.update() 只重建 GetBuilder；" + "RxInt 赋值只重建 Obx",
              "style": new TextStyle({
                "fontSize": 14,
                "color": Colors.blue
              })
            })))
          ]
        })
      })
    });
  }
  dispose() {
    Get.delete({ typeArguments: {"S": "GetxCounterVm"} });
    super.dispose();
  }
}

