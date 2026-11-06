import 'package:flutter/material.dart';
import 'package:hot_module_base/hot_module_base.dart' as base;
import 'package:hot_patch_annotations/hot_patch_annotations.dart';
import 'package:provider/provider.dart' as p;

import '../model/counter_vm.dart' as vm;

/// import 前缀别名（`as`）demo。
///
/// 验证两类"同名/跨包"引用在 JS 侧仍然正确：
///   - **同名类**：本文件声明的 [User] 与 `package:hot_module_base` 的
///     `base.User` 简单名相同——Dart 里靠前缀区分，JS 侧必须同样分成两个
///     不同的类引用（`User` 与 `base.User`），不能合并成一条；
///   - **包模块类**：`p.ChangeNotifierProvider` / `p.Consumer` 来自
///     `package:provider` 的 `patch/provider.js`，别名引用同样要落到该模块。
class User {
  const User(this.tag);

  final String tag;

  String describe() => '本地 User($tag)';
}

@PatchEntry('AliasDetail')
class AliasDetail extends StatelessWidget {
  const AliasDetail({super.key});

  @override
  Widget build(BuildContext context) {
    // `vm.CounterVm`：同项目内的模型类，经前缀别名引用。
    final counter = vm.CounterVm();
    final local = User('local');
    final remote = base.User(name: 'base', age: 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'import 前缀别名（as）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '同名类与包模块类都靠前缀区分：User / base.User、'
          'p.ChangeNotifierProvider / p.Consumer。',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Text('本地同名类 → ${local.describe()}'),
        Text('包前缀的同名类 → ${remote.name} / ${remote.age}'),
        const SizedBox(height: 12),
        p.ChangeNotifierProvider<vm.CounterVm>.value(
          value: counter,
          child: p.Consumer<vm.CounterVm>(
            builder: (ctx, value, child) => Row(
              children: [
                Text('count = ${value.count}'),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: value.inc,
                  child: const Text('inc（经别名取到的 Consumer）'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
