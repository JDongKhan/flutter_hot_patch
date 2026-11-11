// ===== BasicMessageChannel：flutter/services 同名镜像（flutter.js 值类区）=====
//
// 与 MethodChannel 同构，只是消息体直接是 codec 的 T 值：
//   send(message)
//     → _app_host_.invoke('basicMessageChannelSend', [name, codec, message])
//     → 宿主 BasicMessageChannel(name, codec).send(message) → 原生 reply
//
//   setMessageHandler(fn)（原生主动发消息）
//     → _app_host_.invoke('basicMessageChannelHandler', [name, codec, fnHandle])
//     → 宿主 BasicMessageChannel.setMessageHandler：native 发来消息时
//     → JsRuntimeManager.invokeAwait(fnHandle, [message])
//     → JS 返回的值即 native 收到的 reply
//
// codec 只镜像 Standard / String / JSON / Binary 四种内置 codec；Binary 需要
// ByteData 二进制承载，当前桥是 JSON，暂不支持（宿主显式报错，不做占位兜底）。
const String basicMessageChannelJsSource = r'''
  // ----- BasicMessageChannel ------------------------------------------------

  // name#codec → 当前注册的 JS 函数句柄 id（与 MethodChannel 分开存，
  // 两者同名 channel 互不影响）。
  var __basicMessageHandlerIds = {};

  export class StandardMessageCodec {
    constructor() { this.__codec = 'standard'; }
  }
  export class StringCodec {
    constructor() { this.__codec = 'string'; }
  }
  export class JSONMessageCodec {
    constructor() { this.__codec = 'json'; }
  }
  export class BinaryCodec {
    constructor() { this.__codec = 'binary'; }
  }

  export class BasicMessageChannel {
    constructor(args) {
      this.name = (args && args.name !== undefined) ? args.name : '';
      var codec = args && args.codec;
      this.codec = (codec && codec.__codec) ? codec.__codec : 'standard';
    }
    send(message) {
      return Future.__wrap(G._app_host_.invoke(
        'basicMessageChannelSend', [this.name, this.codec, message]));
    }
    setMessageHandler(handler) {
      var key = this.name + '#' + this.codec;
      var prev = __basicMessageHandlerIds[key];
      if (prev) {
        G.__core.__releaseHandle(prev, false);
        delete __basicMessageHandlerIds[key];
      }
      var id = null;
      if (typeof handler === 'function') {
        // __createFnHandle 返回信封 {__fn: id}，宿主只认 id。
        var env = G.__core.__createFnHandle(__basicMessageHandlerWrapper(handler));
        id = env.__fn;
        __basicMessageHandlerIds[key] = id;
      }
      // 与 Dart 一致：setMessageHandler 是 void（注册失败只留日志）。
      G._app_host_.invoke(
        'basicMessageChannelHandler', [this.name, this.codec, id]
      ).catch(function (e) {
        __error('BasicMessageChannel.setMessageHandler: ' + String(e));
      });
    }
  }

  // 回调结果同样折成 `{value}` / `{__mcError}`：宿主据此区分正常返回与抛错，
  // 后者转 PlatformException 交给原生。
  function __basicMessageHandlerWrapper(handler) {
    return function (message) {
      var out;
      try {
        out = handler(message);
      } catch (e) {
        return { __mcError: String(e) };
      }
      if (out && typeof out.then === 'function') {
        return out.then(
          function (v) { return { value: v === undefined ? null : v }; },
          function (e) { return { __mcError: String(e) }; });
      }
      return { value: out === undefined ? null : out };
    };
  }
''';
