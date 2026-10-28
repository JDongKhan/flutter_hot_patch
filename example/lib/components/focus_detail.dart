import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// Focus 演示：FocusNode 显式控制焦点。
///
/// - 三个可聚焦块：A / B 可聚焦，C 声明 `canRequestFocus: false`；
/// - 按钮调用 `FocusNode.requestFocus()` / `unfocus()`；
/// - `onFocusChange` 每次焦点变化记一条日志；
/// - 块的颜色读 `hasFocus`（JS 侧是宿主回传的镜像，addListener 后即时刷新）。
///
/// 一比一翻译说明：
///   - `FocusNode(debugLabel: …)` 构造参数经句柄 meta 下发，宿主真实节点一致；
///   - `_node.addListener(_refresh)` 在 JS 侧同样是 ChangeNotifier 语义
///     （宿主 Focus 每次焦点变化回传 hasFocus → 触发 listener）；
///   - `onFocusChange: (v) {…}` 形参声明为 `ValueChanged<bool>`，生成器按形参
///     类型识别为事件 → JS 侧收到的就是 bool；
///   - `canRequestFocus: false` 的块点了不会获得焦点（与原生一致）。
@PatchEntry('FocusDetail')
class FocusDetail extends StatefulWidget {
  const FocusDetail({super.key});

  @override
  State<FocusDetail> createState() => _FocusDetailState();
}

class _FocusDetailState extends State<FocusDetail> {
  final FocusNode _a = FocusNode(debugLabel: 'node-a');
  final FocusNode _b = FocusNode(debugLabel: 'node-b');

  String _log = '（暂无焦点变化）';

  @override
  void initState() {
    super.initState();
    // 焦点变化 → 重建（块颜色读 hasFocus）。
    _a.addListener(_refresh);
    _b.addListener(_refresh);
  }

  @override
  void dispose() {
    _a.removeListener(_refresh);
    _b.removeListener(_refresh);
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {});
  }

  void _record(String label, bool hasFocus) {
    setState(() {
      _log = hasFocus ? '$label 获得焦点' : '$label 失去焦点';
    });
  }

  String get _current {
    if (_a.hasFocus) return 'A';
    if (_b.hasFocus) return 'B';
    return '无';
  }

  Widget _box(String label, FocusNode node) {
    return Focus(
      focusNode: node,
      onFocusChange: (v) => _record(label, v),
      child: GestureDetector(
        onTap: () => node.requestFocus(),
        child: Container(
          width: 80,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: node.hasFocus ? Colors.deepPurple : Colors.grey.shade200,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: node.hasFocus ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Focus / FocusNode', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '点块或按钮切换焦点；C 声明 canRequestFocus: false，点了不聚焦',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _box('A', _a),
            const SizedBox(width: 12),
            _box('B', _b),
            const SizedBox(width: 12),
            Focus(
              canRequestFocus: false,
              child: Container(
                width: 80,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: const Text('C\n(不可聚焦)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('当前聚焦：$_current', style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6),
        Text('变化日志：$_log', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(onPressed: () => _a.requestFocus(), child: const Text('聚焦 A')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: () => _b.requestFocus(), child: const Text('聚焦 B')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: () => _a.unfocus(), child: const Text('失焦')),
          ],
        ),
      ],
    );
  }
}
