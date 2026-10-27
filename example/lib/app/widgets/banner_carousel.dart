import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hot_example/base/app_router.dart';

import '../model/app_models.dart';

/// 首页轮播组件：**只接收一个 banner 数组**，内部自己完成
/// 「PageView 翻页 + 5s 自动切换 + 指示点跟随」。
///
/// 之所以做成自包含组件（而不是让页面持有 PageController + Timer）：
///  - 页面只关心数据（`List<HomeBanner>`），翻页节奏、指示器状态都是组件内部实现细节；
///  - 城市切换后页面换一批 banner，组件在 `didUpdateWidget` 里自己重置且重新计时，
///    页面不需要知道轮播的内部状态。
///
/// 无 banner 时不渲染（高度塌陷为 0），避免出现空白占位。
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners});

  /// 轮播页数据（任意长度：1 页时只显示不加计时器，0 页时不渲染）。
  final List<HomeBanner> banners;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  /// 轮播高度固定，避免图片加载完成后高度跳动。
  static const double _height = 150;

  /// 自动切换间隔。
  static const Duration _interval = Duration(seconds: 5);

  /// 翻页动画时长。
  static const Duration _animate = Duration(milliseconds: 350);

  final PageController _controller = PageController();

  /// 周期定时器（由 `capabilities` 里的 Dart Timer 同名注入承接）。
  Timer? _timer;

  /// 当前页下标（指示器高亮项）。
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 城市切换 → 页面换了一整组 banner（列表按引用比较变化）：重置到有效页并
    // 重新计时。引用相同说明只是父级重建，保持当前页与节奏不动。
    if (oldWidget.banners != widget.banners) {
      _reset();
    }
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _controller.dispose();
    super.dispose();
  }

  /// banner 换组：下标收敛到新列表范围内，必要时跳到该页，然后重开自动播放。
  void _reset() {
    final count = widget.banners.length;
    if (count == 0) {
      _stopAutoPlay();
      _index = 0;
      return;
    }
    if (_index >= count) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
    _startAutoPlay();
  }

  /// 停止自动播放。
  ///
  /// 先取本地引用再判空调用（写成 `_timer?.cancel()` 在热更产物里不会保留空安全
  /// 语义，会直接对 null 发起调用）。
  void _stopAutoPlay() {
    final timer = _timer;
    if (timer != null) {
      timer.cancel();
    }
    _timer = null;
  }

  /// 启动自动播放：先停旧的（换城市 / 重建都会走到这里），页数不足 2 时不启动。
  void _startAutoPlay() {
    _stopAutoPlay();
    if (widget.banners.length < 2) return;
    // 显式闭包而不是 `_tick` 方法名：回调由本组件实例执行，this 必须绑回组件。
    _timer = Timer.periodic(_interval, (timer) => _tick(timer));
  }

  /// 每 5s 翻到下一页（到末尾回到第 1 页），并同步指示器。
  void _tick(Timer timer) {
    if (_timer == null) return;
    final count = widget.banners.length;
    if (count < 2) return;
    final next = (_index + 1) % count;
    _controller.animateToPage(
      next,
      duration: _animate,
      curve: Curves.easeOut,
    );
    setState(() => _index = next);
  }

  /// 手势滑动翻页：指示器跟着手动下标走。
  void _onPageChanged(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.length == 0) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _height,
          child: PageView(
            controller: _controller,
            onPageChanged: _onPageChanged,
            children: [
              for (var i = 0; i < banners.length; i++)
                BannerSlide(banner: banners[i]),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 指示点：高亮当前页
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < banners.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index
                      ? const Color(0xFF0E7AFB)
                      : const Color(0xFFD5D9E0),
                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                ),
              ),
          ],
        ),
      ],
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
