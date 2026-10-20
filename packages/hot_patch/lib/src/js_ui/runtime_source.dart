/// js_ui —— JS 侧 UI 运行时（框架代码，非按组件生成）。
///
/// 职责：把「JS 对象树」变成宿主能直接应用的增量补丁。
///   - element：`Text({...})` 返回的不可变描述对象；
///   - component/state：状态、setState、build 都在 JS；
///   - reconciler：重建 -> 对比 -> 产出 patch ops；
///   - 作用域/context：按**类型名**向上查找 + 订阅（不关心类型是模型还是别的），
///     取值在 JS 内同步完成；同时向宿主发同名 op，由宿主在真值 BuildContext 上
///     登记依赖（宿主侧的权威校验）；
///   - bridge：出方向只有一个对外入口 `_app_host_.invoke(channel, args)`——
///     JS 发起调用，宿主**必定**回填：成功用 `_app_host_.resolve(id, value)`，
///     宿主实现抛错用 `_app_host_.reject(id, message)`（JS 侧 await 处抛出）。
///     增量补丁 `jsuiCommit`、日志 `log`、native 通道、@HostInjected 方法
///     全部复用这一个入口（内部统一打到单桥通道 `_app_bridge_`，消息体 `ch`
///     字段标示目标通道，宿主一次订阅、二次分发）。
///
/// 宿主只做两件事：把 `type` 映射成 Flutter widget、应用 patch。
/// 因此新增 JS 组件/状态库不改宿主；只有新增「Flutter 侧不存在的视觉
/// widget」才往宿主注册表加一条。
///
/// **多根**：同一 JS 运行时里可并存多个页面，每个页面按 `pageKey` 隔离自己
/// 的结点树、订阅、脏队列与出方向 ops（互不订阅、互不重建）。宿主
/// 每次 `mount`/`dispose` 都显式带 `pageKey`；事件在**构建期**由生成器产出
/// `this.__bind("方法/表达式")` 绑定到产出该结点的组件实例（Dart tear-off 语义），
/// 宿主点击只回传句柄 id，无任何运行时树形状启发。
///
/// 本文件集中维护 JS 侧**框架代码**，由 JsRuntimeManager 单入口注入（幂等）：
///   - [jsUiRuntimeSource]：UI 运行时骨架（IIFE）——环境全局（模块表
///     `__modules`、编译/平台标志、console 桥，挂 globalThis）+ element/
///     component/reconciler/context/订阅 + 能力桥 + ChangeNotifier 基类 +
///     commit 协议，与组件无关；
///   - 核心片段拆分：mini-react（mini_react_js.dart）、ChangeNotifier
///     （change_notifier_js.dart）、能力桥（capabilities/）。
///
/// **分区导航**（`jsUiRuntimeSource` 内以 `// ===== 【n】` 分隔，按代码顺序）：
///
/// | 分区 | 内容 | 属于哪个设计 |
/// | --- | --- | --- |
/// | 【1】 | 全局状态与工具（id 序号、结点标记、页面根表） | 全体共用 |
/// | 【1b】 | 跨语言句柄注册表（`reg` / `release` / `call` / `handleOp`） | 全体共用（新增能力只注册 kind） |
/// | 【1c】 | Dart 标准库 → JS 内建补齐（`Array.prototype.clear` 等） | 全体共用（生成器看不到接收者类型，同名方法无法在编译期区分） |
/// | 【2】 | 出方向桥（emit / commit / send → `sendMessage`） | 全体共用 |
/// | 【3】 | 宿主桥 `_app_host_`（`invoke` / `resolve` / `reject`，唯一对外出口） | @HostInjected 专用 |
/// | 【4】 | element 与事件句柄（`h` / `fn` / `invoke`） | mini-react |
/// | 【5】 | reconciler 工具（`eq` / `keyOf` / `hostIdOf` / `rootFor`） | mini-react |
/// | 【6】 | 组件基类（`setState` / `__bind`） | mini-react（生成器产物的能力袋） |
/// | 【7】 | 作用域｜按类型名向上查找 + 消费者订阅（`registerScope` / `scopeOf` / `subscribeListenable`） | 通用机制（三方库按类型注册，见 capabilities/js_ui_library.dart） |
/// | 【8】 | 调度（`markDirty` → `flush` 批处理） | mini-react |
/// | 【9】 | reconciler 主流程（`mount` / `patch` / `unmount`） | mini-react |
/// | 【10】 | 对外入口 `api`（mount / dispose / invoke / host） | 全体共用 |
///
/// 跨分区交叉点用行内 `[ctx]` / `[mini-react]` 标注，便于判断
/// 「这段代码是为哪个设计写的」。
library;

import 'package:flutter/foundation.dart'
    show kDebugMode, kReleaseMode, defaultTargetPlatform, TargetPlatform;

// 能力 JS 片段**不在此 import**：各能力（Flutter 等价物与三方库一视同仁）的
// 片段由自己的 [JsUiLibrary.jsFragments] 提供，[jsUiRuntimeSource] 遍历注册表
// 拼接（见 capabilities/js_ui_library.dart 的 _seedBuiltins）。
// 本文件只保留**骨架地基**片段：
//       capabilities/core/handle_registry_js.dart → 跨语言句柄注册表（必须先于一切能力）
import 'capabilities/core/handle_registry_js.dart';
import 'capabilities/js_ui_library.dart';
import 'js/mini_react_js.dart';

/// UI 运行时骨架头部（到 ScrollController 片段前）。
/// 运行环境｜IIFE 入口 + 全局状态与工具（id 序号、句柄表、结点标记、页面根表）【1】。
/// IIFE 骨架第一段：全局对象 + 运行环境（模块表 / 编译平台标志 / console
/// 桥，原 jsRuntimeEnvSource 并入）。环境全局在 IIFE 内挂 G（globalThis），
/// 产物（模块 evaluate）经全局对象裸引用可见，与顶层 var 语义等价。
String _jsUiGlobals() => _jsUiGlobalsHead + _jsUiEnvVars() + _jsUiGlobalsTail;

/// 静态头部：IIFE 入口 + 全局对象 + 幂等守卫。
const String _jsUiGlobalsHead = r'''


(function () {
  var G = typeof globalThis !== 'undefined'
    ? globalThis
    : Function('return this')();
  if (G.__jsui) { return; }
''';
/// env 标志（插值生成）：模块表 / 编译平台标志 / console 桥。
/// 直接引用 Flutter 全局 [kDebugMode] / [kReleaseMode] / [defaultTargetPlatform]，
/// 不再经参数传递。
String _jsUiEnvVars() =>
    '''


if (typeof G.__modules === 'undefined') {
  G.__modules = {};
}
// 编译/运行期标志（Dart kDebugMode/kReleaseMode + 当前平台注入）。
// 产物与 Dart 一比一：kDebugMode / kReleaseMode / Platform.isAndroid 原样
// 保留（见生成器 globalFlagJs / platformFlagJs），运行时注入同名对象。
G.kDebugMode = $kDebugMode;
G.kReleaseMode = $kReleaseMode;
G.Platform = {
  isAndroid: ${defaultTargetPlatform == TargetPlatform.android},
  isIOS: ${defaultTargetPlatform == TargetPlatform.iOS},
  isMacOS: ${defaultTargetPlatform == TargetPlatform.macOS},
  isWindows: ${defaultTargetPlatform == TargetPlatform.windows},
  isLinux: ${defaultTargetPlatform == TargetPlatform.linux},
  isFuchsia: ${defaultTargetPlatform == TargetPlatform.fuchsia}
};
// JS 原生日志方法（Dart debugPrint/print 转换产物直接调用）：
// 统一桥到逻辑通道 'log'（宿主 log 处理器 → HotPatchLog）。
// G.console.debug 语义 = 仅调试输出（受 kDebugMode 控制），其余级别始终输出。
// 注意：flutter_js 引擎可能自带 console（只有部分方法），不能用
// `typeof console === 'undefined'` 判断 —— 无条件合并覆盖，保证
// debug/info/log/warn/error 全部可用且路由到 log 服务。
// 出口统一走 `_app_host_.invoke`（唯一 JS→宿主入口）；宿主 'log' 处理器始终已注册，
// 故 Promise 一定被回填、不会悬挂。
// 值 → 字符串（对象/数组完整展开，循环引用安全）：JS 侧 `String(obj)` 只会
// 得到 `[object Object]`，日志里看不到任何字段。`__str` 递归展开 own 字段，
// 函数标成 `[Function name]`、循环引用标成 `[Circular]`（与 JSON.stringify
// 不同：不会因循环引用直接抛错，也不丢函数字段）。
// 生成器把 Dart 字符串插值（形如 '\$name'）翻译成 __str(name)（见
// js_translator _logArgJs），console 桥也用它，故挂在 G 上供产物裸引用。
function __fmt(v, stack) {
  if (typeof v === 'string') return v;
  if (v === null) return 'null';
  if (typeof v === 'undefined') return 'undefined';
  var t = typeof v;
  if (t === 'function') return '[Function ' + (v.name || 'anonymous') + ']';
  if (t !== 'object') return String(v);
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
// G.console.debug 语义 = 仅调试输出（受 kDebugMode 控制），其余级别始终输出。
// 注意：flutter_js 引擎可能自带 console（只有部分方法），不能用
// `typeof console === 'undefined'` 判断 —— 无条件合并覆盖，保证
// debug/info/log/warn/error 全部可用且路由到 log 服务。
// 出口统一走 `_app_host_.invoke`（唯一 JS→宿主入口）；宿主 'log' 处理器始终已注册，
// 故 Promise 一定被回填、不会悬挂。
G.console = (typeof G.console === 'undefined') ? {} : G.console;
function __log(level, args) {
  if (typeof G._app_host_ !== 'undefined' && G._app_host_.invoke) {
    var text = '';
    for (var i = 0; i < args.length; i++) {
      text += (i ? ' ' : '') + __fmt(args[i], []);
    }
    // 级别一并带给宿主（位置实参 [level, text]）：console.warn/error 在宿主侧
    // 就是 warn/error 级，可直接进统一上报出口；未知级别按 info 处理（见
    // builtin_host_methods.dart 的 _log）。
    G._app_host_.invoke('log', [level, text]);
  }
}
G.console.debug = function() { if (G.kDebugMode) { __log('debug', arguments); } };
G.console.info = function() { __log('info', arguments); };
G.console.log = function() { __log('info', arguments); };
G.console.warn = function() { __log('warn', arguments); };
G.console.error = function() { __log('error', arguments); }
''';
/// 静态尾部：骨架状态与工具（原 _jsUiGlobals 其余）。
const String _jsUiGlobalsTail = r'''

  // ===== 【1】运行环境｜全局状态与工具 ==================================
  var idSeq = 0;
  var HOST = 1, COMP = 2;

  // pageKey -> { key, inst, dirty, flushing, ops }
  var roots = {};
  // pageKey -> 句柄 id[]：本页面（scope=page）登记的全部跨语言句柄（控制器 /
  // 函数 / 未来的 Key / 对象…）。页面退出时由 disposeRoot 统一释放——新增能力
  // 只要按句柄登记即自动获得页面回收，无需再改 disposeRoot（见【1b】句柄注册表）。
  var pageHandles = {};
  // 正在 mount/patch/flush 的根；emit / 结点归属都读它。
  var activeRoot = null;
  // 正在构建的元素（build 执行期）——`context` 的锚点。`context.watch/read` 据此
  // 定位**作用域**（按类型名向上找，见【7】）并订阅（与 Dart 的 BuildContext
  // 语义一致：按**位置**而非「谁定义了这个方法」）。委托型组件（Builder/Consumer）
  // 把 builder 方法以 owner 为 this 调用时，锚点仍是它们自身的结点。
  var building = null;

  // id 统一规则：`<端>:<种类>/<子类>#<序号>`（子类可省），序号全局单调仅用于
  // 唯一化。带前缀是为了让宿主侧 ValueKey / Flutter DevTools 一眼看出 id 的
  // 归属端（js/dt）与种类（node/comp/ctrl/fn/key…）——调试可读性。
  //   结点：js:node/<Type>#N（宿主结点）/ js:comp/<Name>#N（组件结点）
  //   句柄：js:ctrl/Scroll#N、js:fn#N、dt:key/Global#N（见【1b】句柄注册表）
  function nodeId(type) { idSeq += 1; return 'js:node/' + type + '#' + idSeq; }
  function compId(type) { idSeq += 1; return 'js:comp/' + compName(type) + '#' + idSeq; }

  // COMP 结点 id 用的类名：`class X {}` -> `X`（生成器产物均为具名类）。
  function compName(type) { return (type && type.name) || 'Component'; }

  // ===== 【1c】Dart 标准库 → JS 内建补齐 ==============================
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

''';

/// 出方向桥｜emit / commit / send → sendMessage（唯一底层发送）【2】。
const String _jsUiEmit = r'''
  // ===== 【2】出方向桥｜唯一底层发送（emit / commit / send）============
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
    send('jsuiCommit', { args: { key: root.key, ops: list } });
  }

''';

/// 宿主桥｜_app_host_.invoke / resolve / reject（唯一对外出口）【3】。
const String _jsUiHostBridge = r'''
  // ===== 【3】宿主桥｜_app_host_.invoke / resolve / reject（唯一对外出口）======
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

''';

/// mini-react｜element 与事件句柄（h / fn / invoke）【4】。

/// mini-react｜reconciler 工具（eq / keyOf / hostIdOf / rootFor）【5】。

/// mini-react｜组件基类（setState / __bind，生成器产物的能力袋）【6】。

/// 作用域｜按类型名向上查找 + 消费者侧订阅（registerScope / scopeOf）【7】。

/// mini-react｜调度（markDirty → flush 批处理）【8】。

/// mini-react｜reconciler 主流程（mount / patch / unmount）【9】。

/// 对外入口｜api（Dart 只调 mount / dispose / invoke / host）【10】。
const String _jsUiApi = r'''
  // ===== 【10】对外入口｜api（Dart 只调 mount / dispose / invoke / host）
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
      // dirty 队列，挂载收尾后统一 flush（见【8】markDirty 与 mountRoot）。
      key: pageKey, inst: null, dirty: [], flushing: false,
      mounting: false, ops: null
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
    } finally {
      root.mounting = false;
      activeRoot = prev;
    }
    // 挂载期间累积的 setState（如子组件 initState 里 `setState(() => _loading = true)`）
    // 在这里补一次 flush：根补丁已下发，实例与结点都在，走的正是 patch 增量重建，
    // 与 Flutter「initState 里 setState → 首帧后再重建」语义一致。
    if (root.dirty.length) { flush(root); }
    return true;
  }

  function disposeRoot(pageKey) {
    var root = roots[pageKey];
    if (!root) { return; }
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
    // 页面退出兜底：统一释放本页面登记的**全部**句柄（控制器 / 函数 / Key /
    // 对象…，见【1b】句柄注册表）——拥有端销毁真实对象，对端丢句柄。组件若已
    // 在自身 dispose() 里释放，这里幂等。
    releasePageHandles(pageKey);
    delete roots[pageKey];
  }

''';

/// 泄漏观测 / 缓存全景函数（**仅 debug 构建拼入**，release 产物里没有这段）：
/// 导出运行时自维护的三张表——页面根表 roots、句柄表 handles、页面句柄索引
/// pageHandles。JS 堆无法直接枚举，但页面级对象（组件实例 / 控制器代理 /
/// 函数闭包 / 监听器）全部经这三张表可达：表清干净，其余对象失去引用自然
/// 可被 GC；表里有残留就是真泄漏。宿主在页面销毁后取一次做判定（见
/// js_leak_snapshot.dart）；[cacheDump] 则是排查用的全量清单。
const String _jsUiLeakSnapshotFn = r'''

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
''';

/// 泄漏观测的 api 成员（**仅 debug 构建拼入**；release 无此成员，宿主侧
/// `capture()` 的 typeof 守卫会拿到 "null" 静默跳过——双端同一构建标志）。
const String _jsUiLeakApiMember =
    '    leakSnapshot: leakSnapshot,\n    cacheDump: cacheDump,\n';

/// UI 运行时骨架尾部·前段（TextEditingController 片段后到 api 对象开口）。
const String _jsUiRuntimeSkeletonTailHead = r'''

  var api = {
    h: h,
    fn: fn,
    invoke: invoke,
    Component: Component,
    mount: mountRoot,
    dispose: disposeRoot,
''';

/// UI 运行时骨架尾部·后段（api 收尾到 IIFE 闭包结束）。
const String _jsUiRuntimeSkeletonTailEnd = r'''
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
''';

/// js_ui 运行时源码 = 核心骨架各分区 + **各三方库注入片段**拼接（IIFE），由
/// [ensureJsUiRuntime] 注入。所有片段在**同一 IIFE 作用域**，片段间靠函数
/// 提升 / 后声明互相引用，与拆分前语义一致。
///
/// 核心与能力的接缝即 [jsUiLibraries]：任何能力（Flutter 等价物 Key /
/// 各 Controller / BuildContext 代理，或三方库 provider / GetX / …）只需在
/// 自己的 [JsUiLibrary] 子类里声明 [JsUiLibrary.jsFragments]，**本文件不再
/// 变动**；本文件只保留骨架地基（句柄注册表必须先于一切能力）。
/// 环境全局（模块表 / 标志 / console）并入 [_jsUiGlobals]。
String jsUiRuntimeSource() => [
  _jsUiGlobals(),
  _jsUiEmit,
  _jsUiHostBridge,
  handleRegistryJsSource,
  miniReactElementSource,
  miniReactReconcilerUtilsSource,
  miniReactComponentBaseSource,
  miniReactScopeSource,
  miniReactSchedulerSource,
  miniReactReconcilerSource,
  _jsUiApi,
  // 各能力/三方库片段：位于骨架之后（可安全调用核心函数）、IIFE 收尾之前。
  // 顺序 = capabilities/js_ui_library.dart 的注册顺序。
  for (final library in jsUiLibraries) ...library.jsFragments,
  // 懒容器类型注册（Dart 侧能力声明折算）：必须在骨架之后再执行（用到
  // reconciler 里的 registerLazyChildHost），且在任何 mount 之前（幂等）。
  jsUiLazyChildHostRegistrations(),
  // 泄漏观测仅 debug 拼入：release 产物不含 leakSnapshot 函数与 api 成员，
  // 线上逻辑零增量（宿主侧调用点同样是 kDebugMode 门控，双端一致）。
  if (kDebugMode) _jsUiLeakSnapshotFn,
  _jsUiRuntimeSkeletonTailHead,
  if (kDebugMode) _jsUiLeakApiMember,
  _jsUiRuntimeSkeletonTailEnd,
].join('\n');


/// 运行时环境全局源码（依赖 Dart 侧注入的编译/平台标志，故为函数式生成）。
///
/// 与 [jsUiRuntimeSource] 同源维护：模块加载器（JsRuntimeManager.loadModule）
/// 依赖这里声明的全局，不再自带一份 JS 文本。
/// 内容：模块注册表 `__modules`、编译/运行期标志、console 桥、ChangeNotifier
/// 基类。**顶层书写（不包 IIFE）**：`var` 声明必须落到全局，供后续
/// `evaluate` 的模块产物（`__modules[...] = ...`）与产物里裸引用的
/// `kDebugMode` / `Platform` / `console` 可见。重复求值安全（`var`/`function`
/// 重复声明无副作用），由调用方做一次幂等注入。
/// 依赖这里声明的全局，不再自带一份 JS 文本。
/// 内容：模块注册表 `__modules`、编译/运行期标志、console 桥（ChangeNotifier
/// 基类已拆到 change_notifier_js.dart，不属于 env）。**顶层书写（不包 IIFE）**：
/// `var` 声明必须落到全局，供后续 `evaluate` 的模块产物（`__modules[...] =
