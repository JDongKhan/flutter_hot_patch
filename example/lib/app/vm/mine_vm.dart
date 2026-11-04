import 'package:flutter/foundation.dart';

import '../model/app_models.dart';
import '../service/app_service.dart';

/// 我的页 VM：头像 + 订单统计 + 功能菜单。
class MineVm extends ChangeNotifier {
  final AppService _service = AppService();

  MineFeed? feed;
  bool loading = true;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      feed = await _service.fetchMine();
      error = null;
    } catch (e) {
      print('MineVm 加载失败: $e');
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }
}
