import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// AutomaticKeepAlive 演示：TabBarView 切页时，State 是否随离屏页销毁。
///
/// - 左页「保活页」的 State 混入 [AutomaticKeepAliveClientMixin] 且
///   `wantKeepAlive` 恒为 true：切走时 element 被 Flutter 的 KeepAlive 留住，
///   切回来计数、State 原样保留；
/// - 右页「不保活页」不声明 `wantKeepAlive`：切走即销毁，切回来计数归零。
///
/// 一比一翻译说明：
///   - mixin 在 JS 侧只体现为 State 实例上的 `wantKeepAlive` 布尔声明，产物里
///     `get wantKeepAlive()` 原样保留；运行时在懒槽位挂载 / 父级重建 / 组件自身
///     重建后把声明经占位结点的 `__keepAlive` 同步给宿主（见组件支持文档 §8.2）。
///   - `super.build(context)` 是 mixin 的契约；`wantKeepAlive` 为常量 true 时
///     生成器按文档约定省略该调用，两边行为一致。
///   - TabBarView 是懒容器：离屏页由宿主 element 生命周期驱动挂载 / 卸载，
///     所以「切走再切回」能真实检验保活声明是否生效。
@PatchEntry('AutomaticKeepAliveDetail')
class AutomaticKeepAliveDetail extends StatelessWidget {
  const AutomaticKeepAliveDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SizedBox(
        height: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '先点「+1」再看：切到另一页，然后切回来对比计数',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TabBar(
              tabs: [
                const Tab(text: '保活页'),
                const Tab(text: '不保活页'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const _KeepAlivePage(),
                  const _PlainPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 保活页：`wantKeepAlive` 恒为 true，离屏不销毁。
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage();

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  int _count = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '保活页 · wantKeepAlive = true',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '切走再回来：计数保留',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Text('当前计数：$_count', style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => setState(() {
              _count++;
            }),
            child: const Text('+1'),
          ),
        ],
      ),
    );
  }
}

/// 不保活页：不声明 `wantKeepAlive`，切走即销毁。
class _PlainPage extends StatefulWidget {
  const _PlainPage();

  @override
  State<_PlainPage> createState() => _PlainPageState();
}

class _PlainPageState extends State<_PlainPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '不保活页 · 未声明 wantKeepAlive',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '切走再回来：计数归零',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Text('当前计数：$_count', style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => setState(() {
              _count++;
            }),
            child: const Text('+1'),
          ),
        ],
      ),
    );
  }
}
