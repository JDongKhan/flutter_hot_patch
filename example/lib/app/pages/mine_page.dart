import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import '../../base/app_router.dart';
import '../../base/web_view.dart';
import '../model/app_models.dart';
import '../service/app_service.dart';
import 'detail_pages.dart';

/// 我的 tab（`@PatchEntry` → 连带翻译，产物 patch/app/pages/mine_page.js）。
///
/// 对应 docs/app-prototype.html 的「我的」：渐变个人信息头（点击进登录页）
/// + 订单统计四项 + 功能菜单 + 退出登录。末尾额外挂两项**开发者入口**：
/// 「组件案例」（widget_details 的常用组件 demo 列表）与「热更 Demo 列表」。
///
/// 本页用了翻译器覆盖不到的构造（`Navigator.push(MaterialPageRoute(...))`、
/// 方法体 tear-off 回调），相关跳转统一收敛到 [AppRouter] 的 `@HostInjected`
/// 通道（与 JS 侧同一条通路）。
///
/// 头像 / 订单统计 / 功能菜单由 [AppService.fetchMine] 请求本地 mock 接口取回，
/// 加载期间显示 loading。
@PatchEntry()
class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  static const List<Color> _menuTints = [
    Color(0xFFE8F2FF),
    Color(0xFFFFF3E0),
    Color(0xFFEEF0F4),
    Color(0xFFE9F7EF),
  ];

  final AppService _service = AppService();

  /// 接口数据；null = 加载中。
  MineFeed? _feed;

  @override
  void initState() {
    super.initState();
    print("MinePage initState ---");
    _load();
  }

  Future<void> _load() async {
    final MineFeed feed = await _service.fetchMine();
    setState(() {
      _feed = feed;
    });
  }

  void _openMenu(MenuEntry m) {
    if (m.screen == 'orders') {
      AppRouter.openOrders();
    } else if (m.screen == 'showcase') {
      AppRouter.openWidgetShowcase();
    } else {
      // webview：走与 JS 侧同一条宿主通道（lib/base/web_view.dart）。
      WebView.open('https://flutter.dev', m.arg.isEmpty ? m.title : m.arg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feed;
    if (feed == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 个人信息头
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88FF), Color(0xFF0E7AFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: GestureDetector(
              onTap: () => AppRouter.openLogin(),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      feed.avatar,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                        width: 58,
                        height: 58,
                        color: const Color(0x33FFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '旅行家小七',
                          style: TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '138****8888',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '点击头像可跳转登录页 ›',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xB3FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xCCFFFFFF),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        // 订单统计
        Transform.translate(
          offset: const Offset(0, -12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                for (final s in feed.stats)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => AppRouter.openOrders(),
                      child: Column(
                        children: [
                          Text(
                            s[1],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF171A21),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            s[0],
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF8B909A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 功能菜单
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (var i = 0; i < feed.menu.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: 56,
                    color: Color(0xFFF0F2F6),
                  ),
                GestureDetector(
                  onTap: () => _openMenu(feed.menu[i]),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _menuTints[i % _menuTints.length],
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            feed.menu[i].emoji,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feed.menu[i].title,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Color(0xFFC3C8D2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // 退出登录
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: GestureDetector(
            onTap: () => AppRouter.toast('已退出登录（演示）'),
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '退出登录',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kPrice,
                ),
              ),
            ),
          ),
        ),
        // 开发者入口
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, 8),
          child: Text(
            '开发者',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF98A0AC),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _DevRow(
                icon: Icons.widgets_outlined,
                title: '组件案例',
                subtitle: '常用组件 原生 ↔ JS 同屏对比',
                onTap: () => AppRouter.openWidgetShowcase(),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF0F2F6)),
              _DevRow(
                icon: Icons.compare_arrows,
                title: '热更 Demo 列表',
                subtitle: 'HelloCard / ProviderCard / WatchDemo 等对比',
                onTap: () => AppRouter.openDemoList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 开发者入口行。
class _DevRow extends StatelessWidget {
  const _DevRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2FF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: kBrand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF98A0AC),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFC3C8D2)),
          ],
        ),
      ),
    );
  }
}
