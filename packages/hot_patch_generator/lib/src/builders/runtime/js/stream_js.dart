// ===== dart:async 的 Stream / StreamController / StreamSubscription 同名镜像 =====
//
// 产物按 Dart 写法原样发射，翻译层不认识这些类型名：
//   `StreamController<T>()`        → `new StreamController({typeArguments: …})`
//   `StreamController.broadcast()` → `new StreamController.broadcast({})`
//   `s.listen(onData, onError: e)` → `s.listen(onData, {onError: e})`
//   `async*` 方法 / 闭包            → `Stream.fromAsyncGenerator((async function* () {…}).bind(this)())`
//   `await for (final x in s)`     → `for await (const x of s)`
//
// 设计基线（手册第 14 章）：**显式事件 + 订阅状态机**，一条规则覆盖所有种类：
//
//   ┌ 事件缓冲 ┬ 单订阅：首个订阅前 → Stream 级 _pending；暂停 → 订阅者 _queue
//   │          └ 广播： 无订阅者丢弃 data/error（done 粘滞）；暂停 → 订阅者 _queue
//   ├ 背压     ┬ 单订阅：任一订阅者暂停 → 暂停拉取上游（Dart async* 的 yield 语义）
//   │          └ 广播：不传播暂停（事件进各订阅者队列）
//   ├ 取消     └ 最后一个订阅者 / 拉取者离开 → 取消上游并 await 其清理（break / take / 抛错）
//   └ 错误     └ 交付 onError 后，cancelOnError 独立生效（与是否提供 onError 无关）
//
// 转换方法（map / where / …）一律「订阅上游 + 转发事件」，不用 `for await` 循环：
// 一次 error 不会终止下游流，也不会遗留上游订阅。
const String streamJsSource = r'''
  export class Stream {
    constructor(opts) {
      opts = opts || {};
      this._broadcast = opts.broadcast === true;
      // 惰性事件源：返回 AsyncIterator 的函数（async* 产物）。null = 由
      // StreamController.add/addError/close 外部驱动。
      this._source = typeof opts.source === 'function' ? opts.source : null;
      this._onListen = typeof opts.onListen === 'function' ? opts.onListen : null;
      this._onCancel = typeof opts.onCancel === 'function' ? opts.onCancel : null;
      this._subs = new Set();
      this._pullers = new Set();
      // 单订阅：首个订阅者出现前的 data / error / done 都留在这里。
      this._pending = [];
      this._readyWaiters = [];
      this._done = false;
      this._started = false;
      this._stopped = false;
      this._closed = false;
      this._iterator = null;
      // 单订阅流**一生只能被订阅一次**（Dart 语义）：取消后再次 listen / await for
      // 必须抛 StateError，不能静默返回一个永远收不到事件的订阅。
      this._listenedOnce = false;
      this._asyncIterated = false;
      // close() 的 Future：等订阅者处理完 done 才完成（与 Dart 一致）。
      this._closeWaiters = [];
      this._closeDone = false;
      this._closePendingSubs = null;
    }

    get isBroadcast() { return this._broadcast; }

    get _hasListener() {
      return this._subs.size > 0 || this._pullers.size > 0 || this._asyncIterated;
    }

    // ---- 事件源驱动（async*）----

    _start() {
      if (this._started) return;
      this._started = true;
      if (this._onListen != null) {
        try { this._onListen(); } catch (e) { this._emit('error', e); }
      }
      if (this._source != null) this._pump();
    }

    async _pump() {
      try {
        var it = this._source();
        this._iterator = it;
        while (!this._stopped) {
          await this._waitDemand();
          if (this._stopped) { return; }
          var r = await it.next();
          if (r.done) { await this._emit('done'); return; }
          await this._emit('data', r.value);
        }
      } catch (e) {
        await this._emit('error', e, e instanceof Error ? e.stack : '');
        await this._emit('done');
      }
    }

    // 需求：单订阅要等订阅者可接收（未暂停）；拉取方要等它有等待中的 next。
    // 广播不传播暂停，只要有订阅者就继续拉。
    _hasDemand() {
      if (this._broadcast) return this._subs.size > 0;
      for (var sub of this._subs) {
        if (!sub._paused && !sub._cancelled) { return true; }
      }
      for (var p of this._pullers) {
        if (p.waiters.length > 0) { return true; }
      }
      return false;
    }

    _waitDemand() {
      if (this._stopped || this._hasDemand()) return Promise.resolve();
      var self = this;
      return new Promise(function (resolve) { self._readyWaiters.push(resolve); });
    }

    _wake() {
      var ws = this._readyWaiters;
      this._readyWaiters = [];
      for (var w of ws) { w(); }
    }

    // ---- 事件投递 ----

    // 与 Dart 一致：事件异步投递（微任务），add 调用栈内不触发回调。
    // done 的「终态」在 emit 时立即记下（close 后 add 抛错、done 后不再投递）。
    // 返回投递完成的 Promise：拉取源（_pump）要等这一项真正被消费后再拉下一项，
    // 否则「消费方 break」会晚于下一次拉取（上游多生产一项）。
    _emit(type, value, stack) {
      if (type === 'done') {
        if (this._done) { return Promise.resolve(); }
        this._done = true;
      } else if (this._done) {
        return Promise.resolve();
      }
      // error 的栈由**产生错误的一方**提供（与 Dart 一致）：`addError(e)` 不带
      // stackTrace 时是空栈；生成器 `throw` 时取 Error 自带的栈。JS 侧传栈
      // 字符串（不是 StackTrace 对象，见手册已知差异），空栈统一为 `''`。
      if (stack == null) { stack = ''; }
      var self = this;
      return Promise.resolve().then(function () {
        self._deliverEvent(type, value, stack);
      });
    }

    // 分发（唯一出口）：单订阅 / 广播 / 拉取方在这里统一处理缓冲与投递。
    _deliverEvent(type, value, stack) {
      if (this._subs.size === 0 && this._pullers.size === 0) {
        if (this._broadcast) { return; }   // 广播无订阅者：丢弃 data / error
        this._pending.push({ type: type, value: value, stack: stack });
        return;
      }
      for (var sub of Array.from(this._subs)) {
        sub._enqueue(type, value, stack);
      }
      if (this._pullers.size > 0) {
        var ev = { type: type, value: value };
        for (var p of Array.from(this._pullers)) {
          if (p.waiters.length > 0) { p.waiters.shift()(ev); } else { p.queue.push(ev); }
        }
      }
    }

    // ---- 生命周期 ----

    _cleanupIfIdle() {
      if (this._subs.size > 0 || this._pullers.size > 0) {
        this._wake();
        return Promise.resolve();
      }
      var self = this;
      return this._cancelSource().then(function () {
        self._tryResolveClose();
        if (self._broadcast) {
          // 广播：订阅者归零后允许再次订阅（onListen / onCancel 按转换次数成对调用）。
          self._stopped = false;
          self._started = false;
        }
      });
    }

    _cancelSource() {
      if (this._stopped) { return Promise.resolve(); }
      this._stopped = true;
      this._wake();
      var self = this;
      var cleanup = Promise.resolve();
      var it = this._iterator;
      this._iterator = null;
      if (it != null && typeof it.return === 'function') {
        cleanup = (async function () {
          try { await it.return(); } catch (e) {}
        })();
      }
      return cleanup.then(function () {
        if (self._onCancel != null) {
          var f = self._onCancel;
          self._onCancel = null;
          f();
        }
      });
    }

    listen(onData, opts) {
      opts = opts || {};
      if (!this._broadcast && this._listenedOnce) {
        throw new StateError({ message: 'Stream has already been listened to' });
      }
      this._listenedOnce = true;
      var sub = new StreamSubscription(this, onData,
          typeof opts.onError === 'function' ? opts.onError : null,
          typeof opts.onDone === 'function' ? opts.onDone : null,
          opts.cancelOnError === true);
      this._subs.add(sub);
      if (this._pending.length > 0) {
        // 单订阅：把首个订阅前缓冲的事件按序交给该订阅者。
        var buffered = this._pending;
        this._pending = [];
        for (var ev of buffered) { sub._enqueue(ev.type, ev.value, ev.stack); }
      } else if (this._done && this._broadcast) {
        // 广播：close 之后订阅仍会收到 done（data 已丢弃）。
        sub._enqueue('done', undefined);
      }
      if (this._closePendingSubs != null) { this._closePendingSubs.add(sub); }
      this._start();
      return sub;
    }

    // ---- 拉取形态（await for）----

    [Symbol.asyncIterator]() {
      if (!this._broadcast && this._listenedOnce) {
        throw new StateError({ message: 'Stream has already been listened to' });
      }
      this._listenedOnce = true;
      this._asyncIterated = true;
      var self = this;
      var pull = { queue: [], waiters: [] };
      if (this._pending.length > 0) {
        pull.queue = this._pending;
        this._pending = [];
      }
      this._pullers.add(pull);
      this._start();
      return {
        next: function () {
          if (pull.queue.length) {
            var ev = pull.queue.shift();
            return Promise.resolve().then(function () { return self._settle(ev); });
          }
          if (self._done) { return Promise.resolve({ done: true, value: undefined }); }
          return new Promise(function (resolve) {
            pull.waiters.push(function (e) {
              resolve(Promise.resolve().then(function () { return self._settle(e); }));
            });
            self._wake();
          });
        },
        return: function () {
          self._pullers.delete(pull);
          // break / return / 抛错退出：传播取消并等待上游清理完成。
          return self._cleanupIfIdle().then(function () {
            return { done: true, value: undefined };
          });
        }
      };
    }

    _settle(ev) {
      if (ev.type === 'error') { throw ev.value; }
      if (ev.type === 'done') { return { done: true, value: undefined }; }
      return { done: false, value: ev.value };
    }

    // ---- 关闭 ----

    close() {
      if (!this._closed) {
        this._closed = true;
        if (this._subs.size > 0) { this._closePendingSubs = new Set(this._subs); }
        this._emit('done');
      }
      if (this._closeDone) { return Future.value(); }
      var self = this;
      return Future.__wrap(new Promise(function (resolve) {
        self._closeWaiters.push(resolve);
        self._tryResolveClose();
      }));
    }

    _onDoneDelivered(sub) {
      if (this._closePendingSubs != null) { this._closePendingSubs.delete(sub); }
      this._tryResolveClose();
    }

    _tryResolveClose() {
      if (this._closeDone || !this._closed) { return; }
      if (this._closePendingSubs != null) {
        if (this._closePendingSubs.size === 0) { this._finishClose(); }
        return;
      }
      // 关闭时没有订阅者：有未消费缓冲就等首个订阅者消费完 done；否则立即完成。
      if (this._pending.length === 0) { this._finishClose(); }
    }

    _finishClose() {
      this._closeDone = true;
      var ws = this._closeWaiters;
      this._closeWaiters = [];
      for (var w of ws) { w(); }
    }

    // ---- 转换：订阅上游 + 转发事件（error 不终止下游）----

    _forwardEach(onEach) {
      var self = this;
      var sub = null;
      var ctl = new StreamController({
        onListen: function () {
          if (sub != null) { return; }
          sub = self.listen(function (v) {
            if (ctl.isClosed) { return; }
            onEach(v, ctl);
          }, {
            onError: function (e) { if (!ctl.isClosed) { ctl.addError(e); } },
            onDone: function () { sub = null; if (!ctl.isClosed) { ctl.close(); } }
          });
        },
        onCancel: function () {
          if (sub != null) { sub.cancel(); sub = null; }
        }
      });
      return ctl.stream;
    }

    map(fn) {
      return this._forwardEach(function (v, ctl) { ctl.add(fn(v)); });
    }

    where(fn) {
      return this._forwardEach(function (v, ctl) { if (fn(v)) { ctl.add(v); } });
    }

    expand(fn) {
      return this._forwardEach(function (v, ctl) {
        for (var x of fn(v)) { ctl.add(x); }
      });
    }

    skip(n) {
      var seen = 0;
      return this._forwardEach(function (v, ctl) {
        seen += 1;
        if (seen > n) { ctl.add(v); }
      });
    }

    distinct() {
      var seen = [];
      return this._forwardEach(function (v, ctl) {
        if (seen.contains(v)) { return; }
        seen.push(v);
        ctl.add(v);
      });
    }

    take(n) {
      var self = this;
      var sub = null;
      var count = 0;
      var ctl = new StreamController({
        onListen: function () {
          if (n <= 0) { ctl.close(); return; }
          sub = self.listen(function (v) {
            ctl.add(v);
            count += 1;
            if (count >= n) {
              if (sub != null) { sub.cancel(); sub = null; }
              ctl.close();
            }
          }, {
            onError: function (e) { if (!ctl.isClosed) { ctl.addError(e); } },
            onDone: function () { sub = null; ctl.close(); }
          });
        },
        onCancel: function () { if (sub != null) { sub.cancel(); sub = null; } }
      });
      return ctl.stream;
    }

    // 串行等待：逐个 await，禁止 Promise.all 并行；error / done 照常转发。
    asyncMap(fn) {
      var self = this;
      var sub = null;
      var chain = Promise.resolve();
      var ctl = new StreamController({
        onListen: function () {
          if (sub != null) { return; }
          sub = self.listen(function (v) {
            chain = chain.then(function () { return fn(v); }).then(function (r) {
              if (!ctl.isClosed) { ctl.add(r); }
            }, function (e) { if (!ctl.isClosed) { ctl.addError(e); } });
          }, {
            onError: function (e) { if (!ctl.isClosed) { ctl.addError(e); } },
            onDone: function () {
              sub = null;
              chain.then(function () { if (!ctl.isClosed) { ctl.close(); } });
            }
          });
        },
        onCancel: function () { if (sub != null) { sub.cancel(); sub = null; } }
      });
      return ctl.stream;
    }

    asBroadcastStream() {
      var self = this;
      var sub = null;
      var ctl = new StreamController({
        broadcast: true,
        onListen: function () {
          if (sub != null) { return; }
          sub = self.listen(function (v) { ctl.add(v); }, {
            onError: function (e) { if (!ctl.isClosed) { ctl.addError(e); } },
            onDone: function () { sub = null; ctl.close(); }
          });
        },
        onCancel: function () {
          if (sub != null) { sub.cancel(); sub = null; }
        }
      });
      return ctl.stream;
    }

    pipe(dest) {
      this.listen(function (v) { dest.add(v); }, {
        onError: function (e) { if (dest.addError != null) { dest.addError(e); } },
        onDone: function () { dest.close(); }
      });
      return dest.stream;
    }

    // ---- 终止操作：返回 Future ----

    toList() {
      var out = [];
      return this._consume(function (v) { out.push(v); }).then(function () { return out; });
    }

    toSet() {
      var out = new Set();
      return this._consume(function (v) { out.add(v); }).then(function () { return out; });
    }

    get first() {
      var self = this;
      return Future.__wrap(new Promise(function (resolve, reject) {
        var sub = self.listen(function (v) {
          sub.cancel();
          resolve(v);
        }, {
          onError: function (e) { reject(e); },
          onDone: function () { reject(new StateError({ message: 'No element' })); },
          cancelOnError: true
        });
      }));
    }

    get last() {
      var lastValue = null;
      var seen = false;
      return this._consume(function (v) { lastValue = v; seen = true; }).then(function () {
        if (!seen) { throw new StateError({ message: 'No element' }); }
        return lastValue;
      });
    }

    get length() { return this.toList().then(function (l) { return l.length; }); }

    get isEmpty() { return this.toList().then(function (l) { return l.length === 0; }); }

    get isNotEmpty() { return this.toList().then(function (l) { return l.length > 0; }); }

    _consume(onValue) {
      var self = this;
      return Future.__wrap(new Promise(function (resolve, reject) {
        self.listen(function (v) { onValue(v); }, {
          onError: function (e) { reject(e); },
          onDone: function () { resolve(); },
          cancelOnError: true
        });
      }));
    }

    // ---- 静态工厂 ----

    static fromAsyncGenerator(gen) {
      return new Stream({ source: function () { return gen; } });
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
      return new Stream({
        source: function () {
          return (async function* () {
            while (!stopped) {
              await new Promise(function (r) { setTimeout(r, ms); });
              if (stopped) { return; }
              yield typeof computation === 'function' ? computation() : 0;
            }
          })();
        },
        onCancel: function () { stopped = true; }
      });
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
      // data / error / done 统一走一条队列：暂停期间全部缓冲，恢复后按序补发。
      this._queue = [];
      this._draining = false;
      this._cancelled = false;
      this._doneDelivered = false;
    }

    get isPaused() { return this._paused; }

    pause() {
      this._paused = true;
    }

    resume() {
      if (!this._paused) { return; }
      this._paused = false;
      this._drain();
      // 恢复接收 → 允许上游继续拉取（背压）。
      this._stream._wake();
    }

    cancel() {
      if (this._cancelled) { return Promise.resolve(); }
      this._cancelled = true;
      this._queue.length = 0;
      this._stream._subs.delete(this);
      return this._stream._cleanupIfIdle();
    }

    _enqueue(type, value, stack) {
      if (this._cancelled) { return; }
      this._queue.push({ type: type, value: value, stack: stack });
      this._drain();
    }

    _drain() {
      if (this._draining) { return; }
      this._draining = true;
      while (!this._paused && !this._cancelled && this._queue.length > 0) {
        var ev = this._queue.shift();
        this._deliver(ev.type, ev.value, ev.stack);
      }
      this._draining = false;
    }

    _deliver(type, value, stack) {
      if (type === 'data') {
        if (typeof this._onData === 'function') { this._onData(value); }
        return;
      }
      if (type === 'error') {
        if (typeof this._onError === 'function') {
          // Dart 的 onError 可声明 (error, stackTrace) 两个形参；单参处理器忽略第二参。
          this._onError(value, stack);
        } else {
          // Dart 把无 onError 的错误报为「未捕获错误」，绝不静默丢弃。
          var text = value instanceof Error ? String(value) : __str(value);
          __error('jsui: unhandled stream error: ' + text
            + (stack ? '\n' + stack : ''));
        }
        // Dart 语义：cancelOnError 与是否提供 onError 无关，交付后即取消。
        if (this._cancelOnError) { this.cancel(); }
        return;
      }
      // done：每个订阅只交付一次。
      if (this._doneDelivered) { return; }
      this._doneDelivered = true;
      if (typeof this._onDone === 'function') { this._onDone(); }
      this._stream._onDoneDelivered(this);
    }
  }

  export class StreamController {
    constructor(props) {
      props = props || {};
      this._closed = false;
      this.stream = new Stream({
        broadcast: props.broadcast === true,
        onListen: typeof props.onListen === 'function' ? props.onListen : null,
        onCancel: typeof props.onCancel === 'function' ? props.onCancel : null
      });
    }

    get isClosed() { return this._closed; }

    get hasListener() { return this.stream._hasListener; }

    add(value) {
      if (this._closed) { throw new StateError({ message: 'Cannot add event after closing' }); }
      this.stream._emit('data', value);
    }

    addError(error, stackTrace) {
      if (this._closed) { throw new StateError({ message: 'Cannot add event after closing' }); }
      this.stream._emit('error', error, stackTrace);
    }

    close() {
      if (this._closed) { return Future.value(); }
      this._closed = true;
      return this.stream.close();
    }

    static broadcast(props) {
      var opts = {};
      if (props != null) { for (var k in props) { opts[k] = props[k]; } }
      opts.broadcast = true;
      return new StreamController(opts);
    }
  }
''';
