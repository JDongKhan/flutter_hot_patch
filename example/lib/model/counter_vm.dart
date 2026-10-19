import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../components/banner_component.dart';

/// 响应式模型：ChangeNotifier 子类。
///
/// 生成器把本类翻译成 JS class（extends ChangeNotifier，运行时注入基类），
/// 业务方法（inc/reset）一比一翻译，notifyListeners 触发 JS 侧
/// ListenableBuilder 局部重建。
class CounterVm extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void inc() async {
    _count++;
    // 语句级 if：到达上限自动归零（生成器 if 语句翻译演示）
    if (_count >= 10) {
      _count = 0;
    }
    notifyListeners();
  }

  void reset() {
    // 语句级 while：逐次递减归零（生成器 while 语句翻译演示）
    while (_count > 0) {
      _count--;
    }
    notifyListeners();
  }

  Future<String> getUserName() async {
    return "22";
  }

  Widget buildText() {
    return BannerCard();
  }
}
