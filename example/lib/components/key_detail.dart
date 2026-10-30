import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import 'key_tile.dart';

/// Key 家族全员用例页（仅 JS 热更版展示：GlobalKey 的量测必须由宿主端算）。
@PatchEntry('KeyDetail')
class KeyDetail extends StatefulWidget {
  const KeyDetail({super.key});

  @override
  State<KeyDetail> createState() => _KeyDetailState();
}

class _KeyDetailState extends State<KeyDetail> {
  // ---- ValueKey：列表按值匹配 ----
  /// 行标签序列。`final` + `clear()` 是 Dart 的惯用写法：clear 是**原地**清空
  /// （保持同一数组实例），JS 侧的 `Array.prototype.clear` 由运行时补齐
  /// （见 hot_patch runtime_js.dart【1c】），故产物原样调用即可。
  final List<String> _names = ['A', 'B', 'C', 'D'];

  // ---- ObjectKey：按对象身份相等 ----
  /// **同一个实例**：字段初始化时建一次，之后每次 build 拿到的都是它 → key 稳定。
  final List<int> _stableObj = [1];

  /// 父级重建次数：只用来证明「父级确实重建了」（两行的 label 都会跟着变），
  /// 而两行的计数表现却相反——差异只可能来自 key 的身份是否稳定。
  int _rebuildSeq = 0;

  // ---- UniqueKey：每次都是新身份（强制重建）----
  int _uniqueSeq = 0;

  // ---- PageStorageKey：滚动位置持久化 ----
  bool _storeA = true;

  // ---- GlobalKey：宿主端量测 + 定位 ----
  final GlobalKey _targetKey = GlobalKey();
  String _measureText = '未测量';

  // ===== 卡片 1：ValueKey vs 无 key =====

  void _rotateNames() {
    setState(() {
      final head = _names[0];
      _names.removeAt(0);
      _names.add(head);
    });
  }

  void _resetNames() {
    setState(() {
      _names.clear();
      _names.add('A');
      _names.add('B');
      _names.add('C');
      _names.add('D');
    });
  }

  Widget _valueKeyRows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '① 带 key：key: ValueKey(name)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        for (var i = 0; i < _names.length; i++)
          KeyTile(
            key: ValueKey(_names[i]),
            index: i,
            label: '${_names[i]}（key）',
          ),
        const SizedBox(height: 10),
        const Text(
          '② 不带 key：按位置匹配',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        for (var i = 0; i < _names.length; i++)
          KeyTile(index: i, label: '${_names[i]}（无 key）'),
      ],
    );
  }

  // ===== 卡片 2：ObjectKey =====

  void _rebuildParent() {
    setState(() => _rebuildSeq++);
  }

  Widget _objectKeyRows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A：key 包的是**字段里的那个实例**——跨帧恒定，身份稳定。
        KeyTile(
          key: ObjectKey(_stableObj),
          index: 0,
          label: 'A · ObjectKey(字段实例) · 父级已重建 $_rebuildSeq 次',
        ),
        // B：key 每次 build 都包一个**新造的** [1]——值一样，身份不同。
        KeyTile(
          key: ObjectKey([1]),
          index: 1,
          label: 'B · ObjectKey(每帧新造 [1]) · 父级已重建 $_rebuildSeq 次',
        ),
      ],
    );
  }

  // ===== 卡片 3：UniqueKey =====

  void _bumpUnique() {
    setState(() => _uniqueSeq++);
  }

  // ===== 卡片 4：PageStorageKey =====

  void _flipStore() {
    setState(() => _storeA = !_storeA);
  }

  Widget _storageView() {
    if (_storeA) {
      return SizedBox(
        height: 150,
        child: ListView(
          key: const PageStorageKey('key-page-a'),
          children: [
            for (var i = 0; i < 12; i++)
              ListTile(dense: true, title: Text('A 行 $i')),
          ],
        ),
      );
    }
    return SizedBox(
      height: 150,
      child: ListView(
        key: const PageStorageKey('key-page-b'),
        children: [
          for (var i = 0; i < 12; i++)
            ListTile(dense: true, title: Text('B 行 $i')),
        ],
      ),
    );
  }

  // ===== 卡片 5：GlobalKey =====

  /// 用 GlobalKey 取目标盒子的位置与尺寸。
  ///
  /// 与 SliverDetail 里同款链路：`currentContext → findRenderObject` 拿到
  /// 「RenderObject 代理」再测——`measure` 挂在代上（GlobalKey 本身没有）。
  /// `dynamic` 中转在这一跳（原生返回 RenderObject、没有 measure()）。
  Future<void> _measureTarget() async {
    final ctx = _targetKey.currentContext;
    if (ctx == null) {
      return;
    }
    final dynamic box = ctx.findRenderObject();
    if (box == null) {
      return;
    }
    final dynamic rect = await box.measure();
    if (rect == null) {
      setState(() => _measureText = '量不到（未布局）');
      return;
    }
    setState(() {
      _measureText =
          'x=${rect.dx.toStringAsFixed(1)} y=${rect.dy.toStringAsFixed(1)}'
          ' · ${rect.width.toStringAsFixed(0)} × ${rect.height.toStringAsFixed(0)}';
    });
  }

  void _scrollToTarget() {
    final ctx = _targetKey.currentContext;
    if (ctx == null) {
      return;
    }
    final target = ctx.findRenderObject();
    if (target == null) {
      return;
    }
    target.showOnScreen();
  }

  // ===== 页面装配 =====

  // 卡片外壳直接写在每个 `_cardXxx()` 里：生成器只支持**无参已声明方法**在
  // widget 位置内联（`_valueKeyRows()` 可以），带实参的 helper 方法无法翻译
  // （会整张卡片降级成占位结点），故不做 `_card(title, desc, child)` 这种共用壳。
  Widget _cardValueKey() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ValueKey · 列表按值匹配',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '换序后看两列计数：① 的状态跟着「行（值）」走，② 的状态留在「位置」上——'
            'reconciler 取 keySig（v:值）做「带 key 优先、无 key 按位置」的匹配。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          _valueKeyRows(),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _rotateNames,
                child: const Text('轮换顺序（A→末尾）'),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: _resetNames, child: const Text('重置')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardObjectKey() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ObjectKey · 按对象身份相等',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ObjectKey 的判据是 identical（是不是**同一个对象实例**），不是值相等。'
            'A 行包的是字段里那个实例（跨帧恒定）→ 父级重建后元素复用、计数保留；'
            'B 行每次 build 都新造一个 [1]（值一样但身份不同）→ 元素不匹配、销毁重建、计数归零。'
            '注意：B 的计数是**被销毁**而不是被藏起来——归零之后回不来。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          _objectKeyRows(),
          const SizedBox(height: 8),
          const Text(
            '操作：先给 A、B 各点几次 +1，再点下面的「父级重建」，对比两行的计数。'
            '选型场景：数据源没有稳定 ID、但你跨帧持有同一批对象实例时用它。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          const Text(
            '补充：Dart 里 ValueKey 按 == 比较、ObjectKey 按 identical 比较。'
            '本例的 [1] 是 List，没有重写 ==（Dart 的 == 对 List 本就是身份比较），'
            '所以这里两者结果相同——本案例要看的是「key 的身份稳不稳定」这件事本身。',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _rebuildParent,
                child: const Text('父级重建（setState 一次）'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardUniqueKey() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'UniqueKey · 每次都是新身份',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '点「重建」触发 setState：子树的 UniqueKey 每次都是新实例（身份新 → 元素不匹配），'
            '整棵子树重建、内部计数归零。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          KeyTile(key: UniqueKey(), index: 0, label: '唯一身份行 #$_uniqueSeq'),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _bumpUnique,
                child: const Text('重建（setState 一次）'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardStorageKey() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PageStorageKey · 滚动位置持久化',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '把 A 列表滚到中间 → 切到 B → 切回 A：位置应回到原处。'
            '值本体走值 codec（__psk），宿主造真实 PageStorageKey，位置由宿主端 PageStorage 存取。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          _storageView(),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _flipStore,
                child: Text(_storeA ? '切到 B 列表' : '切回 A 列表'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardGlobalKey() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'GlobalKey · 宿主端量测 / 定位',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'currentContext → findRenderObject 这条链两端同形，但「值」只能在宿主算：'
            '位置与尺寸经异步桥回填（box.measure()），定位用真实 RenderObject 的 showOnScreen。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            key: _targetKey,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '目标盒子（GlobalKey 挂在这里）',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '测量：$_measureText',
            style: const TextStyle(fontSize: 13, color: Colors.teal),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton(
                onPressed: _measureTarget,
                child: const Text('测量位置与尺寸'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _scrollToTarget,
                child: const Text('定位（showOnScreen）'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Key 家族 · 全部用例'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Text(
              '每一张卡片一种 key 的语义；「计数」是 KeyTile 的内部 State，'
              '用它来观察状态是跟着行走还是跟着位置走。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          _cardValueKey(),
          _cardObjectKey(),
          _cardUniqueKey(),
          _cardStorageKey(),
          _cardGlobalKey(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
