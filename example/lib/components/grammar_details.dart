import 'package:flutter/material.dart';
import 'package:hot_module_base/hot_module_base.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 基础语法 demo 集合（「基础语法 · 列表」页点击进入）。
///
/// 与 [WidgetShowcase] 的常用组件详情同一套形态：每个类都是 `@PatchEntry`
/// 组件，原生可直接用、JS 侧由 `patch/components/grammar_details.js` 实例化。
///
/// 这里专门验证两类 Dart 语法能力的**跨包**引用：
///   - `mixin`：State 混入 `package:hot_module_base` 的 [StateLogMixin]；
///   - `extension`：String 调用 `package:hot_module_base` 的 [StringLogExtension]。
///
/// 注意：JS 侧对 mixin / extension 的翻译尚未实现，当前只有原生侧生效；
/// 这些 demo 先作为能力落地后的验收用例。

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
