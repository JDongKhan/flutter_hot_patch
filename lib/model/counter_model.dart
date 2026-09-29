import 'package:flutter/foundation.dart';

/// 响应式模型：ChangeNotifier 子类。
///
/// 生成器把本类翻译成 JS class（extends ChangeNotifier，运行时注入基类），
/// 业务方法（inc/reset）一比一翻译，notifyListeners 触发 ListenableBuilder
/// 局部重建（JS 侧通过 lbNotify 通道，见 HotPatchWidget）。
class CounterModel extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void inc() {
    _count++;
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}
