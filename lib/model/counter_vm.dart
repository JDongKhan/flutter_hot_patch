import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

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
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }

  Future<String> getUserName() async {
    return "22";
  }

  Widget buildText() {
    return Text("test 2");
  }
}
