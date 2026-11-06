// ===== dart:async 的 Future 同名镜像（JS 侧片段，随 flutter.js 发布）=====
//
// 产物的构造翻译是 1:1 原样发射，翻译层不认识 `Future` 这个类名：
//   `Future(() => x)`                           → `new Future({computation: () => x})`
//   `Future.delayed(const Duration(seconds: 1))` → `Future.delayed({duration: new Duration({seconds: 1})})`
//   `Future.value(x)`                           → `Future.value({value: x})`
//   `Future.wait([...])`                        → `Future.wait([...])`
// 因此这里不引入任何产物协议，只补 Dart SDK 的 `Future`：内部持有一个原生
// Promise，`await` / `then` / `catchError` 按 Dart 语义转发；`Future.delayed`
// 与 Timer 同口径用一次性 setTimeout（引擎（flutter_js / QuickJS）只提供
// setTimeout，没有其它定时设施）。
//
// 以后 Dart 侧新增同类异步语义，只需在本文件补一个同名静态方法，翻译器与
// 运行时框架都不动。
const String futureJsSource = r'''
  export class Future {
    constructor(props) {
      props = __positionalArgs(props, ['computation']);
      // Dart 的 `Future(computation)` 是**异步**启动（内部走 Timer.run），
      // 这里等价用一次性 setTimeout。
      this.__promise = Future.__run(props.computation, false);
    }

    // 计算体执行：异常一律转成 rejection（与 Dart 一致）。
    static __run(computation, sync) {
      return new Promise(function (resolve, reject) {
        var run = function () {
          try {
            resolve(typeof computation === 'function' ? computation() : null);
          } catch (e) {
            reject(e);
          }
        };
        if (sync) { run(); } else { setTimeout(run, 0); }
      });
    }

    // 原生 Promise → Future（不重复包装已有实例）。
    static __wrap(promise) {
      var f = Object.create(Future.prototype);
      f.__promise = promise;
      return f;
    }

    // 原生 Promise 会自动解包 thenable（onValue 返回 Future 时等待其完成），
    // 与 Dart `then` 的扁平化语义一致。第二个参数兼容两种形态：
    //   - `await` 内部调用 `then(resolve, reject)`（裸函数）；
    //   - Dart 具名实参 `then(onValue, onError: …)` 的尾参对象 `{onError}`。
    then(onValue, onError) {
      var handler = typeof onError === 'function' ? onError
        : ((onError && typeof onError.onError === 'function') ? onError.onError : null);
      return Future.__wrap(this.__promise.then(onValue, handler));
    }

    catchError(onError, opts) {
      var test = opts && typeof opts.test === 'function' ? opts.test : null;
      return Future.__wrap(this.__promise.catch(function (e) {
        // Dart 语义：test 为假时异常原样继续向后抛。
        if (test != null && !test(e)) { throw e; }
        return typeof onError === 'function' ? onError(e, null) : e;
      }));
    }

    whenComplete(action) {
      var call = function () {
        return typeof action === 'function' ? action() : null;
      };
      return Future.__wrap(this.__promise.then(
        function (v) { return Promise.resolve(call()).then(function () { return v; }); },
        function (e) { return Promise.resolve(call()).then(function () { throw e; }); }));
    }

    toString() { return 'Instance of Future'; }

    // `Future.delayed(duration, [computation])`：构造签名表把位置实参映射成
    // `{duration, computation}`；签名查不到时落 `__pos`，由 __positionalArgs 展开。
    static delayed(props, second) {
      var duration = null;
      var computation = null;
      if (props && typeof props.inMilliseconds === 'number') {
        duration = props;
        computation = second;
      } else {
        var opts = __positionalArgs(props, ['duration', 'computation']);
        duration = opts.duration;
        computation = opts.computation;
      }
      var ms = __durationMs(duration);
      if (ms == null || ms < 0) { ms = 0; }
      return Future.__wrap(new Promise(function (resolve, reject) {
        setTimeout(function () {
          try {
            resolve(typeof computation === 'function' ? computation() : null);
          } catch (e) {
            reject(e);
          }
        }, ms);
      }));
    }

    // `Future.value([value])`
    static value(props) {
      props = __positionalArgs(props, ['value']);
      return Future.__wrap(Promise.resolve(props.value));
    }

    // `Future.error(error, [stackTrace])`：JS 无独立栈传递，异常本身已带栈。
    static error(props) {
      props = __positionalArgs(props, ['error', 'stackTrace']);
      return Future.__wrap(Promise.reject(props.error));
    }

    // `Future.sync(computation)`：与构造的唯一差别是**同步**启动计算体。
    static sync(props) {
      props = __positionalArgs(props, ['computation']);
      var computation = props.computation;
      try {
        return Future.__wrap(Promise.resolve(
          typeof computation === 'function' ? computation() : null));
      } catch (e) {
        return Future.__wrap(Promise.reject(e));
      }
    }

    // `Future.microtask(computation)`：微任务启动（比 setTimeout 更早）。
    static microtask(props) {
      props = __positionalArgs(props, ['computation']);
      var computation = props.computation;
      return Future.__wrap(Promise.resolve().then(function () {
        return typeof computation === 'function' ? computation() : null;
      }));
    }

    // `Future.wait(futures, {eagerError, cleanUp})`：静态方法，位置实参 + 尾参对象。
    static wait(futures, opts) {
      var list = Array.from(futures || []);
      var eager = opts && opts.eagerError === true;
      var cleanUp = opts && typeof opts.cleanUp === 'function' ? opts.cleanUp : null;
      return Future.__wrap(new Promise(function (resolve, reject) {
        var results = [];
        var remaining = list.length;
        var error = null;
        if (remaining === 0) { resolve(results); return; }
        list.forEach(function (item, index) {
          Promise.resolve(item).then(function (value) {
            results[index] = value;
            remaining -= 1;
            if (remaining === 0 && error === null) { resolve(results); }
          }, function (e) {
            if (cleanUp != null) {
              try { cleanUp(results[index]); } catch (ignored) {}
            }
            if (error === null) { error = e; }
            remaining -= 1;
            // eagerError：首个异常立即报告；否则等全部完成再报告。
            if (eager || remaining === 0) { reject(error); }
          });
        });
      }));
    }

    // `Future.any(futures)`：首个完成者胜出；全部失败则以异常列表结束。
    static any(futures) {
      var list = Array.from(futures || []);
      return Future.__wrap(new Promise(function (resolve, reject) {
        var errors = [];
        var remaining = list.length;
        if (remaining === 0) {
          reject(new StateError({ message: 'No futures to wait for' }));
          return;
        }
        list.forEach(function (item, index) {
          Promise.resolve(item).then(resolve, function (e) {
            errors[index] = e;
            remaining -= 1;
            if (remaining === 0) { reject(errors); }
          });
        });
      }));
    }
  }

  // `Completer<T>()`：与 Future 配套的手动完成器。`future` 是 Future 实例
  // （`await` / `then` 走同一套 `__wrap`）；`complete` / `completeError` 只允许
  // 调用一次，重复完成按 Dart 语义抛 StateError。
  export class Completer {
    constructor(props) {
      var self = this;
      this.__completed = false;
      this.future = Future.__wrap(new Promise(function (resolve, reject) {
        self.__resolve = resolve;
        self.__reject = reject;
      }));
    }

    get isCompleted() { return this.__completed; }

    complete(value) {
      if (this.__completed) {
        throw new StateError({ message: 'Future already completed' });
      }
      this.__completed = true;
      this.__resolve(value);
    }

    completeError(error, stackTrace) {
      if (this.__completed) {
        throw new StateError({ message: 'Future already completed' });
      }
      this.__completed = true;
      this.__reject(error);
    }
  }
''';
