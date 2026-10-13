import 'package:flutter/material.dart';

import '../../base/app_router.dart';
import '../model/app_data.dart';
import '../model/app_models.dart';

/// App 二级页集合（常规 Flutter 页面，无 @UIComponent 注解）。
///
/// 首页 `@UIComponent` 组件的跳转入口统一经宿主路由
/// （lib/base/app_router.dart）推入这些页面；其余 tab 直接 Navigator.push。

const Color kBrand = Color(0xFF0E7AFB);
const Color kPrice = Color(0xFFFF5A36);

/// 统一轻提示。
void appToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(40, 0, 40, 110),
      ),
    );
}

/// 二级页统一顶栏（返回 + 标题）。
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEF1F5))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => AppRouter.pop(),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F5F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 15,
                color: Color(0xFF171A21),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 白色圆角内容块。
class _Block extends StatelessWidget {
  const _Block({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// 键值行。
class _Kv extends StatelessWidget {
  const _Kv({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4D5462)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 17 : 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? kPrice : const Color(0xFF171A21),
            ),
          ),
        ],
      ),
    );
  }
}

/// 块内小标题。
class _BlockTitle extends StatelessWidget {
  const _BlockTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// 底部操作条。
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF1F5))),
      ),
      child: Row(children: children),
    );
  }
}

/// 描边小按钮。
class MiniButton extends StatelessWidget {
  const MiniButton({
    super.key,
    required this.label,
    this.primary = false,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? kBrand : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary ? kBrand : const Color(0xFFDFE4EC)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: primary ? FontWeight.w600 : FontWeight.w500,
            color: primary ? Colors.white : const Color(0xFF4D5462),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 搜索页
// ---------------------------------------------------------------------------

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(String kw) {
    AppRouter.toast('搜索：${kw.isEmpty ? '全部' : kw}');
  }

  @override
  Widget build(BuildContext context) {
    final guesses = kSpots.reversed.toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: _TopBar(
              title: '',
              trailing: GestureDetector(
                onTap: () => _go(_controller.text),
                child: const Text(
                  '搜索',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: kBrand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          // 搜索输入框
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onSubmitted: _go,
              decoration: InputDecoration(
                hintText: '搜索景点 / 目的地 / 攻略',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFFA3A9B4),
                ),
                filled: true,
                fillColor: const Color(0xFFF3F5F8),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(19),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _Block(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BlockTitle('热门搜索'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final k in kHotSearch)
                            GestureDetector(
                              onTap: () => _go(k),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F5F8),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  k,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF4D5462),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Text(
                    '猜你想去',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                for (final s in guesses)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: GestureDetector(
                      onTap: () => AppRouter.openSpot(s.id),
                      child: PostRow(
                        img: s.img,
                        title: s.title,
                        sub: s.sub,
                        trailing: '￥${s.price} 起',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 通用「图 + 文」横排卡片
// ---------------------------------------------------------------------------

class PostRow extends StatelessWidget {
  const PostRow({
    super.key,
    required this.img,
    required this.title,
    required this.sub,
    this.trailing,
    this.footNote,
  });

  final String img;
  final String title;
  final String sub;
  final String? trailing;
  final String? footNote;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              img,
              width: 86,
              height: 86,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                width: 86,
                height: 86,
                color: const Color(0xFFE8EBF0),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF8B909A),
                    height: 1.5,
                  ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      trailing!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kPrice,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (footNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      footNote!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA3A9B4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 景点详情
// ---------------------------------------------------------------------------

class SpotDetailPage extends StatelessWidget {
  const SpotDetailPage({super.key, required this.spot});

  final Spot spot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 大图 + 标题
                SizedBox(
                  height: 230,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        spot.img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) =>
                            Container(color: const Color(0xFFB9C3D2)),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x99000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 44,
                        child: GestureDetector(
                          onTap: () => AppRouter.pop(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xE6FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 15,
                              color: Color(0xFF171A21),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spot.title,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              spot.sub,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xE6FFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Block(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BlockTitle('行程亮点'),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final t in spot.tags)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF3FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: kBrand,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        spot.desc,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.85,
                          color: Color(0xFF4D5462),
                        ),
                      ),
                    ],
                  ),
                ),
                _Block(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BlockTitle('费用说明'),
                      _Kv(
                        label: '成人价',
                        value: '￥${spot.price} / 人',
                        highlight: true,
                      ),
                      _Kv(label: '已售', value: spot.sold),
                      const _Kv(label: '退改政策', value: '出行前 24 小时免费退'),
                    ],
                  ),
                ),
                _Block(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _BlockTitle('用户评价（4.8 分）'),
                      Text(
                        '“海岛的水真的很蓝，浮潜看到了很多鱼，酒店离沙滩走路两分钟，值。” —— 旅行家小七',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.85,
                          color: Color(0xFF4D5462),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _BottomBar(
            children: [
              Text(
                '￥${spot.price}',
                style: const TextStyle(
                  fontSize: 22,
                  color: kPrice,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '起',
                style: TextStyle(fontSize: 13, color: Color(0xFF5C6270)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => AppRouter.toast('已提交预订（演示）'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrand,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text('立即预订'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 帖子详情
// ---------------------------------------------------------------------------

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 180,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        post.img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) =>
                            Container(color: const Color(0xFFB9C3D2)),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x99000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 44,
                        child: GestureDetector(
                          onTap: () => AppRouter.pop(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xE6FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 15,
                              color: Color(0xFF171A21),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundImage: NetworkImage(kAvatarImg),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.author,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${post.time} · ${post.type}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8B909A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => AppRouter.toast('已关注 ${post.author}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kBrand,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            '关注',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Block(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.sub,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.9,
                          color: Color(0xFF4D5462),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '这次出行一共 3 天，人均花费不到 800。第一天上午出发，中午到营地搭好帐篷，下午沿着湖边走了差不多 6 公里，傍晚的日落是全程最值得的部分。',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.9,
                          color: Color(0xFF4D5462),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '装备方面，帐篷和防潮垫是必须的，夜里温度会降到 10 度以下，建议带一件抓绒。营地有热水和厕所，但没有便利店，食物要提前备好。',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.9,
                          color: Color(0xFF4D5462),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _BottomBar(
            children: [
              Expanded(
                child: MiniButton(
                  label:
                      '♡ 点赞 · ${post.like > 999 ? '${(post.like / 1000).toStringAsFixed(1)}k' : post.like}',
                  onTap: () => AppRouter.toast('已点赞'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MiniButton(
                  label: '收藏',
                  primary: true,
                  onTap: () => AppRouter.toast('已收藏'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 资源专题页
// ---------------------------------------------------------------------------

class ResourceDetailPage extends StatelessWidget {
  const ResourceDetailPage({super.key, required this.resource});

  final Resource resource;

  @override
  Widget build(BuildContext context) {
    final items = kPosts.take(3).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: _TopBar(title: resource.title),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SizedBox(
                  height: 150,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        resource.img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) =>
                            Container(color: const Color(0xFFB9C3D2)),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x99000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resource.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              resource.sub,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xE6FFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Text(
                    '相关推荐',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                for (final p in items)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: GestureDetector(
                      onTap: () => AppRouter.openPost(p.id),
                      child: PostRow(
                        img: p.img,
                        title: p.title,
                        sub: p.sub,
                        footNote: '${p.author} · ${p.time}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 订单详情
// ---------------------------------------------------------------------------

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.order});

  final Order order;

  static const List<String> _steps = ['提交订单', '支付成功', '商家发货', '已完成'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: const _TopBar(title: '订单详情'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                _Block(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BlockTitle(order.status),
                      for (var i = 0; i < _steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i <= order.step
                                      ? kBrand
                                      : const Color(0xFFDFE4EC),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _steps[i],
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: i <= order.step
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: i <= order.step
                                      ? const Color(0xFF171A21)
                                      : const Color(0xFF8B909A),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _Block(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BlockTitle('出行信息'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              order.img,
                              width: 62,
                              height: 62,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, s) => Container(
                                width: 62,
                                height: 62,
                                color: const Color(0xFFE8EBF0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.title,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  order.spec,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8B909A),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  '×1',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFA3A9B4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _Block(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BlockTitle('订单信息'),
                      _Kv(label: '订单号', value: order.no),
                      const _Kv(label: '下单时间', value: '2026-10-13 09:41'),
                      const _Kv(label: '出行人', value: '旅行家小七'),
                    ],
                  ),
                ),
                _Block(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BlockTitle('价格明细'),
                      _Kv(label: '成人票 × 1', value: '￥${order.price}'),
                      const _Kv(label: '优惠', value: '-￥0'),
                      _Kv(
                        label: '实付',
                        value: '￥${order.price}',
                        highlight: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _BottomBar(
            children: [
              Expanded(
                child: MiniButton(
                  label: '联系客服',
                  onTap: () => AppRouter.toast('已联系客服（演示）'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => AppRouter.toast(
                    order.status == '待付款' ? '支付成功（演示）' : '已申请开票（演示）',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: order.status == '待付款' ? kPrice : kBrand,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(order.status == '待付款' ? '立即支付' : '申请开票'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 登录页
// ---------------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _login() {
    if (_phone.text.length < 11) {
      AppRouter.toast('请输入 11 位手机号');
      return;
    }
    AppRouter.toast('登录成功，欢迎回来');
    AppRouter.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: const _TopBar(title: '登录'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(26, 32, 26, 32),
              children: [
                Center(
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kBrand, Color(0xFF7FB6FF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🧭', style: TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '欢迎回来',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                const Text(
                  '登录后可同步订单与收藏',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF8B909A)),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '+86',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '请输入手机号',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 50,
                  child: TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '请输入验证码',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () => AppRouter.toast('验证码已发送'),
                        child: const Center(
                          widthFactor: 1,
                          child: Text(
                            '获取验证码',
                            style: TextStyle(
                              fontSize: 13,
                              color: kBrand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrand,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    '登录',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '登录即代表同意《用户协议》与《隐私政策》',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8B909A),
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WebView 占位页（宿主侧实现，不引 webview_flutter）
// ---------------------------------------------------------------------------

/// 宿主 WebView 页面：展示传入 URL 与模拟的 H5 内容。
/// 由 `WebView.open(url, title)`（lib/base/web_view.dart，@HostInjected）
/// 从 JS 侧或原生侧推入。
class WebViewPage extends StatelessWidget {
  const WebViewPage({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: _TopBar(
              title: title,
              trailing: GestureDetector(
                onTap: () => AppRouter.toast('已刷新'),
                child: const Icon(
                  Icons.refresh,
                  size: 18,
                  color: Color(0xFF5C6270),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    url,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF98A0AC),
                    ),
                  ),
                ),
                _Block(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          kBanners[0].img,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => Container(
                            height: 130,
                            color: const Color(0xFFE8EBF0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '这是通过宿主 WebView 打开的 H5 页面（演示占位）。真实实现中这里会加载真实网页内容，并复用统一的导航栏与加载进度。',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.9,
                          color: Color(0xFF4D5462),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'JS 侧调用 WebView.open(url, title)，宿主侧用 Navigator 推入本页面（与 Network 同一套 @HostInjected 通道）。',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.9,
                          color: Color(0xFF4D5462),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
