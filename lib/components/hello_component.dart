import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';
import 'package:flutter_hot/model/user.dart';

/// 本文件演示两个能力：
///   1. HelloCard —— 一个**完全正常的 Flutter StatefulWidget**（原生可直接用）
///   2. 单文件多组件 —— HelloPanel 与 HelloCard 同文件，codegen 都注册进 JS
///   3. 同文件静态样式类 —— PanelColors 与本组件同文件，codegen inline 进
///      同一产物（const PanelColors = {...}），build 里 `PanelColors.background`
///      直接翻译成 JS 表达式引用，无需 import 独立产物。
///
/// 注解仅 @UIComponent('组件名') 一个类级注解，其余全量生成：
///   - 所有非 static 基础类型字段 → JS 属性（一比一，_count → _count）
///   - 所有非生命周期方法 → JS 方法（一比一，inc → inc）
///   - SnackBar 形式的方法 → 自动 native 通道（nativeToast）
///   - build() 原封不动翻译成 JS build()
///
/// 构建期由 ui_component_generator 静态翻译出：
///   hello_component.component.js（注册 HelloCard + HelloPanel）
/// 线上出 bug 时，运行时把组件切换为 HotPatchWidget 加载 JS 版本即可热修复，
/// 组件本体永远保持可正常使用。
@UIComponent('HelloCard')
class HelloCard extends StatefulWidget {
  const HelloCard({super.key});

  @override
  State<HelloCard> createState() => _HelloCardState();
}

class _HelloCardState extends State<HelloCard> {
  // 无注解：自动成为 JS 属性 `_count`
  int _count = 0;

  // 模型类型字段：按调用链进 JS 属性（this._user = null）
  User? _user;

  // 无注解：自动成为 JS 方法 `inc`
  void inc() {
    setState(() => _count++);
  }

  // 模拟网络请求：await Future.delayed → Promise/setTimeout；
  // setState 里构造 User（模型）→ new User({name, age})
  Future<void> loadUser() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _user = const User(name: 'Alice', age: 18);
    });
  }

  // 无注解：自动成为 JS 方法 `reset`
  void reset() {
    setState(() {
      _count = 0;
    });
  }

  // 无注解：方法体是 SnackBar 形式 → 自动 native 通道 `nativeToast`
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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text('count = $_count'),
        Text('user: ${_user?.name ?? '加载中'}'),
        Text('age: ${_user?.age ?? '-'}'),
        Row(
          children: [
            ElevatedButton(
              onPressed: inc,
              style: ElevatedButton.styleFrom(
                backgroundColor: PanelColors.background,
                foregroundColor: Colors.white,
              ),
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
            ElevatedButton(
              onPressed: loadUser,
              child: const Text('Load User'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 同文件静态样式类：与本组件同文件，由 codegen inline 进同一产物
/// （const PanelColors = {...}），组件 build 里 `PanelColors.xxx` 直接引用，
/// 不产生独立单例产物、不 import。
class PanelColors {
  static Color background = const Color(0xFFFF0000);
  static const Color primary = Color(0xFF6750A4);
  static const String tagline = 'demo';
}

/// 单文件多组件演示：与 HelloCard 同文件、同产物，注册为第二个组件。
@UIComponent('HelloPanel')
class HelloPanel extends StatefulWidget {
  const HelloPanel({super.key});

  @override
  State<HelloPanel> createState() => _HelloPanelState();
}

class _HelloPanelState extends State<HelloPanel> {
  // 全量生成：_taps → JS 属性 `_taps`
  int _taps = 0;

  // 全量生成：tap → JS 方法 `tap`
  void tap() {
    setState(() => _taps++);
  }

  // 全量生成：clear → JS 方法 `clear`
  void clear() {
    setState(() {
      _taps = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'HelloPanel (JS)',
          style: const TextStyle(fontSize: 20),
        ),
        Text('taps = $_taps'),
        Row(
          children: [
            ElevatedButton(
              onPressed: tap,
              child: const Text('Tap'),
            ),
            ElevatedButton(
              onPressed: () => clear(),
              child: const Text('Clear'),
            ),
          ],
        ),
      ],
    );
  }
}
