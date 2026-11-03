// mini-react —— JS 侧 UI 运行时核心（框架核心，独立成文件）。
//
// 与 runtime_js.dart 的骨架入口/桥（【1】~【3】、【11】+尾部）拼接后
// 注入同一 IIFE：这里定义 element 描述、reconciler（mount/patch/unmount）、
// 组件基类（setState/__bindFn）、作用域（按类型名）查找与订阅、脏调度批处理。
// 新增框架级机制（如 fiber、portals）改本文件；新增业务能力桥接
// （controller 等）仍走 capabilities/，两边互不干扰。
//
// 组件生命周期与 Flutter 对齐，统一由本文件派发：
//   initState / didChangeDependencies（首帧）→ mount【10】；
//   依赖变更 → didChangeDependencies → flush【9】；
//   父级重建 → didUpdateWidget(oldWidget) → patch【10】；
//   摘除 → deactivate → dispose → unmount【10】。
//   （activate 需「重挂载/reparent」场景，mini-react 无此能力，故不派发。）
//
// 分区与 runtime_js.dart 导航表一致（【5】~【10】）。

/// mini-react｜element 与事件句柄（__createElement / __createFnHandle / __invokeEventHandler）【5】。
const String miniReactElementSource = r'''

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

''';

/// props 深比较的最大递归深度（编译期配置）。
///
/// 原实现固定 `4`：超过 4 层的嵌套 props（如 style → decoration → gradient →
/// colors 这类结构）变化会被判为相等，导致 patch 不下发、UI 不刷新。
/// 这里提高到 32 并把入口改为函数，深度只在 Dart 常量一处维护。
const int jsUiMaxPropDiffDepth = 32;

/// mini-react｜reconciler 工具（__propsEqual / __nodeKeyOf / __nodeIdOf / __rootOf）【6】。
String miniReactReconcilerUtilsSource() => _miniReactReconcilerUtilsSource
    .replaceFirst('__EQ_MAX_DEPTH__', '$jsUiMaxPropDiffDepth');

const String _miniReactReconcilerUtilsSource = r'''

  // 深比较（用于避免每次重建都下发 props）；下面紧邻的 __nodeKeyOf /
  // __nodeIdOf / __renderRootIdOf / __rootOf 同属本分区。
  var EQ_MAX_DEPTH = __EQ_MAX_DEPTH__;
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

''';

/// mini-react｜回调调用（__invokeCallback）【7】。
///
/// `Component`（setState / context）已移到 flutter.js：它是
/// 「Dart / Flutter 对象在 JS 侧的代表」，不属于 mini-react 核心。运行时只留
/// 与句柄表相关的回调调用入口。
const String miniReactComponentBaseSource = r'''

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

''';

/// 作用域｜按**类型名**向上查找 + 消费者侧订阅（__scopeOf / __subscribeListenable）【8】。
const String miniReactScopeSource = r'''

  // **与 Flutter 的 InheritedWidget 同语义**：宿主结点用 `__provides`
  // （类型名 → 值）声明自己对外提供的作用域；查找**只认类型名**，不关心这个
  // 类型是模型、控制器还是别的什么 —— 正如 Dart 侧
  // `dependOnInheritedWidgetOfExactType<T>()` 不关心 T 是干嘛的。
  //
  // 「谁提供什么」由**各能力自己**注册（[__registerScope]）；reconciler 只在
  // mount/patch 时把结点 props 交给对应 publisher 折算成 `__provides`，核心
  // 零业务知识（与「新增能力 = 注册描述符」同构）。三方库的注册见
  // capabilities/js_ui_library.dart（provider 是其中一族）。
  var __scopePublishers = {};

  // 注册：宿主 widget 类型 → `props => {类型名: 值}`（返回空 = 不提供）。
  function __registerScope(hostType, publish) {
    __scopePublishers[hostType] = publish;
  }

  // mount/patch 时调用：把该宿主结点的 props 折算进 `__provides`。
  // 每次 patch 都重放（props 变了、或 publisher 换了实例，如 create 重跑）。
  function __publishScope(inst, props) {
    var publish = __scopePublishers[inst.__type];
    if (!publish) { return; }
    var provided = publish(props || {});
    inst.__provides = (provided && Object.keys(provided).length) ? provided : null;
  }

  // 从 [inst] 沿 `__parent` 向上取最近提供 [type] 的**值**（同名就近遮蔽）。
  // 必须是同步取值：渲染期 `model.count` 直接读，不能经异步桥回宿主。
  // 取不到返回 null（不猜、不回退）。
  function __scopeOf(inst, type) {
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
  function __subscribeListenable(anchor, value) {
    if (!value || typeof value.addListener !== 'function') { return; }
    var mine = anchor.__subs || (anchor.__subs = []);
    for (var i = 0; i < mine.length; i++) {
      if (mine[i].value === value) { return; }
    }
    var entry = { value: value };
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

  // 生成器产出的 JS 类（逻辑组件，如 Overlay）需要「从 context 沿作用域取某类型
  // 的值」——即 Dart 的 `X.of(context)`。这是**通用出口**，不是某个组件专用 API：
  // 传进来的 context 是任何 BuildContext 代理（取它的锚点向上找），类型名由调用方
  // 给（与 `dependOnInheritedWidgetOfExactType<T>` 同构，核心不认识具体类型）。
  // 取不到返回 null（不猜、不回退），调用方自行决定缺失时的行为。
  // 生成器产出的 JS 类按 context 取作用域值（Dart 的 `X.of(context)`）。
  // 与核心 `__scopeOf(inst, type)` 区分：这里接收的是 BuildContext 代理。
  G.__scopeOfContext = function (ctx, type) {
    var anchor = ctx && ctx.__anchor;
    return anchor ? __scopeOf(anchor, type) : null;
  };

''';

/// mini-react｜调度（__markDirty → flush 批处理）【9】。
const String miniReactSchedulerSource = r'''

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

''';

/// mini-react｜reconciler 主流程（mount / patch / unmount）【10】。
const String miniReactReconcilerSource = r'''

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

  // 宿主元素判据：字符串 type（Component.host 产物），或**没有重写 build** 的
  // 包装类（宿主包装类只继承 Component 的空 build；逻辑/翻译组件一定重写 build）。
  function __isHostElement(el) {
    var T = el.__type;
    if (typeof T === 'string') { return true; }
    if (typeof T !== 'function' || T.prototype == null) { return false; }
    return !Object.prototype.hasOwnProperty.call(T.prototype, 'build');
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
      // 作用域声明（`__provides`）：由该宿主类型注册的 publisher 折算（【8】）。
      __publishScope(hi, hi.__props);
      __hostNodes[hi.__id] = hi;
      __trackNode(hi.__id);
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
      // props 变更 → 作用域声明重放（provider 的 vm 实例可能已换）。
      __publishScope(oldInst, newProps);
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
    // didUpdateWidget 期间把构建锚点指向本实例（新建句柄的归属 / this.context）。
    __withBuilding(oldInst, function () { oldInst.didUpdateWidget(oldWidget); });
    __patchComponentChild(oldInst);
    return oldInst;
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

''';
