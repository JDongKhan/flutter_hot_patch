// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/operator_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, CrossAxisAlignment, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../../flutter.js';

// 模型 Price
export class Price {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this._cents = (args && args._cents !== undefined) ? args._cents : 0;
  }
  get cents() {
    return this._cents;
  }
  set cents(v) {
    this._cents = v;
  }
  __op$add(other) {
    return new Price({
      "_cents": (this._cents + other._cents)
    });
  }
  __op$neg() {
    return new Price({
      "_cents": (-this._cents)
    });
  }
  __op$eq(other) {
    return ((other instanceof Price) && (other._cents === this._cents));
  }
  get hashCode() {
    return this._cents.hashCode;
  }
}

// 组件 OperatorDetail
export class OperatorDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  _operatorText() {
    const a = new Price({
      "_cents": 100
    });
    const b = new Price({
      "_cents": 23
    });
    const total = a.__op$add(b);
    total.cents = 150;
    const sameValue = new Price({
      "_cents": 150
    });
    const same = ((__a, __b) => __a == null ? __b == null : __a.__op$eq(__b))(total, sameValue);
    const hashSame = (total.hashCode === sameValue.hashCode);
    const neg = b.__op$neg();
    return "setter/运算符：sum=" + total.cents + " / 相等=" + same + " / hash一致=" + hashSame + " " + "/ 取负=" + neg.cents;
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "运算符重载 · setter · == / hashCode",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": this._operatorText()
        })
      ]
    });
  }
}

