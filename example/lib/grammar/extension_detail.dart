import 'package:flutter/material.dart';
import 'package:hot_module_base/hot_module_base.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'extension/e_string.dart';
import 'extension/e_tag.dart';

/// extension 语法 demo：
///   - 跨包 extension（`StringLogExtension.logText`）与项目内多文件 extension；
///   - extension 运算符重载（`+` / 一元 `-` / `%`）；
///   - 显式调用 `ShoutEx(x).shout()` 的调用点改写；
///   - 可空目标扩展（构建期出声跳过，不产出注册）。
@PatchEntry('ExtensionDetail')
class ExtensionDetail extends StatefulWidget {
  const ExtensionDetail({super.key});

  @override
  State<ExtensionDetail> createState() => _ExtensionDetailState();
}

class _ExtensionDetailState extends State<ExtensionDetail> {
  int _count = 0;

  /// 扩展运算符：调用点 `receiver.__op$xxx(args)`，成员随注册装到原型上。
  String _extensionOperatorText() {
    final Vector a = Vector(2);
    final Vector b = Vector(3);
    final sum = a + b;
    final neg = -a;
    final rest = a % 4;
    // 显式 extension 调用：等价于 `'explicit'.shout()`。
    final shout = ShoutEx('explicit').shout();
    return 'extension operator：sum=${sum.x} / neg=${neg.x} / mod=$rest '
        '/ 显式调用=$shout';
  }

  void _increment() {
    // 跨包 extension：String 本身没有 logText，由 StringLogExtension 提供。
    _count =  _count.increment();
    "test".log1();
    setState(() {});
  }

  /// 成对 getter/setter + 生成器成员：扩展成员与类方法共用同一条发射规则。
  String _accessorGeneratorText() {
    final counter = Counter();
    counter.level = 3; // setter
    final steps = counter.steps(3).toList(); // sync* 生成器

    // 显式扩展 setter / 复合赋值：`CounterLevel(x).level = v` 与 `+=`。
    final explicit = Counter();
    CounterLevel(explicit).level = 2;
    CounterLevel(explicit).level += 1;
    return '扩展 getter/setter：level=${counter.level} / value=${counter.value} '
        '/ 生成器=${steps.join(',')} / 显式 setter=${explicit.level}'
        '/${explicit.value}';
  }

  /// 同目标同名扩展的**显式**调用：按扩展身份分派。
  String _identityText() =>
      '显式分派：TagA=${TagA('x').tag()} / TagB=${TagB('x').tag()} '
      '/ 自身调用=${TagA('y').loud()}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('String 扩展 logText（跨包 extension）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          "调用 '扩展方法打印的日志'.logText('ExtensionDetail')，控制台输出 [ExtensionDetail] ...",
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        Center(child: Text("$_count", style: TextStyle(fontSize: 20, color: Colors.black54))),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _increment, child: const Text('add')),
        const SizedBox(height: 12),
        Text(_extensionOperatorText(), style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        Text(_accessorGeneratorText(), style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        Text(_identityText(), style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// extension 运算符
// ---------------------------------------------------------------------------

/// extension 运算符的接收者（普通类，无自身运算符）。
class Vector {
  const Vector(this.x);

  final int x;
}

extension VectorOps on Vector {
  Vector operator +(Vector other) => Vector(this.x + other.x);
  Vector operator -() => Vector(-this.x);
  int operator %(int mod) => this.x % mod;
}

/// 与 `TagB` 同目标同名：显式调用必须按扩展身份分派（`TagA(x).tag()` ≠ `TagB(x).tag()`）。
extension TagA on String {
  String tag() => 'A';

  /// 调用同名成员必须显式写出扩展（`TagA(this)`）：Dart 里 `this.tag()` 在
  /// 两个扩展都适用时是歧义编译错误，产物按同一口径处理（不替开发者选一个）。
  String loud() => '${TagA(this).tag()}!';
}

/// 显式调用 `ShoutEx(x).shout()`：按扩展身份分派（`ShoutEx.m.call(x)`），
/// 不走原型抢注；同名成员由两个扩展提供时也只有身份能区分。
extension ShoutEx on String {
  String shout() => '${this}!';
}

/// 可空目标：JS 侧没有可挂载的原型，构建期应出声跳过（不产出注册）。
extension NullableTag on String? {
  String tagText() => this == null ? 'null' : '有值';
}

// ---------------------------------------------------------------------------
// 同名 getter / setter + 生成器成员
// ---------------------------------------------------------------------------

class Counter {
  int value = 0;
}

extension CounterLevel on Counter {
  /// 与下面的 setter 同名：产物里必须合并成同一个 `{ get, set }` 描述符。
  int get level => this.value ~/ 10;

  set level(int v) => this.value = v * 10;

  /// `sync*` 成员：与类方法同一发射规则（`function*`）。
  Iterable<int> steps(int count) sync* {
    for (var i = 0; i < count; i++) {
      yield this.value + i;
    }
  }
}
