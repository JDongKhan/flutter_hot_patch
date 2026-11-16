import 'package:flutter/services.dart';

import '../js_runtime_manager.dart';
import 'builtin_host_method_group.dart';
import 'channel_shared.dart';

/// JS 侧 `MethodChannel`：invokeMethod + setMethodCallHandler。
final class MethodChannelHostMethods extends BuiltinHostMethodGroup {
  /// JS 侧 `MethodChannel` 的宿主实例缓存。
  ///
  /// 键是 channel 身份 `name#codec`，不是运行时句柄：Dart 的 MethodChannel
  /// 无状态、无 dispose，同名实例共享 binaryMessenger 的 channel 路由，因此
  /// 「一个 JS channel 对象对应一个 Dart 实例」用该键即可精确表达，且重载
  /// 补丁 / 页面销毁都不需要释放。
  final Map<String, MethodChannel> _channels = {};

  /// `name#codec` → 当前注册的 JS 函数句柄 id。
  ///
  /// 与 Dart 的语义一致：handler 归 **channel 名**所有，同名新注册覆盖旧注册
  /// （旧 JS 句柄由 JS 侧释放）。null 表示已注销。
  final Map<String, String> _handlerIds = {};

  @override
  Map<String, Function> get methods => {
    'methodChannel': _invoke,
    'methodChannelHandler': _setHandler,
  };

  /// `methodChannel`：把 JS 侧的 `(channel, codec, method, args)` 还原成
  /// Dart 侧 `MethodChannel(name, codec).invokeMethod(method, args)`，由 Flutter
  /// 的 binaryMessenger 继续发往原生——不绕过、也不新开 JS↔原生通道。
  Future<Object?> _invoke(
    String name,
    String codec,
    String method, [
    Object? arguments,
  ]) {
    return _channelOf(name, codec).invokeMethod<Object?>(method, arguments);
  }

  /// `methodChannelHandler`：JS 侧 `setMethodCallHandler` 的宿主落点。
  ///
  /// 注册后，原生经该 channel 发来的调用会走 `invokeAwait` 回到 JS 回调；
  /// 回调结果包成 `{value}` / `{__mcError}`（见生成器 `method_channel_js.dart`），
  /// 后者转成 `PlatformException` 回给原生。
  Future<Object?> _setHandler(
    String name,
    String codec,
    String? handlerId,
  ) async {
    final key = '$name#$codec';
    final channel = _channelOf(name, codec);
    if (handlerId == null) {
      _handlerIds.remove(key);
      channel.setMethodCallHandler(null);
      return null;
    }
    _handlerIds[key] = handlerId;
    channel.setMethodCallHandler((call) async {
      // 已被新注册覆盖 / 已注销：本次调用按「无 handler」返回 null。
      if (_handlerIds[key] != handlerId) return null;
      final raw = await JsRuntimeManager.invokeAwait(
        {'__fn': handlerId},
        [call.method, call.arguments],
      );
      return unwrapJsHandlerResult(raw);
    });
    return null;
  }

  /// 按 channel 身份取（并缓存）Dart 侧 MethodChannel 实例。
  MethodChannel _channelOf(String name, String codec) {
    return _channels.putIfAbsent(
      '$name#$codec',
      () => MethodChannel(name, codecOf(codec)),
    );
  }
}
