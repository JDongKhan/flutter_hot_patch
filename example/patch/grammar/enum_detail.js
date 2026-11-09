// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/enum_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, CrossAxisAlignment, ElevatedButton, FontWeight, SizedBox, StatefulWidget, Text, TextStyle } from '../flutter.js';

export const TaskLevel = (function () {
  const __enumValues = [];
  function __makeEnumValue(name, index) {
    return {
      name: name,
      index: index,
      toString: function () { return "TaskLevel." + name; }
    };
  }
  const low = __makeEnumValue("low", 0);
  __enumValues.push(low);
  const medium = __makeEnumValue("medium", 1);
  __enumValues.push(medium);
  const high = __makeEnumValue("high", 2);
  __enumValues.push(high);
  return {
    low: low,
    medium: medium,
    high: high,
    values: __enumValues,
    byName: function (name) {
      for (var i = 0; i < __enumValues.length; i++) {
        if (__enumValues[i].name === name) { return __enumValues[i]; }
      }
      throw new Error("Invalid argument(s): Invalid value: " + name);
    }
  };
})();

// 组件 EnumDetail
export class EnumDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._level = TaskLevel.medium;
  }
  _cycle() {
    this.setState(() => {
      this._level = TaskLevel.values[__mod(((this._level.index + 1)), TaskLevel.values.length)];
    });
  }
  _levelText(level) {
    switch (level) {
      case TaskLevel.high:
      return "高";
      case TaskLevel.medium:
      return "中";
      case TaskLevel.low:
      return "低";
    }
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "枚举：values / name / index / byName / switch",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "枚举：" + TaskLevel.values.length + " 项，" + "首个=" + TaskLevel.values[0].name + "，" + "high.index=" + TaskLevel.high.index + "，" + "byName=" + TaskLevel.byName("high").name + "，" + "high=" + TaskLevel.high.toString()
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "当前等级：" + this._level.name + "（" + this._levelText(this._level) + "）"
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        new ElevatedButton({
          "onPressed": () => this._cycle(),
          "child": (this.__k3 || (this.__k3 = new Text({
            "data": "切换等级"
          })))
        })
      ]
    });
  }
}

