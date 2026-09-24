/// 自定义模型（Model）：无注解的普通数据类。
///
/// 生成器按「调用链」决定是否翻译成 JS：
/// 组件方法体 / build 树里出现 `User(...)` 构造调用时，把本类翻译成
/// JS 类（function User(args) { this.name = args.name; ... }）注入该组件
/// 产物；未用到的模型不翻译（如 BannerCard 不用 User → 产物里没有 User）。
class User {
  final String name;
  final int age;

  const User({required this.name, required this.age});
}
