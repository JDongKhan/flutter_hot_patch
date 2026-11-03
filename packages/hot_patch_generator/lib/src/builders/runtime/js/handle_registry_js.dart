// 跨语言句柄注册表（JS 侧核心，通用层地基）。
//
// 解决问题：JS 与 Dart 各有一批「真实对象」（JS 的代理实例 / 闭包，Dart 的
// ScrollController / Key / …），一端需要操作另一端的对象。此前每个能力各写
// 一套通道 + 一张 id 表（fn / sc / tec / tc），新增能力就要动核心文件。
//
// 本片段把这件事收敛成**一套**机制：一个真实对象登记为一个**句柄**（id），
// 对端只持 id，所有操作按 id 转发给拥有端。对象、函数/block、控制器、未来
// 的 Key / ChangeNotifier / Widget 都只是不同 `kind`，新增能力 = 注册一个 kind 描述符，
// 核心文件（本文件 / runtime_source 骨架 / __disposeRoot）零改动。
//
// id 规则：`js:<kind>#<序号>`（kind 本身可带子类，如 `ctrl/Scroll`）——
// 序号全局单调仅用于唯一化，kind 用于一眼看懂是什么对象。
//
// scope：
//   - instance：随**持有它的组件实例**释放（构造期 / initState / build 里创建的
//               控制器、Key 等；实例从树上摘除时整份释放，与 Dart 的
//               State.dispose 语义一致）；
//   - page   ：随页面释放（登记时绑 __activeRoot.key，__disposeRoot 统一回收；
//               无组件归属的兜底）；
//   - global ：跨页面常驻，不随页面释放（静态字段 / 模块级单例）；
//   - local  ：由拥有者自己的代码显式释放（如构建期事件句柄，随组件卸载释放）。
//
// 归属只决定**释放时机**，不影响 id 反查：`__handles` 仍是全局表，宿主只持 id
// 也能找到对象（组件卸载时、`dispose()` 里显式释放时都没有页面上下文）。
//
// 释放语义（拥有端为准 + 页面兜底）：任一端 release 都会通知对端一并释放
// （1:1 资源两端必须同时消失）；重复 release 幂等，不会形成通知回环。
//
// **为什么本片段刻意不是 [JsUiLibrary.jsFragments]**（地基而非能力）：
//   1. 它必须拼在 mini-react 骨架**之前**（见 runtime_source 的拼接位置），
//      而模板片段统一落在骨架之后；
//   2. 它与宿主侧 handle_registry.dart 同因：它是插座，不是插头，永无第二实现。
const String handleRegistryJsSource = r'''
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

''';
