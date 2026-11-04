import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hot_example/base/app_router.dart';
import 'package:provider/provider.dart';

import '../model/app_models.dart';
import '../service/app_service.dart';
import 'floor_status.dart';

/// 景点推荐楼层 VM：**自己请求** `/app/home/spots` 取这一层的数据。
class SpotFloorVm extends ChangeNotifier {
  SpotFloorVm({required this.city});

  String city;
  bool loading = true;
  String? error;

  final AppService _service = AppService();

  List<Spot> spots = [];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      spots = await _service.fetchHomeSpots(city);
      error = null;
    } catch (e) {
      print('SpotFloor 加载失败: $e');
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await load();
  }

  Future<void> setCity(String newCity) async {
    if (newCity == city) return;
    city = newCity;
    await load();
  }
}

/// 景点推荐楼层：把该层的 VM 以 provider 提供给楼层视图。
class SpotFloor extends StatelessWidget {
  const SpotFloor({super.key, required this.vm});

  final SpotFloorVm vm;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SpotFloorVm>.value(
      value: vm,
      child: const SpotFloorView(),
    );
  }
}

/// 景点推荐楼层视图：栏目标题 + 两列自适应卡片。
class SpotFloorView extends StatelessWidget {
  const SpotFloorView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SpotFloorVm>();
    Widget body;
    if (vm.loading) {
      body = const FloorLoadingView();
    } else if (vm.error != null) {
      body = FloorErrorView(message: vm.error!, onRetry: vm.load);
    } else {
      body = GridView(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 190,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < vm.spots.length; i++)
            SpotCard(spot: vm.spots[i]),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
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
                style: TextStyle(fontSize: 12, color: Color(0xFF8A909E)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: body,
        ),
      ],
    );
  }
}

/// 景点卡片（景点推荐楼层单元格）。
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
                  Image.asset(spot.img, fit: BoxFit.cover),
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
