// mini-react —— JS 侧 UI 运行时核心（框架核心，独立成文件）。
//
// 与 runtime_source.dart 的骨架入口/桥（【1】~【3】、【10】+尾部）拼接后
// 注入同一 IIFE：这里定义 element 描述、reconciler（mount/patch/unmount）、
// 组件基类（setState/__bind）、provider 上下文查找与订阅、脏调度批处理。
// 新增框架级机制（如 fiber、portals）改本文件；新增业务能力桥接
// （controller 等）仍走 capabilities/，两边互不干扰。
//
// 分区与 runtime_source.dart 导航表一致（【4】~【9】）。


/// mini-react｜element 与事件句柄（h / fn / invoke）【4】。
const String miniReactElementSource = r'''

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
    if (!f) {
      // 宿主回传的句柄 id 在 JS 侧找不到 —— 说明该结点下发时的 handler 与当前
      // handlers 表不一致（已卸载回收 / 从未登记）。
      return;
    }
    if (typeof payload === 'string' && payload.length) {
      try { payload = JSON.parse(payload); } catch (e) { payload = null; }
    }
    f(payload);
  }

''';

/// mini-react｜reconciler 工具（eq / keyOf / hostIdOf / rootFor）【5】。
const String miniReactReconcilerUtilsSource = r'''

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

''';

/// mini-react｜组件基类（setState / __bind，生成器产物的能力袋）【6】。
const String miniReactComponentBaseSource = r'''

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
  // 构建期**闭包**句柄：与 __bind 语义相同（绑定到构建时的组件实例 / 构建
  // 位置），但接受真实 JS 函数而非表达式字符串——用于事件表达式引用了
  // 「构建期才存在的名字」（循环变量、build 局部变量）的场景：字符串方案在
  // 点击时求值，拿不到这些名字（如 `for (final s in kSorts) onTap: () =>
  // setState(() => _sort = s)`）。
  //   按 [key] 缓存：同一 (实例, key) 重复构建复用同一句柄 id（props 稳定，
  //   增量补丁不失效），只是把内部执行的闭包换成最新的（新捕获值）。
  //   key 由生成器按「表达式源码 + 当前循环变量值」拼出，故每次迭代互不串味。
  Component.prototype.__bindFn = function (key, f) {
    var bag = this.__boundFn || (this.__boundFn = {});
    var handle = bag[key];
    if (handle) { handle.__run = f; return handle; }
    var anchor = building || this;
    handle = fn(function (payload) {
      var prev = building;
      building = anchor;
      try { handle.__run(payload); }
      catch (e) { if (typeof console !== 'undefined' && console.error) { console.error(String(e)); } }
      finally { building = prev; }
    });
    handle.__run = f;
    handle.__key = key; // 便于调试：句柄带上构建期 key
    bag[key] = handle;
    return handle;
  };

''';

/// provider｜向上查找 + 消费者侧订阅台账（watch / read / findProvider）【7】。
const String miniReactProviderSource = r'''

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

''';

/// mini-react｜调度（markDirty → flush 批处理）【8】。
const String miniReactSchedulerSource = r'''

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

''';

/// mini-react｜reconciler 主流程（mount / patch / unmount）【9】。
const String miniReactReconcilerSource = r'''

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
    inst.__bindFn = Component.prototype.__bindFn;
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
      // 同理解放 __bindFn 登记的构建期闭包句柄。
      var bagFn = inst.__boundFn;
      if (bagFn) {
        for (var k in bagFn) { delete handlers[bagFn[k].__fn]; }
        inst.__boundFn = null;
      }
      markUnmounted(inst.__child);
    }
  }

''';
