import 'package:flutter/foundation.dart';

import '../model/app_models.dart';
import '../service/app_service.dart';

/// 外壳 VM：从 `/app/tabs` 拉取底部导航配置。
///
/// 外壳用这份配置决定 tab 的顺序、文案、图标以及装配哪个页面。
class AppShellVm extends ChangeNotifier {
  final AppService _service = AppService();

  List<AppTabConfig> tabs = [];

  bool loading = true;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      tabs = await _service.fetchAppTabs();
      error = null;
    } catch (e) {
      print('AppShellVm 底部配置加载失败: $e');
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }
}
