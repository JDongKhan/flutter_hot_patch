import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 拖拽演示：`Draggable` / `LongPressDraggable` / `DragTarget`。
///
/// 关键点（实现见 packages/hot_patch/lib/src/js_ui/capabilities/drag/ 与生成器
/// 的 runtime/js/drag_js.dart）：
///   - `data` 是**任意 JS 值**（这里是 `Fruit` 实例）。跨桥不传内容，只传按身份
///     索引的 id；事件回到 JS 时 id 换回原引用，所以 `details.data` 与构造时
///     给的 `data` 是同一个对象，`details.data.name` 直接可用。
///   - `feedback` / `childWhenDragging` 是普通 widget 子树，照常由 JS 建树。
///   - `DragTarget.builder(context, candidate, rejected)` 在 JS 里执行：宿主只回传
///     候选/被拒的 id 列表，JS 执行 builder 后把子树以 patch 回填（悬停高亮即
///     这一机制）。
///   - `onWillAccept*` 需要同步返回值，跨语言只能异步，故不参与翻译（恒接受）。
@PatchEntry('DragDetail')
class DragDetail extends StatefulWidget {
  const DragDetail({super.key});

  @override
  State<DragDetail> createState() => _DragDetailState();
}

/// 拖拽负载：对象实例。`details.data` 与它身份相同（不是快照）。
class Fruit {
  const Fruit({required this.name});

  final String name;
}

class _DragDetailState extends State<DragDetail> {
  static const List<Fruit> _fruits = [
    Fruit(name: '苹果'),
    Fruit(name: '香蕉'),
    Fruit(name: '橙子'),
  ];

  int _drops = 0;
  String _log = '（还没有拖拽事件）';
  Fruit? _inBasketA;
  Fruit? _inBasketB;
  String? _longPressDrop;

  void _accept(String label, Fruit? data) {
    setState(() {
      if (label == '篮子 A') {
        _inBasketA = data;
      } else {
        _inBasketB = data;
      }
      _drops += 1;
      _log = data == null ? '$label 收到空数据' : '$label 收到 ${data.name}';
    });
  }

  /// 悬停：`onMove` 带的是当前候选数据的**原对象**。
  void _hover(String label, Fruit? data) {
    if (data == null) return;
    setState(() => _log = '正悬停在 $label：${data.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('拖拽', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'data 是对象实例：跨桥只传身份 id，回到 JS 的 details.data 是同一个对象',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),

        // ── Draggable：把水果拖到篮子 ──
        const Text('Draggable → DragTarget', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final f in _fruits) ...[
              _chip(f),
              const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _basket(label: '篮子 A', fruit: _inBasketA),
            const SizedBox(width: 12),
            _basket(label: '篮子 B', fruit: _inBasketB),
          ],
        ),
        const SizedBox(height: 12),

        // ── LongPressDraggable ──
        const Text('LongPressDraggable（delay 400ms）', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 6),
        Row(
          children: [
            LongPressDraggable<String>(
              data: '长按拖我',
              delay: const Duration(milliseconds: 400),
              onDragStarted: () => setState(() => _log = '长按 400ms 后开始拖动'),
              feedback: _feedbackFace('长按拖我'),
              childWhenDragging: const Opacity(
                opacity: 0.3,
                child: Text('长按拖我'),
              ),
              child: const Text('长按拖我'),
            ),
            const SizedBox(width: 12),
            _longPressBasket(),
          ],
        ),
        const SizedBox(height: 12),

        // ── 事件与结果回显 ──
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
              Text('落篮次数：$_drops', style: const TextStyle(fontSize: 12)),
              Text('长按落点：${_longPressDrop ?? '（空）'}', style: const TextStyle(fontSize: 12)),
              Text('事件：$_log', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  /// 可拖拽的水果片：`feedback` 是拖动中跟随手指的子树，
  /// `childWhenDragging` 是原位留下的替身。
  Widget _chip(Fruit fruit) {
    return Draggable<Fruit>(
      data: fruit,
      onDragStarted: () => setState(() => _log = '开始拖动 ${fruit.name}'),
      onDragEnd: (details) => setState(() {
        _log = details.wasAccepted
            ? '${fruit.name} 被接收（速度 ${details.velocity.pixelsPerSecond.dy}）'
            : '${fruit.name} 没被接收';
      }),
      feedback: _feedbackFace(fruit.name),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _chipFace(fruit.name),
      ),
      child: _chipFace(fruit.name),
    );
  }

  Widget _chipFace(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Text(name),
    );
  }

  Widget _feedbackFace(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade300,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Text(name),
    );
  }

  /// 放果实的篮子：`builder` 在 JS 侧执行，`candidate` 非空时高亮并显示候选名。
  Widget _basket({required String label, required Fruit? fruit}) {
    return DragTarget<Fruit>(
      onAcceptWithDetails: (details) => _accept(label, details.data),
      onMove: (details) => _hover(label, details.data),
      builder: (context, candidate, rejected) {
        final hovering = candidate.length > 0;
        return Container(
          width: 120,
          height: 90,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hovering ? Colors.green.shade100 : Colors.grey.shade100,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(
                hovering
                    ? '松手放入 ${candidate.first?.name ?? ''}'
                    : (fruit == null ? '（空）' : fruit.name),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 长按版的落点：`data` 是字符串，走同一条身份表。
  Widget _longPressBasket() {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => setState(() {
        _longPressDrop = details.data;
        _drops += 1;
        _log = '长按落点收到 ${details.data}';
      }),
      builder: (context, candidate, rejected) {
        final hovering = candidate.length > 0;
        return Container(
          width: 120,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hovering ? Colors.green.shade100 : Colors.grey.shade100,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Text(hovering ? '松手放入' : '长按拖到这里'),
        );
      },
    );
  }
}
