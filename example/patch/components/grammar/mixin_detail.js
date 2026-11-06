// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/mixin_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { StateLogMixin } from '../../packages/hot_module_base/src/state_log_mixin.js';
import { Colors, Column, CrossAxisAlignment, ElevatedButton, FontWeight, SizedBox, StatefulWidget, Text, TextStyle } from '../../flutter.js';

// 模型 _SuperTagged_Tagged
class _SuperTagged_Tagged {
  constructor() {
  }
}

// 模型 _SuperTagged_Tagged_SuperM
class _SuperTagged_Tagged_SuperM extends _SuperTagged_Tagged {
  constructor(args) {
    super(args);
  }
  describe() {
    return "super:" + super.describe();
  }
}

// 模型 SuperTagged
export class SuperTagged extends _SuperTagged_Tagged_SuperM {
  constructor(args) {
    super(args);
  }
  get tag() {
    return "Super";
  }
}

// 模型 _MultiTagged_Tagged
class _MultiTagged_Tagged {
  constructor() {
  }
}

// 模型 _MultiTagged_Tagged_CounterM
class _MultiTagged_Tagged_CounterM extends _MultiTagged_Tagged {
  constructor(args) {
    super(args);
    this.hits = 0;
  }
}

// 模型 MultiTagged
export class MultiTagged extends _MultiTagged_Tagged_CounterM {
  constructor(args) {
    super(args);
  }
  get tag() {
    return "Multi";
  }
}

// 模型 _LoudTagged_Tagged
class _LoudTagged_Tagged {
  constructor() {
  }
}

// 模型 LoudTagged
export class LoudTagged extends _LoudTagged_Tagged {
  constructor(args) {
    super(args);
  }
  get tag() {
    return "Loud";
  }
}

// 模型 _MixinDetail_StatefulWidget_StateLogMixin
class _MixinDetail_StatefulWidget_StateLogMixin extends StatefulWidget {
  constructor(args) {
    super(args);
    this.__ta = (args && args.typeArguments) || {};
  }
}

// 组件 MixinDetail
export class MixinDetail extends _MixinDetail_StatefulWidget_StateLogMixin {
  constructor(args) {
    super(args);
    this._count = 0;
  }
  _bump() {
    this.setState(() => {
      this._count += 1;
    });
    this.logState("计数变为 " + this._count);
  }
  _mixinClassText() {
    const base = new Tagged({});
    const mixed = new LoudTagged({});
    const multi = new MultiTagged({});
    const sup = new SuperTagged({});
    return "mixin class：" + base.describe() + " / " + mixed.describe() + " / " + "多 mixin：" + multi.describe() + " " + multi.bump() + " " + multi.counterText() + " / " + "super：" + sup.describe();
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "State 混入 StateLogMixin（跨包 mixin）",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "点击按钮后 setState + 调用 mixin 提供的 logState，控制台输出 [StateLogMixin] ...",
          "style": new TextStyle({
            "fontSize": 13,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": (this.__k4 || (this.__k4 = new TextStyle({
            "fontSize": 20
          }))),
          "data": "当前计数：" + this._count
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k5 || (this.__k5 = new TextStyle({
            "fontSize": 13
          }))),
          "data": this._mixinClassText()
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new ElevatedButton({
          "onPressed": () => this._bump(),
          "child": (this.__k6 || (this.__k6 = new Text({
            "data": "+1 并打日志"
          })))
        })
      ]
    });
  }
}

// 模型 Tagged
export class Tagged {
  constructor() {
  }
  get tag() {
    return "Tagged";
  }
  describe() {
    return "[" + this.tag + "]";
  }
}

// 模型 CounterM
export class CounterM {
  constructor() {
    this.hits = 0;
  }
  bump() {
    return this.hits += 1;;
  }
  counterText() {
    return "hits=" + this.hits;
  }
}

// 模型 SuperM
export class SuperM {
  constructor() {
  }
}
__mixinHard(_SuperTagged_Tagged, Tagged);
__mixinHard(_SuperTagged_Tagged_SuperM, SuperM);
__mixinHard(_MultiTagged_Tagged, Tagged);
__mixinHard(_MultiTagged_Tagged_CounterM, CounterM);
__mixinHard(_LoudTagged_Tagged, Tagged);
__mixinHard(_MixinDetail_StatefulWidget_StateLogMixin, StateLogMixin);

