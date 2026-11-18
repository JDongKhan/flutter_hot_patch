import 'package:flutter/material.dart';

import '../../utils/dynamic_flutter_log.dart';
import '../js_runtime_manager.dart';
import 'builtin_host_method_group.dart';

/// `nativeToast`：弹原生 SnackBar。context 由 [JsRuntimeManager.navigatorKey]
/// 提供（全局服务，与页面无关）。
final class NativeToastHostMethods extends BuiltinHostMethodGroup {
  const NativeToastHostMethods();

  @override
  Map<String, Function> get methods => {'nativeToast': _nativeToast};

  void _nativeToast({String? message}) {
    final ctx = JsRuntimeManager.navigatorKey?.currentContext;
    if (ctx == null || !ctx.mounted) {
      JsLog.warn(
        'nativeToast ignored: navigatorKey not configured / context not ready',
      );
      return;
    }
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(SnackBar(content: Text(message ?? '')));
  }
}
