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
/// 本文件集中维护 JS 侧**框架代码**，由 JsRuntimeManager 分两块注入（幂等）：
///   - [jsUiRuntimeSource]：UI 运行时骨架（element/component/reconciler/
///     context/订阅 + commit 协议），与组件无关；
///   - [jsRuntimeEnvSource]：运行时环境全局（模块表 `__modules`、编译/平台
///     标志、console 桥、ChangeNotifier 基类），依赖 Dart 侧注入的标志。
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

import 'package:flutter/foundation.dart' show TargetPlatform;

// 能力 JS 片段（各能力文件内聚，runtime_source 拼接注入）：
//   - capabilities/scroll_controller_js.dart      → ScrollController 代理类
//   - capabilities/text_editing_controller_js.dart → TextEditingController 代理类
import 'capabilities/scroll_controller_js.dart';
import 'capabilities/text_editing_controller_js.dart';

/// UI 运行时骨架头部（到 ScrollController 片段前）。
const String _jsUiRuntimeSkeletonHead = r'''
(function () {
  var G = typeof globalThis !== 'undefined'
    ? globalThis
    : Function('return this')();
  if (G.__jsui) { return; }

  // ===== 【1】运行环境｜全局状态与工具 ==================================
  var idSeq = 0;
  var handlerSeq = 0;
  var handlers = {};
  var HOST = 1, COMP = 2;

  // pageKey -> { key, inst, dirty, flushing, ops }
  var roots = {};
  // pageKey -> ScrollController[]（本页面构造的控制器）。
  // 控制器内的 metrics 句柄是框架内部实现（用户无从释放），故按页面登记，
  // 页面退出时由 disposeRoot 兜底释放；组件已在自身 dispose() 释放则为空操作。
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

  // ===== 【4】mini-react｜element 与事件句柄（h / fn / invoke）========
  function h(type, props, children) {
    var ch = [];
    if (children != null) {
      ch = Array.isArray(children) ? children : [children];
    }
    return { type: type, props: props || {}, children: ch };
  }

  // 事件回调无法跨语言传递 -> 登记为句柄，宿主侧回调用 invoke 触发。
  function fn(f) {
    handlerSeq += 1;
    var id = 'fn' + handlerSeq;
    handlers[id] = f;
    return { __fn: id };
  }

  function invoke(id, payload) {
    var f = handlers[id];
    if (!f) { return; }
    if (typeof payload === 'string' && payload.length) {
      try { payload = JSON.parse(payload); } catch (e) { payload = null; }
    }
    f(payload);
  }

  // ===== 【5】mini-react｜reconciler 工具 ==============================
  // 深比较（用于避免每次重建都下发 props）；下面紧邻的 keyOf / hostIdOf /
  // rootFor 同属本分区。
  function eq(a, b, depth) {
    if (a === b) { return true; }
    if (depth <= 0) { return false; }
    if (typeof a !== typeof b) { return false; }
    if (a === null || b === null || typeof a !== 'object') { return false; }
    var aArr = Array.isArray(a), bArr = Array.isArray(b);
    if (aArr !== bArr) { return false; }
    var ka = Object.keys(a), kb = Object.keys(b);
    if (ka.length !== kb.length) { return false; }
    for (var i = 0; i < ka.length; i++) {
      if (!eq(a[ka[i]], b[ka[i]], depth - 1)) { return false; }
    }
    return true;
  }

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

  // ===== 【6】mini-react｜组件基类（生成器产物的能力袋）===============
  // 生成器产物**不** extends 本类：`augment` 把这些方法拷到实例上。
  // setState / __bind 属于 mini-react；中间的 watch / read 属于 provider
  // （见行内【7】标注）。
  function Component(props) { this.props = props || {}; }
  Component.prototype.setState = function (mutate) {
    if (typeof mutate === 'function') { mutate.call(this); }
    markDirty(this);
  };
  // ── 【7】provider｜取值 + 订阅（插入在组件基类中，供 this.watch/read）──
  // 取最近 provider 的**值**并订阅（值变更 -> 重构建该位置的结点）。
  // 锚点是**当前构建的元素**（`building`），即订阅者自己：provider 只是纯值
  // 结点，不感知订阅（与 Dart context.watch 一致——按位置取最近 provider，
  // 依赖由该 BuildContext 持有，而非 provider 记账）。
  Component.prototype.watch = function (type) {
    var anchor = building || this;
    var node = findProvider(anchor, type);
    if (!node) { return undefined; }
    subscribeVm(anchor, node, node.__value);
    return node.__value;
  };
  // 只读不订阅（同样按当前构建位置向上取最近 provider）。
  Component.prototype.read = function (type) {
    var node = findProvider(building || this, type);
    return node ? node.__value : undefined;
  };
  // ── 回到【6】mini-react｜事件句柄（__bind）────────────────────────────
  // 事件句柄：在**构建期**把事件表达式绑定到当前组件实例（Dart tear-off 语义）。
  // 生成器产出 `this.__bind("_incA")`——`this` 正是 build 作用域里的组件实例，
  // 也就是**定义该事件方法的组件**（含 Consumer/Builder 把 builder 方法
  // `.call(owner)` 的场景）。句柄随 props 传下去（`{__fn:id, __ev:原表达式}`），
  // 宿主点击时经 invoke(id) 回来；因为绑定信息挂在 props 上，包装型组件
  // （MultiProvider 透传 child）也不会把它弄丢。
  //   句柄执行时会还原**绑定时的构建位置**：事件表达式里的 `this.__read/__watch`
  //   按定义该表达式时的 context 位置解析（而非点击时的 `this`）。
  //   按 (实例, 表达式) 缓存：重建产出同一句柄 → props 稳定（增量补丁仍生效）；
  //   卸载时统一释放（markUnmounted）。
  Component.prototype.__bind = function (expr) {
    var bag = this.__bound || (this.__bound = {});
    if (bag[expr]) { return bag[expr]; }
    var self = this;
    var anchor = building || this; // 绑定时的 context 位置（见上）
    // 两种事件形态，触发即执行：裸方法名（`_incA`）→ 调实例方法；其余整体
    // 作为调用表达式求值（`this.__read("T").inc()`）。二者都无返回值语义。
    var isName = /^[A-Za-z_$][A-Za-z0-9_$]*$/.test(expr);
    var run = isName
      ? function (payload) {
          var m = self[expr];
          if (typeof m === 'function') { m.call(self, payload); }
        }
      : function () {
          new Function('return (' + expr + ');').call(self);
        };
    var handle = fn(function (payload) {
      // 还原绑定时的构建位置：表达式若含 `this.__read/__watch`，按当时的
      // context 位置解析（点击时无 build 上下文，`building` 为 null）。
      var prev = building;
      building = anchor;
      try { run(payload); }
      catch (e) { if (typeof console !== 'undefined' && console.error) { console.error(String(e)); } }
      finally { building = prev; }
    });
    handle.__ev = expr; // 便于调试：句柄带上原表达式
    bag[expr] = handle;
    return handle;
  };

  // ===== 【7】provider｜向上查找 + 消费者侧订阅台账 =====================
  // 从 [inst] 沿 `__parent` 向上取最近提供 [type] 的 provider —— 与 Dart
  // `context.read/watch` 的向上查找一致，取不到返回 null（不猜、不回退）。
  function findProvider(inst, type) {
    var p = inst.__parent;
    while (p) {
      if (p.__provides && Object.prototype.hasOwnProperty.call(p.__provides, type)) {
        return p.__provides[type];
      }
      p = p.__parent;
    }
    return null;
  }

  // 订阅：给 [vm] 挂一个「把 [anchor] 标脏」的监听。订阅由**消费者自己持有**
  // （provider 不记账），台账记在消费者侧 `__vmSubs`，卸载时精确退订。
  // 按 provider 结点去重：重建会再次 watch，但不会重复挂监听。
  function subscribeVm(anchor, node, vm) {
    if (!vm || typeof vm.addListener !== 'function') { return; }
    var mine = anchor.__vmSubs || (anchor.__vmSubs = []);
    for (var i = 0; i < mine.length; i++) {
      if (mine[i].node === node) { return; }
    }
    var entry = { node: node, vm: vm };
    entry.listener = function () { markDirty(anchor); };
    vm.addListener(entry.listener);
    mine.push(entry);
  }

  // 卸载时按消费者自己记录的台账精确退订。
  function unsubscribeAll(inst) {
    var mine = inst.__vmSubs;
    if (!mine) { return; }
    for (var i = 0; i < mine.length; i++) {
      var vm = mine[i].vm;
      if (vm && typeof vm.removeListener === 'function') {
        vm.removeListener(mine[i].listener);
      }
    }
    inst.__vmSubs = null;
  }

  // ===== 【8】mini-react｜调度（dirty → flush 批处理）==================
  // collected dirty -> 重建子树 -> 一次 commit。
  // 触发源有两处：mini-react 的 setState、provider 的订阅回调（见【7】）。
  function markDirty(inst) {
    if (!inst || inst.__unmounted || inst.__dirty) { return; }
    var root = inst.__root;
    if (!root) { return; }
    inst.__dirty = true;
    root.dirty.push(inst);
    if (!root.flushing) {
      root.flushing = true;
      try { flush(root); } finally { root.flushing = false; }
    }
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
          root.ops = [];
          inst.__child = patch(inst.__child, buildOf(inst), inst, inst.__slot);
          commit(root);
        }
      }
    } finally {
      activeRoot = prev;
    }
  }

  // ===== 【9】mini-react｜reconciler 主流程（mount / patch / unmount）==
  // 普通类组件（生成器产物不 extends Component）挂载基类能力：
  //   [mini-react] props / setState / __bind（构建期事件句柄）
  //   [provider]   watch / read（含生成器产物使用的下划线别名
  //                `this.__watch(...)` / `this.__read(...)`）
  // 对 extends Component 的类重复赋值无害。
  function augment(inst) {
    if (inst.props === undefined || inst.props === null) {
      inst.props = inst.__el ? inst.__el.props : {};
    }
    inst.setState = Component.prototype.setState;
    inst.watch = Component.prototype.watch;
    inst.read = Component.prototype.read;
    inst.__watch = Component.prototype.watch;
    inst.__read = Component.prototype.read;
    inst.__bind = Component.prototype.__bind;
  }

  // 在 [inst] 的 build 执行期间把 `building` 指向它 —— watch/read 与事件绑定
  // 据此拿到「当前构建位置」作为 context 锚点。building 只在同步的 build 调用
  // 内有效，退出即还原（委托型组件的 builder 方法在 build 调用栈内执行，
  // 因此锚点仍是该委托组件自身的结点）。
  function buildOf(inst) {
    var prev = building;
    building = inst;
    try { return inst.build(); } finally { building = prev; }
  }

  function mount(el, parent, slot) {
    if (el == null || el === false) { return null; }

    if (typeof el.type === 'string') {
      var hi = {
        __k: HOST, __id: nextId(el.type), __type: el.type, __root: rootFor(parent),
        __props: el.props, __children: [], __parent: parent
      };
      emit({ op: 'create', id: hi.__id, type: hi.__type, props: hi.__props });
      if (slot && slot.hostParentId) {
        emit({ op: 'insert', parent: slot.hostParentId, id: hi.__id, index: slot.index });
      }
      var idx = 0;
      for (var i = 0; i < el.children.length; i++) {
        var c = mount(el.children[i], hi, { hostParentId: hi.__id, index: idx });
        if (c) { hi.__children.push(c); idx += 1; }
      }
      // 值为 element 的 props（如 Scaffold.body / AppBar.title）：单独挂载，
      // 不入 children 列表，另发 propsChild 让宿主挂到对应 prop 上。
      hi.__propsChildren = {};
      mountPropChildren(hi, null, el.props || {});
      return hi;
    }

    var ci = new el.type(el.props, el.children);
    ci.__k = COMP;
    ci.__id = nextId(compName(el.type));
    ci.__el = el;
    ci.__parent = parent;
    ci.__slot = slot;
    ci.__root = rootFor(parent);
    augment(ci);
    if (typeof ci.initState === 'function') { ci.initState(); }
    ci.__child = mount(buildOf(ci), ci, slot);
    return ci;
  }

  function patch(oldInst, el, parent, slot) {
    if (el == null || el === false) {
      if (oldInst) { unmount(oldInst); }
      return null;
    }
    if (!oldInst) { return mount(el, parent, slot); }

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
      if (!eq(oldProps, el.props, 4)) {
        emit({ op: 'props', id: oldInst.__id, props: el.props });
      }
      oldInst.__props = el.props;
      patchChildren(oldInst, el.children);
      mountPropChildren(oldInst, oldProps, el.props || {});
      return oldInst;
    }

    oldInst.__el = el;
    oldInst.props = el.props;
    oldInst.children = el.children;
    oldInst.__child = patch(oldInst.__child, buildOf(oldInst), oldInst, oldInst.__slot);
    return oldInst;
  }

  function patchChildren(parentHost, newEls) {
    var old = parentHost.__children || [];
    var remaining = old.slice();
    var keyedOld = {};
    var i, j;
    for (i = 0; i < old.length; i++) {
      var k = keyOf(old[i]);
      if (k != null) { keyedOld['k' + k] = old[i]; }
    }

    var next = [];
    var hostIdx = 0;
    for (j = 0; j < newEls.length; j++) {
      var el = newEls[j];
      if (el == null || el === false) { continue; }
      var ek = el.props ? el.props.key : null;
      var matched = null;
      if (ek != null && keyedOld['k' + ek]) {
        matched = keyedOld['k' + ek];
      } else if (ek == null) {
        for (i = 0; i < remaining.length; i++) {
          if (remaining[i] && keyOf(remaining[i]) == null) { matched = remaining[i]; break; }
        }
      }
      if (matched) { remaining.splice(remaining.indexOf(matched), 1); }

      var inst = patch(matched, el, parentHost, { hostParentId: parentHost.__id, index: hostIdx });
      if (inst) {
        // 复用的结点位置变化 -> 下发 move（新建的自带 insert）。
        if (inst === matched && old.indexOf(inst) !== hostIdx) {
          emit({ op: 'move', parent: parentHost.__id, id: hostIdOf(inst), index: hostIdx });
        }
        next.push(inst);
        hostIdx += 1;
      }
    }

    for (i = 0; i < remaining.length; i++) {
      if (remaining[i]) { unmount(remaining[i]); }
    }
    parentHost.__children = next;
  }

  // 值为 element 的 props：新旧对比后复用/新建/移除，逐个下发 propsChild op。
  function isElement(v) {
    return v != null && typeof v === 'object' && v.type != null;
  }

  function mountPropChildren(hostInst, oldProps, newProps) {
    var old = hostInst.__propsChildren || {};
    var next = {};
    for (var k in newProps) {
      var pv = newProps[k];
      if (!isElement(pv)) { continue; }
      var prev = old[k] || null;
      var inst = patch(prev, pv, hostInst, null);
      if (!inst) { continue; }
      next[k] = inst;
      if (!prev) {
        emit({ op: 'propsChild', parent: hostInst.__id, key: k, childId: hostIdOf(inst) });
      }
    }
    for (var k2 in old) {
      if (!Object.prototype.hasOwnProperty.call(next, k2)) {
        unmount(old[k2]);
        emit({ op: 'propsChildRemove', parent: hostInst.__id, key: k2 });
      }
    }
    hostInst.__propsChildren = next;
  }

  function unmount(inst) {
    if (!inst) { return; }
    var hostId = hostIdOf(inst);
    if (hostId) { emit({ op: 'remove', id: hostId }); }
    markUnmounted(inst);
  }

  function markUnmounted(inst) {
    if (!inst) { return; }
    inst.__unmounted = true;
    if (inst.__k === HOST) {
      for (var i = 0; i < inst.__children.length; i++) { markUnmounted(inst.__children[i]); }
      var pcs = inst.__propsChildren;
      if (pcs) { for (var pk in pcs) { markUnmounted(pcs[pk]); } }
    } else {
      if (typeof inst.dispose === 'function') {
        try { inst.dispose(); } catch (e) {}
      }
      // [provider] 从各 VM 的监听表里摘掉自己（订阅登记在消费者侧 `__vmSubs`）。
      unsubscribeAll(inst);
      // [mini-react] 释放构建期登记的（实例, 表达式）事件句柄，避免 handlers 泄漏。
      var bag = inst.__bound;
      if (bag) {
        for (var k in bag) { delete handlers[bag[k].__fn]; }
        inst.__bound = null;
      }
      markUnmounted(inst.__child);
    }
  }

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

  // 挂载一个页面：pageKey 隔离根，moduleKey 定位模块，className 是导出工厂。
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
      root.inst = mount(C(parse(propsJson)), null, null);
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
    // 页面退出兜底：释放本页面登记的 ScrollController（删句柄 + 通知宿主
    // 释放真实 controller）。组件若已在自身 dispose() 里释放，这里幂等。
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
  // 模块表 `__modules` 由环境全局（jsRuntimeEnvSource）单点声明/创建，
  // 骨架注入前必已就位；此处只登记 core，不再自带一份守卫。
  G.__modules['js_ui/core'] = api;
})();
''';

/// UI 运行时源码 = 骨架 + 各能力 JS 片段拼接（能力片段见 capabilities/*_js.dart）。
/// 顺序：骨架头部 → 滚动控制器 → 文本控制器 → 骨架尾部（同一 IIFE 作用域，
/// 片段间靠函数提升/后声明互相引用，与拆分前语义一致）。
final String jsUiRuntimeSource = [
  _jsUiRuntimeSkeletonHead,
  scrollControllerJsSource,
  textEditingControllerJsSource,
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
String jsRuntimeEnvSource({
  required bool debugMode,
  required bool releaseMode,
  required TargetPlatform platform,
}) =>
    '''
if (typeof __modules === 'undefined') {
  var __modules = {};
}
// 编译/运行期标志（Dart kDebugMode/kReleaseMode + 当前平台注入）。
// 产物与 Dart 一比一：kDebugMode / kReleaseMode / Platform.isAndroid 原样
// 保留（见生成器 globalFlagJs / platformFlagJs），运行时注入同名对象。
var kDebugMode = $debugMode;
var kReleaseMode = $releaseMode;
var Platform = {
  isAndroid: ${platform == TargetPlatform.android},
  isIOS: ${platform == TargetPlatform.iOS},
  isMacOS: ${platform == TargetPlatform.macOS},
  isWindows: ${platform == TargetPlatform.windows},
  isLinux: ${platform == TargetPlatform.linux},
  isFuchsia: ${platform == TargetPlatform.fuchsia}
};
// JS 原生日志方法（Dart debugPrint/print 转换产物直接调用）：
// 统一桥到逻辑通道 'log'（宿主 log 处理器 → HotPatchLog）。
// console.debug 语义 = 仅调试输出（受 kDebugMode 控制），其余级别始终输出。
// 注意：flutter_js 引擎可能自带 console（只有部分方法），不能用
// `typeof console === 'undefined'` 判断 —— 无条件合并覆盖，保证
// debug/info/log/warn/error 全部可用且路由到 log 服务。
// 出口统一走 `__jsui.host`（唯一 JS→宿主入口）；宿主 'log' 处理器始终已注册，
// 故 Promise 一定被回填、不会悬挂。
var console = (typeof console === 'undefined') ? {} : console;
function __log(m) {
  if (typeof __jsui !== 'undefined' && __jsui.host) {
    __jsui.host('log', [String(m)]);
  }
}
console.debug = function(m) { if (kDebugMode) { __log(m); } };
console.info = function(m) { __log(m); };
console.log = function(m) { __log(m); };
console.warn = function(m) { __log(m); };
console.error = function(m) { __log(m); };
// ChangeNotifier 的 JS 基类（1:1 保持 Dart 类名）：模型 `class X
// extends ChangeNotifier` 共用，notifyListeners 触发订阅回调。
function ChangeNotifier() {
  this._listeners = [];
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
  this._listeners.slice().forEach(function(f) {
    f();
  });
};
// Dart ChangeNotifier.dispose：清空订阅（释放闭包引用）。被 dispose 后
// 不再响应 notify（原生语义：disposed 后 notify 抛错；JS 侧简化为静默）。
ChangeNotifier.prototype.dispose = function() {
  this._listeners = [];
};
''';