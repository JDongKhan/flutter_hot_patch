// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/null_safety_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { TaskItem } from 'constructor_detail.js';
import { Column, CrossAxisAlignment, ElevatedButton, FontWeight, OutlinedButton, Row, SizedBox, StatefulWidget, Text, TextStyle } from '../flutter.js';

// 组件 NullSafetyDetail
export class NullSafetyDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._task = null;
    this._note = null;
    this._scores = null;
    this._upper = null;
    this._first = null;
    this._second = null;
    this._cell = null;
    this._chain = null;
  }
  _run() {
    this.setState(() => {
      this._task = TaskItem.highlight({title: "阅读"});
      this._note = "hello";
      this._scores = [3, 1, 4];
      this._upper = this._note?.toUpperCase();
      this._first = this._scores?.[0];
      ((__t) => { if (__t != null) __t[1] = 1; })(this._scores);
      this._second = this._scores?.[1];
      ((__t) => { if (__t != null) __t.scores = [0, 0]; })(this._task);
      ((__t) => { if (__t != null) __t[1] = 9; })(this._task?.scores);
      this._cell = this._task?.scores?.[1];
      this._chain = this._task?.level.name;
    });
  }
  _clear() {
    this.setState(() => {
      this._task = null;
      this._note = null;
      this._scores = null;
      this._upper = this._note?.toUpperCase();
      this._first = this._scores?.[0];
      ((__t) => { if (__t != null) __t[1] = 1; })(this._scores);
      this._second = this._scores?.[1];
      ((__t) => { if (__t != null) __t[1] = 9; })(this._task?.scores);
      this._cell = this._task?.scores?.[1];
      this._chain = this._task?.level.name;
    });
  }
  build(context) {
    const task = this._task;
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "空安全：?. / ?[] / 空安全赋值 / 多层链",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "命名构造：" + ((__nn(this._task) == null) ? "(点击按钮生成)" : this._task.describe())
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "空安全调用：_note?.toUpperCase() = " + (this._upper ?? "null")
        }),
        new Text({
          "data": "空安全下标：_scores?[0] = " + (this._first ?? "null")
        }),
        new Text({
          "data": "空安全赋值：_scores?[1] = 1 → " + (this._second ?? "null")
        }),
        new Text({
          "data": "多层空安全赋值：_task?.scores?[1] = 9 → " + (this._cell ?? "null")
        }),
        new Text({
          "data": "空安全链：_task?.level.name = " + (this._chain ?? "null")
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        new Row({
          "children": [
            new ElevatedButton({
              "onPressed": () => this._run(),
              "child": (this.__k3 || (this.__k3 = new Text({
                "data": "生成"
              })))
            }),
            (this.__k4 || (this.__k4 = new SizedBox({
              "width": 12
            }))),
            new OutlinedButton({
              "onPressed": () => this._clear(),
              "child": (this.__k5 || (this.__k5 = new Text({
                "data": "置空"
              })))
            })
          ]
        })
      ]
    });
  }
}

