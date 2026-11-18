import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';
import 'package:provider/provider.dart';

import '../../base/app_router.dart';
import '../model/app_models.dart';
import '../vm/user_center_vm.dart';
import '../widgets/load_error_view.dart';

/// 用户中心页（`@PatchEntry`）：从「我的」页点击个人信息进入。
///
/// 一个接口（`/app/user`）撑起整页：头部个人信息 + 四项资产 + 常用功能 +
/// 账号与安全 + 退出登录。可交互项一律走宿主路由（[AppRouter]），
/// 因此原生与 JS 两种渲染下行为一致。
@PatchEntry()
class UserCenterPage extends StatelessWidget {
  const UserCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserCenterVm>(
      create: (_) => UserCenterVm()..load(),
      child: const _UserCenterView(),
    );
  }
}

/// 页架：头部常显（未加载完也保留返回入口），下半区按加载状态切换。
class _UserCenterView extends StatelessWidget {
  const _UserCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserCenterVm>();
    final UserProfile? profile = vm.feed;
    final String? error = vm.error;
    Widget body;
    if (profile != null) {
      body = _ProfileBody(profile: profile);
    } else if (error != null) {
      body = LoadErrorView(message: error, onRetry: vm.load);
    } else {
      body = const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: Column(
        children: [
          _ProfileHeader(profile: profile),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// 渐变头部：返回 + 标题 + 编辑资料，头像 / 昵称 / 会员等级 / 手机号。
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({super.key, this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    // 加载中也要有完整布局：所有取值先落到普通局部变量，避免构造实参里写表达式。
    final String avatar =
        p == null ? 'assets/images/photo-1494790108377-be9c29b29330.jpg' : p.avatar;
    final String nickname = p == null ? '未登录' : p.nickname;
    final String phone = p == null ? '登录后同步你的旅行足迹' : p.phone;
    final String level = p == null ? '游客' : p.level;
    final String levelSub = p == null ? '' : p.levelSub;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E88FF), Color(0xFF0E7AFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => AppRouter.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '个人中心',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => AppRouter.toast('编辑资料（演示）'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '编辑资料',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Image.asset(
                      avatar,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                        width: 62,
                        height: 62,
                        color: const Color(0x33FFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x33FFFFFF),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                level,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          levelSub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xB3FFFFFF),
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
      ),
    );
  }
}

/// 下半区：资产卡 / 常用功能 / 账号与安全 / 退出登录 / 页脚。
class _ProfileBody extends StatelessWidget {
  const _ProfileBody({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 26),
      children: [
        _assetsCard(),
        _sectionTitle('常用功能'),
        _servicesCard(),
        _sectionTitle('账号与安全'),
        _securityCard(),
        const SizedBox(height: 18),
        _logout(),
        _footer(),
      ],
    );
  }

  /// 四项资产：数字大、标签小，点一下给个演示提示。
  Widget _assetsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _assetCell('${profile.points}', '积分'),
          _assetCell('${profile.coupons}', '优惠券'),
          _assetCell('${profile.favorites}', '收藏'),
          _assetCell('${profile.footprints}', '足迹'),
        ],
      ),
    );
  }

  Widget _assetCell(String value, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => AppRouter.toast('$label（演示）'),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D24),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF8B909A)),
            ),
          ],
        ),
      ),
    );
  }

  /// 常用功能：两行四列，每项一个 emoji 圆底 + 标题。
  Widget _servicesCard() {
    final services = profile.services;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _serviceRow(services, 0),
          const SizedBox(height: 14),
          _serviceRow(services, 4),
        ],
      ),
    );
  }

  /// 从 [start] 起取 4 个入口拼成一行（不足 4 个就少画几个）。
  Widget _serviceRow(List<List<String>> services, int start) {
    final cells = <Widget>[];
    final int end = start + 4;
    for (var i = start; i < end; i++) {
      if (i >= services.length) {
        cells.add(const Expanded(child: SizedBox()));
      } else {
        final String emoji = services[i][0];
        final String title = services[i][1];
        cells.add(_serviceCell(emoji, title));
      }
    }
    return Row(children: cells);
  }

  Widget _serviceCell(String emoji, String title) {
    return Expanded(
      child: GestureDetector(
        onTap: () => AppRouter.toast('$title（演示）'),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F5FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 19)),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF3A3F4A)),
            ),
          ],
        ),
      ),
    );
  }

  /// 账号与安全：每行「标题 + 说明 + 箭头」，第一行是手机号。
  Widget _securityCard() {
    final security = profile.security;
    final rows = <Widget>[];
    for (var i = 0; i < security.length; i++) {
      if (i > 0) {
        rows.add(
          const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFEEF0F4)),
        );
      }
      rows.add(_securityRow(security[i]));
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _cardDecoration(),
      child: Column(children: rows),
    );
  }

  Widget _securityRow(List<String> row) {
    final String title = row[0];
    final String sub = row[1];
    return GestureDetector(
      onTap: () => _openSecurity(title),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1D24),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8B909A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: Color(0xFFC3C8D2),
            ),
          ],
        ),
      ),
    );
  }

  /// 「切换账号」保留登录页入口（改版后「我的」页头部不再直连登录页）。
  void _openSecurity(String title) {
    if (title == '切换账号') {
      AppRouter.openLogin();
    } else {
      AppRouter.toast('$title（演示）');
    }
  }

  Widget _logout() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _cardDecoration(),
      child: GestureDetector(
        onTap: () => AppRouter.toast('已退出登录（演示）'),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              '退出登录',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE5484D),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return const Padding(
      padding: EdgeInsets.only(top: 16),
      child: Center(
        child: Text(
          '账号 ID 100086 · 已注册 1024 天',
          style: TextStyle(fontSize: 10.5, color: Color(0xFFA8ADB8)),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    );
  }
}
