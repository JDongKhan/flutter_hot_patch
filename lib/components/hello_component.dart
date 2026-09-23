import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

/// HelloCard —— 一个**完全正常的 Flutter StatefulWidget**：
/// 原生场景直接 `HelloCard()` 使用，功能完整。
///
/// 上面的注解只是构建期元数据（不影响运行）：
///   - @UIComponent('HelloCard')  标记组件，codegen 按注解名生成 JS 版本
///   - @UIProp('count')           标记 State 里需要同步到 JS 的状态字段
///   - @UIAction('inc')           标记可被 JS 调用的事件方法
///   - @UIAction(native: ...)     标记需要回调原生（SnackBar）的动作
///
/// 构建期由 ui_component_generator 静态翻译出两份产物：
///   hello_component.component.js / hello_component.component.schema.json
/// 线上出 bug 时，运行时把组件切换为 JsWidget 加载 JS 版本即可热修复，
/// 组件本体永远保持可正常使用。
@UIComponent('HelloCard')
class HelloCard extends StatefulWidget {
  const HelloCard({super.key});

  @override
  State<HelloCard> createState() => _HelloCardState();
}

class _HelloCardState extends State<HelloCard> {
  @UIProp('count')
  int _count = 0;

  @UIAction('inc')
  void inc() {
    setState(() => _count++);
  }

  @UIAction('reset')
  void reset() {
    setState(() {
      _count = 0;
    });
  }

  @UIAction('native', native: 'nativeToast')
  void showNative() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hello from native (JS-driven)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Hello from JS logic',
          style: const TextStyle(fontSize: 20),
        ),
        Text('count = $_count'),
        Row(
          children: [
            ElevatedButton(
              onPressed: inc,
              child: const Text('+1'),
            ),
            ElevatedButton(
              onPressed: () => reset(),
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: showNative,
              child: const Text('Native'),
            ),
          ],
        ),
      ],
    );
  }
}
