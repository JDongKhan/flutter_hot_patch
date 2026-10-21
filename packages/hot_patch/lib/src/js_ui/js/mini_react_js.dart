// mini-react —— JS 侧 UI 运行时核心（框架核心，独立成文件）。
//
// 与 runtime_source.dart 的骨架入口/桥（【1】~【3】、【10】+尾部）拼接后
// 注入同一 IIFE：这里定义 element 描述、reconciler（mount/patch/unmount）、
// 组件基类（setState/__bindFn）、作用域（按类型名）查找与订阅、脏调度批处理。
// 新增框架级机制（如 fiber、portals）改本文件；新增业务能力桥接
// （controller 等）仍走 capabilities/，两边互不干扰。
//
// 组件生命周期与 Flutter 对齐，统一由本文件派发：
//   initState / didChangeDependencies（首帧）→ mount【9】；
//   依赖变更 → didChangeDependencies → flush【8】；
//   父级重建 → didUpdateWidget(oldWidget) → patch【9】；
//   摘除 → deactivate → dispose → unmount【9】。
//   （activate 需「重挂载/reparent」场景，mini-react 无此能力，故不派发。）
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

  // 事件回调无法跨语言传递 -> 登记为句柄（kind=fn，scope=local：由拥有者
  // 代码显式释放，如构建期 __bindFn 随组件卸载释放，见【1b】句柄注册表）。
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

  // 结点声明的 key（**值**，不是结点）：ValueKey / ObjectKey 实例、GlobalKey /
  // UniqueKey 的句柄实例，或 null（未声明）。比较一律经 [keySig]（见【10.6】），
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

''';

/// mini-react｜组件基类（setState / __bindFn，生成器产物的能力袋）【6】。
const String miniReactComponentBaseSource = r'''

  // ===== 【6】mini-react｜组件基类（生成器产物的能力袋）===============
  // 生成器产物**不** extends 本类：`augment` 把这些方法拷到实例上。
  // setState / __bindFn 属于 mini-react；上下文（`context.watch/read`）与
  // BuildContext 代理见【10.7】（调用面与 Dart 一致，不在实例上挂 `this.watch`）。
  function Component(props) { this.props = props || {}; }
  Component.prototype.setState = function (mutate) {
    if (typeof mutate === 'function') { mutate.call(this); }
    markDirty(this);
  };
  // ── 回到【6】mini-react｜事件句柄（__bindFn）─────────────────────────
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
  // → key 稳定），原始值按 String。WeakMap 自动回收，不延长捕获对象寿命。
  var __capIds = typeof WeakMap === 'function' ? new WeakMap() : null;
  var __capSeq = 0;
  function capKey(v) {
    if (v === null || v === undefined) { return ''; }
    var t = typeof v;
    if (t === 'object' || t === 'function') {
      if (!__capIds) { return String(v); }
      var id = __capIds.get(v);
      if (!id) { id = ++__capSeq; __capIds.set(v, id); }
      return '#' + id;
    }
    return String(v);
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
      catch (e) { if (typeof console !== 'undefined' && console.error) { console.error(String(e)); } }
      finally { building = prev; }
    });
    handle.__run = f;
    handle.__key = key; // 便于调试：句柄带上构建期 key
    bag[key] = handle;
    return handle;
  };

''';

/// 作用域｜按**类型名**向上查找 + 消费者侧订阅（scopeOf / subscribeListenable）【7】。
const String miniReactScopeSource = r'''

  // ===== 【7】作用域｜按类型名向上查找 + 消费者侧订阅 ==================
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

''';

/// mini-react｜调度（markDirty → flush 批处理）【8】。
const String miniReactSchedulerSource = r'''

  // ===== 【8】mini-react｜调度（dirty → flush 批处理）==================
  // collected dirty -> 重建子树 -> 一次 commit。
  // 触发源有两处：mini-react 的 setState、作用域订阅回调（见【7】`subscribeListenable`）。
  //
  // **挂载中不 flush**：`root.mounting` 期间 `root.ops` 归 mountRoot 累积（整棵树的
  // create/insert），而 flush 会重置并消耗同一份 ops —— 未下发的结点连同根 op 一起
  // 丢，宿主收不到根、页面永远停在加载态。setState 在 initState / 构造里是合法写法
  // （Flutter 也是首帧后再重建），故这里只入 dirty 队列，mountRoot 收尾时再 flush。
  function markDirty(inst) {
    if (!inst || inst.__unmounted || inst.__dirty) { return; }
    var root = inst.__root;
    if (!root) { return; }
    inst.__dirty = true;
    root.dirty.push(inst);
    if (!root.flushing && !root.mounting) {
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
          // 作用域依赖变更（__depDirty）走这里：与 Flutter 一致，
          // 先 didChangeDependencies 再 build；setState 触发的重建不调。
          if (inst.__depDirty) {
            inst.__depDirty = false;
            if (typeof inst.didChangeDependencies === 'function') {
              inst.didChangeDependencies();
            }
          }
          inst.__child = patchComponentChild(inst);
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
  //
  // 「懒容器 + 延迟子结点」：容器的 children 不随容器一起挂载，而是等**宿主**
  // 真的 inflate 到那个槽位时才挂载 —— 即 initState 由 `_JsNodeState` 的生命周期
  // 驱动。MiniReact 的挂载是一次性全树遍历，做不到层层按需；而「哪个子结点可见」
  // 的真值只在宿主侧（Flutter 的 element inflation）。所以这里只留一个**普通**
  // 零尺寸占位结点（复用 SizedBox 类型：不新增 widget 类型、产物形态零改动），
  // 真实子元素先挂在占位实例的 `__deferred` 上；宿主 inflate 到占位结点时经
  // `__lazyFn`（事件句柄同款 invoke 通道）回调 lazyMount，才真正 mount
  //（构造 + initState + build，顺序与 Flutter 一致）并把占位换成真实结点。
  //
  // 懒容器类型表：type -> true（无条件懒）| props 键名数组（带这些键之一才懒）。
  // 名单**不写在 JS 侧**：由 Dart 侧能力声明（JsUiLibrary.lazyChildHostTypes）
  // 折算成 `registerLazyChildHost(...)` 顶层语句，随运行时骨架一次性注入
  //（见 capabilities/js_ui_library.dart 的 jsUiLazyChildHostRegistrations）。
  var lazyChildHosts = {};

  // 注册一个懒容器类型。propKeys 为空 = 无条件懒（如 PageView/TabBarView：
  // 子项被 SliverFillViewport 强制成整屏）；非空 = 只有该结点 props 带其中
  // 任一键时才懒（如 ListView 只在带 itemExtent 时懒 —— 那时子项尺寸才被
  // 容器强制，零尺寸占位才布局中性；不带 itemExtent 的 ListView 子项尺寸按
  // 内容量出，零尺寸占位会让视口把全部 item 判可见，懒加载反而失效）。
  function registerLazyChildHost(type, propKeys) {
    lazyChildHosts[type] = (propKeys && propKeys.length) ? propKeys : true;
  }

  // 该宿主结点的 children 是否延迟挂载（按 type + props 判定）。
  function lazyChildOf(type, props) {
    var rule = lazyChildHosts[type];
    if (rule === true) { return true; }
    if (!rule) { return false; }
    for (var i = 0; i < rule.length; i++) {
      if (props && props[rule[i]] !== undefined) { return true; }
    }
    return false;
  }

  // 命名构造 `.builder` / `.separated` 的滚动视图：生成器只在**委托形态**
  // （`delegate: SliverChildBuilderDelegate(...)`，props 键 `builder`）下用 JS 代理类
  // 展开子结点；`.builder` 命名构造产出的是参数名键（`itemBuilder` / `itemCount` /
  // `separatorBuilder`）且**不展开** children。这里按同样的「沿 `__parent` 找拥有者
  // 方法」语义补上展开（与 flutter.js 的代理类一字不差），children 已有内容时原样
  // 返回（不重复展开、与生成器将来改回代理类兼容）。
  var builderHostTypes = {
    ListView: 1, GridView: 1, SliverList: 1, SliverGrid: 1,
    SliverFixedExtentList: 1, SliverFillViewport: 1,
    // `.builder` 命名构造没有 JS 代理类，但 itemBuilder 仍需在宿主侧展开：
    // 否则 itemCount > children.length，`_childAt` 越界返回无 key 占位，
    // ReorderableListView 会直接断言 "Every item must have a key"。
    ReorderableListView: 1, PageView: 1
  };
  function expandBuilderChildren(el, parent) {
    if (!builderHostTypes[el.type]) { return []; }
    // 代理类（生成的 builder 组件）已把展开结果写进内部键 __items，
    // 由 __h 归入 children 对象；有就直接用，不再重复展开。
    var slots = el.children || {};
    var pre = slots.__items;
    if (Array.isArray(pre) && pre.length) { return pre; }
    var p = el.props || {};
    var del = slots.delegate;
    var delBuilder = (del && del.__delegate === 'builder') ? del.builder : null;
    var name = p.itemBuilder || p.builder || delBuilder;
    if (typeof name !== 'string') { return []; }
    var n = p.itemCount !== undefined ? p.itemCount
        : (p.childCount !== undefined ? p.childCount
        : (del && del.childCount !== undefined ? del.childCount : 0));
    if (typeof n !== 'number' || n <= 0) { return []; }
    var owner = parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return []; }
    var sep = p.separatorBuilder;
    // 传给 builder 的 `context` 形参 = 拥有者组件的代理（它是**构建单位**：有
    // build 方法、能被订阅标脏重建；宿主结点不是构建单位，不能当订阅锚点）。
    var ctx = contextOf(owner);
    var out = [];
    // 委托调用期间 owner 锚点指向方法体所在的组件实例：builder 里创建的
    // 控制器 / Key 归属它（`building` 在这里可能是宿主结点或已还原）。
    withOwner(owner, function () {
      for (var i = 0; i < n; i++) {
        out.push(owner[name].call(owner, ctx, i));
        if (typeof sep === 'string' && i < n - 1) {
          out.push(owner[sep].call(owner, ctx, i));
        }
      }
    });
    return out;
  }

  // 宿主结点索引（id → 结点实例）：只为「宿主上报 inflate」的反查用（懒槽位）。
  var hostNodes = {};

  // 宿主回调句柄：runtime 级常驻（scope=local 且不同步宿主——宿主只拿它的 id 走
  // 事件 invoke 通道回调，本端不需要留镜像）。
  var lazyMountFn = fn(function (id) { lazyMount(id); });

  // 懒槽位占位结点：普通宿主结点（SizedBox 0x0）+ `__lazy` 数据标记 + 回调句柄；
  // 真实子元素先存在 `__deferred`，本帧不挂载。
  function newLazySlot(parent, childEl, slot) {
    var hi = {
      __k: HOST, __id: nodeId('SizedBox'), __type: 'SizedBox',
      __root: rootFor(parent),
      __props: { width: 0, height: 0, __lazy: true, __lazyFn: lazyMountFn },
      __children: [], __parent: parent, __slot: slot,
      __deferred: childEl, __childIdx: slot ? slot.index : 0
    };
    hostNodes[hi.__id] = hi;
    emit({ op: 'create', id: hi.__id, type: hi.__type, props: hi.__props });
    if (slot && slot.hostParentId) {
      emit({ op: 'insert', parent: slot.hostParentId, id: hi.__id, index: slot.index });
    }
    return hi;
  }

  // 宿主 inflate 到懒槽位 → 真正挂载它的子元素（幂等：只对还没挂载过的占位生效）。
  // ops 纪律与 mountRoot 一致：挂载期间 `root.ops` 归本次挂载累积，挂载期间的
  // setState 只入 dirty 队列，收尾再 flush（见【8】）。
  function lazyMount(placeholderId) {
    var ph = hostNodes[placeholderId];
    if (!ph || !ph.__deferred) { return false; }
    var el = ph.__deferred;
    ph.__deferred = null;
    var root = ph.__root || rootFor(ph.__parent);
    if (!root) { return false; }
    var prev = activeRoot;
    activeRoot = root;
    root.mounting = true;
    root.ops = [];
    try {
      var inst = mount(el, ph.__parent, ph.__slot);
      // 占位换成真实结点：remove 排在本子树 create/insert 之后，父结点 childIds
      // 的下标序列保持不变（原文位置由真实结点顶上）。
      unmount(ph);
      commit(root);
    } finally {
      root.mounting = false;
      activeRoot = prev;
    }
    if (ph.__parent && ph.__parent.__children[ph.__childIdx] === ph) {
      ph.__parent.__children[ph.__childIdx] = inst;
    }
    // 挂载期间累积的 setState（如 initState 里同步 setState）补一次 flush。
    if (root.dirty.length) { flush(root); }
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
    try { return inst.build(contextOf(inst)); } finally { building = prev; }
  }

  function mount(el, parent, slot) {
    if (el == null || el === false) { return null; }

    if (typeof el.type === 'string') {
      var hi = {
        __k: HOST, __id: nodeId(el.type), __type: el.type, __root: rootFor(parent),
        __props: el.props, __children: [], __parent: parent
      };
      // 作用域声明（`__provides`）：由该宿主类型注册的 publisher 折算（【7】）。
      applyScope(hi, el.props);
      hostNodes[hi.__id] = hi;
      emit({ op: 'create', id: hi.__id, type: hi.__type, props: hi.__props });
      if (slot && slot.hostParentId) {
        emit({ op: 'insert', parent: slot.hostParentId, id: hi.__id, index: slot.index });
      }
      var idx = 0;
      // 懒容器（如 TabBarView）的 children 先只下发零尺寸占位（见 newLazySlot）：
      // 真实子树等宿主 inflate 到该槽位时回调再挂，否则「一次切 TabBarView」就把
      // 全部子页的 initState / 请求都跑掉了。
      var lazyChildren = lazyChildOf(hi.__type, hi.__props);
      var kids = expandBuilderChildren(el, hi);
      for (var i = 0; i < kids.length; i++) {
        var cel = kids[i];
        if (cel == null || cel === false) { continue; }
        var c = lazyChildren
            ? newLazySlot(hi, cel, { hostParentId: hi.__id, index: idx })
            : mount(cel, hi, { hostParentId: hi.__id, index: idx });
        if (c) { hi.__children.push(c); idx += 1; }
      }
      // props 里的 widget（单值 / 数组）与 delegate：单独挂载，不入 flatten
      // 列表，各自按 prop 名缓存（Scaffold.body / AppBar.actions 等）。
      hi.__propsChildren = {};
      hi.__propsChildrenList = {};
      hi.__propsData = {};
      patchPropSlots(hi, el.children || {});
      return hi;
    }

    var ownFrame = beginConstruct();
    var ci;
    try {
      ci = new el.type(el.props, el.children);
    } catch (e) {
      endConstruct(null, ownFrame);
      throw e;
    }
    ci.__k = COMP;
    ci.__id = compId(el.type);
    // 构造期（字段初始化）里登记的控制器 / Key 句柄归属本实例：此刻 `ci` 才存在，
    // 故构造期间先暂存、新对象返回后再回填（见 handle_registry_js 的 beginConstruct）。
    endConstruct(ci, ownFrame);
    ci.__el = el;
    ci.__parent = parent;
    ci.__slot = slot;
    ci.__root = rootFor(parent);
    augment(ci);
    // 生命周期与 Flutter 对齐：initState → didChangeDependencies → build。
    // （后续「依赖变更」走 flush 的 __depDirty，「父级重建」走 patch 的
    //  didUpdateWidget，见【8】/【9】。）
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
    if (el == null || el === false) {
      if (oldInst) { unmount(oldInst); }
      return null;
    }
    if (!oldInst) {
      var mi = mount(el, parent, slot);
      if (mi && propSlot) { mi.__propSlot = propSlot; }
      return mi;
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
      if (!eq(oldProps, el.props, 4)) {
        emit({ op: 'props', id: oldInst.__id, props: el.props });
      }
      oldInst.__props = el.props;
      // props 变更 → 作用域声明重放（provider 的 vm 实例可能已换）。
      applyScope(oldInst, el.props);
      patchChildren(oldInst, expandBuilderChildren(el, oldInst));
      patchPropSlots(oldInst, el.children || {});
      return oldInst;
    }

    // 复用同一实例（= Flutter 的 State 复用），只替换 element（= 新 Widget）。
    // 先取旧 props 作为 oldWidget 快照（el.props 每次 build 都是新对象，故旧引用
    // 自然保留），再把新 props 落到实例（`widget` 即新值），然后以旧 props 回调
    // didUpdateWidget，最后 build——顺序与 Flutter 完全一致。
    var oldWidget = oldInst.props;
    oldInst.__el = el;
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
      emit({
        op: 'propsChildAt', parent: slot.parentId, key: slot.key,
        index: slot.index, childId: newRoot
      });
    }
    return inst.__child;
  }

  function patchChildren(parentHost, newEls) {
    var old = parentHost.__children || [];
    var remaining = old.slice();
    var keyedOld = {};
    var i, j;
    // 带 key 的旧结点按**签名**建索引（keySig：ValueKey 按值 / ObjectKey 按身份 /
    // GlobalKey、UniqueKey 按句柄 id）。绝不能拿 key 对象直接当索引键——对象会被
    // 隐式 toString 成 "[object Object]"，所有 key 撞成一条。
    for (i = 0; i < old.length; i++) {
      var k = keySig(keyOf(old[i]));
      if (k != null) { keyedOld[k] = old[i]; }
    }

    var next = [];
    var hostIdx = 0;
    for (j = 0; j < newEls.length; j++) {
      var el = newEls[j];
      if (el == null || el === false) { continue; }
      var ek = keySig(el.props ? el.props.key : null);
      var matched = null;
      if (ek != null && keyedOld[ek]) {
        matched = keyedOld[ek];
        // 同一签名的 key 只认领一个旧结点：重复 key（Dart 侧本就是错误写法）
        // 时另一个按新建处理，绝不让同一实例被挂两次（会串坏 __parent/__slot）。
        keyedOld[ek] = null;
      } else if (ek == null) {
        for (i = 0; i < remaining.length; i++) {
          if (remaining[i] && keySig(keyOf(remaining[i])) == null) { matched = remaining[i]; break; }
        }
      }
      if (matched) { remaining.splice(remaining.indexOf(matched), 1); }

      // 懒槽位还没被宿主 inflate 过（`__deferred` 仍挂着子元素）→ 只把「待挂载的
      // 子元素」换成最新的，**绝不能**在这里把它挂载出来，否则重建（外壳每次切
      // tab 都会整树 patch）会把懒加载整个破坏掉。
      if (matched && matched.__deferred && lazyChildOf(parentHost.__type, parentHost.__props)) {
        matched.__deferred = el;
        matched.__childIdx = hostIdx;
        matched.__slot = { hostParentId: parentHost.__id, index: hostIdx };
        next.push(matched);
        hostIdx += 1;
        continue;
      }

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
  function patchSlotList(parentHost, oldList, newEls, slotKey) {
    var remaining = oldList.slice();
    var keyedOld = {};
    var i, j;
    for (i = 0; i < oldList.length; i++) {
      var k = keySig(keyOf(oldList[i]));
      if (k != null) { keyedOld[k] = oldList[i]; }
    }
    var next = [];
    for (j = 0; j < newEls.length; j++) {
      var el = newEls[j];
      if (el == null || el === false) { continue; }
      var ek = keySig(el.props ? el.props.key : null);
      var matched = null;
      if (ek != null && keyedOld[ek]) {
        matched = keyedOld[ek];
        keyedOld[ek] = null;
      } else if (ek == null) {
        for (i = 0; i < remaining.length; i++) {
          if (remaining[i] && keySig(keyOf(remaining[i])) == null) {
            matched = remaining[i];
            break;
          }
        }
      }
      if (matched) { remaining.splice(remaining.indexOf(matched), 1); }
      var slotIndex = next.length;
      var inst = patch(matched, el, parentHost, null, {
        key: slotKey,
        index: slotIndex,
        parentId: parentHost.__id
      });
      if (inst) { next.push(inst); }
    }
    for (i = 0; i < remaining.length; i++) {
      if (remaining[i]) { unmount(remaining[i]); }
    }
    return next;
  }

  function patchPropSlots(hostInst, newSlots) {
    var oldS = hostInst.__propsChildren || {};
    var oldL = hostInst.__propsChildrenList || {};
    var oldD = hostInst.__propsData || {};
    var nextS = {}, nextL = {}, nextD = {};
    var i, k;
    for (k in newSlots) {
      if (k === '__items') { continue; }
      if (!Object.prototype.hasOwnProperty.call(newSlots, k)) { continue; }
      var v = newSlots[k];
      if (isElement(v)) {
        var prev = oldS[k] || null;
        var inst = patch(prev, v, hostInst, null);
        if (inst) {
          nextS[k] = inst;
          emit({ op: 'propsChild', parent: hostInst.__id, key: k, childId: hostIdOf(inst) });
        }
        if (oldL[k]) {
          for (i = 0; i < oldL[k].length; i++) { unmount(oldL[k][i]); }
          emit({ op: 'propsChildren', parent: hostInst.__id, key: k, childIds: [] });
        }
        if (oldD[k]) { emit({ op: 'propsDataRemove', parent: hostInst.__id, key: k }); }
        continue;
      }
      if (isElementList(v)) {
        var arr = patchSlotList(hostInst, oldL[k] || [], v, k);
        nextL[k] = arr;
        emit({
          op: 'propsChildren', parent: hostInst.__id, key: k,
          childIds: arr.map(hostIdOf)
        });
        if (oldS[k]) { unmount(oldS[k]); emit({ op: 'propsChildRemove', parent: hostInst.__id, key: k }); }
        if (oldD[k]) { emit({ op: 'propsDataRemove', parent: hostInst.__id, key: k }); }
        continue;
      }
      if (v != null && typeof v === 'object' && v.__delegate) {
        if (v.__delegate === 'list') {
          var arr2 = patchSlotList(hostInst, oldL[k] || [], v.children || [], k);
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
        if (oldS[k]) { unmount(oldS[k]); emit({ op: 'propsChildRemove', parent: hostInst.__id, key: k }); }
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
    if (!inst) { return; }
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
          try { inst.deactivate(); } catch (e) {}
        }
        if (typeof inst.dispose === 'function') {
          try { inst.dispose(); } catch (e) {}
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

''';
