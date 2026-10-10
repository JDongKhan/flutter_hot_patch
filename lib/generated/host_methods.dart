// GENERATED CODE - DO NOT MODIFY BY HAND
//
// 由 ui_component_generator 的 hostRegisterBuilder 扫描全包
// `@HostInjected` 方法生成。用法（main() 里调用一次）：
//
//   registerHostMethods();
//
// 注册目标默认指向配套运行时（package:hot_patch/hot_patch.dart），
// 需要换运行时实现时用 build.yaml 的 register_import / register_call 覆盖。

import 'package:hot_patch/hot_patch.dart';

import '../base/account_center.dart';
import '../base/network.dart';

/// 注册本包全部 `@HostInjected` 宿主方法（无注解时为空实现）。
void registerHostMethods() {
  JsRuntimeManager.registerHostMethod('getUserName', (args) => Function.apply(AccountCenter.getUserName, args));
  JsRuntimeManager.registerHostMethod('post', (args) => Function.apply(Network.post, args));
}
