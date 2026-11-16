import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';
import 'package:provider/provider.dart';

import '../../base/app_router.dart';
import '../model/app_models.dart';
import '../vm/community_vm.dart';
import '../widgets/load_error_view.dart';
import 'detail_pages.dart';

/// 社区 tab（`@PatchEntry` → 连带翻译，产物 patch/app/pages/community_page.js）。
///
/// 对应 docs/app-prototype.html 的「社区」：广场/推荐双 tab + 横向资源推荐
/// + 排序快捷条 + 「筛选」下拉面板 + 帖子列表。
///
/// 页面数据与交互状态收敛到 [CommunityVm]（provider）：页面只订阅 VM，
/// 接口请求 / 筛选条件 / 面板开关都在 VM 内。
@PatchEntry()
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CommunityVm>(
      create: (_) => CommunityVm()..load(),
      child: const CommunityView(),
    );
  }
}

/// 社区视图：订阅 [CommunityVm]。
class CommunityView extends StatefulWidget {
  const CommunityView({super.key});

  @override
  State<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView>
    with AutomaticKeepAliveClientMixin {
  /// 横向资源列表项：懒加载 builder 会抽成实例方法，VM 从当前 context 读取，
  /// 不依赖 build 里的局部变量（否则产物里会成为未定义自由变量）。
  Widget _buildResourceItem(BuildContext context, int i) {
    final List<Resource> resources = context.read<CommunityVm>().resources!;
    return _ResourceCard(
      resource: resources[i],
      onTap: () => AppRouter.openResource(resources[i].id),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 契约
    final vm = context.watch<CommunityVm>();
    final feed = vm.feed;
    final resources = vm.resources;
    // 失败后必须退出 loading 态：给出异常信息与重试入口。
    final error = vm.feedError ?? vm.resourcesError;
    if (feed == null || resources == null) {
      if (error != null) {
        return LoadErrorView(message: error, onRetry: vm.retry);
      }
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
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
                  for (final t in feed.tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => vm.selectTab(t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: vm.tab == t
                                ? const Color(0xFFE8F2FF)
                                : const Color(0xFFF3F5F8),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: vm.tab == t
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: vm.tab == t
                                  ? kBrand
                                  : const Color(0xFF5C6270),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => AppRouter.toast('发布新动态（演示）'),
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
        const SizedBox(height: 10),
        // 横向资源推荐（随 tab 变化）
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: resources.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: _buildResourceItem,
          ),
        ),
        const SizedBox(height: 12),
        // 排序快捷条 + 筛选入口
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              for (final s in feed.sorts)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => vm.selectFilter('sort', s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: vm.sort == s
                            ? const Color(0xFFE8F2FF)
                            : const Color(0xFFF3F5F8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: vm.sort == s
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: vm.sort == s
                              ? kBrand
                              : const Color(0xFF5C6270),
                        ),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: vm.toggleFilter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: vm.filterOpen
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
                          color: vm.filterOpen
                              ? kBrand
                              : const Color(0xFF5C6270),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.tune,
                        size: 14,
                        color: vm.filterOpen
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
        // 列表请求中：贴一条细进度条（列表接口的加载反馈）
        if (vm.listLoading) const LinearProgressIndicator(minHeight: 2),
        // 列表 + 下拉筛选面板：面板顶 = 列表区 Stack 顶部（即筛选条下沿），
        // 位置由布局决定，不需要任何测量。
        Expanded(
          child: vm.posts == null
              ? vm.postsError != null
                    ? LoadErrorView(
                        message: vm.postsError!,
                        onRetry: vm.retry,
                      )
                    : const Center(child: CircularProgressIndicator())
              : _ListContent(
                  resetFilter: vm.resetFilter,
                  openFilter: vm.filterOpen,
                  toggleFilter: vm.toggleFilter,
                  feed: feed,
                  list: vm.posts!,
                  sort: vm.sort,
                  type: vm.type,
                  dist: vm.dist,
                  price: vm.price,
                  onSelectFilter: vm.selectFilter,
                ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ListContent extends StatefulWidget {
  final List<Post> list;
  final CommunityFeed feed;
  final bool openFilter;
  final String sort;
  final String type;
  final String dist;
  final String price;
  final VoidCallback resetFilter;
  final Function(String, String) onSelectFilter;
  final VoidCallback toggleFilter;
  const _ListContent({
    required this.list,
    required this.feed,
    this.openFilter = false,
    required this.sort,
    required this.type,
    required this.dist,
    required this.price,
    required this.onSelectFilter,
    required this.resetFilter,
    required this.toggleFilter,
  });

  @override
  State<_ListContent> createState() => _ListContentState();
}

class _ListContentState extends State<_ListContent> {
  @override
  void initState() {
    super.initState();
    print("--_ListContent init");
  }

  @override
  void didUpdateWidget(covariant _ListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("--_ListContent didUpdateWidget 0");
    if (widget.list.length != oldWidget.list.length) {
      print("-- _ListContent didUpdateWidget 1");
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.list;
    final filterOpen = widget.openFilter;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            if (posts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Text(
                    '没有符合条件的帖子，试试放宽筛选条件',
                    style: TextStyle(fontSize: 13, color: Color(0xFF98A0AC)),
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
        // 筛选面板（从筛选条下沿展开，覆盖列表区）
        if (filterOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.toggleFilter,
              child: Container(color: const Color(0x66000000)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _FilterPanel(
              feed: widget.feed,
              sort: widget.sort,
              type: widget.type,
              dist: widget.dist,
              price: widget.price,
              onPick: widget.onSelectFilter,
              onReset: widget.resetFilter,
              onApply: widget.toggleFilter,
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
              child: Image.asset(
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
              child: Image.asset(
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
class _FilterPanel extends StatefulWidget {
  const _FilterPanel({
    required this.feed,
    required this.sort,
    required this.type,
    required this.dist,
    required this.price,
    required this.onPick,
    required this.onReset,
    required this.onApply,
  });

  /// 筛选项配置（排序方式/内容类型/距离范围/价格区间）随接口一起下发。
  final CommunityFeed feed;
  final String sort;
  final String type;
  final String dist;
  final String price;
  final void Function(String key, String value) onPick;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  @override
  void initState() {
    super.initState();
    debugPrint('[_FilterPanel] initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('[_FilterPanel] didChangeDependencies');
  }

  @override
  void didUpdateWidget(covariant _FilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('[_FilterPanel] didUpdateWidget: old=$oldWidget');
  }

  @override
  void deactivate() {
    super.deactivate();
    debugPrint('[_FilterPanel] deactivate');
  }

  @override
  void activate() {
    super.activate();
    debugPrint('[_FilterPanel] activate');
  }

  @override
  void dispose() {
    debugPrint('[_FilterPanel] dispose');
    super.dispose();
  }

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
                onTap: () => widget.onPick(key, v),
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
            _group('排序方式', 'sort', widget.feed.sorts, widget.sort),
            const SizedBox(height: 16),
            _group('内容类型', 'type', widget.feed.postTypes, widget.type),
            const SizedBox(height: 16),
            _group('距离范围', 'dist', widget.feed.dists, widget.dist),
            const SizedBox(height: 16),
            _group('价格区间', 'price', widget.feed.priceRanges, widget.price),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onReset,
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
                    onTap: widget.onApply,
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
