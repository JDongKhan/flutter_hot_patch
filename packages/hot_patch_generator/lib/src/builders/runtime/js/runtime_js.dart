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
/// 每次 `mount`/`dispose` 都显式带 `pageKey`；翻译层只产出字面函数值，宿主
/// 元素 props 在**下发边界**由 `__hostProps` 统一换成 `{__fn:id}` 句柄（按结点
/// 缓存、重建复用），宿主点击只回传句柄 id，无任何运行时树形状启发。
///
/// 本文件集中维护 JS 侧**框架代码**，由生成器的 `ui_runtime` builder 写成
/// `patch/runtime.js`，运行时包只负责加载（幂等）：
///   - [runtimeJsSource]：UI 运行时骨架（IIFE）——环境全局（模块表
///     `__modules`、日志全局 `print` / `debugPrint`，挂 globalThis）+ element/
///     component/reconciler/context/订阅 + 能力桥 + commit 协议，
///     与组件无关；编译/平台标志由宿主求值前注入；
///   - 核心片段拆分：mini-react（mini_react_js.dart）、各能力（同目录 `*_js.dart`）。
///
/// **分区导航**（`runtimeJsSource` 内以 `// ===== 【n】` 分隔，编号即代码顺序）：
///
/// | 分区 | 内容 | 属于哪个设计 |
/// | --- | --- | --- |
/// | 【1】 | 运行环境 + 全局状态与工具（全局对象 / 模块表 / 日志全局 / id 序号 / 页面根表） | 全体共用 |
/// | 【2】 | 出方向桥（`__emitOp` / `__commitOps` / `__sendToHost` → `sendMessage`） | 全体共用 |
/// | 【3】 | 宿主桥 `_app_host_`（`invoke` / `resolve` / `reject`，唯一对外出口） | @HostInjected 专用 |
/// | 【4】 | 跨语言句柄注册表（`__registerHandle` / `__releaseHandle` / `__callHandle` / `__handleOp`）+ 控制器三件套基座 | 全体共用（新增能力只注册 kind） |
/// | 【5】 | element 与宿主回调句柄（`__isElement` / `__createFnHandle` / `__hostProps` / `__invokeEventHandler`） | mini-react |
/// | 【6】 | reconciler 工具（`__propsEqual` / `__nodeKeyOf` / `__keyedMatcher` / `__rootOf`） | mini-react |
/// | 【7】 | 构建锚点 / 生命周期派发 / 回调调用（`__withBuilding` / `__callLifecycle` / `G.__invokeCallback`） | mini-react（生成器产物的能力袋） |
/// | 【8】 | 作用域｜按类型名向上查找 + 消费者订阅（`__registerScope` / `__scopeOf` / `__subscribeListenable`） | 通用机制（三方库按类型注册，见 capabilities/js_ui_library.dart） |
/// | 【9】 | 调度（`__markDirty` → `__rebuildDirty` 批处理） | mini-react |
/// | 【10】 | reconciler 主流程（`__mount` / `__patch` / `__unmount`） | mini-react |
/// | 【11】 | 对外入口 `api` + 独立根事务（`__openRoot` / `__closeRoot`：页面根与弹层根共用） | 全体共用 |
/// | 【11.5】 | 跨模块核心符号（`G.__core`，供 flutter.js 值类区与能力模块解构） | 跨模块约定 |
/// | 【21】【25】~【27.5】 | BuildContext 代理 / 泄漏观测 / 缓存追踪 / Dismissible / extension | 按能力自洽 |
///
/// **命名约定**：`__` 前缀 = 框架内部符号（只在 runtime.js / flutter.js /
/// 能力模块之间使用）。对外只有三类入口，不在此列：
///   - 宿主契约 `G.__jsui.*`（Dart 侧 evaluate 按名调用）；
///   - 跨模块契约 `G.__core.*`（flutter.js / provider.js 解构）；
///   - 产物调用入口 `print` / `debugPrint` / `G.__invokeCallback` /
///     `G.__scopeOfContext` / `G.registerExtension`（生成器产物直接引用）。
///
/// **三方库与 Flutter SDK 的 API 面不在本文件**：provider 的 `context.watch/read`
/// 与作用域声明在它自己的包模块 `patch/provider.js`（生成器
/// `provider_module_js.dart`）；`showDialog` 系列与弹层面板机制在
/// `patch/flutter.js`（生成器 `dialogs_js.dart` / `navigator_js.dart`）。
/// 本文件只提供它们要用的通用机制（作用域 / 代理 / 独立根挂载），经 `G.__core` 交接。
///
/// **值类区不在本文件**：`Duration` / `Size` / `Offset` / `Color` /
/// `ChangeNotifier` / 各 Controller / `Key` / 动画等「Dart 值对象与控制器镜像」
/// 已迁至 `patch/flutter.js`（见 widget_module_builder 的值类区），本文件只留
/// 语言层与 mini-react 核心。它们共用的核心符号经 `G.__core` 交接。
///
/// 跨分区交叉点用行内 `[ctx]` / `[mini-react]` 标注，便于判断
/// 「这段代码是为哪个设计写的」。
library;

// 核心 JS 片段随本文件迁入生成器（`runtime/js/` 同目录），由
// [runtimeJsSource] 按**固定顺序**拼接成单个 `patch/runtime.js`。
// 运行时包（hot_patch）不再持有任何 JS 源码：JS 修复随产物发布即可生效，
// 不需要发版。
import 'build_context_js.dart';
import 'cache_trace_js.dart';
import 'handle_registry_js.dart';
import 'js_extension_js.dart';
import 'key_sig_js.dart';
import 'mini_react_js.dart';

/// UI 运行时骨架头部（到 ScrollController 片段前）。
/// 运行环境｜IIFE 入口 + 全局状态与工具（id 序号、句柄表、结点标记、页面根表）【1】。
/// IIFE 骨架第一段：全局对象 + 运行环境（模块表 / 编译平台标志 / 日志全局，
/// 原 jsRuntimeEnvSource 并入）。环境全局在 IIFE 内挂 G（globalThis），
/// 产物（模块 evaluate）经全局对象裸引用可见，与顶层 var 语义等价。
String _jsUiGlobals(String version) =>
    _jsUiGlobalsHead(version) + _jsUiEnvVars() + _jsUiGlobalsTail;

/// 静态头部：IIFE 入口 + 全局对象 + **按内容哈希的幂等守卫**。
///
/// `G.__jsuiVersion` 由本文件内容哈希生成（[runtimeContentVersion]）：
///   - 哈希相同（同一份产物被重复加载 / 多个 manager）= 短路，不重复初始化、
///     不丢已挂载状态；
///   - 哈希不同（补丁包带了新版 runtime.js）= **继续执行并重建**整个 `__jsui`，
///     于是 JS 侧修复对已上线的 App 立即生效，无需发版。
String _jsUiGlobalsHead(String version) =>
    '''

(function () {
  var G = typeof globalThis !== 'undefined'
    ? globalThis
    : Function('return this')();
  if (G.__jsui && G.__jsuiVersion === '$version') { return; }
  G.__jsuiVersion = '$version';
''';

/// env 标志（插值生成）：模块表 / 编译平台标志 / 日志全局（print、debugPrint）。
/// 直接引用 Flutter 全局 [kDebugMode] / [kReleaseMode] / [defaultTargetPlatform]，
/// 不再经参数传递。
String _jsUiEnvVars() => '''


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
''';

/// 静态尾部：骨架状态与工具（原 _jsUiGlobals 其余）。
const String _jsUiGlobalsTail = r'''

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
      var i = this.indexOf(value);
      if (i < 0) { return false; }
      this.splice(i, 1);
      return true;
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
      this.splice(index, 0, value);
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
    }
  });
  //   - int 的 `isEven` / `isOdd` 是 Dart 的属性（不是方法），JS 数字没有；
  //     生成器按 Dart 写法一比一产出 `n.isEven`，故按同名同义补 getter。
  __defineProtoGetter(Number.prototype, {
    isEven: function () {
      return this % 2 === 0;
    },
    isOdd: function () {
      return this % 2 !== 0;
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

''';

/// 出方向桥｜__emitOp / __commitOps / __sendToHost → sendMessage（唯一底层发送）【2】。
const String _jsUiEmit = r'''
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

''';

/// 宿主桥｜_app_host_.invoke / resolve / reject（唯一对外出口）【3】。
const String _jsUiHostBridge = r'''
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

''';

/// mini-react｜element 与事件句柄（h / fn / invoke）【5】。

/// mini-react｜reconciler 工具（__propsEqual / __nodeKeyOf / hostNodeIdOf / __rootOf）【6】。

/// mini-react｜组件基类（setState / __bindFn，生成器产物的能力袋）【7】。

/// 作用域｜按类型名向上查找 + 消费者侧订阅（__registerScope / __scopeOf）【8】。

/// mini-react｜调度（__markDirty → flush 批处理）【9】。

/// mini-react｜reconciler 主流程（mount / patch / unmount）【10】。

/// 对外入口｜api（Dart 只调 mount / dispose / invoke / host）【11】。
const String _jsUiApi = r'''
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

''';

/// 泄漏观测**切面**：纯只读探针，只导出运行时自维护的三张表——页面根表
/// __roots、句柄表 __handles、页面句柄索引 __pageHandles。JS 堆无法直接枚举，但页面级
/// 对象（组件实例 / 控制器代理 / 函数闭包 / 监听器）全部经这三张表可达：表清
/// 干净，其余对象失去引用自然可被 GC；表里有残留就是真泄漏。宿主在页面进入 /
/// 销毁两端取快照做比对（见 js_leak_snapshot.dart）；[cacheDump] 则是排查用的
/// 全量清单。
///
/// **切面约束**：本段不挂在 __registerHandle / __releaseHandle / mount / unmount 等任何业务
/// 路径上（不计数、不改任何表），业务逻辑完全感知不到它存在；宿主只在 debug
/// 构建里调用（kDebugMode 门控），release 下这些函数即使被拼入也不会执行。
/// 之所以无条件拼入：产物分不出 debug/release，体积换「不参与业务」的简单性。
const String _jsUiLeakSnapshotFn = r'''

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
''';

/// 泄漏观测 / 缓存追踪切面的 api 成员。宿主 debug 代码经 `__jsui.leakSnapshot()` /
/// `__jsui.setCacheVerbose(true)` 调用；release 下无人调用（宿主调用点被
/// kDebugMode 裁掉）。
const String _jsUiLeakApiMember =
    '    leakSnapshot: __leakSnapshot,\n'
    '    cacheDump: __cacheDump,\n'
    '    setCacheVerbose: __setCacheVerbose,\n'
    '    sweepPage: __sweepPage,\n';

/// UI 运行时骨架尾部·前段（TextEditingController 片段后到 api 对象开口）。
const String _jsUiRuntimeSkeletonTailHead = r'''

  // 宿主侧契约（`__jsui.<key>`，Dart 侧 evaluate 按名调用）：只保留宿主真正用到的入口。
  var api = {
    invoke: __invokeEventHandler,
    // 需要结果的事件调用（宿主等待 Future）：执行句柄 → 若返回 Promise 则
    // await → 经宿主通道 `jsuiEventResult` 回传 token 与结果。与能力无关，
    // 所有 `Future<T>` 回调共用（见 `JsRuntimeManager.invokeAwait`）。
    invokeAwait: __invokeEventHandlerAwait,
    mount: __mountRoot,
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
''';

/// 跨模块核心符号导出面：值类区与能力模块（`flutter.js` / `capabilities/*.js`）
/// 运行在独立模块作用域，与 runtime 的 IIFE 不共享词法环境。原型补丁、控制器
/// 注册、句柄表、reconciler 仍由 runtime 拥有，此处一次性挂到 G，模块顶部解构
/// 取用——与 `__jsui` / `__modules` 同一约定：**跨模块只走 G**，不假设同一作用域。
///
/// 交接的是**通用机制**，不含任何能力语义：作用域查找、BuildContext 代理、
/// 独立根的挂载/卸载、宿主桥。具体用法（provider 的作用域声明、
/// showDialog 的面板策略）在各自模块里。
///
/// **可变状态用访问器**：`__building` / `__activeRoot` 是核心闭包里的 var，直接
/// 取值会把当时的快照带进模块（之后永不更新）。故都以 getter（`__activeRoot`
/// 另加 setter）暴露，按属性实时读写。
const String _jsUiCrossModuleExports = r'''
  G.__core = {
    // 句柄机制。register/release 走转发调用：debug 缓存追踪切面会在运行时
    // 替换这两个实现，直接引用会让跨模块调用绕过切面。
    __handleOp: __handleOp,
    __registerHandle: function (obj, kind, opts) { return __registerHandle(obj, kind, opts); },
    __releaseHandle: function (id, notify) { return __releaseHandle(id, notify); },
    __handleObjectOf: __handleObjectOf,
    __createFnHandle: __createFnHandle,
    // 作用域机制（provider 在自己的模块 patch/provider.js 里注册作用域）。
    __registerScope: __registerScope,
    __scopeOf: __scopeOf,
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
''';

/// UI 运行时骨架尾部·后段（api 收尾到 IIFE 闭包结束）。
const String _jsUiRuntimeSkeletonTailEnd = r'''
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
''';

/// js_ui 运行时源码 = 核心骨架各分区 + 各能力片段拼接成**一个 IIFE**，
/// 由生成器写成 `patch/runtime.js`（构建期产物，随热更包发布）。
///
/// 运行时包（hot_patch）只负责**加载**它：`JsRuntimeManager.ensureJsUiRuntime`
/// 从补丁根目录读 `runtime.js` 求值（并把 kDebugMode / Platform 等编译期
/// 标志先行注入）。因此任何 JS 侧修复都只需重出产物，无需发版。
///
/// 所有片段在**同一 IIFE 作用域**，片段间靠函数提升 / 后声明互相引用，与拆分前
/// 语义一致。拼接顺序 = 核心骨架（【2】~【11.7】）→ 能力片段（【21】~【27.5】），
/// 后面的片段可直接引用前面已执行的内容。值类区不在这里（见 `flutter.js`）。
///
/// 产物体积较大，**每个分区都以 `// ===== 【n】标题 =====` 注释隔开**，便于
/// 排查线上问题时直接定位到某一段。

String runtimeJsSource() {
  // 版本 = 除头部以外的全部内容哈希（头部要写入版本号，不能参与计算）。
  // 内容一变 → 版本变 → 已上线 App 里的 runtime.js 会被原地重建。
  final body = [
    _section('【2】出方向桥（__emitOp / __commitOps）', _jsUiEmit),
    _section('【3】宿主桥 _app_host_', _jsUiHostBridge),
    _section('【4】跨语言句柄注册表', handleRegistryJsSource),
    _section('【5】element 与事件句柄', miniReactElementSource),
    _section('【6】reconciler 工具', miniReactReconcilerUtilsSource()),
    _section('【7】组件基类', miniReactComponentBaseSource),
    _section('【8】作用域与订阅', miniReactScopeSource),
    _section('【9】调度', miniReactSchedulerSource),
    _section('【10】reconciler 主流程', miniReactReconcilerSource),
    _section('【11】对外入口 api', _jsUiApi),
    // 值类区（Dart 值对象 / Controller 类族）已迁至 flutter.js：runtime.js 只留
    // 语言层与 mini-react 核心。它们需要的那几个核心符号在此交接。
    _section('【11.5】跨模块核心符号（供 flutter.js 值类区）', _jsUiCrossModuleExports),
    // State 句柄（GlobalKey.currentState）随 flutter.js 发布：它承载的是 Dart
    // State 对象，与控件 / 值类同层，runtime.js 不认识它（见 state_handle_js.dart）。
    // Key 签名：reconciler 的 __patchChildren 直接用 __keySig，故属核心。
    _section('【11.7】Key 签名（__keySig / __objectToken）', keySigJsSource),
    // 各能力片段：位于骨架之后（可安全调用核心函数）、IIFE 收尾之前。
    // BuildContext 代理留在核心侧（机制：代理 / 句柄 / 通用 op 转发）。它的
    // 库级 API（provider 的 watch/read）由 patch/provider.js 在求值时补到原型上
    // （同一全局对象，不要求同一作用域）。
    _section('【21】BuildContext 代理', buildContextJsSource),
    // 泄漏观测：无条件拼入（构建期不知道 App 是 debug 还是 release）。
    // 宿主侧调用点仍由 kDebugMode 门控，release 下这些函数不会被调用，
    // 只占体积、不影响行为。
    _section('【25】泄漏观测（debug 用）', _jsUiLeakSnapshotFn),
    // 缓存详细追踪切面：同样无条件拼入（分不出 debug/release），默认关闭，
    // 只有宿主显式 setCacheVerbose(true) 才安装包装。
    _section('【26】缓存详细追踪（debug 用）', cacheTraceJsSource),
    // Dismissible 没有专属 JS 逻辑：confirmDismiss 的结果走通用
    // `__jsui.invokeAwait`（见【5】事件句柄），故不占独立片段。
    // Dart extension 注册机制：生成器在扩展声明处发射 `registerExtension(...)`，
    // 原型成员随产物注册（调用点与 Dart 一对一，无名字映射）。
    _section('【27.5】Dart extension 注册（registerExtension）', jsExtensionJsSource),
    _section('【28】api 收尾', _jsUiRuntimeSkeletonTailHead),
    _jsUiLeakApiMember,
    _jsUiRuntimeSkeletonTailEnd,
  ].join('\n');
  final version = runtimeContentVersion(body);
  final head = _section(
    '【1】运行环境｜IIFE 入口 + 全局对象 + 日志全局（版本 $version）',
    _jsUiGlobals(version),
  );
  return '$head$body';
}

/// 运行时内容版本：FNV-1a 32 位哈希（十六进制）。
///
/// 不依赖 `String.hashCode`（跨 VM 版本不保证稳定）。同一份源码在任意机器 /
/// 任意次构建得到同一版本号，因此「产物是否变化」的判定是确定的。
String runtimeContentVersion(String source) {
  var hash = 0x811c9dc5;
  for (final unit in source.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// 分区注释头：产物里每段 JS 都有可搜索的边界（`// ===== 【n】标题 =====`）。
String _section(String title, String body) => '\n// ===== $title =====\n$body';
