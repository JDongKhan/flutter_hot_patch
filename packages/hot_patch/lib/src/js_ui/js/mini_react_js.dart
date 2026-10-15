// mini-react —— JS 侧 UI 运行时核心（框架核心，独立成文件）。
//
// 与 runtime_source.dart 的骨架入口/桥（【1】~【3】、【10】+尾部）拼接后
// 注入同一 IIFE：这里定义 element 描述、reconciler（mount/patch/unmount）、
// 组件基类（setState/__bind）、作用域（按类型名）查找与订阅、脏调度批处理。
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
  // 代码显式释放，如构建期 __bind 随组件卸载释放，见【1b】句柄注册表）。
  // 宿主侧回调用 invoke 触发。
  function fn(f) {
    var id = reg(f, 'fn', { scope: 'local', sync: false });
    return { __fn: id };
  }

  // 事件回传载荷统一为**参数数组**（Dart 侧 `_invoke(handler, args)` 的 args）：
  // 0 参事件 `[]`、onChanged `[v]`、多参事件 `[a,b]`…。句柄是普通位置函数——
  // 能力桥 `fn(function(t){…})` 按真实形参直接收下；__bind/__bindFn 生成的
  // wrapper 用 `arguments` 汇总任意个数再摊开调用目标方法。故 0/1/N 参事件共用
  // 同一条通路，新增多参事件无需改这里。
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

/// mini-react｜组件基类（setState / __bind，生成器产物的能力袋）【6】。
const String miniReactComponentBaseSource = r'''

  // ===== 【6】mini-react｜组件基类（生成器产物的能力袋）===============
  // 生成器产物**不** extends 本类：`augment` 把这些方法拷到实例上。
  // setState / __bind 属于 mini-react；上下文（`context.watch/read`）与
  // BuildContext 代理见【10.7】（调用面与 Dart 一致，不在实例上挂 `this.watch`）。
  function Component(props) { this.props = props || {}; }
  Component.prototype.setState = function (mutate) {
    if (typeof mutate === 'function') { mutate.call(this); }
    markDirty(this);
  };
  // ── 回到【6】mini-react｜事件句柄（__bind）────────────────────────────
  // 事件句柄：在**构建期**把事件表达式绑定到当前组件实例（Dart tear-off 语义）。
  // 生成器产出 `this.__bind("_incA")`——`this` 正是 build 作用域里的组件实例，
  // 也就是**定义该事件方法的组件**（含 Consumer/Builder 把 builder 方法
  // `.call(owner)` 的场景）。句柄随 props 传下去（`{__fn:id, __ev:原表达式}`），
  // 宿主点击时经 invoke(id) 回来；因为绑定信息挂在 props 上，包装型组件
  // （MultiProvider 透传 child）也不会把它弄丢。
  //   句柄执行时会还原**绑定时的构建位置**：事件表达式里的 `this.context.watch/read`
  //   按定义该表达式时的 context 位置解析（而非点击时的 `this`）。
  //   按 (实例, 表达式) 缓存：重建产出同一句柄 → props 稳定（增量补丁仍生效）；
  //   卸载时统一释放（markUnmounted）。
  Component.prototype.__bind = function (expr) {
    var bag = this.__bound || (this.__bound = {});
    if (bag[expr]) { return bag[expr]; }
    var self = this;
    var anchor = building || this; // 绑定时的 context 位置（见上）
    // 两种事件形态，触发即执行：裸方法名（`_incA`）→ 调实例方法；其余整体
    // 作为调用表达式求值（`this.context.read("T").inc()`）。**原样返回被调方法的
    // 返回值**：普通事件（点击 / 输入）由 invoke 丢弃返回值，语义不变；而
    // 「可等待事件」（EasyRefresh 的 onRefresh，见 capabilities/easy_refresh）
    // 靠这个返回值拿到 JS 侧的 Promise，await 完成后才回传宿主。
    var isName = /^[A-Za-z_$][A-Za-z0-9_$]*$/.test(expr);
    var run = isName
      // 方法名形态：句柄收到的参数数组用 apply 摊开成位置实参（支持 N 参事件）。
      ? function (args) {
          var m = self[expr];
          if (typeof m === 'function') { return m.apply(self, args); }
        }
      : function () {
          return new Function('return (' + expr + ');').call(self);
        };
    var handle = fn(function () {
      // 还原绑定时的构建位置：表达式若含 `this.context.watch/read`，按当时的
      // context 位置解析（点击时无 build 上下文，`building` 为 null）。
      // 事件位置实参在 `arguments` 里（invoke 已摊开），原样交给 run 转发。
      var prev = building;
      building = anchor;
      try { return run(arguments); }
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
    handle = fn(function () {
      var prev = building;
      building = anchor;
      // 位置实参在 `arguments` 里（invoke 已摊开），原样转发给闭包。
      // 返回值同 __bind：普通事件丢弃、可等待事件（EasyRefresh onRefresh）靠它拿 Promise。
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
          // 作用域依赖变更（__depDirty）走这里：与 Flutter 一致，
          // 先 didChangeDependencies 再 build；setState 触发的重建不调。
          if (inst.__depDirty) {
            inst.__depDirty = false;
            if (typeof inst.didChangeDependencies === 'function') {
              inst.didChangeDependencies();
            }
          }
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
  //   [ctx]        context（BuildContext 代理 —— build 传参 / `this.context`）
  // 对 extends Component 的类重复赋值无害。
  function augment(inst) {
    if (inst.props === undefined || inst.props === null) {
      inst.props = inst.__el ? inst.__el.props : {};
    }
    inst.setState = Component.prototype.setState;
    inst.__bind = Component.prototype.__bind;
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
    ci.__id = compId(el.type);
    ci.__el = el;
    ci.__parent = parent;
    ci.__slot = slot;
    ci.__root = rootFor(parent);
    augment(ci);
    // 生命周期与 Flutter 对齐：initState → didChangeDependencies → build。
    // （后续「依赖变更」走 flush 的 __depDirty，「父级重建」走 patch 的
    //  didUpdateWidget，见【8】/【9】。）
    if (typeof ci.initState === 'function') { ci.initState(); }
    if (typeof ci.didChangeDependencies === 'function') { ci.didChangeDependencies(); }
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
      // props 变更 → 作用域声明重放（provider 的 vm 实例可能已换）。
      applyScope(oldInst, el.props);
      patchChildren(oldInst, el.children);
      mountPropChildren(oldInst, oldProps, el.props || {});
      return oldInst;
    }

    // 复用同一实例（= Flutter 的 State 复用），只替换 element（= 新 Widget）。
    // 先取旧 props 作为 oldWidget 快照（el.props 每次 build 都是新对象，故旧引用
    // 自然保留），再把新 props 落到实例（`widget` 即新值），然后以旧 props 回调
    // didUpdateWidget，最后 build——顺序与 Flutter 完全一致。
    var oldWidget = oldInst.props;
    oldInst.__el = el;
    oldInst.props = el.props;
    oldInst.children = el.children;
    // props 变更 → 重新派生「构造参数字段」。生成器产物把 `this.x = args.x` 的
    // 参数↔字段映射放在 `__applyProps` 里；复用实例不会重跑构造函数，若不在此
    // 同步一次，子组件会一直拿着旧 props 派生的字段（如列表项不随排序刷新）。
    if (typeof oldInst.__applyProps === 'function') {
      oldInst.__applyProps(el.props);
    }
    if (typeof oldInst.didUpdateWidget === 'function') {
      oldInst.didUpdateWidget(oldWidget);
    }
    oldInst.__child = patch(oldInst.__child, buildOf(oldInst), oldInst, oldInst.__slot);
    return oldInst;
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
      // 与 Flutter 一致：从树上摘除时先 deactivate、再最终 dispose。
      if (typeof inst.deactivate === 'function') {
        try { inst.deactivate(); } catch (e) {}
      }
      if (typeof inst.dispose === 'function') {
        try { inst.dispose(); } catch (e) {}
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
      // [mini-react] 释放构建期登记的（实例, 表达式）事件句柄，避免句柄泄漏。
      var bag = inst.__bound;
      if (bag) {
        for (var k in bag) { releaseHandle(bag[k].__fn, false); }
        inst.__bound = null;
      }
      // 同理解放 __bindFn 登记的构建期闭包句柄。
      var bagFn = inst.__boundFn;
      if (bagFn) {
        for (var k in bagFn) { releaseHandle(bagFn[k].__fn, false); }
        inst.__boundFn = null;
      }
      markUnmounted(inst.__child);
    }
  }

''';
