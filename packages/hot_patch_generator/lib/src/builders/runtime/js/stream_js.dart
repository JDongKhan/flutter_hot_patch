// ===== dart:async 的 Stream / StreamController / StreamSubscription 同名镜像 =====
//
// 产物按 Dart 写法原样发射，翻译层不认识这些类型名：
//   `StreamController<T>()`          → `new StreamController({typeArguments: …})`
//   `StreamController.broadcast()`   → `new StreamController.broadcast({})`
//   `s.listen(onData, onError: e)`   → `s.listen(onData, {onError: e})`
//   `async*` 方法 / 闭包              → `Stream.fromAsyncGenerator((async function* () {…}).bind(this)())`
//   `await for (final x in s)`       → `for await (const x of s)`
//
// 设计基线（手册第 14 章）：推送 + 拉取双形态。内部把事件推给 `listen` 的订阅者，
// 同时把同一批事件放进每个 `[Symbol.asyncIterator]` 的队列，供 `for await` 消费；
// 单订阅流第二次订阅抛 StateError，广播流每个订阅者独立；pause 期间单订阅流缓冲，
// 广播流丢弃；错误不终止流（除 cancelOnError），await for 遇错则中断。
//
// `async*` 生成的流是惰性的：首次 listen / 迭代才启动内部异步生成器。
const String streamJsSource = r'''
  export class Stream {
    constructor(opts) {
      opts = opts || {};
      this._broadcast = opts.broadcast === true;
      this._gen = opts.gen || null;
      this._onStart = typeof opts.onStart === 'function' ? opts.onStart : null;
      this._onCancel = typeof opts.onCancel === 'function' ? opts.onCancel : null;
      this._listeners = new Set();
      this._pulls = new Set();
      this._readyWaiters = [];
      this._done = false;
      this._started = false;
      this._stopped = false;
      this._asyncIterated = false;
      this._hasListener = false;
    }

    get isBroadcast() { return this._broadcast; }

    // 惰性启动：async* 产出的生成器在首次订阅 / 迭代时才开跑。
    //
    // 拉取式背压（与 Dart 的 async* 一致）：单订阅流被 pause 时不在 `yield`
    // 之后继续推进生成器，`_waitReady` 阻塞到 resume；订阅全部取消则停掉
    // 生成器（`it.return()` 让 Dart 侧 finally / 收尾逻辑照常执行）。
    // 广播流不传播 pause（Dart 语义），暂停的订阅者由 `_deliver` 丢弃事件。
    _start() {
      if (this._started) return;
      this._started = true;
      if (this._onStart != null) {
        try { this._onStart(); } catch (e) { this._emit('error', e); }
      }
      var gen = this._gen;
      if (gen == null) return;
      var self = this;
      (async function () {
        try {
          var it = gen[Symbol.asyncIterator]();
          while (true) {
            await self._waitReady();
            if (self._stopped) {
              if (typeof it.return === 'function') {
                try { await it.return(); } catch (ignored) {}
              }
              return;
            }
            var r = await it.next();
            if (r.done) { self._emit('done'); return; }
            self._emit('data', r.value);
          }
        } catch (e) {
          self._emit('error', e);
          self._emit('done');
        }
      })();
    }

    /// 有单订阅订阅者处于 pause 时返回一个挂起的 Promise，resume / cancel 时唤醒。
    _waitReady() {
      var self = this;
      if (self._stopped || self._broadcast) return Promise.resolve();
      for (var sub of self._listeners) {
        if (sub._paused && !sub._cancelled) {
          return new Promise(function (resolve) { self._readyWaiters.push(resolve); });
        }
      }
      return Promise.resolve();
    }

    _wake() {
      var ws = this._readyWaiters;
      this._readyWaiters = [];
      for (var w of ws) w();
    }

    // 与 Dart 一致：控制器 add 的事件异步投递（微任务），订阅者不能在 add
    // 调用栈内收到回调。async* 生成器本身已异步，补一次微任务不改变时序。
    // 同一订阅者的 error / done 必须排在已排队的 data 之后（_deliver 内再排队）。
    _emit(type, value) {
      var self = this;
      Promise.resolve().then(function () { self._deliverNow(type, value); });
    }

    _deliverNow(type, value) {
      if (type === 'done') {
        this._done = true;
        // 队列里可能还有未消费的 data：done 追加在队尾（不能清空，否则
        // `add(1); add(2); close()` 的 await for 会丢掉最后一个值）。
        for (var p of this._pulls) {
          if (p.waiters.length) {
            while (p.waiters.length) p.waiters.shift()({ type: 'done', value: undefined });
          } else {
            p.queue.push({ type: 'done', value: undefined });
          }
        }
        for (var sub of Array.from(this._listeners)) sub._deliver('done', undefined);
        return;
      }
      for (var sub of Array.from(this._listeners)) sub._deliver(type, value);
      for (var p of this._pulls) {
        var ev = { type: type, value: value };
        if (p.waiters.length) p.waiters.shift()(ev); else p.queue.push(ev);
      }
    }

    _settle(ev) {
      if (ev.type === 'error') throw ev.value;
      if (ev.type === 'done') return { done: true, value: undefined };
      return { done: false, value: ev.value };
    }

    _cancelSource() {
      this._stopped = true;
      this._wake();
      if (this._onCancel != null) {
        var f = this._onCancel;
        this._onCancel = null;
        f();
      }
    }

    listen(onData, opts) {
      opts = opts || {};
      if (!this._broadcast && (this._hasListener || this._asyncIterated)) {
        throw new StateError({ message: 'Stream has already been listened to' });
      }
      this._hasListener = true;
      var sub = new StreamSubscription(this, onData,
          typeof opts.onError === 'function' ? opts.onError : null,
          typeof opts.onDone === 'function' ? opts.onDone : null,
          opts.cancelOnError === true);
      this._listeners.add(sub);
      if (this._done) {
        sub._deliver('done', undefined);
      } else {
        this._start();
      }
      return sub;
    }

    [Symbol.asyncIterator]() {
      if (!this._broadcast && (this._hasListener || this._asyncIterated)) {
        throw new StateError({ message: 'Stream has already been listened to' });
      }
      this._asyncIterated = true;
      this._hasListener = true;
      var self = this;
      var pull = { queue: [], waiters: [] };
      this._pulls.add(pull);
      this._start();
      return {
        next: function () {
          if (pull.queue.length) {
            var ev = pull.queue.shift();
            return Promise.resolve().then(function () { return self._settle(ev); });
          }
          if (self._done) return Promise.resolve({ done: true, value: undefined });
          return new Promise(function (resolve) {
            pull.waiters.push(function (e) {
              resolve(Promise.resolve().then(function () { return self._settle(e); }));
            });
          });
        },
        return: function () {
          self._pulls.delete(pull);
          return Promise.resolve({ done: true, value: undefined });
        }
      };
    }

    // ---- 转换方法：新 Stream 在订阅时串行消费上游（保持惰性）----
    map(fn) {
      var self = this;
      return Stream.fromAsyncGenerator((async function* () {
        for await (var v of self) { yield fn(v); }
      })());
    }

    where(fn) {
      var self = this;
      return Stream.fromAsyncGenerator((async function* () {
        for await (var v of self) { if (fn(v)) yield v; }
      })());
    }

    expand(fn) {
      var self = this;
      return Stream.fromAsyncGenerator((async function* () {
        for await (var v of self) {
          for (var x of fn(v)) { yield x; }
        }
      })());
    }

    take(n) {
      var self = this;
      return Stream.fromAsyncGenerator((async function* () {
        if (n <= 0) return;
        var i = 0;
        for await (var v of self) {
          yield v;
          i += 1;
          if (i >= n) return;
        }
      })());
    }

    skip(n) {
      var self = this;
      return Stream.fromAsyncGenerator((async function* () {
        var i = 0;
        for await (var v of self) {
          if (i < n) { i += 1; continue; }
          yield v;
        }
      })());
    }

    distinct() {
      var self = this;
      return Stream.fromAsyncGenerator((async function* () {
        var seen = [];
        for await (var v of self) {
          if (seen.contains(v)) continue;
          seen.push(v);
          yield v;
        }
      })());
    }

    // 串行等待：禁止 Promise.all 并行（与 Dart asyncMap 一致）。
    asyncMap(fn) {
      var self = this;
      return Stream.fromAsyncGenerator((async function* () {
        for await (var v of self) { yield await fn(v); }
      })());
    }

    asBroadcastStream() {
      var self = this;
      var sub = null;
      var ctl = new StreamController({
        broadcast: true,
        onListen: function () {
          sub = self.listen(function (v) { ctl.add(v); }, {
            onError: function (e) { ctl.addError(e); },
            onDone: function () { ctl.close(); }
          });
        },
        onCancel: function () { if (sub != null) { sub.cancel(); } }
      });
      return ctl.stream;
    }

    pipe(dest) {
      this.listen(function (v) { dest.add(v); }, {
        onError: function (e) { if (dest.addError != null) dest.addError(e); },
        onDone: function () { dest.close(); }
      });
      return dest.stream;
    }

    // ---- 终止操作：返回 Future（Promise 包装）----
    toList() {
      var self = this;
      return Future.__wrap((async function () {
        var out = [];
        for await (var v of self) { out.push(v); }
        return out;
      })());
    }

    get first() {
      var self = this;
      return Future.__wrap(new Promise(function (resolve, reject) {
        var sub = self.listen(function (v) { sub.cancel(); resolve(v); }, {
          onError: function (e) { reject(e); },
          onDone: function () { reject(new StateError({ message: 'No element' })); }
        });
      }));
    }

    get last() {
      return this.toList().then(function (l) {
        if (l.length === 0) throw new StateError({ message: 'No element' });
        return l[l.length - 1];
      });
    }

    get length() {
      return this.toList().then(function (l) { return l.length; });
    }

    get isEmpty() {
      return this.toList().then(function (l) { return l.length === 0; });
    }

    get isNotEmpty() {
      return this.toList().then(function (l) { return l.length > 0; });
    }

    toSet() {
      var self = this;
      return Future.__wrap((async function () {
        var out = new Set();
        for await (var v of self) { out.add(v); }
        return out;
      })());
    }

    // ---- 静态工厂 / async* 包装入口 ----
    // `async*` 方法 / 闭包统一经这里包装，保留惰性（首次订阅才启动生成器）。
    static fromAsyncGenerator(gen) {
      return new Stream({ gen: gen });
    }

    static value(v) {
      return Stream.fromAsyncGenerator((async function* () { yield v; })());
    }

    static empty() {
      return Stream.fromAsyncGenerator((async function* () {})());
    }

    static error(error) {
      return Stream.fromAsyncGenerator((async function* () { throw error; })());
    }

    static fromFuture(future) {
      return Stream.fromAsyncGenerator((async function* () { yield await future; })());
    }

    static fromIterable(iterable) {
      return Stream.fromAsyncGenerator((async function* () {
        for (var v of iterable) { yield v; }
      })());
    }

    static periodic(duration, computation) {
      var ms = __durationMs(duration);
      if (ms == null || ms < 0) { ms = 0; }
      var stopped = false;
      var s = Stream.fromAsyncGenerator((async function* () {
        while (!stopped) {
          await new Promise(function (r) { setTimeout(r, ms); });
          if (stopped) { return; }
          yield typeof computation === 'function' ? computation() : 0;
        }
      })());
      s._onCancel = function () { stopped = true; };
      return s;
    }
  }

  export class StreamSubscription {
    constructor(stream, onData, onError, onDone, cancelOnError) {
      this._stream = stream;
      this._onData = onData;
      this._onError = onError;
      this._onDone = onDone;
      this._cancelOnError = cancelOnError === true;
      this._paused = false;
      this._buffer = [];
      this._cancelled = false;
      this._doneDelivered = false;
    }

    get isPaused() { return this._paused; }

    pause() { this._paused = true; }

    resume() {
      if (!this._paused) return;
      this._paused = false;
      // 先补发暂停期间缓冲的事件，再唤醒上游生成器（保持事件顺序）。
      while (!this._paused && this._buffer.length) {
        var ev = this._buffer.shift();
        this._deliverNow(ev.type, ev.value);
      }
      this._stream._wake();
    }

    cancel() {
      this._cancelled = true;
      this._stream._listeners.delete(this);
      if (this._stream._listeners.size === 0 && this._stream._pulls.size === 0) {
        this._stream._cancelSource();
      } else {
        this._stream._wake();
      }
      return Promise.resolve();
    }

    _deliver(type, value) {
      if (this._cancelled) return;
      if (this._paused) {
        // 单订阅：缓冲事件；广播：按 Dart 语义直接丢弃 data（错误仍上报）。
        if (this._stream._broadcast) {
          if (type === 'error') { this._deliverNow(type, value); }
          return;
        }
        this._buffer.push({ type: type, value: value });
        return;
      }
      this._deliverNow(type, value);
    }

    _deliverNow(type, value) {
      if (type === 'data') {
        if (typeof this._onData === 'function') { this._onData(value); }
      } else if (type === 'error') {
        if (typeof this._onError === 'function') {
          this._onError(value);
        } else if (this._cancelOnError) {
          this.cancel();
        }
      } else if (type === 'done') {
        if (this._doneDelivered) return;
        this._doneDelivered = true;
        if (typeof this._onDone === 'function') { this._onDone(); }
      }
    }
  }

  export class StreamController {
    constructor(props) {
      props = props || {};
      this._closed = false;
      this.stream = new Stream({
        broadcast: props.broadcast === true,
        onStart: typeof props.onListen === 'function' ? props.onListen : null,
        onCancel: typeof props.onCancel === 'function' ? props.onCancel : null
      });
    }

    get isClosed() { return this._closed; }

    get hasListener() { return this.stream._hasListener; }

    add(value) {
      if (this._closed) throw new StateError({ message: 'Cannot add event after closing' });
      this.stream._emit('data', value);
    }

    addError(error) {
      if (this._closed) throw new StateError({ message: 'Cannot add event after closing' });
      this.stream._emit('error', error);
    }

    close() {
      if (!this._closed) {
        this._closed = true;
        this.stream._emit('done');
      }
      return Future.value();
    }

    // `StreamController.broadcast({onListen, onCancel})`：产物按命名构造发射
    // `new StreamController.broadcast({...})`；构造函数返回对象即生效。
    static broadcast(props) {
      var opts = {};
      if (props != null) { for (var k in props) { opts[k] = props[k]; } }
      opts.broadcast = true;
      return new StreamController(opts);
    }
  }
''';
