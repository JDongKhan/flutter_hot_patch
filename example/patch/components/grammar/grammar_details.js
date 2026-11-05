// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/grammar_details.dart 自动生成
// 重新生成：dart run build_runner build

import { StateLogMixin } from '../../hot_module_base.js';
import { StringLogExtension } from '../../extensions/hot_module_base.js';
import { TestString1 } from 'extension/e_string.js';
import { Colors, Column, CrossAxisAlignment, DateTime, Duration, ElevatedButton, FontWeight, RegExp, SizedBox, StatefulWidget, StatelessWidget, StringBuffer, Text, TextStyle } from '../../flutter.js';

// 模型 Greeting
export class Greeting {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.name = (args && args.name !== undefined) ? args.name : '';
  }
  greet() {
    return "Hello, " + this.name;
  }
  describe() {
    return "Greeting(" + this.name + ")";
  }
}

// 模型 FancyGreeting
export class FancyGreeting extends Greeting {
  constructor(args) {
    super(args);
    this.emoji = "✨";
  }
  greet() {
    return super.greet() + " " + this.emoji;
  }
  describe() {
    return super.describe() + " → FancyGreeting";
  }
}

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

// 组件 ExtensionDetail
export class ExtensionDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  _log() {
    "扩展方法打印的日志".logText("ExtensionDetail");
    "test".log1();
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
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new ElevatedButton({
          "onPressed": () => this._log(),
          "child": (this.__k4 || (this.__k4 = new Text({
            "data": "调用 String.logText()"
          })))
        })
      ]
    });
  }
}

// 组件 InheritanceDetail
export class InheritanceDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const plain = new Greeting({
      "name": "Dart"
    });
    const fancy = new FancyGreeting({
      "name": "JS"
    });
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "普通类单继承（extends / super / 多态）",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "Greeting 为基类，FancyGreeting 覆盖 greet / describe 并调用 super。",
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
            "fontSize": 15
          }))),
          "data": plain.greet()
        }),
        new Text({
          "style": (this.__k5 || (this.__k5 = new TextStyle({
            "fontSize": 13
          }))),
          "data": plain.describe()
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k4 || (this.__k4 = new TextStyle({
            "fontSize": 15
          }))),
          "data": fancy.greet()
        }),
        new Text({
          "style": (this.__k5 || (this.__k5 = new TextStyle({
            "fontSize": 13
          }))),
          "data": fancy.describe()
        })
      ]
    });
  }
}

// 组件 BasicApiDetail
export class BasicApiDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._now = DateTime.now();
  }
  _refresh() {
    this.setState(() => {
      this._now = DateTime.now();
    });
  }
  build(context) {
    const start = new DateTime({year: 2024, month: 3, day: 1, hour: 9, minute: 30});
    const end = start.add(new Duration({hours: 2, minutes: 45}));
    const span = end.difference(start);
    const parsed = DateTime.parse("2024-03-01T09:30:00Z");
    const order = (end.isAfter(start) ? "end 晚于 start" : "end 不晚于 start");
    const text = "订单 A1001，金额 128.50 元，数量 3 件";
    const digitRe = new RegExp({source: "\\d+"});
    const hasDigits = digitRe.hasMatch(text);
    const firstDigits = digitRe.firstMatch(text);
    const allDigits = digitRe.allMatches(text);
    const priceRe = new RegExp({source: "(\\d+)\\.(\\d+)"});
    const price = priceRe.firstMatch(text);
    const priceText = ((__nn(price) == null) ? "未匹配" : "整数 " + price.group(1) + "，小数 " + price.group(2));
    const buffer = new StringBuffer();
    buffer.write("匹配到 ");
    buffer.write(allDigits.length);
    buffer.writeln(" 段数字");
    buffer.write("首个片段：");
    buffer.write(((__nn(firstDigits) == null) ? "无" : firstDigits.group(0)));
    const built = buffer.toString();
    buffer.clear();
    const clearedEmpty = buffer.isEmpty;
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "dart:core 基础 API（DateTime / RegExp / StringBuffer）",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "与 Dart 同名同义的 JS 镜像：构造、成员、静态工厂均一比一。",
          "style": new TextStyle({
            "fontSize": 13,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 16
        }))),
        (this.__k4 || (this.__k4 = new Text({
          "data": "DateTime",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "data": "now().toIso8601String() → " + this._now.toIso8601String()
        }),
        new Text({
          "data": "DateTime(2024, 3, 1, 9, 30) → " + start
        }),
        new Text({
          "data": "add(Duration(hours: 2, minutes: 45)) → " + end
        }),
        new Text({
          "data": "difference(start) → " + span.inMilliseconds + " ms"
        }),
        new Text({
          "data": "isAfter(start) → " + order
        }),
        new Text({
          "data": "parse('2024-03-01T09:30:00Z').toUtc() → " + parsed.toUtc()
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 16
        }))),
        (this.__k6 || (this.__k6 = new Text({
          "data": "RegExp",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "data": "待匹配文本：" + text
        }),
        new Text({
          "data": "RegExp(r'\\d+').hasMatch(text) → " + hasDigits
        }),
        new Text({
          "data": "firstMatch(text).group(0) → " + ((__nn(firstDigits) == null) ? "无" : firstDigits.group(0))
        }),
        new Text({
          "data": "allMatches(text).length → " + allDigits.length
        }),
        new Text({
          "data": "RegExp(r'(\\d+)\\.(\\d+)') 分组 → " + priceText
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 16
        }))),
        (this.__k7 || (this.__k7 = new Text({
          "data": "StringBuffer",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "data": "write / writeln 拼接 → " + built.replaceAll("\n", " ⏎ ")
        }),
        new Text({
          "data": "clear() 后 isEmpty → " + clearedEmpty
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 16
        }))),
        new ElevatedButton({
          "onPressed": () => this._refresh(),
          "child": (this.__k8 || (this.__k8 = new Text({
            "data": "重新计算 DateTime.now()"
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

