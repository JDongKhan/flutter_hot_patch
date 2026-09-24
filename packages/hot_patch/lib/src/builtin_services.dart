import 'package:flutter/material.dart';

import 'native_service.dart';

/// 内置原生服务策略：开箱即用的 JS→原生 能力。
///
/// 新增内置服务 = 在这里加一个 service 类 + register 一行；
/// 自定义服务 = 业务方实现 NativeService 并通过
/// HotPatchWidget(nativeServices: ...) 注入，核心代码零改动。
void registerBuiltinNativeServices(NativeServiceRegistry registry) {
  registry
    ..register(const SnackBarService())
    ..register(const LogService());
}

/// SnackBarService：channel=nativeToast，弹原生 SnackBar。
/// 与页面无关 → 全局服务（context 由 JsRuntimeManager.navigatorKey 提供）。
///
/// JS 侧：sendMessage('nativeToast', JSON.stringify({key, message: '...'}))
class SnackBarService extends GlobalNativeService {
  const SnackBarService();

  @override
  String get channel => 'nativeToast';

  @override
  void handle(BuildContext context, dynamic payload) {
    final message = payload is Map
        ? payload['message']?.toString()
        : payload?.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? '')),
    );
  }
}

/// LogService：channel=log，JS 侧打日志（调试用）。
/// 与页面无关 → 全局服务。
///
/// JS 侧：sendMessage('log', '任意文本')
class LogService extends GlobalNativeService {
  const LogService();

  @override
  String get channel => 'log';

  @override
  void handle(BuildContext context, dynamic payload) {
    debugPrint('[hot_patch][js-log] $payload');
  }
}
