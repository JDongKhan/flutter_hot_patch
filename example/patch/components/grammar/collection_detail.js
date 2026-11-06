// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/collection_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, CrossAxisAlignment, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../../flutter.js';

// 组件 CollectionDetail
export class CollectionDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  _collectionText() {
    const scores = [3, 1, 4];
    const base = [10, 20];
    const merged = [1, ...(scores.isNotEmpty ? [scores.first] : []), ...base, ...(scores).map((s) => [(s * 2)])];
    return "集合元素：" + merged._join("/");
  }
  _forPartsText() {
    const cells = [...(() => {
        const __r = [];
        for (let i = 0; (i < 3); (i++)) {
          __r.push(...[(i * i)]);
        }
        return __r;
      })()];
    return "三段式集合：" + cells._join("/");
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "集合字面量：if / for / 展开",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": this._collectionText()
        }),
        new Text({
          "data": this._forPartsText()
        })
      ]
    });
  }
}

