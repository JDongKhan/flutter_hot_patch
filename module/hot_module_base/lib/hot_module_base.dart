/// 模块化基座包出口：网络请求、账号能力与通用模型 / 工具类。
///
/// 本包是**独立 Dart 包**（不属于 example App），被 example 以
/// `package:hot_module_base/...` 引用——用于验证生成器的跨包翻译能力：
///   - `@HostInjected` 宿主能力类（[Network] / [AccountCenter]）：跨包调用点
///     仍翻译为 `_app_host_.invoke(...)`，并由宿主注册清单跨包注册；
///   - 普通类（[User]）：跨包类表解析 + 聚合产物 import；
///   - `mixin`（[StateLogMixin]）与 `extension`（[StringLogExtension]）：
///     跨包语法能力验证，demo 见 example 的「基础语法」页。
library;

export 'src/account_center.dart';
export 'src/guide_bubble_widget.dart';
export 'src/model/user.dart';
export 'src/network.dart';
export 'src/state_log_mixin.dart';
export 'src/string_log_extension.dart';
