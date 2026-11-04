import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hot_example/base/app_router.dart';
import 'package:provider/provider.dart';

import '../floors/banner_floor.dart';
import '../floors/floor_base.dart';
import '../floors/grid_floor.dart';
import '../floors/promo_floor.dart';
import '../floors/spot_floor.dart';
import '../vm/home_vm.dart';
import '../widgets/load_error_view.dart';

/// App 首页（对应 docs/app-prototype.html 的「首页」tab）。
///
/// 页面本身只负责“壳”：
/// - 由 [HomeVm] 先请求楼层配置（接口只下发 type）；
/// - 按 type 装配各楼层组件，楼层组件在自己的 provider 作用域内**自己请求**
///   自己的接口取数据；
/// - 下拉刷新交给 [HomeVm.refresh] 逐个楼层刷新（楼层可空实现）。
///
/// 首页不是 `@PatchEntry` 根类：热更载体是四 tab 外壳 `AppShell`
/// （lib/app/app.dart），首页沿 import 链被连带翻译，产物
/// `patch/app/pages/home_page.js`。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeVm>(
      create: (_) => HomeVm()..load(),
      child: const HomeView(),
    );
  }
}

/// 首页视图：订阅 [HomeVm]，楼层本体各自订阅自己的楼层 VM。
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// 下拉刷新控制器：JS 侧 `new EasyRefreshController()` 与宿主真实实例按
  /// 句柄绑定（同 ScrollController 模式），`callRefresh()` 可程序化触发刷新。
  final EasyRefreshController _refreshController = EasyRefreshController();

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  /// 下拉刷新 / 头部刷新按钮：统一调用页面 VM 刷新所有楼层。
  Future<void> _onRefresh() async {
    await context.read<HomeVm>().refresh();
  }

  /// 头部刷新按钮：走 controller 主动触发（与下拉手势同一条刷新链路）。
  void _refresh() {
    _refreshController.callRefresh();
  }

  /// 唤起城市选择器：宿主侧弹底部面板，选完回写城市并由各楼层重新取数。
  Future<void> _pickCity() async {
    final HomeVm vm = context.read<HomeVm>();
    final picked = await AppRouter.openCityPicker(vm.city);
    if (picked == null) return;
    await vm.changeCity(picked);
  }

  @override
  Widget build(BuildContext context) {
    final HomeVm vm = context.watch<HomeVm>();
    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = vm.error;
    if (error != null) {
      return LoadErrorView(message: error, onRetry: vm.load);
    }
    return Container(
      color: const Color(0xFFF4F5F7),
      // 顶部头（定位 / 刷新 / 消息 / 搜索）固定在滚动区之外：下拉刷新手势只作用
      // 在下方滚动内容上，因此刷新指示器从第一个楼层处开始下拉，头不会跟着移动。
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeader(
            city: vm.city,
            onRefresh: _refresh,
            onPickCity: _pickCity,
          ),
          Expanded(
            // 下拉刷新：用户下拉 → 宿主触发 JS 侧 `_onRefresh()` → 逐个楼层刷新
            // → await 完指示器才收起。
            child: EasyRefresh(
              controller: _refreshController,
              onRefresh: _onRefresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final floor in vm.floors) FloorSlot(floor: floor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 楼层装配点：按接口下发的 type 组装对应楼层组件。
class FloorSlot extends StatelessWidget {
  const FloorSlot({super.key, required this.floor});

  final HomeFloor floor;

  @override
  Widget build(BuildContext context) {
    final type = floor.type;
    if (type == 'banner') return BannerFloor(vm: floor.vm);
    if (type == 'grid') return GridFloor(vm: floor.vm);
    if (type == 'spots') return SpotFloor(vm: floor.vm);
    if (type == 'promo') return PromoFloor(vm: floor.vm);
    // 未知楼层类型不静默丢弃：输出明确日志并显示可见提示。
    print('FloorSlot 未知楼层类型：$type');
    return Text(
      '未知楼层类型：$type',
      style: const TextStyle(fontSize: 12, color: Color(0xFF8A909E)),
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

  /// 当前城市名（来自首页 VM，选择器选完由 VM 回写并通知刷新）。
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
