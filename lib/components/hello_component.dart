import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hot/base/account_center.dart';
import 'package:flutter_hot/base/network.dart';
import 'dart:io';
import 'package:ui_component/ui_component.dart';
import 'package:flutter_hot/model/user.dart';

/// 本文件演示两个能力：
///   1. HelloCard —— 一个**完全正常的 Flutter StatefulWidget**（原生可直接用）
///   2. 同文件静态样式类 —— PanelColors 与本组件同文件，codegen inline 进
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
///   hello_component.js（注册 HelloCard）
/// 线上出 bug 时，运行时把组件切换为 JsUiWidget 加载 JS 版本即可热修复，
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
    debugPrint('inc: count=$_count'); // 日志：方法体 → sendMessage('log', 插值)
    setState(() => _count++);
  }

  // 模拟网络请求：await Future.delayed → Promise/setTimeout；
  // setState 里构造 User（模型）→ new User({name, age})
  Future<void> loadUser() async {
    String? name = await AccountCenter.getUserName();
    Map userMap = await Network.post(params: {"name": name});
    print("用户信息:${userMap["code"]}");
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hello from native (JS-driven)')));
  }

  @override
  Widget build(BuildContext context) {
    // return 前的局部逻辑：user 已加载且 age >= 18 → 成人
    final isAdult = _user != null && _user!.age >= 18;
    final debugActive = kDebugMode; // 标志转换：kDebugMode → __isDebug
    final android = Platform.isAndroid; // 标志转换：Platform.isAndroid → __isAndroid
    debugPrint('build: count=$_count debug=$debugActive android=$android'); // 日志 → console.debug
    return Column(
      children: [
        Text(
          'Hello from JS logic 3',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        Text('count = $_count'),
        Text('user: ${_user?.name ?? '加载中'}'),
        Text('age: ${_user?.age ?? '-'}'),
        // 三目运算：状态驱动的文案（count > 3 切换提示）
        Text(_count > 3 ? 'count 已经大于 3，点 Reset 归零' : 'count 还小，继续 +1'),
        // collection-if：按状态条件插入节点（无 else）
        if (_count > 0) Text('当前 count 是正数（if 条件渲染）'),
        // collection-if + else：用户加载与否显示不同节点
        if (_user != null) Text('用户已加载（if + else 渲染）') else Text('用户未加载，点 Load User'),
        // collection-for：循环渲染（循环变量 i 直接参与插值）
        for (var i = 0; i < 3; i++) Text('循环第 $i 个'),
        Row(
          children: [
            ElevatedButton(
              onPressed: inc,
              style: ElevatedButton.styleFrom(
                // 局部变量驱动的样式：isAdult 时按钮变色
                backgroundColor: isAdult ? PanelColors.adult : PanelColors.background,
                foregroundColor: Colors.white,
              ),
              child: const Text('+1'),
            ),
            ElevatedButton(onPressed: () => reset(), child: const Text('Reset')),
            ElevatedButton(onPressed: showNative, child: const Text('Native')),
            ElevatedButton(onPressed: loadUser, child: const Text('Load User')),
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
  static Color adult = const Color(0xFF4CAF50); // 成人态按钮色（绿色）
  static const Color primary = Color(0xFF6750A4);
  static const String tagline = 'demo';
}
