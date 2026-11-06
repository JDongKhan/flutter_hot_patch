// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/basic_api_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, Column, CrossAxisAlignment, DateTime, Duration, ElevatedButton, FontWeight, RegExp, SizedBox, StatefulWidget, StringBuffer, Text, TextStyle } from '../flutter.js';

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

