// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/statement_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { topLevelCounter, topLevelGreet, topLevelNums, topLevelPrefix } from 'top_level_helper.js';
import { Column, CrossAxisAlignment, FontWeight, FormatException, SizedBox, StatelessWidget, Text, TextStyle, int } from '../flutter.js';

// 组件 StatementDetail
export class StatementDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  _tryText() {
    const parts = [];
    for (let raw of ["12", "x"]) {
      try {
        parts.add("解析=" + int.parse(raw));
      } catch (__e) {
        if (__e instanceof FormatException) {
          parts.add("格式错误");
        }
        else {
          const e = __e;
          parts.add("其它:" + e);
        }
      }
    }
    return topLevelPrefix("try/catch") + "/" + topLevelGreet({ "name": "x" }) + "/" + topLevelCounter().count + "/" + topLevelNums().length + "：" + parts._join("，");
  }
  _rethrowText() {
    let trace = "";
    try {
      try {
        int.parse("x");
      } catch (__e) {
        if (__e instanceof FormatException) {
          trace = "内层";
          throw __e;
        }
        else {
          throw __e;
        }
      }
    } catch (__e) {
      if (__e instanceof FormatException) {
        trace = trace + " → 外层捕获";
      }
      else {
        throw __e;
      }
    }
    return "rethrow：" + trace;
  }
  _labelText() {
    const scores = [3, 1, 4];
    let hit = 0;
    outer: for (let v of scores) {
      for (let w of [v, (v + 1)]) {
        if ((w >= 4)) {
          hit = w;
          break outer;
        }
      }
    }
    return "label：hit=" + hit;
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "语句：try/catch · rethrow · label",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": this._tryText()
        }),
        new Text({
          "data": this._rethrowText()
        }),
        new Text({
          "data": this._labelText()
        })
      ]
    });
  }
}

