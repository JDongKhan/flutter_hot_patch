import 'package:flutter/material.dart';
import 'package:flutter_hot/base/app_router.dart';
import 'package:flutter_hot/base/web_view.dart';

import '../model/app_data.dart';
import '../model/app_models.dart';

/// App 首页（对应 docs/app-prototype.html 的「首页」tab）——**普通原生页面**。
///
/// 数据来自 `lib/app/model/app_data.dart` 的顶层 const，构造参数带同值默认值：
/// 既能 `const HomePage()` 直接构造（外壳 `AppShell` 里就是这么用的，宿主做
/// 原生注入时也不用传参），也能显式换一份数据（`HomePage(spots: mySpots)`）。
///
/// 首页本身**不是** `@UIComponent` 组件：热更的载体上移到了四 tab 外壳
/// `AppShell`（lib/app/app.dart）。外壳被翻译成 JS 后，首页由宿主经
/// `nativeComponents` 原生注入，因此本文件不产生任何 JS 产物。
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.banners = kBanners,
    this.grid = kGrid,
    this.spots = kSpots,
    this.adImg = kAdImg,
  });

  final List<HomeBanner> banners;
  final List<GridEntry> grid;
  final List<Spot> spots;
  final String adImg;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F5F7),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HomeHeader(),
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
                        margin: const EdgeInsets.symmetric(horizontal: 3),
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
                  child: GridView.count(
                    crossAxisCount: 4,
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
                          borderRadius: BorderRadius.all(Radius.circular(2)),
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.72,
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
    );
  }
}

// ---------------------------------------------------------------------------
// 顶部渐变头（定位 + 消息 + 搜索条）
// ---------------------------------------------------------------------------
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  void openSearch() {
    AppRouter.openSearch();
  }

  void openMessages() {
    AppRouter.toast('暂无新消息');
  }

  void openLocation() {
    AppRouter.toast('定位：上海市 · 点击切换城市');
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
                  onTap: openLocation,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Color(0xFFFFFFFF),
                        size: 18,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '上海',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFFFFFFFF),
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
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
    AppRouter.toast('${entry.title} 频道');
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
