import 'package:flutter/material.dart';
import 'package:hot_module_base/hot_module_base.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'extension/e_string.dart';

/// 基础语法 demo 集合（「基础语法 · 列表」页点击进入）。
///
/// 与 [WidgetShowcase] 的常用组件详情同一套形态：每个类都是 `@PatchEntry`
/// 组件，原生可直接用、JS 侧由 `patch/components/grammar_details.js` 实例化。
///
/// 这里验证三类 Dart 语法能力：
///   - `mixin`：State 混入 `package:hot_module_base` 的 [StateLogMixin]；
///   - `extension`：String 调用 `package:hot_module_base` 的 [StringLogExtension]；
///   - `extends`：普通类单继承（父类字段 / 覆盖方法 / `super` 调用 / 多态）。

// ---------------------------------------------------------------------------
// mixin：给 State 扩展日志能力
// ---------------------------------------------------------------------------

@PatchEntry('MixinDetail')
class MixinDetail extends StatefulWidget {
  const MixinDetail({super.key});

  @override
  State<MixinDetail> createState() => _MixinDetailState();
}

/// 混入跨包 mixin：[_MixinDetailState] 自身没有 `logState` 方法，
/// 直接调用到 [StateLogMixin] 里的实现。
class _MixinDetailState extends State<MixinDetail> with StateLogMixin<MixinDetail> {
  int _count = 0;

  void _bump() {
    setState(() => _count++);
    logState('计数变为 $_count');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'State 混入 StateLogMixin（跨包 mixin）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '点击按钮后 setState + 调用 mixin 提供的 logState，控制台输出 [StateLogMixin] ...',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Text('当前计数：$_count', style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _bump, child: const Text('+1 并打日志')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// extension：给 String 扩展日志能力
// ---------------------------------------------------------------------------

@PatchEntry('ExtensionDetail')
class ExtensionDetail extends StatelessWidget {
  const ExtensionDetail({super.key});

  void _log() {
    // 跨包 extension：String 本身没有 logText，由 StringLogExtension 提供。
    '扩展方法打印的日志'.logText('ExtensionDetail');
    "test".log1();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'String 扩展 logText（跨包 extension）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "调用 '扩展方法打印的日志'.logText('ExtensionDetail')，控制台输出 [ExtensionDetail] ...",
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _log, child: const Text('调用 String.logText()')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// extends：普通类单继承
// ---------------------------------------------------------------------------

/// 基类：持有字段并提供可被子类覆盖的两个方法。
class Greeting {
  Greeting(this.name);

  final String name;

  String greet() => 'Hello, $name';

  String describe() => 'Greeting($name)';
}

/// 子类：继承父类字段与 [Greeting.greet]，覆盖 [Greeting.describe]，
/// 两处都用 `super` 复用父类实现。
///
/// JS 侧是**原生继承**（`class FancyGreeting extends Greeting`）：父类字段由
/// 父类构造的 `__applyProps(args)` 填、`super.greet()` 由引擎沿原型链解析。
class FancyGreeting extends Greeting {
  /// `super.name` = 直接转发给父类构造的同名参数。
  FancyGreeting(super.name);

  final String emoji = '✨';

  @override
  String greet() => '${super.greet()} $emoji';

  @override
  String describe() => '${super.describe()} → FancyGreeting';
}

@PatchEntry('InheritanceDetail')
class InheritanceDetail extends StatelessWidget {
  const InheritanceDetail({super.key});

  @override
  Widget build(BuildContext context) {
    // 多态：同一静态类型 [Greeting]，运行期分别落到基类 / 子类实现。
    final Greeting plain = Greeting('Dart');
    final Greeting fancy = FancyGreeting('JS');
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
      ],
    );
  }
}
