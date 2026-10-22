import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'banner_component.dart';

/// 复合组件演示：build() 里使用**其他自定义 widget**。
///
/// 两种形态：
///   1. `BannerCard()` —— 有 @PatchEntry 注解：JS 版递归渲染为嵌套组件结点
///      （运行时 new 嵌套实例 + 事件回流），原生版直接嵌组件。
///   2. `_LabeledDivider()` —— 无注解的 lib 自定义 widget：原生版直接使用；
///      JS 版渲染为可见占位提示（该类型未在宿主注册原生实现）。
@PatchEntry('DashboardCard')
class DashboardCard extends StatefulWidget {
  const DashboardCard({super.key});

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  // 全量生成：_ticks → JS 属性 `_ticks`
  int _ticks = 0;

  // 全量生成：tick → JS 方法 `tick`
  void tick() {
    setState(() => _ticks++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Dashboard (JS)',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        Text('ticks = $_ticks'),
        // 有注解的自定义组件：JS 版递归渲染 BannerCard（含其自身状态）
        const BannerCard(),
        const SizedBox(height: 12),
        // 私有组件（_ 开头）：@PatchIgnore 退出翻译，运行时由原生注入实现渲染；
        // 它的 child slot 会原样传给 registerNativeComponent 的 JsRenderContext。
        const _LabeledDivider(
          text: 'private widget',
          child: Text('native child slot'),
        ),
        const SizedBox(height: 8),
        // 非私有组件：同文件 public widget，会被生成器连带翻译成 JS 类。
        const LabeledDivider(text: 'public widget'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: tick,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Tick'),
        ),
      ],
    );
  }
}

/// 私有组件（_ 开头）：默认生成器递归翻译成 JS 注册进同一产物。
/// 这里标 @PatchIgnore 演示「不参与连带转换」：生成器跳过
/// 翻译（产物里无该 JS 类），build 树保留 `_LabeledDivider` 类型名结点（未注册），
/// 运行时由业务方在 `main()` 里注册原生实现（registerNativeComponent）渲染。
@PatchIgnore()
class _LabeledDivider extends StatelessWidget {
  const _LabeledDivider({required this.text, this.child});

  final String text;

  /// 子组件 slot：验证 registerNativeComponent 能拿到 children。
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('— $text —', style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        // ignore: use_null_aware_elements - 生成器当前只支持 if-element 形式
        if (child != null) child!,
      ],
    );
  }
}

/// 非私有组件：同文件 public widget，JS 侧会被连带翻译成 JS 类；
/// `_LabeledDivider` 的原生注册实现也复用它来渲染。
class LabeledDivider extends StatelessWidget {
  const LabeledDivider({super.key, required this.text, this.child});

  final String text;

  /// 原生注入实现渲染的 child slot（JS 侧翻译时同样作为子结点）。
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '★ $text ★',
          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
        ),
        // ignore: use_null_aware_elements - 生成器当前只支持 if-element 形式
        if (child != null) child!,
      ],
    );
  }
}
