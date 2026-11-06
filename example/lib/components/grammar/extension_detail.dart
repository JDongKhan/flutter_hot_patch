import 'package:flutter/material.dart';
import 'package:hot_module_base/hot_module_base.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'extension/e_string.dart';

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

/// 显式调用 `ShoutEx(x).shout()`：调用点改写成 `x.shout()`（成员在原型上）。
extension ShoutEx on String {
  String shout() => '${this}!';
}

/// 可空目标：JS 侧没有可挂载的原型，构建期应出声跳过（不产出注册）。
extension NullableTag on String? {
  String tagText() => this == null ? 'null' : '有值';
}
