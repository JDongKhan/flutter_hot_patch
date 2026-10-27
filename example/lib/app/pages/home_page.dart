import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hot_example/base/app_router.dart';
import 'package:flutter_hot_example/base/web_view.dart';

import '../model/app_models.dart';
import '../service/app_service.dart';

/// App 首页（对应 docs/app-prototype.html 的「首页」tab）。
///
/// 数据不再由构造参数注入，而是由 [AppService.fetchHome] 请求本地 mock 接口
/// 取回：请求期间显示 loading，回来后 setState 出内容。原生与 JS 两条通路写法
/// 完全一致（service 内部走的就是 `@HostInjected` 的宿主通道）。
///
/// 首页不是 `@PatchEntry` 根类：热更载体是四 tab 外壳 `AppShell`
/// （lib/app/app.dart），首页沿 import 链被连带翻译，产物
/// `patch/app/pages/home_page.js`。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppService _service = AppService();

  /// 下拉刷新控制器：JS 侧 `new EasyRefreshController()` 与宿主真实实例按
  /// 句柄绑定（同 ScrollController 模式），`callRefresh()` 可程序化触发刷新。
  final EasyRefreshController _refreshController = EasyRefreshController();

  /// 接口数据；null = 加载中。
  HomeFeed? _feed;

  /// 当前城市（顶部左上角展示）。点击唤起宿主城市选择器，选完回写并重新取数。
  String _city = '上海';

  @override
  void initState() {
    super.initState();
    print("HomePage initState ---");
    _load();
  }

  /// 唤起城市选择器：宿主侧弹底部面板，返回选中的城市名（取消则 null）。
  Future<void> _pickCity() async {
    final picked = await AppRouter.openCityPicker(_city);
    if (picked == null) return;
    setState(() => _city = picked);
    await _load();
  }
  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("--HomePage didUpdateWidget 0");
  }

  /// 头部刷新按钮：走 controller 主动触发（与下拉手势同一条 onRefresh 链路）。
  void _refresh() {
    _refreshController.callRefresh();
  }

  Future<void> _load() async {
    final HomeFeed feed = await _service.fetchHome();
    setState(() {
      _feed = feed;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("--HomePage build");
    final feed = _feed;
    if (feed == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // 字段派生的 final 局部：翻译器会把它们折算成字段别名（`feed.banners`
    // → `this._feed.banners`），因此 SliverGrid 的懒加载 builder 被抽成实例
    // 方法后照样引用得到（见 js_translator 的链式别名 + widget2js 的
    // warnCapturedLocals 告警口径）。
    final banners = feed.banners;
    final grid = feed.grid;
    final spots = feed.spots;
    final adImg = feed.adImg;
    return Container(
      color: const Color(0xFFF4F5F7),
      // 顶部头（定位 / 刷新 / 消息 / 搜索）固定在滚动区之外：下拉刷新手势只作用
      // 在下方滚动内容上，因此刷新指示器从 Banner 处开始下拉，头不会跟着移动。
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeader(city: _city, onRefresh: _refresh, onPickCity: _pickCity),
          Expanded(
            // 下拉刷新：宿主侧容器由 hot_patch 的 capabilities/easy_refresh 提供
            // （桥接 Flutter 侧 EasyRefresh）。用户下拉 → 宿主触发 JS 侧 `_load()`
            // → JS 侧 await 完重新请求后指示器才收起；指示器样式用包内默认
            // ClassicHeader，不参与翻译。
            // controller 与 JS 侧 `new EasyRefreshController()` 按句柄绑定：
            // 头部刷新按钮 → callRefresh → 宿主真实 controller 带动画拉起指示器。
            child: EasyRefresh(
              controller: _refreshController,
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        // 轮播：PageView + BannerSlide（子组件，走 JS 类引用）
                        SizedBox(
                          height: 150,
                          child: PageView(
                            children: [
                              for (var i = 0; i < banners.length; i++)
                                BannerSlide(banner: banners[i]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 轮播指示点（静态高亮第 1 个；StatelessWidget 不追踪滑动位置）
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < banners.length; i++)
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? const Color(0xFF0E7AFB)
                                      : const Color(0xFFD5D9E0),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(3),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 九宫格入口
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          // 九宫格的高度必须**恒定**：格子高度交给 mainAxisExtent 固定，
                          // 列数交给 Flutter 按可用宽度动态算（maxCrossAxisExtent）。
                          // 原先用 GridView.count(crossAxisCount: 4) —— 格子高 = 格子宽，
                          // 窗口一宽行高就被拉高，整个白卡变成一大块空白。
                          child: GridView(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 150,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  mainAxisExtent: 84,
                                ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              for (var i = 0; i < grid.length; i++)
                                GridCell(entry: grid[i]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 图片广告位
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          child: PromoCard(img: adImg),
                        ),
                        const SizedBox(height: 16),
                        // 栏目标题
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0E7AFB),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '景点推荐',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2430),
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                '为你精选',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A909E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  // 景点两列瀑布格：SliverGrid + SliverChildBuilderDelegate 懒加载
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    sliver: SliverGrid(
                      // 卡片高度固定（不再用 childAspectRatio 让高度跟着宽度走）：
                      // 窄屏 2 列（与原型一致），宽屏按 maxCrossAxisExtent 自动铺成 3~4 列。
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 190,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => SpotCard(spot: spots[index]),
                        childCount: spots.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 顶部渐变头（定位 + 消息 + 搜索条）
// ---------------------------------------------------------------------------
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onRefresh,
    required this.city,
    required this.onPickCity,
  });

  /// 程序化刷新：宿主真实 EasyRefreshController.callRefresh（JS 侧同款方法）。
  final VoidCallback onRefresh;

  /// 当前城市名（来自首页 state，选择器选完由首页回写）。
  final String city;

  /// 点击城市 → 首页唤起宿主城市选择器。
  final VoidCallback onPickCity;

  void openSearch() {
    AppRouter.openSearch();
  }

  void openMessages() {
    AppRouter.openNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E88FF), Color(0xFF0E7AFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: onPickCity,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFFFFFFF),
                        size: 18,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        city,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFFFFFFFF),
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 程序化刷新（EasyRefreshController.callRefresh）：与下拉手势
                // 触发同一条 onRefresh 链路，验证 controller 跨桥可用。
                InkWell(
                  onTap: onRefresh,
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.refresh,
                      color: Color(0xFFFFFFFF),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: openMessages,
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  child: const Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.notifications,
                          color: Color(0xFFFFFFFF),
                          size: 24,
                        ),
                      ),
                      Positioned(
                        right: 3,
                        top: 3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFFF5A36),
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          child: SizedBox(width: 8, height: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: openSearch,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.all(Radius.circular(21)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF9AA0AC), size: 20),
                    SizedBox(width: 6),
                    Text(
                      '搜索目的地 / 关键词',
                      style: TextStyle(fontSize: 14, color: Color(0xFF9AA0AC)),
                    ),
                    Spacer(),
                    Text(
                      '搜索',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0E7AFB),
                        fontWeight: FontWeight.w600,
                      ),
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

// ---------------------------------------------------------------------------
// 轮播单页
// ---------------------------------------------------------------------------
class BannerSlide extends StatelessWidget {
  const BannerSlide({super.key, required this.banner});

  final HomeBanner banner;

  void open() {
    AppRouter.toast(banner.title);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: open,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(banner.img, fit: BoxFit.cover),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x00000000), Color(0xB3000000)],
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      banner.sub,
                      style: const TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 九宫格单元
// ---------------------------------------------------------------------------
class GridCell extends StatelessWidget {
  const GridCell({super.key, required this.entry});

  final GridEntry entry;

  void open() {
    AppRouter.openChannel(entry.title, entry.emoji);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: open,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(entry.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            entry.title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4D5462)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 景点卡片（SliverGrid 单元格）
// ---------------------------------------------------------------------------
class SpotCard extends StatelessWidget {
  const SpotCard({super.key, required this.spot});

  final Spot spot;

  void open() {
    AppRouter.openSpot(spot.id);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: open,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(spot.img, fit: BoxFit.cover),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5A36),
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Text(
                        spot.tag,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2430),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spot.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A909E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '¥',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF5A36),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${spot.price}',
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFFFF5A36),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        spot.sold,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9AA0AC),
                        ),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// 广告位（点击走 WebView 宿主通道）
// ---------------------------------------------------------------------------
class PromoCard extends StatelessWidget {
  const PromoCard({super.key, required this.img});

  final String img;

  void open() {
    WebView.open('https://flutter.dev', '活动详情');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: open,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: SizedBox(
        height: 96,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(img, fit: BoxFit.cover),
              Positioned(
                left: 16,
                top: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '热气球季 · 限时特惠',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xE6FFFFFF),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: const Text(
                        '立即查看 >',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0E7AFB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
