import 'package:flutter/services.dart';

import '../js_runtime_manager.dart';
import 'builtin_host_method_group.dart';
import 'channel_shared.dart';

/// JS 侧 `BasicMessageChannel`：send + setMessageHandler。
final class BasicMessageChannelHostMethods extends BuiltinHostMethodGroup {
  /// `name#codec` → 当前注册的 JS 消息回调句柄 id。
  final Map<String, String> _handlerIds = {};

  @override
  Map<String, Function> get methods => {
    'basicMessageChannelSend': _send,
    'basicMessageChannelHandler': _setHandler,
  };

  /// `basicMessageChannelSend`：JS 侧 `BasicMessageChannel.send(message)` 的宿主落点。
  ///
  /// 只支持 Standard / JSON / String 三种内置 codec；Binary（ByteData）需要
  /// 二进制承载，当前桥是 JSON，显式报错而不是静默降级。
  Future<Object?> _send(String name, String codec, Object? message) async {
    switch (codec) {
      case 'string':
        return BasicMessageChannel<String>(
          name,
          const StringCodec(),
        ).send(message == null ? '' : '$message');
      case 'json':
        return BasicMessageChannel<dynamic>(
          name,
          const JSONMessageCodec(),
        ).send(message);
      case 'standard':
        return BasicMessageChannel<dynamic>(
          name,
          const StandardMessageCodec(),
        ).send(message);
      default:
        throw UnsupportedError(
          'BasicMessageChannel codec "$codec" 暂不支持'
          '（仅 standard / json / string）',
        );
    }
  }

  /// `basicMessageChannelHandler`：JS 侧 `setMessageHandler` 的宿主落点。
  ///
  /// 原生发来消息时经 `invokeAwait` 执行 JS 回调，返回值即 native 收到的
  /// reply；JS 抛错则转 `PlatformException`。
  Future<Object?> _setHandler(
    String name,
    String codec,
    String? handlerId,
  ) async {
    final key = '$name#$codec';
    if (handlerId == null) {
      _handlerIds.remove(key);
      _setMessageHandler(name, codec, null);
      return null;
    }
    _handlerIds[key] = handlerId;
    _setMessageHandler(name, codec, (message) async {
      if (_handlerIds[key] != handlerId) return null;
      final raw = await JsRuntimeManager.invokeAwait(
        {'__fn': handlerId},
        [message],
      );
      return unwrapJsHandlerResult(raw);
    });
    return null;
  }

  /// 按 codec 选择具体泛型的 `BasicMessageChannel` 注册消息回调。
  void _setMessageHandler(
    String name,
    String codec,
    Future<Object?> Function(Object?)? handler,
  ) {
    switch (codec) {
      case 'string':
        BasicMessageChannel<String>(
          name,
          const StringCodec(),
        ).setMessageHandler(
          handler == null
              ? null
              : (m) async => ((await handler(m)) as String?) ?? '',
        );
      case 'json':
        BasicMessageChannel<dynamic>(
          name,
          const JSONMessageCodec(),
        ).setMessageHandler(handler == null ? null : (m) async => handler(m));
      case 'standard':
        BasicMessageChannel<dynamic>(
          name,
          const StandardMessageCodec(),
        ).setMessageHandler(handler == null ? null : (m) async => handler(m));
      default:
        throw UnsupportedError(
          'BasicMessageChannel codec "$codec" 暂不支持'
          '（仅 standard / json / string）',
        );
    }
  }
}
