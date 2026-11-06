import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// `extends` 语法 demo：普通类单继承（父类字段 / 覆盖方法 / `super` 调用 / 多态）。
///
/// JS 侧是**原生继承**（`class FancyGreeting extends Greeting`）：父类字段由
/// 父类构造的 `__applyProps(args)` 填、`super.greet()` 由引擎沿原型链解析。
@PatchEntry('InheritanceDetail')
class InheritanceDetail extends StatelessWidget {
  const InheritanceDetail({super.key});

  @override
  Widget build(BuildContext context) {
    // 多态：同一静态类型 [Greeting]，运行期分别落到基类 / 子类实现。
    final Greeting plain = Greeting('Dart');
    final Greeting fancy = FancyGreeting('JS');
    final car = SportCar();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '普通类单继承（extends / super / 多态）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Greeting 为基类，FancyGreeting 覆盖 greet / describe 并调用 super。',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Text(plain.greet(), style: const TextStyle(fontSize: 15)),
        Text(plain.describe(), style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        Text(fancy.greet(), style: const TextStyle(fontSize: 15)),
        Text(fancy.describe(), style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        Text('父类成员：speed=${car.speed} / report=${car.report()}',
            style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

/// 基类：持有字段并提供可被子类覆盖的两个方法。
class Greeting {
  Greeting(this.name);

  final String name;

  String greet() => 'Hello, $name';

  String describe() => 'Greeting($name)';
}

/// 子类：继承父类字段与 [Greeting.greet]，覆盖 [Greeting.describe]，
/// 两处都用 `super` 复用父类实现。
class FancyGreeting extends Greeting {
  /// `super.name` = 直接转发给父类构造的同名参数。
  FancyGreeting(super.name);

  final String emoji = '✨';

  @override
  String greet() => '${super.greet()} $emoji';

  @override
  String describe() => '${super.describe()} → FancyGreeting';
}

// ---------------------------------------------------------------------------
// 父类成员：`super.x`（字段 / getter）与 `super.m()`
// ---------------------------------------------------------------------------

class BaseVehicle {
  /// 父类**字段**：JS 侧是实例属性，`super.wheels` 读不到，应落 `this.wheels`。
  final int wheels = 4;

  /// 父类 **getter**：定义在原型上，`super.speed` 必须保持（子类会 override）。
  int get speed => 60;

  int describe() => speed + 10;
}

class SportCar extends BaseVehicle {
  /// getter 里读父类 getter：必须绕过子类的 override。
  @override
  int get speed => super.speed + 20;

  /// 同时覆盖父类字段读取与父类方法调用。
  int report() => super.wheels * 10 + super.describe();
}
