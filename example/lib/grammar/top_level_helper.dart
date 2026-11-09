import '../model/counter_vm.dart';

/// 顶层函数验证：跨文件调用与产物发射。
String topLevelPrefix(String value) => '顶层:$value';

/// 具名参数 / 默认值验证：与成员函数共用 _functionParamPlan。
String topLevelGreet({required String name, String prefix = 'Hi'}) =>
    '$prefix:$name';

/// 函数体引用跨文件模型：验证类依赖 import。
CounterVm topLevelCounter() => CounterVm();

/// 生成器顶层函数：与 sync* 闭包 / 方法共用同一实现。
Iterable<int> topLevelNums() sync* {
  yield 1;
  yield 2;
}
