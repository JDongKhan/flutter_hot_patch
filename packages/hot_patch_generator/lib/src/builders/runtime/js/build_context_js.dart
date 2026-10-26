// 由 runtime_js.dart 拆出的 BuildContext 代理片段（能力内聚，见 capabilities/ 设计规范）。
//
// **调用面与 Dart 完全一致**：用户写的 `context.xxx` 里的 `context` 就是本代理。
// 它与 Dart 侧原生 BuildContext 一一对应，关系（绑定）就建立在这里：
//   - `__anchor` ：消费它的 JS 组件实例（watch/read 按**构建位置**取值）；
//   - `__nodeId` ：最近宿主祖先结点 id —— 宿主侧 `nodeId → BuildContext` 的键，
//                  由 _JsNodeState 在 build 期间登记（element 级 scope）；
//   - `__id`     ：跨语言句柄（kind=ctx/BuildContext），宿主凭它反查真值
//                  BuildContext 并执行同名 op ——「调 context 的任何方法实际
//                  就是调 Dart 端 context」。
//
// **本片段只是机制，不含任何库的 API**：`watch` / `read` 等方法由各自的三方库
// 在自己片段里补到 `JsBuildContext.prototype` 上（对齐 Dart 的
// `extension BuildContextX on BuildContext`）——见 capabilities/provider/provider_js.dart。
// 宿主侧由核心的 `registerContextOp` 分发给注册者，核心不认识具体 op 名。
//
// 代理由运行时在 build 时**传入**（`inst.build(ctx)`，对应 Dart 的
// `build(BuildContext context)` 签名）；`this.context` 是同一条同步可达路径
// （事件/延迟作用域里形参不可见），但按**执行位置**解析：`building` 非空时取
// 它的代理——被委托的 builder 方法（`this` 是 owner）因此拿到**被委托组件**的
// 代理，与 Dart 里闭包捕获 `context` 形参同语义（见 mini-react【7】的 augment）。
//
// 同步约束（设计内）：库在自己补的 `watch` 里做的**取值**必须同步（渲染期
// `model.count` 要直接读），而 JS→宿主只有异步桥，故取值在本端按**类型名**沿
// `__parent` 从最近的作用域结点取（通用机制，见 mini-react【8】的 `scopeOf`；
// 作用域声明见各三方库的接入文件，如 capabilities/provider/provider_js.dart）。
const String buildContextJsSource = r'''
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

  // `context.watch<T>()` / `read<T>()` **不在这里**：它们不是框架 API，而是
  // provider 那类 `extension BuildContextX on BuildContext`——方法补丁在
  // capabilities/provider/provider_js.dart，宿主侧处理见 provider/context_ops.dart。
  // 本片段只提供机制：代理、句柄、`contextOf`/`buildContextOf`、通用 op 转发。

  // 组件实例 → 代理（每个实例一个，缓存进 `__ctx`）。**同一执行位置**下，
  // build 形参与 `this.context` 是同一个对象：前者由 buildOf 传入 `contextOf(inst)`，
  // 后者由 getter 传 `building`，而 `buildOf` 期间 `building === inst`。
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
