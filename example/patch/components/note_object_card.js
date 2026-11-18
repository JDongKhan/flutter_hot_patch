// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/note_object_card.dart 自动生成
// 重新生成：dart run build_runner build

import { Card, Color, Colors, Column, CrossAxisAlignment, EdgeInsets, ElevatedButton, FontWeight, MainAxisSize, Padding, SizedBox, StatefulWidget, Text, TextStyle } from '../flutter.js';
import { NoteObject } from '../packages/NoteObject.js';

// 组件 NoteObjectCard
export class NoteObjectCard extends StatefulWidget {
  constructor(args) {
    super(args);
    this._note = new NoteObject({title: "演示对象"});
    this._greet = "尚未调用";
    this._bump = "—";
    this._title = "—";
  }
  async _run() {
    this.setState(() => {
      this._greet = "调用中…";
    });
    try {
      const g = await this._note.greet("豆包");
      const b = await this._note.bump();
      const t = await this._note.readTitle();
      this.setState(() => {
        this._greet = "" + g;
        this._bump = "" + b;
        this._title = "" + t;
      });
    } catch (__e) {
      const e = __e;
      this.setState(() => {
        this._greet = "失败：" + e;
      });
    }
  }
  build(context) {
    return new Card({
      "child": new Padding({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
          "value": 16
        }))),
        "child": new Column({
          "mainAxisSize": MainAxisSize.min,
          "crossAxisAlignment": CrossAxisAlignment.start,
          "children": [
            new Text({
              "style": new TextStyle({
                "fontSize": 15,
                "fontWeight": FontWeight.bold,
                "color": new Color({
                  "value": 0xFF5E35B1
                })
              }),
              "data": "new NoteObject(...) → js/NoteObject.js → obj/NoteObject"
            }),
            new SizedBox({
              "height": 8
            }),
            new Text({
              "style": new TextStyle({
                "fontSize": 13
              }),
              "data": "greet(\"豆包\")：" + this._greet
            }),
            new SizedBox({
              "height": 4
            }),
            new Text({
              "style": new TextStyle({
                "fontSize": 13
              }),
              "data": "bump()：" + this._bump
            }),
            new SizedBox({
              "height": 4
            }),
            new Text({
              "style": new TextStyle({
                "fontSize": 13
              }),
              "data": "readTitle()：" + this._title
            }),
            new SizedBox({
              "height": 10
            }),
            new ElevatedButton({
              "onPressed": () => this._run(),
              "child": new Text({
                "data": "调用宿主实例的三个成员"
              })
            }),
            new SizedBox({
              "height": 8
            }),
            new Text({
              "style": new TextStyle({
                "fontSize": 12,
                "color": Colors.grey
              }),
              "data": "JS 侧每一次成员调用都是一次 jsHandle op（call / get / set），" + "宿主按成员名分派到真实实例——不是 JS 里另建一份状态。"
            })
          ]
        })
      })
    });
  }
}

