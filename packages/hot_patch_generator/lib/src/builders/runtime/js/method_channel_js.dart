// ===== MethodChannel：flutter/services 同名镜像（flutter.js 值类区）=====
//
// 三方库 / 插件里的 Dart 代码被翻译成 JS 后，`MethodChannel('name')`
// 原样保留；这里提供同名类。JS 侧**不持有原生句柄**：channel 的身份就是
// `(name, codec)`，宿主按同一个键缓存 Dart 侧 MethodChannel 实例——等价于
// 「JS channel 与 Dart channel 实例绑定」，但不需要异步 acquire / release
// （MethodChannel 无状态、无 dispose，同名实例共享 messenger 路由）。
//
// 调用链（不绕过 Flutter 通道）：
//   MethodChannel.invokeMethod
//     → _app_host_.invoke('methodChannel', [name, codec, method, args])
//     → 宿主 Dart MethodChannel(name, codec).invokeMethod(method, args)
//     → 原生
//
// 反向（原生 → Flutter → JS）：
//   setMethodCallHandler(fn)
//     → _app_host_.invoke('methodChannelHandler', [name, codec, fnHandle])
//     → 宿主 MethodChannel.setMethodCallHandler：native 调用到达时
//     → JsRuntimeManager.invokeAwait(fnHandle, [method, args])
//     → JS 执行 fn，结果经 jsuiEventResult 回传宿主，再回给原生
//
// codec 只镜像「默认 StandardMethodCodec / JSONMethodCodec」；自定义 codec
// 无法在 JS 侧复刻，由构建期告警，不做占位兜底。
//
// 回调结果统一包成 `{value}` / `{__mcError}`：宿主据此区分「正常返回」与
// 「JS 抛错」，后者转成 PlatformException 回给原生（invokeAwait 本身把异常
// 折叠为 null，无法区分，故包装放在 JS 侧）。
const String methodChannelJsSource = r'''
  // ----- MethodChannel ------------------------------------------------------

  // name#codec → 当前注册的 JS 函数句柄 id。Dart 语义：同名 channel 的
  // handler 是「名下唯一」，新注册覆盖旧注册；这里按同一个键释放旧句柄。
  var __methodChannelHandlerIds = {};

  export class StandardMethodCodec {
    constructor() { this.__codec = 'standard'; }
  }
  export class JSONMethodCodec {
    constructor() { this.__codec = 'json'; }
  }
  export class MethodChannel {
    constructor(args) {
      this.name = (args && args.name !== undefined) ? args.name : '';
      var codec = args && args.codec;
      this.codec = (codec && codec.__codec) ? codec.__codec : 'standard';
    }
    invokeMethod(method, args) {
      return Future.__wrap(G._app_host_.invoke(
        'methodChannel', [this.name, this.codec, method, args]));
    }
    invokeListMethod(method, args) {
      return this.invokeMethod(method, args);
    }
    invokeMapMethod(method, args) {
      return this.invokeMethod(method, args);
    }
    setMethodCallHandler(handler) {
      var key = this.name + '#' + this.codec;
      var prev = __methodChannelHandlerIds[key];
      if (prev) {
        G.__core.__releaseHandle(prev, false);
        delete __methodChannelHandlerIds[key];
      }
      var id = null;
      if (typeof handler === 'function') {
        // __createFnHandle 返回信封 {__fn: id}，宿主只认 id。
        var env = G.__core.__createFnHandle(__methodChannelHandlerWrapper(handler));
        id = env.__fn;
        __methodChannelHandlerIds[key] = id;
      }
      // 与 Dart 一致：setMethodCallHandler 是 void（注册失败只留日志）。
      G._app_host_.invoke(
        'methodChannelHandler', [this.name, this.codec, id]
      ).catch(function (e) {
        __error('MethodChannel.setMethodCallHandler: ' + String(e));
      });
    }
  }

  // 把 Dart 侧的 `(MethodCall call) async {…}` 形态还原成 JS 可执行函数：
  // 宿主传 [method, arguments]，这里装箱成 `{method, arguments}`（MethodCall
  // 的两个公开字段），同步 / 异步结果统一折成 `{value}` 或 `{__mcError}`。
  function __methodChannelHandlerWrapper(handler) {
    return function (method, args) {
      var call = { method: method, arguments: args };
      var out;
      try {
        out = handler(call);
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
