import 'package:flutter/foundation.dart';

import '../floors/banner_floor.dart';
import '../floors/floor_base.dart';
import '../floors/grid_floor.dart';
import '../floors/promo_floor.dart';
import '../floors/spot_floor.dart';
import '../model/app_models.dart';
import '../service/app_service.dart';

/// 首页 VM：只负责「楼层编排」。
///
/// 1. 先请求 `/app/home/floors` 拿到楼层配置（只有 type）；
/// 2. 按 type 创建对应楼层 VM，并让每个楼层 VM 自己请求自己的接口；
/// 3. 下拉刷新统一走 [refresh]，逐个调用楼层 VM 的 refresh（楼层可为空实现）；
/// 4. 城市变化时把新城市下发给各楼层，由各楼层重新取数。
class HomeVm extends ChangeNotifier {
  final AppService _service = AppService();

  String city = '上海';

  /// 楼层实例（type + 楼层 VM）。
  List<HomeFloor> floors = [];

  /// 楼层配置是否正在加载。
  bool loading = true;

  /// 楼层配置加载失败的原因；null = 没有失败。
  String? error;

  /// 拉取楼层配置并按 type 装配楼层。
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final List<HomeFloorConfig> configs = await _service.fetchHomeFloors();
      // 楼层实例只创建一次：楼层数据刷新 / 城市切换都复用同一个 VM，
      // 避免 provider 的 value 在重建后仍指向旧实例。
      if (floors.isEmpty) {
        final list = <HomeFloor>[];
        for (final c in configs) {
          final vm = _createFloor(c.type);
          if (vm == null) {
            print('HomeVm 未知楼层类型：${c.type}，已跳过');
            continue;
          }
          vm.load();
          list.add(HomeFloor(type: c.type, vm: vm));
        }
        floors = list;
      }
      error = null;
    } catch (e) {
      print('HomeVm 楼层配置加载失败: $e');
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  /// 下拉刷新：逐个楼层调用自己的 refresh（默认空实现，不刷新也不报错）。
  Future<void> refresh() async {
    for (final floor in floors) {
      await floor.vm.refresh();
    }
  }

  /// 切换城市：更新首页城市后，把新城市下发给各楼层重新取数。
  Future<void> changeCity(String newCity) async {
    if (newCity == city) return;
    city = newCity;
    notifyListeners();
    for (final floor in floors) {
      await floor.vm.setCity(newCity);
    }
  }

  /// 按楼层类型创建对应 VM（新增楼层类型只需在这里补一个分支）。
  dynamic _createFloor(String type) {
    switch (type) {
      case 'banner':
        return BannerFloorVm(city: city);
      case 'grid':
        return GridFloorVm(city: city);
      case 'spots':
        return SpotFloorVm(city: city);
      case 'promo':
        return PromoFloorVm(city: city);
    }
    return null;
  }

  @override
  void dispose() {
    // 楼层 VM 由 HomeVm 创建，随 HomeVm 一起释放（provider 只负责 HomeVm）。
    for (final floor in floors) {
      floor.vm.dispose();
    }
    floors = [];
    super.dispose();
  }
}
