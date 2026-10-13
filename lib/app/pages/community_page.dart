import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

import '../../base/app_router.dart';
import '../model/app_data.dart';
import '../model/app_models.dart';
import 'detail_pages.dart';

/// 社区 tab（`@UIComponentIgnore` → 不参与连带翻译，运行时原生注入）。
///
/// 对应 docs/app-prototype.html 的「社区」：广场/推荐双 tab + 横向资源推荐
/// + 排序快捷条 + 「筛选」下拉面板（从顶部展开，面板内四组条件：排序方式 /
/// 内容类型 / 距离范围 / 价格区间）+ 帖子列表。
///
/// 筛选面板用页面内 [Stack] 实现：面板 top 位置在打开时按筛选条的**实际
/// 布局位置**测量，避免写死高度。
///
/// 本页用了翻译器覆盖不到的构造（GlobalKey/RenderBox 实测布局、
/// `.where().toList()` 过滤、集合 for-if 展开、build 内局部变量），强行连带
/// 翻译会产出空的 `build()`；故显式标 `@UIComponentIgnore()` 退出翻译，
/// 在外壳产物里保持 `Component` 占位结点，由宿主 `nativeComponents` 原生注入。
@UIComponentIgnore()
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _barKey = GlobalKey();

  String _tab = kCommunityTabs.first;
  bool _filterOpen = false;
  double _panelTop = 0;

  // 筛选条件（与原型 state.filters 对应）。
  String _sort = kSorts.first;
  String _type = kPostTypes.first;
  String _dist = kDists.first;
  String _price = kPriceRanges.first;

  /// 按「内容类型 + 排序方式」过滤列表（距离/价格在原型的示例数据里无对应字段，
  /// 仅作为可选条件参与面板交互）。
  List<Post> get _visiblePosts {
    var list = kPosts
        .where((p) => _type == kPostTypes.first || p.type == _type)
        .toList();
    switch (_sort) {
      case '最新':
        list = list.reversed.toList();
      case '最热':
        list = list.toList()..sort((a, b) => b.like.compareTo(a.like));
    }
    return list;
  }

  void _toggleFilter() {
    if (_filterOpen) {
      setState(() => _filterOpen = false);
      return;
    }
    // 面板紧贴筛选条下沿：按实际布局测量（不写死高度）。
    var top = 0.0;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final barBox = _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox != null && barBox != null) {
      final dy = barBox.localToGlobal(Offset.zero, ancestor: stackBox).dy;
      top = dy + barBox.size.height;
    }
    setState(() {
      _panelTop = top;
      _filterOpen = true;
    });
  }

  void _resetFilter() {
    setState(() {
      _sort = kSorts.first;
      _type = kPostTypes.first;
      _dist = kDists.first;
      _price = kPriceRanges.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final posts = _visiblePosts;
    return Stack(
      key: _stackKey,
      children: [
        Column(
          children: [
            // 顶部双 tab（广场 / 推荐）
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: Row(
                    children: [
                      for (final t in kCommunityTabs)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _tab = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _tab == t
                                    ? const Color(0xFFE8F2FF)
                                    : const Color(0xFFF3F5F8),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: _tab == t
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _tab == t
                                      ? kBrand
                                      : const Color(0xFF5C6270),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => appToast(context, '发布新动态（演示）'),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F5F8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Color(0xFF5C6270),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  const SizedBox(height: 10),
                  // 横向资源推荐
                  SizedBox(
                    height: 116,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: kResources.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => _ResourceCard(
                        resource: kResources[i],
                        onTap: () => AppRouter.openResource(kResources[i].id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 排序快捷条 + 筛选入口
                  Container(
                    key: _barKey,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        for (final s in kSorts)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => _sort = s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _sort == s
                                      ? const Color(0xFFE8F2FF)
                                      : const Color(0xFFF3F5F8),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: _sort == s
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _sort == s
                                        ? kBrand
                                        : const Color(0xFF5C6270),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _toggleFilter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _filterOpen
                                  ? const Color(0xFFE8F2FF)
                                  : const Color(0xFFF3F5F8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '筛选',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _filterOpen
                                        ? kBrand
                                        : const Color(0xFF5C6270),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.tune,
                                  size: 14,
                                  color: _filterOpen
                                      ? kBrand
                                      : const Color(0xFF5C6270),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 帖子列表
                  if (posts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          '没有符合条件的帖子，试试放宽筛选条件',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF98A0AC),
                          ),
                        ),
                      ),
                    )
                  else
                    for (final p in posts)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                        child: _PostCard(
                          post: p,
                          onTap: () => AppRouter.openPost(p.id),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
        // 筛选面板（从顶部下拉展开）
        if (_filterOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleFilter,
              child: Container(color: const Color(0x66000000)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: _panelTop,
            child: _FilterPanel(
              sort: _sort,
              type: _type,
              dist: _dist,
              price: _price,
              onPick: (key, value) => setState(() {
                switch (key) {
                  case 'sort':
                    _sort = value;
                  case 'type':
                    _type = value;
                  case 'dist':
                    _dist = value;
                  case 'price':
                    _price = value;
                }
              }),
              onReset: _resetFilter,
              onApply: _toggleFilter,
            ),
          ),
        ],
      ],
    );
  }
}

/// 横向资源卡：图 + 标题/副标题。
class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource, required this.onTap});

  final Resource resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 156,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 68,
              width: double.infinity,
              child: Image.network(
                resource.img,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) =>
                    Container(height: 68, color: const Color(0xFFE8EBF0)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    resource.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF98A0AC),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 帖子卡片：左图右文 + 作者/时间/点赞页脚。
class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  static String _likeText(int n) =>
      n > 999 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                post.img,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  width: 92,
                  height: 92,
                  color: const Color(0xFFE8EBF0),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: SizedBox(
                height: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        post.sub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8B909A),
                          height: 1.5,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F5F8),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            post.type,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF5C6270),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.author} · ${post.time}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFA3A9B4),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.favorite_border,
                          size: 13,
                          color: Color(0xFFA3A9B4),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _likeText(post.like),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFA3A9B4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶部下拉筛选面板：四组条件 chips + 重置 / 查看结果。
class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.sort,
    required this.type,
    required this.dist,
    required this.price,
    required this.onPick,
    required this.onReset,
    required this.onApply,
  });

  final String sort;
  final String type;
  final String dist;
  final String price;
  final void Function(String key, String value) onPick;
  final VoidCallback onReset;
  final VoidCallback onApply;

  Widget _group(String title, String key, List<String> values, String current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171A21),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              GestureDetector(
                onTap: () => onPick(key, v),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: current == v ? kBrand : const Color(0xFFF3F5F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    v,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: current == v
                          ? Colors.white
                          : const Color(0xFF5C6270),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _group('排序方式', 'sort', kSorts, sort),
            const SizedBox(height: 16),
            _group('内容类型', 'type', kPostTypes, type),
            const SizedBox(height: 16),
            _group('距离范围', 'dist', kDists, dist),
            const SizedBox(height: 16),
            _group('价格区间', 'price', kPriceRanges, price),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onReset,
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F8),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: const Text(
                        '重置',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C6270),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onApply,
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kBrand,
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: const Text(
                        '查看结果',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
