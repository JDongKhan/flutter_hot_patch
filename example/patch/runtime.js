
// ===== 【1】运行环境｜IIFE 入口 + 全局对象 + 日志全局（版本 cf325a05） =====

(function () {
  var G = typeof globalThis !== 'undefined'
    ? globalThis
    : Function('return this')();
  if (G.__jsui && G.__jsuiVersion === 'cf325a05') { return; }
  G.__jsuiVersion = 'cf325a05';


if (typeof G.__modules === 'undefined') {
  G.__modules = {};
}
// 编译/运行期标志（kDebugMode / kReleaseMode / Platform）**由宿主在求值本
// 文件之前注入**（见 JsRuntimeManager._jsUiEnvSource）：这些值取决于 App 的
// 编译模式与目标平台，构建期（build_runner）无从得知，故不写进产物。
// 产物与 Dart 一比一：kDebugMode / kReleaseMode / Platform.isAndroid 原样
// 保留（见生成器 globalFlagJs / platformFlagJs），运行时注入同名对象。
// 值 → 字符串（对象/数组完整展开，循环引用安全）：JS 侧 `String(obj)` 只会
// 得到 `[object Object]`，日志里看不到任何字段。`__formatValue` 递归展开 own
// 字段，函数标成 `[Function name]`、循环引用标成 `[Circular]`（与 JSON.stringify
// 不同：不会因循环引用直接抛错，也不丢函数字段）。
// 日志全局 `print` / `debugPrint` 用它展开实参；JS 值类（StringBuffer）经
// `__core.str` 取同一份实现，跨模块只走 G.__core。
function __formatValue(v, stack) {
  if (typeof v === 'string') return v;
  if (v === null) return 'null';
  if (typeof v === 'undefined') return 'undefined';
  var t = typeof v;
  if (t === 'function') return '[Function ' + (v.name || 'anonymous') + ']';
  if (t !== 'object') return String(v);
  // Error 的 message / name 是原型上的非枚举属性，直接按 own keys 展开只会得到
  // `{}`——异常日志必须可读，故单独按 name + message 输出。
  if (v instanceof Error) {
    return (v.name || 'Error') + (v.message ? ': ' + v.message : '');
  }
  if (stack.indexOf(v) >= 0) return '[Circular]';
  var next = stack.concat([v]);
  if (Array.isArray(v)) {
    var items = [];
    for (var i = 0; i < v.length; i++) { items.push(__formatValue(v[i], next)); }
    return '[' + items.join(', ') + ']';
  }
  var keys = Object.keys(v);
  var out = [];
  for (var j = 0; j < keys.length; j++) {
    out.push(keys[j] + ': ' + __formatValue(v[keys[j]], next));
  }
  return '{' + out.join(', ') + '}';
}
function __str(v) { return __formatValue(v, []); }
// 日志唯一出口：桥到逻辑通道 'log'（宿主 log 处理器 → HotPatchLog）。
//
// **release 下关闭、零跨桥**：kDebugMode 为 false 时直接返回 —— 一次日志的
// 代价是「格式化 + JSON 编码 + 桥消息 + Promise」，线上既看不到也担不起；
// 需要线上诊断请走显式上报通道，不要指望 print。
//
// 出口统一走 `_app_host_.invoke`（唯一 JS→宿主入口）；宿主 'log' 处理器始终
// 已注册，故 Promise 一定被回填、不会悬挂。`_app_host_` 在本 IIFE 收尾（【25】）
// 赋值，而日志只可能由页面代码触发——那时它必然已存在，无需探测。
//
// 级别：Dart `print` → info、`debugPrint` → debug；框架内部诊断用 warn / error
// （宿主侧同样按级别归类，见 builtin_host_methods.dart 的 _log）。
function __logText(level, text) {
  if (!G.kDebugMode) { return; }
  G._app_host_.invoke('log', [level, String(text)]);
}
// 框架内部诊断（只在 debug 下出声，release 零开销）。
function __warn(text) { __logText('warn', text); }
function __error(text) { __logText('error', text); }
// 多个实参 → 一行（与 Dart print 的空格分隔语义一致）。
function __argsText(args) {
  var text = '';
  for (var i = 0; i < args.length; i++) {
    text += (i ? ' ' : '') + __formatValue(args[i], []);
  }
  return text;
}
G.print = function (message) { __logText('info', __argsText([message])); };
// debugPrint 的 Dart 签名是 `debugPrint(String? message, {int? wrapWidth})`：
// 混合调用由生成器按「运行时全局函数」的统一信封传入
// `{ "@args": [message], "wrapWidth": … }`，这里取出位置实参（wrapWidth 只
// 影响原生逐行折行，JS 侧无对应物，忽略）。
G.debugPrint = function (message) {
  if (message !== null && typeof message === 'object' && message['@args']) {
    message = message['@args'][0];
  }
  __logText('debug', __formatValue(message, []));
};
// 空值归一（Dart 只有 null，JS 有 null 与 undefined）：`__nn(v)` 把 undefined
// 归一为 null，其它值（含 null）原样返回——**只归一，不抛错**。生成器在判空 /
// 相等比较处先包一层（`__nn(x) == null`），保证下游只看到 null。
if (typeof G.__nn !== 'function') {
  G.__nn = function (v) { return v === undefined ? null : v; };
}
// Dart `%` 是欧几里得取模：结果非负（`-7 % 3 == 2`，`7 % -3 == 1`）。
// JS `%` 是截断余数（`-7 % 3 == -1`），故统一走这里。
if (typeof G.__mod !== 'function') {
  G.__mod = function (a, b) {
    var r = a % b;
    return r < 0 ? r + Math.abs(b) : r;
  };
}

  var __idSeq = 0;
  var __HOST = 1, __COMP = 2;

  // pageKey -> { key, inst, dirty, flushing, flushPending, mounting, ops }
  var __roots = {};
  // pageKey -> 句柄 id[]：本页面（scope=page）登记的全部跨语言句柄（控制器 /
  // 函数 / 未来的 Key / 对象…）。页面退出时由 __disposeRoot 统一释放——新增能力
  // 只要按句柄登记即自动获得页面回收，无需再改 __disposeRoot（见【4】句柄注册表）。
  var __pageHandles = {};
  // 正在 mount/patch/commit 的根；__emitOp / 结点归属都读它。
  var __activeRoot = null;
  // 正在构建的元素（build 执行期）——`context` 的锚点。`context.watch/read` 据此
  // 定位**作用域**（按类型名向上找，见【8】）并订阅（与 Dart 的 BuildContext
  // 语义一致：按**位置**而非「谁定义了这个方法」）。委托型组件（Builder/Consumer）
  // 把 builder 方法以 owner 为 this 调用时，锚点仍是它们自身的结点。
  var __building = null;

  // id 统一规则：`<端>:<种类>/<子类>#<序号>`（子类可省），序号全局单调仅用于
  // 唯一化。带前缀是为了让宿主侧 ValueKey / Flutter DevTools 一眼看出 id 的
  // 归属端（js/dt）与种类（node/comp/ctrl/fn/key…）——调试可读性。
  //   结点：js:node/<Type>#N（宿主结点）/ js:comp/<Name>#N（组件结点）
  //   句柄：js:ctrl/Scroll#N、js:fn#N、dt:key/Global#N（见【4】句柄注册表）
  function __nextNodeId(type) { __idSeq += 1; return 'js:node/' + type + '#' + __idSeq; }
  function __nextComponentId(type) { __idSeq += 1; return 'js:comp/' + __componentName(type) + '#' + __idSeq; }

  // __COMP 结点 id 用的类名：`class X {}` -> `X`（生成器产物均为具名类）。
  function __componentName(type) { return (type && type.name) || 'Component'; }

  // Dart 类型名 → JS 构造函数别名表（见【27.5】Dart extension 注册）。
  // 语言核心类型（int/String/List…）由 __extensionTargetOf 直接映射；运行时
  // 私有代理类（如 BuildContext）在这里登记别名——**不**挂到 G 上，避免为了
  // extension 把一个内部类暴露成全局。产物里的类无需登记：注册时既可直接传
  // 构造函数（跨产物 import 得到同一个类），也可按类型名走 `G[name]`。
  var __typeAliases = {};
  function __registerTypeAlias(name, ctor) { __typeAliases[name] = ctor; }

  // 【项目规则】凡是「翻译产物里调用的方法名，而在原生 JS 对应类型上不存在」的，
  // 一律**在本节给 JS 内建补一个同名同义的方法**，产物保持原样调用——不在生成器
  // 里做名字映射、也不改单源去绕开。
  // 为什么放在运行时而不是生成器：生成器不带类型解析，只看得到**方法名**，而
  // Dart 的方法名与别的类的同名方法经常撞车（`clear` 既是 `List.clear()`，也是
  // TextEditingController.clear()，见 capabilities/text_editing_controller/text_editing_controller_js.dart）。
  // 若在生成器里按名字映射成 `xs.length = 0`，控制器那次 clear 会被**静默改错**
  // （清不掉输入框、还平白多一个 length 属性）——比报错更难发现。补齐到具体的内建
  // 原型上则天然按**接收者类型**分发：挂 Array.prototype 只影响数组，别处同名方法
  // 分毫不动，且生成器零改动。
  // 新增补齐项的三个硬要求：
  //   1) 挂在**最具体的**内建原型上（如 Array.prototype），不得挂 Object.prototype；
  //   2) 定义成**不可枚举**（enumerable:false），否则会污染 for...in / Object.keys /
  //      JSON.stringify（序列化 props 时会凭空多出字段）；
  //   3) 带存在性守卫（`typeof X !== 'function'`），引擎/宿主自带时以自带为准，
  //      且可重复注入不覆盖（运行时可能被重新求值）。
  // 注意：本节属**运行时 Dart 代码**，改动随 App 一起注入——热更/热重启不生效，
  // 必须完全重启 App。
  // 补齐成员的声明形态统一为「目标原型 + 一张表」：表 key 是成员名，value 是
  // 方法体 / getter 函数。新增补齐项只往对应的表里加一行，不再一项一次调用
  // 散落各处；挂载与存在性守卫只由下面两个函数承担。
  //   - 方法表：同名成员不是函数才挂（引擎/宿主自带优先）。
  //   - getter 表：目标上没有同名自有属性才挂（Dart 属性写法按同名同义补齐）。
  function __defineProtoMember(proto, members) {
    for (var name in members) {
      if (!Object.prototype.hasOwnProperty.call(members, name)) { continue; }
      if (typeof proto[name] !== 'function') {
        Object.defineProperty(proto, name, {
          value: members[name],
          writable: true,
          enumerable: false,
          configurable: true
        });
      }
    }
  }
  function __defineProtoGetter(proto, members) {
    for (var name in members) {
      if (!Object.prototype.hasOwnProperty.call(members, name)) { continue; }
      if (!Object.getOwnPropertyDescriptor(proto, name)) {
        Object.defineProperty(proto, name, {
          get: members[name],
          enumerable: false,
          configurable: true
        });
      }
    }
  }
  //   - Array.prototype：数组在 JS 侧就是 List。`clear` 是 Dart `List.clear()`
  //     的**原地**清空（保持数组实例，故 `final` 列表也能清；返回 void）。
  //     「已知缺口（未补）：Dart `Map` 字面量在 JS 侧是**普通对象**（不是 Map
  //     实例），故 `Map.clear()` 无处可挂（挂 Object.prototype 影响面过大），
  //     需要时得按「字段类型是 Map」在翻译层分发；Dart `Set` 字面量翻成
  //     `new Set([...])`，JS Set 自带 clear()，无需处理。」
  //     Dart 同名成员（`first` / `where` / `add` / `removeAt` / `insert` /
  //     `toList` / `isEmpty` …）生成器不再按名字改写，原样产出，由本表按接收者
  //     类型补齐同名同义实现。
  __defineProtoMember(Array.prototype, {
    clear: function () { this.length = 0; },
    where: function (predicate) {
      return this.filter(predicate);
    },
    // Dart List.toList() 返回新列表；这里保持数组实例（与既有产物行为一致），
    // 后续链式调用 / 原地修改语义不变。
    toList: function () { return this; },
    add: function (value) {
      this.push(value);
    },
    removeAt: function (index) {
      return this.splice(index, 1)[0];
    },
    //   - List.remove(value) / removeLast() / removeWhere：Dart 侧极常用
    //     （`this._items.remove(item)`），缺一个，事件回调就会抛 TypeError，
    //     `setState` 的 mutator 半途中断、**界面不重建**（典型症状：Dismissible
    //     已滑走但条目仍在树上，触发 "dismissed ... still part of the tree"）。
    //     语义按 Dart：remove 删第一个 == value 的元素并返回是否删过。
    remove: function (value) {
      for (var i = 0; i < this.length; i++) {
        var el = this[i];
        if (el === value ||
            (el != null && typeof el.__op$eq === 'function' && el.__op$eq(value))) {
          this.splice(i, 1);
          return true;
        }
      }
      return false;
    },
    removeLast: function () {
      return this.pop();
    },
    removeWhere: function (predicate) {
      var removed = false;
      for (var i = this.length - 1; i >= 0; i--) {
        if (predicate(this[i])) { this.splice(i, 1); removed = true; }
      }
      return removed;
    },
    insert: function (index, value) {
      if (index < 0 || index > this.length) {
        throw new RangeError('RangeError: Index out of range');
      }
      this.splice(index, 0, value);
    },
    //   - Dart `List` 缺同名的成员（原生没有对应名字）：直接挂同名同义实现。
    //     `addAll` 用循环而不是 `push(...xs)`（大数组展开有实参上限）。
    addAll: function (values) {
      for (var v of values) { this.push(v); }
    },
    // Dart `contains` 用 `==`：先按 `===` 比，再尝试元素自带的 `__op$eq`
    // （声明了 `operator ==` 的自定义类由生成器改写成该成员）。
    contains: function (value) {
      for (var i = 0; i < this.length; i++) {
        var el = this[i];
        if (el === value) { return true; }
        if (el != null && typeof el.__op$eq === 'function' && el.__op$eq(value)) {
          return true;
        }
      }
      return false;
    },
    // Dart `fillRange(start, end, [value])`（参数顺序与原生 fill(value, start, end) 不同）。
    fillRange: function (start, end, value) {
      if (end === undefined || end == null) { end = this.length; }
      return this.fill(value === undefined ? null : value, start, end);
    },
    // Dart `sublist(start, [end])`：越界抛 RangeError（原生 slice 会静默裁剪）。
    sublist: function (start, end) {
      if (end === undefined || end == null) { end = this.length; }
      if (start < 0 || start > this.length || end < start || end > this.length) {
        throw new RangeError('RangeError: invalid sublist range');
      }
      return this.slice(start, end);
    },
    // Dart `firstWhere(test, {orElse})`：找不到时走 orElse，没有就抛 StateError。
    firstWhere: function (predicate, orElse) {
      for (var i = 0; i < this.length; i++) {
        if (predicate(this[i])) { return this[i]; }
      }
      var fallback = orElse;
      if (fallback && typeof fallback === 'object' && fallback.orElse) {
        fallback = fallback.orElse;
      }
      if (typeof fallback === 'function') { return fallback(); }
      throw new Error('StateError: No element');
    },
    // Dart `Iterable.expand(f)`：把每个元素展开成序列再串接（等价 flatMap）。
    expand: function (f) {
      var out = [];
      for (var i = 0; i < this.length; i++) {
        var part = f(this[i]);
        for (var x of part) { out.push(x); }
      }
      return out;
    },
    // Dart `fold(init, fn)`：初值在前、累加器在后（与原生 reduce 不同）。
    fold: function (init, fn) {
      var acc = init;
      for (var i = 0; i < this.length; i++) { acc = fn(acc, this[i]); }
      return acc;
    },
    // Dart `any(f)` ↔ 原生 `some`（`every` 原生同名同义）。
    any: function (f) { return this.some(f); },
    // Dart `take(n)` / `skip(n)`：负数抛 RangeError，越界按长度截断。
    take: function (n) {
      if (n < 0) { throw new RangeError('RangeError: count must not be negative'); }
      return this.slice(0, n < this.length ? n : this.length);
    },
    skip: function (n) {
      if (n < 0) { throw new RangeError('RangeError: count must not be negative'); }
      return this.slice(n < this.length ? n : this.length);
    },
    // Dart `asMap()`：索引 → 值的 Map（项目 Map 形态是普通对象）。
    asMap: function () {
      var m = {};
      for (var i = 0; i < this.length; i++) { m[i] = this[i]; }
      return m;
    },
    // Dart `elementAt(i)`：越界抛 RangeError（原生下标只会返回 undefined）。
    elementAt: function (index) {
      if (index < 0 || index >= this.length) {
        throw new RangeError('RangeError: Index out of range');
      }
      return this[index];
    },
    //   - 原生同名但语义不一致（不覆盖原生，挂下划线版本；生成器只对可判定为
    //     List 的接收者按映射表改写成 `_sort` / `_join` / `_setLength`）。
    //     `_sort()` 无比较器时按 Dart Comparable（数值 / 字符串 / 自带 compareTo）。
    _sort: function (compare) {
      if (typeof compare === 'function') { return this.sort(compare); }
      return this.sort(function (a, b) {
        if (a === b) { return 0; }
        if (a == null) { return -1; }
        if (b == null) { return 1; }
        if (typeof a.compareTo === 'function') { return a.compareTo(b); }
        return a < b ? -1 : (a > b ? 1 : 0);
      });
    },
    //     `_join()` 默认分隔符是空串（原生默认 `','`）。
    _join: function (separator) {
      return this.join(separator === undefined ? '' : separator);
    },
    //     `_setLength(n)`：Dart growable list 语义（截断 / 补 null），
    //     负数或非整数抛 RangeError（原生写 length 会静默截断 / 扩展）。
    _setLength: function (n) {
      if (typeof n !== 'number' || !Number.isInteger(n) || n < 0) {
        throw new RangeError('RangeError: Invalid list length');
      }
      if (n < this.length) { this.length = n; }
      while (this.length < n) { this.push(null); }
      return n;
    }
  });
  __defineProtoGetter(Array.prototype, {
    first: function () { return this[0]; },
    last: function () {
      return this[this.length - 1];
    },
    isEmpty: function () {
      return this.length === 0;
    },
    isNotEmpty: function () {
      return this.length > 0;
    },
    reversed: function () {
      return this.slice().reverse();
    }
  });
  __defineProtoGetter(String.prototype, {
    isEmpty: function () {
      return this.length === 0;
    },
    isNotEmpty: function () {
      return this.length > 0;
    },
    // Dart `String.hashCode`：JS 没有同名成员，按稳定散列补齐（FNV-1a 32 位，
    // 只用值语义一致性，不做安全用途；跨引擎结果相同）。
    hashCode: function () {
      var h = 2166136261;
      for (var i = 0; i < this.length; i++) {
        h ^= this.charCodeAt(i);
        h = (h * 16777619) >>> 0;
      }
      return h >>> 0;
    }
  });
  //   - int 的 `isEven` / `isOdd` 是 Dart 的属性（不是方法），JS 数字没有；
  //     生成器按 Dart 写法一比一产出 `n.isEven`，故按同名同义补 getter。
  //     `hashCode`：Dart 数字的 `hashCode` 是值本身（数字相等即散列相等）；
  //     自定义 `==` 的类常组合字段 `hashCode`，缺失会得到 undefined。
  __defineProtoGetter(Number.prototype, {
    isEven: function () {
      return this % 2 === 0;
    },
    isOdd: function () {
      return this % 2 !== 0;
    },
    hashCode: function () {
      return this.valueOf();
    }
  });
  var __compareTo = function (other) {
    return this < other ? -1 : (this > other ? 1 : 0);
  };
  __defineProtoMember(String.prototype, { compareTo: __compareTo });
  //   - Number.prototype：Dart `num` 的方法在 JS 里**没有同名成员**
  //     （`(x * 100).round()` 直接抛 "is not a function"，整个组件挂载失败、
  //     页面只显示加载失败占位）。生成器按 Dart 写法一比一产出，故在数字原型上
  //     按**同名同义**补齐（与 Dart 语义一致：truncate/toInt 向零取整，
  //     字符串化/取整返回新值不改变接收者）。
  __defineProtoMember(Number.prototype, {
    compareTo: __compareTo,
    round: function () { return Math.round(this); },
    floor: function () { return Math.floor(this); },
    ceil: function () { return Math.ceil(this); },
    abs: function () { return Math.abs(this); },
    truncate: function () { return Math.trunc(this); },
    toInt: function () { return Math.trunc(this); },
    toDouble: function () { return this; },
    toStringAsFixed: function (digits) { return this.toFixed(digits); },
    clamp: function (lo, hi) { return Math.min(Math.max(this, lo), hi); }
  });

  //   - G.assert：Dart `assert(condition, [message])` 的运行时补齐。
  //     生成器产物原样调用 `assert(cond, msg)`（一比一翻译），这里按 Dart 语义
  //     实现：只在 debug 模式校验，失败抛出 Error；message 支持字符串或返回
  //     字符串的函数（与 Dart assert 的第二参数形态一致）。
  if (typeof G.assert !== 'function') {
    G.assert = function (condition, message) {
      if (!G.kDebugMode) { return; }
      if (condition) { return; }
      var msg = (typeof message === 'function') ? message() : message;
      throw new Error(msg == null ? 'Assertion failed' : msg);
    };
  }


// ===== 【2】出方向桥（__emitOp / __commitOps） =====
  // 所有 JS→宿主消息都打到单桥通道 `_app_bridge_`，目标通道名放在消息体
  // `ch` 字段。宿主只订阅该桥通道一次，再按 ch 二次分发。
  // `__sendToHost` 是运行时**内部**的低层发送（不对外暴露）；对外的唯一入口是
  // `_app_host_.invoke`（见【3】），它等于 `__sendToHost` + Promise 回填。
  var __APP_BRIDGE = '_app_bridge_';
  function __sendToHost(channel, data) {
    if (typeof sendMessage !== 'function') { return; }
    sendMessage(__APP_BRIDGE, JSON.stringify({ ch: channel, data: data }));
  }

  function __emitOp(op) {
    if (__activeRoot && __activeRoot.ops) { __activeRoot.ops.push(op); }
  }
  function __commitOps(root) {
    var list = root.ops;
    root.ops = null;
    if (!list || !list.length) { return; }
    // 补丁按页面 key 路由到对应 JsUiStore（key 放进 args，宿主 handler 解析）。
    try {
      __sendToHost('jsuiCommit', { args: { key: root.key, ops: list } });
    } catch (e) {
      // 诊断：某条 op 的载荷带循环引用时 JSON.stringify 会整体抛错，这里逐条
      // 重试并报出**无法序列化的那一 op**（类型 + props 键名），便于定位是谁
      // 把实例/元素塞进了 props（元素带 `inst`，实例带 `__elCache`，互为环）。
      for (var di = 0; di < list.length; di++) {
        try {
          JSON.stringify(list[di]);
        } catch (e2) {
          var bad = list[di];
          var ks = [];
          var bp = bad.props || {};
          for (var bk in bp) { ks.push(bk + ':' + typeof bp[bk]); }
          __error('jsui: op not serializable #' + di + ' op=' + bad.op +
            ' type=' + bad.type + ' id=' + bad.id +
            ' keys=[' + ks.join(',') + ']: ' + e2);
        }
      }
      throw e;
    }
  }



// ===== 【3】宿主桥 _app_host_ =====
  // JS 发起调用，宿主**必定**结算 Promise（成功回填 / 失败抛回）
  // 生成器把 Dart 的 static 调用 `AccountCenter.getUserName(a, b)` 翻译成
  // `_app_host_.invoke("getUserName", [a, b])`（参数载荷按形态给：纯位置→数组、
  // 纯具名→对象、混合→对象 + "@args" 键装位置实参）：本函数返回 Promise，
  // 经桥通道把 `{id, args}` 交给宿主，宿主实现完成后用
  // `_app_host_.resolve(id, value)` 回填（见 JsRuntimeManager.registerHostMethod）。
  // 框架内建通道（日志 `log`、native 通道等）同样走这里，保持单一出口。
  var __hostSeq = 0;
  var __hostPending = {};
  function __invokeHostMethod(channel, args) {
    __hostSeq += 1;
    var id = 'host' + __hostSeq;
    var p = new Promise(function (resolve, reject) {
      __hostPending[id] = { resolve: resolve, reject: reject };
    });
    __sendToHost(channel, { id: id, args: args || [] });
    return p;
  }
  // 结算并**摘除**条目：先删后调，保证一条 pending 只结算一次；成功/失败两条
  // 路径都必须走这里——宿主侧不会「既不 resolve 也不 reject」（未注册通道由
  // 宿主回填 null，实现抛错由宿主 reject），所以表里不会留下永久滞留的条目。
  function __takeHostCall(id) {
    var h = __hostPending[id];
    if (!h) { return null; }
    delete __hostPending[id];
    return h;
  }
  function __resolveHostCall(id, value) {
    var h = __takeHostCall(id);
    if (!h) { return; }
    h.resolve(value);
  }
  // 宿主实现失败：把错误原样抛给 JS 调用者（`await _app_host_.invoke(...)`
  // 处抛出，落进 JS 自己的 try/catch），而不是伪装成「结果是 null」。
  function __rejectHostCall(id, message) {
    var h = __takeHostCall(id);
    if (!h) { return; }
    h.reject(new Error(message));
  }



// ===== 【4】跨语言句柄注册表 =====
  // __handleSeq 与 __idSeq 相互独立：句柄 id 与结点 id 分属两套命名空间。
  var __handleSeq = 0;
  // id -> { id, kind, scope, key, obj, meta, release }
  var __handles = {};
  // 对象 -> id：同一对象重复登记返回同一 id（身份去重，WeakMap 不阻止回收）。
  var __handleOwnerIdx = new WeakMap();

  // 句柄 id：`js:<kind>#N`（kind 形如 `fn` / `ctrl/Scroll` / `key`）。
  function __nextHandleId(kind) {
    __handleSeq += 1;
    return 'js:' + kind + '#' + __handleSeq;
  }

  // 句柄摘要里的「是什么对象」：构造名优先（日志与泄漏/缓存全景共用同一套取法）。
  function __constructorName(h) {
    var t = h.obj === null ? 'null' : typeof h.obj;
    if (h.obj && (t === 'object' || t === 'function') && h.obj.constructor) {
      return h.obj.constructor.name || t;
    }
    return t;
  }

  // 【不在此留痕】句柄的登记 / 释放**不在 JS 侧打日志**：同一个句柄事件在宿主侧
  // 已由 `[binding] + / -` 逐条记录（见 binding_cache.dart 的 _logPut / remove），
  // 且带「类型 / 页面 / 引用强度 / 存活时长 / 登记方」；JS 侧再打一遍纯属重复，
  // 异步桥还要多套一层 `[js-log]` 前缀，反而更难读。JS 端的全景视图另由
  // `__jsui.cacheDump()`（debug）与泄漏快照汇总给出，__constructorName 仍供它们使用。

  // 登记一个 JS 侧真实对象/函数为句柄，返回 id。
  //
  // 归属优先级（scope 未显式指定时）：
  //   1. 组件**构造中**（`new el.type(...)` 期间）：记入最内层构造帧，返回后由
  //      __endConstruct 回填到该组件实例——字段初始化里的
  //      `this._controller = new ScrollController()` 正是这个时机；
  //   2. 委托调用期间（__withOwner）：归属方法体所在的类实例；
  //   3. `__building` 是组件结点（initState / build / 事件执行期）：直接归属它；
  //   4. 其余（模块级 / 静态字段）：随页面；无 __activeRoot 时退化为 global。
  //
  // 显式 `opts.scope`（'local' / 'page' / 'global'）优先，事件闭包等仍按原语义。
  //
  // `opts.release(h)`：本端真实资源的清理钩子（可选），随登记声明——只有需要
  // 「释放时还要动内部状态」的对象才传（如控制器要连带释放回传句柄与订阅）。
  // 对端的清理由对端自己的登记负责，跨桥只传 id + op。
  function __registerHandle(obj, kind, opts) {
    if (obj === null || obj === undefined) { return null; }
    var exist = __handleOwnerIdx.get(obj);
    if (exist && __handles[exist]) { return exist; }
    opts = opts || {};
    var explicit = opts.scope;
    var owner = opts.owner || null;
    var pending = false;
    if (!explicit && !owner) {
      if (__constructFrames.length) {
        pending = true; // 归属最内层构造中的组件（见 __beginConstruct/__endConstruct）
      } else if (__ownerAnchor) {
        // 委托调用期间（不是 build 锚点）：资源属于方法体所在的类实例
        owner = __ownerAnchor;
      } else if (__building && __building.__k === __COMP) {
        owner = __building;
      }
    }
    var pageKey = (__activeRoot && __activeRoot.key) || null;
    var scope = explicit || ((owner || pending) ? 'instance' : 'page');
    var key = pageKey; // 诊断 / 宿主侧页面兜底都用它
    if (scope === 'page') {
      key = opts.key || pageKey || null;
      if (key === null) { scope = 'global'; }
    }
    var id = __nextHandleId(kind);
    __handles[id] = {
      id: id, kind: kind, scope: scope, key: key, obj: obj,
      meta: opts.meta || null, release: opts.release || null, owner: null
    };
    __handleOwnerIdx.set(obj, id);
    if (scope === 'page') {
      (__pageHandles[key] || (__pageHandles[key] = [])).push(id);
    }
    if (owner) { __attachOwner(id, owner); }
    if (pending) { __constructFrames[__constructFrames.length - 1].push(id); }
    // 自动同步宿主：宿主侧同名 kind 的登记处理器据此创建真实对象
    // （scope=local 的纯本端句柄——如事件闭包——传 sync:false 不同步）。
    // pageKey 一并下发：宿主侧据此登记「句柄→页面」，页面销毁时做本端兜底回收。
    if (opts.sync !== false) {
      __invokeHostMethod('jsHandle', [{
        id: id, op: 'create', kind: kind, pageKey: key, meta: opts.meta || null
      }]);
    }
    return id;
  }

  // ── 组件实例归属（owner）────────────────────────────────────────────
  // 每个组件实例一份 `__owns`（id 数组），实例卸载时整份释放。物理存储仍在
  // 全局 `__handles`，这里只是「释放时机」的索引。
  var __constructFrames = []; // 组件构造帧栈：每帧收集该次 new 期间登记的句柄 id
  // 显式归属锚点：委托调用（`owner[name].call(owner, ...)`）期间指向方法体
  // 所在的类实例——`__building` 此时是被委托组件，不能用它判断资源归属。
  var __ownerAnchor = null;

  function __withOwner(inst, callback) {
    var prev = __ownerAnchor;
    __ownerAnchor = inst;
    try { return callback(); } finally { __ownerAnchor = prev; }
  }

  function __attachOwner(id, inst) {
    var h = __handles[id];
    if (!h || !inst) { return; }
    h.owner = inst;
    (inst.__owns || (inst.__owns = [])).push(id);
  }

  // 组件实例构造开始：返回本帧（mount 里紧贴 `new el.type(...)` 使用）。
  function __beginConstruct() {
    var frame = [];
    __constructFrames.push(frame);
    return frame;
  }

  // 构造结束：把本帧登记的句柄回填给新实例（构造抛错时 inst 传 null，
  // 这些句柄没有归属者，直接释放，避免两端残留）。
  function __endConstruct(inst, frame) {
    var i = __constructFrames.lastIndexOf(frame);
    if (i >= 0) { __constructFrames.splice(i, 1); }
    if (!frame) { return; }
    if (!inst) {
      for (var k = 0; k < frame.length; k++) { __releaseHandle(frame[k]); }
      return;
    }
    for (var j = 0; j < frame.length; j++) { __attachOwner(frame[j], inst); }
  }

  // 实例卸载：释放它持有的全部句柄（`dispose()` 里已显式释放过的幂等跳过）。
  function __releaseOwnerHandles(inst) {
    if (!inst || !inst.__owns) { return; }
    var snapshot = inst.__owns.slice();
    inst.__owns = null;
    for (var i = 0; i < snapshot.length; i++) { __releaseHandle(snapshot[i]); }
  }

  // 释放一个句柄（本端）。幂等：不存在即返回（不回环——对端释放时本地已删，
  // 不再二次通知）。notify=false 用于纯本端句柄（如构建期事件句柄）。
  function __releaseHandle(id, notify) {
    var h = __handles[id];
    if (!h) { return; }
    delete __handles[id];
    if (h.obj) { try { __handleOwnerIdx.delete(h.obj); } catch (e) {} }
    // 从所属组件实例的索引里摘除（实例卸载时 __owns 已置 null，跳过）。
    if (h.owner && h.owner.__owns) {
      var owns = h.owner.__owns;
      var oi = owns.indexOf(id);
      if (oi >= 0) { owns.splice(oi, 1); }
    }
    if (h.scope === 'page' && h.key && __pageHandles[h.key]) {
      var arr = __pageHandles[h.key];
      var i = arr.indexOf(id);
      if (i >= 0) { arr.splice(i, 1); }
    }
    if (h.release) {
      try { h.release(h); } catch (e) {}
    }
    if (notify !== false) { __invokeHostMethod('jsHandle', [{ id: id, op: 'release' }]); }
  }

  // 页面退出兜底：释放本页登记的全部 page 句柄（数组边遍历边被 __releaseHandle
  // 摘除，故拷贝一份再遍历）。
  function __releasePageHandles(pageKey) {
    var arr = __pageHandles[pageKey];
    if (!arr) { return; }
    var snapshot = arr.slice();
    for (var i = 0; i < snapshot.length; i++) { __releaseHandle(snapshot[i]); }
    delete __pageHandles[pageKey];
  }

  // 页面退出兜底（宿主在泄漏比对之后显式调用）：清掉**本页所属**的残留句柄。
  //
  // 判定「属于本页」用句柄自身的 key + 持有者归属：
  //   - key !== pageKey：别的页的，跳过；
  //   - 持有者仍挂在**活着的**页面根上（__roots[owner.__root.key] 存在）：说明该
  //     对象被别的活页面共享使用，跳过（避免退出 A 页把 B 页还在用的对象释放掉）；
  //   - 其余（无持有者、持有者的根已销毁）即本页孤儿，释放。
  // 正常路径上组件卸载已逐实例释放，这里剩的只是卸载路径没跑到的残渣；释放幂等，
  // 因此页面挂载/卸载多少次都不会累积。放在比对之后调用，泄漏仍可被观测。
  function __sweepPage(pageKey) {
    __releasePageHandles(pageKey);
    var ids = [];
    for (var id in __handles) {
      var h = __handles[id];
      if (h.key !== pageKey) { continue; }
      var owner = h.owner;
      if (owner && owner.__root && __roots[owner.__root.key]) { continue; }
      ids.push(id);
    }
    for (var i = 0; i < ids.length; i++) { __releaseHandle(ids[i]); }
  }

  // 宿主 → JS：按 id 在**本端**真实对象上执行 op（宿主侧句柄注册表经 evaluate
  // 调用，见 __jsui.call）。返回结果供宿主回填（Promise 场景）。
  //   invoke：函数句柄调用（args 数组）
  //   call  ：对象方法调用（method + args）
  //   get/set：属性读写（name）
  function __callHandle(id, op, payload) {
    var h = __handles[id];
    if (!h) {
      __warn('jsui: handle not found (released?): ' + id + ' op=' + op);
      return undefined;
    }
    var o = h.obj;
    payload = payload || {};
    if (op === 'invoke') { return typeof o === 'function' ? o.apply(null, payload.args || []) : undefined; }
    if (op === 'call') { return (o && typeof o[payload.method] === 'function') ? o[payload.method].apply(o, payload.args || []) : undefined; }
    if (op === 'get') { return o ? o[payload.name] : undefined; }
    if (op === 'set') { if (o) { o[payload.name] = payload.value; } return undefined; }
    return undefined;
  }

  // 句柄对应的本端真实对象（跨模块按 id 取 obj：easy_refresh 的异步回程等）。
  function __handleObjectOf(id) {
    var h = __handles[id];
    return h ? h.obj : null;
  }

  // JS → 宿主：对本端句柄对应的**宿主端真实对象**发起 op（返回 Promise）。
  // 与 __callHandle 方向相反、语义对称（call/get/set/invoke）。
  function __handleOp(id, op, payload) {
    var body = { id: id, op: op };
    if (payload) { for (var k in payload) { body[k] = payload[k]; } }
    return __invokeHostMethod('jsHandle', [body]);
  }

  // 控制器（ScrollController / AnimationController / …）的 JS 基类不在这里：
  // 它们是 Flutter 侧语义，随 flutter.js 发布（`ControllerBase`，见
  // js/controller_base_js.dart）。本片段只提供与能力无关的句柄机制
  // （__registerHandle / __handleOp / __releaseHandle）。



// ===== 【5】element 与事件句柄 =====

  // 元素的唯一判据：`__element === true`。
  //   - 宿主元素（含宿主包装类 `new Text(...)` 的返回值）：`__type` 是**类型名字符串**；
  //   - 组件元素：`Component` 实例**自身**就是元素（构造时写入 `__element` /
  //     `__type` / props，见 flutter.js 的 Component）。
  // 两者共用同一个标记，reconciler 不再按「原型上有没有 build」猜组件。
  // 双下划线前缀 = 运行时保留名，Dart 业务字段不会覆盖它。
  function __isElement(v) {
    return v != null && typeof v === 'object' && v.__element === true;
  }

  // 元素数组（子项列表）。数组里的非元素值（数据）原样保留。
  function __isElementList(v) {
    if (!Array.isArray(v) || v.length === 0) { return false; }
    for (var i = 0; i < v.length; i++) {
      if (v[i] != null && !__isElement(v[i])) { return false; }
    }
    return true;
  }

  // 日志预览：值对象里的描述内容可能很深 / 带复杂实例，只取一段可读文本。
  function __jsonPreview(v) {
    try {
      var s = JSON.stringify(v);
      if (s == null) { return ''; }
      return s.length > 200 ? s.slice(0, 200) + '…' : s;
    } catch (e) { return '<unserializable>'; }
  }

  // 值对象（值类）里携带的宿主元素 → 宿主可还原的元素描述
  // `{type, props, children, element: true}`（还原入口见宿主 js_widget_registry
  // 的 `buildJsElement`，renderer 侧即 `JsRenderContext.element`）。
  //
  // 这些元素**不进 reconciler 树**：父 renderer 取用时就地建 Flutter widget，
  // 父级每次重建重建一次（与 Flutter 一致，没有 patch/diff 语义）。
  //
  // 判据只有协议：`__element === true` 的元素、数组、delegate 列表递归摊开，
  // 其余值原样透传。
  //
  // **JS 组件（重写了 build）就地展开**：值对象不进结点树，宿主没有可驱动的
  // 结点，所以在序列化时按 reconciler 的同一入口 `__buildOf` 执行一次 build，
  // 把结果递归摊成普通元素描述。build 结果里再套自定义组件由递归继续展开，
  // 直到落到宿主可渲染的类型。语义边界：只跑 build 一次（无 initState /
  // didChangeDependencies / setState / dispose，状态不刷新），展开失败时保留
  // 原描述并打 `component: true` + 告警，宿主渲染为「未注册类型」占位。
  function __descriptorOf(v, depth) {
    depth = depth || 0;
    if (v == null) { return null; }
    if (depth > 16) {
      __warn('值对象里的元素嵌套过深（疑似自引用），已丢弃');
      return null;
    }
    if (Array.isArray(v)) {
      var arr = [];
      for (var i = 0; i < v.length; i++) { arr.push(__descriptorOf(v[i], depth + 1)); }
      return arr;
    }
    if (!__isElement(v)) { return v; }
    var T = v.__type;
    var type = typeof T === 'string' ? T : (T && T.name);
    if (!type) {
      __warn('值对象里的元素缺少类型名，已丢弃');
      return null;
    }
    // JS 组件实例由 Component 构造写入 `__host=false`（宿主包装类为 true）；
    // 不再按原型上「有没有 build」判断（InheritedWidget 这类基类的 build 是继承的）。
    var isComponent = v.__host === false;
    if (isComponent) {
      var built = null;
      try {
        // 与 reconciler 同一条 build 入口（锚点 = 该实例 / 页面），只执行一次。
        built = __buildOf(v);
      } catch (e) {
        __warn('值对象里的 JS 组件 "' + type + '" build 失败：' +
          (e && e.message ? e.message : String(e)));
      }
      if (built != null && built !== v) { return __descriptorOf(built, depth + 1); }
      if (built === v) {
        __warn('值对象里的 JS 组件 "' + type + '" build 返回自身（自引用），已丢弃');
      }
      // 展开失败：继续往下走，保留原描述并打标记（宿主给可见占位，不静默）。
    }
    // props / 子槽：宿主包装类在构造期已按统一协议拆好（见 Component.__splitHost）；
    // JS 组件不拆分，widget 实参仍在 props 里——这里统一递归摊开，保证整棵描述
    // 可 JSON 化（元素实例带 `__anchor` 等循环引用，不能直接下发）。
    var props = {}, children = {};
    var src = v.props || {};
    for (var k in src) {
      if (!Object.prototype.hasOwnProperty.call(src, k)) { continue; }
      if (typeof src[k] === 'function') {
        __warn('值对象里的元素 "' + type + '" 的回调 "' + k +
          '" 无法跨桥（值对象不进结点树，没有句柄归属），已丢弃');
        continue;
      }
      props[k] = __descriptorOf(src[k], depth + 1);
    }
    var slots = v.__children || {};
    for (var sk in slots) {
      if (!Object.prototype.hasOwnProperty.call(slots, sk)) { continue; }
      var sv = slots[sk];
      if (sv != null && typeof sv === 'object' && !Array.isArray(sv) &&
          (sv.__builder !== undefined || sv.__delegate === 'builder')) {
        __warn('值对象里的元素 "' + type + '" 的 builder 槽 "' + sk +
          '" 无法跨桥，已丢弃');
        continue;
      }
      if (sv != null && typeof sv === 'object' && !Array.isArray(sv) &&
          sv.__delegate === 'list') {
        children[sk] = {
          __delegate: 'list', children: __descriptorOf(sv.children || [], depth + 1)
        };
        continue;
      }
      children[sk] = __descriptorOf(sv, depth + 1);
    }
    var out = { type: type, props: props, children: children, element: true };
    if (isComponent) {
      out.component = true;
      __warn('值对象里的 JS 组件 "' + type + '" 未能展开（build 为空 / 抛错 / 自引用），' +
        '将渲染为未注册占位；下发的描述：' + __jsonPreview(out));
    }
    return out;
  }

  // 事件回调无法跨语言传递 -> 登记为句柄（kind=fn，scope=local）。
  // 宿主回调用 __invokeEventHandler 触发。
  //
  // 句柄的**创建时机**只有一个：宿主 props 下发前的 [__hostProps]。翻译层只
  // 做字面翻译（闭包就是闭包、`Colors.red` 就是 `Colors.red`），不判断某个
  // 实参「是不是回调」；函数值是否需要句柄由运行时按 `typeof` 决定。
  function __createFnHandle(f) {
    var id = __registerHandle(f, 'fn', { scope: 'local', sync: false });
    return { __fn: id };
  }

  // 宿主元素的函数形参名单：元素自带（`el.__fnProps`）优先，否则取类上的静态
  // 声明。**未声明 = undefined = 本类型没有回调**（零循环）；数组 = 名单；
  // `null` = 签名不可得（回退全量扫描）。字符串类型没有类可查 → null。
  function __hostFnNamesOf(el) {
    var names = el.__fnProps;
    if (names !== undefined) { return names; }
    var T = el.__type;
    if (typeof T !== 'function') { return null; }
    return T.__fnProps;
  }

  // 宿主 props 跨语言下发前的统一折算：**函数值 → `{__fn:id}` 句柄**，其它值
  // 原样。句柄缓存在**宿主结点**上、按 prop 名索引：
  //   - 结点内信封与 id 稳定：重建只更新本侧实现，props 比较不抖动；
  //   - 结点独占缓存：兄弟结点 / 列表项各自一份，天然不串味（不需要编译期位点号）；
  //   - 结点卸载时随结点释放（见 __markUnmounted）。
  function __hostProps(host, props, anchor, fnNames) {
    // 名单已知（数组，或 undefined = 本类型没有回调）：只查名单里的键；
    // `null` = 签名不可得 → 全量扫描兜底。
    var listed = fnNames !== null;
    var need = false, k, i;
    if (listed) {
      var count = fnNames ? fnNames.length : 0;
      for (i = 0; i < count; i++) {
        if (typeof props[fnNames[i]] === 'function') { need = true; break; }
      }
    } else {
      for (k in props) {
        if (typeof props[k] === 'function') { need = true; break; }
      }
    }
    if (!need) {
      // 上一帧有函数、这一帧全没了：旧句柄一并释放。
      if (host.__hostFns) { __releaseHostFns(host); }
      return props;
    }

    var bag = host.__hostFns || (host.__hostFns = {});
    var out = {};
    // 一次浅拷贝（只复制引用）。必须复制而不是原地改：元素对象可能被 const /
    // 循环复用，原地写成句柄会让另一个结点也拿到同一份 props。
    for (k in props) {
      if (Object.prototype.hasOwnProperty.call(props, k)) { out[k] = props[k]; }
    }
    if (listed) {
      for (i = 0; i < fnNames.length; i++) {
        k = fnNames[i];
        if (typeof props[k] === 'function') { out[k] = __hostFnOf(bag, k, props[k], anchor); }
      }
    } else {
      for (k in out) {
        if (typeof out[k] === 'function') { out[k] = __hostFnOf(bag, k, out[k], anchor); }
      }
    }
    // 名单外 / 已变成普通值 / 已移除的函数键：句柄一并释放。
    for (k in bag) {
      if (out[k] !== bag[k].env) { __releaseHandle(bag[k].env.__fn, false); delete bag[k]; }
    }
    return out;
  }

  // 一个宿主函数 prop 的句柄记录：`env` 是**唯一**进入 props 的信封（只含
  // `__fn`，必须可 JSON 序列化）；`state` 存实际实现与构建锚点，留在本侧，
  // 绝不挂到信封上（带上组件实例会让 commit 的 JSON.stringify 成环）。
  function __hostFnOf(bag, key, fn, anchor) {
    var rec = bag[key];
    if (!rec) {
      var state = { run: fn, anchor: anchor };
      var handle = __createFnHandle(function () {
        var args = arguments;
        // 回调执行时还原**产出该元素的组件**为构建锚点：闭包里的 `this.context`
        // 与构造期句柄归属都和编译期绑定时一致。
        try {
          return __withBuilding(state.anchor, function () {
            return state.run.apply(null, args);
          });
        } catch (e) { __error(String(e)); }
      });
      rec = bag[key] = { env: handle, state: state };
      return handle;
    }
    rec.state.run = fn;
    rec.state.anchor = anchor;
    return rec.env;
  }

  // 卸载宿主结点时释放它的函数句柄（句柄 scope=local，不经 owner 索引）。
  function __releaseHostFns(node) {
    var bag = node.__hostFns;
    if (!bag) { return; }
    for (var k in bag) { __releaseHandle(bag[k].env.__fn, false); }
    node.__hostFns = null;
  }

  // 事件回传载荷统一为**参数数组**（Dart 侧 `_invoke(handler, args)` 的 args）：
  // 0 参事件 `[]`、onChanged `[v]`、多参事件 `[a,b]`…。句柄登记的是产物的普通
  // 函数（见 __hostProps 的 wrapper），按 `arguments` 把任意个数原样摊开转发。
  // 故 0/1/N 参事件共用同一条通路，新增多参事件无需改这里。
  function __invokeEventHandler(id, args) {
    var h = __handles[id];
    var f = h && h.obj;
    if (typeof f !== 'function') {
      // 宿主回传的句柄 id 在 JS 侧找不到 —— 说明该结点下发时的 handler 与当前
      // 句柄表不一致（已卸载回收 / 从未登记）。
      return;
    }
    if (typeof args === 'string' && args.length) {
      try { args = JSON.parse(args); } catch (e) { args = null; }
    }
    if (!Array.isArray(args)) { args = args == null ? [] : [args]; }
    // 返回值原样给调用方：普通事件无人读（`__jsui.invoke` 丢弃），
    // 需要结果的事件走 `__jsui.invokeAwait`（见下），二者共用本函数。
    return f.apply(null, args);
  }

  // 宿主发起、需要拿回结果的事件调用（`__jsui.invokeAwait` 的实现）。
  //
  // 统一机制，与具体能力无关：Dart 侧 `Future<T>` 回调（confirmDismiss /
  // onRefresh / 未来任何 async `onPressed`）在 JS 侧都是 async 函数，返回
  // Promise。iOS/JavaScriptCore 无法把 Promise 交回 Dart，因此这里 await 完后
  // 经唯一 JS→宿主出口把「token + 结果 JSON」回传，宿主按 token 结算 Future。
  //
  // 同步返回值也走同一条回传（`该回调不是 async` 与 `async 立即 resolve`
  // 对宿主无差别），保证宿主那条 pending **必定结算**。
  function __invokeEventHandlerAwait(id, argsJson, token) {
    var out;
    try {
      out = __invokeEventHandler(id, argsJson);
    } catch (e) {
      __error('[jsui] 事件执行抛错: ' + String(e));
      __sendEventResult(token, null, String(e));
      return;
    }
    if (out && typeof out.then === 'function') {
      out.then(
        function (v) { __sendEventResult(token, v, null); },
        function (e) { __sendEventResult(token, null, String(e)); }
      );
      return;
    }
    __sendEventResult(token, out, null);
  }

  function __sendEventResult(token, value, error) {
    var json = 'null';
    try { json = JSON.stringify(value === undefined ? null : value); } catch (e) { json = 'null'; }
    __invokeHostMethod('jsuiEventResult', [token, json, error]);
  }



// ===== 【6】reconciler 工具 =====

  // 深比较（用于避免每次重建都下发 props）；下面紧邻的 __nodeKeyOf /
  // __nodeIdOf / __renderRootIdOf / __rootOf 同属本分区。
  var EQ_MAX_DEPTH = 32;
  function __propsEqual(a, b, depth) {
    if (a === b) { return true; }
    if (depth === undefined || depth === null) { depth = EQ_MAX_DEPTH; }
    if (depth <= 0) { return false; }
    if (typeof a !== typeof b) { return false; }
    if (a === null || b === null || typeof a !== 'object') { return false; }
    var aArr = Array.isArray(a), bArr = Array.isArray(b);
    if (aArr !== bArr) { return false; }
    // 数组先比长度：列表插删是最常见的变化，能在这里短路，不必走进逐项递归。
    if (aArr && a.length !== b.length) { return false; }
    // 只分配 a 的键数组；b 的键数用 for-in 计数（原来每层两次 Object.keys，
    // 深树 patch 时是纯 GC 压力）。
    var ka = Object.keys(a);
    var bn = 0;
    for (var kb in b) {
      if (Object.prototype.hasOwnProperty.call(b, kb)) { bn += 1; }
    }
    if (ka.length !== bn) { return false; }
    for (var i = 0; i < ka.length; i++) {
      if (!__propsEqual(a[ka[i]], b[ka[i]], depth - 1)) { return false; }
    }
    return true;
  }

  // 结点声明的 key（**值**，不是结点）：ValueKey / ObjectKey 实例、GlobalKey /
  // UniqueKey 的句柄实例，或 null（未声明）。比较一律经 [__keySig]（见【20】），
  // 不在此处做归一——`__nodeKeyOf` 只负责取。
  function __nodeKeyOf(inst) {
    var p = inst.__k === __HOST ? inst.__props : inst.props;
    return p ? p.key : null;
  }

  // key 的「上下文绑定」协议：只有声明了 __attachContext 的 key 对象（如
  // GlobalKey）参与，reconciler 只认方法、不认类型。
  //
  // 挂载时把本结点的 BuildContext 代理挂到 key 上，卸载时按身份摘除，从而
  // `key.currentContext` 与 Flutter 一致：**未挂载 / 已卸载为 null**，挂载期间
  // 返回同一个代理。
  //   - 组件结点：它自己的上下文代理（anchor + 结点 id，watch/read 可用）；
  //   - 宿主结点：JS 侧没有组件实例，用 key 句柄——位置 / 尺寸 op 由宿主沿真实
  //     GlobalKey 解析（见 capabilities/key/key_bridge.dart）。
  function __attachKeyContext(inst) {
    var k = __nodeKeyOf(inst);
    if (!k || typeof k.__attachContext !== 'function') { return; }
    var ctx = inst.__k === __COMP
        ? __contextOf(inst)
        : new JsBuildContext(null, null, k.__id);
    k.__attachContext(ctx);
    inst.__keyCtx = ctx;
    inst.__keyOwner = k;
  }

  // 卸载时摘除。这里只摘引用、**不释放句柄**：组件上下文句柄由 __markUnmounted
  // 的 [ctx] 分支释放；GlobalKey 句柄随持有它的组件 / 页面兜底释放。
  // 按身份比较：同一个 key 可能已被后来的结点重新挂上（元素换位 / 旧结点卸载
  // 晚于新结点挂载），此时不能清掉新绑定。
  function __detachKeyContext(inst) {
    var k = inst.__keyOwner;
    if (!k) { return; }
    if (typeof k.__detachContext === 'function') { k.__detachContext(inst.__keyCtx); }
    inst.__keyCtx = null;
    inst.__keyOwner = null;
  }

  // 结点在**父槽里的标识**：__HOST / __COMP 都用自己的 `__id`。
  // 组件结点是宿主的**挂载边界**（宿主为它建 wrapper，wrapper 在 build 里同步
  // 拉取 JS build 结果），所以父槽引用的是组件结点本身，而不是它的渲染根。
  function __nodeIdOf(inst) { return inst ? inst.__id : null; }

  // 组件的**渲染根结点 id**（组件结点的 `child` 槽指向它）。
  function __renderRootIdOf(inst) {
    return inst && inst.__child ? inst.__child.__id : null;
  }

  // 结点归属的根：mount 期间用 __activeRoot，其余情况继承父结点。
  function __rootOf(parent) {
    return __activeRoot || (parent && parent.__root) || null;
  }



// ===== 【7】组件基类 =====

  // 生成器产物与逻辑组件类都 `extends Component`（见 flutter.js），
  // setState / context 由基类提供，不在实例上逐个挂载。
  // 这里只留回调调用与生命周期派发的唯一入口。

  // ── 构建锚点（__withBuilding）─────────────────────────────────────────────
  // 「当前构建位置」的唯一读写点：`context` / 宿主回调执行 / 构造期句柄归属
  // 都据此定位。build / didUpdateWidget / didChangeDependencies / 卸载期
  // 生命周期都在这个锚点里执行，退出即还原。
  function __withBuilding(inst, fn) {
    var prev = __building;
    __building = inst;
    try { return fn(); } finally { __building = prev; }
  }

  // ── 生命周期派发（__callLifecycle）─────────────────────────────────────────
  // 卸载期的 deactivate / dispose：异常只记日志（为的是「一个组件清理失败
  // 不能中断整棵树的拆解」），且执行期间锚点指向本实例（新建/释放句柄的归属）。
  function __callLifecycle(inst, name, args) {
    if (typeof inst[name] !== 'function') { return; }
    __withBuilding(inst, function () {
      try { inst[name].apply(inst, args || []); }
      catch (e) { __error(name + ' failed: ' + (e && e.message ? e.message : String(e))); }
    });
  }

  // ── 回调调用（__invokeCallback）─────────────────────────────────────────
  // JS 类内部要调一个「函数型 prop」时统一走这里。
  // 双下划线 = **运行时私有**，只允许生成器产出的 JS 类（逻辑组件）调用，
  // 组件使用方的业务代码不得直接引用（回调应由组件自身消费，见 AGENTS.md）。
  // JS 侧的函数 prop 一律是可调用函数；只有宿主元素 props 才在 `__hostProps`
  // 归一成 `{__fn:id}` 信封。
  // 反之，函数型 prop 也可能缺省（调用方没传），此时静默返回 undefined。
  // 与上面的 `invoke(id, args)` 区分：后者是**宿主回传**（按句柄 id 反查），
  // 这里拿到的是**回调本身**。
  G.__invokeCallback = function (target, args) {
    args = args || [];
    if (typeof target === 'function') { return target.apply(null, args); }
    return undefined;
  };



// ===== 【8】作用域与订阅 =====

  // 子结点上的 `__inheritedElements`（类型名 → 提供者结点）：InheritedWidget /
  // provider 作用域由提供者自己登记；查找只认精确类型名（见 __getInheritedElement）。
  // Dart 类型名 → JS 侧精确类型键：去掉泛型实参 / import 前缀。
  function __exactTypeName(name) {
    if (typeof name !== 'string') { return null; }
    var s = name.trim();
    var lt = s.indexOf('<');
    if (lt >= 0) { s = s.slice(0, lt); }
    var dot = s.lastIndexOf('.');
    if (dot >= 0) { s = s.slice(dot + 1); }
    return s || null;
  }

  // 泛型方法 / 构造下发的类型实参 → 第一个类型名（键名取决于声明侧类型参数名，
  // 消费方按 Object.values 取值，与开发者写的参数名无关）。
  function __typeArgumentOf(props, api) {
    var ta = (props && props.typeArguments) || {};
    var keys = Object.keys(ta);
    if (!keys.length) {
      if (api) { __warn('[jsui] ' + api + ' 缺少类型实参 typeArguments'); }
      return null;
    }
    return ta[keys[0]];
  }

  // 结点声明自己为某个精确类型的提供者（InheritedWidget / provider 作用域）。
  function __inheritElement(inst, typeName) {
    var key = __exactTypeName(typeName);
    if (!inst || key == null) { return; }
    if (inst.__inheritedElements == null) { inst.__inheritedElements = {}; }
    var prev = inst.__inheritedType;
    if (prev != null && prev !== key) { delete inst.__inheritedElements[prev]; }
    inst.__inheritedElements[key] = inst;
    inst.__inheritedType = key;
  }

  // 从 [inst] 沿 `__parent` 向上取最近提供 [typeName] 的结点（同名就近遮蔽），
  // 对应 `Element.getElementForInheritedWidgetOfExactType`。
  // 必须是同步取值：渲染期直接读，不能经异步桥回宿主。取不到返回 null。
  function __getInheritedElement(inst, typeName) {
    var key = __exactTypeName(typeName);
    if (!inst || key == null) { return null; }
    var p = inst.__parent;
    while (p) {
      var map = p.__inheritedElements;
      if (map && Object.prototype.hasOwnProperty.call(map, key)) { return map[key]; }
      p = p.__parent;
    }
    return null;
  }

  // 依赖登记：消费位置（anchor）挂到提供者结点的 `__dependents`（对应
  // `InheritedElement._dependents`），anchor 自己的台账记 `__dependencies`
  // （对应 `Element._dependencies`），重建 / 卸载时据此精确摘除。
  function __registerDependency(anchor, element, key) {
    if (!anchor || !element) { return; }
    var deps = anchor.__dependencies;
    if (!deps) { deps = anchor.__dependencies = []; }
    for (var i = 0; i < deps.length; i++) {
      if (deps[i].element === element && deps[i].key === key) { return; }
    }
    deps.push({ element: element, key: key });
    var ds = element.__dependents;
    if (!ds) { ds = element.__dependents = []; }
    if (ds.indexOf(anchor) < 0) { ds.push(anchor); }
  }

  // 清空 anchor 的依赖边（每次重建 / 卸载时调用：Flutter 重建时也会重新
  // 收集依赖，旧边必须摘掉）。
  function __clearDependencies(anchor) {
    var deps = anchor && anchor.__dependencies;
    if (!deps) { return; }
    for (var i = 0; i < deps.length; i++) {
      var ds = deps[i].element && deps[i].element.__dependents;
      if (!ds) { continue; }
      var at = ds.indexOf(anchor);
      if (at >= 0) { ds.splice(at, 1); }
    }
    anchor.__dependencies = null;
  }

  // 提供者变更 → 通知全部依赖者（对应 `InheritedElement.notifyClients`）。
  // 依赖变更走 `__depDirty`（与 setState 区分：flush 时先 didChangeDependencies
  // 再 build），与 Flutter 的 InheritedWidget 变更语义一致。
  function __notifyClients(element) {
    var ds = element && element.__dependents;
    if (!ds || !ds.length) { return; }
    for (var i = 0; i < ds.length; i++) {
      var dependent = ds[i];
      if (!dependent || dependent.__unmounted) { continue; }
      dependent.__depDirty = true;
      __markDirty(dependent);
    }
  }

  
  
  // 订阅：给 [value] 挂一个「把 [anchor] 标脏」的监听。订阅由**消费者自己持有**
  // （提供者不记账），台账记在消费者侧 `__subs`，卸载时精确退订。
  // 按值身份去重：重建会再次 watch，但不会重复挂监听。
  // 这条通路复用的是原生 ChangeNotifier API（不是 provider 私有记账）：
  // notify 时把订阅位置标脏 → 重建 → 下发 patch → 宿主结点重建，UI 才真正更新。
  //
  // **鸭子判型**：值是不是可监听是**值自己的事**——「找到值之后怎么用」属于
  // 调用方，与查找机制无关（与 Flutter 一致：watch 一个纯数据 InheritedWidget
  // 也合法，只是没有本端订阅可言）。
  function __subscribeListenable(anchor, value, owner) {
    if (!value || typeof value.addListener !== 'function') { return; }
    var mine = anchor.__subs || (anchor.__subs = []);
    var i;
    for (i = 0; i < mine.length; i++) {
      if (mine[i].owner === owner && mine[i].value === value) { return; }
    }
    // 同一 owner 换了被监听实例（provider 的 notifier 被替换）：精确退订旧的，
    // 避免悬空监听继续标脏。
    for (i = 0; i < mine.length; i++) {
      if (mine[i].owner === owner) {
        var old = mine[i];
        if (typeof old.value.removeListener === 'function') {
          old.value.removeListener(old.listener);
        }
        mine.splice(i, 1);
        break;
      }
    }
    var entry = { value: value, owner: owner };
    // 依赖变更必须区别于 setState：标记 __depDirty，flush 时据此在 build 前
    // 补一次 didChangeDependencies（对应 Flutter 的 InheritedWidget 变更语义）。
    entry.listener = function () { anchor.__depDirty = true; __markDirty(anchor); };
    value.addListener(entry.listener);
    mine.push(entry);
  }

  // 卸载时按消费者自己记录的台账精确退订。
  function __unsubscribeAll(inst) {
    var mine = inst.__subs;
    if (!mine) { return; }
    for (var i = 0; i < mine.length; i++) {
      var value = mine[i].value;
      if (value && typeof value.removeListener === 'function') {
        value.removeListener(mine[i].listener);
      }
    }
    inst.__subs = null;
  }

  


// ===== 【9】调度 =====

  // collected dirty -> 重建子树 -> 一次 commit。
  // 触发源有两处：mini-react 的 setState、作用域订阅回调（见【8】`__subscribeListenable`）。
  //
  // **挂载中不 flush**：`root.mounting` 期间 `root.ops` 归 __mountRoot 累积（整棵树的
  // create/insert），而 flush 会重置并消耗同一份 ops —— 未下发的结点连同根 op 一起
  // 丢，宿主收不到根、页面永远停在加载态。setState 在 initState / 构造里是合法写法
  // （Flutter 也是首帧后再重建），故这里只入 dirty 队列，__mountRoot 收尾时再 flush。
  //
  // **按帧合并（与 Flutter 的 setState 语义一致）**：setState 只标脏，真正的
  // rebuild 由宿主在每帧 begin frame 调 `api.flushPending()` 统一执行。同一帧内
  // 收到多少个 setState（例如滚动通知逐条回传）都只 build 一次；此前是每次
  // setState 同步 flush，滚动时 JS 的重建次数等于通知数，是原生的数倍。
  // 没有宿主桥（命令行 / 测试 harness）时退化为同步 flush，保持原行为。
  function __markDirty(inst) {
    if (!inst || inst.__unmounted || inst.__dirty) { return; }
    // build 期对自己 setState 是错误写法：Flutter 原生在此直接断言（
    // "setState() or markNeedsBuild() called during build"）。若不拦截，flush
    // 的 while 会「置 __dirty=false → build 内再入队 → 再 build」无限循环，
    // 整个 JS 线程卡死且没有任何日志。这里出声并跳过。
    // 只挡「自己正在 build」：祖先/子结点互相标脏不受影响（原生同样放行）。
    if (inst.__building) {
      __error('jsui: setState during build ignored (' +
        __componentName(inst.constructor) + ')');
      return;
    }
    var root = inst.__root;
    if (!root) { return; }
    inst.__dirty = true;
    root.dirty.push(inst);
    if (root.flushing || root.mounting) { return; }
    __requestFlush(root);
  }

  // 请求宿主在下一帧统一 flush。同一帧内多次 setState 只请求一次。
  function __requestFlush(root) {
    if (root.flushPending) { return; }
    root.flushPending = true;
    // 有宿主桥才交给它调度；否则（无 sendMessage 的纯 JS 环境，如单测）同步兜底。
    if (typeof sendMessage === 'function' && G._app_host_) {
      G._app_host_.invoke('jsuiRequestFrame', []);
      return;
    }
    __flushNow(root);
  }

  // 立即 flush：挂载收尾（__mountRoot / __lazyMount / __lazyUnmount）与无宿主兜底用。
  function __flushNow(root) {
    if (!root || root.flushing || root.mounting) { return; }
    root.flushPending = false;
    root.flushing = true;
    try { __rebuildDirty(root); } finally { root.flushing = false; }
  }

  // 宿主每帧 begin frame 调用：跑掉所有页面根累积的重建（帧级批处理入口）。
  function __flushPending() {
    for (var key in __roots) {
      var root = __roots[key];
      if (!root || !root.flushPending || root.flushing || root.mounting) {
        continue;
      }
      __flushNow(root);
    }
    return true;
  }

  function __rebuildDirty(root) {
    var prev = __activeRoot;
    __activeRoot = root;
    try {
      while (root.dirty.length) {
        var batch = root.dirty;
        root.dirty = [];
        for (var i = 0; i < batch.length; i++) {
          var inst = batch[i];
          inst.__dirty = false;
          if (inst.__unmounted) { continue; }
          // 首次 build 还没被宿主拉起（组件 wrapper 尚未挂载）：build 由
          // __pullComponent 驱动，它会读取此刻最新的 props / state，故这里跳过。
          if (inst.__k === __COMP && !inst.__built) { continue; }
          // 单条重建失败不连坐同批其余组件（与 Flutter「一个子树建错出
          // ErrorWidget、兄弟照常构建」对齐）：本批已由 root.dirty 整体接管
          // 并清空，异常若冲出 for 循环，后面那些组件的 __dirty 仍是 true 却
          // 已不在队列里，__markDirty 会因 __dirty 早退 → 它们将永不重建。
          root.ops = [];
          try {
            // 继承依赖：每次重建前重新收集（与 Flutter 的重建语义一致）。
            __clearDependencies(inst);
            // 作用域依赖变更（__depDirty）走这里：与 Flutter 一致，
            // 先 didChangeDependencies 再 build；setState 触发的重建不调。
            if (inst.__depDirty) {
              inst.__depDirty = false;
              if (typeof inst.didChangeDependencies === 'function') {
                inst.didChangeDependencies();
              }
            }
            inst.__child = __patchComponentChild(inst);
            // 组件自身重建（setState → flush）不经过父级 __patchLazySlot：动态
            // wantKeepAlive（`bool get wantKeepAlive => _flag`）的变化必须在这里
            // 补一次同步，否则宿主侧保活声明会停留在旧值。
            // 读的是业务 getter，异常只记日志：不能让它把本次**已成功**的重建
            // 补丁一起丢进下面的 catch。
            try {
              __syncEnclosingKeepAlive(inst);
            } catch (e2) {
              __error('jsui: keepAlive sync failed (' +
                __componentName(inst.constructor) + '): ' + e2);
            }
            // 宿主渲染以组件为重建粒度：props / 结构补丁已随本批下发，宿主只需
            // 重建该组件的 wrapper（它的 build 会按 store 里的最新结点重渲染整棵
            // 子树）。宿主叶子结点因此不必各自持有 wrapper。
            __emitOp({ op: 'rebuild', id: inst.__id });
            __commitOps(root);
          } catch (e) {
            // 丢弃本次未 commit 的增量：宿主只接受整批 commit，半棵树不下发，
            // 避免 JS 树与宿主渲染在中途状态上分叉。该实例保持 __dirty=false，
            // 下次 setState / 订阅通知会重新重建。
            root.ops = null;
            __error('jsui: rebuild failed (' +
              __componentName(inst.constructor) + '): ' + e);
          }
        }
      }
    } finally {
      __activeRoot = prev;
    }
  }



// ===== 【10】reconciler 主流程 =====

  //
  // 「懒容器 + 延迟子结点」：容器的 children 不随容器一起挂载，而是等**宿主**
  // 真的 inflate 到那个槽位时才挂载 —— 即 initState 由 `_JsPlainNodeHostState` 的生命周期
  // 驱动。MiniReact 的挂载是一次性全树遍历，做不到层层按需；而「哪个子结点可见」
  // 的真值只在宿主侧（Flutter 的 element inflation）。所以这里只留一个**普通**
  // 零尺寸占位结点（复用 SizedBox 类型：不新增 widget 类型、产物形态零改动），
  // 真实子元素先挂在占位实例的 `__deferred` 上；宿主 inflate 到占位结点时经
  // `__lazyFn`（事件句柄同款 invoke 通道）回调 __lazyMount，才真正 mount
  //（构造 + initState + build，顺序与 Flutter 一致）。
  //
  // 占位结点**永不替换**：真实子树挂成占位结点的 `child` slot（propsChild），
  // 槽位在父容器里的 id / 位置不变，Flutter element 因而不重建 —— 这是
  // TabBarView 声明式 children 能保持当前页不白屏的关键（早期「先占位再替换
  // 结点」的实现会换掉当前页的 element key，整页被重新 inflate 成空白）。
  //
  // 懒槽位覆盖两类位置（slot.kind）：
  //   - children：容器的有序子结点（builder 展开 / `__items`），位置由 insert 下发；
  //   - prop：props 里的 widget 数组（`TabBarView(children: [...])` /
  //     `PageView(children: [...])`），位置由 propsChildren 下发。
  //
  // **是否懒由元素自己声明**：`el.lazyChildren === true`，由生成的 `__h`
  // （flutter.js）按构建期配置打标。运行时**零类型知识**——不认识 PageView /
  // TabBarView / ListView，也不维护任何类型表；新增懒容器只改生成器配置
  // （shared/js_class_defs.dart）并重出产物，运行时代码不动。

  // 子项来源：`{el}` = 已创建的 element，`{make}` = 延迟生成（懒容器下的
  // builder 子项，宿主 inflate 到占位时才调用）。
  //
  // builder 只消费产物里的**显式形态协议**，不按类型名、不猜属性名——
  //   1) 命名构造（`.builder` / `.separated`）由生成的 JS 代理类下发
  //      `children.__builder = {item, sep, count, ctx}`（内部键，由 __h 归入
  //      children）；
  //   2) `delegate: SliverChildBuilderDelegate(...)` 由生成器译成
  //      `{__delegate:'builder', builder, childCount}` 放进 `children.delegate`。
  // 未来新增自定义滚动容器只要沿用上述任一协议即可，运行时无需登记类型。
  //
  // **懒容器下绝不在这里调用 builder**：每次展开 N 项会把所有子组件的构造
  // （控制器 / 监听器）都跑一遍，与 Flutter `ListView.builder` 只构造可见项
  // 不一致；故每项只带延迟工厂，真正执行推迟到 `__lazyMount`。
  // builder 回调协议只有**一种形态：闭包（函数）**。方法 tear-off 在构建期统一
  // 生成绑定闭包（`this` 由词法作用域固定），因此运行时不需要「找拥有者方法」
  // 这一层——少一条静默失败路径（找不到方法 → 空列表白屏）。
  function __builderSpec(el) {
    var slots = el.__children || {};
    var b = slots.__builder;
    if (b && typeof b.item === 'function' && typeof b.count === 'number') {
      return { item: b.item, sep: typeof b.sep === 'function' ? b.sep : null, count: b.count, ctx: b.ctx };
    }
    var d = slots.delegate;
    if (!d || d.__delegate !== 'builder' || typeof d.builder !== 'function') {
      return null;
    }
    var n = d.childCount;
    if (typeof n !== 'number' || n <= 0) { return null; }
    return { item: d.builder, sep: null, count: n, ctx: null };
  }

  // 第 [slotIndex] 个子结点（`.separated` 按 item/separator 交替展开）。
  // 传给 builder 的 `context` 形参：命名构造优先用代理 build 收到的那个
  // （与原行为一致），delegate 形态用拥有者组件的代理。
  function __buildItem(owner, spec, slotIndex) {
    var ctx = spec.ctx || __contextOf(owner);
    var out = null;
    // 委托调用期间 owner 锚点指向 builder 所属组件实例：builder 里创建的
    // 控制器 / Key 归属它（`__building` 在这里可能是宿主结点或已还原）。
    __withOwner(owner, function () {
      var sep = spec.sep;
      if (sep && slotIndex % 2 === 1) {
        out = sep(ctx, (slotIndex - 1) / 2);
      } else {
        out = spec.item(ctx, sep ? slotIndex / 2 : slotIndex);
      }
    });
    return out;
  }

  function __childSources(el, parent, lazy) {
    var slots = el.__children || {};
    var pre = slots.__items;
    var out = [];
    var i;
    if (Array.isArray(pre)) {
      for (i = 0; i < pre.length; i++) { out.push({ el: pre[i] }); }
      return out;
    }
    var spec = __builderSpec(el);
    if (!spec) { return out; }
    // 闭包自带接收者，展开时只需要锚点做句柄归属（parent 即拥有者实例）。
    var owner = parent || null;
    var total = spec.sep ? Math.max(0, spec.count * 2 - 1) : spec.count;
    for (i = 0; i < total; i++) {
      if (lazy) {
        out.push({ make: (function (idx, ow) {
          return function () { return __buildItem(ow, spec, idx); };
        })(i, owner) });
      } else {
        // 非懒容器：保持原语义，一次性展开全部子结点。
        out.push({ el: __buildItem(owner, spec, i) });
      }
    }
    return out;
  }

  // 宿主结点索引（id → 结点实例）：只为「宿主上报 inflate」的反查用（懒槽位）。
  var __hostNodes = {};
  // 组件结点索引（id → 组件实例）：宿主挂载组件 wrapper 时按 id 同步拉取
  // build（见 __pullComponent）。
  var __compNodes = {};

  // 挂载事务帧：记录本次尝试新增的宿主结点与组件实例，失败时**按帧**精确回滚
  // （见 __lazyMount 的 catch）。不能按 `__root` 清扫——那是整页根，会误伤同页
  // 其他已挂载的子树（整页回滚是 __mountRoot 的 __abortRoot，二者不要混用）。
  // 只在 __lazyMount 期间非空：正常挂载路径只多一次 length 判断。
  var __mountFrames = [];
  function __beginMountFrame() {
    var frame = { nodes: [], insts: [] };
    __mountFrames.push(frame);
    return frame;
  }
  function __endMountFrame(frame) {
    var i = __mountFrames.lastIndexOf(frame);
    if (i >= 0) { __mountFrames.splice(i, 1); }
  }
  function __trackNode(id) {
    if (__mountFrames.length) {
      __mountFrames[__mountFrames.length - 1].nodes.push(id);
    }
  }
  function __trackInst(inst) {
    if (__mountFrames.length) {
      __mountFrames[__mountFrames.length - 1].insts.push(inst);
    }
  }

  // 回滚一个挂载事务帧：逆序 teardown 本次挂载的组件实例（__markUnmounted 会递归
  // 释放 `__owns` / `__ctx` / 宿主函数句柄、退订并删掉已挂树的宿主结点），
  // 再补齐「父结点 mount 尚未返回、因而没进任何 `__children`」的宿主结点 id。
  // 宿主侧此时 commit 未发生（create/insert 随丢弃的 ops 一起没下发），故不需要
  // 发 remove；占位结点的 `__deferred` / props 都未改动，下次 inflate 可重试。
  function __rollbackMountFrame(frame) {
    var i;
    for (i = frame.insts.length - 1; i >= 0; i--) {
      var inst = frame.insts[i];
      if (inst && !inst.__unmounted) { __markUnmounted(inst); }
    }
    for (i = 0; i < frame.nodes.length; i++) {
      var node = __hostNodes[frame.nodes[i]];
      if (node) {
        delete __hostNodes[frame.nodes[i]];
        node.__unmounted = true;
      }
    }
  }

  // 宿主回调句柄：runtime 级常驻（scope=local 且不同步宿主——宿主只拿它的 id 走
  // 事件 invoke 通道回调，本端不需要留镜像）。
  //   - __lazyMount：宿主 element **inflate**（首次布局到该槽位）；
  //   - __lazyUnmount：宿主 element **dispose**（ListView 回收离屏项 / 页面销毁）——
  //     与 Flutter 同寿：离屏项的 State 被销毁，滚回来再 initState 重新构建。
  //     没有这条通知，JS 侧挂过的 item 会永远活着（滚到底后每次重建都在 patch
  //     全量 item），列表越长越糟。
  //     宿主侧在 dispose（finalizeTree 的 lockState 内）不直接回调，而是延后到
  //     post-frame 再发——本方法会同步 commit 回来重建**存活**的父结点，
  //     锁定期 setState 会触发框架断言（见 _JsPlainNodeHostState._unmountIfLazy）。
  var __lazyMountFn = __createFnHandle(function (id) { __lazyMount(id); });
  var __lazyUnmountFn = __createFnHandle(function (id) { __lazyUnmount(id); });

  // 懒槽位占位结点：普通宿主结点（SizedBox 0x0）+ `__lazy` 数据标记 + 回调句柄；
  // 子元素来源先挂在占位实例上（`src.el` 元素 / `src.make` 延迟工厂），本帧不挂载。
  function __newLazySlot(parent, src, slot) {
    // 占位结点沿用子元素的声明式 key：父级重建时按 key 复用槽位，宿主侧
    // element key 也不会因占位/真实切换而变化（延迟工厂形态此时拿不到 key）。
    var props = {
      width: 0, height: 0, __lazy: true,
      __lazyFn: __lazyMountFn, __lazyOffFn: __lazyUnmountFn
    };
    if (src && src.el && src.el.props && src.el.props.key !== undefined) {
      props.key = src.el.props.key;
    }
    var hi = {
      __k: __HOST, __id: __nextNodeId('SizedBox'), __type: 'SizedBox',
      __root: __rootOf(parent),
      __props: props,
      __children: [], __parent: parent, __slot: slot,
      __deferred: src ? src.el : null,
      __deferMake: src ? src.make : null,
      __lazySlot: true
    };
    __hostNodes[hi.__id] = hi;
    __trackNode(hi.__id);
    __emitOp({ op: 'create', id: hi.__id, type: hi.__type, props: hi.__props });
    if (slot && slot.kind === 'children' && slot.hostParentId) {
      __emitOp({ op: 'insert', parent: slot.hostParentId, id: hi.__id, index: slot.index });
    }
    return hi;
  }

  // 懒槽位当前的子元素来源 → element（未挂载时按需调用延迟工厂）。
  function __lazyElementOf(src) {
    if (!src) { return null; }
    if (src.el !== undefined) { return src.el; }
    return src.make ? src.make() : null;
  }

  // 子树内是否有组件声明「保持存活」：与 Flutter 的 KeepAliveNotification 同语义
  // ——子树中任意 State（AutomaticKeepAliveClientMixin）都能把整棵懒槽位保活。
  // 只认实例上的 `wantKeepAlive` 布尔声明，运行时不做类型判断。
  //
  // **不越过嵌套懒槽位**：内层懒槽位（如页面里的 ListView 子项）的保活声明由它
  // 自己的占位结点负责（Flutter 里通知也只冒泡到最近的 AutomaticKeepAlive），
  // 否则内层 item 的声明会把整页错误地保活。
  function __subtreeWantsKeepAlive(inst) {
    if (!inst) { return false; }
    if (inst.__k !== __HOST) {
      if (inst.wantKeepAlive === true) { return true; }
      return __subtreeWantsKeepAlive(inst.__child);
    }
    if (inst.__lazySlot) { return false; }
    var i;
    var cs = inst.__children || [];
    for (i = 0; i < cs.length; i++) {
      if (__subtreeWantsKeepAlive(cs[i])) { return true; }
    }
    var pcs = inst.__propsChildren;
    if (pcs) {
      for (var k in pcs) {
        if (__subtreeWantsKeepAlive(pcs[k])) { return true; }
      }
    }
    var pcl = inst.__propsChildrenList;
    if (pcl) {
      for (var lk in pcl) {
        var arr = pcl[lk] || [];
        for (i = 0; i < arr.length; i++) {
          if (__subtreeWantsKeepAlive(arr[i])) { return true; }
        }
      }
    }
    return false;
  }

  // 把当前已挂载子树的 keep-alive 声明同步到占位结点 props（幂等）。
  // 声明变化必须下发 props op：宿主 _JsPlainNodeHost 收到补丁后重建，build 里
  // updateKeepAlive() 才会真正注册 / 释放 KeepAlive。
  function __syncKeepAlive(ph) {
    var wants = __subtreeWantsKeepAlive(ph.__mountedChild);
    var has = !!(ph.__props && ph.__props.__keepAlive);
    if (wants === has) { return; }
    ph.__props = ph.__props || {};
    if (wants) {
      ph.__props.__keepAlive = true;
    } else {
      delete ph.__props.__keepAlive;
    }
    __emitOp({ op: 'props', id: ph.__id, props: ph.__props });
    // 占位结点的 keepAlive 声明参与宿主侧 build（wantKeepAlive getter），
    // 变化后必须重建这个 wrapper。
    __emitOp({ op: 'rebuild', id: ph.__id });
  }

  // 组件自身重建（setState → flush）后，把变更同步给**最近的**懒槽位：
  // 与 Flutter 一致，保活声明的生效范围是「最近的 AutomaticKeepAlive 祖先」，
  // 所以向上找第一个 `__lazySlot` 占位结点即可（不越级影响外层槽位）。
  // 没有懒槽位祖先（如页面根组件）时什么也不做。
  function __syncEnclosingKeepAlive(inst) {
    var p = inst;
    while (p) {
      if (p.__lazySlot) {
        __syncKeepAlive(p);
        return;
      }
      p = p.__parent;
    }
  }

  // 父级重建时更新一个**已存在**的懒槽位（幂等，绝不在这里做首次挂载）：
  // 未挂载的只替换来源；已挂载的把新元素 patch 到真实子树上，渲染根 id 变化
  // 时更新占位结点的 `child` slot（与 propsChildAt 同语义）。
  // 两个分支都刷新来源：宿主 dispose 后槽位要按**最新**来源重新生成（see
  // __lazyUnmount），旧快照会让滚回来的 item 渲染成旧 props。
  function __patchLazySlot(ph, src) {
    ph.__deferred = src ? src.el : null;
    ph.__deferMake = src ? src.make : null;
    if (!ph.__mountedChild) {
      return ph;
    }
    var el = __lazyElementOf(src);
    if (el == null || el === false) {
      // builder 返回空属错误写法（Flutter 侧会直接抛错）：保留已挂载子树并留痕。
      __warn('jsui: lazy slot builder returned empty, keep mounted subtree');
      return ph;
    }
    // 与原生 Flutter 对齐：父级每次重建都会重新执行 itemBuilder，并把产出的新
    // 元素 patch 到已挂载的子树上——组件照常进 didUpdateWidget / build。
    // **不能**按「产出元素内容相同」短路：那会吞掉 didUpdateWidget 的副作用。
    // 例外只有引用相同（`const` 构造的同一实例，见 patch 的 `__el` 判等），
    // 此时与原生 `Element.updateChild` 的 `child.widget == newWidget` 一致。
    var oldRoot = ph.__mountedRootId;
    ph.__mountedChild = __patch(ph.__mountedChild, el, ph, null);
    var newRoot = __nodeIdOf(ph.__mountedChild);
    if (newRoot !== oldRoot) {
      ph.__mountedRootId = newRoot;
      ph.__propsChildren['child'] = ph.__mountedChild;
      __emitOp({ op: 'propsChild', parent: ph.__id, key: 'child', childId: newRoot });
      // 占位结点的 child 槽换了：重建这个懒槽位 wrapper。
      __emitOp({ op: 'rebuild', id: ph.__id });
    }
    // 父级重建路径的保活声明同步（组件自身 setState 引起的变化走 flush 的
    // __syncEnclosingKeepAlive，见【9】）。
    __syncKeepAlive(ph);
    return ph;
  }

  // 宿主 inflate 到懒槽位 → 真正挂载它的子元素（幂等：只对还没挂载过的占位生效）。
  // ops 纪律与 __mountRoot 一致：挂载期间 `root.ops` 归本次挂载累积，挂载期间的
  // setState 只入 dirty 队列，收尾再 flush（见【9】）。
  function __lazyMount(placeholderId) {
    var ph = __hostNodes[placeholderId];
    if (!ph || (!ph.__deferred && !ph.__deferMake)) { return false; }
    // 延迟工厂（builder 子项）在这里才执行：全树只展开「宿主真正 inflate 到」的那些。
    var el = ph.__deferred;
    if (el == null && ph.__deferMake) { el = ph.__deferMake(); }
    if (el == null || el === false) {
      __warn('jsui: lazy slot builder returned empty, placeholder=' + placeholderId);
      return false;
    }
    // 来源**保留**：宿主 dispose（ListView 回收离屏项）后还要按同一来源重建，
    // 见 __lazyUnmount。
    var root = ph.__root || __rootOf(ph.__parent);
    if (!root) { return false; }
    var prev = __activeRoot;
    __activeRoot = root;
    root.mounting = true;
    root.ops = [];
    var frame = __beginMountFrame();
    var ok = true;
    try {
      // 真实子树的父结点是**占位结点**（宿主侧同样的父子关系），作用域链 /
      // BuildContext 锚点与「直接挂在容器下」一致。
      var inst = __mount(el, ph, null);
      ph.__mountedChild = inst;
      ph.__mountedRootId = __nodeIdOf(inst);
      ph.__propsChildren = ph.__propsChildren || {};
      ph.__propsChildren['child'] = inst;
      // 占位从「零尺寸空隙」变为「透传容器」：只去掉尺寸，**保留**懒槽位标记与
      // 回调句柄——宿主 element 再次 dispose 时要靠 `__lazyOffFn` 反查，重新
      // inflate 时也要靠 `__lazy` 重新回调 __lazyMount。占位结点本身保留
      //（id / element key 不变），父容器不需要任何列表换位。
      var mountedProps = { __lazy: true, __lazyFn: __lazyMountFn, __lazyOffFn: __lazyUnmountFn };
      if (ph.__props && ph.__props.key !== undefined) { mountedProps.key = ph.__props.key; }
      // 保活声明随挂载一起下发：宿主 _JsPlainNodeHost 据此注册 KeepAlive，切走 tab 时
      // element 不被销毁 → 不会回调 __lazyUnmount，JS 侧 State 与已加载数据保留。
      if (__subtreeWantsKeepAlive(inst)) { mountedProps.__keepAlive = true; }
      ph.__props = mountedProps;
      __emitOp({ op: 'props', id: ph.__id, props: ph.__props });
      __emitOp({ op: 'propsChild', parent: ph.__id, key: 'child', childId: ph.__mountedRootId });
      // 占位结点现在有了 child：重建这个懒槽位 wrapper。
      __emitOp({ op: 'rebuild', id: ph.__id });
      __commitOps(root);
    } catch (e) {
      // 本次尝试失败：commit 未发生，宿主侧没有半棵树（create/insert 随 ops 一起
      // 丢弃），故不需要发 remove；只回滚 JS 侧**本次新增**的结点与句柄。
      // 占位的 `__deferred` / `__deferMake` / props 都没改过（props 在挂载成功后
      // 才 emit），宿主下次 inflate 仍会回调到这里重试。
      ok = false;
      __rollbackMountFrame(frame);
      root.ops = null;
      __error('jsui: lazy slot mount failed, placeholder=' +
        placeholderId + ': ' + e);
    } finally {
      __endMountFrame(frame);
      root.mounting = false;
      __activeRoot = prev;
    }
    // 挂载期间累积的 setState（如 initState 里同步 setState）补一次 flush。
    // 失败路径里本次实例已被回滚标成 __unmounted，flush 的 `continue` 会跳过；
    // 不能清 root.dirty —— 其中可能还有同页其他组件已入队的重建。
    if (root.dirty.length) { __flushNow(root); }
    return ok;
  }

  // 宿主 element dispose（ListView 回收离屏项 / 页面销毁）→ 卸载已挂载的子树，
  // 槽位本身与来源保留；宿主再次 inflate 时 __lazyMount 按来源重新构建（与 Flutter
  // 「离屏项 State 销毁、滚回再 initState」一致）。幂等：未挂载的槽位直接跳过。
  function __lazyUnmount(placeholderId) {
    var ph = __hostNodes[placeholderId];
    if (!ph || !ph.__mountedChild) { return false; }
    var root = ph.__root || __rootOf(ph.__parent);
    if (!root) { return false; }
    var inst = ph.__mountedChild;
    ph.__mountedChild = null;
    ph.__mountedRootId = null;
    if (ph.__propsChildren) { delete ph.__propsChildren['child']; }
    var prev = __activeRoot;
    __activeRoot = root;
    root.mounting = true;
    root.ops = [];
    try {
      // 已卸载：撤下 keep-alive 声明（下次挂载按新实例重新评估，避免带着旧声明
      // 让新建 element 在未挂载时就被保活）。
      if (ph.__props && ph.__props.__keepAlive) {
        delete ph.__props.__keepAlive;
        __emitOp({ op: 'props', id: ph.__id, props: ph.__props });
      }
      // unmount 派发 deactivate → dispose，并下发子树 remove；宿主侧的 element
      // 已随本次 dispose 一起销毁，store 按 remove 递归摘除结点。
      __unmount(inst);
      __emitOp({ op: 'propsChildRemove', parent: ph.__id, key: 'child' });
      // 占位结点的 child 槽已清空：重建这个懒槽位 wrapper。
      __emitOp({ op: 'rebuild', id: ph.__id });
      __commitOps(root);
    } finally {
      root.mounting = false;
      __activeRoot = prev;
    }
    if (root.dirty.length) { __flushNow(root); }
    return true;
  }

  // 在 [inst] 的 build 执行期间把锚点指向它 —— 事件绑定据此拿到「当前构建位置」。
  // 按 Dart 签名把 BuildContext 代理**传进去**：`build(context)`。
  //
  // `inst.__building` 标记「本实例正处在 build 执行期」，供 __markDirty 拦截
  // build 内 setState（见【9】）。**不能用锚点代替**：initState / didUpdateWidget
  // 期间锚点也指向本实例，那两个阶段 setState 是合法写法。
  function __buildOf(inst) {
    return __withBuilding(inst, function () {
      inst.__building = true;
      try { return inst.build(__contextOf(inst)); }
      finally { inst.__building = false; }
    });
  }

  // 宿主元素判据：字符串 type（Component.host 产物），或 Component 构造写入
  // `__host=true` 的宿主包装类（只继承 Component 的空 build）。
  // JS 组件（含继承 InheritedWidget 基类、自身不重写 build 的翻译类）为 false。
  function __isHostElement(el) {
    var T = el.__type;
    if (typeof T === 'string') { return true; }
    return el.__host === true;
  }

  // 宿主结点类型名：字符串直接用；包装类用类名（类名 === 宿主类型名）。
  function __hostTypeName(el) {
    var T = el.__type;
    return typeof T === 'string' ? T : T.name;
  }

  function __mount(el, parent, slot) {
    if (el == null || el === false) { return null; }

    if (__isHostElement(el)) {
      var hostType = __hostTypeName(el);
      var hi = {
        __k: __HOST, __id: __nextNodeId(hostType), __type: hostType,
        __root: __rootOf(parent), __props: null,
        __children: [], __parent: parent, __el: el
      };
      // 宿主 props 里的函数值在这里换成句柄（唯一的句柄创建点）。
      hi.__props = __hostProps(hi, el.props || {}, el.__anchor || null, __hostFnNamesOf(el));
      __hostNodes[hi.__id] = hi;
      __trackNode(hi.__id);
      __attachKeyContext(hi);
      __emitOp({ op: 'create', id: hi.__id, type: hi.__type, props: hi.__props });
      if (slot && slot.hostParentId) {
        __emitOp({ op: 'insert', parent: slot.hostParentId, id: hi.__id, index: slot.index });
      }
      var idx = 0;
      // 懒容器（如 TabBarView / ListView.builder(itemExtent:)）的 children 先只
      // 下发零尺寸占位（见 __newLazySlot）：真实子树等宿主 inflate 到该槽位时
      // 回调再挂；builder 形态连 itemBuilder 的调用也一并推迟（见 __childSources）。
      // 懒标记在元素构造期已由 Component / 包装类声明写好，运行时不做类型判断。
      var lazyChildren = el.lazyChildren === true;
      var srcs = __childSources(el, hi, lazyChildren);
      for (var i = 0; i < srcs.length; i++) {
        var src = srcs[i];
        if (!lazyChildren && (src.el == null || src.el === false)) { continue; }
        var c = lazyChildren
            ? __newLazySlot(hi, src, { kind: 'children', hostParentId: hi.__id, index: idx })
            : __mount(src.el, hi, { hostParentId: hi.__id, index: idx });
        if (c) { hi.__children.push(c); idx += 1; }
      }
      // props 里的 widget（单值 / 数组）与 delegate：单独挂载，不入 flatten
      // 列表，各自按 prop 名缓存（Scaffold.body / AppBar.actions 等）。
      hi.__propsChildren = {};
      hi.__propsChildrenList = {};
      hi.__propsData = {};
      __patchPropSlots(hi, el.__children || {}, lazyChildren);
      return hi;
    }

    var ownFrame = __beginConstruct();
    var ci;
    var C = el.__type;
    try {
      // 组件元素有两种来源，都带 `__element: true`：
      //   1. 翻译层 `new X(props)` 产出的 `Component` 实例（实例即元素）；
      //   2. `__h(类, props)` 产出的元素描述（还没有实例，builder 代理走这条）。
      // 只有「实例且未挂上树、未卸载」时才直接复用；同一实例出现在两个槽位时
      // （Dart 允许）按 props 再构造一份，避免状态串位。
      ci = (el instanceof C && !el.__unmounted && !el.__parent)
          ? el
          : new C(el.props);
    } catch (e) {
      __endConstruct(null, ownFrame);
      throw e;
    }
    ci.__k = __COMP;
    ci.__id = __nextComponentId(C);
    // 构造期（字段初始化）里登记的控制器 / Key 句柄归属本实例：此刻 `ci` 才存在，
    // 故构造期间先暂存、新对象返回后再回填（见 handle_registry_js 的 __beginConstruct）。
    __endConstruct(ci, ownFrame);
    // 记入挂载事务帧（若有）：构造已成功、控制器等句柄已归属本实例，之后
    // initState / didChangeDependencies / build 任何一步抛错都要按帧回收。
    __trackInst(ci);
    ci.__parent = parent;
    ci.__slot = slot;
    ci.__root = __rootOf(parent);
    __compNodes[ci.__id] = ci;
    __attachKeyContext(ci);
    // InheritedWidget 子类：按**类名**登记为继承结点（对应 InheritedElement），
    // 子孙的 `context.get/dependOnInheritedWidgetOfExactType` 据此查找。
    if (typeof ci.updateShouldNotify === 'function') {
      __inheritElement(ci, __componentName(C));
    }
    // 生命周期：initState 仍在**挂载期**执行（与 Flutter 一致，它不依赖继承
    // 上下文，控制器 / 监听器在这里登记归属本实例）；didChangeDependencies 与
    // build 一并推迟到 [__pullComponent] —— 由宿主的组件 wrapper 在 element 挂载
    // 时同步拉起。这样 build 执行时 BuildContext 锚点已经登记，
    // `MediaQuery.of(context)` / `context.watch` 首帧就能读到真值。
    ci.__built = false;
    ci.__depsDone = false;
    __withBuilding(ci, function () {
      if (typeof ci.initState === 'function') { ci.initState(); }
    });
    // 组件结点占住父槽：宿主据此为它建一个挂载边界（wrapper），并在 wrapper 的
    // build 里同步拉取 build 结果（见 __pullComponent）。
    // `hasBuild: true` = 元素所属类**重写了 build**（__COMP 结点）：宿主要为它建
    // 挂载边界并在 element 挂载时驱动 build。宿主包装类没有重写 build，不带本标记。
    __emitOp({ op: 'create', id: ci.__id, type: __componentName(C), hasBuild: true });
    if (slot && slot.hostParentId) {
      __emitOp({ op: 'insert', parent: slot.hostParentId, id: ci.__id, index: slot.index });
    }
    return ci;
  }

  // 宿主 element 挂载 → **同步拉取**组件的首次 build 结果。
  //
  // 调用点：宿主给每个组件结点建 wrapper，wrapper 在 build 里同步 evaluate
  // `__jsui.pull(pageKey, id)`。此刻该组件的 BuildContext 锚点已由 wrapper 登记，
  // 所以 build 里的上下文读取（MediaQuery / provider …）拿的是真值，不再依赖
  // 「build 早于挂载」的兜底缓存。
  //
  // 返回：本次 build 产生的补丁（JSON 数组；空数组 = 无补丁）。build 抛错时返回
  // `{"error": "…"}`，宿主据此渲染明确的错误视图（不静默降级）。
  function __pullComponent(pageKey, compId) {
    var root = __roots[pageKey];
    var inst = __compNodes[compId];
    if (!root || !inst || inst.__unmounted) { return []; }
    if (inst.__built) { return []; }
    if (root.mounting || root.flushing) {
      __error('jsui: component pull re-entered during mount/flush: ' + compId);
      return { error: '组件 build 与挂载/flush 重入: ' + compId };
    }
    var prevRoot = __activeRoot;
    __activeRoot = root;
    root.ops = [];
    var frame = __beginMountFrame();
    var error = null;
    var ops = null;
    try {
      // 继承依赖：与 Flutter 的重建语义一致——每次 build 前重新收集依赖，
      // 旧边先摘掉（didChangeDependencies 里也能重新登记）。
      __clearDependencies(inst);
      if (!inst.__depsDone) {
        inst.__depsDone = true;
        __withBuilding(inst, function () {
          if (typeof inst.didChangeDependencies === 'function') {
            inst.didChangeDependencies();
          }
        });
      }
      inst.__child = __mount(__buildOf(inst), inst, null);
      var rootId = __renderRootIdOf(inst);
      if (rootId == null) {
        error = '组件 build 未产出任何结点: ' + __componentName(inst.constructor);
      } else {
        inst.__built = true;
        __emitOp({ op: 'propsChild', parent: inst.__id, key: 'child', childId: rootId });
      }
      // 子树里的 keep-alive 声明随挂载同步到最近的懒槽位（与 __lazyMount 同义）。
      __syncEnclosingKeepAlive(inst);
      ops = root.ops;
    } catch (e) {
      error = (e && e.message ? e.message : String(e));
    } finally {
      __endMountFrame(frame);
      root.ops = null;
      __activeRoot = prevRoot;
    }
    if (error != null) {
      // build 失败：按帧回滚本次新增的结点 / 句柄（宿主尚未 commit，无需 remove）。
      inst.__built = false;
      inst.__child = null;
      __rollbackMountFrame(frame);
      __error('jsui: component build failed (' + compId + '): ' + error);
      return { error: error };
    }
    return ops || [];
  }

  function __patch(oldInst, el, parent, slot, propSlot) {
    if (el == null || el === false) {
      if (oldInst) { __unmount(oldInst); }
      return null;
    }
    if (!oldInst) {
      var mi = __mount(el, parent, slot);
      if (mi && propSlot) { mi.__propSlot = propSlot; }
      return mi;
    }

    // 对齐 Flutter `Element.updateChild` 的 `child.widget == newWidget` 短路：
    // 元素就是实例本身，引用相同才短路（const 构造在 JS 侧 hoist 成同一实例）。
    // 绝不做 props 值比较——非 const 子组件即使 props 完全相同，父级重建时也必须
    // 走 didUpdateWidget（见 __patchLazySlot 的约定）。
    if (oldInst === el) {
      if (propSlot) { oldInst.__propSlot = propSlot; }
      return oldInst;
    }

    var newIsHost = __isHostElement(el);
    var newHostType = newIsHost ? __hostTypeName(el) : null;
    var oldIsHost = (oldInst.__k === __HOST);
    var sameType = oldIsHost
      ? (newIsHost && oldInst.__type === newHostType)
      : (!newIsHost && oldInst.constructor === el.__type);
    // 与 Flutter `Widget.canUpdate` 完全对齐：**类型相同且 key 相同**才复用。
    // 单子槽（`child:` / 组件渲染根）没有 __keyedMatcher 兜着，少判 key 就会把旧
    // 结点连同它的生命周期（已 hide 的 controller、已跑完的定时器等）复用到新的
    // widget 上——key 形同虚设，与原生行为不一致。列表槽的 key 匹配见
    // [__keyedMatcher]，这里是单结点路径的唯一判据。
    if (!sameType ||
        __keySig(__nodeKeyOf(oldInst)) !== __keySig(el.props ? el.props.key : null)) {
      __unmount(oldInst);
      return __mount(el, parent, slot);
    }

    if (oldIsHost) {
      var oldProps = oldInst.__props;
      // 先按新元素折算（函数 → 结点上已缓存的同一句柄，只更新实现），再比较。
      var newProps = __hostProps(oldInst, el.props || {}, el.__anchor || null, __hostFnNamesOf(el));
      if (!__propsEqual(oldProps, newProps)) {
        __emitOp({ op: 'props', id: oldInst.__id, props: newProps });
      }
      oldInst.__props = newProps;
      oldInst.__el = el;
      // 子项来源按新元素声明的懒标记生成：懒容器下 builder 形态只带延迟工厂，
      // 已挂载的槽位由 __patchLazySlot 现场调用工厂重建该项。
      var lazyChildren = el.lazyChildren === true;
      __patchChildren(oldInst, __childSources(el, oldInst, lazyChildren), lazyChildren);
      __patchPropSlots(oldInst, el.__children || {}, lazyChildren);
      return oldInst;
    }

    // 复用同一实例（= Flutter 的 State 复用），只替换 element（= 新 Widget）。
    // 先取旧 props 作为 oldWidget 快照（el.props 每次 build 都是新对象，故旧引用
    // 自然保留），再把新 props 落到实例（`widget` 即新值），然后以旧 props 回调
    // didUpdateWidget，最后 build——顺序与 Flutter 完全一致。
    var oldWidget = oldInst.props;
    oldInst.props = el.props;
    // props 变更 → 重新派生「构造参数字段」。生成器产物把 `this.x = args.x` 的
    // 参数↔字段映射放在 `__applyProps` 里；复用实例不会重跑构造函数，若不在此
    // 同步一次，子组件会一直拿着旧 props 派生的字段（如列表项不随排序刷新）。
    if (typeof oldInst.__applyProps === 'function') {
      oldInst.__applyProps(el.props);
    }
    // 首次 build 尚未由宿主拉起（wrapper 还没挂载）：只同步 props，didUpdateWidget
    // 在「已构建」之后才有意义；build 由 __pullComponent 读取最新 props 后执行。
    if (!oldInst.__built) { return oldInst; }
    // 继承依赖：与 Flutter 一样，重建时重新收集（旧边先摘掉）。
    __clearDependencies(oldInst);
    // InheritedWidget：props 变更后按 `updateShouldNotify(oldWidget)` 决定是否
    // 通知依赖者（对应 InheritedElement.update → notifyClients）。
    if (typeof oldInst.updateShouldNotify === 'function') {
      var shouldNotify = false;
      try {
        shouldNotify = oldInst.updateShouldNotify(__oldWidgetOf(oldInst, oldWidget)) === true;
      } catch (e) {
        __error('jsui: updateShouldNotify failed (' +
          __componentName(oldInst.constructor) + '): ' + e);
      }
      if (shouldNotify) { __notifyClients(oldInst); }
    }
    // didUpdateWidget 期间把构建锚点指向本实例（新建句柄的归属 / this.context）。
    __withBuilding(oldInst, function () { oldInst.didUpdateWidget(oldWidget); });
    __patchComponentChild(oldInst);
    return oldInst;
  }

  // `InheritedWidget.updateShouldNotify(oldWidget)` 的旧值视图：不重跑构造副作用，
  // 只在同原型对象上按 `__applyProps` 派生旧 props，字段读取与 Dart 同义。
  function __oldWidgetOf(inst, oldProps) {
    var view = Object.create(inst.constructor.prototype);
    view.props = oldProps;
    if (typeof view.__applyProps === 'function') { view.__applyProps(oldProps); }
    return view;
  }

  /// 组件 build 出新子树，并在渲染根 id 变化时回报它自己的 `child` 槽。
  function __patchComponentChild(inst) {
    if (!inst.__built) { return null; }
    var oldRoot = __renderRootIdOf(inst);
    inst.__child = __patch(inst.__child, __buildOf(inst), inst, null);
    var newRoot = __renderRootIdOf(inst);
    if (newRoot !== oldRoot) {
      if (newRoot == null) {
        // build 返回空只可能来自产物缺陷：Dart 的 `Widget build()` 必返回 Widget。
        // 宿主侧 propsChildAt 的 childId 为空无法落位，这里必须出声，不静默。
        __error('jsui: component render root is empty after build (' +
          __componentName(inst.constructor) + ')');
        return inst.__child;
      }
      __emitOp({
        op: 'propsChildAt', parent: inst.__id, key: 'child',
        index: 0, childId: newRoot
      });
    }
    return inst.__child;
  }

  // 子项 keyed 匹配器（`__patchChildren` / `__patchSlotList` 共用**唯一一份**实现）。
  //
  // 旧实现每个子项都做「线性扫 remaining + splice + indexOf」→ O(n²)：100 项列表
  // 每次重建约 1 万次比较、100 次数组搬移。这里一次建索引，之后每项 O(1)：
  //   - 带 key：`__keySig` → 实例（同签名只认领一个，重复 key 按新建处理）；
  //   - 无 key：按旧序游标推进（保持「位置优先」的复用语义）；
  //   - 位置：`__id` → 旧下标，move 判定不再 `indexOf`。
  //
  // `take(ek)` 返回本轮可复用的旧实例（没有则 null）；`leftovers()` 返回未被
  // 认领的旧实例（调用方负责 unmount）。
  function __keyedMatcher(oldList) {
    var byKey = {};
    var unkeyed = [];
    var posById = {};
    var consumed = {};
    var i;
    for (i = 0; i < oldList.length; i++) {
      var inst = oldList[i];
      if (!inst) { continue; }
      if (inst.__id != null) { posById[inst.__id] = i; }
      var k = __keySig(__nodeKeyOf(inst));
      if (k != null) {
        // 同一签名的 key 只认领一个旧结点：重复 key（Dart 侧本就是错误写法）时
        // 另一个按新建处理，绝不让同一实例被挂两次（会串坏 __parent/__slot）。
        if (byKey[k] === undefined) { byKey[k] = inst; }
      } else {
        unkeyed.push(inst);
      }
    }
    var cursor = 0;
    return {
      take: function (ek) {
        var m = null;
        if (ek != null) {
          m = byKey[ek] || null;
          byKey[ek] = null;
        } else {
          while (cursor < unkeyed.length && !unkeyed[cursor]) { cursor += 1; }
          m = unkeyed[cursor] || null;
          if (m) { unkeyed[cursor] = null; }
        }
        if (m && m.__id != null) { consumed[m.__id] = true; }
        return m;
      },
      positionOf: function (inst) {
        var p = inst && inst.__id != null ? posById[inst.__id] : undefined;
        return p === undefined ? -1 : p;
      },
      leftovers: function () {
        var out = [];
        for (var n = 0; n < oldList.length; n++) {
          var it = oldList[n];
          if (it && !(it.__id != null && consumed[it.__id])) { out.push(it); }
        }
        return out;
      }
    };
  }

  // [srcs] 是子项来源（见 __childSources）：`{el}` 直接元素 / `{make}` 延迟工厂。
  // [lazy] 来自新元素的 `el.lazyChildren`（运行时不做类型判断）。
  function __patchChildren(parentHost, srcs, lazy) {
    var old = parentHost.__children || [];
    var matcher = __keyedMatcher(old);
    var next = [];
    var hostIdx = 0;
    var i, j;
    for (j = 0; j < srcs.length; j++) {
      var src = srcs[j];
      if (!src) { continue; }
      var el = src.el !== undefined ? src.el : null;
      // 延迟工厂形态在展开前没有 element（也没有 key），只能按位置匹配。
      if (src.el !== undefined && (el == null || el === false)) { continue; }
      var ek = __keySig(el && el.props ? el.props.key : null);
      var matched = matcher.take(ek);

      // 已存在的懒槽位（未挂载的来源 / 已挂载的 `__mountedChild`）→ 只更新子元素，
      // **绝不能**在这里把未挂载的槽位挂出来，否则重建（外壳每次切 tab 都会整树
      // patch）会把懒加载整个破坏掉。
      if (matched && lazy && matched.__lazySlot) {
        matched.__slot = { kind: 'children', hostParentId: parentHost.__id, index: hostIdx };
        __patchLazySlot(matched, src);
        // 懒槽位同样要跟随排序：宿主 `childIds` 的顺序只由 insert/move 决定。
        if (matcher.positionOf(matched) !== hostIdx) {
          __emitOp({ op: 'move', parent: parentHost.__id, id: matched.__id, index: hostIdx });
        }
        next.push(matched);
        hostIdx += 1;
        continue;
      }

      // 新增的子结点同样先落成懒槽位，避免「父级重建新增离屏项」时提前挂载。
      // 容器从「非懒」切到「懒」（如 ListView 动态加/去 itemExtent）时，旧子结点
      // 不是懒槽位、宿主 dispose 时不会回传 `__lazyOffFn` → 必须换成懒槽位，
      // 否则该子项会永远挂在 JS 树里。与 Flutter「delegate 形态改变 → 子项重建」
      // 一致。
      if (lazy) {
        if (matched) { __unmount(matched); }
        next.push(__newLazySlot(parentHost, src, {
          kind: 'children', hostParentId: parentHost.__id, index: hostIdx
        }));
        hostIdx += 1;
        continue;
      }

      // 非懒容器（或懒容器里已提前挂载的旧结点）：此处必须有 element；
      // 延迟工厂形态（如容器从 lazy 变为非 lazy）在此现场展开一次。
      var cel = el !== null ? el : __lazyElementOf(src);
      if (cel == null || cel === false) { continue; }
      var inst = __patch(matched, cel, parentHost, { hostParentId: parentHost.__id, index: hostIdx });
      if (inst) {
        // 复用的结点位置变化 -> 下发 move（新建的自带 insert）。
        if (inst === matched && matcher.positionOf(inst) !== hostIdx) {
          __emitOp({ op: 'move', parent: parentHost.__id, id: __nodeIdOf(inst), index: hostIdx });
        }
        next.push(inst);
        hostIdx += 1;
      }
    }

    var leftovers = matcher.leftovers();
    for (i = 0; i < leftovers.length; i++) {
      __unmount(leftovers[i]);
    }
    parentHost.__children = next;
  }

  // props 里的 slot：值可能是单个元素、元素数组，或 delegate 描述
  // （`{__delegate:'list'|'builder', …}`）。元素判据统一为 `element === true`
  // （见【5】的 __isElement），不做 `{type, props}` 形状猜测。

  // 列表型 slot 的 keyed diff：复用已有实例，新键挂载，缺失卸载。
  // 不向宿主发 insert/move（宿主按 propsChildren 整表替换）。
  // 父结点是懒容器时，**每一项**都先落成懒槽位（未 visit 的子页不挂载）：
  // 已有槽位只更新 deferred / patch 子树；新项创建占位而不是立刻 mount。
  // [lazy] 由所在宿主元素的 `el.lazyChildren` 传入（运行时不做类型判断）。
  function __patchSlotList(parentHost, oldList, newEls, slotKey, lazy) {
    var matcher = __keyedMatcher(oldList);
    var next = [];
    var j;
    for (j = 0; j < newEls.length; j++) {
      var el = newEls[j];
      if (el == null || el === false) { continue; }
      var ek = __keySig(el.props ? el.props.key : null);
      var matched = matcher.take(ek);
      var slotIndex = next.length;
      if (lazy) {
        var ph = matched && matched.__lazySlot ? matched : null;
        if (matched && !ph) {
          // 同 __patchChildren：容器切到懒态时旧子结点必须换成懒槽位，否则宿主
          // dispose 时不会回调 `__lazyOffFn`，JS 子树永久驻留。
          __unmount(matched);
        }
        if (!ph) {
          ph = __newLazySlot(parentHost, { el: el }, { kind: 'prop' });
        } else {
          __patchLazySlot(ph, { el: el });
        }
        next.push(ph);
        continue;
      }
      var inst = __patch(matched, el, parentHost, null, {
        key: slotKey,
        index: slotIndex,
        parentId: parentHost.__id
      });
      if (inst) { next.push(inst); }
    }
    var leftovers = matcher.leftovers();
    for (var i = 0; i < leftovers.length; i++) {
      __unmount(leftovers[i]);
    }
    return next;
  }

  function __patchPropSlots(hostInst, newSlots, lazy) {
    var oldS = hostInst.__propsChildren || {};
    var oldL = hostInst.__propsChildrenList || {};
    var oldD = hostInst.__propsData || {};
    var nextS = {}, nextL = {}, nextD = {};
    var i, k;
    for (k in newSlots) {
      // __items / __builder 是 builder 展开协议（子结点走 flatten 列表），不是 prop slot。
      if (k === '__items' || k === '__builder') { continue; }
      if (!Object.prototype.hasOwnProperty.call(newSlots, k)) { continue; }
      var v = newSlots[k];
      if (__isElement(v)) {
        var prev = oldS[k] || null;
        var inst = __patch(prev, v, hostInst, null);
        if (inst) {
          nextS[k] = inst;
          __emitOp({ op: 'propsChild', parent: hostInst.__id, key: k, childId: __nodeIdOf(inst) });
        }
        // 本 key 上其他形态的旧绑定（列表 / delegate）由下面的清理循环统一
        // 卸载并解绑：这里再 unmount 一次会让组件 dispose() 跑两遍。
        continue;
      }
      if (__isElementList(v)) {
        var arr = __patchSlotList(hostInst, oldL[k] || [], v, k, lazy);
        nextL[k] = arr;
        __emitOp({
          op: 'propsChildren', parent: hostInst.__id, key: k,
          childIds: arr.map(__nodeIdOf)
        });
        continue;
      }
      if (v != null && typeof v === 'object' && v.__delegate) {
        if (v.__delegate === 'list') {
          var arr2 = __patchSlotList(hostInst, oldL[k] || [], v.children || [], k, lazy);
          nextL[k] = arr2;
          __emitOp({
            op: 'propsChildren', parent: hostInst.__id, key: k,
            childIds: arr2.map(__nodeIdOf)
          });
          nextD[k] = { __delegate: 'list' };
        } else {
          nextD[k] = v;
          __emitOp({ op: 'propsData', parent: hostInst.__id, key: k, value: v });
        }
        continue;
      }
    }
    for (k in oldS) {
      if (!nextS[k]) {
        __unmount(oldS[k]);
        __emitOp({ op: 'propsChildRemove', parent: hostInst.__id, key: k });
      }
    }
    for (k in oldL) {
      if (!nextL[k]) {
        for (i = 0; i < oldL[k].length; i++) { __unmount(oldL[k][i]); }
        __emitOp({ op: 'propsChildren', parent: hostInst.__id, key: k, childIds: [] });
      }
    }
    for (k in oldD) {
      if (!nextD[k]) { __emitOp({ op: 'propsDataRemove', parent: hostInst.__id, key: k }); }
    }
    hostInst.__propsChildren = nextS;
    hostInst.__propsChildrenList = nextL;
    hostInst.__propsData = nextD;
  }

  function __unmount(inst) {
    if (!inst) { return; }
    var hostId = __nodeIdOf(inst);
    if (hostId) { __emitOp({ op: 'remove', id: hostId }); }
    __markUnmounted(inst);
  }

  function __markUnmounted(inst) {
    // 幂等：同一结点可能经「自身 + 祖先递归」两条路径到达（事务帧回滚时逆序
    // teardown 尤其如此）。不拦会 `dispose()` 执行两遍、句柄二次释放。
    if (!inst || inst.__unmounted) { return; }
    inst.__unmounted = true;
    // 先摘除挂在本结点 key 上的上下文绑定（此刻组件上下文句柄还没释放）。
    __detachKeyContext(inst);
    if (inst.__k === __HOST) {
      delete __hostNodes[inst.__id];
      // 宿主 props 的函数句柄随结点释放（它们只为本结点的宿主回调存在）。
      __releaseHostFns(inst);
      for (var i = 0; i < inst.__children.length; i++) { __markUnmounted(inst.__children[i]); }
      var pcs = inst.__propsChildren;
      if (pcs) { for (var pk in pcs) { __markUnmounted(pcs[pk]); } }
      var pcl = inst.__propsChildrenList;
      if (pcl) {
        for (var lk in pcl) {
          for (var li = 0; li < pcl[lk].length; li++) { __markUnmounted(pcl[lk][li]); }
        }
      }
    } else {
      // 组件结点索引同步摘除：宿主不会再拉取一个已卸载的组件。
      delete __compNodes[inst.__id];
      // 与 Flutter 一致：从树上摘除时先 deactivate、再最终 dispose。
      // 生命周期异常不静默吞掉（后果是「句柄泄漏 / 监听未摘」，只能靠日志定位）。
      __callLifecycle(inst, 'deactivate');
      __callLifecycle(inst, 'dispose');
      // [scope] 从各被监听值的监听表里摘掉自己（订阅登记在消费者侧 `__subs`）。
      __unsubscribeAll(inst);
      // [inherited] 从各提供者结点的 `__dependents` 里摘掉自己（台账在 `__dependencies`）。
      __clearDependencies(inst);
      // [ctx] 释放 BuildContext 代理句柄。**必须通知宿主**：代理在宿主侧有
      // 真实记录（句柄→结点），纯本端删除会让宿主那条记录留到页面销毁。
      // 与页面兜底 __releasePageHandles 幂等（先删者胜，第二次是空操作）。
      if (inst.__ctx != null && inst.__ctx.__id != null) {
        __releaseHandle(inst.__ctx.__id);
        inst.__ctx = null;
      }
      __markUnmounted(inst.__child);
      // [owner] 释放该实例持有的句柄（控制器 / Key 等）：先递归卸载子树，再
      // 整份释放——与 Dart 的 State.dispose 顺序一致。`dispose()` 里显式释放
      // 过的句柄已被移出 `__owns`，这里幂等跳过。
      __releaseOwnerHandles(inst);
    }
  }

  // 整页挂载失败的回滚（__mountRoot 的 catch 调用）。此刻 `root.inst` **尚未赋值**
  // （mount 的返回值还没落到根上），半棵子树不可达，不能走 unmount；只能按归属
  // 清扫：宿主结点看 `__root`，句柄看 `key === pageKey`（挂载期登记的一切句柄：
  // page 作用域 / 事件闭包 / 实例持有的控制器、Key、ctx）或 `owner.__root`
  // （兜底：判据不依赖 __registerHandle 时 __activeRoot 是否已就位）。
  function __abortRoot(root) {
    var pageKey = root.key;
    var seen = {}, list = [], i;
    for (var id in __hostNodes) {
      var node = __hostNodes[id];
      if (node && node.__root === root) { delete __hostNodes[id]; }
    }
    for (var cid in __compNodes) {
      var comp = __compNodes[cid];
      if (comp && comp.__root === root) { delete __compNodes[cid]; }
    }
    var arr = __pageHandles[pageKey] || [];
    for (i = 0; i < arr.length; i++) { seen[arr[i]] = 1; list.push(arr[i]); }
    for (var hid in __handles) {
      if (seen[hid]) { continue; }
      var h = __handles[hid];
      if (!h) { continue; }
      if (h.key === pageKey || (h.owner && h.owner.__root === root)) {
        seen[hid] = 1;
        list.push(hid);
      }
    }
    // 逐条释放会同步通知宿主摘掉对端镜像记录；重复释放幂等。
    for (i = 0; i < list.length; i++) { __releaseHandle(list[i]); }
    root.ops = null;
    root.dirty = [];
    root.flushPending = false;
    root.inst = null;
    delete __roots[pageKey];
  }



// ===== 【11】对外入口 api =====
  function __parseProps(x) {
    if (x == null || x === '') { return {}; }
    if (typeof x === 'string') {
      try { return JSON.parse(x); } catch (e) { return {}; }
    }
    return x;
  }

  // 打开一个独立根（页面根 / 弹层面板根共用同一份事务）：
  //   初始化根记录 → 建立建树事务（ops 归本次挂载累积）→ 挂载元素 →
  //   下发根结点 → commit → 收尾补一次 flush。
  // `mounting`：挂载进行中。此刻 `root.ops` 正被本次挂载累积整棵树的
  // create/insert，而 flush 会**重置并消耗**同一份 ops（`root.ops = []` 后
  // commit 把它置 null），既丢掉尚未下发的结点、又让随后的根 op被 emit 静默
  // 丢弃（宿主收不到根 → 页面停在加载态）。故挂载期间的 setState 只入 dirty
  // 队列，挂载收尾后统一 flush（见【9】__markDirty）。
  function __openRoot(pageKey, el, parent) {
    var root = {
      key: pageKey, inst: null, dirty: [], flushing: false,
      flushPending: false, mounting: false, ops: null
    };
    __roots[pageKey] = root;
    var prev = __activeRoot;
    __activeRoot = root;
    root.mounting = true;
    try {
      root.ops = [];
      root.inst = __mount(el, parent, null);
      __emitOp({ op: 'root', id: __nodeIdOf(root.inst) });
      __commitOps(root);
    } catch (e) {
      // 失败即整根回滚：本次 commit 未发生（宿主侧没有半棵树），但 JS 侧已创建
      // 的宿主结点索引与已同步过去的句柄会随每次重试累积——只进不出。
      // 见 __abortRoot（按 __root / pageKey 归属清扫，不能走 __unmount(root.inst)：
      // 抛错时 root.inst 还没赋值）。
      __abortRoot(root);
      throw e;
    } finally {
      root.mounting = false;
      __activeRoot = prev;
    }
    // 挂载期间累积的 setState（如 initState 里 `setState(() => _loading = true)`）
    // 在这里补一次 flush：根补丁已下发，实例与结点都在，走的正是 patch 增量重建，
    // 与 Flutter「initState 里 setState → 首帧后再重建」语义一致。
    if (root.dirty.length) { __flushNow(root); }
    return root;
  }

  // 关闭一个独立根：卸载整棵树 → 宿主侧子树已随页面/路由销毁，补丁丢弃即可 →
  // 释放本页 scope=page 的句柄。组件自身持有的句柄由 __unmount 逐实例释放。
  function __closeRoot(root) {
    if (!root) { return; }
    var prev = __activeRoot;
    __activeRoot = root;
    try {
      root.ops = [];
      __unmount(root.inst);
      root.ops = null;
    } finally {
      __activeRoot = prev;
    }
    root.inst = null;
    // 页面退出兜底（scope=page）：这类句柄就是「显式归页面所有」的，页面没了
    // 即应释放，属正常生命周期而非泄漏。scope=instance/local 的孤儿残留留给
    // 宿主在泄漏比对之后调用 sweepPage 处理。
    __releasePageHandles(root.key);
    delete __roots[root.key];
  }

  // 挂载一个页面：pageKey 隔离根，moduleKey 定位模块，className 是组件类名。
  // 组件产物里 **JS 类名 = Dart 类名**，元素 type 就是这个类本身（JS 里没有
  // 「factory」这层包装）；`G[className]` 兜底全局注册的组件类。
  function __mountRoot(pageKey, moduleKey, className, propsJson) {
    var mod = (G.__modules && G.__modules[moduleKey]) || null;
    var C = (mod && mod[className]) || G[className];
    if (!C) {
      throw new Error('jsui: component not found: ' + className + ' in ' + moduleKey);
    }
    // 根组件是 `Component` 实例（实例即元素），build 由宿主在它的组件 wrapper
    // 挂载时同步拉取（见 __pullComponent）。
    __openRoot(pageKey, new C(__parseProps(propsJson)), null);
    return true;
  }

  function __disposeRoot(pageKey) { __closeRoot(__roots[pageKey]); }

  // 宿主侧 props 更新（Dart JsUiWidget.didUpdateWidget → 这里），与 Flutter
  // 「父级重建」语义对齐：替换根实例 props → 重跑 __applyProps（构造参数
  // 派生的字段）→ 回调 didUpdateWidget(oldWidget) → 标脏重建。
  // 根尚未 mount / 已 dispose 时返回 false（不静默：Dart 侧会按返回值记日志）。
  function __updateRootProps(pageKey, propsJson) {
    var root = __roots[pageKey];
    if (!root || !root.inst) { return false; }
    var inst = root.inst;
    var next = __parseProps(propsJson);
    var prev = inst.props || {};
    inst.props = next;
    if (typeof inst.__applyProps === 'function') { inst.__applyProps(next); }
    // 首次 build 尚未由宿主拉起：只同步 props，didUpdateWidget 在「已构建」之后
    // 才有意义；build 由 __pullComponent 读取最新 props 后执行。
    if (inst.__built) { __withBuilding(inst, function () { inst.didUpdateWidget(prev); }); }
    __markDirty(inst);
    return true;
  }



// ===== 【11.5】跨模块核心符号（供 flutter.js 值类区） =====
  G.__core = {
    // 句柄机制。register/release 走转发调用：debug 缓存追踪切面会在运行时
    // 替换这两个实现，直接引用会让跨模块调用绕过切面。
    __handleOp: __handleOp,
    __registerHandle: function (obj, kind, opts) { return __registerHandle(obj, kind, opts); },
    __releaseHandle: function (id, notify) { return __releaseHandle(id, notify); },
    __handleObjectOf: __handleObjectOf,
    __createFnHandle: __createFnHandle,
    // 继承机制（InheritedWidget 语义）：provider 在自己的模块 patch/provider.js
    // 里登记作用域；BuildContext 的查找方法在 runtime 内核里（同一 IIFE）。
    __inheritElement: __inheritElement,
    __notifyClients: __notifyClients,
    __typeArgumentOf: __typeArgumentOf,
    __subscribeListenable: __subscribeListenable,
    // 调度：`Component.setState`（flutter.js 的基类）需要把实例标脏。
    __markDirty: __markDirty,
    // 结点 / 独立根：弹层面板机制（dialogs）只用这几个通用入口。
    __contextOf: __contextOf,
    __isElement: __isElement,
    __isElementList: __isElementList,
    // 值对象携带的嵌套元素 → 宿主可还原的元素描述（值类 toJSON 使用）。
    __descriptorOf: __descriptorOf,
    __nodeIdOf: __nodeIdOf,
    __mount: __mount,
    __unmount: __unmount,
    __openRoot: __openRoot,
    __closeRoot: __closeRoot,
    // 宿主桥（弹层打开/关闭等模块级通道调用）。
    __invokeHostMethod: __invokeHostMethod,
    // 日志与值展开：flutter.js 的框架内提示 / 值类（StringBuffer）共用。
    log: __logText,
    str: __str,
    __roots: __roots,
    // 可变状态用访问器：直接取 const 只会拿到求值当时的快照。
    get building() { return __building; },
    set building(v) { __building = v; },
    // 当前归属锚点：build 锚点优先，其次委托调用（builder）的拥有者实例。
    // 宿主元素在构造期记录它，回调执行时还原（见 mini-react 的 __hostProps）。
    get anchor() { return __building || __ownerAnchor; },
    get activeRoot() { return __activeRoot; },
    set activeRoot(v) { __activeRoot = v; },
    get JsBuildContext() { return JsBuildContext; },
    __objectToken: __objectToken
  };


// ===== 【11.7】Key 签名（__keySig / __objectToken） =====
  // ObjectKey / ValueKey(对象值) 的身份 token：对象走 WeakMap（不阻止回收），
  // 原始值没有身份，退化为值 string。
  var __okeySeq = 0;
  var __okeyIdx = new WeakMap();
  function __objectToken(v) {
    if (v === null || (typeof v !== 'object' && typeof v !== 'function')) {
      return 'p:' + String(v);
    }
    var t = __okeyIdx.get(v);
    if (t == null) { __okeySeq += 1; t = 'i:' + __okeySeq; __okeyIdx.set(v, t); }
    return t;
  }

  // 值 → 签名片段（原始值按「类型 + 值」，对象按身份）。
  function __keyValueSig(v) {
    if (v === null || (typeof v !== 'object' && typeof v !== 'function')) {
      return typeof v + ':' + String(v);
    }
    return 'i:' + __objectToken(v);
  }

  // key → 可比较签名；null / undefined（无 key）返回 null。
  // 形态判据用**自有字段**（`__vkey` / `__okey`）：ValueKey 的值本身可以是
  // null/undefined，故只能判「有没有这个字段」，不能判它的值。
  function __keySig(k) {
    if (k == null) { return null; }
    if (Object.prototype.hasOwnProperty.call(k, '__vkey')) { return 'v:' + __keyValueSig(k.__vkey); }
    // PageStorageKey：同值也与 ValueKey 不等（`p:` 前缀），对象值同 ValueKey 走 token。
    if (Object.prototype.hasOwnProperty.call(k, '__psk')) {
      var pv = k.__psk;
      if (pv !== null && typeof pv === 'object' &&
          Object.prototype.hasOwnProperty.call(pv, '__vtok')) {
        return 'p:' + pv.__vtok;
      }
      return 'p:' + __keyValueSig(pv);
    }
    if (Object.prototype.hasOwnProperty.call(k, '__okey')) { return 'o:' + k.__okey; }
    // GlobalKey / UniqueKey：句柄 id 即身份（props 里的 key 是 live 实例，带 __id）。
    if (k.__id != null) { return 'h:' + k.__id; }
    // 兜底：认不出的 key 对象按**引用身份**区分。绝不能 `String(k)` ——
    // 所有对象都会拼成 "[object Object]" 而互相撞车，导致不同 key 复用同一
    // 结点（`x:` 前缀保留，表明这是兜底签名）。
    return 'x:' + __objectToken(k);
  }


// ===== 【21】BuildContext 代理 =====
  class JsBuildContext {
    constructor(anchor, nodeId, handleId) {
      // 消费它的 JS 组件实例（watch/read 的构建位置锚点）。
      this.__anchor = anchor;
      // 最近宿主祖先结点 id（宿主侧 nodeId -> 真值 BuildContext 的键）。
      this.__nodeId = nodeId;
      // 跨语言句柄：**惰性**登记（没用过 context 的组件零句柄开销）。
      // 已有句柄时（GlobalKey.currentContext 复用 key 句柄）直接沿用，不再新建。
      this.__id = handleId == null ? null : handleId;
    }

    // 句柄（首次真正需要宿主真值时才登记，宿主 onCreate 绑定 nodeId）。
    __handle() {
      if (this.__id == null) {
        this.__id = __registerHandle(this, 'ctx/BuildContext', {
          meta: this.__nodeId == null ? null : { node: this.__nodeId }
        });
      }
      return this.__id;
    }

    // 向宿主真值 BuildContext 发同名 op（其余 context API 走这条路）。
    // JS→宿主只有异步桥，故 fire-and-forget：不阻塞本端同步渲染，失败静默丢弃
    // （页面卸载竞态下句柄可能已释放）。
    __host(op, payload) {
      try {
        var p = __handleOp(this.__handle(), op, payload);
        if (p && typeof p.catch === 'function') { p.catch(function () {}); }
      } catch (e) {}
    }

    // Flutter `BuildContext.getInheritedWidgetOfExactType<T>()`：取最近提供该
    // **精确类型**的祖先结点，不建立依赖。类型实参由生成器按泛型元信息下发
    // （`{ typeArguments: {...} }`），取第一个值。
    getInheritedWidgetOfExactType(props) {
      var type = __typeArgumentOf(props, 'context.getInheritedWidgetOfExactType');
      if (type == null) { return null; }
      return __getInheritedElement(this.__anchor, type);
    }

    // Flutter `BuildContext.dependOnInheritedWidgetOfExactType<T>()`：同上，并把
    // 当前位置登记为该提供者的依赖（提供者 `__notifyClients` 时先
    // didChangeDependencies 再重建）。
    dependOnInheritedWidgetOfExactType(props) {
      var type = __typeArgumentOf(props, 'context.dependOnInheritedWidgetOfExactType');
      if (type == null) { return null; }
      var element = __getInheritedElement(this.__anchor, type);
      if (element == null) { return null; }
      __registerDependency(this.__anchor, element, __exactTypeName(type));
      return element;
    }
  }

  // 登记类型别名：`extension X on BuildContext` 的注册按 Dart 类型名解析目标
  // （见【27.5】）。BuildContext 是运行时私有代理，不挂 G——只为 extension
  // 解析留一条别名，不把内部类暴露成全局。
  __registerTypeAlias('BuildContext', JsBuildContext);

  // `context.watch<T>()` / `read<T>()` **不在这里**：它们不是框架 API，而是
  // provider 那类 `extension BuildContextX on BuildContext`——方法补丁在
  // patch/provider.js（provider_module_js.dart）。
  // 本片段只提供机制：代理、句柄、InheritedWidget 查找（depend/get）、通用 op 转发。

  // 组件实例 → 代理（每个实例一个，缓存进 `__ctx`）。**同一执行位置**下，
  // build 形参与 `this.context` 是同一个对象：前者由 __buildOf 传入 `__contextOf(inst)`，
  // 后者由 getter 传 `__building`，而 `__buildOf` 期间 `__building === inst`。
  function __contextOf(inst) {
    if (inst.__ctx == null) { inst.__ctx = __createContext(inst); }
    return inst.__ctx;
  }

  // 建立代理：结点锚点 = **组件自己的结点 id**。
  // 组件结点现在是宿主的挂载边界（宿主为它建 wrapper，wrapper 在 build 里先
  // 登记锚点、再同步拉取 JS build），因此每次 build 时锚点必然已经登记——
  // `MediaQuery.of(context)` / `context.watch` 首次 build 就能发起取值（真值经
  // 异步桥回填后标脏重建校正），不会卡在兜底值上。
  // 只有拿不到结点 id 的极端情况（未挂载的实例）才退回页面锚点。
  function __createContext(inst) {
    if (inst && inst.__id) { return new JsBuildContext(inst, inst.__id); }
    var root = __activeRoot || (inst && inst.__root);
    return new JsBuildContext(inst, root ? 'page:' + root.key : null);
  }


// ===== 【25】泄漏观测（debug 用） =====

  function __leakSnapshot() {
    var hs = [];
    for (var id in __handles) {
      var h = __handles[id];
      hs.push({ id: id, kind: h.kind, scope: h.scope, key: h.key, obj: __constructorName(h) });
    }
    var ph = {};
    for (var pk in __pageHandles) { ph[pk] = __pageHandles[pk].length; }
    var rs = [];
    for (var rk in __roots) { rs.push(rk); }
    // 键名是宿主快照协议的字段（handles / pageHandles / roots），与内部变量名无关。
    return JSON.stringify({ handles: hs, pageHandles: ph, roots: rs });
  }

  // 宿主侧调试入口用的**缓存全景**（仅 debug）：`__handles` 是 JS 端唯一的对象
  // 缓存（函数 / 控制器 / Key / ChangeNotifier / ctx 句柄都在这一张表里，kind 只是
  // 条目上的标签）——这里按 kind 汇总条目数 + 逐条列出 id/scope/key/构造名，外加
  // 页面句柄索引与页面根表，一眼看全 JS 端持有什么（见 JsLeakSnapshot.logJsCache）。
  function __cacheDump() {
    var byKind = {};
    var lines = [];
    for (var id in __handles) {
      var h = __handles[id];
      byKind[h.kind] = (byKind[h.kind] || 0) + 1;
      lines.push(h.kind + ' ' + id + ' obj=' + __constructorName(h)
        + (h.key ? ' page=' + h.key : ' scope=' + h.scope));
    }
    var kinds = [];
    for (var k in byKind) { kinds.push(k + '×' + byKind[k]); }
    var ph = [];
    for (var pk in __pageHandles) { ph.push(pk + '×' + __pageHandles[pk].length); }
    var rs = [];
    for (var rk in __roots) { rs.push(rk); }
    return 'js binding cache: ' + lines.length + ' 条（' + kinds.join(', ') + '）'
      + '\n  pageHandles: ' + (ph.length ? ph.join(', ') : '-')
      + '\n  roots: ' + (rs.length ? rs.join(', ') : '-')
      + (lines.length ? '\n  ' + lines.join('\n  ') : '');
  }


// ===== 【26】缓存详细追踪（debug 用） =====
  var __cacheTraceOn = false;
  var __cacheTraceInstalled = false;

  // 一行摘要：id（构造名）· kind · scope · page · 持有者类型。
  function __cacheTraceLine(h) {
    var page = h.key || '-';
    var owner = h.owner ? (h.owner.__name || h.owner.__k || 'inst') : '-';
    return h.id + '（' + __constructorName(h) + '）· kind=' + h.kind
      + ' · scope=' + h.scope + ' · 页面=' + page + ' · 持有者=' + owner;
  }

  // 安装切面（幂等）：把 __registerHandle / __releaseHandle 换成「原实现 + 日志」。
  function __installCacheTrace() {
    if (__cacheTraceInstalled) { return; }
    __cacheTraceInstalled = true;
    var rawReg = __registerHandle;
    __registerHandle = function (obj, kind, opts) {
      // 同一对象重复登记返回同一 id（身份去重）——那种不算「新建」，不打印。
      var existed = (obj === null || obj === undefined)
        ? null : __handleOwnerIdx.get(obj);
      var id = rawReg(obj, kind, opts);
      if (__cacheTraceOn && id && id !== existed && __handles[id]) {
        G.debugPrint('[binding] + JS ' + __cacheTraceLine(__handles[id]));
      }
      return id;
    };
    var rawRelease = __releaseHandle;
    __releaseHandle = function (id, notify) {
      var h = __cacheTraceOn ? __handles[id] : null;
      rawRelease(id, notify);
      // 幂等释放（本地已删）不打印，避免与对端 release 重复刷屏。
      if (h) { G.debugPrint('[binding] - JS ' + __cacheTraceLine(h)); }
    };
  }

  // 宿主入口：打开 / 关闭详细追踪。关闭即包装内日志分支短路（只多一次布尔
  // 判断），不会再安装第二层包装。
  function __setCacheVerbose(on) {
    __cacheTraceOn = !!on;
    if (__cacheTraceOn) { __installCacheTrace(); }
  }


// ===== 【27.5】Dart extension 注册（registerExtension） =====
  // 类型名 → 构造函数：语言核心映射 → 运行时别名表 → G[name]。
  // 三者都取不到时返回 null（调用方 __error，不静默吞掉）。
  function __extensionTargetOf(target) {
    if (typeof target !== 'string') return target || null;
    switch (target) {
      case 'int':
      case 'num':
      case 'double': return Number;
      case 'String': return String;
      case 'bool': return Boolean;
      case 'List':
      case 'Iterable': return Array;
      case 'Set': return Set;
    }
    if (Object.prototype.hasOwnProperty.call(__typeAliases, target)) {
      return __typeAliases[target];
    }
    var g = G[target];
    return typeof g === 'function' ? g : null;
  }

  // 原型上的扩展登记簿（owners: 成员名 → 扩展 id）。非枚举挂在原型自身，
  // 用来区分「类/内建本来就有」（静默跳过）与「另一个扩展占了」（warn）。
  function __extensionMeta(proto) {
    if (!Object.prototype.hasOwnProperty.call(proto, '__extensionMeta')) {
      Object.defineProperty(proto, '__extensionMeta', {
        value: { owners: {} },
        writable: true,
        enumerable: false,
        configurable: true
      });
    }
    return proto.__extensionMeta;
  }

  // id -> { proto, names }：同 id 再注册时据此卸载上一次的成员。
  var __extensionRecords = {};
  var __extensionSeq = 0;

  function __uninstallExtension(id) {
    var rec = __extensionRecords[id];
    if (!rec) return;
    var meta = __extensionMeta(rec.proto);
    for (var i = 0; i < rec.names.length; i++) {
      var name = rec.names[i];
      if (meta.owners[name] === id) {
        delete meta.owners[name];
        // 成员一律 configurable，删除不会抛错；引擎实现差异用 try 兜住。
        try { delete rec.proto[name]; } catch (e) {}
      }
    }
    delete __extensionRecords[id];
  }

  G.registerExtension = function (target, members, opts) {
    opts = opts || {};
    var id = opts.id == null ? '' : String(opts.id);
    var statics = opts.statics || {};
    var ctor = __extensionTargetOf(target);
    if (!ctor) {
      __error('jsui: extension target not found: ' + String(target) +
        (id ? ' (' + id + ')' : ''));
      return statics;
    }
    var proto = ctor.prototype;
    if (!proto) {
      __error('jsui: extension target has no prototype: ' + String(target));
      return statics;
    }
    if (id) __uninstallExtension(id);
    var meta = __extensionMeta(proto);
    var record = { proto: proto, names: [] };
    for (var name in members) {
      if (!Object.prototype.hasOwnProperty.call(members, name)) continue;
      // 目标上已有同名成员（含继承）：Dart 里显式成员优先于扩展，静默跳过。
      if (name in proto) {
        if (id && meta.owners[name] && meta.owners[name] !== id) {
          __warn('jsui: extension member conflict: ' + name +
            ' already provided by ' + meta.owners[name] +
            ' (later registration ignored)');
        }
        continue;
      }
      var member = members[name];
      if (typeof member === 'function') {
        Object.defineProperty(proto, name, {
          value: member,
          writable: true,
          enumerable: false,
          configurable: true
        });
      } else {
        Object.defineProperty(proto, name, {
          get: member.get,
          set: member.set,
          enumerable: false,
          configurable: true
        });
      }
      __extensionSeq += 1;
      meta.owners[name] = id || ('@' + __extensionSeq);
      record.names.push(name);
    }
    if (id) __extensionRecords[id] = record;
    return statics;
  };


// ===== 【28】api 收尾 =====

  // 宿主侧契约（`__jsui.<key>`，Dart 侧 evaluate 按名调用）：只保留宿主真正用到的入口。
  var api = {
    invoke: __invokeEventHandler,
    // 需要结果的事件调用（宿主等待 Future）：执行句柄 → 若返回 Promise 则
    // await → 经宿主通道 `jsuiEventResult` 回传 token 与结果。与能力无关，
    // 所有 `Future<T>` 回调共用（见 `JsRuntimeManager.invokeAwait`）。
    invokeAwait: __invokeEventHandlerAwait,
    // 页面根挂载（Dart 侧 evaluate `__jsui.mountRoot(...)`）。
    // 不要与 reconciler 内部的 `__mount`（挂载单个结点）混淆。
    mountRoot: __mountRoot,
    // 宿主挂载组件 wrapper 时**同步**拉取该组件的首次 build 结果（补丁 JSON）。
    // 这是唯一一条「宿主 build → JS build」的入口：保证 JS build 执行时
    // BuildContext 锚点已由 wrapper 登记。
    pull: __pullComponent,
    dispose: __disposeRoot,
    updateProps: __updateRootProps,
    // 帧级批处理入口：宿主每帧 begin frame 调用，统一跑掉待处理重建
    // （setState 只标脏，见【9】__markDirty / __requestFlush）。
    flushPending: __flushPending,
    // `panelMount` / `panelClosed` 不在这里：命令式弹层的独立根归 flutter.js
    // （见 dialogs_js.dart），该模块求值时把两个入口装到 `__jsui` 上。

    leakSnapshot: __leakSnapshot,
    cacheDump: __cacheDump,
    setCacheVerbose: __setCacheVerbose,
    sweepPage: __sweepPage,

    // 跨语言句柄（通用层）：宿主侧句柄注册表经 evaluate 调用本端真实对象
    // （见 capabilities/core/handle_registry.dart）。
    release: function (id) { __releaseHandle(id, false); },
    call: __callHandle
  };

  G.__jsui = api;
  // JS→宿主唯一出口（宿主桥）：`invoke` 发起调用，宿主**必定**结算——
  // 成功 `resolve`，实现抛错 `reject`。与 `__jsui`（页面挂载/事件回传等运行
  // 入口）分开，语义单一。
  G._app_host_ = { invoke: __invokeHostMethod, resolve: __resolveHostCall, reject: __rejectHostCall };
  // 模块表 `__modules` 由同一 IIFE 首段（_jsUiEnvVars）创建（挂 G），
  // 此处只登记 core，不再自带守卫。
  G.__modules['js_ui/core'] = api;
})();
