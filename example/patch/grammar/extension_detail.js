// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/extension_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { IntExtension } from '../packages/hot_module_base/src/int_extension.js';
import { TestString1 } from 'extension/e_string.js';
import { TagB } from 'extension/e_tag.js';
import { Center, Colors, Column, CrossAxisAlignment, ElevatedButton, FontWeight, SizedBox, StatefulWidget, Text, TextStyle } from '../flutter.js';

// 模型 Counter
export class Counter {
  constructor() {
    this.value = 0;
    this.note = null;
  }
}

// 模型 Vector
export class Vector {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.x = (args && args.x !== undefined) ? args.x : 0;
  }
}

// 组件 ExtensionDetail
export class ExtensionDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._count = 0;
  }
  _extensionOperatorText() {
    const a = new Vector({
      "x": 2
    });
    const b = new Vector({
      "x": 3
    });
    const sum = a.__op$add(b);
    const neg = a.__op$neg();
    const rest = a.__op$mod(4);
    const shout = ShoutEx.shout.call("explicit");
    return "extension operator：sum=" + sum.x + " / neg=" + neg.x + " / mod=" + rest + " " + "/ 显式调用=" + shout;
  }
  _increment() {
    this._count = this._count.increment();
    "test".log1();
    this.setState(() => {});
  }
  _accessorGeneratorText() {
    const counter = new Counter({});
    counter.level = 3;
    const steps = counter.steps(3).toList();
    const explicit = new Counter({});
    ((__r) => { const __v = 2; CounterLevel.level.set.call(__r, __v); return __v; })(explicit);
    ((__r) => { const __v = 1; const __n = CounterLevel.level.get.call(__r) + __v; CounterLevel.level.set.call(__r, __n); return __n; })(explicit);
    const post = ((__r) => { const __o = CounterLevel.level.get.call(__r); CounterLevel.level.set.call(__r, __o + 1); return __o; })(explicit);
    const pre = ((__r) => { const __n = CounterLevel.level.get.call(__r) + 1; CounterLevel.level.set.call(__r, __n); return __n; })(explicit);
    ((__r) => { const __c = CounterLevel.label.get.call(__r); if (__c != null) return __c; const __v = "x"; CounterLevel.label.set.call(__r, __v); return __v; })(explicit);
    ((__r) => { const __c = CounterLevel.label.get.call(__r); if (__c != null) return __c; const __v = "y"; CounterLevel.label.set.call(__r, __v); return __v; })(explicit);
    CounterLevel.v = 7;
    const bumped = CounterLevel.bump();
    return "扩展 getter/setter：level=" + counter.level + " / value=" + counter.value + " " + "/ 生成器=" + steps.join(",") + " / 显式 setter=" + explicit.level + "/" + explicit.value + " / ++--=" + post + "," + pre + " / ??==" + CounterLevel.label.get.call(explicit) + " / static=" + CounterLevel.v + "," + bumped;
  }
  _identityText() {
    return "显式分派：TagA=" + TagA.tag.call("x") + " / TagB=" + TagB.tag.call("x") + " " + "/ 自身调用=" + TagA.loud.call("y");
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "String 扩展 logText（跨包 extension）",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "调用 '扩展方法打印的日志'.logText('ExtensionDetail')，控制台输出 [ExtensionDetail] ...",
          "style": new TextStyle({
            "fontSize": 13,
            "color": Colors.black54
          })
        }))),
        new Center({
          "child": new Text({
            "style": new TextStyle({
              "fontSize": 20,
              "color": Colors.black54
            }),
            "data": this._count
          })
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new ElevatedButton({
          "onPressed": () => this._increment(),
          "child": (this.__k4 || (this.__k4 = new Text({
            "data": "add"
          })))
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": (this.__k5 || (this.__k5 = new TextStyle({
            "fontSize": 13
          }))),
          "data": this._extensionOperatorText()
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k5 || (this.__k5 = new TextStyle({
            "fontSize": 13
          }))),
          "data": this._accessorGeneratorText()
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k5 || (this.__k5 = new TextStyle({
            "fontSize": 13
          }))),
          "data": this._identityText()
        })
      ]
    });
  }
}

// 扩展 VectorOps
export const VectorOps = registerExtension(Vector, (function () {
  "use strict";
  return {
    __op$add: function (other) {
      return new Vector({
        "x": (this.x + other.x)
      });
    },
    __op$neg: function () {
      return new Vector({
        "x": (-this.x)
      });
    },
    __op$mod: function (mod) {
      return __mod(this.x, mod);
    },
  };
})(), { id: "lib/grammar/extension_detail.dart#VectorOps" });

// 扩展 TagA
export const TagA = registerExtension("String", (function () {
  "use strict";
  return {
    tag: function () {
      return "A";
    },
    loud: function () {
      return TagA.tag.call(this) + "!";
    },
  };
})(), { id: "lib/grammar/extension_detail.dart#TagA" });

// 扩展 ShoutEx
export const ShoutEx = registerExtension("String", (function () {
  "use strict";
  return {
    shout: function () {
      return this + "!";
    },
  };
})(), { id: "lib/grammar/extension_detail.dart#ShoutEx" });

// 扩展 CounterLevel
export const CounterLevel = registerExtension(Counter, (function () {
  "use strict";
  return {
    level: { get: function () {
        return Math.trunc(this.value / 10);
      }, set: function (v) {
        this.value = (v * 10);
      } },
    label: { get: function () {
        return this.note;
      }, set: function (v) {
        this.note = v;
      } },
    steps: function* (count) {
      for (let i = 0; (i < count); (i++)) {
        yield (this.value + i);
      }
    },
  };
})(), { id: "lib/grammar/extension_detail.dart#CounterLevel", statics: { _v: 0, get v() {
      return CounterLevel._v;
    }, set v(next) {
      return CounterLevel._v = next;
    }, bump: function () {
      CounterLevel._v = (CounterLevel._v + 1);
      return CounterLevel._v;
    }, } });

