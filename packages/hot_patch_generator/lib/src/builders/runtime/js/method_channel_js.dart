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
// codec 只镜像「默认 StandardMethodCodec / JSONMethodCodec」；自定义 codec
// 无法在 JS 侧复刻，由构建期告警，不做占位兜底。
const String methodChannelJsSource = r'''
  // ----- MethodChannel ------------------------------------------------------
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
  }
''';
