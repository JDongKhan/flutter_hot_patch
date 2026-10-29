import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 命令式弹层演示：`showDialog` + AlertDialog。
///
/// - 「打开」按钮 → `showDialog<bool>(context: …, builder: …)`，返回的 Future
///   在关闭时结算：点「确定」回传计数值，点「取消」/遮罩/返回键回传 null；
/// - 弹层内容是**独立的 JS 根**：里面的「+1」只重建弹层那一小块，页面本身
///   不会跟着重建（与 Flutter 里 dialog 是独立路由的效果一致）；
/// - `barrierDismissible: false` 的变体：点遮罩/返回键都关不掉，只能用按钮。
///
/// 一比一翻译说明：
///   - `showDialog` 是裸顶层调用 → 运行时注入的同名全局函数（见
///     builders/runtime/js/portal_js.dart），实参按具名形态打成配置对象；
///   - `builder` 闭包在 JS 侧执行一次，产出的元素树挂在独立根上，跨桥只传
///     面板 key + 标量参数；
///   - `Navigator.of(context).pop(v)` 在弹层里等价于 `Navigator.pop(context, v)`：
///     关闭请求发回宿主 pop 路由，结果留在 JS 端结算 Future。
@PatchEntry('DialogDetail')
class DialogDetail extends StatefulWidget {
  const DialogDetail({super.key});

  @override
  State<DialogDetail> createState() => _DialogDetailState();
}

class _DialogDetailState extends State<DialogDetail> {
  String _last = '（还没有关闭过弹层）';
  int _opens = 0;

  /// `showDialog` 的返回值：确定 → 计数，其余关闭方式 → null。
  void _open({required bool dismissible}) {
    setState(() => _opens += 1);
    showDialog<Object?>(
      context: context,
      barrierDismissible: dismissible,
      builder: (ctx) => DialogContent(dismissible: dismissible),
    ).then((v) => _record(v));
  }

  void _record(Object? v) {
    setState(() {
      _last = v == null ? '已关闭：null（取消 / 遮罩 / 返回键）' : '已关闭：$v';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('showDialog', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '弹层内容由 JS 侧 builder 建树并挂在独立根上；返回值经 Future 回传',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () => _open(dismissible: true),
              child: const Text('打开 AlertDialog'),
            ),
            OutlinedButton(
              onPressed: () => _open(dismissible: false),
              child: const Text('打开（点遮罩不关）'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('打开次数：$_opens', style: const TextStyle(fontSize: 12)),
              Text('最近结果：$_last', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

/// 弹层内容：自己持有一份状态（计数），证明弹层是独立重建的 JS 根。
class DialogContent extends StatefulWidget {
  const DialogContent({super.key, required this.dismissible});

  final bool dismissible;

  @override
  State<DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<DialogContent> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('JS 弹层'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这个 AlertDialog 的整棵树在 JS 侧构建，「+1」只重建本弹层',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text('计数：$_count', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            widget.dismissible ? 'barrierDismissible: true' : 'barrierDismissible: false',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _count += 1),
          child: const Text('+1'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop('确定，计数 = $_count'),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
