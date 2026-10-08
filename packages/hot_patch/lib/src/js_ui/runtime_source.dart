/// js_ui —— JS 侧 UI 运行时（框架代码，非按组件生成）。
///
/// 职责：把「JS 对象树」变成宿主能直接应用的增量补丁。
///   - element：`Text({...})` 返回的不可变描述对象；
///   - component/state：状态、setState、build 都在 JS；
///   - reconciler：重建 -> 对比 -> 产出 patch ops；
///   - context/provider：纯 JS 的作用域查找 + 订阅，宿主完全不感知；
///   - bridge：仅一个出方向通道 `jsuiCommit`。
///
/// 宿主只做两件事：把 `type` 映射成 Flutter widget、应用 patch。
/// 因此新增 JS 组件/状态库不改宿主；只有新增「Flutter 侧不存在的视觉
/// widget」才往宿主注册表加一条。
///
/// **多根**：同一 JS 运行时里可并存多个页面，每个页面按 `pageKey` 隔离自己
/// 的结点树、provider 表、脏队列与出方向 ops（互不订阅、互不重建）。宿主
/// 每次 `mount`/`dispose` 都显式带 `pageKey`；事件在**构建期**由生成器产出
/// `this.__bind("方法/表达式")` 绑定到产出该结点的组件实例（Dart tear-off 语义），
/// 宿主点击只回传句柄 id，无任何运行时树形状启发。
///
/// 注入方式：由 JsRuntimeManager.ensureJsUiRuntime() 求值一次（幂等）。
library;

/// 运行时 JS 源码（幂等 IIFE，重复求值无副作用）。
const String jsUiRuntimeSource = r'''
(function () {
  var G = typeof globalThis !== 'undefined'
    ? globalThis
    : Function('return this')();
  if (G.__jsui) { return; }

  var idSeq = 0;
  var handlerSeq = 0;
  var handlers = {};
  var HOST = 1, COMP = 2;

  // pageKey -> { key, inst, dirty, flushing, ops }
  var roots = {};
  // 正在 mount/patch/flush 的根；emit / 结点归属都读它。
  var activeRoot = null;
  // 正在构建的元素（build 执行期）——`context` 的锚点。watch/read 据此
  // 定位 provider 并订阅（与 Dart 的 BuildContext 语义一致：按**位置**而非
  // 「谁定义了这个方法」）。委托型组件（Builder/Consumer）把 builder 方法
  // 以 owner 为 this 调用时，锚点仍是它们自身的结点。
  var building = null;

  function nextId() { idSeq += 1; return 'n' + idSeq; }

  // ---------------------------------------------------------------------
  // 与宿主唯一的出方向通道
  // ---------------------------------------------------------------------
  function sendHost(channel, obj, key) {
    if (typeof sendMessage === 'function') {
      obj.key = key;
      sendMessage(channel, JSON.stringify(obj));
    }
  }

  function emit(op) {
    if (activeRoot && activeRoot.ops) { activeRoot.ops.push(op); }
  }
  function commit(root) {
    var list = root.ops;
    root.ops = null;
    if (!list || !list.length) { return; }
    sendHost('jsuiCommit', { ops: list }, root.key);
  }

  // ---------------------------------------------------------------------
  // element / 事件句柄
  // ---------------------------------------------------------------------
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

  // ---------------------------------------------------------------------
  // 深比较（用于避免每次重建都下发 props）
  // ---------------------------------------------------------------------
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

  // ---------------------------------------------------------------------
  // Component / State
  // ---------------------------------------------------------------------
  function Component(props) { this.props = props || {}; }
  Component.prototype.setState = function (mutate) {
    if (typeof mutate === 'function') { mutate.call(this); }
    markDirty(this);
  };
  // 取最近 provider 提供的值并订阅（值变更 -> 重构建该位置的结点）。
  // 锚点是**当前构建的元素**（`building`）：订阅的是这个位置，notify 只重建
  // 这个位置（与 Dart context.watch 重建该 BuildContext 一致），且 provider
  // 按位置向上取最近一个 —— 不再依赖「谁调用」的启发式。
  Component.prototype.watch = function (type) {
    var anchor = building || this;
    var node = findProvider(anchor, type);
    if (!node) { return undefined; }
    if (node.__subs.indexOf(anchor) < 0) { node.__subs.push(anchor); }
    // 订阅双方各记一份：provider 侧 `__subs` 用于 notify 广播；订阅者侧
    // `__providerSubs` 用于卸载时精确退订（避免 provider 上残留死订阅）。
    var mine = anchor.__providerSubs || (anchor.__providerSubs = []);
    if (mine.indexOf(node) < 0) { mine.push(node); }
    return node.__value;
  };
  // 只读不订阅（同样按当前构建位置向上取最近 provider）。
  Component.prototype.read = function (type) {
    var node = findProvider(building || this, type);
    return node ? node.__value : undefined;
  };
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

  // 卸载时按订阅者自己记录的列表精确退订（watch 里登记在 `__providerSubs`）。
  function unsubscribeAll(inst) {
    var mine = inst.__providerSubs;
    if (!mine) { return; }
    for (var i = 0; i < mine.length; i++) {
      var subs = mine[i].__subs;
      if (!subs) { continue; }
      var j = subs.indexOf(inst);
      if (j >= 0) { subs.splice(j, 1); }
    }
    inst.__providerSubs = null;
  }

  // provider 结点：订阅者通知（ChangeNotifier.notifyListeners 也走这里）。
  function notifyProvider(node) {
    var subs = node.__subs || [];
    var list = subs.slice();
    for (var i = 0; i < list.length; i++) { markDirty(list[i]); }
  }

  // ---------------------------------------------------------------------
  // 调度：collected dirty -> 重建子树 -> 一次 commit（批处理）
  // ---------------------------------------------------------------------
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

  // ---------------------------------------------------------------------
  // mount / patch / unmount
  // ---------------------------------------------------------------------
  // 普通类组件（生成器产物不 extends Component）挂载基类能力：
  // props / setState / watch / read（含生成器产物使用的下划线别名
  // `this.__watch(...)` / `this.__read(...)`）/ __notify（provider 结点在
  // 模型 notify 时标记订阅者 dirty）。对 extends Component 的类重复赋值无害。
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
    inst.__notify = function () { notifyProvider(this); };
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
        __k: HOST, __id: nextId(), __type: el.type, __root: rootFor(parent),
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
    ci.__id = nextId();
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
      // 从所有 provider 的订阅表里摘掉自己（watch 把订阅登记在 provider 上）。
      unsubscribeAll(inst);
      // 释放构建期登记的（实例, 表达式）事件句柄，避免 handlers 表泄漏。
      var bag = inst.__bound;
      if (bag) {
        for (var k in bag) { delete handlers[bag[k].__fn]; }
        inst.__bound = null;
      }
      markUnmounted(inst.__child);
    }
  }

  // ---------------------------------------------------------------------
  // 对外入口
  // ---------------------------------------------------------------------
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
    delete roots[pageKey];
  }

  var api = {
    h: h,
    fn: fn,
    invoke: invoke,
    Component: Component,
    mount: mountRoot,
    dispose: disposeRoot,
    notifyProvider: notifyProvider
  };

  G.__jsui = api;
  G.__modules = G.__modules || {};
  G.__modules['js_ui/core'] = api;
})();
''';