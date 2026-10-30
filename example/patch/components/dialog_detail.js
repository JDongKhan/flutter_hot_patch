// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/dialog_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { AlertDialog, BorderRadius, BoxDecoration, Colors, Column, Container, CrossAxisAlignment, CupertinoActionSheet, CupertinoActionSheetAction, CupertinoAlertDialog, CupertinoDialogAction, Dialog, EdgeInsets, FilledButton, FontWeight, MainAxisSize, Navigator, OutlinedButton, Padding, Radius, SafeArea, SizedBox, Text, TextButton, TextStyle, Wrap, showAdaptiveDialog, showCupertinoDialog, showCupertinoModalPopup, showDialog, showGeneralDialog, showModalBottomSheet } from '../flutter.js';

// 组件 DialogDetail
export class DialogDetail {
  constructor(args) {
    this.props = args || {};
    this._last = "（还没有关闭过弹层）";
    this._opens = 0;
  }
  _openMaterial() {
    this.setState(() => { this._opens += 1; });
    showDialog({"context": this.context, "builder": (ctx) => { return new DialogContent({}); }}).then((v) => { return this._record("showDialog", v); });
  }
  _openNonDismissible() {
    this.setState(() => { this._opens += 1; });
    showDialog({"context": this.context, "barrierDismissible": false, "builder": (ctx) => { return new DialogContent({
          "barrierDismissible": false
        }); }}).then((v) => { return this._record("showDialog(barrierDismissible: false)", v); });
  }
  _openSheet() {
    this.setState(() => { this._opens += 1; });
    showModalBottomSheet({"context": this.context, "showDragHandle": true, "builder": (ctx) => { return new SheetContent({}); }}).then((v) => { return this._record("showModalBottomSheet", v); });
  }
  _openCupertino() {
    this.setState(() => { this._opens += 1; });
    showCupertinoDialog({"context": this.context, "builder": (ctx) => { return new CupertinoDialogContent({}); }}).then((v) => { return this._record("showCupertinoDialog", v); });
  }
  _openAdaptive() {
    this.setState(() => { this._opens += 1; });
    showAdaptiveDialog({"context": this.context, "builder": (ctx) => { return new CupertinoDialogContent({}); }}).then((v) => { return this._record("showAdaptiveDialog", v); });
  }
  _openCupertinoSheet() {
    this.setState(() => { this._opens += 1; });
    showCupertinoModalPopup({"context": this.context, "builder": (ctx) => { return new ActionSheetContent({}); }}).then((v) => { return this._record("showCupertinoModalPopup", v); });
  }
  _openGeneral() {
    this.setState(() => { this._opens += 1; });
    showGeneralDialog({"context": this.context, "barrierDismissible": true, "barrierLabel": "关闭", "barrierColor": Colors.black54, "pageBuilder": (ctx, animation, secondaryAnimation) => { return (this.__k0 || (this.__k0 = new GeneralDialogContent({}))); }}).then((v) => { return this._record("showGeneralDialog", v); });
  }
  _record(label, v) {
    this.setState(() => { this._last = ((v == null) ? label + " → null（取消 / 遮罩 / 返回键）" : label + " → " + v); });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.start,
      "children": [
        (this.__k1 || (this.__k1 = new Text({
          "data": "命令式弹层",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 4
        }))),
        (this.__k3 || (this.__k3 = new Text({
          "data": "每种弹层的 builder 都在 JS 侧建树并挂到独立根；返回值经 Future 回传",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k5 || (this.__k5 = new Text({
          "data": "showDialog / AlertDialog",
          "style": new TextStyle({
            "fontSize": 13
          })
        }))),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 4
        }))),
        new Wrap({
          "spacing": 8,
          "runSpacing": 8,
          "children": [
            new FilledButton({
              "onPressed": this.__bindFn(0, [], () => this._openMaterial()),
              "child": (this.__k6 || (this.__k6 = new Text({
                "data": "打开"
              })))
            }),
            new OutlinedButton({
              "onPressed": this.__bindFn(1, [], () => this._openNonDismissible()),
              "child": (this.__k7 || (this.__k7 = new Text({
                "data": "打开（点遮罩不关）"
              })))
            })
          ]
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k8 || (this.__k8 = new Text({
          "data": "showModalBottomSheet",
          "style": new TextStyle({
            "fontSize": 13
          })
        }))),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 4
        }))),
        new OutlinedButton({
          "onPressed": this.__bindFn(2, [], () => this._openSheet()),
          "child": (this.__k9 || (this.__k9 = new Text({
            "data": "打开底部弹层"
          })))
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k10 || (this.__k10 = new Text({
          "data": "Cupertino 弹窗 / 动作面板",
          "style": new TextStyle({
            "fontSize": 13
          })
        }))),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 4
        }))),
        new Wrap({
          "spacing": 8,
          "runSpacing": 8,
          "children": [
            new OutlinedButton({
              "onPressed": this.__bindFn(3, [], () => this._openCupertino()),
              "child": (this.__k11 || (this.__k11 = new Text({
                "data": "showCupertinoDialog"
              })))
            }),
            new OutlinedButton({
              "onPressed": this.__bindFn(4, [], () => this._openAdaptive()),
              "child": (this.__k12 || (this.__k12 = new Text({
                "data": "showAdaptiveDialog"
              })))
            }),
            new OutlinedButton({
              "onPressed": this.__bindFn(5, [], () => this._openCupertinoSheet()),
              "child": (this.__k13 || (this.__k13 = new Text({
                "data": "showCupertinoModalPopup"
              })))
            })
          ]
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k14 || (this.__k14 = new Text({
          "data": "showGeneralDialog",
          "style": new TextStyle({
            "fontSize": 13
          })
        }))),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 4
        }))),
        new OutlinedButton({
          "onPressed": this.__bindFn(6, [], () => this._openGeneral()),
          "child": (this.__k15 || (this.__k15 = new Text({
            "data": "打开自定义弹窗"
          })))
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        new Container({
          "padding": (this.__k16 || (this.__k16 = EdgeInsets.all({
            "value": 8
          }))),
          "decoration": new BoxDecoration({
            "color": Colors.grey.shade100,
            "borderRadius": (this.__k17 || (this.__k17 = BorderRadius.all({
              "radius": Radius.circular({
                "radius": 6
              })
            })))
          }),
          "child": new Column({
            "crossAxisAlignment": CrossAxisAlignment.start,
            "children": [
              new Text({
                "style": (this.__k18 || (this.__k18 = new TextStyle({
                  "fontSize": 12
                }))),
                "data": "打开次数：" + this._opens
              }),
              new Text({
                "style": (this.__k18 || (this.__k18 = new TextStyle({
                  "fontSize": 12
                }))),
                "data": "最近结果：" + this._last
              })
            ]
          })
        })
      ]
    });
  }
}

// 组件 GeneralDialogContent
export class GeneralDialogContent {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new Dialog({
      "child": new Padding({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
          "value": 16
        }))),
        "child": new Column({
          "mainAxisSize": MainAxisSize.min,
          "crossAxisAlignment": CrossAxisAlignment.start,
          "children": [
            (this.__k1 || (this.__k1 = new Text({
              "data": "showGeneralDialog",
              "style": new TextStyle({
                "fontWeight": FontWeight.bold
              })
            }))),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            (this.__k3 || (this.__k3 = new Text({
              "data": "pageBuilder 建树、barrierLabel / barrierColor 由宿主还原",
              "style": new TextStyle({
                "fontSize": 12,
                "color": Colors.black54
              })
            }))),
            (this.__k4 || (this.__k4 = new SizedBox({
              "height": 12
            }))),
            new Wrap({
              "spacing": 8,
              "runSpacing": 8,
              "children": [
                new FilledButton({
                  "onPressed": this.__bindFn(0, [], () => Navigator.of(this.context).pop("自定义确定")),
                  "child": (this.__k5 || (this.__k5 = new Text({
                    "data": "确定"
                  })))
                }),
                new OutlinedButton({
                  "onPressed": this.__bindFn(1, [], () => Navigator.of(this.context).pop(null)),
                  "child": (this.__k6 || (this.__k6 = new Text({
                    "data": "取消"
                  })))
                })
              ]
            })
          ]
        })
      })
    });
  }
}

// 组件 ActionSheetContent
export class ActionSheetContent {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new CupertinoActionSheet({
      "title": (this.__k0 || (this.__k0 = new Text({
        "data": "CupertinoActionSheet"
      }))),
      "message": (this.__k1 || (this.__k1 = new Text({
        "data": "由 showCupertinoModalPopup 承载，从底部弹出"
      }))),
      "actions": [
        new CupertinoActionSheetAction({
          "onPressed": this.__bindFn(0, [], () => Navigator.of(this.context).pop("选项 A")),
          "child": (this.__k2 || (this.__k2 = new Text({
            "data": "选项 A"
          })))
        }),
        new CupertinoActionSheetAction({
          "isDestructiveAction": true,
          "onPressed": this.__bindFn(1, [], () => Navigator.of(this.context).pop("删除")),
          "child": (this.__k3 || (this.__k3 = new Text({
            "data": "删除"
          })))
        })
      ],
      "cancelButton": new CupertinoActionSheetAction({
        "onPressed": this.__bindFn(2, [], () => Navigator.of(this.context).pop(null)),
        "child": (this.__k4 || (this.__k4 = new Text({
          "data": "取消"
        })))
      })
    });
  }
}

// 组件 CupertinoDialogContent
export class CupertinoDialogContent {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new CupertinoAlertDialog({
      "title": (this.__k0 || (this.__k0 = new Text({
        "data": "Cupertino 弹窗"
      }))),
      "content": (this.__k1 || (this.__k1 = new Text({
        "data": "CupertinoAlertDialog 的树也在 JS 侧建好，宿主只负责 push 路由",
        "style": new TextStyle({
          "fontSize": 12
        })
      }))),
      "actions": [
        new CupertinoDialogAction({
          "onPressed": this.__bindFn(0, [], () => Navigator.of(this.context).pop(null)),
          "child": (this.__k2 || (this.__k2 = new Text({
            "data": "取消"
          })))
        }),
        new CupertinoDialogAction({
          "isDefaultAction": true,
          "onPressed": this.__bindFn(1, [], () => Navigator.of(this.context).pop("iOS 风格确定")),
          "child": (this.__k3 || (this.__k3 = new Text({
            "data": "确定"
          })))
        })
      ]
    });
  }
}

// 组件 SheetContent
export class SheetContent {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new SafeArea({
      "child": new Padding({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.fromLTRB({
          "bottom": 16,
          "left": 16,
          "right": 16,
          "top": 0
        }))),
        "child": new Column({
          "mainAxisSize": MainAxisSize.min,
          "crossAxisAlignment": CrossAxisAlignment.start,
          "children": [
            (this.__k1 || (this.__k1 = new Text({
              "data": "底部弹层",
              "style": new TextStyle({
                "fontWeight": FontWeight.bold
              })
            }))),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            (this.__k3 || (this.__k3 = new Text({
              "data": "showModalBottomSheet 的内容同样是 JS 独立根，可拖拽 / 点遮罩关闭",
              "style": new TextStyle({
                "fontSize": 12,
                "color": Colors.black54
              })
            }))),
            (this.__k4 || (this.__k4 = new SizedBox({
              "height": 12
            }))),
            new Wrap({
              "spacing": 8,
              "runSpacing": 8,
              "children": [
                new FilledButton({
                  "onPressed": this.__bindFn(0, [], () => Navigator.of(this.context).pop("底部确定")),
                  "child": (this.__k5 || (this.__k5 = new Text({
                    "data": "确定"
                  })))
                }),
                new OutlinedButton({
                  "onPressed": this.__bindFn(1, [], () => Navigator.of(this.context).pop(null)),
                  "child": (this.__k6 || (this.__k6 = new Text({
                    "data": "取消"
                  })))
                })
              ]
            })
          ]
        })
      })
    });
  }
}

// 组件 DialogContent
export class DialogContent {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
    this._count = 0;
  }
  __applyProps(args) {
    this.barrierDismissible = (args && args.barrierDismissible !== undefined) ? args.barrierDismissible : true;
  }
  build(context) {
    return new AlertDialog({
      "title": (this.__k0 || (this.__k0 = new Text({
        "data": "JS 弹层"
      }))),
      "content": new Column({
        "mainAxisSize": MainAxisSize.min,
        "crossAxisAlignment": CrossAxisAlignment.start,
        "children": [
          (this.__k1 || (this.__k1 = new Text({
            "data": "这个 AlertDialog 的整棵树在 JS 侧构建，「+1」只重建本弹层",
            "style": new TextStyle({
              "fontSize": 12
            })
          }))),
          (this.__k2 || (this.__k2 = new SizedBox({
            "height": 8
          }))),
          new Text({
            "style": (this.__k3 || (this.__k3 = new TextStyle({
              "fontSize": 13
            }))),
            "data": "计数：" + this._count
          }),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 4
          }))),
          new Text({
            "style": (this.__k5 || (this.__k5 = new TextStyle({
              "color": Colors.black54,
              "fontSize": 12
            }))),
            "data": this.barrierDismissible ? "barrierDismissible: true" : "barrierDismissible: false"
          })
        ]
      }),
      "actions": [
        new TextButton({
          "onPressed": this.__bindFn(0, [], () => this.setState(() => {
            this._count += 1;
          })),
          "child": (this.__k6 || (this.__k6 = new Text({
            "data": "+1"
          })))
        }),
        new TextButton({
          "onPressed": this.__bindFn(1, [], () => Navigator.of(this.context).pop(null)),
          "child": (this.__k7 || (this.__k7 = new Text({
            "data": "取消"
          })))
        }),
        new TextButton({
          "onPressed": this.__bindFn(2, [], () => Navigator.of(this.context).pop("确定，计数 = " + this._count)),
          "child": (this.__k8 || (this.__k8 = new Text({
            "data": "确定"
          })))
        })
      ]
    });
  }
}

