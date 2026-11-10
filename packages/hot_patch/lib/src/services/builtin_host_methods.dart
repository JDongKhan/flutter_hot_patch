import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../js_ui/js_ui_store.dart';
import '../utils/hot_patch_assets.dart';
import '../utils/hot_patch_log.dart';
import 'js_runtime_manager.dart';

// ===========================================================================
// 框架内建宿主方法（通道）注册
//
// 与业务 @HostInjected 方法共用唯一入口 JsRuntimeManager.registerHostMethod
// 与唯一处理器表；JS 侧也只有唯一出口 `_app_host_.invoke`。六条内建通道：
//   - `log`          ← Dart 日志全局（JS 侧 print/debugPrint → __log →
//                      _app_host_.invoke('log', [..])）
//   - `nativeToast`  ← 生成器把 SnackBar 形式动作译为
//                      `_app_host_.invoke('nativeToast', {message})`
//   - `jsuiCommit`   ← JS 增量补丁，payload 带页面 key，路由到对应 JsUiStore
//   - `jsuiRequestFrame` ← JS 侧 setState 后请求一帧；宿主在 begin frame 统一
//                      flush，把同一帧内的多次 setState 合并成一次 build
//                      （与 Flutter 的 setState 语义一致）
//   - `assetLoadString` ← JS 侧 `rootBundle.loadString(key)` 的宿主落点
//   - `methodChannel`  ← JS 侧 `MethodChannel.invokeMethod` 的宿主落点：
//                      一个通用入口承接所有 channel（name / codec 是参数，
//                      不是注册项），宿主按 `name#codec` 缓存 Dart 侧实例，
//                      再调用真正的 Flutter MethodChannel → 原生
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
  JsRuntimeManager.registerHostMethod('assetLoadString', _assetLoadString);
  JsRuntimeManager.registerHostMethod('methodChannel', _methodChannel);
  JsRuntimeManager.registerHostMethod(
    'methodChannelHandler',
    _methodChannelHandler,
  );
}

/// JS 侧 `MethodChannel` 的宿主实例缓存。
///
/// 键是 channel 身份 `name#codec`，不是运行时句柄：Dart 的 MethodChannel
/// 无状态、无 dispose，同名实例共享 binaryMessenger 的 channel 路由，因此
/// 「一个 JS channel 对象对应一个 Dart 实例」用该键即可精确表达，且重载
/// 补丁 / 页面销毁都不需要释放。
final Map<String, MethodChannel> _methodChannels = {};

/// `methodChannel`：把 JS 侧的 `(channel, codec, method, args)` 还原成
/// Dart 侧 `MethodChannel(name, codec).invokeMethod(method, args)`，由 Flutter
/// 的 binaryMessenger 继续发往原生——不绕过、也不新开 JS↔原生通道。
Future<Object?> _methodChannel(
  String name,
  String codec,
  String method, [
  Object? arguments,
]) {
  return _channelOf(name, codec).invokeMethod<Object?>(method, arguments);
}

/// `name#codec` → 当前注册的 JS 函数句柄 id。
///
/// 与 Dart 的语义一致：handler 归 **channel 名**所有，同名新注册覆盖旧注册
/// （旧 JS 句柄由 JS 侧释放）。null 表示已注销。
final Map<String, String> _methodChannelHandlerIds = {};

/// `methodChannelHandler`：JS 侧 `setMethodCallHandler` 的宿主落点。
///
/// 注册后，原生经该 channel 发来的调用会走 `invokeAwait` 回到 JS 回调；
/// 回调结果包成 `{value}` / `{__mcError}`（见生成器 `method_channel_js.dart`），
/// 后者转成 `PlatformException` 回给原生。
Future<Object?> _methodChannelHandler(
  String name,
  String codec,
  String? handlerId,
) async {
  final key = '$name#$codec';
  final channel = _channelOf(name, codec);
  if (handlerId == null) {
    _methodChannelHandlerIds.remove(key);
    channel.setMethodCallHandler(null);
    return null;
  }
  _methodChannelHandlerIds[key] = handlerId;
  channel.setMethodCallHandler((call) async {
    // 已被新注册覆盖 / 已注销：本次调用按「无 handler」返回 null。
    if (_methodChannelHandlerIds[key] != handlerId) return null;
    final raw = await JsRuntimeManager.invokeAwait(
      {'__fn': handlerId},
      [call.method, call.arguments],
    );
    if (raw is Map && raw.containsKey('__mcError')) {
      throw PlatformException(
        code: 'js_error',
        message: '${raw['__mcError']}',
      );
    }
    return raw is Map ? raw['value'] : null;
  });
  return null;
}

/// 按 channel 身份取（并缓存）Dart 侧 MethodChannel 实例。
MethodChannel _channelOf(String name, String codec) {
  return _methodChannels.putIfAbsent(
    '$name#$codec',
    () => MethodChannel(name, _codecOf(codec)),
  );
}

/// codec 只镜像 Standard / JSON 两种（见生成器的 `JSONMethodCodec` /
/// `StandardMethodCodec` 同名类）；未知标记回落标准 codec。
MethodCodec _codecOf(String name) => switch (name) {
  'json' => const JSONMethodCodec(),
  _ => const StandardMethodCodec(),
};

/// `assetLoadString`：JS 侧 `rootBundle.loadString(key)` 的宿主落点。
///
/// 解析顺序与图片一致：补丁包根下同名文件优先，缺失或读取失败回退 Flutter
/// assets（见 [HotPatchAssets]）。
Future<String> _assetLoadString(String key) =>
    HotPatchAssets.bundle.loadString(key);

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

/// `log`：JS 侧 `print` / `debugPrint` → HotPatchLog。级别由 JS 侧一并传来
/// （见 runtime_js 的 `G.print` / `G.debugPrint`：info / debug），未知级别
/// 按 info 处理。
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
  ScaffoldMessenger.of(
    ctx,
  ).showSnackBar(SnackBar(content: Text(message ?? '')));
}

/// `jsuiCommit`：把 JS 算好的增量补丁按页面 key 应用到对应 [JsUiStore]。
void _commit({required String key, required List ops}) {
  final store = jsUiPageStores[key];
  if (store == null) {
    // 页面已销毁 / 还没登记：补丁无处可落，整批丢弃。属于正常竞态，但必须留痕。
    HotPatchLog.debug(
      'jsuiCommit: 页面 "$key" 已销毁或未登记，'
      '${ops.length} 条补丁已丢弃',
    );
    return;
  }
  store.apply(ops);
}
