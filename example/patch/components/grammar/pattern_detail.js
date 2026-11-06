// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/pattern_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { TaskItem } from 'constructor_detail.js';
import { Column, CrossAxisAlignment, ElevatedButton, FontWeight, OutlinedButton, Row, SizedBox, StatefulWidget, Text, TextStyle } from '../../flutter.js';

// 组件 PatternDetail
export class PatternDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._task = null;
    this._scores = null;
  }
  _run() {
    this.setState(() => {
      this._task = TaskItem.highlight({title: "阅读"});
      this._scores = [3, 1, 4];
    });
  }
  _clear() {
    this.setState(() => {
      this._task = null;
      this._scores = null;
    });
  }
  _matchText() {
    const task = this._task;
    {
      const __v0 = task;
      let title;
      const __ok = (() => {
        if (!(__v0 instanceof TaskItem)) return false;
        const __v1 = __v0.title;
        title = __v1;
        return (title.isNotEmpty);
      })();
      if (__ok) {
        return "if-case 命中：" + title + " / " + task.level.name;
      }
    }
    {
      const __v0 = task;
      const __ok = (() => {
        if (!(__v0 === null)) return false;
        return true;
      })();
      if (__ok) {
        return "if-case：null";
      }
    }
    return "if-case：其它";
  }
  _destructureText() {
    const scores = this._scores;
    if ((__nn(scores) == null)) {
      return "解构：null";
    }
    var __v0 = scores;
    var a, b, c;
    if (!(() => {
      if (!(Array.isArray(__v0) && __v0.length === 3)) return false;
      const __v1 = __v0[0];
      a = __v1;
      const __v2 = __v0[1];
      b = __v2;
      const __v3 = __v0[2];
      c = __v3;
      return true;
    })()) {
      throw new Error("pattern 变量声明未匹配：final [a, b, c] = scores;");
    }
    return "解构：" + a + " / " + b + " / " + c;
  }
  _rangeText() {
    const score = (this._task?.score ?? 0);
    {
      const __v0 = score;
      const __ok = (() => {
        if (!(__v0 > 50)) return false;
        if (!(__v0 < 200)) return false;
        return true;
      })();
      if (__ok) {
        return "关系模式：" + score;
      }
    }
    const scores = this._scores;
    {
      const __v0 = scores;
      let a, b, rest;
      const __ok = (() => {
        if (!(Array.isArray(__v0) && __v0.length >= 2)) return false;
        const __v1 = __v0[0];
        a = __v1;
        const __v2 = __v0[1];
        b = __v2;
        const __v3 = __v0.slice(2);
        rest = __v3;
        return true;
      })();
      if (__ok) {
        return "列表模式：" + a + "," + b + " +" + rest.length;
      }
    }
    return "关系/列表：未命中";
  }
  _patternForText() {
    const pairs = [[1, 2], [3, 4]];
    let sum = 0;
    for (const __v of pairs) {
      let a, b;
      if (!(() => {
        if (!(Array.isArray(__v) && __v.length === 2)) return false;
        const __v1 = __v[0];
        a = __v1;
        const __v2 = __v[1];
        b = __v2;
        return true;
      })()) {
        throw new Error("pattern for 未匹配：final [a, b] in pairs");
      }
      sum += (a * b);
    }
    return "pattern for：sum=" + sum;
  }
  _caseElementText() {
    const task = this._task;
    const labels = [...(() => {
        const __v0 = task;
        let t;
        const __ok = (() => { if (!(__v0 instanceof TaskItem)) return false; const __v1 = __v0.title; t = __v1; return true; })();
        return __ok ? ["标题:" + t] : [];
      })(), ...(() => {
        const __v0 = task;
        const __ok = (() => { if (!(__v0 === null)) return false; return true; })();
        return __ok ? ["空"] : [];
      })()];
    return "集合 if-case：" + labels._join("，");
  }
  _switchExprText() {
    const task = this._task;
    const label = (() => {
      const __v0 = task;
      let title, score;
      switch (true) {
        case (() => { if (!(__v0 instanceof TaskItem)) return false; const __v1 = __v0.title; title = __v1; const __v2 = __v0.score; score = __v2; return ((score >= 100)); })(): return title + "（满分 " + score + "）";
        case (() => { if (!(__v0 instanceof TaskItem)) return false; const __v1 = __v0.title; title = __v1; return true; })(): return title;
        case (() => { if (!(__v0 === null)) return false; return true; })(): return "未生成";
        default: throw new Error("switch 表达式未匹配：switch (task) {TaskItem(title: final title, score: final score) when score >= 100 => '$title（满分 $score）', TaskItem(title: final title) => title, null => '未生成'}");
      }
    })();
    return "switch 表达式：" + label;
  }
  _switchStmtText() {
    const score = (this._task?.score ?? 0);
    {
      const __v0 = score;
      switch (true) {
        case (() => { if (!(__v0 > 100)) return false; if (!(__v0 < 200)) return false; return true; })():
        return "switch 语句：高分";
        case (() => { if (!(__v0 > 0)) return false; return true; })():
        return "switch 语句：普通";
        default:
        return "switch 语句：无分";
      }
    }
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "模式匹配：if-case / 解构 / 关系 / 列表 / switch",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": this._matchText()
        }),
        new Text({
          "data": this._destructureText()
        }),
        new Text({
          "data": this._rangeText()
        }),
        new Text({
          "data": this._patternForText()
        }),
        new Text({
          "data": this._caseElementText()
        }),
        new Text({
          "data": this._switchExprText()
        }),
        new Text({
          "data": this._switchStmtText()
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

