import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hot_example/base/app_router.dart';
import 'package:provider/provider.dart';

import '../model/app_models.dart';
import '../service/app_service.dart';
import 'floor_status.dart';

/// 九宫格楼层 VM：**自己请求** `/app/home/grid` 取这一层的数据。
class GridFloorVm extends ChangeNotifier {
  GridFloorVm({required this.city});

  String city;
  bool loading = true;
  String? error;

  final AppService _service = AppService();

  List<GridEntry> grid = [];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      grid = await _service.fetchHomeGrid();
      error = null;
    } catch (e) {
      print('GridFloor 加载失败: $e');
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

/// 九宫格楼层：把该层的 VM 以 provider 提供给楼层视图。
class GridFloor extends StatelessWidget {
  const GridFloor({super.key, required this.vm});

  final GridFloorVm vm;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GridFloorVm>.value(
      value: vm,
      child: const GridFloorView(),
    );
  }
}

/// 九宫格楼层视图。
class GridFloorView extends StatelessWidget {
  const GridFloorView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GridFloorVm>();
    Widget body;
    if (vm.loading) {
      body = const FloorLoadingView();
    } else if (vm.error != null) {
      body = FloorErrorView(message: vm.error!, onRetry: vm.load);
    } else {
      body = Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        // 九宫格高度恒定：格子高度交给 mainAxisExtent 固定，列数交给
        // Flutter 按可用宽度动态算（maxCrossAxisExtent）。
        child: GridView(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            mainAxisExtent: 84,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < vm.grid.length; i++) GridCell(entry: vm.grid[i]),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: body,
    );
  }
}

/// 九宫格单元。
class GridCell extends StatelessWidget {
  const GridCell({super.key, required this.entry});

  final GridEntry entry;

  void open() {
    AppRouter.openChannel(entry.title, entry.emoji);
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
