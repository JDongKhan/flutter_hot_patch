// ===== 基础能力：Dart 内置异常镜像（JS 侧片段）=====
//
// 翻译层把任何类构造统一发射为 `new X({...})`，Dart 内置异常
// （StateError / ArgumentError / FormatException / RangeError / …）在 JS 里没有
// 同名类，产物执行即为 ReferenceError、`throw` / `catch` 整段失效。这里按
// **同名类注入**补齐：构造签名与 Dart 一致（props 形态），实例是标准 Error。
//
// 不做类名白名单维护：新增异常类只需在此补一个 G 赋值（JS 侧能力扩展），
// 翻译器与运行时框架都不改动。
const String dartErrorsJsSource = r'''
  function __dartErrorCtor(name, positional) {
    var ctor = function (props) {
      props = __posArgs(props, positional);
      var msg = props.message;
      var err = new Error(msg == null ? '' : String(msg));
      err.name = name;
      return err;
    };
    ctor.prototype = Error.prototype;
    // 命名构造 `X.value(value, [name, message])`：Dart 侧统一映射为静态方法。
    ctor.value = function (props) {
      props = __posArgs(props, ['value', 'name', 'message']);
      var msg = props.message != null ? props.message : props.name;
      var err = ctor({ message: msg });
      err.value = props.value;
      return err;
    };
    return ctor;
  }
  G.StateError = __dartErrorCtor('StateError', ['message']);
  G.ArgumentError = __dartErrorCtor('ArgumentError', ['message']);
  G.FormatException = __dartErrorCtor('FormatException', ['message', 'source', 'offset']);
  G.RangeError = __dartErrorCtor('RangeError', ['message']);
  G.UnsupportedError = __dartErrorCtor('UnsupportedError', ['message']);
  G.UnimplementedError = __dartErrorCtor('UnimplementedError', ['message']);
  G.Exception = __dartErrorCtor('Exception', ['message']);
  G.Error = G.Error || __dartErrorCtor('Error', ['message']);
''';
