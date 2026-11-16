import 'package:flutter/material.dart';
import 'package:hot_module_base/hot_module_base.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// mixin 语法 demo：
///   - State 混入跨包 `package:hot_module_base` 的 [StateLogMixin]；
///   - `mixin class`、纯 `mixin`、多个 `with`、带 `super` 的 mixin。
///
/// 成员都不内联进最终类：由 mixin 原文件产物 + application 类链 + `__mixinHard` 应用。
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
    setState(() => _count = increment(_count));
  }

  /// mixin class / 纯 mixin / 多个 with / 带 super 的 mixin。
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
        const Text('State 混入 StateLogMixin（跨包 mixin）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
