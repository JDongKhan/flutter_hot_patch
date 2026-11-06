// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/record_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, CrossAxisAlignment, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../../flutter.js';

// 组件 RecordDetail
export class RecordDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  _pairValue() {
    return {"$1": 5, "$2": "e"};
  }
  _namedPairValue() {
    return {"x": 6, "y": "f"};
  }
  _recordText() {
    const pos = {"$1": 1, "$2": "a"};
    const named = {"x": 2, "y": "b"};
    const mixed = {"$1": 3, "ok": true};
    const arrow = this._pairValue();
    const block = this._namedPairValue();
    const localPair = () => { return {"$1": 7, "$2": "g"}; };
    const local = localPair();
    const make = (v) => { return {"$1": v, "$2": "h"}; };
    const closure = make(8);
    return "record：" + pos.$1 + "/" + pos.$2 + " / " + named.x + named.y + " / " + mixed.$1 + ":" + mixed.ok + " / " + "返回值：" + arrow.$1 + arrow.$2 + " " + block.x + block.y + " " + local.$1 + local.$2 + " " + closure.$1 + closure.$2;
  }
  _recordPatternText() {
    const pair = {"$1": 1, "$2": "a"};
    const named = {"x": 2, "y": 3};
    {
      const __v0 = pair;
      let first, second;
      const __ok = (() => {
        if (__v0 == null || typeof __v0 !== "object") return false;
        const __v1 = __v0["$1"];
        first = __v1;
        if (__v0 == null || typeof __v0 !== "object") return false;
        const __v2 = __v0["$2"];
        second = __v2;
        return true;
      })();
      if (__ok) {
        return "record 模式：" + first + " / " + second + "，命名：" + named.x + "+" + named.y;
      }
    }
    return "record 模式：未命中";
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "record：字面量 · 返回值 · 模式解构",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": this._recordText()
        }),
        new Text({
          "data": this._recordPatternText()
        })
      ]
    });
  }
}

