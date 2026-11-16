// ===== Dart 内置异常（JS 侧片段，随 flutter.js 发布）=====
//
// 翻译层把任何类构造统一发射为 `new X({...})`，Dart 内置异常
// （StateError / ArgumentError / FormatException / RangeError / …）在 JS 里没有
// 同名类，产物执行即为 ReferenceError、`throw` / `catch` 整段失效。这里按
// **同名类注入**补齐：都是普通 ES class（继承 JS `Error`），构造与 Dart 同形
// （props 形态，位置实参经 `__positionalArgs` 展开）。
//
// 归属 flutter.js（Dart 值 / 语言镜像区）：runtime.js 只做运行环境与 mini-react
// 核心，自身不构造任何异常；异常的消费方是产物代码（按名从 flutter.js import），
// 依赖方向因此只有 flutter.js → runtime.js。
//
// 不做类名白名单维护：新增异常类只需在此补一个 `export class`，翻译器与运行时
// 框架都不改动。
const String dartErrorsJsSource = r'''
  // Dart 异常共用基类：`message` 来自 props（位置实参按 names 展开），
  // `name` 取自身类名（StateError / ArgumentError / …），栈由 JS Error 提供。
  class DartError extends Error {
    constructor(props, positional) {
      props = __positionalArgs(props, positional);
      super(props.message == null ? '' : String(props.message));
      this.name = this.constructor.name;
    }

    // 命名构造 `X.value(value, [name, message])`：Dart 侧统一映射为静态方法。
    static value(props) {
      props = __positionalArgs(props, ['value', 'name', 'message']);
      var msg = props.message != null ? props.message : props.name;
      var err = new this({ message: msg });
      err.value = props.value;
      return err;
    }
  }

  export class StateError extends DartError {
    constructor(props) { super(props, ['message']); }
  }

  export class ArgumentError extends DartError {
    constructor(props) { super(props, ['message']); }
  }

  export class FormatException extends DartError {
    constructor(props) { super(props, ['message', 'source', 'offset']); }
  }

  export class RangeError extends DartError {
    constructor(props) { super(props, ['message']); }
  }

  export class UnsupportedError extends DartError {
    constructor(props) { super(props, ['message']); }
  }

  export class UnimplementedError extends DartError {
    constructor(props) { super(props, ['message']); }
  }

  export class Exception extends DartError {
    constructor(props) { super(props, ['message']); }
  }

  // `Error` 不导出：JS 原生 Error 就是 Dart Error 的落点（两者同名同义），
  // 导出同名类反而会遮蔽模块内的原生 Error。
''';
