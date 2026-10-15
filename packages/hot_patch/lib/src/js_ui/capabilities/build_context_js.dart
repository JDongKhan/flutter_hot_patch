// 由 runtime_source.dart 拆出的 BuildContext 代理片段（能力内聚，见 capabilities/ 设计规范）。
//
// **调用面与 Dart 完全一致**：用户写的 `context.watch<T>()` / `context.read<T>()`
// / `context.xxx` 里的 `context` 就是本代理。它与 Dart 侧原生 BuildContext
// 一一对应，关系（绑定）就建立在这里：
//   - `__anchor` ：消费它的 JS 组件实例（watch/read 按**构建位置**取值）；
//   - `__nodeId` ：最近宿主祖先结点 id —— 宿主侧 `nodeId → BuildContext` 的键，
//                  由 _JsNodeState 在 build 期间登记（element 级 scope）；
//   - `__id`     ：跨语言句柄（kind=ctx/BuildContext），宿主凭它反查真值
//                  BuildContext 并执行同名 op ——「调 context 的任何方法实际
//                  就是调 Dart 端 context」。
//
// 代理由运行时在 build 时**传入**（`inst.build(ctx)`，对应 Dart 的
// `build(BuildContext context)` 签名），并缓存为 `this.context`：事件/延迟
// 作用域里形参不可见，`this.context` 是同一对象的同步可达路径。
//
// 唯一的例外（同步约束，设计内）：`watch`/`read` 的**取值**必须同步（渲染期
// `model.count` 要直接读），而 JS→宿主只有异步桥，故 VM 实例在本端沿 `__parent`
// 取（provider 宿主结点带 vm 实例）；同时照常向宿主发同名 op，由宿主在**真实
// BuildContext** 上登记依赖（Dart 语义照落）。
const String buildContextJsSource = r'''
  // ===== 【10.7】BuildContext 代理（`context.watch/read/…`）===============
  defineHandleKind('ctx/BuildContext', {});

  function JsBuildContext(anchor, nodeId) {
    // 消费它的 JS 组件实例（watch/read 的构建位置锚点）。
    this.__anchor = anchor;
    // 最近宿主祖先结点 id（宿主侧 nodeId -> 真值 BuildContext 的键）。
    this.__nodeId = nodeId;
    // 跨语言句柄：**惰性**登记（没用过 context 的组件零句柄开销）。
    this.__id = null;
  }

  // 句柄（首次真正需要宿主真值时才登记，宿主 onCreate 绑定 nodeId）。
  JsBuildContext.prototype.__handle = function () {
    if (this.__id == null) {
      this.__id = reg(this, 'ctx/BuildContext', {
        meta: this.__nodeId == null ? null : { node: this.__nodeId }
      });
    }
    return this.__id;
  };

  // 向宿主真值 BuildContext 发同名 op（其余 context API 走这条路）。
  // JS→宿主只有异步桥，故 fire-and-forget：不阻塞本端同步渲染，失败静默丢弃
  // （页面卸载竞态下句柄可能已释放）。
  JsBuildContext.prototype.__host = function (op, payload) {
    try {
      var p = handleOp(this.__handle(), op, payload);
      if (p && typeof p.catch === 'function') { p.catch(function () {}); }
    } catch (e) {}
  };

  // `context.watch<T>()`：取最近 provider 的实例并订阅（模型 notify 时只重建
  // 调用 watch 的那个位置）。取值同步（见文件头），依赖登记交给宿主。
  JsBuildContext.prototype.watch = function (type) {
    var vm = findVm(this.__anchor, type);
    if (vm == null) { this.__host('watch', { type: type }); return undefined; }
    subscribeVm(this.__anchor, vm);
    this.__host('watch', { type: type });
    return vm;
  };

  // `context.read<T>()`：仅取实例，不订阅（按钮回调里的合法用法）。
  JsBuildContext.prototype.read = function (type) {
    this.__host('read', { type: type });
    var vm = findVm(this.__anchor, type);
    return vm == null ? undefined : vm;
  };

  // 组件实例 → 代理（每个实例一个，缓存；build 传参与 `this.context` 同一对象）。
  function contextOf(inst) {
    if (inst.__ctx == null) { inst.__ctx = buildContextOf(inst); }
    return inst.__ctx;
  }

  // 建立代理：结点锚点 = 最近宿主祖先结点 id。上溯不到说明是**根组件**
  // （COMP 之上再没有宿主结点）——退回页面锚点 `page:<pageKey>`（由
  // JsUiWidgetState 在 build 期间登记的上下文），保证根组件一样拿到真值。
  // 两条都取不到时 nodeId 为 null：代理仍可用（宿主侧反查不到），不抛错——
  // 构建顺序变化不应让组件构建失败。
  function buildContextOf(inst) {
    var node = inst;
    while (node && node.__k !== HOST) { node = node.__parent; }
    if (node) { return new JsBuildContext(inst, node.__id); }
    var root = activeRoot || inst.__root;
    return new JsBuildContext(inst, root ? 'page:' + root.key : null);
  }
''';
