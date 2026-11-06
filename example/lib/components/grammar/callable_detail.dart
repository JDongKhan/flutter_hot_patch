import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 可调用对象 / 函数调用语法 demo：
///   - 实例方法 `call` → JS 侧改名 `invoke`，`add(1)` / `add.call(2)` 都落到
///     `add.invoke(...)`（避免与 `Function.prototype.call` 冲突）；
///   - Dart `fn.call(3)` 等价 `fn(3)`，JS 首参 thisArg 必须去掉；
///   - 立即调用闭包 / 括号包裹的函数值（AST `FunctionExpressionInvocation`）。
@PatchEntry('CallableDetail')
class CallableDetail extends StatelessWidget {
  const CallableDetail({super.key});

  /// 可调用对象：隐式调用 `add(1)` 与显式 `add.call(2)` 都为 `invoke`。
  String _callText() {
    final add = Adder(3);
    return 'call：add(1)=${add(1)} / add.call(2)=${add.call(2)}';
  }

  /// Function 的 `call`：Dart `fn.call(3)` 等价 `fn(3)`。
  String _functionCallText() {
    int twice(int v) => v * 2;
    final Function fn = twice;
    final int Function(int) typed = twice;
    return 'Function.call：fn.call(3)=${fn.call(3)} '
        '/ typed.call(2)=${typed.call(2)} '
        '/ fn(4)=${fn(4)}';
  }

  /// 函数值调用：立即调用闭包 / 括号包裹的函数值。
  String _fnValueCallText() {
    final int Function(int) twice = (v) => v * 2;
    final quad = ((int v) => v * 2)(3);
    final picked = (twice ?? (v) => v)(5);
    return '函数值调用：$quad/$picked';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'callable 对象 · Function.call · 函数值调用',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_callText()),
        Text(_functionCallText()),
        Text(_fnValueCallText()),
      ],
    );
  }
}

class Adder {
  const Adder(this.delta);

  final int delta;

  int call(int v) => v + delta;
}
