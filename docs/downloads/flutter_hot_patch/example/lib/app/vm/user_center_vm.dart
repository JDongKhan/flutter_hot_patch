import 'package:flutter/foundation.dart';

import '../model/app_models.dart';
import '../service/app_service.dart';

/// 用户中心 VM：一个接口（`/app/user`）撑起整页。
class UserCenterVm extends ChangeNotifier {
  final AppService _service = AppService();

  UserProfile? feed;
  bool loading = true;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      feed = await _service.fetchUserProfile();
      error = null;
    } catch (e) {
      print('UserCenterVm 加载失败: $e');
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }
}
