import 'package:flutter/material.dart';

import '../js_ui/js_ui_store.dart';
import '../utils/hot_patch_log.dart';
import 'js_runtime_manager.dart';

// ===========================================================================
// 框架内建宿主方法（通道）注册
//
// 与业务 @HostInjected 方法共用唯一入口 JsRuntimeManager.registerHostMethod
// 与唯一处理器表；JS 侧也只有唯一出口 `__jsui.host`。三条内建通道：
//   - `log`          ← console.* 桥（JS 侧 __log → __jsui.host('log', [..])）
//   - `nativeToast`  ← 生成器把 SnackBar 形式动作译为
//                      `__jsui.host('nativeToast', {message})`
//   - `jsuiCommit`   ← JS 增量补丁，payload 带页面 key，路由到对应 JsUiStore
//
// 幂等（全局一次）：由 JsUiWidget 启动时调用。
// ===========================================================================

bool _registered = false;

/// 注册框架内建宿主方法（全局一次，幂等）。
void registerBuiltinHostMethods() {
  if (_registered) return;
  _registered = true;
  JsRuntimeManager.registerHostMethod('log', _log);
  JsRuntimeManager.registerHostMethod('nativeToast', _nativeToast);
  JsRuntimeManager.registerHostMethod('jsuiCommit', _commit);
}

/// `log`：JS console 桥 → HotPatchLog。
void _log(Object? message) => HotPatchLog.log('[js-log] $message');

/// `nativeToast`：弹原生 SnackBar。context 由 [JsRuntimeManager.navigatorKey]
/// 提供（全局服务，与页面无关）。
void _nativeToast({String? message}) {
  final ctx = JsRuntimeManager.navigatorKey?.currentContext;
  if (ctx == null || !ctx.mounted) {
    HotPatchLog.log(
      'nativeToast ignored: navigatorKey not configured / context not ready',
    );
    return;
  }
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message ?? '')));
}

/// `jsuiCommit`：把 JS 算好的增量补丁按页面 key 应用到对应 [JsUiStore]。
void _commit({required String key, required List ops}) {
  jsUiPageStores[key]?.apply(ops);
}