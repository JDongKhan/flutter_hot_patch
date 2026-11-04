import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/app_models.dart';
import '../service/app_service.dart';
import '../widgets/banner_carousel.dart';
import 'floor_status.dart';

/// banner 楼层 VM：**自己请求** `/app/home/banner` 取这一层的数据。
class BannerFloorVm extends ChangeNotifier {
  BannerFloorVm({required this.city});

  /// 当前城市：依赖城市的楼层在 [load] 里按它取数。
  String city;

  /// 该楼层是否正在加载；true 时楼层视图显示局部 loading。
  bool loading = true;

  /// 该楼层的失败原因；null = 没有失败。
  String? error;

  final AppService _service = AppService();

  List<HomeBanner> banners = [];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      banners = await _service.fetchHomeBanners(city);
      error = null;
    } catch (e) {
      print('BannerFloor 加载失败: $e');
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  /// 下拉刷新：空实现——演示「楼层刷新方法可以是空」，banner 不参与刷新。
  Future<void> refresh() async {}

  /// 城市变化：更新城市后重新加载本楼层。
  Future<void> setCity(String newCity) async {
    if (newCity == city) return;
    city = newCity;
    await load();
  }
}

/// banner 楼层：把该层的 VM 以 provider 提供给楼层视图。
class BannerFloor extends StatelessWidget {
  const BannerFloor({super.key, required this.vm});

  final BannerFloorVm vm;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BannerFloorVm>.value(
      value: vm,
      child: const BannerFloorView(),
    );
  }
}

/// banner 楼层视图：只订阅本层 VM。
class BannerFloorView extends StatelessWidget {
  const BannerFloorView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BannerFloorVm>();
    Widget body;
    if (vm.loading) {
      body = const FloorLoadingView(height: 150);
    } else if (vm.error != null) {
      body = FloorErrorView(message: vm.error!, onRetry: vm.load, height: 150);
    } else {
      body = BannerCarousel(banners: vm.banners);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: body,
    );
  }
}
