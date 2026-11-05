import 'package:flutter/material.dart';
import 'package:hot_module_base/hot_module_base.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'extension/e_string.dart';

/// 基础语法 demo 集合（「基础语法 · 列表」页点击进入）。
///
/// 与 [WidgetShowcase] 的常用组件详情同一套形态：每个类都是 `@PatchEntry`
/// 组件，原生可直接用、JS 侧由 `patch/components/grammar_details.js` 实例化。
///
/// 这里验证四类 Dart 语法能力：
///   - `mixin`：State 混入 `package:hot_module_base` 的 [StateLogMixin]；
///   - `extension`：String 调用 `package:hot_module_base` 的 [StringLogExtension]；
///   - `extends`：普通类单继承（父类字段 / 覆盖方法 / `super` 调用 / 多态）；
///   - `dart:core` 基础 API：`DateTime` / `RegExp` / `StringBuffer` 值类镜像。

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

  /// mixin class / 纯 mixin / 多个 with / 带 super 的 mixin：成员都不内联进最终类，
  /// 由 mixin 原文件产物 + application 类链 + `__mixinHard` 应用。
  String _mixinClassText() {
    final base = Tagged();
    final mixed = LoudTagged();
    final multi = MultiTagged();
    final sup = SuperTagged();
    return 'mixin class：${base.describe()} / ${mixed.describe()} / '
        '多 mixin：${multi.describe()} ${multi.bump()} ${multi.counterText()} / '
        'super：${sup.describe()}';
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
        Text(_mixinClassText(), style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _bump, child: const Text('+1 并打日志')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// mixin class：既能当类，也能被 with
// ---------------------------------------------------------------------------

/// `mixin class` 同时具备两种身份：可实例化 / 被 `extends`，也可被 `with`。
mixin class Tagged {
  String get tag => 'Tagged';

  String describe() => '[$tag]';
}

/// 作为 mixin 应用：消费者产物生成 `_LoudTagged_Tagged` application 类，
/// `__mixinHard` 复制 Tagged 的成员；本类的 `tag` 覆盖 mixin 实现。
class LoudTagged with Tagged {
  @override
  String get tag => 'Loud';
}

/// 纯 mixin：字段 + 方法；被 `with` 时字段由 application 类构造初始化，方法
/// 由 `__mixinHard` 复制（不内联进最终类）。
mixin CounterM {
  int hits = 0;

  int bump() => ++hits;

  String counterText() => 'hits=$hits';
}

/// 多个 `with`：Tagged → CounterM 的 application 类链，后者优先级更高。
class MultiTagged with Tagged, CounterM {
  @override
  String get tag => 'Multi';
}

/// 带 super 的 mixin：`describe` 在 application 类里重新发射，原生 super 指向
/// 上一层（Tagged 的 describe）。
mixin SuperM on Tagged {
  @override
  String describe() => 'super:${super.describe()}';
}

class SuperTagged with Tagged, SuperM {
  @override
  String get tag => 'Super';
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

// ---------------------------------------------------------------------------
// dart:core 基础 API：DateTime / RegExp / StringBuffer
// ---------------------------------------------------------------------------

/// `DateTime` / `RegExp` / `StringBuffer` 在 JS 侧没有同名可用的内建类型，
/// 由 `patch/flutter.js` 的值类区提供一比一镜像（`new DateTime({...})` /
/// `new RegExp({source})` / `new StringBuffer({})`）。
///
/// 页面把三类 API 的常用成员集中跑一遍：一边看原生结果，一边看 JS 热更结果。
@PatchEntry('BasicApiDetail')
class BasicApiDetail extends StatefulWidget {
  const BasicApiDetail({super.key});

  @override
  State<BasicApiDetail> createState() => _BasicApiDetailState();
}

class _BasicApiDetailState extends State<BasicApiDetail> {
  DateTime _now = DateTime.now();

  void _refresh() {
    setState(() => _now = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    // ---- DateTime：构造 / 加减 / 差值 / 比较 / 解析 / 格式化 ----
    final start = DateTime(2024, 3, 1, 9, 30);
    final end = start.add(const Duration(hours: 2, minutes: 45));
    final span = end.difference(start);
    final parsed = DateTime.parse('2024-03-01T09:30:00Z');
    final order = end.isAfter(start) ? 'end 晚于 start' : 'end 不晚于 start';

    // ---- RegExp：hasMatch / firstMatch / allMatches / 捕获分组 ----
    final text = '订单 A1001，金额 128.50 元，数量 3 件';
    final digitRe = RegExp(r'\d+');
    final hasDigits = digitRe.hasMatch(text);
    final firstDigits = digitRe.firstMatch(text);
    final allDigits = digitRe.allMatches(text);
    final priceRe = RegExp(r'(\d+)\.(\d+)');
    final price = priceRe.firstMatch(text);
    final priceText =
        price == null ? '未匹配' : '整数 ${price.group(1)}，小数 ${price.group(2)}';

    // ---- StringBuffer：write / writeln / length / clear ----
    final buffer = StringBuffer();
    buffer.write('匹配到 ');
    buffer.write(allDigits.length);
    buffer.writeln(' 段数字');
    buffer.write('首个片段：');
    buffer.write(firstDigits == null ? '无' : firstDigits.group(0));
    final built = buffer.toString();
    buffer.clear();
    final clearedEmpty = buffer.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'dart:core 基础 API（DateTime / RegExp / StringBuffer）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '与 Dart 同名同义的 JS 镜像：构造、成员、静态工厂均一比一。',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        const Text('DateTime', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('now().toIso8601String() → ${_now.toIso8601String()}'),
        Text('DateTime(2024, 3, 1, 9, 30) → $start'),
        Text('add(Duration(hours: 2, minutes: 45)) → $end'),
        Text('difference(start) → ${span.inMilliseconds} ms'),
        Text('isAfter(start) → $order'),
        Text("parse('2024-03-01T09:30:00Z').toUtc() → ${parsed.toUtc()}"),
        const SizedBox(height: 16),
        const Text('RegExp', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('待匹配文本：$text'),
        Text("RegExp(r'\\d+').hasMatch(text) → $hasDigits"),
        Text(
          'firstMatch(text).group(0) → '
          '${firstDigits == null ? '无' : firstDigits.group(0)}',
        ),
        Text('allMatches(text).length → ${allDigits.length}'),
        Text("RegExp(r'(\\d+)\\.(\\d+)') 分组 → $priceText"),
        const SizedBox(height: 16),
        const Text('StringBuffer', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('write / writeln 拼接 → ${built.replaceAll('\n', ' ⏎ ')}'),
        Text('clear() 后 isEmpty → $clearedEmpty'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _refresh,
          child: const Text('重新计算 DateTime.now()'),
        ),
      ],
    );
  }
}
