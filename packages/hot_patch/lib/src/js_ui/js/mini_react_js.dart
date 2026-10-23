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

  // 组件实例 → 元素描述：生成类与普通类一样「构造即实例」，父级把它当子结点
  // 消费时在这里统一折算（与 flutter.js 的 __asElement 同一协议）。
  // `inst` 随元素一起携带：mount 直接复用该实例，**不再 new 第二次**。
  function asElement(v) {
    if (v == null || typeof v !== 'object' || v.element === true) { return v; }
    var C = v.constructor;
    if (typeof C === 'function' && C.prototype &&
        typeof C.prototype.build === 'function') {
      return {
        type: C, props: v.props || {}, children: {}, element: true, inst: v
      };
    }
    return v;
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

/// props 深比较的最大递归深度（编译期配置）。
///
/// 原实现固定 `4`：超过 4 层的嵌套 props（如 style → decoration → gradient →
/// colors 这类结构）变化会被判为相等，导致 patch 不下发、UI 不刷新。
/// 这里提高到 32 并把入口改为函数，深度只在 Dart 常量一处维护。
const int jsUiMaxPropDiffDepth = 32;

/// mini-react｜reconciler 工具（eq / keyOf / hostIdOf / rootFor）【5】。
String miniReactReconcilerUtilsSource() =>
    _miniReactReconcilerUtilsSource.replaceFirst(
      '__EQ_MAX_DEPTH__',
      '$jsUiMaxPropDiffDepth',
    );

const String _miniReactReconcilerUtilsSource = r'''

  // ===== 【5】mini-react｜reconciler 工具 ==============================
  // 深比较（用于避免每次重建都下发 props）；下面紧邻的 keyOf / hostIdOf /
  // rootFor 同属本分区。
  var EQ_MAX_DEPTH = __EQ_MAX_DEPTH__;
  function eq(a, b, depth) {
    if (a === b) { return true; }
    if (depth === undefined || depth === null) { depth = EQ_MAX_DEPTH; }
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
  function findOwner(parent, name) {
    var owner = parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner || null;
  }

  function builderSpec(el) {
    var slots = el.children || {};
    var b = slots.__builder;
    if (b && typeof b.item === 'string' && typeof b.count === 'number') {
      return { item: b.item, sep: b.sep, count: b.count, ctx: b.ctx };
    }
    var d = slots.delegate;
    if (!d || d.__delegate !== 'builder' || typeof d.builder !== 'string') {
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
    // 委托调用期间 owner 锚点指向方法体所在的组件实例：builder 里创建的
    // 控制器 / Key 归属它（`building` 在这里可能是宿主结点或已还原）。
    withOwner(owner, function () {
      var sep = spec.sep;
      if (typeof sep === 'string' && sep && slotIndex % 2 === 1) {
        out = owner[sep].call(owner, ctx, (slotIndex - 1) / 2);
      } else {
        out = owner[spec.item].call(owner, ctx, sep ? slotIndex / 2 : slotIndex);
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
    var owner = findOwner(parent, spec.item);
    if (!owner) { return out; }
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

  // 宿主回调句柄：runtime 级常驻（scope=local 且不同步宿主——宿主只拿它的 id 走
  // 事件 invoke 通道回调，本端不需要留镜像）。
  //   - lazyMount：宿主 element **inflate**（首次布局到该槽位）；
  //   - lazyUnmount：宿主 element **dispose**（ListView 回收离屏项 / 页面销毁）——
  //     与 Flutter 同寿：离屏项的 State 被销毁，滚回来再 initState 重新构建。
  //     没有这条通知，JS 侧挂过的 item 会永远活着（滚到底后每次重建都在 patch
  //     全量 item），列表越长越糟。
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
      if (typeof console !== 'undefined' && console.warn) {
        console.warn('jsui: lazy slot builder returned empty, keep mounted subtree');
      }
      return ph;
    }
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
    return ph;
  }

  // 宿主 inflate 到懒槽位 → 真正挂载它的子元素（幂等：只对还没挂载过的占位生效）。
  // ops 纪律与 mountRoot 一致：挂载期间 `root.ops` 归本次挂载累积，挂载期间的
  // setState 只入 dirty 队列，收尾再 flush（见【8】）。
  function lazyMount(placeholderId) {
    var ph = hostNodes[placeholderId];
    if (!ph || (!ph.__deferred && !ph.__deferMake)) { return false; }
    // 延迟工厂（builder 子项）在这里才执行：全树只展开「宿主真正 inflate 到」的那些。
    var el = ph.__deferred;
    if (el == null && ph.__deferMake) { el = ph.__deferMake(); }
    if (el == null || el === false) {
      if (typeof console !== 'undefined' && console.warn) {
        console.warn('jsui: lazy slot builder returned empty, placeholder=' + placeholderId);
      }
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
      ph.__props = mountedProps;
      emit({ op: 'props', id: ph.__id, props: ph.__props });
      emit({ op: 'propsChild', parent: ph.__id, key: 'child', childId: ph.__mountedRootId });
      commit(root);
    } finally {
      root.mounting = false;
      activeRoot = prev;
    }
    // 挂载期间累积的 setState（如 initState 里同步 setState）补一次 flush。
    if (root.dirty.length) { flush(root); }
    return true;
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
      // unmount 派发 deactivate → dispose，并下发子树 remove；宿主侧的 element
      // 已随本次 dispose 一起销毁，store 按 remove 递归摘除结点。
      unmount(inst);
      emit({ op: 'propsChildRemove', parent: ph.__id, key: 'child' });
      commit(root);
    } finally {
      root.mounting = false;
      activeRoot = prev;
    }
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
    el = asElement(el);
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
      ci = (el.inst && !el.inst.__unmounted)
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

  // [srcs] 是子项来源（见 childSources）：`{el}` 直接元素 / `{make}` 延迟工厂。
  // [lazy] 来自新元素的 `el.lazyChildren`（运行时不做类型判断）。
  function patchChildren(parentHost, srcs, lazy) {
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
    for (j = 0; j < srcs.length; j++) {
      var src = srcs[j];
      if (!src) { continue; }
      var el = src.el !== undefined ? src.el : null;
      // 延迟工厂形态在展开前没有 element（也没有 key），只能按位置匹配。
      if (src.el !== undefined && (el == null || el === false)) { continue; }
      var ek = keySig(el && el.props ? el.props.key : null);
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

      // 已存在的懒槽位（未挂载的来源 / 已挂载的 `__mountedChild`）→ 只更新子元素，
      // **绝不能**在这里把未挂载的槽位挂出来，否则重建（外壳每次切 tab 都会整树
      // patch）会把懒加载整个破坏掉。
      if (matched && lazy && matched.__lazySlot) {
        matched.__slot = { kind: 'children', hostParentId: parentHost.__id, index: hostIdx };
        patchLazySlot(matched, src);
        // 懒槽位同样要跟随排序：宿主 `childIds` 的顺序只由 insert/move 决定。
        if (old.indexOf(matched) !== hostIdx) {
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
  // 父结点是懒容器时，**每一项**都先落成懒槽位（未 visit 的子页不挂载）：
  // 已有槽位只更新 deferred / patch 子树；新项创建占位而不是立刻 mount。
  // [lazy] 由所在宿主元素的 `el.lazyChildren` 传入（运行时不做类型判断）。
  function patchSlotList(parentHost, oldList, newEls, slotKey, lazy) {
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
    for (i = 0; i < remaining.length; i++) {
      if (remaining[i]) { unmount(remaining[i]); }
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
