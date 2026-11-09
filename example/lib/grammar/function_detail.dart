import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'inheritance_detail.dart';
import 'import_show_helper.dart' show ShownModel, shownConst, shownGreeting;
import 'top_level_helper.dart' hide topLevelHidden;

/// 函数语法 demo：局部函数、顶层函数、形参签名、方法 / 对象 tear-off。
@PatchEntry('FunctionDetail')
class FunctionDetail extends StatelessWidget {
  const FunctionDetail({super.key});

  /// 局部函数：表达式体 + 块体（块体内再用 if-case），两者都捕获外层字段。
  String _localFuncText() {
    int twice(int x) => x * 2;

    String grade(int score) {
      if (score case > 100 && < 200) return '高分';
      if (score case > 0) return '普通';
      return '无分';
    }

    final score = 120;
    return '局部函数：twice($score)=${twice(score)} / ${grade(score)}';
  }

  /// 形参签名：类方法 / 局部函数 / 闭包的「可选位置 + 默认值」与「具名」。
  String _paramsText() {
    int localScale(int v, [int factor = 3]) => v * factor;
    int localPack(int v, {int step = 2, int times = 1}) => v + step * times;

    final namedClosure = ({int a = 1, int b = 2}) => a + b;
    final optionalClosure = (int v, [int k = 10]) => v + k;

    final base = 20;
    final scale = Scale(base);
    return '形参：方法可选=${scale.plus()}/${scale.plus(4)} '
        '/ 方法具名=${scale.scaled(factor: 2, bonus: base)} '
        '/ 局部可选=${localScale(4)} '
        '/ 局部具名=${localPack(1, step: 3, times: 2)} '
        '/ 闭包具名=${namedClosure(b: 5)} '
        '/ 闭包可选=${optionalClosure(1)} '
        '/ 静态具名=${Scale.fromBase(base, discount: 3).value}';
  }

  /// getter（读值）与方法 tear-off（取函数并绑定 this）在值位置的区分。
  int get _baseValue => 11;

  int _addBase(int v) => v + _baseValue;

  String _tearOffText() {
    final int Function(int) add = _addBase;
    final int bv = _baseValue;
    return '方法 tear-off：${add(1)}/$bv';
  }

  /// 对象上的方法 tear-off：局部变量接收者 / 构造接收者（后者只求值一次）。
  String _objTearOffText() {
    final car = SportCar();
    final int Function() reportFn = car.report;
    final int Function() fresh = SportCar().report;
    final int speedNow = car.speed;
    return '对象 tear-off：${reportFn()}/$fresh/$speedNow';
  }

  /// 顶层函数：与成员函数共用形参 / 函数体翻译，跨文件调用。
  String _topLevelText() {
    final counter = topLevelCounter();
    return '顶层函数：${topLevelPrefix('fn')} / '
        '${topLevelGreet(name: 'Dart')} / '
        '${counter.count} / ${topLevelNums().length}';
  }

  /// import show / hide：只用组合子放行的符号（类 / 顶层常量 / 顶层函数）。
  String _importCombinatorText() {
    final model = ShownModel(3);
    return 'import 组合子：$shownConst / ${shownGreeting()} / ${model.value}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '函数：局部函数 · 顶层函数 · 形参签名 · tear-off',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_localFuncText()),
        Text(_topLevelText()),
        Text(_importCombinatorText()),
        Text(_paramsText()),
        Text(_tearOffText()),
        Text(_objTearOffText()),
      ],
    );
  }
}

/// 形参签名演示载体：可选位置形参 / 具名形参 / 静态方法的具名形参。
class Scale {
  Scale(this.value);

  final int value;

  /// 可选位置形参（默认值）：JS 签名保留为位置形参，函数体开头补缺省。
  int plus([int extra = 1]) => value + extra;

  /// 具名形参（默认值）：具名实参合并成尾参对象 `__o`，函数体开头解构。
  int scaled({int factor = 2, int bonus = 0}) => value * factor + bonus;

  /// 静态方法的具名形参走同一套签名规则。
  static Scale fromBase(int base, {int discount = 0}) =>
      Scale(base - discount);
}
