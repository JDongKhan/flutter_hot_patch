import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// KeyboardListener 演示：原始按键事件（不经过输入框 / 手势）。
///
/// - 面板是 KeyboardListener 的孩子，获得焦点后接收全部按键；
/// - 方向键移动方块、空格切换颜色、Esc 复位；
/// - KeyDown / KeyRepeat / KeyUp 分别计数，并显示最近一次按键的
///   `logicalKey.keyLabel` / `character` / `physicalKey.debugName`。
///
/// 一比一翻译说明：
///   - `onKeyEvent` 形参声明为 `ValueChanged<KeyEvent>`，生成器按形参类型
///     识别为事件 → JS 侧收到的就是 KeyEvent **实例**（宿主把原生事件归一成
///     JSON，JS 侧还原，见 keyboard_listener_js.dart）；
///   - `event is KeyDownEvent` / `is KeyRepeatEvent` 与 Dart 同名子类判别一致
///     （生成器把 `is` 翻成 `instanceof`）；
///   - `event.logicalKey == LogicalKeyboardKey.escape` 这类比较在 JS 侧按
///     keyId 归一成同一实例，结果与 Dart 一致；
///   - `focusNode` 是同一个 FocusNode 句柄：按钮 `requestFocus()` 走宿主 op。
@PatchEntry('KeyboardListenerDetail')
class KeyboardListenerDetail extends StatefulWidget {
  const KeyboardListenerDetail({super.key});

  @override
  State<KeyboardListenerDetail> createState() => _KeyboardListenerDetailState();
}

class _KeyboardListenerDetailState extends State<KeyboardListenerDetail> {
  final FocusNode _node = FocusNode(debugLabel: 'keyboard-listener-demo');

  int _row = 1;
  int _col = 1;
  bool _lit = false;

  int _down = 0;
  int _up = 0;
  int _repeat = 0;

  String _last = '（还没有按键：点一下面板再按方向键）';
  String _char = '（无）';
  String _phys = '（无）';

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent) {
      setState(() {
        _down += 1;
        _last = 'KeyDown  ${key.keyLabel}';
        _char = event.character ?? '（无）';
        _phys = event.physicalKey.debugName ?? '（无）';
        if (key == LogicalKeyboardKey.arrowUp) _row = (_row + 2) % 3;
        if (key == LogicalKeyboardKey.arrowDown) _row = (_row + 1) % 3;
        if (key == LogicalKeyboardKey.arrowLeft) _col = (_col + 2) % 3;
        if (key == LogicalKeyboardKey.arrowRight) _col = (_col + 1) % 3;
        if (key == LogicalKeyboardKey.space) _lit = !_lit;
        if (key == LogicalKeyboardKey.escape) {
          _row = 1;
          _col = 1;
          _lit = false;
        }
      });
      return;
    }
    if (event is KeyRepeatEvent) {
      setState(() {
        _repeat += 1;
      });
      return;
    }
    setState(() {
      _up += 1;
      _last = 'KeyUp  ${key.keyLabel}';
    });
  }

  Widget _cell(int r, int c) {
    final active = r == _row && c == _col;
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.all(3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? (_lit ? Colors.amber : Colors.deepPurple)
            : Colors.grey.shade200,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Text(
        active ? '●' : '',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _gridRow(int r) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_cell(r, 0), _cell(r, 1), _cell(r, 2)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('KeyboardListener', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '方向键移动方块，空格切换颜色，Esc 复位；KeyDown / KeyRepeat / KeyUp 分别计数',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        KeyboardListener(
          focusNode: _node,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_gridRow(0), _gridRow(1), _gridRow(2)],
                ),
                const SizedBox(height: 8),
                Text('最近事件：$_last', style: const TextStyle(fontSize: 12)),
                Text('字符 character：$_char', style: const TextStyle(fontSize: 12)),
                Text('物理键：$_phys', style: const TextStyle(fontSize: 12)),
                Text(
                  'KeyDown $_down · KeyRepeat $_repeat · KeyUp $_up',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => _node.requestFocus(),
              child: const Text('让面板获得焦点'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _row = 1;
                  _col = 1;
                  _lit = false;
                });
              },
              child: const Text('复位方块'),
            ),
          ],
        ),
      ],
    );
  }
}
