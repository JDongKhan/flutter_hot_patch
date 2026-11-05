// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/syntax_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, CrossAxisAlignment, EdgeInsets, ElevatedButton, MainAxisSize, OutlinedButton, Padding, Row, SizedBox, StatefulWidget, Text } from '../../flutter.js';

export const TaskLevel = (function () { const __values = []; function __mk(name, index) { return { name: name, index: index, toString: function () { return "TaskLevel." + name; } }; } const low = __mk("low", 0); __values.push(low); const medium = __mk("medium", 1); __values.push(medium); const high = __mk("high", 2); __values.push(high); return { low: low, medium: medium, high: high, values: __values }; })();

// 模型 TaskItem
export class TaskItem {
  constructor(args) {
    this.__applyProps(args);
    this.score = 0;
    this.level = null;
  }
  __applyProps(args) {
    this.title = (args && args.title !== undefined) ? args.title : '';
  }
  describe() {
    return this.title + " · " + this.level.name + " · " + this.score;
  }
  // 命名构造 TaskItem.highlight
  static highlight(args) {
    const title = args.title;
    const __o = new TaskItem(args);
    __o.score = 100;
    __o.level = TaskLevel.high;
    return __o;
  }
  // 命名构造 TaskItem.scored
  static scored(args) {
    const title = args.title;
    const score = args.score;
    const __o = new TaskItem(args);
    __o.title = title;
    __o.score = score;
    __o.level = TaskLevel.medium;
    return __o;
  }
  // 命名构造 TaskItem.fromLevel（factory）
  static fromLevel(args) {
    const title = args.title;
    const level = args.level;
    return TaskItem.scored({title: title, score: (level.index * 10)});
  }
}

// 组件 SyntaxDetail
export class SyntaxDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._task = null;
    this._note = null;
    this._scores = null;
    this._upper = null;
    this._first = null;
    this._chain = null;
  }
  _run() {
    this.setState(() => { this._task = TaskItem.highlight({     "title": "阅读"   }); this._note = "hello"; this._scores = [3, 1, 4]; this._upper = this._note?.toUpperCase(); this._first = this._scores?.[0]; this._chain = this._task?.level.name; });
  }
  _clear() {
    this.setState(() => { this._task = null; this._note = null; this._scores = null; this._upper = this._note?.toUpperCase(); this._first = this._scores?.[0]; this._chain = this._task?.level.name; });
  }
  _levelText(level) {
    switch (level) {
      case TaskLevel.high:
      return "高";
      case TaskLevel.medium:
      return "中";
      case TaskLevel.low:
      return "低";
    }
  }
  build(context) {
    var task = this._task;
    return new Padding({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
        "value": 16
      }))),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.stretch,
        "mainAxisSize": MainAxisSize.min,
        "children": [
          new Text({
            "data": "空安全 · 命名构造 · 枚举"
          }),
          (this.__k1 || (this.__k1 = new SizedBox({
            "height": 8
          }))),
          new Text({
            "data": "枚举：" + TaskLevel.values.length + " 项，" + "首个=" + TaskLevel.values[0].name + "，" + "high.index=" + TaskLevel.high.index + "，" + "high=" + TaskLevel.high.toString()
          }),
          (this.__k1 || (this.__k1 = new SizedBox({
            "height": 8
          }))),
          new Text({
            "data": "命名构造：" + ((this._task == null) ? "(点击按钮生成)" : this._task.describe())
          }),
          new Text({
            "data": "当前等级：" + ((this._task == null) ? "-" : this._levelText(this._task.level))
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
      })
    });
  }
}

