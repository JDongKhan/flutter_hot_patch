// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/expression_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Price } from 'operator_detail.js';
import { Column, CrossAxisAlignment, FontWeight, SizedBox, StateError, StatelessWidget, Text, TextStyle, num } from '../flutter.js';

// 组件 ExpressionDetail
export class ExpressionDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  _bitwiseText() {
    const a = 6;
    const b = 3;
    const bAnd = (a & b);
    const bOr = (a | b);
    const bXor = (a ^ b);
    const lsh = (a << 2);
    const rsh = ((-8) >> 1);
    const lrsh = ((-8) >>> 1);
    const inv = (~a);
    let quot = 6;
    quot = Math.trunc(quot / 4);
    let mask = 6;
    mask &= (~2);
    const nums = [8, 16];
    const idx = 1;
    ((__t, __i) => { __t[__i] = Math.trunc(__t[__i] / 3); })(nums, idx);
    const cells = [10, 20];
    cells[0] += 5;
    let counter = 1;
    counter <<= 2;
    return "位运算：and=" + bAnd + " or=" + bOr + " xor=" + bXor + " lsh=" + lsh + " rsh=" + rsh + " " + "lrsh=" + lrsh + " not=" + inv + " ~/=" + quot + " mask=" + mask + " idx-num=" + nums[idx] + " " + "cells=" + cells[0] + " shl=" + counter;
  }
  _assignExprText() {
    let i = 0;
    const steps = [];
    while ((((i = (i + 1))) < 4)) {
      steps.add(i);
    }
    const cells = [9, 9];
    let slot = 0;
    const added = (cells[((slot = 1))] += 3);
    const truncated = ((__t, __i) => { return (__t[__i] = Math.trunc(__t[__i] / 4)); })(cells, ((slot = 1)));
    ((__t, __i) => { __t[__i] = Math.trunc(__t[__i] / 3); })(cells, ((slot = 0)));
    let hit = 0;
    return "赋值表达式：steps=" + steps._join("/") + " / added=" + added + " " + "/ 整除=" + truncated + " / 列表=" + cells._join("/") + " / slot=" + slot + " " + "/ assigned=" + " / hit=" + hit + " " + "/ 空目标=";
  }
  _cascadeText() {
    const nums = (() => { const _t = []; _t.add(1); _t.add(2); return _t; })();
    const alias = nums;
    const nothing = null;
    const live = ((_t) => { if (_t == null) return _t; _t.add(3); return _t; })(alias);
    const dead = ((_t) => { if (_t == null) return _t; _t.add(9); _t.add(8); _t[0] = 7; return _t; })(nothing);
    const price = (() => { const _t = new Price({_cents: 1}); _t.cents = 5; _t.cents += 2; return _t; })();
    const map = (() => { const _t = new Map(); __idxSet(_t, "a", 1); __idxSet(_t, "b", 2); return _t; })();
    return "级联：列表=" + nums._join("/") + " / 非空分支=" + (live?.length ?? 0) + " " + "/ 空分支=" + (dead?.length ?? "null") + " / setter=" + price.cents + " " + "/ map=" + __nn(__idx(map, "b"));
  }
  _throwExprText() {
    const requireValue = (xs) => { return (xs?.first ?? ((() => { throw new StateError({message: "空列表"}); })())); };
    const boom = () => { throw new StateError({message: "箭头体"}); };
    let caught = "";
    try {
      requireValue(null);
    } catch (__e) {
      if (__e instanceof StateError) {
        caught += "空值";
      }
      else {
        throw __e;
      }
    }
    try {
      boom();
    } catch (__e) {
      if (__e instanceof StateError) {
        caught += "/箭头";
      }
      else {
        throw __e;
      }
    }
    return "throw 表达式：捕获=" + caught;
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "表达式：位运算 · 赋值表达式 · 级联 · throw",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": this._bitwiseText()
        }),
        new Text({
          "data": this._assignExprText()
        }),
        new Text({
          "data": this._cascadeText()
        }),
        new Text({
          "data": this._throwExprText()
        })
      ]
    });
  }
}

