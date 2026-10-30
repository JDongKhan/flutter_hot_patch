// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/drag_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, BorderRadius, BoxDecoration, Colors, Column, Container, CrossAxisAlignment, DragTarget, Draggable, Duration, EdgeInsets, FontWeight, LongPressDraggable, MainAxisSize, Opacity, Radius, Row, SizedBox, Text, TextStyle } from '../flutter.js';

// 模型 Fruit
export class Fruit {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.name = (args && args.name !== undefined) ? args.name : '';
  }
}

// 组件 DragDetail
export class DragDetail {
  static _fruits = [new Fruit({name: "苹果"}), new Fruit({name: "香蕉"}), new Fruit({name: "橙子"})];
  constructor(args) {
    this.props = args || {};
    this._drops = 0;
    this._log = "（还没有拖拽事件）";
    this._inBasketA = null;
    this._inBasketB = null;
    this._longPressDrop = null;
  }
  _accept(label, data) {
    this.setState(() => { if ((label == "篮子 A")) {   this._inBasketA = data; } else {   this._inBasketB = data; } this._drops += 1; this._log = ((data == null) ? label + " 收到空数据" : label + " 收到 " + data.name); });
  }
  _hover(label, data) {
    if ((data == null)) {
      return;
    }
    this.setState(() => { this._log = "正悬停在 " + label + "：" + data.name; });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.start,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "拖拽",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "data 是对象实例：跨桥只传身份 id，回到 JS 的 details.data 是同一个对象",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        (this.__k4 || (this.__k4 = new Text({
          "data": "Draggable → DragTarget",
          "style": new TextStyle({
            "fontSize": 13
          })
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new Row({
          "children": [
            ...(() => { var out = []; for (let f of DragDetail._fruits) { out.push.apply(out, [this._chip(f), (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 8
                  })))]); } return out; })()
          ]
        }),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 10
        }))),
        new Row({
          "children": [
            this._basket({ "label": "篮子 A", "fruit": this._inBasketA }),
            (this.__k8 || (this.__k8 = new SizedBox({
              "width": 12
            }))),
            this._basket({ "label": "篮子 B", "fruit": this._inBasketB })
          ]
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        (this.__k9 || (this.__k9 = new Text({
          "data": "LongPressDraggable（delay 400ms）",
          "style": new TextStyle({
            "fontSize": 13
          })
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new Row({
          "children": [
            new LongPressDraggable({
              "data": "长按拖我",
              "delay": (this.__k10 || (this.__k10 = new Duration({
                "milliseconds": 400
              }))),
              "onDragStarted": () => { this.setState(() => { this._log = "长按 400ms 后开始拖动"; }); },
              "feedback": this._feedbackFace("长按拖我"),
              "childWhenDragging": (this.__k11 || (this.__k11 = new Opacity({
                "child": new Text({
                  "data": "长按拖我"
                }),
                "opacity": 0.3
              }))),
              "child": (this.__k12 || (this.__k12 = new Text({
                "data": "长按拖我"
              }))),
              "model": "String"
            }),
            (this.__k8 || (this.__k8 = new SizedBox({
              "width": 12
            }))),
            this._longPressBasket()
          ]
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Container({
          "padding": (this.__k13 || (this.__k13 = EdgeInsets.all({
            "value": 8
          }))),
          "decoration": new BoxDecoration({
            "color": Colors.grey.shade100,
            "borderRadius": (this.__k14 || (this.__k14 = BorderRadius.all({
              "radius": Radius.circular({
                "radius": 6
              })
            })))
          }),
          "child": new Column({
            "crossAxisAlignment": CrossAxisAlignment.start,
            "children": [
              new Text({
                "style": (this.__k15 || (this.__k15 = new TextStyle({
                  "fontSize": 12
                }))),
                "data": "落篮次数：" + this._drops
              }),
              new Text({
                "style": (this.__k15 || (this.__k15 = new TextStyle({
                  "fontSize": 12
                }))),
                "data": "长按落点：" + (this._longPressDrop ?? "（空）")
              }),
              new Text({
                "style": (this.__k15 || (this.__k15 = new TextStyle({
                  "fontSize": 12
                }))),
                "data": "事件：" + this._log
              })
            ]
          })
        })
      ]
    });
  }
  _chip(fruit) {
    return new Draggable({
      "data": fruit,
      "onDragStarted": () => { this.setState(() => { this._log = "开始拖动 " + fruit.name; }); },
      "onDragEnd": (details) => { this.setState(() => { this._log = (details.wasAccepted ? fruit.name + " 被接收（速度 " + details.velocity.pixelsPerSecond.dy + "）" : fruit.name + " 没被接收"); }); },
      "feedback": this._feedbackFace(fruit.name),
      "childWhenDragging": new Opacity({
        "opacity": 0.3,
        "child": this._chipFace(fruit.name)
      }),
      "child": this._chipFace(fruit.name),
      "model": "Fruit"
    });
  }
  _chipFace(name) {
    return new Container({
      "padding": (this.__k16 || (this.__k16 = EdgeInsets.symmetric({
        "horizontal": 12,
        "vertical": 8
      }))),
      "decoration": new BoxDecoration({
        "color": Colors.orange.shade100,
        "borderRadius": (this.__k17 || (this.__k17 = BorderRadius.all({
          "radius": Radius.circular({
            "radius": 16
          })
        })))
      }),
      "child": new Text({
        "data": name
      })
    });
  }
  _feedbackFace(name) {
    return new Container({
      "padding": (this.__k18 || (this.__k18 = EdgeInsets.symmetric({
        "horizontal": 14,
        "vertical": 10
      }))),
      "decoration": new BoxDecoration({
        "color": Colors.orange.shade300,
        "borderRadius": (this.__k17 || (this.__k17 = BorderRadius.all({
          "radius": Radius.circular({
            "radius": 16
          })
        })))
      }),
      "child": new Text({
        "data": name
      })
    });
  }
  _basket(label, fruit) {
    return new DragTarget({
      "onAcceptWithDetails": (details) => { return this._accept(label, details.data); },
      "onMove": (details) => { return this._hover(label, details.data); },
      "builder": (context, candidate, rejected) => {
        var hovering = (candidate.length > 0);
        return new Container({
          "width": 120,
          "height": 90,
          "alignment": Alignment.center,
          "decoration": new BoxDecoration({
            "color": hovering ? Colors.green.shade100 : Colors.grey.shade100,
            "borderRadius": (this.__k19 || (this.__k19 = BorderRadius.all({
              "radius": Radius.circular({
                "radius": 8
              })
            })))
          }),
          "child": new Column({
            "mainAxisSize": MainAxisSize.min,
            "children": [
              new Text({
                "style": (this.__k20 || (this.__k20 = new TextStyle({
                  "color": Colors.black54,
                  "fontSize": 12
                }))),
                "data": label
              }),
              (this.__k1 || (this.__k1 = new SizedBox({
                "height": 4
              }))),
              new Text({
                "style": (this.__k21 || (this.__k21 = new TextStyle({
                  "fontSize": 13
                }))),
                "data": hovering ? "松手放入 " + ((candidate.first == null ? null : candidate.first.name) ?? "") : (((fruit == null) ? "（空）" : fruit.name))
              })
            ]
          })
        });
      },
      "model": "Fruit"
    });
  }
  _longPressBasket() {
    return new DragTarget({
      "onAcceptWithDetails": (details) => { this.setState(() => { this._longPressDrop = details.data; this._drops += 1; this._log = "长按落点收到 " + details.data; }); },
      "builder": (context, candidate, rejected) => {
        var hovering = (candidate.length > 0);
        return new Container({
          "width": 120,
          "height": 40,
          "alignment": Alignment.center,
          "decoration": new BoxDecoration({
            "color": hovering ? Colors.green.shade100 : Colors.grey.shade100,
            "borderRadius": (this.__k19 || (this.__k19 = BorderRadius.all({
              "radius": Radius.circular({
                "radius": 8
              })
            })))
          }),
          "child": new Text({
            "data": hovering ? "松手放入" : "长按拖到这里"
          })
        });
      },
      "model": "String"
    });
  }
}

