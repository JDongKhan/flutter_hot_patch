// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/generator_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, CrossAxisAlignment, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../flutter.js';

// 组件 GeneratorDetail
export class GeneratorDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  *_squares(n) {
    for (let i = 0; (i < n); (i++)) {
      yield (i * i);
    }
  }
  *_chain(n) {
    yield (-1);
    yield* this._squares(n);
    yield 99;
  }
  _generatorText() {
    const tags = () => (function* () { yield "a";
      yield "b"; }).bind(this)();
    const evens = (n) => (function* () { for (let i = 0; (i < n); (i++)) {
        yield (i * 2);
      } }).bind(this)();
    const chained = this._chain(3).toList();
    const tagList = tags().toList();
    let sum = 0;
    for (let v of evens(4)) {
      sum += v;
    }
    return "生成器：chain=" + chained._join("/") + " / tags=" + tagList._join(",") + " " + "/ 闭包求和=" + sum + " / first=" + this._squares(4).first;
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "生成器：sync* / yield / yield*",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": this._generatorText()
        })
      ]
    });
  }
}

