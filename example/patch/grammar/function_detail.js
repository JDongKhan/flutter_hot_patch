// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/function_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { SportCar } from 'inheritance_detail.js';
import { Column, CrossAxisAlignment, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../flutter.js';

// 模型 Scale
export class Scale {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.value = (args && args.value !== undefined) ? args.value : 0;
  }
  plus(extra) {
    extra = (extra === undefined) ? 1 : extra;
    return (this.value + extra);
  }
  scaled(__o) {
    let factor = (__o && __o.factor !== undefined) ? __o.factor : 2;
    let bonus = (__o && __o.bonus !== undefined) ? __o.bonus : 0;
    return ((this.value * factor) + bonus);
  }
  static fromBase(base, __o) {
    let discount = (__o && __o.discount !== undefined) ? __o.discount : 0;
    return new Scale({
      "value": (base - discount)
    });
  }
}

// 组件 FunctionDetail
export class FunctionDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  _localFuncText() {
    const twice = (x) => { return (x * 2); };
    const grade = (score) => { {
        const __v0 = score;
        const __ok = (() => {
          if (!(__v0 > 100)) return false;
          if (!(__v0 < 200)) return false;
          return true;
        })();
        if (__ok) {
          return "高分";
        }
      }
      {
        const __v0 = score;
        const __ok = (() => {
          if (!(__v0 > 0)) return false;
          return true;
        })();
        if (__ok) {
          return "普通";
        }
      }
      return "无分"; };
    const score = 120;
    return "局部函数：twice(" + score + ")=" + twice(score) + " / " + grade(score);
  }
  _paramsText() {
    const localScale = (v, factor) => { factor = (factor === undefined) ? 3 : factor; return (v * factor); };
    const localPack = (v, __o) => { let step = (__o && __o.step !== undefined) ? __o.step : 2; let times = (__o && __o.times !== undefined) ? __o.times : 1; return (v + (step * times)); };
    const namedClosure = (__o) => { let a = (__o && __o.a !== undefined) ? __o.a : 1; let b = (__o && __o.b !== undefined) ? __o.b : 2; return (a + b); };
    const optionalClosure = (v, k) => { k = (k === undefined) ? 10 : k; return (v + k); };
    const base = 20;
    const scale = new Scale({
      "value": base
    });
    return "形参：方法可选=" + scale.plus() + "/" + scale.plus(4) + " " + "/ 方法具名=" + scale.scaled({ "factor": 2, "bonus": base }) + " " + "/ 局部可选=" + localScale(4) + " " + "/ 局部具名=" + localPack(1, { "step": 3, "times": 2 }) + " " + "/ 闭包具名=" + namedClosure({ "b": 5 }) + " " + "/ 闭包可选=" + optionalClosure(1) + " " + "/ 静态具名=" + Scale.fromBase(base, { "discount": 3 }).value;
  }
  get _baseValue() {
    return 11;
  }
  _addBase(v) {
    return (v + this._baseValue);
  }
  _tearOffText() {
    const add = this._addBase.bind(this);
    const bv = this._baseValue;
    return "方法 tear-off：" + add(1) + "/" + bv;
  }
  _objTearOffText() {
    const car = new SportCar();
    const reportFn = car.report.bind(car);
    const fresh = ((__o) => __o.report.bind(__o))(new SportCar());
    const speedNow = car.speed;
    return "对象 tear-off：" + reportFn() + "/" + fresh + "/" + speedNow;
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "函数：局部函数 · 形参签名 · tear-off",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": this._localFuncText()
        }),
        new Text({
          "data": this._paramsText()
        }),
        new Text({
          "data": this._tearOffText()
        }),
        new Text({
          "data": this._objTearOffText()
        })
      ]
    });
  }
}

