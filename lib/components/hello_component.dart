import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

/// HelloCard —— 一个**完全正常的 Flutter StatefulWidget**：
/// 原生场景直接 `HelloCard()` 使用，功能完整。
///
/// 上面的注解只是构建期元数据（不影响运行）：
///   - @UIComponent('HelloCard')  标记组件，codegen 按注解名生成 JS 版本
///
/// 默认全量生成（无需 @UIProp / @UIAction）：
///   - 所有非 static 字段自动进 JS state（_count → count）
///   - 所有方法自动进 action（inc → inc / reset → reset）
///   - SnackBar 形式的方法自动识别为 native 通道（nativeToast）
/// 注解仅作可选修饰：@UIProp('xx') 自定义状态名 / 强制包含对象字段；
/// @UIAction('xx', native: 'yy') 自定义事件名 / 指定原生通道。
///
/// 构建期由 ui_component_generator 静态翻译出两份产物：
///   hello_component.component.js / hello_component.component.schema.json
/// 线上出 bug 时，运行时把组件切换为 HotPatchWidget 加载 JS 版本即可热修复，
/// 组件本体永远保持可正常使用。
@UIComponent('HelloCard')
class HelloCard extends StatefulWidget {
  const HelloCard({super.key});

  @override
  State<HelloCard> createState() => _HelloCardState();
}

class _HelloCardState extends State<HelloCard> {
  // 无注解：自动成为 state prop `count`
  int _count = 0;

  // 无注解：自动成为 action `inc`
  void inc() {
    setState(() => _count++);
  }

  // 无注解：自动成为 action `reset`
  void reset() {
    setState(() {
      _count = 0;
    });
  }

  // 无注解：方法体是 SnackBar 形式 → 自动成为 native 通道 `nativeToast`
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
