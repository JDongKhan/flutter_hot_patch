/// 楼层描述：配置里的 type + 该楼层对应的 VM。
///
/// [vm] 是具体楼层 VM（运行时按 type 分派），首页用它把楼层装配成对应组件。
///
/// 说明：各楼层 VM 都直接继承 `ChangeNotifier`，不抽项目内公共基类——
/// 产物里子类调用父类（项目类）继承来的成员无法被解析，会丢语句；因此
/// 楼层 VM 的「加载 / 刷新 / 城市」字段与方法各自声明，行为保持一致。
class HomeFloor {
  final String type;
  final dynamic vm;

  const HomeFloor({required this.type, required this.vm});
}
