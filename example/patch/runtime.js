
// ===== 【1】运行环境｜IIFE 入口 + 全局对象 + console 桥（版本 3de841c2） =====

(function () {
  var G = typeof globalThis !== 'undefined'
    ? globalThis
    : Function('return this')();
  if (G.__jsui && G.__jsuiVersion === '3de841c2') { return; }
  G.__jsuiVersion = '3de841c2';


if (typeof G.__modules === 'undefined') {
  G.__modules = {};
}
// 编译/运行期标志（kDebugMode / kReleaseMode / Platform）**由宿主在求值本
// 文件之前注入**（见 JsRuntimeManager._jsUiEnvSource）：这些值取决于 App 的
// 编译模式与目标平台，构建期（build_runner）无从得知，故不写进产物。
// 产物与 Dart 一比一：kDebugMode / kReleaseMode / Platform.isAndroid 原样
// 保留（见生成器 globalFlagJs / platformFlagJs），运行时注入同名对象。
// 值 → 字符串（对象/数组完整展开，循环引用安全）：JS 侧 `String(obj)` 只会
// 得到 `[object Object]`，日志里看不到任何字段。`__str` 递归展开 own 字段，
// 函数标成 `[Function name]`、循环引用标成 `[Circular]`（与 JSON.stringify
// 不同：不会因循环引用直接抛错，也不丢函数字段）。
// 生成器把 Dart 字符串插值（形如 '$name'）翻译成 __str(name)（见
// js_translator _logArgJs），console 桥也用它，故挂在 G 上供产物裸引用。
function __fmt(v, stack) {
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
    for (var i = 0; i < v.length; i++) { items.push(__fmt(v[i], next)); }
    return '[' + items.join(', ') + ']';
  }
  var keys = Object.keys(v);
  var out = [];
  for (var j = 0; j < keys.length; j++) {
    out.push(keys[j] + ': ' + __fmt(v[keys[j]], next));
  }
  return '{' + out.join(', ') + '}';
}
G.__str = function (v) { return __fmt(v, []); };
// 原生日志方法（Dart debugPrint/print 转换产物直接调用）：统一桥到逻辑通道
// 'log'（宿主 log 处理器 → HotPatchLog）。支持多实参（`console.log(a, b)` 与
// 浏览器一致，空格分隔），每个实参都走 __fmt 展开。
//
// **release 下全部关闭、零跨桥**：kDebugMode 为 false 时五个级别都是同一个空
// 函数 —— 一次日志的代价是「格式化 + JSON 编码 + 桥消息 + Promise」，线上既
// 看不到也担不起；需要线上诊断请走显式上报通道，不要指望 print。
//
// 注意：flutter_js 引擎可能自带 console（只有部分方法），不能用
// `typeof console === 'undefined'` 判断 —— 无条件合并覆盖，保证
// debug/info/log/warn/error 全部可用。
// 出口统一走 `_app_host_.invoke`（唯一 JS→宿主入口）；宿主 'log' 处理器始终已注册，
// 故 Promise 一定被回填、不会悬挂。`_app_host_` 在本 IIFE 收尾（【25】）赋值，
// 而 console 只可能被页面代码调用——那时它必然已存在，无需探测。
G.console = (typeof G.console === 'undefined') ? {} : G.console;
function __log(level, args) {
  var text = '';
  for (var i = 0; i < args.length; i++) {
    text += (i ? ' ' : '') + __fmt(args[i], []);
  }
  // 级别一并带给宿主（位置实参 [level, text]）：console.warn/error 在宿主侧
  // 就是 warn/error 级，可直接进统一上报出口；未知级别按 info 处理（见
  // builtin_host_methods.dart 的 _log）。
  G._app_host_.invoke('log', [level, text]);
}
function __silentLog() {}
G.console.debug = __silentLog;
G.console.info = __silentLog;
G.console.log = __silentLog;
G.console.warn = __silentLog;
G.console.error = __silentLog;
if (G.kDebugMode) {
  G.console.debug = function () { __log('debug', arguments); };
  G.console.info = function () { __log('info', arguments); };
  G.console.log = function () { __log('info', arguments); };
  G.console.warn = function () { __log('warn', arguments); };
  G.console.error = function () { __log('error', arguments); };
}

  var idSeq = 0;
  var HOST = 1, COMP = 2;

  // pageKey -> { key, inst, dirty, flushing, flushPending, mounting, ops }
  var roots = {};
  // pageKey -> 句柄 id[]：本页面（scope=page）登记的全部跨语言句柄（控制器 /
  // 函数 / 未来的 Key / 对象…）。页面退出时由 disposeRoot 统一释放——新增能力
  // 只要按句柄登记即自动获得页面回收，无需再改 disposeRoot（见【4】句柄注册表）。
  var pageHandles = {};
  // 正在 mount/patch/flush 的根；emit / 结点归属都读它。
  var activeRoot = null;
  // 正在构建的元素（build 执行期）——`context` 的锚点。`context.watch/read` 据此
  // 定位**作用域**（按类型名向上找，见【8】）并订阅（与 Dart 的 BuildContext
  // 语义一致：按**位置**而非「谁定义了这个方法」）。委托型组件（Builder/Consumer）
  // 把 builder 方法以 owner 为 this 调用时，锚点仍是它们自身的结点。
  var building = null;

  // id 统一规则：`<端>:<种类>/<子类>#<序号>`（子类可省），序号全局单调仅用于
  // 唯一化。带前缀是为了让宿主侧 ValueKey / Flutter DevTools 一眼看出 id 的
  // 归属端（js/dt）与种类（node/comp/ctrl/fn/key…）——调试可读性。
  //   结点：js:node/<Type>#N（宿主结点）/ js:comp/<Name>#N（组件结点）
  //   句柄：js:ctrl/Scroll#N、js:fn#N、dt:key/Global#N（见【4】句柄注册表）
  function nodeId(type) { idSeq += 1; return 'js:node/' + type + '#' + idSeq; }
  function compId(type) { idSeq += 1; return 'js:comp/' + compName(type) + '#' + idSeq; }

  // COMP 结点 id 用的类名：`class X {}` -> `X`（生成器产物均为具名类）。
  function compName(type) { return (type && type.name) || 'Component'; }

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
  //   - Array.prototype.clear()：Dart `List.clear()` 的**原地**清空（保持数组
  //     实例，故 `final` 列表也能清；返回 void）。数组在 JS 侧就是 List。
  // 已知缺口（未补）：Dart `Map` 字面量在 JS 侧是**普通对象**（不是 Map 实例），
  // 故 `Map.clear()` 无处可挂（挂 Object.prototype 影响面过大），需要时得按
  // 「字段类型是 Map」在翻译层分发；Dart `Set` 字面量翻成 `new Set([...])`，
  // JS Set 自带 clear()，无需处理。
  if (typeof Array.prototype.clear !== 'function') {
    Object.defineProperty(Array.prototype, 'clear', {
      value: function () { this.length = 0; },
      writable: true,
      enumerable: false,
      configurable: true
    });
  }
  //   - Array / String 的 Dart 同名成员：生成器不再按名字改写（`first` /
  //     `where` / `add` / `removeAt` / `insert` / `toList` / `isEmpty` … 原样
  //     产出），由本节按接收者类型补齐同名同义实现。全部不可枚举 + 存在性守卫，
  //     避免污染 for...in / Object.keys / JSON.stringify。
  function __defineProtoMember(proto, name, fn) {
    if (typeof proto[name] !== 'function') {
      Object.defineProperty(proto, name, {
        value: fn,
        writable: true,
        enumerable: false,
        configurable: true
      });
    }
  }
  function __defineProtoGetter(proto, name, getter) {
    if (!Object.getOwnPropertyDescriptor(proto, name)) {
      Object.defineProperty(proto, name, {
        get: getter,
        enumerable: false,
        configurable: true
      });
    }
  }
  __defineProtoGetter(Array.prototype, 'first', function () { return this[0]; });
  __defineProtoGetter(Array.prototype, 'last', function () {
    return this[this.length - 1];
  });
  __defineProtoGetter(Array.prototype, 'isEmpty', function () {
    return this.length === 0;
  });
  __defineProtoGetter(Array.prototype, 'isNotEmpty', function () {
    return this.length > 0;
  });
  __defineProtoGetter(Array.prototype, 'reversed', function () {
    return this.slice().reverse();
  });
  __defineProtoMember(Array.prototype, 'where', function (predicate) {
    return this.filter(predicate);
  });
  // Dart List.toList() 返回新列表；这里保持数组实例（与既有产物行为一致），
  // 后续链式调用 / 原地修改语义不变。
  __defineProtoMember(Array.prototype, 'toList', function () { return this; });
  __defineProtoMember(Array.prototype, 'add', function (value) {
    this.push(value);
  });
  __defineProtoMember(Array.prototype, 'removeAt', function (index) {
    return this.splice(index, 1)[0];
  });
  //   - List.remove(value) / removeLast() / removeWhere：Dart 侧极常用
  //     （`this._items.remove(item)`），缺一个，事件回调就会抛 TypeError，
  //     `setState` 的 mutator 半途中断、**界面不重建**（典型症状：Dismissible
  //     已滑走但条目仍在树上，触发 "dismissed ... still part of the tree"）。
  //     语义按 Dart：remove 删第一个 == value 的元素并返回是否删过。
  __defineProtoMember(Array.prototype, 'remove', function (value) {
    var i = this.indexOf(value);
    if (i < 0) { return false; }
    this.splice(i, 1);
    return true;
  });
  __defineProtoMember(Array.prototype, 'removeLast', function () {
    return this.pop();
  });
  __defineProtoMember(Array.prototype, 'removeWhere', function (predicate) {
    var removed = false;
    for (var i = this.length - 1; i >= 0; i--) {
      if (predicate(this[i])) { this.splice(i, 1); removed = true; }
    }
    return removed;
  });
  __defineProtoMember(Array.prototype, 'insert', function (index, value) {
    this.splice(index, 0, value);
  });
  __defineProtoGetter(String.prototype, 'isEmpty', function () {
    return this.length === 0;
  });
  __defineProtoGetter(String.prototype, 'isNotEmpty', function () {
    return this.length > 0;
  });
  //   - int 的 `isEven` / `isOdd` 是 Dart 的属性（不是方法），JS 数字没有；
  //     生成器按 Dart 写法一比一产出 `n.isEven`，故按同名同义补 getter。
  __defineProtoGetter(Number.prototype, 'isEven', function () {
    return this % 2 === 0;
  });
  __defineProtoGetter(Number.prototype, 'isOdd', function () {
    return this % 2 !== 0;
  });
  var __compareTo = function (other) {
    return this < other ? -1 : (this > other ? 1 : 0);
  };
  __defineProtoMember(Number.prototype, 'compareTo', __compareTo);
  __defineProtoMember(String.prototype, 'compareTo', __compareTo);
  //   - Number.prototype：Dart `num` 的方法在 JS 里**没有同名成员**
  //     （`(x * 100).round()` 直接抛 "is not a function"，整个组件挂载失败、
  //     页面只显示加载失败占位）。生成器按 Dart 写法一比一产出，故在数字原型上
  //     按**同名同义**补齐（与 Dart 语义一致：truncate/toInt 向零取整，
  //     字符串化/取整返回新值不改变接收者）。
  var numPatches = {
    round: function () { return Math.round(this); },
    floor: function () { return Math.floor(this); },
    ceil: function () { return Math.ceil(this); },
    abs: function () { return Math.abs(this); },
    truncate: function () { return Math.trunc(this); },
    toInt: function () { return Math.trunc(this); },
    toDouble: function () { return this; },
    toStringAsFixed: function (digits) { return this.toFixed(digits); },
    clamp: function (lo, hi) { return Math.min(Math.max(this, lo), hi); }
  };
  for (var numKey in numPatches) {
    if (typeof Number.prototype[numKey] !== 'function') {
      Object.defineProperty(Number.prototype, numKey, {
        value: numPatches[numKey],
        writable: true,
        enumerable: false,
        configurable: true
      });
    }
  }

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


// ===== 【2】出方向桥（emit / commit） =====
  // 所有 JS→宿主消息都打到单桥通道 `_app_bridge_`，目标通道名放在消息体
  // `ch` 字段。宿主只订阅该桥通道一次，再按 ch 二次分发。
  // `send` 是运行时**内部**的低层发送（不对外暴露）；对外的唯一入口是
  // `_app_host_.invoke`（见【3】），它等于 `send` + Promise 回填。
  var APP_BRIDGE = '_app_bridge_';
  function send(channel, data) {
    if (typeof sendMessage !== 'function') { return; }
    sendMessage(APP_BRIDGE, JSON.stringify({ ch: channel, data: data }));
  }

  function emit(op) {
    if (activeRoot && activeRoot.ops) { activeRoot.ops.push(op); }
  }
  function commit(root) {
    var list = root.ops;
    root.ops = null;
    if (!list || !list.length) { return; }
    // 补丁按页面 key 路由到对应 JsUiStore（key 放进 args，宿主 handler 解析）。
    try {
      send('jsuiCommit', { args: { key: root.key, ops: list } });
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
          console.error('jsui: op not serializable #' + di + ' op=' + bad.op +
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
  var hostSeq = 0;
  var hostPending = {};
  function host(channel, args) {
    hostSeq += 1;
    var id = 'host' + hostSeq;
    var p = new Promise(function (resolve, reject) {
      hostPending[id] = { resolve: resolve, reject: reject };
    });
    send(channel, { id: id, args: args || [] });
    return p;
  }
  // 结算并**摘除**条目：先删后调，保证一条 pending 只结算一次；成功/失败两条
  // 路径都必须走这里——宿主侧不会「既不 resolve 也不 reject」（未注册通道由
  // 宿主回填 null，实现抛错由宿主 reject），所以表里不会留下永久滞留的条目。
  function settleHost(id) {
    var h = hostPending[id];
    if (!h) { return null; }
    delete hostPending[id];
    return h;
  }
  function resolveHost(id, value) {
    var h = settleHost(id);
    if (!h) { return; }
    h.resolve(value);
  }
  // 宿主实现失败：把错误原样抛给 JS 调用者（`await _app_host_.invoke(...)`
  // 处抛出，落进 JS 自己的 try/catch），而不是伪装成「结果是 null」。
  function rejectHost(id, message) {
    var h = settleHost(id);
    if (!h) { return; }
    h.reject(new Error(message));
  }



// ===== 【4】跨语言句柄注册表 =====
  // handleSeq 与 idSeq 相互独立：句柄 id 与结点 id 分属两套命名空间。
  var handleSeq = 0;
  // id -> { id, kind, scope, key, obj, meta }
  var handles = {};
  // 对象 -> id：同一对象重复登记返回同一 id（身份去重，WeakMap 不阻止回收）。
  var handleOwnerIdx = new WeakMap();
  // kind -> { release(h) }：JS 本端登记时的真实资源清理（可选）。对端的清理
  // 由对端各自的 kind 描述符负责，跨桥只传 id + op。
  var handleKinds = {};

  function defineHandleKind(name, desc) { handleKinds[name] = desc || {}; }

  // 句柄 id：`js:<kind>#N`（kind 形如 `fn` / `ctrl/Scroll` / `key`）。
  function newHandleId(kind) {
    handleSeq += 1;
    return 'js:' + kind + '#' + handleSeq;
  }

  // 句柄摘要里的「是什么对象」：构造名优先（日志与泄漏/缓存全景共用同一套取法）。
  function ctorNameOf(h) {
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
  // `__jsui.cacheDump()`（debug）与泄漏快照汇总给出，ctorNameOf 仍供它们使用。

  // 登记一个 JS 侧真实对象/函数为句柄，返回 id。
  //
  // 归属优先级（scope 未显式指定时）：
  //   1. 组件**构造中**（`new el.type(...)` 期间）：记入最内层构造帧，返回后由
  //      endConstruct 回填到该组件实例——字段初始化里的
  //      `this._controller = new ScrollController()` 正是这个时机；
  //   2. 委托调用期间（withOwner）：归属方法体所在的类实例；
  //   3. `building` 是组件结点（initState / build / 事件执行期）：直接归属它；
  //   4. 其余（模块级 / 静态字段）：随页面；无 activeRoot 时退化为 global。
  //
  // 显式 `opts.scope`（'local' / 'page' / 'global'）优先，事件闭包等仍按原语义。
  function reg(obj, kind, opts) {
    if (obj === null || obj === undefined) { return null; }
    var exist = handleOwnerIdx.get(obj);
    if (exist && handles[exist]) { return exist; }
    opts = opts || {};
    var explicit = opts.scope;
    var owner = opts.owner || null;
    var pending = false;
    if (!explicit && !owner) {
      if (constructFrames.length) {
        pending = true; // 归属最内层构造中的组件（见 beginConstruct/endConstruct）
      } else if (ownerAnchor) {
        // 委托调用期间（不是 build 锚点）：资源属于方法体所在的类实例
        owner = ownerAnchor;
      } else if (building && building.__k === COMP) {
        owner = building;
      }
    }
    var pageKey = (activeRoot && activeRoot.key) || null;
    var scope = explicit || ((owner || pending) ? 'instance' : 'page');
    var key = pageKey; // 诊断 / 宿主侧页面兜底都用它
    if (scope === 'page') {
      key = opts.key || pageKey || null;
      if (key === null) { scope = 'global'; }
    }
    var id = newHandleId(kind);
    handles[id] = {
      id: id, kind: kind, scope: scope, key: key, obj: obj,
      meta: opts.meta || null, owner: null
    };
    handleOwnerIdx.set(obj, id);
    if (scope === 'page') {
      (pageHandles[key] || (pageHandles[key] = [])).push(id);
    }
    if (owner) { attachOwner(id, owner); }
    if (pending) { constructFrames[constructFrames.length - 1].push(id); }
    // 自动同步宿主：宿主侧同名 kind 描述符的 onCreate 据此创建真实对象
    // （scope=local 的纯本端句柄——如事件闭包——传 sync:false 不同步）。
    // pageKey 一并下发：宿主侧据此登记「句柄→页面」，页面销毁时做本端兜底回收。
    if (opts.sync !== false) {
      host('jsHandle', [{
        id: id, op: 'create', kind: kind, pageKey: key, meta: opts.meta || null
      }]);
    }
    return id;
  }

  // ── 组件实例归属（owner）────────────────────────────────────────────
  // 每个组件实例一份 `__owns`（id 数组），实例卸载时整份释放。物理存储仍在
  // 全局 `handles`，这里只是「释放时机」的索引。
  var constructFrames = []; // 组件构造帧栈：每帧收集该次 new 期间登记的句柄 id
  // 显式归属锚点：委托调用（`owner[name].call(owner, ...)`）期间指向方法体
  // 所在的类实例——`building` 此时是被委托组件，不能用它判断资源归属。
  var ownerAnchor = null;

  function withOwner(inst, fn) {
    var prev = ownerAnchor;
    ownerAnchor = inst;
    try { return fn(); } finally { ownerAnchor = prev; }
  }

  function attachOwner(id, inst) {
    var h = handles[id];
    if (!h || !inst) { return; }
    h.owner = inst;
    (inst.__owns || (inst.__owns = [])).push(id);
  }

  // 组件实例构造开始：返回本帧（mount 里紧贴 `new el.type(...)` 使用）。
  function beginConstruct() {
    var frame = [];
    constructFrames.push(frame);
    return frame;
  }

  // 构造结束：把本帧登记的句柄回填给新实例（构造抛错时 inst 传 null，
  // 这些句柄没有归属者，直接释放，避免两端残留）。
  function endConstruct(inst, frame) {
    var i = constructFrames.lastIndexOf(frame);
    if (i >= 0) { constructFrames.splice(i, 1); }
    if (!frame) { return; }
    if (!inst) {
      for (var k = 0; k < frame.length; k++) { releaseHandle(frame[k]); }
      return;
    }
    for (var j = 0; j < frame.length; j++) { attachOwner(frame[j], inst); }
  }

  // 实例卸载：释放它持有的全部句柄（`dispose()` 里已显式释放过的幂等跳过）。
  function releaseOwnerHandles(inst) {
    if (!inst || !inst.__owns) { return; }
    var snapshot = inst.__owns.slice();
    inst.__owns = null;
    for (var i = 0; i < snapshot.length; i++) { releaseHandle(snapshot[i]); }
  }

  // 释放一个句柄（本端）。幂等：不存在即返回（不回环——对端释放时本地已删，
  // 不再二次通知）。notify=false 用于纯本端句柄（如构建期事件句柄）。
  function releaseHandle(id, notify) {
    var h = handles[id];
    if (!h) { return; }
    delete handles[id];
    if (h.obj) { try { handleOwnerIdx.delete(h.obj); } catch (e) {} }
    // 从所属组件实例的索引里摘除（实例卸载时 __owns 已置 null，跳过）。
    if (h.owner && h.owner.__owns) {
      var owns = h.owner.__owns;
      var oi = owns.indexOf(id);
      if (oi >= 0) { owns.splice(oi, 1); }
    }
    if (h.scope === 'page' && h.key && pageHandles[h.key]) {
      var arr = pageHandles[h.key];
      var i = arr.indexOf(id);
      if (i >= 0) { arr.splice(i, 1); }
    }
    var desc = handleKinds[h.kind];
    if (desc && typeof desc.release === 'function') {
      try { desc.release(h); } catch (e) {}
    }
    if (notify !== false) { host('jsHandle', [{ id: id, op: 'release' }]); }
  }

  // 页面退出兜底：释放本页登记的全部 page 句柄（数组边遍历边被 releaseHandle
  // 摘除，故拷贝一份再遍历）。
  function releasePageHandles(pageKey) {
    var arr = pageHandles[pageKey];
    if (!arr) { return; }
    var snapshot = arr.slice();
    for (var i = 0; i < snapshot.length; i++) { releaseHandle(snapshot[i]); }
    delete pageHandles[pageKey];
  }

  // 页面退出兜底（宿主在泄漏比对之后显式调用）：清掉**本页所属**的残留句柄。
  //
  // 判定「属于本页」用句柄自身的 key + 持有者归属：
  //   - key !== pageKey：别的页的，跳过；
  //   - 持有者仍挂在**活着的**页面根上（roots[owner.__root.key] 存在）：说明该
  //     对象被别的活页面共享使用，跳过（避免退出 A 页把 B 页还在用的对象释放掉）；
  //   - 其余（无持有者、持有者的根已销毁）即本页孤儿，释放。
  // 正常路径上组件卸载已逐实例释放，这里剩的只是卸载路径没跑到的残渣；释放幂等，
  // 因此页面挂载/卸载多少次都不会累积。放在比对之后调用，泄漏仍可被观测。
  function sweepPage(pageKey) {
    releasePageHandles(pageKey);
    var ids = [];
    for (var id in handles) {
      var h = handles[id];
      if (h.key !== pageKey) { continue; }
      var owner = h.owner;
      if (owner && owner.__root && roots[owner.__root.key]) { continue; }
      ids.push(id);
    }
    for (var i = 0; i < ids.length; i++) { releaseHandle(ids[i]); }
  }

  // 宿主 → JS：按 id 在**本端**真实对象上执行 op（宿主侧句柄注册表经 evaluate
  // 调用，见 __jsui.call）。返回结果供宿主回填（Promise 场景）。
  //   invoke：函数句柄调用（args 数组）
  //   call  ：对象方法调用（method + args）
  //   get/set：属性读写（name）
  function callHandle(id, op, payload) {
    var h = handles[id];
    if (!h) {
              console.warn('jsui: handle not found (released?): ' + id + ' op=' + op);
      
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

  // 宿主 → JS：释放本端句柄（对端发起的 release，不再回通知）。
  function releaseFromHost(id) { releaseHandle(id, false); }

  // JS → 宿主：对本端句柄对应的**宿主端真实对象**发起 op（返回 Promise）。
  // 与 callHandle 方向相反、语义对称（call/get/set/invoke）。
  function handleOp(id, op, payload) {
    var body = { id: id, op: op };
    if (payload) { for (var k in payload) { body[k] = payload[k]; } }
    return host('jsHandle', [body]);
  }

  // Scroll/Tab/Text 的 JS 代理类同构：__listeners 数组、内部回传句柄
  // （meta.fn 交宿主回传）、句柄登记（scope=page）、release 清理、dispose、
  // toJSON、__notify。本工厂收敛这套样板；能力只写差异：
  //   init(self, ...)   ：构造体（镜像字段），实参透传（如 Tab 的 opts）；
  //   onHost(self, p)   ：宿主回传 → 更新镜像 + __notify（缺省则无回传句柄）；
  //   extraJSON(self)   ：toJSON 附加字段（如 Tab 的 length/initialIndex）；
  //   meta(self)        ：随句柄 create 下发给宿主的构造参数（宿主据此创建
  //                       真实对象，如 EasyRefreshController 的 controlFinish*）。
  // ChangeNotifier 刻意不用本工厂：它是用户模型基类（无回传句柄、
  // notifyListeners 是公开 API、双路派发），见 change_notifier_js.dart。
  function defineController(kind, spec) {
    spec = spec || {};
    defineHandleKind(kind, {
      release: function (h) {
        var c = h.obj;
        if (!c) { return; }
        // 内部回传句柄是框架实现（用户无从释放），随本控制器一并释放。
        if (c.__hostFn) { releaseHandle(c.__hostFn.__fn, false); c.__hostFn = null; }
        c.__listeners = [];
      }
    });
    var Ctor = function () {
      this.__listeners = [];
      if (spec.init) { spec.init.apply(this, arguments); }
      if (spec.onHost) {
        var self = this;
        this.__hostFn = fn(function (p) { spec.onHost(self, p); });
      }
      // 登记为句柄（scope=page）：自动同步宿主 onCreate（meta 携带回传句柄与
      // 能力自带的构造参数，供宿主创建真实对象）；页面退出时 disposeRoot 兜底释放。
      var meta = this.__hostFn ? { fn: this.__hostFn } : null;
      if (spec.meta) {
        var extra = spec.meta(this);
        if (extra) {
          meta = meta || {};
          for (var k in extra) { meta[k] = extra[k]; }
        }
      }
      this.__id = reg(this, kind, { meta: meta });
    };
    Ctor.prototype.addListener = function (f) {
      if (typeof f === 'function') { this.__listeners.push(f); }
    };
    Ctor.prototype.removeListener = function (f) {
      var i = this.__listeners.indexOf(f);
      if (i >= 0) { this.__listeners.splice(i, 1); }
    };
    Ctor.prototype.__notify = function () {
      var fs = this.__listeners;
      for (var i = 0; i < fs.length; i++) { fs[i](); }
    };
    Ctor.prototype.dispose = function () {
      releaseHandle(this.__id);
      this.__id = null;
    };
    Ctor.prototype.toJSON = function () {
      var out = { __handle: this.__id };
      if (spec.extraJSON) {
        var extra = spec.extraJSON(this);
        if (extra) { for (var k in extra) { out[k] = extra[k]; } }
      }
      return out;
    };
    return Ctor;
  }



// ===== 【5】element 与事件句柄 =====

  function h(type, props, children) {
    var ch = [];
    if (children != null) {
      ch = Array.isArray(children) ? children : [children];
    }
    return { type: type, props: props || {}, children: ch };
  }

  // 组件实例 → 元素描述：生成类与普通类一样「构造即实例」，父级把它当子结点
  // 消费时在这里统一折算（与 flutter.js 的 __asElement 同一协议）。
  // `inst` 随元素一起携带：mount 直接复用该实例，**不再 new 第二次**。
  function asElement(v) {
    if (v == null || typeof v !== 'object' || v.element === true) { return v; }
    var C = v.constructor;
    if (typeof C === 'function' && C.prototype &&
        typeof C.prototype.build === 'function') {
      // 同一 Widget 实例 → 同一元素描述：Dart「const 规范化」在 JS 侧的对应物。
      // 生成器把 `const X(...)` 的产物 hoist 成同一实例后，靠这层缓存让每次
      // 折算都得到同一个元素对象，patch 才能像原生 `updateChild` 那样按引用短路。
      if (v.__elCache) { return v.__elCache; }
      var e = {
        type: C, props: v.props || {}, children: {}, element: true, inst: v
      };
      v.__elCache = e;
      return e;
    }
    return v;
  }

  // 事件回调无法跨语言传递 -> 登记为句柄（kind=fn，scope=local：由拥有者
  // 代码显式释放，如构建期 __bindFn 随组件卸载释放，见【4】句柄注册表）。
  // 宿主侧回调用 invoke 触发。
  function fn(f) {
    var id = reg(f, 'fn', { scope: 'local', sync: false });
    return { __fn: id };
  }

  // 事件回传载荷统一为**参数数组**（Dart 侧 `_invoke(handler, args)` 的 args）：
  // 0 参事件 `[]`、onChanged `[v]`、多参事件 `[a,b]`…。句柄是普通位置函数——
  // 能力桥 `fn(function(t){…})` 按真实形参直接收下；__bindFn 生成的 wrapper
  // 用 `arguments` 汇总任意个数再摊开转发给生成器产出的箭头闭包。故 0/1/N 参
  // 事件共用同一条通路，新增多参事件无需改这里。
  function invoke(id, args) {
    var h = handles[id];
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
    f.apply(null, args);
  }



// ===== 【6】reconciler 工具 =====

  // 深比较（用于避免每次重建都下发 props）；下面紧邻的 keyOf / hostIdOf /
  // rootFor 同属本分区。
  var EQ_MAX_DEPTH = 32;
  function eq(a, b, depth) {
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
      if (!eq(a[ka[i]], b[ka[i]], depth - 1)) { return false; }
    }
    return true;
  }

  // 结点声明的 key（**值**，不是结点）：ValueKey / ObjectKey 实例、GlobalKey /
  // UniqueKey 的句柄实例，或 null（未声明）。比较一律经 [keySig]（见【20】），
  // 不在此处做归一——`keyOf` 只负责取。
  function keyOf(inst) {
    var p = inst.__k === HOST ? inst.__props : (inst.__el && inst.__el.props);
    return p ? p.key : null;
  }

  function hostIdOf(inst) {
    while (inst && inst.__k === COMP) { inst = inst.__child; }
    return inst ? inst.__id : null;
  }

  // 结点归属的根：mount 期间用 activeRoot，其余情况继承父结点。
  function rootFor(parent) {
    return activeRoot || (parent && parent.__root) || null;
  }



// ===== 【7】组件基类 =====

  // 生成器产物**不** extends 本类：`augment` 把这些方法拷到实例上。
  // setState / __bindFn 属于 mini-react；上下文（`context.watch/read`）与
  // BuildContext 代理见【21】（调用面与 Dart 一致，不在实例上挂 `this.watch`）。
  function Component(props) { this.props = props || {}; }
  Component.prototype.setState = function (mutate) {
    if (typeof mutate === 'function') { mutate.call(this); }
    markDirty(this);
  };
  // ── 回到【7】mini-react｜事件句柄（__bindFn）─────────────────────────
  // 事件句柄：生成器把事件统一翻译成**构建期箭头闭包**，在此登记成句柄。
  // `this` 正是 build 作用域里的组件实例，也就是**定义该事件的组件**（含
  // Consumer/Builder 把 builder 方法 `.call(owner)` 的场景）。句柄随 props
  // 传下去（`{__fn:id}`），宿主点击时经 invoke(id) 回来；因为句柄信息挂在
  // props 上，包装型组件（MultiProvider 透传 child）也不会把它弄丢。
  //   句柄执行时会还原**绑定时的构建位置**：闭包里的 `this.context.watch/read`
  //   按定义闭包时的 context 位置解析（而非点击时的 `this`）。
  //   按 (位点号, 捕获值) 缓存：重建产出同一句柄 → props 稳定（增量补丁仍生效）；
  //   循环项捕获到不同值时各自独立（回调不互相覆盖）；卸载时统一释放。
  //
  // 捕获值的身份判定：对象 / 函数按**引用身份**（同一个对象每次重建仍是同一个
  // → key 稳定），原始值按 **typeof 前缀 + String**（`1` 与 `'1'`、`null` 与
  // `undefined` 与 `''` 必须是不同 key，否则不同捕获值的闭包会互相覆盖）。
  // WeakMap 自动回收，不延长捕获对象寿命。
  var __capIds = new WeakMap();
  var __capSeq = 0;
  function capKey(v) {
    if (v === undefined) { return 'undefined'; }
    if (v === null) { return 'null'; }
    var t = typeof v;
    if (t === 'object' || t === 'function') {
      var id = __capIds.get(v);
      if (!id) { id = ++__capSeq; __capIds.set(v, id); }
      return t + '#' + id;
    }
    return t + ':' + String(v);
  }
  // [siteId] 是编译期位点号（同一个 on* 位点每次构建都相同）。它只要求
  // **同一个组件类内**唯一：句柄缓存挂在实例自己的 `__boundFn` 上，不同实例
  // （不同页面 / 同一页面多次挂载 / 不同组件）各有一份，编号从 0 重复也不会
  // 互相覆盖。[captures] 是该闭包引用的构建期局部值，两者共同决定句柄复用。
  Component.prototype.__bindFn = function (siteId, captures, f) {
    var bag = this.__boundFn || (this.__boundFn = {});
    var key = siteId + '|';
    if (captures && captures.length) {
      var ks = [];
      for (var i = 0; i < captures.length; i++) { ks.push(capKey(captures[i])); }
      key += ks.join(',');
    }
    var handle = bag[key];
    if (handle) { handle.__run = f; return handle; }
    var anchor = building || this;
    handle = fn(function () {
      var prev = building;
      building = anchor;
      // 位置实参在 `arguments` 里（invoke 已摊开），原样转发给闭包。
      // 返回值保留：普通事件丢弃、可等待事件（EasyRefresh onRefresh）靠它拿 Promise。
      try { return handle.__run.apply(handle, arguments); }
      catch (e) {  console.error(String(e));  }
      finally { building = prev; }
    });
    handle.__run = f;
    handle.__key = key; // 便于调试：句柄带上构建期 key
    bag[key] = handle;
    return handle;
  };



// ===== 【8】作用域与订阅 =====

  // **与 Flutter 的 InheritedWidget 同语义**：宿主结点用 `__provides`
  // （类型名 → 值）声明自己对外提供的作用域；查找**只认类型名**，不关心这个
  // 类型是模型、控制器还是别的什么 —— 正如 Dart 侧
  // `dependOnInheritedWidgetOfExactType<T>()` 不关心 T 是干嘛的。
  //
  // 「谁提供什么」由**各能力自己**注册（[registerScope]）；reconciler 只在
  // mount/patch 时把结点 props 交给对应 publisher 折算成 `__provides`，核心
  // 零业务知识（与「新增能力 = 注册描述符」同构）。三方库的注册见
  // capabilities/js_ui_library.dart（provider 是其中一族）。
  var scopePublishers = {};

  // 注册：宿主 widget 类型 → `props => {类型名: 值}`（返回空 = 不提供）。
  function registerScope(hostType, publish) {
    scopePublishers[hostType] = publish;
  }

  // mount/patch 时调用：把该宿主结点的 props 折算进 `__provides`。
  // 每次 patch 都重放（props 变了、或 publisher 换了实例，如 create 重跑）。
  function applyScope(inst, props) {
    var publish = scopePublishers[inst.__type];
    if (!publish) { return; }
    var provided = publish(props || {});
    inst.__provides = (provided && Object.keys(provided).length) ? provided : null;
  }

  // 从 [inst] 沿 `__parent` 向上取最近提供 [type] 的**值**（同名就近遮蔽）。
  // 必须是同步取值：渲染期 `model.count` 直接读，不能经异步桥回宿主。
  // 取不到返回 null（不猜、不回退）。
  function scopeOf(inst, type) {
    var p = inst.__parent;
    while (p) {
      var pr = p.__provides;
      if (pr && Object.prototype.hasOwnProperty.call(pr, type)) { return pr[type]; }
      p = p.__parent;
    }
    return null;
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
  function subscribeListenable(anchor, value) {
    if (!value || typeof value.addListener !== 'function') { return; }
    var mine = anchor.__subs || (anchor.__subs = []);
    for (var i = 0; i < mine.length; i++) {
      if (mine[i].value === value) { return; }
    }
    var entry = { value: value };
    // 依赖变更必须区别于 setState：标记 __depDirty，flush 时据此在 build 前
    // 补一次 didChangeDependencies（对应 Flutter 的 InheritedWidget 变更语义）。
    entry.listener = function () { anchor.__depDirty = true; markDirty(anchor); };
    value.addListener(entry.listener);
    mine.push(entry);
  }

  // 卸载时按消费者自己记录的台账精确退订。
  function unsubscribeAll(inst) {
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
  // 触发源有两处：mini-react 的 setState、作用域订阅回调（见【8】`subscribeListenable`）。
  //
  // **挂载中不 flush**：`root.mounting` 期间 `root.ops` 归 mountRoot 累积（整棵树的
  // create/insert），而 flush 会重置并消耗同一份 ops —— 未下发的结点连同根 op 一起
  // 丢，宿主收不到根、页面永远停在加载态。setState 在 initState / 构造里是合法写法
  // （Flutter 也是首帧后再重建），故这里只入 dirty 队列，mountRoot 收尾时再 flush。
  //
  // **按帧合并（与 Flutter 的 setState 语义一致）**：setState 只标脏，真正的
  // rebuild 由宿主在每帧 begin frame 调 `api.flushPending()` 统一执行。同一帧内
  // 收到多少个 setState（例如滚动通知逐条回传）都只 build 一次；此前是每次
  // setState 同步 flush，滚动时 JS 的重建次数等于通知数，是原生的数倍。
  // 没有宿主桥（命令行 / 测试 harness）时退化为同步 flush，保持原行为。
  function markDirty(inst) {
    if (!inst || inst.__unmounted || inst.__dirty) { return; }
    // build 期对自己 setState 是错误写法：Flutter 原生在此直接断言（
    // "setState() or markNeedsBuild() called during build"）。若不拦截，flush
    // 的 while 会「置 __dirty=false → build 内再入队 → 再 build」无限循环，
    // 整个 JS 线程卡死且没有任何日志。这里出声并跳过。
    // 只挡「自己正在 build」：祖先/子结点互相标脏不受影响（原生同样放行）。
    if (inst.__building) {
              console.error('jsui: setState during build ignored (' +
          compName(inst.constructor) + ')');
      
      return;
    }
    var root = inst.__root;
    if (!root) { return; }
    inst.__dirty = true;
    root.dirty.push(inst);
    if (root.flushing || root.mounting) { return; }
    requestFlush(root);
  }

  // 请求宿主在下一帧统一 flush。同一帧内多次 setState 只请求一次。
  function requestFlush(root) {
    if (root.flushPending) { return; }
    root.flushPending = true;
    // 有宿主桥才交给它调度；否则（无 sendMessage 的纯 JS 环境，如单测）同步兜底。
    if (typeof sendMessage === 'function' && G._app_host_) {
      G._app_host_.invoke('jsuiRequestFrame', []);
      return;
    }
    flushNow(root);
  }

  // 立即 flush：挂载收尾（mountRoot / lazyMount / lazyUnmount）与无宿主兜底用。
  function flushNow(root) {
    if (!root || root.flushing || root.mounting) { return; }
    root.flushPending = false;
    root.flushing = true;
    try { flush(root); } finally { root.flushing = false; }
  }

  // 宿主每帧 begin frame 调用：跑掉所有页面根累积的重建（帧级批处理入口）。
  function flushPending() {
    for (var key in roots) {
      var root = roots[key];
      if (!root || !root.flushPending || root.flushing || root.mounting) {
        continue;
      }
      flushNow(root);
    }
    return true;
  }

  function flush(root) {
    var prev = activeRoot;
    activeRoot = root;
    try {
      while (root.dirty.length) {
        var batch = root.dirty;
        root.dirty = [];
        for (var i = 0; i < batch.length; i++) {
          var inst = batch[i];
          inst.__dirty = false;
          if (inst.__unmounted) { continue; }
          // 单条重建失败不连坐同批其余组件（与 Flutter「一个子树建错出
          // ErrorWidget、兄弟照常构建」对齐）：本批已由 root.dirty 整体接管
          // 并清空，异常若冲出 for 循环，后面那些组件的 __dirty 仍是 true 却
          // 已不在队列里，markDirty 会因 __dirty 早退 → 它们将永不重建。
          root.ops = [];
          try {
            // 作用域依赖变更（__depDirty）走这里：与 Flutter 一致，
            // 先 didChangeDependencies 再 build；setState 触发的重建不调。
            if (inst.__depDirty) {
              inst.__depDirty = false;
              if (typeof inst.didChangeDependencies === 'function') {
                inst.didChangeDependencies();
              }
            }
            inst.__child = patchComponentChild(inst);
            // 组件自身重建（setState → flush）不经过父级 patchLazySlot：动态
            // wantKeepAlive（`bool get wantKeepAlive => _flag`）的变化必须在这里
            // 补一次同步，否则宿主侧保活声明会停留在旧值。
            // 读的是业务 getter，异常只记日志：不能让它把本次**已成功**的重建
            // 补丁一起丢进下面的 catch。
            try {
              syncEnclosingKeepAlive(inst);
            } catch (e2) {
                              console.error('jsui: keepAlive sync failed (' +
                  compName(inst.constructor) + '): ' + e2);
              
            }
            commit(root);
          } catch (e) {
            // 丢弃本次未 commit 的增量：宿主只接受整批 commit，半棵树不下发，
            // 避免 JS 树与宿主渲染在中途状态上分叉。该实例保持 __dirty=false，
            // 下次 setState / 订阅通知会重新重建。
            root.ops = null;
                          console.error('jsui: rebuild failed (' +
                compName(inst.constructor) + '): ' + e);
            
          }
        }
      }
    } finally {
      activeRoot = prev;
    }
  }



// ===== 【10】reconciler 主流程 =====

  //
  // 「懒容器 + 延迟子结点」：容器的 children 不随容器一起挂载，而是等**宿主**
  // 真的 inflate 到那个槽位时才挂载 —— 即 initState 由 `_JsNodeState` 的生命周期
  // 驱动。MiniReact 的挂载是一次性全树遍历，做不到层层按需；而「哪个子结点可见」
  // 的真值只在宿主侧（Flutter 的 element inflation）。所以这里只留一个**普通**
  // 零尺寸占位结点（复用 SizedBox 类型：不新增 widget 类型、产物形态零改动），
  // 真实子元素先挂在占位实例的 `__deferred` 上；宿主 inflate 到占位结点时经
  // `__lazyFn`（事件句柄同款 invoke 通道）回调 lazyMount，才真正 mount
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
  // （shared/js_widget_defs.dart）并重出产物，运行时代码不动。

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
  // 不一致；故每项只带延迟工厂，真正执行推迟到 `lazyMount`。
  // builder 回调协议只有**一种形态：闭包（函数）**。方法 tear-off 在构建期统一
  // 生成绑定闭包（`this` 由词法作用域固定），因此运行时不需要「找拥有者方法」
  // 这一层——少一条静默失败路径（找不到方法 → 空列表白屏）。
  function isBuilderFn(v) {
    return typeof v === 'function';
  }

  function builderSpec(el) {
    var slots = el.children || {};
    var b = slots.__builder;
    if (b && isBuilderFn(b.item) && typeof b.count === 'number') {
      return { item: b.item, sep: isBuilderFn(b.sep) ? b.sep : null, count: b.count, ctx: b.ctx };
    }
    var d = slots.delegate;
    if (!d || d.__delegate !== 'builder' || !isBuilderFn(d.builder)) {
      return null;
    }
    var n = d.childCount;
    if (typeof n !== 'number' || n <= 0) { return null; }
    return { item: d.builder, sep: null, count: n, ctx: null };
  }

  // 第 [slotIndex] 个子结点（`.separated` 按 item/separator 交替展开）。
  // 传给 builder 的 `context` 形参：命名构造优先用代理 build 收到的那个
  // （与原行为一致），delegate 形态用拥有者组件的代理。
  function buildItem(owner, spec, slotIndex) {
    var ctx = spec.ctx || contextOf(owner);
    var out = null;
    // 委托调用期间 owner 锚点指向 builder 所属组件实例：builder 里创建的
    // 控制器 / Key 归属它（`building` 在这里可能是宿主结点或已还原）。
    withOwner(owner, function () {
      var sep = spec.sep;
      if (sep && slotIndex % 2 === 1) {
        out = sep(ctx, (slotIndex - 1) / 2);
      } else {
        out = spec.item(ctx, sep ? slotIndex / 2 : slotIndex);
      }
    });
    return out;
  }

  function childSources(el, parent, lazy) {
    var slots = el.children || {};
    var pre = slots.__items;
    var out = [];
    var i;
    if (Array.isArray(pre)) {
      for (i = 0; i < pre.length; i++) { out.push({ el: pre[i] }); }
      return out;
    }
    var spec = builderSpec(el);
    if (!spec) { return out; }
    // 闭包自带接收者，展开时只需要锚点做句柄归属（parent 即拥有者实例）。
    var owner = parent || null;
    var total = spec.sep ? Math.max(0, spec.count * 2 - 1) : spec.count;
    for (i = 0; i < total; i++) {
      if (lazy) {
        out.push({ make: (function (idx, ow) {
          return function () { return buildItem(ow, spec, idx); };
        })(i, owner) });
      } else {
        // 非懒容器：保持原语义，一次性展开全部子结点。
        out.push({ el: buildItem(owner, spec, i) });
      }
    }
    return out;
  }

  // 宿主结点索引（id → 结点实例）：只为「宿主上报 inflate」的反查用（懒槽位）。
  var hostNodes = {};

  // 挂载事务帧：记录本次尝试新增的宿主结点与组件实例，失败时**按帧**精确回滚
  // （见 lazyMount 的 catch）。不能按 `__root` 清扫——那是整页根，会误伤同页
  // 其他已挂载的子树（整页回滚是 mountRoot 的 abortRoot，二者不要混用）。
  // 只在 lazyMount 期间非空：正常挂载路径只多一次 length 判断。
  var mountFrames = [];
  function beginMountFrame() {
    var frame = { nodes: [], insts: [] };
    mountFrames.push(frame);
    return frame;
  }
  function endMountFrame(frame) {
    var i = mountFrames.lastIndexOf(frame);
    if (i >= 0) { mountFrames.splice(i, 1); }
  }
  function trackNode(id) {
    if (mountFrames.length) {
      mountFrames[mountFrames.length - 1].nodes.push(id);
    }
  }
  function trackInst(inst) {
    if (mountFrames.length) {
      mountFrames[mountFrames.length - 1].insts.push(inst);
    }
  }

  // 回滚一个挂载事务帧：逆序 teardown 本次挂载的组件实例（markUnmounted 会递归
  // 释放 `__owns` / `__ctx` / `__boundFn` 句柄、退订并删掉已挂树的宿主结点），
  // 再补齐「父结点 mount 尚未返回、因而没进任何 `__children`」的宿主结点 id。
  // 宿主侧此时 commit 未发生（create/insert 随丢弃的 ops 一起没下发），故不需要
  // 发 remove；占位结点的 `__deferred` / props 都未改动，下次 inflate 可重试。
  function rollbackMountFrame(frame) {
    var i;
    for (i = frame.insts.length - 1; i >= 0; i--) {
      var inst = frame.insts[i];
      if (inst && !inst.__unmounted) { markUnmounted(inst); }
    }
    for (i = 0; i < frame.nodes.length; i++) {
      var node = hostNodes[frame.nodes[i]];
      if (node) {
        delete hostNodes[frame.nodes[i]];
        node.__unmounted = true;
      }
    }
  }

  // 宿主回调句柄：runtime 级常驻（scope=local 且不同步宿主——宿主只拿它的 id 走
  // 事件 invoke 通道回调，本端不需要留镜像）。
  //   - lazyMount：宿主 element **inflate**（首次布局到该槽位）；
  //   - lazyUnmount：宿主 element **dispose**（ListView 回收离屏项 / 页面销毁）——
  //     与 Flutter 同寿：离屏项的 State 被销毁，滚回来再 initState 重新构建。
  //     没有这条通知，JS 侧挂过的 item 会永远活着（滚到底后每次重建都在 patch
  //     全量 item），列表越长越糟。
  //     宿主侧在 dispose（finalizeTree 的 lockState 内）不直接回调，而是延后到
  //     post-frame 再发——本方法会同步 commit 回来重建**存活**的父结点，
  //     锁定期 setState 会触发框架断言（见 _JsNodeState._unmountIfLazy）。
  var lazyMountFn = fn(function (id) { lazyMount(id); });
  var lazyUnmountFn = fn(function (id) { lazyUnmount(id); });

  // 懒槽位占位结点：普通宿主结点（SizedBox 0x0）+ `__lazy` 数据标记 + 回调句柄；
  // 子元素来源先挂在占位实例上（`src.el` 元素 / `src.make` 延迟工厂），本帧不挂载。
  function newLazySlot(parent, src, slot) {
    // 占位结点沿用子元素的声明式 key：父级重建时按 key 复用槽位，宿主侧
    // element key 也不会因占位/真实切换而变化（延迟工厂形态此时拿不到 key）。
    var props = {
      width: 0, height: 0, __lazy: true,
      __lazyFn: lazyMountFn, __lazyOffFn: lazyUnmountFn
    };
    if (src && src.el && src.el.props && src.el.props.key !== undefined) {
      props.key = src.el.props.key;
    }
    var hi = {
      __k: HOST, __id: nodeId('SizedBox'), __type: 'SizedBox',
      __root: rootFor(parent),
      __props: props,
      __children: [], __parent: parent, __slot: slot,
      __deferred: src ? src.el : null,
      __deferMake: src ? src.make : null,
      __lazySlot: true
    };
    hostNodes[hi.__id] = hi;
    trackNode(hi.__id);
    emit({ op: 'create', id: hi.__id, type: hi.__type, props: hi.__props });
    if (slot && slot.kind === 'children' && slot.hostParentId) {
      emit({ op: 'insert', parent: slot.hostParentId, id: hi.__id, index: slot.index });
    }
    return hi;
  }

  // 懒槽位当前的子元素来源 → element（未挂载时按需调用延迟工厂）。
  function lazyElementOf(src) {
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
  function subtreeWantsKeepAlive(inst) {
    if (!inst) { return false; }
    if (inst.__k !== HOST) {
      if (inst.wantKeepAlive === true) { return true; }
      return subtreeWantsKeepAlive(inst.__child);
    }
    if (inst.__lazySlot) { return false; }
    var i;
    var cs = inst.__children || [];
    for (i = 0; i < cs.length; i++) {
      if (subtreeWantsKeepAlive(cs[i])) { return true; }
    }
    var pcs = inst.__propsChildren;
    if (pcs) {
      for (var k in pcs) {
        if (subtreeWantsKeepAlive(pcs[k])) { return true; }
      }
    }
    var pcl = inst.__propsChildrenList;
    if (pcl) {
      for (var lk in pcl) {
        var arr = pcl[lk] || [];
        for (i = 0; i < arr.length; i++) {
          if (subtreeWantsKeepAlive(arr[i])) { return true; }
        }
      }
    }
    return false;
  }

  // 把当前已挂载子树的 keep-alive 声明同步到占位结点 props（幂等）。
  // 声明变化必须下发 props op：宿主 _JsNode 收到补丁后重建，build 里
  // updateKeepAlive() 才会真正注册 / 释放 KeepAlive。
  function syncKeepAlive(ph) {
    var wants = subtreeWantsKeepAlive(ph.__mountedChild);
    var has = !!(ph.__props && ph.__props.__keepAlive);
    if (wants === has) { return; }
    ph.__props = ph.__props || {};
    if (wants) {
      ph.__props.__keepAlive = true;
    } else {
      delete ph.__props.__keepAlive;
    }
    emit({ op: 'props', id: ph.__id, props: ph.__props });
  }

  // 组件自身重建（setState → flush）后，把变更同步给**最近的**懒槽位：
  // 与 Flutter 一致，保活声明的生效范围是「最近的 AutomaticKeepAlive 祖先」，
  // 所以向上找第一个 `__lazySlot` 占位结点即可（不越级影响外层槽位）。
  // 没有懒槽位祖先（如页面根组件）时什么也不做。
  function syncEnclosingKeepAlive(inst) {
    var p = inst;
    while (p) {
      if (p.__lazySlot) {
        syncKeepAlive(p);
        return;
      }
      p = p.__parent;
    }
  }

  // 父级重建时更新一个**已存在**的懒槽位（幂等，绝不在这里做首次挂载）：
  // 未挂载的只替换来源；已挂载的把新元素 patch 到真实子树上，渲染根 id 变化
  // 时更新占位结点的 `child` slot（与 propsChildAt 同语义）。
  // 两个分支都刷新来源：宿主 dispose 后槽位要按**最新**来源重新生成（see
  // lazyUnmount），旧快照会让滚回来的 item 渲染成旧 props。
  function patchLazySlot(ph, src) {
    ph.__deferred = src ? src.el : null;
    ph.__deferMake = src ? src.make : null;
    if (!ph.__mountedChild) {
      return ph;
    }
    var el = lazyElementOf(src);
    if (el == null || el === false) {
      // builder 返回空属错误写法（Flutter 侧会直接抛错）：保留已挂载子树并留痕。
              console.warn('jsui: lazy slot builder returned empty, keep mounted subtree');
      
      return ph;
    }
    // 与原生 Flutter 对齐：父级每次重建都会重新执行 itemBuilder，并把产出的新
    // 元素 patch 到已挂载的子树上——组件照常进 didUpdateWidget / build。
    // **不能**按「产出元素内容相同」短路：那会吞掉 didUpdateWidget 的副作用。
    // 例外只有引用相同（`const` 构造的同一实例，见 patch 的 `__el` 判等），
    // 此时与原生 `Element.updateChild` 的 `child.widget == newWidget` 一致。
    var oldRoot = ph.__mountedRootId;
    ph.__mountedChild = patch(ph.__mountedChild, el, ph, null);
    // 复用 / 新建的组件实例都要记住自己的父 slot：组件内部 setState 换掉渲染
    // 根时，patchComponentChild 靠它把新根 id 回报给本占位结点。
    if (ph.__mountedChild && ph.__mountedChild.__k !== HOST) {
      ph.__mountedChild.__propSlot = { parentId: ph.__id, key: 'child', index: 0 };
    }
    var newRoot = hostIdOf(ph.__mountedChild);
    if (newRoot !== oldRoot) {
      ph.__mountedRootId = newRoot;
      ph.__propsChildren['child'] = ph.__mountedChild;
      emit({ op: 'propsChild', parent: ph.__id, key: 'child', childId: newRoot });
    }
    // 父级重建路径的保活声明同步（组件自身 setState 引起的变化走 flush 的
    // syncEnclosingKeepAlive，见【9】）。
    syncKeepAlive(ph);
    return ph;
  }

  // 宿主 inflate 到懒槽位 → 真正挂载它的子元素（幂等：只对还没挂载过的占位生效）。
  // ops 纪律与 mountRoot 一致：挂载期间 `root.ops` 归本次挂载累积，挂载期间的
  // setState 只入 dirty 队列，收尾再 flush（见【9】）。
  function lazyMount(placeholderId) {
    var ph = hostNodes[placeholderId];
    if (!ph || (!ph.__deferred && !ph.__deferMake)) { return false; }
    // 延迟工厂（builder 子项）在这里才执行：全树只展开「宿主真正 inflate 到」的那些。
    var el = ph.__deferred;
    if (el == null && ph.__deferMake) { el = ph.__deferMake(); }
    if (el == null || el === false) {
              console.warn('jsui: lazy slot builder returned empty, placeholder=' + placeholderId);
      
      return false;
    }
    // 来源**保留**：宿主 dispose（ListView 回收离屏项）后还要按同一来源重建，
    // 见 lazyUnmount。
    var root = ph.__root || rootFor(ph.__parent);
    if (!root) { return false; }
    var prev = activeRoot;
    activeRoot = root;
    root.mounting = true;
    root.ops = [];
    var frame = beginMountFrame();
    var ok = true;
    try {
      // 真实子树的父结点是**占位结点**（宿主侧同样的父子关系），作用域链 /
      // BuildContext 锚点与「直接挂在容器下」一致。
      var inst = mount(el, ph, null);
      ph.__mountedChild = inst;
      ph.__mountedRootId = hostIdOf(inst);
      ph.__propsChildren = ph.__propsChildren || {};
      ph.__propsChildren['child'] = inst;
      if (inst && inst.__k !== HOST) {
        inst.__propSlot = { parentId: ph.__id, key: 'child', index: 0 };
      }
      // 占位从「零尺寸空隙」变为「透传容器」：只去掉尺寸，**保留**懒槽位标记与
      // 回调句柄——宿主 element 再次 dispose 时要靠 `__lazyOffFn` 反查，重新
      // inflate 时也要靠 `__lazy` 重新回调 lazyMount。占位结点本身保留
      //（id / element key 不变），父容器不需要任何列表换位。
      var mountedProps = { __lazy: true, __lazyFn: lazyMountFn, __lazyOffFn: lazyUnmountFn };
      if (ph.__props && ph.__props.key !== undefined) { mountedProps.key = ph.__props.key; }
      // 保活声明随挂载一起下发：宿主 _JsNode 据此注册 KeepAlive，切走 tab 时
      // element 不被销毁 → 不会回调 lazyUnmount，JS 侧 State 与已加载数据保留。
      if (subtreeWantsKeepAlive(inst)) { mountedProps.__keepAlive = true; }
      ph.__props = mountedProps;
      emit({ op: 'props', id: ph.__id, props: ph.__props });
      emit({ op: 'propsChild', parent: ph.__id, key: 'child', childId: ph.__mountedRootId });
      commit(root);
    } catch (e) {
      // 本次尝试失败：commit 未发生，宿主侧没有半棵树（create/insert 随 ops 一起
      // 丢弃），故不需要发 remove；只回滚 JS 侧**本次新增**的结点与句柄。
      // 占位的 `__deferred` / `__deferMake` / props 都没改过（props 在挂载成功后
      // 才 emit），宿主下次 inflate 仍会回调到这里重试。
      ok = false;
      rollbackMountFrame(frame);
      root.ops = null;
              console.error('jsui: lazy slot mount failed, placeholder=' +
          placeholderId + ': ' + e);
      
    } finally {
      endMountFrame(frame);
      root.mounting = false;
      activeRoot = prev;
    }
    // 挂载期间累积的 setState（如 initState 里同步 setState）补一次 flush。
    // 失败路径里本次实例已被回滚标成 __unmounted，flush 的 `continue` 会跳过；
    // 不能清 root.dirty —— 其中可能还有同页其他组件已入队的重建。
    if (root.dirty.length) { flushNow(root); }
    return ok;
  }

  // 宿主 element dispose（ListView 回收离屏项 / 页面销毁）→ 卸载已挂载的子树，
  // 槽位本身与来源保留；宿主再次 inflate 时 lazyMount 按来源重新构建（与 Flutter
  // 「离屏项 State 销毁、滚回再 initState」一致）。幂等：未挂载的槽位直接跳过。
  function lazyUnmount(placeholderId) {
    var ph = hostNodes[placeholderId];
    if (!ph || !ph.__mountedChild) { return false; }
    var root = ph.__root || rootFor(ph.__parent);
    if (!root) { return false; }
    var inst = ph.__mountedChild;
    ph.__mountedChild = null;
    ph.__mountedRootId = null;
    if (ph.__propsChildren) { delete ph.__propsChildren['child']; }
    var prev = activeRoot;
    activeRoot = root;
    root.mounting = true;
    root.ops = [];
    try {
      // 已卸载：撤下 keep-alive 声明（下次挂载按新实例重新评估，避免带着旧声明
      // 让新建 element 在未挂载时就被保活）。
      if (ph.__props && ph.__props.__keepAlive) {
        delete ph.__props.__keepAlive;
        emit({ op: 'props', id: ph.__id, props: ph.__props });
      }
      // unmount 派发 deactivate → dispose，并下发子树 remove；宿主侧的 element
      // 已随本次 dispose 一起销毁，store 按 remove 递归摘除结点。
      unmount(inst);
      emit({ op: 'propsChildRemove', parent: ph.__id, key: 'child' });
      commit(root);
    } finally {
      root.mounting = false;
      activeRoot = prev;
    }
    if (root.dirty.length) { flushNow(root); }
    return true;
  }

  // 普通类组件（生成器产物不 extends Component）挂载基类能力：
  //   [mini-react] props / setState / __bindFn（构建期事件句柄）
  //   [ctx]        context（BuildContext 代理 —— build 传参 / `this.context`）
  // 对 extends Component 的类重复赋值无害。
  function augment(inst) {
    if (inst.props === undefined || inst.props === null) {
      inst.props = inst.__el ? inst.__el.props : {};
    }
    inst.setState = Component.prototype.setState;
    inst.__bindFn = Component.prototype.__bindFn;
    // 与 Dart 一致：`context` 既是 build 形参、也是实例上可访问的同一对象。
    // 事件/延迟作用域里形参不可见，`this.context` 是同步可达路径。
    //
    // **按执行位置解析**：`building` 非空时取**它的**代理。被委托的 builder 方法
    // （`_builderN` / `_consumerBuilderN` / `_lbBuilderN`，由 Builder / Consumer /
    // ListView.builder 代理以 `owner[..].call(owner, context, …)` 调用）里 `this`
    // 是 owner，而 `this.context` 必须是**被委托组件**的代理（它在 provider 子树
    // 之内）——这正是 Dart 里闭包捕获 `context` 形参的语义。`this === building`
    // 的路径（组件自身 build、顶层绑定）行为不变。
    // 惰性：不用 context 的组件不建代理、不建跨语言句柄。
    Object.defineProperty(inst, 'context', {
      configurable: true,
      get: function () { return contextOf(building || this); }
    });
  }

  // 在 [inst] 的 build 执行期间把 `building` 指向它 —— 事件绑定据此拿到
  // 「当前构建位置」。building 只在同步的 build 调用内有效，退出即还原
  // （委托型组件的 builder 方法在 build 调用栈内执行，故锚点仍是该结点）。
  //
  // 按 Dart 签名把 BuildContext 代理**传进去**：`build(context)`。
  function buildOf(inst) {
    var prev = building;
    building = inst;
    // `__building` 标记「本实例正处在 build 执行期」，供 markDirty 拦截 build 内
    // setState（见【9】）。**不能用锚点 `building` 代替**：initState /
    // didUpdateWidget 期间锚点也指向本实例，那两个阶段 setState 是合法写法。
    inst.__building = true;
    try { return inst.build(contextOf(inst)); }
    finally { inst.__building = false; building = prev; }
  }

  function mount(el, parent, slot) {
    el = asElement(el);
    if (el == null || el === false) { return null; }

    if (typeof el.type === 'string') {
      var hi = {
        __k: HOST, __id: nodeId(el.type), __type: el.type, __root: rootFor(parent),
        __props: el.props, __children: [], __parent: parent, __el: el
      };
      // 作用域声明（`__provides`）：由该宿主类型注册的 publisher 折算（【8】）。
      applyScope(hi, el.props);
      hostNodes[hi.__id] = hi;
      trackNode(hi.__id);
      emit({ op: 'create', id: hi.__id, type: hi.__type, props: hi.__props });
      if (slot && slot.hostParentId) {
        emit({ op: 'insert', parent: slot.hostParentId, id: hi.__id, index: slot.index });
      }
      var idx = 0;
      // 懒容器（如 TabBarView / ListView.builder(itemExtent:)）的 children 先只
      // 下发零尺寸占位（见 newLazySlot）：真实子树等宿主 inflate 到该槽位时
      // 回调再挂；builder 形态连 itemBuilder 的调用也一并推迟（见 childSources）。
      // 懒标记来自元素本身（生成的 __h 按构建期配置写入），运行时不做类型判断。
      var lazyChildren = el.lazyChildren === true;
      var srcs = childSources(el, hi, lazyChildren);
      for (var i = 0; i < srcs.length; i++) {
        var src = srcs[i];
        if (!lazyChildren && (src.el == null || src.el === false)) { continue; }
        var c = lazyChildren
            ? newLazySlot(hi, src, { kind: 'children', hostParentId: hi.__id, index: idx })
            : mount(src.el, hi, { hostParentId: hi.__id, index: idx });
        if (c) { hi.__children.push(c); idx += 1; }
      }
      // props 里的 widget（单值 / 数组）与 delegate：单独挂载，不入 flatten
      // 列表，各自按 prop 名缓存（Scaffold.body / AppBar.actions 等）。
      hi.__propsChildren = {};
      hi.__propsChildrenList = {};
      hi.__propsData = {};
      patchPropSlots(hi, el.children || {}, lazyChildren);
      return hi;
    }

    var ownFrame = beginConstruct();
    var ci;
    try {
      // 翻译层已经构造好的实例随元素下发（`el.inst`）→ 直接复用，不再 new
      // 第二次；通过 `__h(X, props)` 创建的元素没有实例，才在这里构造。
      // 已卸载（dispose 过）的实例不得复用：懒槽位被宿主回收后，滚回来时元素
      // 仍带着上次那份实例引用，复用会拿到已 release 的控制器/句柄。
      // 已挂在树上的实例同样不得复用：Dart 允许同一 Widget 实例出现在两个槽位
      // （每处各自 new 一个 State），`__asElementList` 会为同一实例产出两个元素；
      // 复用会让第二处覆盖 `__parent/__slot`、状态串位，第一处子树在 JS 侧失联。
      ci = (el.inst && !el.inst.__unmounted && !el.inst.__parent)
          ? el.inst
          : new el.type(el.props, el.children);
    } catch (e) {
      endConstruct(null, ownFrame);
      throw e;
    }
    ci.__k = COMP;
    ci.__id = compId(el.type);
    // 构造期（字段初始化）里登记的控制器 / Key 句柄归属本实例：此刻 `ci` 才存在，
    // 故构造期间先暂存、新对象返回后再回填（见 handle_registry_js 的 beginConstruct）。
    endConstruct(ci, ownFrame);
    // 记入挂载事务帧（若有）：构造已成功、控制器等句柄已归属本实例，之后
    // initState / didChangeDependencies / build 任何一步抛错都要按帧回收。
    trackInst(ci);
    ci.__el = el;
    // 让「父级直接把实例当子结点传入」的折算也拿到同一份元素（见 asElement）。
    ci.__elCache = el;
    ci.__parent = parent;
    ci.__slot = slot;
    ci.__root = rootFor(parent);
    augment(ci);
    // 生命周期与 Flutter 对齐：initState → didChangeDependencies → build。
    // （后续「依赖变更」走 flush 的 __depDirty，「父级重建」走 patch 的
    //  didUpdateWidget，见【9】/【10】。）
    // initState 期间也把构建锚点指向本实例：此时 `this.context` 与新建句柄的
    // 归属都应以本组件为准（过去 building 只在 buildOf 里设置，initState 看到的是父级）。
    var prevBuilding = building;
    building = ci;
    try {
      if (typeof ci.initState === 'function') { ci.initState(); }
      if (typeof ci.didChangeDependencies === 'function') { ci.didChangeDependencies(); }
    } finally {
      building = prevBuilding;
    }
    ci.__child = mount(buildOf(ci), ci, slot);
    return ci;
  }

  function patch(oldInst, el, parent, slot, propSlot) {
    el = asElement(el);
    if (el == null || el === false) {
      if (oldInst) { unmount(oldInst); }
      return null;
    }
    if (!oldInst) {
      var mi = mount(el, parent, slot);
      if (mi && propSlot) { mi.__propSlot = propSlot; }
      return mi;
    }

    // 对齐 Flutter `Element.updateChild` 的 `child.widget == newWidget` 短路：
    // 两种情况命中短路：
    //   1. 元素本身完全相同（`__el` 就是同一个对象，asElement 缓存命中）；
    //   2. 底层实例完全相同（`el.inst` 就是同一个 const 缓存实例，覆盖 __asElement
    //      每次折算得到新元素对象但实例还是同一个的场景，如懒容器 children 数组）；
    // 只认引用相等，绝不做 props 值比较——非 const 子组件即使 props 完全相同，
    // 父级重建时也必须走 didUpdateWidget（见 patchLazySlot 的约定）。
    if (oldInst.__el === el || (el.inst && el.inst === oldInst)) {
      if (propSlot) { oldInst.__propSlot = propSlot; }
      return oldInst;
    }

    var newIsHost = (typeof el.type === 'string');
    var oldIsHost = (oldInst.__k === HOST);
    var sameType = oldIsHost
      ? (newIsHost && oldInst.__type === el.type)
      : (!newIsHost && oldInst.constructor === el.type);
    if (!sameType) {
      unmount(oldInst);
      return mount(el, parent, slot);
    }

    if (oldIsHost) {
      var oldProps = oldInst.__props;
      if (!eq(oldProps, el.props)) {
        emit({ op: 'props', id: oldInst.__id, props: el.props });
      }
      oldInst.__props = el.props;
      oldInst.__el = el;
      // props 变更 → 作用域声明重放（provider 的 vm 实例可能已换）。
      applyScope(oldInst, el.props);
      // 子项来源按新元素声明的懒标记生成：懒容器下 builder 形态只带延迟工厂，
      // 已挂载的槽位由 patchLazySlot 现场调用工厂重建该项。
      var lazyChildren = el.lazyChildren === true;
      patchChildren(oldInst, childSources(el, oldInst, lazyChildren), lazyChildren);
      patchPropSlots(oldInst, el.children || {}, lazyChildren);
      return oldInst;
    }

    // 复用同一实例（= Flutter 的 State 复用），只替换 element（= 新 Widget）。
    // 先取旧 props 作为 oldWidget 快照（el.props 每次 build 都是新对象，故旧引用
    // 自然保留），再把新 props 落到实例（`widget` 即新值），然后以旧 props 回调
    // didUpdateWidget，最后 build——顺序与 Flutter 完全一致。
    var oldWidget = oldInst.props;
    oldInst.__el = el;
    // 实例侧的折算缓存同步到最新元素：父级若再次直接把该实例当子结点传入，
    // asElement 必须拿到 props 与实例一致的那份描述。
    oldInst.__elCache = el;
    oldInst.props = el.props;
    // props 变更 → 重新派生「构造参数字段」。生成器产物把 `this.x = args.x` 的
    // 参数↔字段映射放在 `__applyProps` 里；复用实例不会重跑构造函数，若不在此
    // 同步一次，子组件会一直拿着旧 props 派生的字段（如列表项不随排序刷新）。
    if (typeof oldInst.__applyProps === 'function') {
      oldInst.__applyProps(el.props);
    }
    // didUpdateWidget 期间把构建锚点指向本实例（新建句柄的归属 / this.context）。
    var prevBuilding = building;
    building = oldInst;
    try {
      if (typeof oldInst.didUpdateWidget === 'function') {
        oldInst.didUpdateWidget(oldWidget);
      }
    } finally {
      building = prevBuilding;
    }
    // 记住父级 slot 位置：组件内部 setState 重建走 flush 的
    // patchComponentChild，也要靠它把「渲染根 id 变化」回报给父 slot。
    if (propSlot) { oldInst.__propSlot = propSlot; }
    patchComponentChild(oldInst);
    return oldInst;
  }

  /// 组件 build 出新子树，并在渲染根 id 变化时回报父 slot（propsChildAt）。
  function patchComponentChild(inst) {
    var oldRoot = hostIdOf(inst);
    inst.__child = patch(inst.__child, buildOf(inst), inst, inst.__slot);
    var slot = inst.__propSlot;
    var newRoot = hostIdOf(inst);
    if (slot && newRoot !== oldRoot) {
      if (newRoot == null) {
        // build 返回空只可能来自产物缺陷：Dart 的 `Widget build()` 必返回
        // Widget，生成器对无法翻译的 widget 位置也会降级成 SizedBox 占位。
        // 宿主侧 propsChildAt 的 childId 为空无法落位（会被丢弃，数组槽位因此
        // 留一个空位），这里必须出声，不静默。
                  console.error('jsui: component render root is empty after build (' +
            compName(inst.constructor) + ')');
        
        return inst.__child;
      }
      emit({
        op: 'propsChildAt', parent: slot.parentId, key: slot.key,
        index: slot.index, childId: newRoot
      });
    }
    return inst.__child;
  }

  // 子项 keyed 匹配器（`patchChildren` / `patchSlotList` 共用**唯一一份**实现）。
  //
  // 旧实现每个子项都做「线性扫 remaining + splice + indexOf」→ O(n²)：100 项列表
  // 每次重建约 1 万次比较、100 次数组搬移。这里一次建索引，之后每项 O(1)：
  //   - 带 key：`keySig` → 实例（同签名只认领一个，重复 key 按新建处理）；
  //   - 无 key：按旧序游标推进（保持「位置优先」的复用语义）；
  //   - 位置：`__id` → 旧下标，move 判定不再 `indexOf`。
  //
  // `take(ek)` 返回本轮可复用的旧实例（没有则 null）；`leftovers()` 返回未被
  // 认领的旧实例（调用方负责 unmount）。
  function keyedMatcher(oldList) {
    var byKey = {};
    var unkeyed = [];
    var posById = {};
    var consumed = {};
    var i;
    for (i = 0; i < oldList.length; i++) {
      var inst = oldList[i];
      if (!inst) { continue; }
      if (inst.__id != null) { posById[inst.__id] = i; }
      var k = keySig(keyOf(inst));
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

  // [srcs] 是子项来源（见 childSources）：`{el}` 直接元素 / `{make}` 延迟工厂。
  // [lazy] 来自新元素的 `el.lazyChildren`（运行时不做类型判断）。
  function patchChildren(parentHost, srcs, lazy) {
    var old = parentHost.__children || [];
    var matcher = keyedMatcher(old);
    var next = [];
    var hostIdx = 0;
    var i, j;
    for (j = 0; j < srcs.length; j++) {
      var src = srcs[j];
      if (!src) { continue; }
      var el = src.el !== undefined ? src.el : null;
      // 延迟工厂形态在展开前没有 element（也没有 key），只能按位置匹配。
      if (src.el !== undefined && (el == null || el === false)) { continue; }
      var ek = keySig(el && el.props ? el.props.key : null);
      var matched = matcher.take(ek);

      // 已存在的懒槽位（未挂载的来源 / 已挂载的 `__mountedChild`）→ 只更新子元素，
      // **绝不能**在这里把未挂载的槽位挂出来，否则重建（外壳每次切 tab 都会整树
      // patch）会把懒加载整个破坏掉。
      if (matched && lazy && matched.__lazySlot) {
        matched.__slot = { kind: 'children', hostParentId: parentHost.__id, index: hostIdx };
        patchLazySlot(matched, src);
        // 懒槽位同样要跟随排序：宿主 `childIds` 的顺序只由 insert/move 决定。
        if (matcher.positionOf(matched) !== hostIdx) {
          emit({ op: 'move', parent: parentHost.__id, id: matched.__id, index: hostIdx });
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
        if (matched) { unmount(matched); }
        next.push(newLazySlot(parentHost, src, {
          kind: 'children', hostParentId: parentHost.__id, index: hostIdx
        }));
        hostIdx += 1;
        continue;
      }

      // 非懒容器（或懒容器里已提前挂载的旧结点）：此处必须有 element；
      // 延迟工厂形态（如容器从 lazy 变为非 lazy）在此现场展开一次。
      var cel = el !== null ? el : lazyElementOf(src);
      if (cel == null || cel === false) { continue; }
      var inst = patch(matched, cel, parentHost, { hostParentId: parentHost.__id, index: hostIdx });
      if (inst) {
        // 复用的结点位置变化 -> 下发 move（新建的自带 insert）。
        if (inst === matched && matcher.positionOf(inst) !== hostIdx) {
          emit({ op: 'move', parent: parentHost.__id, id: hostIdOf(inst), index: hostIdx });
        }
        next.push(inst);
        hostIdx += 1;
      }
    }

    var leftovers = matcher.leftovers();
    for (i = 0; i < leftovers.length; i++) {
      unmount(leftovers[i]);
    }
    parentHost.__children = next;
  }

  // props 里的 slot：值可能是单个元素、元素数组，或 delegate 描述
  // （`{__delegate:'list'|'builder', …}`）。元素判据是 __h 统一加的
  // `element: true` 标记，不做 `{type, props}` 形状猜测。
  function isElement(v) {
    return v != null && typeof v === 'object' && v.element === true;
  }
  function isElementList(v) {
    if (!Array.isArray(v) || v.length === 0) { return false; }
    for (var i = 0; i < v.length; i++) {
      if (v[i] != null && !isElement(v[i])) { return false; }
    }
    return true;
  }

  // 列表型 slot 的 keyed diff：复用已有实例，新键挂载，缺失卸载。
  // 不向宿主发 insert/move（宿主按 propsChildren 整表替换）。
  // 父结点是懒容器时，**每一项**都先落成懒槽位（未 visit 的子页不挂载）：
  // 已有槽位只更新 deferred / patch 子树；新项创建占位而不是立刻 mount。
  // [lazy] 由所在宿主元素的 `el.lazyChildren` 传入（运行时不做类型判断）。
  function patchSlotList(parentHost, oldList, newEls, slotKey, lazy) {
    var matcher = keyedMatcher(oldList);
    var next = [];
    var j;
    for (j = 0; j < newEls.length; j++) {
      var el = newEls[j];
      if (el == null || el === false) { continue; }
      var ek = keySig(el.props ? el.props.key : null);
      var matched = matcher.take(ek);
      var slotIndex = next.length;
      if (lazy) {
        var ph = matched && matched.__lazySlot ? matched : null;
        if (matched && !ph) {
          // 同 patchChildren：容器切到懒态时旧子结点必须换成懒槽位，否则宿主
          // dispose 时不会回调 `__lazyOffFn`，JS 子树永久驻留。
          unmount(matched);
        }
        if (!ph) {
          ph = newLazySlot(parentHost, { el: el }, { kind: 'prop' });
        } else {
          patchLazySlot(ph, { el: el });
        }
        next.push(ph);
        continue;
      }
      var inst = patch(matched, el, parentHost, null, {
        key: slotKey,
        index: slotIndex,
        parentId: parentHost.__id
      });
      if (inst) { next.push(inst); }
    }
    var leftovers = matcher.leftovers();
    for (var i = 0; i < leftovers.length; i++) {
      unmount(leftovers[i]);
    }
    return next;
  }

  function patchPropSlots(hostInst, newSlots, lazy) {
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
      if (isElement(v)) {
        var prev = oldS[k] || null;
        var inst = patch(prev, v, hostInst, null);
        if (inst) {
          nextS[k] = inst;
          emit({ op: 'propsChild', parent: hostInst.__id, key: k, childId: hostIdOf(inst) });
        }
        // 本 key 上其他形态的旧绑定（列表 / delegate）由下面的清理循环统一
        // 卸载并解绑：这里再 unmount 一次会让组件 dispose() 跑两遍。
        continue;
      }
      if (isElementList(v)) {
        var arr = patchSlotList(hostInst, oldL[k] || [], v, k, lazy);
        nextL[k] = arr;
        emit({
          op: 'propsChildren', parent: hostInst.__id, key: k,
          childIds: arr.map(hostIdOf)
        });
        continue;
      }
      if (v != null && typeof v === 'object' && v.__delegate) {
        if (v.__delegate === 'list') {
          var arr2 = patchSlotList(hostInst, oldL[k] || [], v.children || [], k, lazy);
          nextL[k] = arr2;
          emit({
            op: 'propsChildren', parent: hostInst.__id, key: k,
            childIds: arr2.map(hostIdOf)
          });
          nextD[k] = { __delegate: 'list' };
        } else {
          nextD[k] = v;
          emit({ op: 'propsData', parent: hostInst.__id, key: k, value: v });
        }
        continue;
      }
    }
    for (k in oldS) {
      if (!nextS[k]) {
        unmount(oldS[k]);
        emit({ op: 'propsChildRemove', parent: hostInst.__id, key: k });
      }
    }
    for (k in oldL) {
      if (!nextL[k]) {
        for (i = 0; i < oldL[k].length; i++) { unmount(oldL[k][i]); }
        emit({ op: 'propsChildren', parent: hostInst.__id, key: k, childIds: [] });
      }
    }
    for (k in oldD) {
      if (!nextD[k]) { emit({ op: 'propsDataRemove', parent: hostInst.__id, key: k }); }
    }
    hostInst.__propsChildren = nextS;
    hostInst.__propsChildrenList = nextL;
    hostInst.__propsData = nextD;
  }

  function unmount(inst) {
    if (!inst) { return; }
    var hostId = hostIdOf(inst);
    if (hostId) { emit({ op: 'remove', id: hostId }); }
    markUnmounted(inst);
  }

  function markUnmounted(inst) {
    // 幂等：同一结点可能经「自身 + 祖先递归」两条路径到达（事务帧回滚时逆序
    // teardown 尤其如此）。不拦会 `dispose()` 执行两遍、句柄二次释放。
    if (!inst || inst.__unmounted) { return; }
    inst.__unmounted = true;
    if (inst.__k === HOST) {
      delete hostNodes[inst.__id];
      for (var i = 0; i < inst.__children.length; i++) { markUnmounted(inst.__children[i]); }
      var pcs = inst.__propsChildren;
      if (pcs) { for (var pk in pcs) { markUnmounted(pcs[pk]); } }
      var pcl = inst.__propsChildrenList;
      if (pcl) {
        for (var lk in pcl) {
          for (var li = 0; li < pcl[lk].length; li++) { markUnmounted(pcl[lk][li]); }
        }
      }
    } else {
      // 与 Flutter 一致：从树上摘除时先 deactivate、再最终 dispose。
      // 生命周期期间把构建锚点指向本实例（`this.context` / 新建句柄归属）。
      var prevBuilding = building;
      building = inst;
      try {
        if (typeof inst.deactivate === 'function') {
          // 生命周期异常不能静默吞掉：卸载路径出错的后果是「句柄泄漏 / 监听未摘」，
          // 线上只能靠这条日志定位（release 下 console 是空函数，无额外开销）。
          try {
            inst.deactivate();
          } catch (e) {
                          console.error('deactivate failed: ' + (e && e.message ? e.message : String(e)));
            
          }
        }
        if (typeof inst.dispose === 'function') {
          try {
            inst.dispose();
          } catch (e) {
                          console.error('dispose failed: ' + (e && e.message ? e.message : String(e)));
            
          }
        }
      } finally {
        building = prevBuilding;
      }
      // [scope] 从各被监听值的监听表里摘掉自己（订阅登记在消费者侧 `__subs`）。
      unsubscribeAll(inst);
      // [ctx] 释放 BuildContext 代理句柄。**必须通知宿主**：代理在宿主侧有
      // 真实记录（句柄→结点），纯本端删除会让宿主那条记录留到页面销毁。
      // 与页面兜底 releasePageHandles 幂等（先删者胜，第二次是空操作）。
      if (inst.__ctx != null && inst.__ctx.__id != null) {
        releaseHandle(inst.__ctx.__id);
        inst.__ctx = null;
      }
      // [mini-react] 释放构建期登记的 (位点号, 捕获值) 事件句柄，避免句柄泄漏。
      var bagFn = inst.__boundFn;
      if (bagFn) {
        for (var k in bagFn) { releaseHandle(bagFn[k].__fn, false); }
        inst.__boundFn = null;
      }
      markUnmounted(inst.__child);
      // [owner] 释放该实例持有的句柄（控制器 / Key 等）：先递归卸载子树，再
      // 整份释放——与 Dart 的 State.dispose 顺序一致。`dispose()` 里显式释放
      // 过的句柄已被移出 `__owns`，这里幂等跳过。
      releaseOwnerHandles(inst);
    }
  }

  // 整页挂载失败的回滚（mountRoot 的 catch 调用）。此刻 `root.inst` **尚未赋值**
  // （mount 的返回值还没落到根上），半棵子树不可达，不能走 unmount；只能按归属
  // 清扫：宿主结点看 `__root`，句柄看 `key === pageKey`（挂载期登记的一切句柄：
  // page 作用域 / 事件闭包 / 实例持有的控制器、Key、ctx）或 `owner.__root`
  // （兜底：判据不依赖 reg 时 activeRoot 是否已就位）。
  function abortRoot(root) {
    var pageKey = root.key;
    var seen = {}, list = [], i;
    for (var id in hostNodes) {
      var node = hostNodes[id];
      if (node && node.__root === root) { delete hostNodes[id]; }
    }
    var arr = pageHandles[pageKey] || [];
    for (i = 0; i < arr.length; i++) { seen[arr[i]] = 1; list.push(arr[i]); }
    for (var hid in handles) {
      if (seen[hid]) { continue; }
      var h = handles[hid];
      if (!h) { continue; }
      if (h.key === pageKey || (h.owner && h.owner.__root === root)) {
        seen[hid] = 1;
        list.push(hid);
      }
    }
    // 逐条释放会同步通知宿主摘掉对端镜像记录；重复释放幂等。
    for (i = 0; i < list.length; i++) { releaseHandle(list[i]); }
    root.ops = null;
    root.dirty = [];
    root.flushPending = false;
    root.inst = null;
    delete roots[pageKey];
  }



// ===== 【11】对外入口 api =====
  function parse(x) {
    if (x == null || x === '') { return {}; }
    if (typeof x === 'string') {
      try { return JSON.parse(x); } catch (e) { return {}; }
    }
    return x;
  }

  function newRoot(pageKey) {
    return {
      // `mounting`：根组件挂载进行中。此刻 `root.ops` 正被 mountRoot 累积整棵树
      // 的 create/insert，而 flush 会**重置并消耗**同一份 ops（`root.ops = []`
      // 后 commit 把它置 null），既丢掉尚未下发的结点、又让随后的根 op 被 emit
      // 静默丢弃（宿主收不到根 → 页面停在加载态）。故挂载期间的 setState 只入
      // dirty 队列，挂载收尾后统一 flush（见【9】markDirty 与 mountRoot）。
      key: pageKey, inst: null, dirty: [], flushing: false,
      flushPending: false, mounting: false, ops: null
    };
  }

  // 挂载一个页面：pageKey 隔离根，moduleKey 定位模块，className 是组件类名。
  // 组件产物里 **JS 类名 = Dart 类名**，元素 type 就是这个类本身（JS 里没有
  // 「factory」这层包装）；`G[className]` 兜底全局注册的组件类。
  function mountRoot(pageKey, moduleKey, className, propsJson) {
    var mod = (G.__modules && G.__modules[moduleKey]) || null;
    var C = (mod && mod[className]) || G[className];
    if (!C) {
      throw new Error('jsui: component not found: ' + className + ' in ' + moduleKey);
    }
    var root = newRoot(pageKey);
    roots[pageKey] = root;
    var prev = activeRoot;
    activeRoot = root;
    root.mounting = true;
    try {
      root.ops = [];
      root.inst = mount(h(C, parse(propsJson), null), null, null);
      // 末位下发根结点 id，宿主据此挂载 _JsNode。
      emit({ op: 'root', id: hostIdOf(root.inst) });
      commit(root);
    } catch (e) {
      // 失败即整页回滚：本次 commit 未发生（宿主侧没有半棵树），但 JS 侧已创建
      // 的宿主结点索引与已同步过去的句柄会随每次重试累积——只进不出。
      // 见 abortRoot（按 __root / pageKey 归属清扫，不能走 unmount(root.inst)：
      // 抛错时 root.inst 还没赋值）。
      abortRoot(root);
      throw e;
    } finally {
      root.mounting = false;
      activeRoot = prev;
    }
    // 挂载期间累积的 setState（如子组件 initState 里 `setState(() => _loading = true)`）
    // 在这里补一次 flush：根补丁已下发，实例与结点都在，走的正是 patch 增量重建，
    // 与 Flutter「initState 里 setState → 首帧后再重建」语义一致。
    if (root.dirty.length) { flushNow(root); }
    return true;
  }

  function disposeRoot(pageKey) {
    var root = roots[pageKey];
    if (!root) { return; }
    // 只做正常卸载：组件 dispose 逐实例释放自己持有的句柄。**不做页面兜底**——
    // 兜底由宿主在泄漏比对之后显式调用 sweepPage，否则会把泄漏一并抹平。
    var prev = activeRoot;
    activeRoot = root;
    try {
      root.ops = [];
      unmount(root.inst);
      // 宿主随页面 widget 一并销毁，无需回传 remove。
      root.ops = null;
    } finally {
      activeRoot = prev;
    }
    root.inst = null;
    // 页面退出兜底（scope=page）：这类句柄就是「显式归页面所有」的，页面没了
    // 即应释放，属正常生命周期而非泄漏。scope=instance/local 的孤儿残留留给
    // 宿主在泄漏比对之后调用 sweepPage 处理。
    releasePageHandles(pageKey);
    delete roots[pageKey];
  }

  // 宿主侧 props 更新（Dart JsUiWidget.didUpdateWidget → 这里），与 Flutter
  // 「父级重建」语义对齐：替换根实例 props → 重跑 __applyProps（构造参数
  // 派生的字段）→ 回调 didUpdateWidget(oldWidget) → 标脏重建。
  // 根尚未 mount / 已 dispose 时返回 false（不静默：Dart 侧会按返回值记日志）。
  function updateRootProps(pageKey, propsJson) {
    var root = roots[pageKey];
    if (!root || !root.inst) { return false; }
    var inst = root.inst;
    var next = parse(propsJson);
    var prev = inst.props || {};
    inst.props = next;
    if (inst.__el) { inst.__el.props = next; }
    if (typeof inst.__applyProps === 'function') { inst.__applyProps(next); }
    var prevBuilding = building;
    building = inst;
    try {
      if (typeof inst.didUpdateWidget === 'function') {
        inst.didUpdateWidget(prev);
      }
    } finally {
      building = prevBuilding;
    }
    markDirty(inst);
    return true;
  }



// ===== 【12】Dart 值类（Duration / Size / Offset / Radius） =====
  // 构建期查不到构造签名时，位置实参以 `__pos: [...]` 下发；这里按形参名顺序
  // 展开。任何类都可复用，不含类名判断。
  function __posArgs(props, names) {
    if (!props || !props.__pos) { return props || {}; }
    var out = {};
    for (var k in props) {
      if (k !== '__pos') { out[k] = props[k]; }
    }
    for (var i = 0; i < names.length && i < props.__pos.length; i++) {
      out[names[i]] = props.__pos[i];
    }
    return out;
  }

  // Duration 产物键是 Dart 的命名实参（milliseconds / seconds / …），换算成
  // 毫秒后经 toJSON 下发；宿主 durationFromJson 只认 `{__duration: ms}` 与裸数字。
  function __durationMs(d) {
    if (d == null) { return null; }
    if (typeof d === 'number') { return d; }
    if (typeof d === 'object') {
      if (typeof d.__duration === 'number') { return d.__duration; }
      if (typeof d.inMilliseconds === 'number') { return d.inMilliseconds; }
    }
    return null;
  }
  function Duration(opts) {
    opts = __posArgs(opts, ['microseconds', 'milliseconds', 'seconds',
      'minutes', 'hours', 'days']);
    var ms = (opts.milliseconds || 0) + (opts.seconds || 0) * 1000 +
      (opts.minutes || 0) * 60000 + (opts.hours || 0) * 3600000 +
      (opts.days || 0) * 86400000;
    ms += (opts.microseconds || 0) / 1000;
    this.inMilliseconds = Math.round(ms);
    this.inMicroseconds = Math.round(ms * 1000);
  }
  Duration.prototype.toJSON = function () {
    return { __duration: this.inMilliseconds };
  };
  G.Duration = Duration;

  function Size(props) {
    props = __posArgs(props, ['width', 'height']);
    this.width = props.width;
    this.height = props.height;
  }
  Size.prototype.toJSON = function () {
    return { width: this.width, height: this.height };
  };
  // Dart `Size` 的命名构造 / 静态常量（产物按统一规则发射 `Size.fromHeight({…})`）。
  // **无界维度是 +∞**：跨桥时 `JSON.stringify(Infinity)` 得到 null，宿主侧按 ∞
  // 还原（见 js_widget_registry 的 PreferredSize / layout 约束的 null 约定）。
  Size.fromHeight = function (props) {
    props = __posArgs(props, ['height']);
    return new Size({ width: Infinity, height: props.height });
  };
  Size.fromWidth = function (props) {
    props = __posArgs(props, ['width']);
    return new Size({ width: props.width, height: Infinity });
  };
  Size.square = function (props) {
    props = __posArgs(props, ['dimension']);
    return new Size({ width: props.dimension, height: props.dimension });
  };
  Size.copy = function (props) {
    props = __posArgs(props, ['source']);
    return new Size({ width: props.source.width, height: props.source.height });
  };
  Size.zero = { width: 0, height: 0 };
  Size.infinite = { width: Infinity, height: Infinity };
  G.Size = Size;

  function Offset(props) {
    props = __posArgs(props, ['dx', 'dy']);
    this.dx = props.dx != null ? props.dx : 0;
    this.dy = props.dy != null ? props.dy : 0;
  }
  Offset.prototype.toJSON = function () {
    return { dx: this.dx, dy: this.dy };
  };
  G.Offset = Offset;

  function Radius(props) {
    props = __posArgs(props, ['radius']);
    var r = props.radius != null ? props.radius : (props.x != null ? props.x : 0);
    this.x = r;
    this.y = r;
  }
  Radius.circular = function (props) { return new Radius(props); };
  Radius.prototype.toJSON = function () { return { radius: this.x }; };
  G.Radius = Radius;

  // BoxConstraints：布局约束值对象（LayoutBuilder 的 builder 第二参）。宿主按
  // {minWidth, maxWidth, minHeight, maxHeight} 下发，无界维度发 null（JSON 不能
  // 表达 Infinity），这里还原成 +∞（见【18.8】）。
  function BoxConstraints(props) {
    props = __posArgs(props, ['minWidth', 'maxWidth', 'minHeight', 'maxHeight']);
    this.minWidth = props.minWidth != null ? props.minWidth : 0;
    this.maxWidth = props.maxWidth != null ? props.maxWidth : Infinity;
    this.minHeight = props.minHeight != null ? props.minHeight : 0;
    this.maxHeight = props.maxHeight != null ? props.maxHeight : Infinity;
  }
  __defineProtoGetter(BoxConstraints.prototype, 'biggest', function () {
    return new Size({ width: this.maxWidth, height: this.maxHeight });
  });
  __defineProtoGetter(BoxConstraints.prototype, 'smallest', function () {
    return new Size({ width: this.minWidth, height: this.minHeight });
  });
  __defineProtoGetter(BoxConstraints.prototype, 'isTight', function () {
    return this.minWidth >= this.maxWidth && this.minHeight >= this.maxHeight;
  });
  __defineProtoGetter(BoxConstraints.prototype, 'hasBoundedWidth', function () {
    return this.maxWidth < Infinity;
  });
  __defineProtoGetter(BoxConstraints.prototype, 'hasBoundedHeight', function () {
    return this.maxHeight < Infinity;
  });
  // 无界维度回 null：与宿主下发协议同形，保证跨语言往返一致。
  BoxConstraints.prototype.toJSON = function () {
    return {
      minWidth: this.minWidth,
      maxWidth: this.maxWidth === Infinity ? null : this.maxWidth,
      minHeight: this.minHeight,
      maxHeight: this.maxHeight === Infinity ? null : this.maxHeight,
    };
  };
  G.BoxConstraints = BoxConstraints;

  // TextSpan：Dart 富文本子树的值对象（RichText 的 `text`）。产物按统一规则
  // 发射 `new TextSpan({text, style, children, semanticsLabel})`；这里镜像字段，
  // 跨桥时由 JSON.stringify 递归序列化成普通对象，宿主 textSpanFromJson 再
  // 还原成真正的 TextSpan 树。
  function TextSpan(props) {
    props = __posArgs(props, ['text']);
    this.text = props.text;
    if (props.style != null) { this.style = props.style; }
    if (props.children != null) { this.children = props.children; }
    if (props.semanticsLabel != null) { this.semanticsLabel = props.semanticsLabel; }
  }
  G.TextSpan = TextSpan;


// ===== 【13】Dart 异常（StateError / ArgumentError / …） =====
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


// ===== 【14】Color 类族（Color / MaterialColor / ColorSwatch） =====
  function __toHex(v) {
    var n = (v >>> 0).toString(16).toUpperCase();
    while (n.length < 8) { n = '0' + n; }
    return '#' + n;
  }

  function Color(props) {
    props = __posArgs(props, ['value']);
    this.value = props.value != null ? (props.value >>> 0) : 0;
  }
  // 序列化：宿主 colorFromJson 只认 '#RRGGBB' / '#AARRGGBB'。
  Color.prototype.toJSON = function () { return __toHex(this.value); };
  Color.prototype.toString = function () { return __toHex(this.value); };
  Color.prototype.withAlpha = function (a) {
    return new Color({ value: ((a & 0xFF) << 24) | (this.value & 0x00FFFFFF) });
  };
  Color.prototype.withOpacity = function (o) {
    var a = Math.round(Math.max(0, Math.min(1, o)) * 255);
    return this.withAlpha(a);
  };
  Color.prototype.withValues = function (opts) {
    opts = __posArgs(opts, []);
    var a = opts.alpha != null ? Math.round(opts.alpha * 255) : this.alpha;
    var r = opts.red != null ? opts.red : this.red;
    var g = opts.green != null ? opts.green : this.green;
    var b = opts.blue != null ? opts.blue : this.blue;
    return Color.fromARGB({ a: a, r: r, g: g, b: b });
  };
  Object.defineProperty(Color.prototype, 'alpha', {
    get: function () { return (this.value >> 24) & 0xFF; }
  });
  Object.defineProperty(Color.prototype, 'red', {
    get: function () { return (this.value >> 16) & 0xFF; }
  });
  Object.defineProperty(Color.prototype, 'green', {
    get: function () { return (this.value >> 8) & 0xFF; }
  });
  Object.defineProperty(Color.prototype, 'blue', {
    get: function () { return this.value & 0xFF; }
  });
  Color.fromARGB = function (props) {
    props = __posArgs(props, ['a', 'r', 'g', 'b']);
    return new Color({ value: ((props.a & 0xFF) << 24) | ((props.r & 0xFF) << 16) |
      ((props.g & 0xFF) << 8) | (props.b & 0xFF) });
  };
  Color.fromRGBO = function (props) {
    props = __posArgs(props, ['r', 'g', 'b', 'opacity']);
    var o = props.opacity != null ? props.opacity : 1;
    return Color.fromARGB({ a: Math.round(o * 255), r: props.r, g: props.g, b: props.b });
  };
  Color.lerp = function (props) {
    props = __posArgs(props, ['a', 'b', 't']);
    var a = props.a || new Color({ value: 0 });
    var b = props.b || new Color({ value: 0 });
    var t = props.t == null ? 0.5 : props.t;
    function mix(x, y) { return Math.round(x + (y - x) * t); }
    return Color.fromARGB({
      a: mix(a.alpha, b.alpha), r: mix(a.red, b.red),
      g: mix(a.green, b.green), b: mix(a.blue, b.blue)
    });
  };
  G.Color = Color;

  // MaterialColor / MaterialAccentColor / ColorSwatch：值仍是 Color（主色），
  // 额外持各档位。档位同时挂在 `shadeNN` 与数字下标上，故 Dart 的
  // `Colors.red[400]` / `Colors.red.shade400` 在 JS 里都能原样求值。
  function __swatch(base, shades) {
    base.__shades = shades || {};
    return base;
  }
  function __swatchBase(props) {
    props = __posArgs(props, ['primary', 'swatch']);
    var v = props.value != null ? props.value : props.primary;
    return { value: v, swatch: props.swatch };
  }
  function MaterialColor(props) {
    var p = __swatchBase(props);
    Color.call(this, { value: p.value });
    __swatch(this, p.swatch);
  }
  MaterialColor.prototype = Object.create(Color.prototype);
  MaterialColor.prototype.constructor = MaterialColor;
  G.MaterialColor = MaterialColor;

  function MaterialAccentColor(props) {
    var p = __swatchBase(props);
    Color.call(this, { value: p.value });
    __swatch(this, p.swatch);
  }
  MaterialAccentColor.prototype = Object.create(Color.prototype);
  MaterialAccentColor.prototype.constructor = MaterialAccentColor;
  G.MaterialAccentColor = MaterialAccentColor;

  function ColorSwatch(props) {
    var p = __swatchBase(props);
    Color.call(this, { value: p.value });
    __swatch(this, p.swatch);
  }
  ColorSwatch.prototype = Object.create(Color.prototype);
  ColorSwatch.prototype.constructor = ColorSwatch;
  G.ColorSwatch = ColorSwatch;


// ===== 【15】ChangeNotifier 基类 =====
// ChangeNotifier 基类（IIFE 骨架内定义，挂 G 供产物继承）。
//
// **职责只有一件事：提供模型本体**。addListener / removeListener 保留在 JS
// 侧（JS 自身逻辑要订阅模型），notifyListeners 双路派发：
//   ① 本端 `_listeners`（JS 侧逻辑 / JS 侧消费者重建）；
//   ② 跨语言 `handleOp(__id, 'notify')`（通知 Dart 端**通用镜像**
//      JsChangeNotifier，驱动 Dart 侧 ChangeNotifierProvider 子树刷新）。
// 构造时登记句柄（kind=notifier/ChangeNotifier），meta.type = JS 端类名 —— Dart 端的
// 通用镜像据此「记下它的 JS 端类型」（context.watch<T>() 的类型一路传到这里）。
function ChangeNotifier() {
  this._listeners = [];
  this.__id = reg(this, 'notifier/ChangeNotifier', {
    meta: { type: (this.constructor && this.constructor.name) || 'ChangeNotifier' }
  });
}
ChangeNotifier.prototype.addListener = function(f) {
  this._listeners.push(f);
};
ChangeNotifier.prototype.removeListener = function(f) {
  var i = this._listeners.indexOf(f);
  if (i >= 0) {
    this._listeners.splice(i, 1);
  }
};
ChangeNotifier.prototype.notifyListeners = function() {
  var ls = this._listeners.slice();
  for (var i = 0; i < ls.length; i++) { ls[i](); }
  // 双路之②：JS→宿主只有异步桥，故这里是 fire-and-forget（不阻塞本地派发）。
  if (this.__id != null) { handleOp(this.__id, 'notify'); }
};
// Dart ChangeNotifier.dispose：清空订阅（释放闭包引用）。被 dispose 后
// 不再响应 notify（原生语义：disposed 后 notify 抛错；JS 侧简化为静默）。
// 同时释放跨语言句柄 → 宿主端的通用镜像一并销毁（1:1 资源）。
ChangeNotifier.prototype.dispose = function() {
  this._listeners = [];
  if (this.__id != null) {
    releaseHandle(this.__id);
    this.__id = null;
  }
};
// 作为元素 prop 下发时（如 ChangeNotifierProvider 的 `notifier`）只带句柄 id：
// 真实对象只存在于 JS 端，宿主经句柄取到自己的通用镜像。
ChangeNotifier.prototype.toJSON = function() {
  return { __handle: this.__id };
};

// 顶层暴露：产物（模块 evaluate）里 `class X extends ChangeNotifier` 经
// globalThis 裸引用解析（与顶层 var 语义等价）。
G.ChangeNotifier = ChangeNotifier;

// ValueNotifier<T>：单值版 ChangeNotifier（`ValueNotifier<int>(0)`）。
//
// **不属于本基类的句柄 kind**：构造时经 ChangeNotifier 登记 `notifier/ChangeNotifier`，
// meta.type 由 `constructor.name` 自动取成 'ValueNotifier'，宿主镜像仍是通用
// JsChangeNotifier（无需新 kind，见 change_notifier_bridge.dart）。
//
// `value` 用 defineProperty 的 get/set 实现，setter 里 **=== 守卫**是
// `ValueListenableBuilder`「值不变不重建」语义的唯一来源：相同即 return，
// 不同才赋值并 notifyListeners()（与 Dart ValueNotifier 一致）。
function ValueNotifier(value) {
  ChangeNotifier.call(this);
  this._value = value;
}
ValueNotifier.prototype = Object.create(ChangeNotifier.prototype);
ValueNotifier.prototype.constructor = ValueNotifier;
Object.defineProperty(ValueNotifier.prototype, 'value', {
  configurable: true,
  enumerable: false,
  get: function () { return this._value; },
  set: function (v) {
    if (this._value === v) { return; }
    this._value = v;
    this.notifyListeners();
  },
});
G.ValueNotifier = ValueNotifier;

// ===== 【16】动画（Animation / AnimationController） =====
  // 只用于 JS 侧推导（AnimatedBuilder 读 value 时宿主已完成真实插值）；
  // 宿主侧按同名表还原真实 Curve（见 animation_from_json.curveFromJson）。
  function __animCurveFn(name) {
    switch (name) {
      case 'linear': return function (t) { return t; };
      case 'ease': case 'easeInOut': return function (t) {
        return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
      };
      case 'easeIn': return function (t) { return t * t; };
      case 'easeOut': return function (t) { return 1 - (1 - t) * (1 - t); };
      case 'fastOutSlowIn': return function (t) { return t * t * (3 - 2 * t); };
      default:
                  console.warn('[patch] 未登记的曲线 "' + name + '"，JS 侧按 linear 估算');
        
        return function (t) { return t; };
    }
  }

  // 生成器对 `Curves.easeOut` 这类「类名.成员」有两种落点（props 位会翻成
  // 成员名字符串，其它位置原样引用），运行时提供同名对象后两边口径一致。
  // 值一律是**成员名字符串**，宿主按名字查真实曲线 / 枚举（见
  // animation_from_json 的 curveFromJson / crossFadeStateFromJson）。
  var __CURVE_NAMES = [
    'linear', 'ease', 'easeIn', 'easeOut', 'easeInOut', 'easeInToLinear',
    'easeInSine', 'easeOutSine', 'easeInOutSine',
    'easeInQuad', 'easeOutQuad', 'easeInOutQuad',
    'easeInCubic', 'easeOutCubic', 'easeInOutCubic',
    'easeInQuart', 'easeOutQuart', 'easeInOutQuart',
    'easeInQuint', 'easeOutQuint', 'easeInOutQuint',
    'easeInExpo', 'easeOutExpo', 'easeInOutExpo',
    'easeInCirc', 'easeOutCirc', 'easeInOutCirc',
    'easeInBack', 'easeOutBack', 'easeInOutBack',
    'fastOutSlowIn', 'slowMiddle', 'decelerate',
    'bounceIn', 'bounceOut', 'bounceInOut',
    'elasticIn', 'elasticOut', 'elasticInOut',
    'fastLinearToSlowEaseIn', 'fastEaseInToSlowEaseOut'
  ];
  var Curves = {};
  for (var __ci = 0; __ci < __CURVE_NAMES.length; __ci++) {
    Curves[__CURVE_NAMES[__ci]] = __CURVE_NAMES[__ci];
  }
  G.Curves = Curves;

  G.CrossFadeState = { showFirst: 'showFirst', showSecond: 'showSecond' };

  // 只在 JS 侧推导 value；作为组件 props 下发时经 toJSON 带上 `__curve`，
  // 宿主用父控制器驱动同一条曲线（见 animation_bridge 的 jsDoubleAnimationOf）。
  function Tween(opts) {
    opts = opts || {};
    this.begin = opts.begin;
    this.end = opts.end;
  }
  Tween.prototype.lerp = function (t) {
    var b = this.begin, e = this.end;
    if (typeof b === 'number' && typeof e === 'number') { return b + (e - b) * t; }
    if (b && e && typeof b.dx === 'number' && typeof e.dx === 'number') {
      return new Offset(b.dx + (e.dx - b.dx) * t, b.dy + (e.dy - b.dy) * t);
    }
    return t < 0.5 ? b : e;
  };
  G.Tween = Tween;

  function CurvedAnimation(opts) {
    opts = opts || {};
    this.parent = opts.parent;
    this.curve = opts.curve;
  }
  Object.defineProperty(CurvedAnimation.prototype, 'value', {
    get: function () {
      var t = (this.parent && typeof this.parent.value === 'number') ? this.parent.value : 0;
      return __animCurveFn(this.curve)(t);
    }
  });
  CurvedAnimation.prototype.addListener = function (f) {
    if (this.parent && typeof this.parent.addListener === 'function') {
      this.parent.addListener(f);
    }
  };
  CurvedAnimation.prototype.removeListener = function (f) {
    if (this.parent && typeof this.parent.removeListener === 'function') {
      this.parent.removeListener(f);
    }
  };
  CurvedAnimation.prototype.toJSON = function () {
    return {
      __handle: this.parent ? this.parent.__id : null,
      __curve: this.curve,
      value: this.value
    };
  };
  G.CurvedAnimation = CurvedAnimation;

  // 真实控制器在宿主（Ticker 驱动）；本镜像只保存 value 与时长：
  //   - forward/reverse/repeat/stop/reset → `handleOp('call')`（载荷带 value 与
  //     时长，宿主据此对齐状态后再驱动）；
  //   - 宿主每帧回传 value → onHost 更新镜像 + __notify（JS listeners 据此重建）。
  var AnimationController = defineController('ctrl/Flash', {
    init: function (opts) {
      opts = opts || {};
      this._value = (typeof opts.value === 'number') ? opts.value : 0;
      this.lowerBound = (typeof opts.lowerBound === 'number') ? opts.lowerBound : 0;
      this.upperBound = (typeof opts.upperBound === 'number') ? opts.upperBound : 1;
      this.durationMs = __durationMs(opts.duration);
      if (this.durationMs == null) { this.durationMs = 300; }
    },
    onHost: function (self, p) {
      if (p != null && typeof p === 'number') {
        self._value = p;
        self.__notify();
      }
    },
    extraJSON: function (self) {
      return { value: self._value, durationMs: self.durationMs };
    }
  });
  Object.defineProperty(AnimationController.prototype, 'value', {
    get: function () { return this._value; },
    set: function (v) {
      var n = (typeof v === 'number') ? v : 0;
      if (this._value === n) { return; }
      this._value = n;
      if (this.__id != null) {
        handleOp(this.__id, 'set', { name: 'value', value: n });
      }
      this.__notify();
    }
  });
  AnimationController.prototype.__play = function (method, opts) {
    if (this.__id == null) { return; }
    // 生成器把命名实参摊平为位置实参（`repeat(reverse: true)` → `repeat(true)`），
    // 故 opts 可能是布尔（reverse）/ 数字（duration 毫秒）/ 对象三种形态，这里统一归一。
    var o = opts;
    if (o === true || o === false) { o = { reverse: o }; }
    else if (typeof o === 'number') { o = { duration: o }; }
    else { o = o || {}; }
    var ms = (o.duration != null) ? __durationMs(o.duration) : this.durationMs;
    handleOp(this.__id, 'call', {
      // id 一并下发：宿主基座的 onOp 不带 id，而「挂逐帧回传」需要它。
      id: this.__id,
      method: method,
      durationMs: ms,
      reverse: !!o.reverse,
      value: this._value
    });
  };
  AnimationController.prototype.forward = function (opts) {
    this.__play('forward', opts);
  };
  AnimationController.prototype.reverse = function (opts) {
    this.__play('reverse', opts);
  };
  AnimationController.prototype.repeat = function (opts) {
    this.__play('repeat', opts);
  };
  AnimationController.prototype.stop = function () {
    this.__play('stop', null);
  };
  AnimationController.prototype.reset = function () {
    this.__play('reset', null);
  };
  G.AnimationController = AnimationController;


// ===== 【17】ScrollController =====
  // 生成器把 Dart 侧 `final ScrollController _scrollController = ScrollController();`
  // 翻译成 `this._scrollController = new ScrollController()`；实例与宿主侧真实
  // ScrollController 按**句柄 id** 绑定。
  // 三件套基座（__listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由通用
  // 工厂 defineController 提供（见【4】）；本类只写差异：
  //   - offset / position / hasClients：本地镜像（宿主回传 metrics 更新）；
  //   - jumpTo/animateTo：实例级 host 通道（载荷带 id，多实例互不干扰）；
  //   - addListener/removeListener：JS 闭包直接登记——**匿名闭包天然支持**，
  //     无需生成器合成方法名，不存在重名问题。
  // 跨桥序列化：props 里的实例经 toJSON 输出 `{__handle: id}`，宿主据此取/建
  // 真实 controller（见 scroll_controller_bridge.dart）。
  // 动画实参归一：Dart 的具名实参在 JS 调用里是**位置化扁平**（JS 无具名参数），
  // 因此 `animateTo(offset, duration: d, curve: c)` 到运行时就是
  // `(offset, d, c)`；也兼容直接传 options 对象的形态。三种 duration 形态
  // （Duration 实例 / options.duration 毫秒数 / options.duration 为 Duration）
  // 与两种 curve 形态（字符串 / options.curve）统一归一。
  function __animArgs(opts, curveArg) {
    var ms = 300;
    var curve = 'easeOut';
    if (opts != null) {
      if (typeof opts.inMilliseconds === 'number') {
        ms = opts.inMilliseconds;
      } else if (typeof opts.duration === 'number') {
        ms = opts.duration;
      } else if (opts.duration && typeof opts.duration.inMilliseconds === 'number') {
        ms = opts.duration.inMilliseconds;
      }
      if (typeof opts.curve === 'string') { curve = opts.curve; }
    }
    if (typeof curveArg === 'string') { curve = curveArg; }
    return { ms: ms, curve: curve };
  }
  var ScrollController = defineController('ctrl/Scroll', {
    init: function () {
      this.offset = 0;
      this.__maxScrollExtent = 0;
      this.__viewportDimension = 0;
      this.__extentAfter = 0;
    },
    // 宿主回传 metrics 快照 → 更新镜像并触发 listeners（listener 无参，
    // 与 Dart addListener 语义一致；闭包内读 this._scrollController.offset）。
    onHost: function (self, p) {
      if (!p) { return; }
      self.offset = p.pixels;
      self.__maxScrollExtent = p.maxScrollExtent;
      self.__viewportDimension = p.viewportDimension;
      self.__extentAfter = p.extentAfter;
      self.__notify();
    },
  });
  ScrollController.prototype.jumpTo = function (offset) {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'jumpTo', args: [offset] }); }
  };
  ScrollController.prototype.animateTo = function (offset, opts, curveArg) {
    if (this.__id == null) { return; }
    var a = __animArgs(opts, curveArg);
    handleOp(this.__id, 'call', { method: 'animateTo', args: [offset, a.ms, a.curve] });
  };
  Object.defineProperty(ScrollController.prototype, 'position', {
    get: function () {
      return {
        pixels: this.offset,
        maxScrollExtent: this.__maxScrollExtent,
        viewportDimension: this.__viewportDimension,
        extentAfter: this.__extentAfter
      };
    }
  });
  Object.defineProperty(ScrollController.prototype, 'hasClients', {
    get: function () { return this.__id != null; }
  });
  G.ScrollController = ScrollController;

  // ===== PageController 代理类（对应 Flutter 官方 PageController）=====
  // 与 ScrollController 同一套句柄层；镜像字段只有 page / initialPage。
  // 构造参数（initialPage / viewportFraction）随 toJSON 的 extraJSON 下发，
  // 宿主 PageView renderer 据此创建真实 PageController。
  var PageController = defineController('ctrl/Page', {
    init: function (opts) {
      var o = opts || {};
      this.initialPage = (o.initialPage != null) ? o.initialPage : 0;
      this.page = this.initialPage;
      this.viewportFraction = (o.viewportFraction != null) ? o.viewportFraction : 1.0;
    },
    onHost: function (self, p) {
      if (p && p.page != null) { self.page = p.page; }
      self.__notify();
    },
    extraJSON: function (self) {
      return {
        initialPage: self.initialPage,
        viewportFraction: self.viewportFraction
      };
    }
  });
  PageController.prototype.jumpToPage = function (page) {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'jumpToPage', args: [page] }); }
  };
  PageController.prototype.animateToPage = function (page, opts, curveArg) {
    if (this.__id == null) { return; }
    var a = __animArgs(opts, curveArg);
    handleOp(this.__id, 'call', { method: 'animateToPage', args: [page, a.ms, a.curve] });
  };
  PageController.prototype.nextPage = function (opts, curveArg) {
    if (this.__id == null) { return; }
    var a = __animArgs(opts, curveArg);
    handleOp(this.__id, 'call', { method: 'nextPage', args: [a.ms, a.curve] });
  };
  PageController.prototype.previousPage = function (opts, curveArg) {
    if (this.__id == null) { return; }
    var a = __animArgs(opts, curveArg);
    handleOp(this.__id, 'call', { method: 'previousPage', args: [a.ms, a.curve] });
  };
  Object.defineProperty(PageController.prototype, 'hasClients', {
    get: function () { return this.__id != null; }
  });
  G.PageController = PageController;


// ===== 【18】TextEditingController =====
  // TextEditingController：JS 侧代理类，与宿主真实 TextEditingController 按
  // **句柄 id** 绑定（通用层，同 ScrollController 模式）。
  // 三件套基座（__listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由通用
  // 工厂 defineController 提供（见【4】）；本类只写差异：
  //   - text：本地镜像（宿主经 textFn 回传更新），setter 发 host set 同步宿主；
  //   - selection：本地镜像，setter 发 host setSelection；
  //   - clear()：发 host clear + 清镜像；
  //   - TextField(controller: 句柄) 渲染时宿主按 id 取真实实例，用户输入经
  //     textFn 回传 JS 镜像并触发 listeners。
  // 跨桥序列化：props 里的实例经 toJSON 输出 `{__handle: id}`。
  var TextEditingController = defineController('ctrl/Text', {
    init: function (initial) {
      this.__text =
        (initial && typeof initial.text === 'string') ? initial.text : '';
      this.__selection = null;
    },
    // 宿主回传（TextField 输入后同步镜像 + 触发 listeners）。
    onHost: function (self, t) {
      self.__text = (t == null) ? '' : String(t);
      self.__notify();
    },
  });
  TextEditingController.prototype.clear = function () {
    this.__text = '';
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'clear' }); }
    this.__notify();
  };
  Object.defineProperty(TextEditingController.prototype, 'text', {
    get: function () { return this.__text; },
    set: function (v) {
      this.__text = (v == null) ? '' : String(v);
      if (this.__id != null) {
        handleOp(this.__id, 'set', { name: 'text', value: this.__text });
      }
      this.__notify();
    }
  });
  Object.defineProperty(TextEditingController.prototype, 'selection', {
    get: function () { return this.__selection; },
    set: function (s) {
      this.__selection = s;
      if (this.__id != null) {
        var b = (s && typeof s.baseOffset === 'number') ? s.baseOffset : 0;
        var e = (s && typeof s.extentOffset === 'number') ? s.extentOffset : b;
        handleOp(this.__id, 'call', { method: 'setSelection', args: [b, e] });
      }
    }
  });
  G.TextEditingController = TextEditingController;


// ===== 【18.5】FocusNode =====
  var FocusNode = defineController('ctrl/Focus', {
    init: function (opts) {
      var o = opts || {};
      this.__hasFocus = false;
      this.__debugLabel = (o.debugLabel != null) ? String(o.debugLabel) : null;
      this.__skipTraversal = o.skipTraversal === true;
      this.__canRequestFocus = o.canRequestFocus !== false;
      this.__descendantsAreFocusable = o.descendantsAreFocusable !== false;
    },
    onHost: function (self, v) {
      self.__hasFocus = v === true;
      self.__notify();
    },
    meta: function (self) {
      return {
        debugLabel: self.__debugLabel,
        skipTraversal: self.__skipTraversal,
        canRequestFocus: self.__canRequestFocus,
        descendantsAreFocusable: self.__descendantsAreFocusable
      };
    }
  });
  FocusNode.prototype.requestFocus = function () {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'requestFocus' }); }
  };
  FocusNode.prototype.unfocus = function () {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'unfocus' }); }
  };
  Object.defineProperty(FocusNode.prototype, 'hasFocus', {
    get: function () { return this.__hasFocus === true; }
  });
  G.FocusNode = FocusNode;


// ===== 【18.6】键盘事件（KeyEvent / LogicalKeyboardKey） =====
  // LogicalKeyboardKey：keyId → 实例（身份去重，常量与事件共用同一张表）。
  var __keyInstances = {};
  function __logicalKey(keyId, label) {
    var k = __keyInstances[keyId];
    if (!k) {
      k = { keyId: keyId, keyLabel: label || '', debugName: label || '' };
      __keyInstances[keyId] = k;
    }
    return k;
  }

  // 常量表：名字 → [keyId, keyLabel]。宿主回传的事件按 keyId 归一，所以这里
  // 只登记「JS 源码里可能出现的名字」，两端读到的仍是同一实例。
  var __KEY_CONSTS = {
    space: [0x00000000020, 'Space'],
    enter: [0x0010000000D, 'Enter'],
    escape: [0x0010000001B, 'Escape'],
    tab: [0x00100000009, 'Tab'],
    backspace: [0x00100000008, 'Backspace'],
    delete: [0x0010000007F, 'Delete'],
    capsLock: [0x00100000104, 'Caps Lock'],
    arrowUp: [0x00100000304, 'Arrow Up'],
    arrowDown: [0x00100000301, 'Arrow Down'],
    arrowLeft: [0x00100000302, 'Arrow Left'],
    arrowRight: [0x00100000303, 'Arrow Right'],
    home: [0x00100000306, 'Home'],
    end: [0x00100000305, 'End'],
    pageUp: [0x00100000308, 'Page Up'],
    pageDown: [0x00100000307, 'Page Down'],
    controlLeft: [0x00200000100, 'Control Left'],
    controlRight: [0x00200000101, 'Control Right'],
    shiftLeft: [0x00200000102, 'Shift Left'],
    shiftRight: [0x00200000103, 'Shift Right'],
    altLeft: [0x00200000104, 'Alt Left'],
    altRight: [0x00200000105, 'Alt Right'],
    metaLeft: [0x00200000106, 'Meta Left'],
    metaRight: [0x00200000107, 'Meta Right']
  };
  // 数字与字母键：logical keyId 就是字符码（digit0 = 0x30，keyA = 0x61），
  // keyLabel 与 Flutter 一致（大写字母 / 数字本身）。
  for (var __d = 0; __d < 10; __d++) {
    __KEY_CONSTS['digit' + __d] = [0x30 + __d, String(__d)];
  }
  for (var __c = 0; __c < 26; __c++) {
    var __letter = String.fromCharCode(0x61 + __c).toUpperCase();
    __KEY_CONSTS['key' + __letter] = [0x61 + __c, __letter];
  }
  var LogicalKeyboardKey = {};
  for (var __name in __KEY_CONSTS) {
    __defineProtoGetter(LogicalKeyboardKey, __name, (function (name) {
      return function () { return __logicalKey(__KEY_CONSTS[name][0], __KEY_CONSTS[name][1]); };
    })(__name));
  }
  G.LogicalKeyboardKey = LogicalKeyboardKey;

  // PhysicalKeyboardKey：`event.physicalKey.usbHidUsage` 按 usb 码归一。
  var __physKeys = {};
  function PhysicalKeyboardKey(props) {
    props = props || {};
    this.usbHidUsage = props.usbHidUsage;
    this.debugName = props.debugName || '';
  }
  G.PhysicalKeyboardKey = PhysicalKeyboardKey;
  function __physicalKey(usb, label) {
    var k = __physKeys[usb];
    if (!k) {
      k = new PhysicalKeyboardKey({ usbHidUsage: usb, debugName: label });
      __physKeys[usb] = k;
    }
    return k;
  }

  // KeyEvent：Dart 的 KeyEvent 是抽象基类，按下 / 抬起 / 重复是三个子类，
  // 源码用 `event is KeyDownEvent` 区分——这里生成真子类以保持同一语义。
  function KeyEvent(props) {
    props = props || {};
    this.physicalKey = props.physicalKey;
    this.logicalKey = props.logicalKey;
    this.character = props.character == null ? null : String(props.character);
    this.timeStamp = props.timeStamp;
  }
  G.KeyEvent = KeyEvent;

  var __KEY_EVENT_SUBCLASSES = {
    down: function KeyDownEvent(props) { KeyEvent.call(this, props); },
    up: function KeyUpEvent(props) { KeyEvent.call(this, props); },
    repeat: function KeyRepeatEvent(props) { KeyEvent.call(this, props); }
  };
  for (var __kind in __KEY_EVENT_SUBCLASSES) {
    var __ctor = __KEY_EVENT_SUBCLASSES[__kind];
    __ctor.prototype = Object.create(KeyEvent.prototype);
    __ctor.prototype.constructor = __ctor;
  }
  G.KeyDownEvent = __KEY_EVENT_SUBCLASSES.down;
  G.KeyUpEvent = __KEY_EVENT_SUBCLASSES.up;
  G.KeyRepeatEvent = __KEY_EVENT_SUBCLASSES.repeat;

  // 宿主桥接见 capabilities/keyboard_listener/keyboard_listener_bridge.dart：
  // 原生 KeyEvent → JSON（kind / character / keyId / keyLabel / usbHidUsage /
  // timeStamp），这里还原成实例并调事件句柄。挂 G：宿主经 evaluate 裸引用调用。
  G.__jsuiKeyEvent = function (handleId, eventJson) {
    var h = handles[handleId];
    if (!h || typeof h.obj !== 'function') { return; }
    var m = {};
    try { m = JSON.parse(eventJson) || {}; } catch (e) { return; }
    var Ctor = __KEY_EVENT_SUBCLASSES[m.kind] || KeyEvent;
    h.obj(new Ctor({
      character: m.character,
      logicalKey: __logicalKey(m.logicalKeyId, m.logicalKeyLabel),
      physicalKey: __physicalKey(m.physicalKeyUsb, m.physicalKeyLabel),
      timeStamp: new Duration({ microseconds: m.timeStampUs || 0 })
    }));
  };


// ===== 【18.7】MediaQuery 镜像 =====
  // ctx 句柄 id -> {
  //   anchor, all, allKey, vals: {aspect: value}, keys: {aspect: key},
  //   pending: {aspect: true}, missing: {aspect: true}
  // }
  var __jsuiMqByCtx = {};
  // 最近一次解析到的整份真值：新 ctx 首帧尚未回填时先读它（同一运行时同一窗口，
  // 基本等价），避免「先显示 0x0 再校正」的闪一帧。
  var __jsuiMqLastAll = null;
  // 真值到达前的兜底常量（构造一次）：字段齐全，避免读崩。
  var __jsuiMqFallback = null;

  function __jsuiMqScale(factor) {
    return { __factor: factor, scale: function (x) { return this.__factor * x; } };
  }

  function __jsuiMqEmpty() {
    if (__jsuiMqFallback == null) {
      __jsuiMqFallback = __jsuiMqBuild({
        size: { width: 0, height: 0 },
        padding: { left: 0, top: 0, right: 0, bottom: 0 },
        viewPadding: { left: 0, top: 0, right: 0, bottom: 0 },
        viewInsets: { left: 0, top: 0, right: 0, bottom: 0 },
        devicePixelRatio: 1,
        textScaleFactor: 1,
        orientation: Orientation.portrait,
        platformBrightness: Brightness.light,
        alwaysUse24HourFormat: false,
        accessibleNavigation: false,
        disableAnimations: false,
        invertColors: false,
        highContrast: false,
        boldText: false,
        navigationMode: NavigationMode.traditional,
      });
    }
    return __jsuiMqFallback;
  }

  // 宿主下发的 JSON → JS 侧 MediaQueryData 同形对象（aspect = null 时整份）。
  function __jsuiMqBuild(json) {
    var s = json.size || { width: 0, height: 0 };
    var f = json.textScaleFactor != null ? json.textScaleFactor : 1;
    return {
      size: new Size({ width: s.width, height: s.height }),
      padding: json.padding,
      viewPadding: json.viewPadding,
      viewInsets: json.viewInsets,
      devicePixelRatio: json.devicePixelRatio,
      textScaleFactor: f,
      textScaler: __jsuiMqScale(f),
      orientation: json.orientation,
      platformBrightness: json.platformBrightness,
      alwaysUse24HourFormat: json.alwaysUse24HourFormat,
      accessibleNavigation: json.accessibleNavigation,
      disableAnimations: json.disableAnimations,
      invertColors: json.invertColors,
      highContrast: json.highContrast,
      boldText: json.boldText,
      navigationMode: json.navigationMode,
    };
  }

  // 单 aspect 的宿主原值 → 本端值（size 包成 Size、textScaler 包出 scale 方法，
  // 其余是标量 / 已同形的对象，原样用）。
  function __jsuiMqDecode(aspect, raw) {
    if (aspect == null) { return __jsuiMqBuild(raw); }
    if (aspect === 'size') {
      return new Size({ width: raw.width, height: raw.height });
    }
    if (aspect === 'textScaler') { return __jsuiMqScale(raw.__factor); }
    return raw;
  }

  function __jsuiMqEntry(id, context) {
    var e = __jsuiMqByCtx[id];
    if (!e) {
      e = __jsuiMqByCtx[id] = {
        anchor: context ? context.__anchor : null,
        all: null, allKey: '',
        vals: {}, keys: {}, pending: {}, missing: {},
      };
    }
    return e;
  }

  // 唯一写口：宿主回填 / 变化回推。
  //   aspect = null → 整份数据；否则只更新该 aspect。
  //   **与缓存不同才标脏**（一次真值变化只重建一次）。
  function __jsuiSetMediaQuery(ctxId, aspect, raw) {
    var id = String(ctxId);
    var e = __jsuiMqEntry(id, null);
    if (raw == null) {
      // 该位置上方没有 MediaQuery：标记后不再重试，避免每次 build 都发桥消息。
      e.missing[aspect] = true;
      return;
    }
    var key = JSON.stringify(raw);
    if (aspect == null) {
      if (e.allKey === key) { return; }
      e.allKey = key;
      e.all = __jsuiMqBuild(raw);
      __jsuiMqLastAll = e.all;
    } else {
      if (e.keys[aspect] === key) { return; }
      e.keys[aspect] = key;
      e.vals[aspect] = __jsuiMqDecode(aspect, raw);
    }
    var a = e.anchor;
    if (a && a.__unmounted) {
      // 组件已卸载（句柄即将/已被释放）：丢掉这条缓存，不再标脏。
      delete __jsuiMqByCtx[id];
      return;
    }
    if (a) { markDirty(a); }
  }

  // 按 aspect 向宿主取一次值（每个 aspect 只取一次，之后靠回推）。
  function __jsuiMqFetch(e, id, aspect) {
    var slot = aspect == null ? 'all' : aspect;
    if (e.pending[slot] || e.missing[slot]) { return; }
    e.pending[slot] = true;
    try {
      var p = handleOp(id, 'mediaQuery',
        aspect == null ? null : { 'aspect': aspect });
      if (p && typeof p.then === 'function') {
        p.then(function (raw) {
          e.pending[slot] = false;
          __jsuiSetMediaQuery(id, aspect, raw);
        }, function () { e.pending[slot] = false; });
      } else {
        e.pending[slot] = false;
      }
    } catch (err) {
      e.pending[slot] = false;
    }
  }

  // `MediaQuery.of(context)`：整份数据（依赖全部 aspect）。
  function __jsuiMqOf(context) {
    var id = null;
    try { id = context.__handle(); } catch (err) { id = null; }
    if (id == null) { return __jsuiMqLastAll || __jsuiMqEmpty(); }
    var e = __jsuiMqEntry(id, context);
    if (e.all == null) { __jsuiMqFetch(e, id, null); }
    return e.all || __jsuiMqLastAll || __jsuiMqEmpty();
  }

  // `MediaQuery.<x>Of(context)`：只依赖该 aspect。
  function __jsuiMqAspect(context, aspect) {
    var id = null;
    try { id = context.__handle(); } catch (err) { id = null; }
    if (id == null) { return (__jsuiMqLastAll || __jsuiMqEmpty())[aspect]; }
    var e = __jsuiMqEntry(id, context);
    var v = e.vals[aspect];
    if (v === undefined) { __jsuiMqFetch(e, id, aspect); }
    if (v !== undefined) { return v; }
    // 该 aspect 还没回来：从整份数据 / 最近值 / 兜底里取同名字段投影。
    var src = e.all || __jsuiMqLastAll || __jsuiMqEmpty();
    return src[aspect];
  }

  // Dart 的静态取值方法：每个都按自己的 aspect 代理（取值 + 重建粒度都对齐）。
  var MediaQuery = {
    of: function (context) { return __jsuiMqOf(context); },
    // `maybeOf` 语义：没有 MediaQuery 祖先时返回 null；这里退化为兜底对象
    // （字段齐全，读不崩），与 `of` 同源。
    maybeOf: function (context) { return __jsuiMqOf(context); },
    sizeOf: function (context) { return __jsuiMqAspect(context, 'size'); },
    paddingOf: function (context) { return __jsuiMqAspect(context, 'padding'); },
    viewPaddingOf: function (context) {
      return __jsuiMqAspect(context, 'viewPadding');
    },
    viewInsetsOf: function (context) {
      return __jsuiMqAspect(context, 'viewInsets');
    },
    devicePixelRatioOf: function (context) {
      return __jsuiMqAspect(context, 'devicePixelRatio');
    },
    textScalerOf: function (context) {
      return __jsuiMqAspect(context, 'textScaler');
    },
    orientationOf: function (context) {
      return __jsuiMqAspect(context, 'orientation');
    },
    platformBrightnessOf: function (context) {
      return __jsuiMqAspect(context, 'platformBrightness');
    },
    navigationModeOf: function (context) {
      return __jsuiMqAspect(context, 'navigationMode');
    },
    alwaysUse24HourFormatOf: function (context) {
      return __jsuiMqAspect(context, 'alwaysUse24HourFormat');
    },
    accessibleNavigationOf: function (context) {
      return __jsuiMqAspect(context, 'accessibleNavigation');
    },
    boldTextOf: function (context) {
      return __jsuiMqAspect(context, 'boldText');
    },
    disableAnimationsOf: function (context) {
      return __jsuiMqAspect(context, 'disableAnimations');
    },
    highContrastOf: function (context) {
      return __jsuiMqAspect(context, 'highContrast');
    },
    invertColorsOf: function (context) {
      return __jsuiMqAspect(context, 'invertColors');
    },
  };

  // Dart 枚举 / 常量镜像：产物里 `Orientation.portrait` 等是原样引用，
  // 值取同一套字符串（宿主 JSON 里也是这套字符串）。
  var Orientation = { portrait: 'portrait', landscape: 'landscape' };
  var Brightness = { dark: 'dark', light: 'light' };
  var NavigationMode = { traditional: 'traditional', directional: 'directional' };

  G.MediaQuery = MediaQuery;
  G.Orientation = Orientation;
  G.Brightness = Brightness;
  G.NavigationMode = NavigationMode;
  G.__jsuiSetMediaQuery = __jsuiSetMediaQuery;


// ===== 【18.8】父约束下发（LayoutBuilder） =====
  // 宿主下发的约束 JSON → BoxConstraints。
  // 挂 G：包模块（flutter.js）只能裸引用全局，IIFE 内的局部声明它看不见。
  G.__jsuiBoxConstraints = function (json) {
    json = json || {};
    return new BoxConstraints({
      minWidth: json.minWidth == null ? 0 : json.minWidth,
      maxWidth: json.maxWidth == null ? Infinity : json.maxWidth,
      minHeight: json.minHeight == null ? 0 : json.minHeight,
      maxHeight: json.maxHeight == null ? Infinity : json.maxHeight,
    });
  };


// ===== 【19】TabController =====
  // 生成器把 Dart 侧 `late final TabController _c = TabController(length: 3, vsync: this)`
  // 翻译成 `this._c = new TabController({length: 3, vsync: this})`（vsync 由本代理
  // 类忽略），实例与宿主侧真实 TabController 按**句柄 id** 绑定。
  // 三件套基座（__listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由通用
  // 工厂 defineController 提供（见【4】）；本类只写差异：
  //   - length/__index：本地镜像（宿主回传 index 更新）；真实实例由宿主在渲染
  //     TabBar / TabBarView 时按 id 取/建（length 随句柄下发，见 extraJSON）；
  //   - index setter：立即设置宿主 index 并通知监听者；
  //   - animateTo(i)：宿主 controller.animateTo（带动画）。
  var TabController = defineController('ctrl/Tab', {
    init: function (opts) {
      opts = opts || {};
      this.length = (typeof opts.length === 'number') ? opts.length : 0;
      this.__index = (typeof opts.initialIndex === 'number') ? opts.initialIndex : 0;
    },
    // 宿主回传（用户点 tab / animateTo 动画结束）→ 更新镜像 + 触发 listeners。
    // 值没变就不是状态变化，不能通知：宿主 attach 时会回传一次初始 index，
    // 若照常 notify，会让监听者（如外壳的 setState）做一次“原地刷新”，
    // 把已挂载子组件无谓地推进 didUpdateWidget → build。
    onHost: function (self, i) {
      if (typeof i !== 'number' || self.__index === i) { return; }
      self.__index = i;
      self.__notify();
    },
    // 跨桥序列化：`{__handle: id, length, initialIndex}`——宿主据此取/建真实
    // controller（见 capabilities/tab/tab_bridge.dart）。
    extraJSON: function (self) {
      return { length: self.length, initialIndex: self.__index };
    },
  });
  TabController.prototype.animateTo = function (index) {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'animateTo', args: [index] }); }
  };
  Object.defineProperty(TabController.prototype, 'index', {
    get: function () { return this.__index; },
    set: function (v) {
      v = (typeof v === 'number') ? v : 0;
      // 同值：镜像没变化 → 不再下发宿主 op、也不再通知（避免一次假刷新）。
      if (this.__index === v) { return; }
      this.__index = v;
      if (this.__id != null) { handleOp(this.__id, 'set', { name: 'index', value: v }); }
      // 与 Dart 语义一致：直接设置 index 立即通知监听者（宿主回传同一值时
      // 会被 onHost 的同值判等吞掉，不会重复通知）。
      this.__notify();
    }
  });
  G.TabController = TabController;

  // TabBarView 是**懒容器**（子页被 SliverFillViewport 强制成整屏，零尺寸占位
  // 布局中性）——不在运行时声明：由生成器配置 lazyChildHostTypes 在 __h 里给
  // 元素打 `lazyChildren` 标记（见 hot_patch_generator 的 shared/js_widget_defs.dart）。


// ===== 【20】Key 类族 =====
  // ObjectKey / ValueKey(对象值) 的身份 token：对象走 WeakMap（不阻止回收），
  // 原始值没有身份，退化为值 string。
  var okeySeq = 0;
  var okeyIdx = new WeakMap();
  function objectToken(v) {
    if (v === null || (typeof v !== 'object' && typeof v !== 'function')) {
      return 'p:' + String(v);
    }
    var t = okeyIdx.get(v);
    if (t == null) { okeySeq += 1; t = 'i:' + okeySeq; okeyIdx.set(v, t); }
    return t;
  }

  // ValueKey：按值相等，纯值 codec（不登记句柄）。
  // 实例的**自有字段名 = 序列化字段名**（__vkey）：reconciler 的 keySig 用字段
  // 形态判据，而 props.key 传的是 live 实例（不是 toJSON 产物），两边必须同形。
  // 对象值跨语言保不住同一性，序列化退化为身份 token（与 keyValueSig 同源）。
  function ValueKey(props) { this.__vkey = __posArgs(props, ['value']).value; }
  ValueKey.prototype.toJSON = function () {
    var v = this.__vkey;
    if (v !== null && (typeof v === 'object' || typeof v === 'function')) {
      return { __vtok: objectToken(v) };
    }
    return { __vkey: v };
  };

  // ObjectKey：按被包裹对象的身份相等（只留身份 token，不再持有对象引用）。
  function ObjectKey(props) { this.__okey = objectToken(__posArgs(props, ['value']).value); }
  ObjectKey.prototype.toJSON = function () { return { __okey: this.__okey }; };

  // PageStorageKey：Dart 侧 `extends ValueKey`（按**值**相等），但宿主必须造
  // **真实** PageStorageKey——它的意义是滚动位置按 key 存进 PageStorage bucket，
  // 那是宿主端行为（JS 侧只有一个值本体）。故 codec 与 ValueKey 同构另加 `__psk`
  // 标记：宿主据此造 PageStorageKey 而非 ValueKey，keySig 前缀 `p:` 使它与
  // 同值的 ValueKey 不等（与 Dart 的 runtimeType 参与相等一致）。
  function PageStorageKey(props) {
    var value = __posArgs(props, ['value']).value;
    this.__psk = (value !== null && (typeof value === 'object' || typeof value === 'function'))
        ? { __vtok: objectToken(value) }
        : value;
  }
  PageStorageKey.prototype.toJSON = function () { return { __psk: this.__psk }; };

  // GlobalKey / UniqueKey：登记为句柄（scope=page，随页面回收），宿主持真实实例。
  defineHandleKind('key/Global', {});
  function GlobalKey(props) {
    var debugLabel = __posArgs(props, ['debugLabel']).debugLabel;
    // 泛型实参由产物下发（`new GlobalKey({typeArguments: ['AnimatedListState']})`）：
    // Dart 的 `GlobalKey<T>` 在 AOT 是 reified 的，T 就是「currentState 的类型」，
    // 取值不需要问宿主、也不靠 runtimeType 猜。
    var ta = (props && props.typeArguments) || [];
    this.__stateType = ta.length ? ta[0] : null;
    this.__id = reg(this, 'key/Global', {
      meta: debugLabel == null ? null : { debugLabel: debugLabel }
    });
  }
  GlobalKey.prototype.toJSON = function () { return { __handle: this.__id }; };

  // GlobalKey.currentContext / findRenderObject()：BuildContext 与 RenderObject 是
  // **宿主端**概念——JS 侧既没有真实对象，也没有同步取值的能力（JS→宿主只有异步
  // 桥，见 handleOp）。故 currentContext 返回一个只携带 key 句柄 id 的代理，链式
  // 调用在 JS 侧是空壳，最后一次调用经通用 op 落到宿主，由宿主用**真实**对象把
  // Flutter 原生语义补全——位置/尺寸只在真正算得出来的一端计算。
  //   - showOnScreen()：void 语义，fire-and-forget，宿主算出该结点位置并滚动；
  //   - measure()：Flutter 的 `box.size` / `box.localToGlobal(Offset.zero)` 是
  //     **同步属性**，而 JS→宿主只能异步，故这里返回 Promise（单源侧 `await`
  //     后即为真实值，见 widget_details 的 _measureFixed）。
  function KeyRef(id) { this.__key = id; }
  KeyRef.prototype.findRenderObject = function () { return new KeyRef(this.__key); };
  KeyRef.prototype.showOnScreen = function () {
    if (this.__key != null) { handleOp(this.__key, 'showOnScreen', {}); }
  };
  KeyRef.prototype.measure = function () {
    if (this.__key == null) { return Promise.resolve(null); }
    return handleOp(this.__key, 'measure', {});
  };
  Object.defineProperty(GlobalKey.prototype, 'currentContext', {
    get: function () { return this.__id == null ? null : new KeyRef(this.__id); }
  });

  // GlobalKey.currentState：State 是宿主对象，JS 侧只保留**句柄**。
  //
  // 运行时**不认识任何业务方法**（`insertItem` / `removeItem` 这类签名属于具体
  // 组件）：每个 State 类型的代理类由生成器随该组件一起写进 flutter.js，并在
  // 加载时用 `__registerStateProxy(type, class)` 登记；类型来自 **GlobalKey<T> 的
  // 泛型实参**，随产物下发，不靠 runtimeType 猜。没有代理类时退化为通用句柄。
  function StateHandle(id, type) { this.__key = id; this.__type = type || null; }
  StateHandle.prototype.__op = function (op, payload) {
    if (this.__key == null) { return null; }
    var p = payload || {};
    // 类型随每次调用下发（来自 GenericKey 的泛型实参）：宿主据此分派到
    // `Type.method`，不同组件的同名方法互不覆盖。
    if (this.__type) { p.type = this.__type; }
    return handleOp(this.__key, '__state.' + op, p);
  };
  var __stateProxies = {};
  function __registerStateProxy(type, cls) { __stateProxies[type] = cls; }
  Object.defineProperty(GlobalKey.prototype, 'currentState', {
    get: function () {
      if (this.__id == null) { return null; }
      // 首选泛型实参（`GlobalKey<AnimatedListState>` 的 T）；未声明泛型时才问
      // 宿主 runtimeType。两者都没有则退化为通用句柄（调用时宿主会告警）。
      var type = this.__stateType || handleOp(this.__id, '__type', {});
      var cls = type ? __stateProxies[type] : null;
      return cls ? new cls(this.__id, type) : new StateHandle(this.__id, type);
    }
  });
  G.__registerStateProxy = __registerStateProxy;
  G.__StateHandle = StateHandle;

  defineHandleKind('key/Unique', {});
  function UniqueKey() {
    this.__id = reg(this, 'key/Unique', {});
  }
  UniqueKey.prototype.toJSON = function () { return { __handle: this.__id }; };

  // 值 → 签名片段（原始值按「类型 + 值」，对象按身份）。
  function keyValueSig(v) {
    if (v === null || (typeof v !== 'object' && typeof v !== 'function')) {
      return typeof v + ':' + String(v);
    }
    return 'i:' + objectToken(v);
  }

  // key → 可比较签名；null / undefined（无 key）返回 null。
  // 形态判据用**自有字段**（`__vkey` / `__okey`）：ValueKey 的值本身可以是
  // null/undefined，故只能判「有没有这个字段」，不能判它的值。
  function keySig(k) {
    if (k == null) { return null; }
    if (Object.prototype.hasOwnProperty.call(k, '__vkey')) { return 'v:' + keyValueSig(k.__vkey); }
    // PageStorageKey：同值也与 ValueKey 不等（`p:` 前缀），对象值同 ValueKey 走 token。
    if (Object.prototype.hasOwnProperty.call(k, '__psk')) {
      var pv = k.__psk;
      if (pv !== null && typeof pv === 'object' &&
          Object.prototype.hasOwnProperty.call(pv, '__vtok')) {
        return 'p:' + pv.__vtok;
      }
      return 'p:' + keyValueSig(pv);
    }
    if (Object.prototype.hasOwnProperty.call(k, '__okey')) { return 'o:' + k.__okey; }
    var hid = k.__id != null ? k.__id : k.__handle;
    if (hid != null) { return 'h:' + hid; }
    // 兜底：认不出的 key 对象按**引用身份**区分。绝不能 `String(k)` ——
    // 所有对象都会拼成 "[object Object]" 而互相撞车，导致不同 key 复用同一
    // 结点（`x:` 前缀保留，表明这是兜底签名）。
    return 'x:' + objectToken(k);
  }

  G.ValueKey = ValueKey;
  G.ObjectKey = ObjectKey;
  G.PageStorageKey = PageStorageKey;
  G.UniqueKey = UniqueKey;
  G.GlobalKey = GlobalKey;


// ===== 【21】BuildContext 代理 =====
  defineHandleKind('ctx/BuildContext', {});

  function JsBuildContext(anchor, nodeId) {
    // 消费它的 JS 组件实例（watch/read 的构建位置锚点）。
    this.__anchor = anchor;
    // 最近宿主祖先结点 id（宿主侧 nodeId -> 真值 BuildContext 的键）。
    this.__nodeId = nodeId;
    // 跨语言句柄：**惰性**登记（没用过 context 的组件零句柄开销）。
    this.__id = null;
  }

  // 句柄（首次真正需要宿主真值时才登记，宿主 onCreate 绑定 nodeId）。
  JsBuildContext.prototype.__handle = function () {
    if (this.__id == null) {
      this.__id = reg(this, 'ctx/BuildContext', {
        meta: this.__nodeId == null ? null : { node: this.__nodeId }
      });
    }
    return this.__id;
  };

  // 向宿主真值 BuildContext 发同名 op（其余 context API 走这条路）。
  // JS→宿主只有异步桥，故 fire-and-forget：不阻塞本端同步渲染，失败静默丢弃
  // （页面卸载竞态下句柄可能已释放）。
  JsBuildContext.prototype.__host = function (op, payload) {
    try {
      var p = handleOp(this.__handle(), op, payload);
      if (p && typeof p.catch === 'function') { p.catch(function () {}); }
    } catch (e) {}
  };

  // `context.watch<T>()` / `read<T>()` **不在这里**：它们不是框架 API，而是
  // provider 那类 `extension BuildContextX on BuildContext`——方法补丁在
  // capabilities/provider/provider_js.dart，宿主侧处理见 provider/context_ops.dart。
  // 本片段只提供机制：代理、句柄、`contextOf`/`buildContextOf`、通用 op 转发。

  // 组件实例 → 代理（每个实例一个，缓存进 `__ctx`）。**同一执行位置**下，
  // build 形参与 `this.context` 是同一个对象：前者由 buildOf 传入 `contextOf(inst)`，
  // 后者由 getter 传 `building`，而 `buildOf` 期间 `building === inst`。
  function contextOf(inst) {
    if (inst.__ctx == null) { inst.__ctx = buildContextOf(inst); }
    return inst.__ctx;
  }

  // 建立代理：结点锚点 = 最近宿主祖先结点 id。上溯不到说明是**根组件**
  // （COMP 之上再没有宿主结点）——退回页面锚点 `page:<pageKey>`（由
  // JsUiWidgetState 在 build 期间登记的上下文），保证根组件一样拿到真值。
  // 两条都取不到时 nodeId 为 null：代理仍可用（宿主侧反查不到），不抛错——
  // 构建顺序变化不应让组件构建失败。
  function buildContextOf(inst) {
    var node = inst;
    while (node && node.__k !== HOST) { node = node.__parent; }
    if (node) { return new JsBuildContext(inst, node.__id); }
    var root = activeRoot || inst.__root;
    return new JsBuildContext(inst, root ? 'page:' + root.key : null);
  }


// ===== 【22】EasyRefresh =====
  // 宿主侧桥接见 capabilities/easy_refresh/easy_refresh_bridge.dart 的
  // `_runAwaitableEvent`：evaluate 本函数触发一次事件，并等 token 回传。
  // 挂 G（globalThis）：宿主经 evaluate 裸引用调用，与 `__jsui` 同一约定。
  G.__jsuiAwaitRun = function (handleId, token) {
    var h = handles[handleId];
    var out = null;
    try {
      out = (h && typeof h.obj === 'function') ? h.obj() : null;
    } catch (e) {
      // 事件方法同步抛错：按「已完成」收尾——指示器必须收起，不能挂死在转圈。
              console.error(String(e));
      
    }
    // 完成回传走 host（唯一 JS→宿主出口）；onFulfilled / onRejected 都必须回传，
    // 否则宿主侧那条 pending 永远等不到结算。
    var done = function () { host('jsuiAwaitDone', [token]); };
    if (out && typeof out.then === 'function') {
      out.then(done, done);
    } else {
      done();
    }
  };

  // 与 ScrollController 同款句柄层（三件套见【4】defineController）：JS 实例与
  // 宿主真实 EasyRefreshController 按句柄 id 绑定。控制方法把**原始实参数组**
  // 原样下发（`handleOp 'call'`），由宿主按 Dart 形参的类型/顺序还原：
  // 生成器对方法调用的具名实参是位置化扁平（JS 无具名参数），所以这里不臆造
  // 形参名，交给宿主按类型判别（数值 → overOffset、Duration 值 → duration、
  // 曲线名 → curve、布尔 → force）。
  // 宿主侧桥接见 capabilities/easy_refresh/easy_refresh_bridge.dart。
  var EasyRefreshController = defineController('ctrl/EasyRefresh', {
    init: function (opts) {
      var o = opts || {};
      this.controlFinishRefresh = !!o.controlFinishRefresh;
      this.controlFinishLoad = !!o.controlFinishLoad;
    },
    // 构造参数随句柄 create 下发：宿主据此创建真实 controller（putIfAbsent——
    // 创建消息与首帧渲染谁先到都复用同一实例）。
    meta: function (self) {
      return {
        controlFinishRefresh: self.controlFinishRefresh,
        controlFinishLoad: self.controlFinishLoad
      };
    },
    // 组件渲染时 controller 经 toJSON 跨桥（`{__handle, controlFinish*}`），
    // Host 在渲染期兜底创建时同样读得到构造参数。
    extraJSON: function (self) {
      return {
        controlFinishRefresh: self.controlFinishRefresh,
        controlFinishLoad: self.controlFinishLoad
      };
    }
  });
  EasyRefreshController.prototype.__op = function (method, args) {
    if (this.__id == null) { return undefined; }
    return handleOp(this.__id, 'call', { method: method, args: args });
  };
  EasyRefreshController.prototype.callRefresh = function () {
    return this.__op('callRefresh', Array.prototype.slice.call(arguments));
  };
  EasyRefreshController.prototype.callLoad = function () {
    return this.__op('callLoad', Array.prototype.slice.call(arguments));
  };
  EasyRefreshController.prototype.openHeaderSecondary = function () {
    return this.__op('openHeaderSecondary', Array.prototype.slice.call(arguments));
  };
  EasyRefreshController.prototype.closeHeaderSecondary = function () {
    return this.__op('closeHeaderSecondary', Array.prototype.slice.call(arguments));
  };
  EasyRefreshController.prototype.openFooterSecondary = function () {
    return this.__op('openFooterSecondary', Array.prototype.slice.call(arguments));
  };
  EasyRefreshController.prototype.closeFooterSecondary = function () {
    return this.__op('closeFooterSecondary', Array.prototype.slice.call(arguments));
  };
  EasyRefreshController.prototype.resetHeader = function () {
    return this.__op('resetHeader', []);
  };
  EasyRefreshController.prototype.resetFooter = function () {
    return this.__op('resetFooter', []);
  };
  EasyRefreshController.prototype.finishRefresh = function () {
    return this.__op('finishRefresh', Array.prototype.slice.call(arguments));
  };
  EasyRefreshController.prototype.finishLoad = function () {
    return this.__op('finishLoad', Array.prototype.slice.call(arguments));
  };
  G.EasyRefreshController = EasyRefreshController;


// ===== 【23】provider =====
  // model   = 类型名（生成器在翻译期写入，源自 `ChangeNotifierProvider<T>` 的 T）；
  // notifier = JS 侧 provider 组件 build 时创建/复用的实例（活对象）。
  registerScope('ChangeNotifierProvider', function (props) {
    if (!props || props.model == null) { return null; }
    var out = {};
    out[props.model] = props.notifier;
    return out;
  });

  // ---- extension BuildContextX on BuildContext ----
  // 对齐 Dart：`context.watch<T>()` / `context.read<T>()` 是 **provider 的**
  // extension，不是 BuildContext 的框架 API。故方法补丁归本库，核心的
  // build_context 片段只提供代理与通用 op 转发（见其文件头）。
  //
  // 取值同步（渲染期 `model.count` 要直接读，而 JS→宿主只有异步桥）⇒ 值在本端
  // 按**类型名**沿 `__parent` 取最近作用域（核心通用机制 `scopeOf`，只认类型名，
  // 不关心 T 是模型还是别的）；值是否可订阅由 `subscribeListenable` 鸭子判型。
  // 「订阅谁」这半是库相关的，交宿主：op 经 `__host` 下发到真实 BuildContext，
  // 由 provider/context_ops.dart 解析成模型镜像并建立依赖。

  // `context.watch<T>()`：取最近提供 [type] 的值并订阅（notify 时只重建调用
  // watch 的那个位置）。
  JsBuildContext.prototype.watch = function (type) {
    var value = scopeOf(this.__anchor, type);
    // 把本端查找结果一并告知宿主：宿主据此区分「消费点在 provider 子树之外」
    // （真错误，宿主会告警）与「宿主侧本就没有该作用域的镜像」（正常，静默）。
    this.__host('watch', { type: type, found: value != null });
    if (value == null) { return undefined; }
    subscribeListenable(this.__anchor, value);
    return value;
  };

  // `context.read<T>()`：仅取实例，不订阅（按钮回调里的合法用法）。
  JsBuildContext.prototype.read = function (type) {
    var value = scopeOf(this.__anchor, type);
    this.__host('read', { type: type, found: value != null });
    return value == null ? undefined : value;
  };


// ===== 【24】Timer（Dart Timer 同名注入） =====
  // 实参归一：正常形态是 `{duration, callback}`；构建期查不到签名时位置实参
  // 落在 `__pos` 里，由 __posArgs 按形参名展开。容错地再支持一次
  // 「第一个实参直接就是 Duration 对象」的形态，避免任何调用写法静默失效。
  function __timerArgs(props, second) {
    var duration = null;
    var callback = null;
    if (props && typeof props.inMilliseconds === 'number') {
      duration = props;
      callback = second;
    } else {
      var opts = __posArgs(props, ['duration', 'callback']);
      duration = opts.duration;
      callback = opts.callback;
    }
    var ms = __durationMs(duration);
    if (ms == null || ms < 0) { ms = 0; }
    return { ms: ms, callback: callback };
  }

  function Timer(props) {
    __timerInit(this, props, false, null);
  }

  // __timerInit 在所有 Timer 实例间共用（构造与 periodic 两条入口）。
  function __timerInit(self, props, repeat, second) {
    var args = __timerArgs(props, second);
    self._ms = args.ms;
    self._callback = args.callback;
    self._repeat = !!repeat;
    self._active = true;
    self._cancelled = false;
    self._handle = null;
    __timerSchedule(self);
  }

  function __timerSchedule(self) {
    if (self._cancelled) { return; }
    self._handle = setTimeout(function () {
      self._handle = null;
      if (self._cancelled) { return; }
      if (!self._repeat) { self._active = false; }
      try {
        if (typeof self._callback === 'function') { self._callback(self); }
      } catch (e) {
        console.error('[patch] Timer 回调异常: ' +
          ((e && e.message) ? e.message : e));
      }
      if (self._repeat && !self._cancelled) { __timerSchedule(self); }
    }, self._ms);
  }

  Timer.prototype.cancel = function () {
    this._cancelled = true;
    this._active = false;
    if (this._handle != null && typeof clearTimeout === 'function') {
      try { clearTimeout(this._handle); } catch (e) {}
    }
    this._handle = null;
  };

  Object.defineProperty(Timer.prototype, 'isActive', {
    get: function () { return !!this._active; }
  });

  // Timer 不是跨语言句柄：万一被当作值下发，只带状态字段（调试友好，宿主侧无对应还原）。
  Timer.prototype.toJSON = function () {
    return { __timer: true, active: !!this._active, repeat: !!this._repeat, ms: this._ms };
  };

  Timer.periodic = function (props, second) {
    var t = Object.create(Timer.prototype);
    __timerInit(t, props, true, second);
    return t;
  };

  G.Timer = Timer;


// ===== 【25】泄漏观测（debug 用） =====

  function leakSnapshot() {
    var hs = [];
    for (var id in handles) {
      var h = handles[id];
      hs.push({ id: id, kind: h.kind, scope: h.scope, key: h.key, obj: ctorNameOf(h) });
    }
    var ph = {};
    for (var pk in pageHandles) { ph[pk] = pageHandles[pk].length; }
    var rs = [];
    for (var rk in roots) { rs.push(rk); }
    return JSON.stringify({ handles: hs, pageHandles: ph, roots: rs });
  }

  // 宿主侧调试入口用的**缓存全景**（仅 debug）：`handles` 是 JS 端唯一的对象
  // 缓存（函数 / 控制器 / Key / ChangeNotifier / ctx 句柄都在这一张表里，kind 只是
  // 条目上的标签）——这里按 kind 汇总条目数 + 逐条列出 id/scope/key/构造名，外加
  // 页面句柄索引与页面根表，一眼看全 JS 端持有什么（见 JsLeakSnapshot.logJsCache）。
  function cacheDump() {
    var byKind = {};
    var lines = [];
    for (var id in handles) {
      var h = handles[id];
      byKind[h.kind] = (byKind[h.kind] || 0) + 1;
      lines.push(h.kind + ' ' + id + ' obj=' + ctorNameOf(h)
        + (h.key ? ' page=' + h.key : ' scope=' + h.scope));
    }
    var kinds = [];
    for (var k in byKind) { kinds.push(k + '×' + byKind[k]); }
    var ph = [];
    for (var pk in pageHandles) { ph.push(pk + '×' + pageHandles[pk].length); }
    var rs = [];
    for (var rk in roots) { rs.push(rk); }
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
    return h.id + '（' + ctorNameOf(h) + '）· kind=' + h.kind
      + ' · scope=' + h.scope + ' · 页面=' + page + ' · 持有者=' + owner;
  }

  // 安装切面（幂等）：把全局 reg / releaseHandle 换成「原实现 + 日志」。
  function __installCacheTrace() {
    if (__cacheTraceInstalled) { return; }
    __cacheTraceInstalled = true;
    var rawReg = reg;
    reg = function (obj, kind, opts) {
      // 同一对象重复登记返回同一 id（身份去重）——那种不算「新建」，不打印。
      var existed = (obj === null || obj === undefined)
        ? null : handleOwnerIdx.get(obj);
      var id = rawReg(obj, kind, opts);
      if (__cacheTraceOn && id && id !== existed && handles[id]) {
        console.log('[binding] + JS ' + __cacheTraceLine(handles[id]));
      }
      return id;
    };
    var rawRelease = releaseHandle;
    releaseHandle = function (id, notify) {
      var h = __cacheTraceOn ? handles[id] : null;
      rawRelease(id, notify);
      // 幂等释放（本地已删）不打印，避免与对端 release 重复刷屏。
      if (h) { console.log('[binding] - JS ' + __cacheTraceLine(h)); }
    };
  }

  // 宿主入口：打开 / 关闭详细追踪。关闭即包装内日志分支短路（只多一次布尔
  // 判断），不会再安装第二层包装。
  function setCacheVerbose(on) {
    __cacheTraceOn = !!on;
    if (__cacheTraceOn) { __installCacheTrace(); return; }
  }


// ===== 【27】Dismissible 确认回程 =====
  // DismissDirection 枚举镜像：Dart 里 `DismissDirection.endToStart` 是枚举值，
  // 跨语言只有名字能表达（宿主也按 name 下发/回传），因此 JS 侧的同名常量就是
  // 名字字符串。这样 `direction == DismissDirection.endToStart` 这种源码级比较
  // 在 JS 侧**语义不变**（生成器对 props 里的枚举值同样下发名字字符串）。
  G.DismissDirection = {
    horizontal: 'horizontal',
    vertical: 'vertical',
    startToEnd: 'startToEnd',
    endToStart: 'endToStart',
    up: 'up',
    down: 'down'
  };

  // 宿主侧桥接见 capabilities/dismissible/dismissible_bridge.dart 的
  // `_awaitJsValue`：evaluate 本函数触发一次事件，并等 token + 结果回传。
  // 挂 G（globalThis）：宿主经 evaluate 裸引用调用，与 `__jsuiAwaitRun` 同一约定。
  G.__jsuiAwaitValue = function (handleId, token, argsJson) {
    var h = handles[handleId];
    var args = [];
    try { args = argsJson ? JSON.parse(argsJson) : []; } catch (e) { args = []; }
    var out;
    try {
      out = (h && typeof h.obj === 'function') ? h.obj.apply(null, args) : null;
    } catch (e) {
      // 事件同步抛错：按「已返回 null」收尾，宿主那条 pending 必须有结果。
      console.error(String(e));
      host('jsuiAwaitValueDone', [token, 'null']);
      return;
    }
    var done = function (v) {
      var s = 'null';
      try { s = JSON.stringify(v === undefined ? null : v); } catch (e) { s = 'null'; }
      host('jsuiAwaitValueDone', [token, s]);
    };
    if (out && typeof out.then === 'function') {
      out.then(done, function () { done(null); });
    } else {
      done(out);
    }
  };


// ===== 【28】api 收尾 =====

  var api = {
    h: h,
    fn: fn,
    invoke: invoke,
    Component: Component,
    mount: mountRoot,
    dispose: disposeRoot,
    updateProps: updateRootProps,
    // 帧级批处理入口：宿主每帧 begin frame 调用，统一跑掉待处理重建
    // （setState 只标脏，见【9】markDirty / requestFlush）。
    flushPending: flushPending,

    leakSnapshot: leakSnapshot,
    cacheDump: cacheDump,
    setCacheVerbose: setCacheVerbose,
    sweepPage: sweepPage,

    // 跨语言句柄（通用层）：宿主侧句柄注册表经 evaluate 调用本端真实对象
    // （见 capabilities/core/handle_registry.dart）。
    reg: reg,
    release: releaseFromHost,
    call: callHandle
  };

  G.__jsui = api;
  // JS→宿主唯一出口（宿主桥）：`invoke` 发起调用，宿主**必定**结算——
  // 成功 `resolve`，实现抛错 `reject`。与 `__jsui`（页面挂载/事件回传等运行
  // 入口）分开，语义单一。
  G._app_host_ = { invoke: host, resolve: resolveHost, reject: rejectHost };
  // 模块表 `__modules` 由同一 IIFE 首段（_jsUiEnvVars）创建（挂 G），
  // 此处只登记 core，不再自带守卫。
  G.__modules['js_ui/core'] = api;
})();
