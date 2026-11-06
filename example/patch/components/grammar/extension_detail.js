// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grammar/extension_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { StringLogExtension } from '../../packages/hot_module_base/src/string_log_extension.js';
import { TestString1 } from 'extension/e_string.js';
import { Colors, Column, CrossAxisAlignment, ElevatedButton, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../../flutter.js';

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
export class ExtensionDetail extends StatelessWidget {
  constructor(args) {
    super(args);
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
    const shout = "explicit".shout();
    return "extension operator：sum=" + sum.x + " / neg=" + neg.x + " / mod=" + rest + " " + "/ 显式调用=" + shout;
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
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": (this.__k5 || (this.__k5 = new TextStyle({
            "fontSize": 13
          }))),
          "data": this._extensionOperatorText()
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
})(), { id: "lib/components/grammar/extension_detail.dart#VectorOps" });

// 扩展 ShoutEx
export const ShoutEx = registerExtension("String", (function () {
  "use strict";
  return {
    shout: function () {
      return this + "!";
    },
  };
})(), { id: "lib/components/grammar/extension_detail.dart#ShoutEx" });

