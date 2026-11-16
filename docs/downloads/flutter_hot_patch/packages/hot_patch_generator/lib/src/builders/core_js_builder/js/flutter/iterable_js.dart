// ===== Dart `Iterable` 的惰性载体（map / where / expand / take / skip）=====
//
// Dart 的 `Iterable.map` / `where` / `expand` / `take` / `skip` 都是**惰性**的：
// 调用时不执行回调，直到真正迭代（toList / for-in / first / length …）。JS 的
// `Array.prototype.map` / `filter` 立即求值，语义不同。
//
// 调用点**保持同名**：`where` / `expand` / `take` / `skip` 由 Array / Set /
// 生成器原型上的同名成员直接返回 [LazyIterable]；只有 `map` 因为不能覆盖原生
// `Array.prototype.map`，由生成器按映射表改名为 `_map`（与 `_sort` / `_join`
// 同一规则）。`__iter*` 是这些原型实现共用的内部原语，不直接出现在产物里。
//
// [LazyIterable] 每次 `[Symbol.iterator]()` 都新建迭代器，因此**可重复迭代**
// （Dart Iterable 可重复消费；裸 JS 生成器不行）。
//
// 不覆盖原生 Array.prototype：运行时自身与用户 JS 仍用原生立即求值方法。
const String iterableJsSource = r'''
  class LazyIterable {
    constructor(factory) {
      this._factory = factory;
    }

    [Symbol.iterator]() {
      return this._factory();
    }

    // ---- 惰性变换：返回新的 LazyIterable，调用时零副作用 ----

    map(fn) {
      var self = this;
      return new LazyIterable(function* () {
        for (var v of self) { yield fn(v); }
      });
    }

    // 生成器对可判定为 List / Iterable 的接收者把 `map` 改名为 `_map`。
    _map(fn) { return this.map(fn); }

    where(fn) {
      var self = this;
      return new LazyIterable(function* () {
        for (var v of self) { if (fn(v)) { yield v; } }
      });
    }

    expand(fn) {
      var self = this;
      return new LazyIterable(function* () {
        for (var v of self) {
          for (var x of fn(v)) { yield x; }
        }
      });
    }

    take(n) {
      if (n < 0) { throw new RangeError('RangeError: count must not be negative'); }
      var self = this;
      return new LazyIterable(function* () {
        if (n === 0) { return; }
        var seen = 0;
        for (var v of self) {
          yield v;
          seen += 1;
          if (seen >= n) { return; }
        }
      });
    }

    skip(n) {
      if (n < 0) { throw new RangeError('RangeError: count must not be negative'); }
      var self = this;
      return new LazyIterable(function* () {
        var seen = 0;
        for (var v of self) {
          if (seen < n) { seen += 1; continue; }
          yield v;
        }
      });
    }

    // ---- 终止操作：消费一次（Dart 同名同义）----

    toList() { return Array.from(this); }

    toSet() { return new Set(this); }

    forEach(fn) {
      for (var v of this) { fn(v); }
    }

    fold(init, fn) {
      var acc = init;
      for (var v of this) { acc = fn(acc, v); }
      return acc;
    }

    any(fn) {
      for (var v of this) { if (fn(v)) { return true; } }
      return false;
    }

    every(fn) {
      for (var v of this) { if (!fn(v)) { return false; } }
      return true;
    }

    join(separator) { return Array.from(this)._join(separator); }

    contains(value) { return Array.from(this).contains(value); }

    indexOf(value, start) { return Array.from(this)._indexOf(value, start); }

    get first() {
      for (var v of this) { return v; }
      throw new StateError({ message: 'No element' });
    }

    get last() {
      var seen = false;
      var result = null;
      for (var v of this) { result = v; seen = true; }
      if (!seen) { throw new StateError({ message: 'No element' }); }
      return result;
    }

    get length() {
      var n = 0;
      for (var _ of this) { n += 1; }
      return n;
    }

    get isEmpty() {
      for (var _ of this) { return false; }
      return true;
    }

    get isNotEmpty() {
      for (var _ of this) { return true; }
      return false;
    }

    elementAt(index) {
      if (index < 0) { throw new RangeError('RangeError: Index out of range'); }
      var i = 0;
      for (var v of this) {
        if (i === index) { return v; }
        i += 1;
      }
      throw new RangeError('RangeError: Index out of range');
    }
  }

  // ---- 生成器发射的运行时原语（与 __nn / __mod 同口径，挂在全局）----
  function __iterMap(src, fn) {
    return new LazyIterable(function* () {
      for (var v of src) { yield fn(v); }
    });
  }

  function __iterWhere(src, fn) {
    return new LazyIterable(function* () {
      for (var v of src) { if (fn(v)) { yield v; } }
    });
  }

  function __iterExpand(src, fn) {
    return new LazyIterable(function* () {
      for (var v of src) {
        for (var x of fn(v)) { yield x; }
      }
    });
  }

  function __iterTake(src, n) {
    if (n < 0) { throw new RangeError('RangeError: count must not be negative'); }
    return new LazyIterable(function* () {
      if (n === 0) { return; }
      var seen = 0;
      for (var v of src) {
        yield v;
        seen += 1;
        if (seen >= n) { return; }
      }
    });
  }

  function __iterSkip(src, n) {
    if (n < 0) { throw new RangeError('RangeError: count must not be negative'); }
    return new LazyIterable(function* () {
      var seen = 0;
      for (var v of src) {
        if (seen < n) { seen += 1; continue; }
        yield v;
      }
    });
  }

  G.__iterMap = __iterMap;
  G.__iterWhere = __iterWhere;
  G.__iterExpand = __iterExpand;
  G.__iterTake = __iterTake;
  G.__iterSkip = __iterSkip;
''';
