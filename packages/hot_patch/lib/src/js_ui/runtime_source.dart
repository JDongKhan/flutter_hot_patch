/// js_ui —— JS 侧 UI 运行时（框架代码，非按组件生成）。
///
/// 职责：把「JS 对象树」变成宿主能直接应用的增量补丁。
///   - element：`Text({...})` 返回的不可变描述对象；
///   - component/state：状态、setState、build 都在 JS；
///   - reconciler：重建 -> 对比 -> 产出 patch ops；
///   - context/provider：纯 JS 的作用域查找 + 订阅，宿主完全不感知；
///   - bridge：出方向只有一个对外入口 `__jsui.host(channel, args)`——
///     JS 发起调用，宿主实现后用 `__jsui.resolve(id, value)` 回填 Promise。
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
/// | 【1】 | 全局状态与工具（id 序号、句柄表、结点标记、页面根表） | 全体共用 |
/// | 【2】 | 出方向桥（emit / commit / send → `sendMessage`） | 全体共用 |
/// | 【3】 | 宿主注入 `__jsui.host` / `resolve`（唯一对外出口） | @HostInjected 专用 |
/// | 【4】 | element 与事件句柄（`h` / `fn` / `invoke`） | mini-react |
/// | 【5】 | reconciler 工具（`eq` / `keyOf` / `hostIdOf` / `rootFor`） | mini-react |
/// | 【6】 | 组件基类（`setState` / `__bind`） | mini-react（生成器产物的能力袋） |
/// | 【7】 | provider 取值与订阅（`watch` / `read` / `findProvider`） | provider 模式专用 |
/// | 【8】 | 调度（`markDirty` → `flush` 批处理） | mini-react |
/// | 【9】 | reconciler 主流程（`mount` / `patch` / `unmount`） | mini-react |
/// | 【10】 | 对外入口 `api`（mount / dispose / invoke / host） | 全体共用 |
///
/// 跨分区交叉点用行内 `[provider]` / `[mini-react]` 标注，便于判断
/// 「这段代码是为哪个设计写的」。
library;

import 'package:flutter/foundation.dart'
    show kDebugMode, kReleaseMode, defaultTargetPlatform, TargetPlatform;

// 能力 JS 片段（各能力文件内聚，runtime_source 拼接注入）：
//   - capabilities/scroll_controller_js.dart      → ScrollController 代理类
//   - capabilities/text_editing_controller_js.dart → TextEditingController 代理类
//   - capabilities/tab_controller_js.dart         → TabController 代理类
import 'capabilities/scroll_controller_js.dart';
import 'capabilities/tab_controller_js.dart';
import 'capabilities/text_editing_controller_js.dart';
import 'js/mini_react_js.dart';
import 'js/change_notifier_js.dart';

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
// 出口统一走 `__jsui.host`（唯一 JS→宿主入口）；宿主 'log' 处理器始终已注册，
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
// 出口统一走 `__jsui.host`（唯一 JS→宿主入口）；宿主 'log' 处理器始终已注册，
// 故 Promise 一定被回填、不会悬挂。
G.console = (typeof G.console === 'undefined') ? {} : G.console;
function __log(args) {
  if (typeof G.__jsui !== 'undefined' && G.__jsui.host) {
    var text = '';
    for (var i = 0; i < args.length; i++) {
      text += (i ? ' ' : '') + __fmt(args[i], []);
    }
    __jsui.host('log', [text]);
  }
}
G.console.debug = function() { if (G.kDebugMode) { __log(arguments); } };
G.console.info = function() { __log(arguments); };
G.console.log = function() { __log(arguments); };
G.console.warn = function() { __log(arguments); };
G.console.error = function() { __log(arguments); }
''';
/// 静态尾部：骨架状态与工具（原 _jsUiGlobals 其余）。
const String _jsUiGlobalsTail = r'''

  // ===== 【1】运行环境｜全局状态与工具 ==================================
  var idSeq = 0;
  var handlerSeq = 0;
  var handlers = {};
  var HOST = 1, COMP = 2;

  // pageKey -> { key, inst, dirty, flushing, ops }
  var roots = {};
  // pageKey -> 控制器[]（本页面构造的 ScrollController / TextEditingController /
  // TabController）。控制器内登记的转发句柄是框架内部实现（用户无从释放），
  // 故按页面登记，页面退出时由 disposeRoot 兜底释放；组件已在自身 dispose()
  // 释放则为空操作（releaseController 按 __kind 分派）。
  var pageControllers = {};
  // 正在 mount/patch/flush 的根；emit / 结点归属都读它。
  var activeRoot = null;
  // 正在构建的元素（build 执行期）——`context` 的锚点。watch/read 据此
  // 定位 provider 并订阅（与 Dart 的 BuildContext 语义一致：按**位置**而非
  // 「谁定义了这个方法」）。委托型组件（Builder/Consumer）把 builder 方法
  // 以 owner 为 this 调用时，锚点仍是它们自身的结点。
  var building = null;

  // 结点 id：`类型#序号`（序号全局单调，仅用于唯一化）。带类型是为了让宿主侧
  // 的 ValueKey / Flutter DevTools 一眼看出这是哪个 widget / 组件（调试可读性）。
  function nextId(kind) { idSeq += 1; return (kind || 'node') + '#' + idSeq; }

  // COMP 结点 id 用的类名：`class X {}` -> `X`（生成器产物均为具名类）。
  function compName(type) { return (type && type.name) || 'Component'; }

''';

/// 出方向桥｜emit / commit / send → sendMessage（唯一底层发送）【2】。
const String _jsUiEmit = r'''
  // ===== 【2】出方向桥｜唯一底层发送（emit / commit / send）============
  // 所有 JS→宿主消息都打到单桥通道 `_app_bridge_`，目标通道名放在消息体
  // `ch` 字段。宿主只订阅该桥通道一次，再按 ch 二次分发。
  // `send` 是运行时**内部**的低层发送（不对外暴露）；对外的唯一入口是
  // `__jsui.host`（见【3】），它等于 `send` + Promise 回填。
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

/// 宿主注入｜__jsui.host / resolve（唯一对外出口）【3】。
const String _jsUiHostBridge = r'''
  // ===== 【3】宿主注入｜__jsui.host / resolve（唯一对外出口）==========
  // JS 发起调用，宿主实现后回填结果
  // 生成器把 Dart 的 static 调用 `AccountCenter.getUserName(a, b)` 翻译成
  // `__jsui.host("getUserName", [a, b])`（参数载荷按形态给：纯位置→数组、
  // 纯具名→对象、混合→对象 + "@args" 键装位置实参）：本函数返回 Promise，
  // 经桥通道把 `{id, args}` 交给宿主，宿主实现完成后用
  // `__jsui.resolve(id, value)` 回填（见 JsRuntimeManager.registerHostMethod）。
  // 框架内建通道（日志 `log`、native 通道等）同样走这里，保持单一出口。
  var hostSeq = 0;
  var hostPending = {};
  function host(channel, args) {
    hostSeq += 1;
    var id = 'host' + hostSeq;
    var p = new Promise(function (resolve) { hostPending[id] = resolve; });
    send(channel, { id: id, args: args || [] });
    return p;
  }
  function resolveHost(id, value) {
    var r = hostPending[id];
    if (!r) { return; }
    delete hostPending[id];
    r(value);
  }

''';

/// mini-react｜element 与事件句柄（h / fn / invoke）【4】。

/// mini-react｜reconciler 工具（eq / keyOf / hostIdOf / rootFor）【5】。

/// mini-react｜组件基类（setState / __bind，生成器产物的能力袋）【6】。

/// provider｜向上查找 + 消费者侧订阅台账（watch / read / findProvider）【7】。

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
      key: pageKey, inst: null, dirty: [], flushing: false, ops: null
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
    try {
      root.ops = [];
      root.inst = mount(h(C, parse(propsJson), null), null, null);
      // 末位下发根结点 id，宿主据此挂载 _JsNode。
      emit({ op: 'root', id: hostIdOf(root.inst) });
      commit(root);
    } finally {
      activeRoot = prev;
    }
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
    // 页面退出兜底：释放本页面登记的控制器（删转发句柄 + 通知宿主释放真实
    // controller，按 __kind 分派）。组件若已在自身 dispose() 里释放，这里幂等。
    var scs = pageControllers[pageKey];
    if (scs) {
      for (var i = 0; i < scs.length; i++) { releaseController(scs[i]); }
      delete pageControllers[pageKey];
    }
    delete roots[pageKey];
  }

''';

/// UI 运行时骨架尾部（TextEditingController 片段后到 IIFE 闭包结束）。
const String _jsUiRuntimeSkeletonTail = r'''

  var api = {
    h: h,
    fn: fn,
    invoke: invoke,
    Component: Component,
    mount: mountRoot,
    dispose: disposeRoot,
    host: host,
    resolve: resolveHost
  };

  G.__jsui = api;
  // 模块表 `__modules` 由同一 IIFE 首段（_jsUiEnvVars）创建（挂 G），
  // 此处只登记 core，不再自带守卫。
  G.__modules['js_ui/core'] = api;
})();
''';

/// UI 运行时源码 = 骨架 + 各能力 JS 片段拼接（能力片段见 capabilities/*_js.dart）。
/// 顺序：骨架头部 → 滚动控制器 → 文本控制器 → 骨架尾部（同一 IIFE 作用域，
/// 片段间靠函数提升/后声明互相引用，与拆分前语义一致）。
/// UI 运行时源码 = 骨架各分区 + 各能力 JS 片段拼接（片段见上；同一 IIFE
/// 作用域，片段间靠函数提升/后声明互相引用，与拆分前语义一致）。
/// js_ui 运行时骨架（IIFE），由 [ensureJsUiRuntime] 注入。
/// 环境全局（模块表 / 标志 / console）并入 [_jsUiGlobals]；ChangeNotifier
/// 基类经 [changeNotifierSource] 拼接（均在 IIFE 内定义、挂 G 暴露给产物）。
String jsUiRuntimeSource() => [
  _jsUiGlobals(),
  _jsUiEmit,
  _jsUiHostBridge,
  miniReactElementSource,
  miniReactReconcilerUtilsSource,
  miniReactComponentBaseSource,
  miniReactProviderSource,
  miniReactSchedulerSource,
  miniReactReconcilerSource,
  _jsUiApi,
  changeNotifierSource,
  scrollControllerJsSource,
  textEditingControllerJsSource,
  tabControllerJsSource,
  _jsUiRuntimeSkeletonTail,
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
