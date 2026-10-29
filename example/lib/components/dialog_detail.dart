import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 命令式弹层演示：覆盖 Flutter「builder 建树 + 独立路由」的全部弹层 API。
///
/// 共同机制（见 packages/hot_patch_generator/lib/src/builders/runtime/js/portal_js.dart）：
///   - `showXxx(options)` 是裸顶层调用 → 运行时注入的同名全局函数，实参按具名
///     形态打成配置对象；
///   - `builder` 闭包在 JS 侧执行**一次**，产出的元素树挂在**独立根**上，
///     跨桥只传「面板 key + 标量 kind/options」；
///   - 关闭统一走宿主路由 pop（遮罩 / 返回键 / `Navigator.pop(ctx, v)`），
///     结果留在 JS 端结算 Future。
///
/// 覆盖清单：
///   - `showDialog` + `AlertDialog`（含 `barrierDismissible: false` 变体）
///   - `showModalBottomSheet`（Material 底部弹层）
///   - `showCupertinoDialog` + `CupertinoAlertDialog`
///   - `showAdaptiveDialog`（iOS/macOS 走 Cupertino，其余走 Material）
///   - `showCupertinoModalPopup` + `CupertinoActionSheet`
///   - `showGeneralDialog` + 自定义 `Dialog`
@PatchEntry('DialogDetail')
class DialogDetail extends StatefulWidget {
  const DialogDetail({super.key});

  @override
  State<DialogDetail> createState() => _DialogDetailState();
}

class _DialogDetailState extends State<DialogDetail> {
  String _last = '（还没有关闭过弹层）';
  int _opens = 0;

  void _openMaterial() {
    setState(() => _opens += 1);
    showDialog<Object?>(
      context: context,
      builder: (ctx) => DialogContent(),
    ).then((v) => _record('showDialog', v));
  }

  void _openNonDismissible() {
    setState(() => _opens += 1);
    showDialog<Object?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DialogContent(barrierDismissible: false),
    ).then((v) => _record('showDialog(barrierDismissible: false)', v));
  }

  void _openSheet() {
    setState(() => _opens += 1);
    showModalBottomSheet<Object?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SheetContent(),
    ).then((v) => _record('showModalBottomSheet', v));
  }

  void _openCupertino() {
    setState(() => _opens += 1);
    showCupertinoDialog<Object?>(
      context: context,
      builder: (ctx) => CupertinoDialogContent(),
    ).then((v) => _record('showCupertinoDialog', v));
  }

  void _openAdaptive() {
    setState(() => _opens += 1);
    showAdaptiveDialog<Object?>(
      context: context,
      builder: (ctx) => CupertinoDialogContent(),
    ).then((v) => _record('showAdaptiveDialog', v));
  }

  void _openCupertinoSheet() {
    setState(() => _opens += 1);
    showCupertinoModalPopup<Object?>(
      context: context,
      builder: (ctx) => ActionSheetContent(),
    ).then((v) => _record('showCupertinoModalPopup', v));
  }

  void _openGeneral() {
    setState(() => _opens += 1);
    showGeneralDialog<Object?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭',
      barrierColor: Colors.black54,
      pageBuilder: (ctx, animation, secondaryAnimation) => const GeneralDialogContent(),
    ).then((v) => _record('showGeneralDialog', v));
  }

  void _record(String label, Object? v) {
    setState(() {
      _last = v == null ? '$label → null（取消 / 遮罩 / 返回键）' : '$label → $v';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('命令式弹层', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '每种弹层的 builder 都在 JS 侧建树并挂到独立根；返回值经 Future 回传',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),

        // ── showDialog + AlertDialog ──
        const Text('showDialog / AlertDialog', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () => _openMaterial(),
              child: const Text('打开'),
            ),
            OutlinedButton(
              onPressed: () => _openNonDismissible(),
              child: const Text('打开（点遮罩不关）'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── showModalBottomSheet ──
        const Text('showModalBottomSheet', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: () => _openSheet(),
          child: const Text('打开底部弹层'),
        ),
        const SizedBox(height: 12),

        // ── Cupertino 三兄弟 ──
        const Text('Cupertino 弹窗 / 动作面板', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => _openCupertino(),
              child: const Text('showCupertinoDialog'),
            ),
            OutlinedButton(
              onPressed: () => _openAdaptive(),
              child: const Text('showAdaptiveDialog'),
            ),
            OutlinedButton(
              onPressed: () => _openCupertinoSheet(),
              child: const Text('showCupertinoModalPopup'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── showGeneralDialog ──
        const Text('showGeneralDialog', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: () => _openGeneral(),
          child: const Text('打开自定义弹窗'),
        ),
        const SizedBox(height: 12),

        // ── 结果回显 ──
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

/// `showDialog` 的弹层内容：自己持有一份状态（计数），证明弹层是独立重建的
/// JS 根——页面 setState 不会连带重建它。
class DialogContent extends StatefulWidget {
  const DialogContent({super.key, this.barrierDismissible = true});

  final bool barrierDismissible;

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
            widget.barrierDismissible ? 'barrierDismissible: true' : 'barrierDismissible: false',
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

/// `showModalBottomSheet` 的弹层内容：Material 底部弹层，带拖拽手柄。
class SheetContent extends StatelessWidget {
  const SheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('底部弹层', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'showModalBottomSheet 的内容同样是 JS 独立根，可拖拽 / 点遮罩关闭',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop('底部确定'),
                  child: const Text('确定'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('取消'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// `showCupertinoDialog` / `showAdaptiveDialog` 的弹层内容（iOS 风格）。
class CupertinoDialogContent extends StatelessWidget {
  const CupertinoDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Cupertino 弹窗'),
      content: const Text(
        'CupertinoAlertDialog 的树也在 JS 侧建好，宿主只负责 push 路由',
        style: TextStyle(fontSize: 12),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop('iOS 风格确定'),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// `showCupertinoModalPopup` 的弹层内容：iOS 动作面板。
class ActionSheetContent extends StatelessWidget {
  const ActionSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('CupertinoActionSheet'),
      message: const Text('由 showCupertinoModalPopup 承载，从底部弹出'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop('选项 A'),
          child: const Text('选项 A'),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop('删除'),
          child: const Text('删除'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(null),
        child: const Text('取消'),
      ),
    );
  }
}

/// `showGeneralDialog` 的弹层内容：完全自定义的 `Dialog`。
class GeneralDialogContent extends StatelessWidget {
  const GeneralDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('showGeneralDialog', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'pageBuilder 建树、barrierLabel / barrierColor 由宿主还原',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop('自定义确定'),
                  child: const Text('确定'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('取消'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
