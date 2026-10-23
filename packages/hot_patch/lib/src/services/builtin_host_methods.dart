import 'package:flutter/material.dart';

import '../js_ui/js_ui_store.dart';
import '../utils/hot_patch_log.dart';
import 'js_runtime_manager.dart';

// ===========================================================================
// 框架内建宿主方法（通道）注册
//
// 与业务 @HostInjected 方法共用唯一入口 JsRuntimeManager.registerHostMethod
// 与唯一处理器表；JS 侧也只有唯一出口 `_app_host_.invoke`。四条内建通道：
//   - `log`          ← console.* 桥（JS 侧 __log → _app_host_.invoke('log', [..])）
//   - `nativeToast`  ← 生成器把 SnackBar 形式动作译为
//                      `_app_host_.invoke('nativeToast', {message})`
//   - `jsuiCommit`   ← JS 增量补丁，payload 带页面 key，路由到对应 JsUiStore
//   - `jsuiRequestFrame` ← JS 侧 setState 后请求一帧；宿主在 begin frame 统一
//                      flush，把同一帧内的多次 setState 合并成一次 build
//                      （与 Flutter 的 setState 语义一致）
//
// 幂等（全局一次）：由 JsUiWidget 启动时调用。
// ===========================================================================

bool _registered = false;

/// 是否已调度了一帧级 flush（同一帧内重复请求只调度一次）。
bool _flushScheduled = false;

/// 注册框架内建宿主方法（全局一次，幂等）。
void registerBuiltinHostMethods() {
  if (_registered) return;
  _registered = true;
  JsRuntimeManager.registerHostMethod('log', _log);
  JsRuntimeManager.registerHostMethod('nativeToast', _nativeToast);
  JsRuntimeManager.registerHostMethod('jsuiCommit', _commit);
  JsRuntimeManager.registerHostMethod('jsuiRequestFrame', _requestFrame);
}

/// `jsuiRequestFrame`：JS 侧有脏组件，请求在下一帧统一 flush。
///
/// 用 transient frame callback（动画同款）：它在 begin frame 的 **build 之前**
/// 执行（早于 `drawFrame` 的持久回调），JS 下发的 ops 能在本帧生效——与 Flutter
/// `setState` → 下一帧 build 的时序一致。
void _requestFrame() {
  if (_flushScheduled) return;
  _flushScheduled = true;
  WidgetsBinding.instance.scheduleFrameCallback((_) {
    _flushScheduled = false;
    JsRuntimeManager.flushJsUiPending();
  });
}

/// `log`：JS console 桥 → HotPatchLog。级别由 JS 侧一并传来（见 runtime_source
/// 的 `G.console`：debug / log·info / warn / error），未知级别按 info 处理——
/// 这样 JS 侧 `console.error` 在宿主就是 error 级，能直接进统一上报出口。
void _log(String? level, Object? message) =>
    HotPatchLog.emit(_levelOf(level), '[js-log] $message');

HotPatchLevel _levelOf(String? name) => switch (name) {
      'debug' => HotPatchLevel.debug,
      'warn' => HotPatchLevel.warn,
      'error' => HotPatchLevel.error,
      _ => HotPatchLevel.info,
    };

/// `nativeToast`：弹原生 SnackBar。context 由 [JsRuntimeManager.navigatorKey]
/// 提供（全局服务，与页面无关）。
void _nativeToast({String? message}) {
  final ctx = JsRuntimeManager.navigatorKey?.currentContext;
  if (ctx == null || !ctx.mounted) {
    HotPatchLog.warn(
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