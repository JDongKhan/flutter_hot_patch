// ===== Dart 内置异常镜像（JS 侧片段，随 flutter.js 发布）=====
//
// 翻译层把任何类构造统一发射为 `new X({...})`，Dart 内置异常
// （StateError / ArgumentError / FormatException / RangeError / …）在 JS 里没有
// 同名类，产物执行即为 ReferenceError、`throw` / `catch` 整段失效。这里按
// **同名类注入**补齐：构造签名与 Dart 一致（props 形态），实例是标准 Error。
//
// 归属 flutter.js（Dart 值/语言镜像区）：runtime.js 只做运行环境与 mini-react
// 核心，自身不构造任何异常；异常的消费方是产物代码（按名从 flutter.js import），
// 依赖方向因此只有 flutter.js → runtime.js。
//
// 不做类名白名单维护：新增异常类只需在此补一行 `export const`（JS 侧能力扩展），
// 翻译器与运行时框架都不改动。
const String dartErrorsJsSource = r'''
  function __dartErrorCtor(name, positional) {
    var ctor = function (props) {
      props = __positionalArgs(props, positional);
      var msg = props.message;
      var err = new Error(msg == null ? '' : String(msg));
      err.name = name;
      return err;
    };
    ctor.prototype = Error.prototype;
    // 命名构造 `X.value(value, [name, message])`：Dart 侧统一映射为静态方法。
    ctor.value = function (props) {
      props = __positionalArgs(props, ['value', 'name', 'message']);
      var msg = props.message != null ? props.message : props.name;
      var err = ctor({ message: msg });
      err.value = props.value;
      return err;
    };
    return ctor;
  }
  export const StateError = __dartErrorCtor('StateError', ['message']);
  export const ArgumentError = __dartErrorCtor('ArgumentError', ['message']);
  export const FormatException =
    __dartErrorCtor('FormatException', ['message', 'source', 'offset']);
  export const RangeError = __dartErrorCtor('RangeError', ['message']);
  export const UnsupportedError = __dartErrorCtor('UnsupportedError', ['message']);
  export const UnimplementedError =
    __dartErrorCtor('UnimplementedError', ['message']);
  export const Exception = __dartErrorCtor('Exception', ['message']);
  // `Error` 不导出：JS 原生 Error 就是 Dart Error 的落点（两者同名同义），
  // 导出同名类反而会遮蔽模块内的原生 Error（dart 侧 `new Error(props)` 也
  // 极少出现，保持原生即可）。
''';
