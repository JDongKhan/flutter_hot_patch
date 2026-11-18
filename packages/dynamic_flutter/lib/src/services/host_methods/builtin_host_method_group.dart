/// 框架内建宿主方法组：一个子类 = 一个能力域的通道集合。
///
/// 子类只声明本组的通道表；注册与幂等由
/// `builtin_host_methods.dart` 的 `registerBuiltinHostMethods` 统一处理。
/// 有会话状态（handler / 订阅 / 帧调度）的组自己持字段，生命周期与进程一致。
abstract class BuiltinHostMethodGroup {
  const BuiltinHostMethodGroup();

  /// 本组「通道名 → 实现」表；实现签名见 `registerHostMethod` 的调用约定。
  Map<String, Function> get methods;
}
