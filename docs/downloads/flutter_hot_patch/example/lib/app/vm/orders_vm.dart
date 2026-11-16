import 'package:flutter/foundation.dart';

import '../model/app_models.dart';
import '../service/app_service.dart';

/// 订单页 VM：状态筛选条 + 订单列表两个接口的状态与交互都收敛在这里。
class OrdersVm extends ChangeNotifier {
  OrdersVm({this.initialStatus});

  /// 初始选中的状态（「我的」页统计项跳进来时指定）。
  final String? initialStatus;

  final AppService _service = AppService();

  OrderFeed? feed;
  List<Order>? orders;

  bool listLoading = false;

  String? feedError;
  String? ordersError;

  /// 当前选中的状态；空串 = 还没定（等价首项「全部」）。
  String status = '';

  /// 首屏：配置与列表并行发。
  void load() {
    loadFeed();
    loadOrders();
  }

  Future<void> loadFeed() async {
    try {
      final OrderFeed value = await _service.fetchOrders();
      feed = value;
      status = initialStatus ?? value.statuses.first;
      feedError = null;
      notifyListeners();
      // 带具体状态跳进来时，首屏那次「空参数（=全部）」的结果不对口，按状态重发。
      if (initialStatus != null) {
        await loadOrders();
      }
    } catch (e) {
      print('OrdersVm 状态条加载失败: $e');
      feedError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    listLoading = true;
    notifyListeners();
    try {
      final List<Order> value = await _service.fetchOrderList(status);
      orders = value;
      listLoading = false;
      ordersError = null;
      notifyListeners();
    } catch (e) {
      print('OrdersVm 订单列表加载失败: $e');
      listLoading = false;
      ordersError = e.toString();
      notifyListeners();
    }
  }

  /// 失败重试：状态条与列表一起重发。
  void retry() {
    feedError = null;
    ordersError = null;
    notifyListeners();
    load();
  }

  /// 点状态：先切高亮，再按新状态请求列表。
  void pickStatus(String value) {
    status = value;
    notifyListeners();
    loadOrders();
  }
}
