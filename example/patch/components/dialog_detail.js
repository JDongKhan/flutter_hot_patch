// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/dialog_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { AlertDialog, Column, Container, FilledButton, OutlinedButton, SizedBox, Text, TextButton, Wrap } from '../flutter.js';

// 组件 DialogDetail
export class DialogDetail {
  constructor(args) {
    this.props = args || {};
    this._last = "（还没有关闭过弹层）";
    this._opens = 0;
  }
  _open(dismissible) {
    this.setState(() => { this._opens += 1; });
    showDialog({"context": this.context, "barrierDismissible": dismissible, "builder": (ctx) => { return new DialogContent({
          "dismissible": dismissible
        }); }}).then((v) => { return this._record(v); });
  }
  _record(v) {
    this.setState(() => { this._last = ((v == null) ? "已关闭：null（取消 / 遮罩 / 返回键）" : "已关闭：" + v); });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "start",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "showDialog",
          "style": {
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "弹层内容由 JS 侧 builder 建树并挂在独立根上；返回值经 Future 回传",
          "style": {
            "color": Colors.black54,
            "fontSize": 12
          }
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Wrap({
          "spacing": 8,
          "runSpacing": 8,
          "children": [
            new FilledButton({
              "onPressed": this.__bindFn(0, [], () => this._open(true)),
              "child": (this.__k4 || (this.__k4 = new Text({
                "data": "打开 AlertDialog"
              })))
            }),
            new OutlinedButton({
              "onPressed": this.__bindFn(1, [], () => this._open(false)),
              "child": (this.__k5 || (this.__k5 = new Text({
                "data": "打开（点遮罩不关）"
              })))
            })
          ]
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Container({
          "padding": {
            "left": 8.0,
            "top": 8.0,
            "right": 8.0,
            "bottom": 8.0
          },
          "decoration": {
            "color": Colors.grey.shade100,
            "borderRadius": {
              "radius": 6.0
            }
          },
          "child": new Column({
            "crossAxisAlignment": "start",
            "children": [
              new Text({
                "style": {
                  "fontSize": 12
                },
                "data": "打开次数：" + this._opens
              }),
              new Text({
                "style": {
                  "fontSize": 12
                },
                "data": "最近结果：" + this._last
              })
            ]
          })
        })
      ]
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
    this.dismissible = (args && args.dismissible !== undefined) ? args.dismissible : false;
  }
  build(context) {
    return new AlertDialog({
      "title": (this.__k0 || (this.__k0 = new Text({
        "data": "JS 弹层"
      }))),
      "content": new Column({
        "mainAxisSize": "min",
        "crossAxisAlignment": "start",
        "children": [
          (this.__k1 || (this.__k1 = new Text({
            "data": "这个 AlertDialog 的整棵树在 JS 侧构建，「+1」只重建本弹层",
            "style": {
              "fontSize": 12
            }
          }))),
          (this.__k2 || (this.__k2 = new SizedBox({
            "height": 8
          }))),
          new Text({
            "style": {
              "fontSize": 13
            },
            "data": "计数：" + this._count
          }),
          (this.__k3 || (this.__k3 = new SizedBox({
            "height": 4
          }))),
          new Text({
            "style": {
              "fontSize": 12,
              "color": Colors.black54
            },
            "data": this.dismissible ? "barrierDismissible: true" : "barrierDismissible: false"
          })
        ]
      }),
      "actions": [
        new TextButton({
          "onPressed": this.__bindFn(0, [], () => this.setState(() => {
            this._count += 1;
          })),
          "child": (this.__k4 || (this.__k4 = new Text({
            "data": "+1"
          })))
        }),
        new TextButton({
          "onPressed": this.__bindFn(1, [], () => Navigator.of(this.context).pop(null)),
          "child": (this.__k5 || (this.__k5 = new Text({
            "data": "取消"
          })))
        }),
        new TextButton({
          "onPressed": this.__bindFn(2, [], () => Navigator.of(this.context).pop("确定，计数 = " + this._count)),
          "child": (this.__k6 || (this.__k6 = new Text({
            "data": "确定"
          })))
        })
      ]
    });
  }
}

