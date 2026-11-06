// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/constructor_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { TaskLevel } from 'enum_detail.js';
import { Colors, Column, CrossAxisAlignment, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../flutter.js';

// 模型 Stamp
export class Stamp {
  constructor(args) {
    const base = args.base;
    this.base = 0;
    this.doubled = 0;
    this.trace = "";
    this.base = base;
    this.doubled = (base * 2);
    this.trace = "built:" + base;
  }
  describe() {
    return "base=" + this.base + " doubled=" + this.doubled + " trace=" + this.trace;
  }
}

// 模型 TaskItem
export class TaskItem {
  constructor(args) {
    this.__applyProps(args);
    this.score = 0;
    this.level = null;
    this.scores = null;
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

// 组件 ConstructorDetail
export class ConstructorDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const byThis = TaskItem.highlight({
      "title": "阅读"
    });
    const byInit = TaskItem.scored({
      "score": 75,
      "title": "算术"
    });
    const byFactory = TaskItem.fromLevel({
      "title": "实验",
      "level": TaskLevel.low
    });
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "命名构造 · factory · 初始化列表",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "TaskItem 三个命名构造分别走 this.x 形参、初始化列表、factory 委托；" + "Stamp 演示默认构造的执行顺序。",
          "style": new TextStyle({
            "fontSize": 13,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "data": "this.x 形参：" + byThis.describe()
        }),
        new Text({
          "data": "初始化列表：" + byInit.describe()
        }),
        new Text({
          "data": "factory 委托：" + byFactory.describe()
        }),
        new Text({
          "data": "默认构造：" + new Stamp({base: 7}).describe()
        })
      ]
    });
  }
}

