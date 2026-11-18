import 'package:flutter/services.dart';

/// codec 只镜像 Standard / JSON 两种（见生成器的 `JSONMethodCodec` /
/// `StandardMethodCodec` 同名类）；未知标记回落标准 codec。
MethodCodec codecOf(String name) => switch (name) {
  'json' => const JSONMethodCodec(),
  _ => const StandardMethodCodec(),
};

/// JS 回调结果的统一解包（MethodChannel / BasicMessageChannel 共用）。
///
/// JS 侧把返回值包成 `{value}`、异常包成 `{__mcError}`（见生成器的
/// `method_channel_js.dart` / `basic_message_channel_js.dart`），因为
/// `invokeAwait` 本身会把异常折叠成 null，宿主无法区分。
Object? unwrapJsHandlerResult(Object? raw) {
  if (raw is Map && raw.containsKey('__mcError')) {
    throw PlatformException(code: 'js_error', message: '${raw['__mcError']}');
  }
  return raw is Map ? raw['value'] : null;
}
