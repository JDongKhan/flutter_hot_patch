import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hot_example/base/web_view.dart';
import 'package:provider/provider.dart';

import '../service/app_service.dart';
import 'floor_status.dart';

/// 广告位楼层 VM：**自己请求** `/app/home/promo` 取这一层的图片。
class PromoFloorVm extends ChangeNotifier {
  PromoFloorVm({required this.city});

  String city;
  bool loading = true;
  String? error;

  final AppService _service = AppService();

  String img = '';

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      img = await _service.fetchHomePromo(city);
      error = null;
    } catch (e) {
      print('PromoFloor 加载失败: $e');
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

/// 广告位楼层：把该层的 VM 以 provider 提供给楼层视图。
class PromoFloor extends StatelessWidget {
  const PromoFloor({super.key, required this.vm});

  final PromoFloorVm vm;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PromoFloorVm>.value(
      value: vm,
      child: const PromoFloorView(),
    );
  }
}

/// 广告位楼层视图。
class PromoFloorView extends StatelessWidget {
  const PromoFloorView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PromoFloorVm>();
    Widget body;
    if (vm.loading) {
      body = const FloorLoadingView(height: 96);
    } else if (vm.error != null) {
      body = FloorErrorView(message: vm.error!, onRetry: vm.load, height: 96);
    } else {
      body = PromoCard(img: vm.img);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: body,
    );
  }
}

/// 广告位（点击走 WebView 宿主通道）。
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
              Image.asset(img, fit: BoxFit.cover),
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
