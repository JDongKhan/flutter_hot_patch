// 命令式弹层（showDialog 系列）：JS 侧把 builder 产出的元素树挂到**独立 root**。
//
// 为什么是独立 root：弹层内容里的 ChangeNotifier / 闭包 / 组件实例都留在 JS
// 本端，跨桥只传「面板 key + 标量 options + 关闭回传」。若把整棵树序列化过桥，
// 上述对象一个都过不去（用户已确认的结论）。
//
// 生命周期（与 Dart 的 showDialog 对齐到语义层）：
//   1. `showDialog(options)` 在本端执行 builder **一次**，得到元素树；
//   2. 向宿主发起 `jsuiPanelOpen`（key / kind / 锚点 / 标量 options），宿主用
//      自己的 showDialog（或 showModalBottomSheet …）push 一条路由，路由内容
//      是承载独立 store 的 `JsUiContent`；
//   3. 宿主首帧后回调 `__jsui.panelMount(key)`：以「调用方实例」为 parent、
//      `slot=null` 挂载（不产出 insert），commit 的补丁按 panelKey 路由到宿主
//      那份 store；
//   4. 关闭只有一条路径：barrier 点击 / 返回键 / `Navigator.pop(ctx, result)`
//      → 宿主 pop 路由 → 路由 Future 完成 → 宿主回调 `__jsui.panelClosed(key)`
//      → 本端卸载独立 root、结算 Promise。
//
// 已知语义差（设计内）：builder 只在打开时执行一次；弹层是独立 root，页面
// setState 不会连带重建弹层内容（弹层自己的 setState 照常生效）。
const String portalJsSource = r'''
  // 面板序号：key 既是 JS 侧独立根的 pageKey，也是宿主侧 store 的路由键。
  var panelSeq = 0;
  // key -> { key, kind, el, caller, root, result, hasResult, resolve, reject }
  var panels = {};

  function newPanelKey() {
    panelSeq += 1;
    return 'jsui_panel_' + panelSeq;
  }

  // 弹层参数里的「可跨桥的标量 / 值对象」：builder 与 context 留在本端，
  // 其余按 JSON 下发（Color 等值类自带 toJSON）。
  function panelOptionsJson(options) {
    var out = {};
    for (var k in options) {
      if (k === 'context' || k === 'builder') { continue; }
      var v = options[k];
      if (v === null || v === undefined) { continue; }
      if (typeof v === 'function') { continue; }
      out[k] = v;
    }
    return out;
  }

  // 按「消费它的调用位置」定位面板。三条命中路径按可信度排序：
  //   1. 面板上下文代理（builder 的形参 ctx 被打了 `__panelKey`）——最准，
  //      嵌套 showDialog 时每个 builder 各自指向自己的面板，不会串台；
  //   2. 组件实例的 `__root` 是面板根（弹层内容里的组件调 pop）——按树归属；
  //   3. 兜底：同一调用方打开的面板里**最近打开**的那个（LIFO，与 Dart 里
  //      `Navigator.pop` 弹最上层路由同义）。
  function panelOf(context) {
    if (context && context.__panelKey) {
      var tagged = panels[context.__panelKey];
      if (tagged) { return tagged; }
    }
    var inst = null;
    if (context && context.__anchor) { inst = context.__anchor; }
    else if (context && context.__root) { inst = context; }
    else if (building) { inst = building; }
    if (!inst) { return null; }
    var root = inst.__root;
    if (root && panels[root.key]) { return panels[root.key]; }
    var found = null;
    for (var k in panels) {
      if (panels[k].caller === inst) { found = panels[k]; }
    }
    return found;
  }

  // 打开面板：builder 执行一次 → 建面板记录 → 请求宿主 push 路由。
  // 返回的 Promise 与 Dart `showDialog<T>` 的 Future 同义（结果为 pop 传的值）。
  function openPanel(kind, options) {
    if (!options || typeof options !== 'object') { options = {}; }
    // 调用方实例：事件执行期取当前构建位置；延迟副作用里（`building` 为空）取
    // 传入 context 代理的锚点实例——面板根因此挂在调用方的 `__parent` 链上，
    // 弹层里的 `context.watch/read` 仍能看到页面的 provider 作用域。
    var given = options.context;
    var caller = building || (given && given.__anchor) || null;
    var callerNode = given && given.__nodeId
      ? given.__nodeId
      : (caller ? contextOf(caller).__nodeId : null);
    var key = newPanelKey();
    // builder 的形参 ctx：**专用代理**（不打在调用方那个缓存代理上——`contextOf`
    // 按实例缓存，共用会把页面的代理永久指向某个面板）。带 `__panelKey` 后
    // `Navigator.pop(ctx)` / `Navigator.of(ctx)` 精确落到本面板，嵌套 showDialog
    // 也不会串台。
    var anchor = new JsBuildContext(caller, callerNode);
    anchor.__panelKey = key;
    // 建树回调按 Flutter 的原形参名取：`showDialog` / `showModalBottomSheet`
    // 等用 `builder`，`showGeneralDialog` 用 `pageBuilder`——两者都是「在弹层
    // 上下文里建一次树」，协议相同，这里不按 API 名特判。
    var buildFn = typeof options.builder === 'function'
      ? options.builder
      : (typeof options.pageBuilder === 'function' ? options.pageBuilder : null);
    var built = null;
    if (buildFn) {
      // 与 Dart 一致：建树回调立即执行（在弹层上下文里建树）。
      // 只传 ctx：`pageBuilder` 的 animation / secondaryAnimation 是宿主侧的
      // 动画对象，JS 端没有可等价的值（用到的话属于未支持项）。
      built = buildFn(anchor);
    }
    var el = asElement(built);
    var p = {
      key: key, kind: kind, el: el, caller: caller, root: null,
      result: null, hasResult: false, resolve: null, reject: null
    };
    var promise = new Promise(function (resolve, reject) {
      p.resolve = resolve;
      p.reject = reject;
    });
    panels[key] = p;
    host('jsuiPanelOpen', [{
      key: key,
      kind: kind,
      anchor: anchor.__nodeId,
      options: panelOptionsJson(options)
    }]).then(function () {}, function (err) {
      // 宿主没打开（无可用 BuildContext / 路由失败）：撤销本端记录，让
      // `await showDialog(...)` 的调用方拿到异常，而不是永远悬着的 Promise。
      if (panels[key] === p) { delete panels[key]; }
      if (p.reject) { p.reject(err); }
    });
    return promise;
  }

  // 宿主首帧后回调：把 builder 产出的元素树挂到独立根上并下发首批补丁。
  // 幂等：重复调用（重建 / 二次回调）直接返回。
  function panelMount(key) {
    var p = panels[key];
    if (!p || p.root) { return false; }
    var root = newRoot(key);
    roots[key] = root;
    var prev = activeRoot;
    activeRoot = root;
    root.mounting = true;
    try {
      root.ops = [];
      // parent = 调用方实例：`__parent` 链因此与页面连通（provider 等按类型
      // 向上的作用域照常可见）；slot=null 故不产出 insert op。
      root.inst = mount(p.el, p.caller, null);
      emit({ op: 'root', id: hostIdOf(root.inst) });
      commit(root);
    } catch (e) {
      abortRoot(root);
      throw e;
    } finally {
      root.mounting = false;
      activeRoot = prev;
    }
    p.root = root;
    // 挂载期间累积的 setState（initState 里同步 setState）补一次 flush。
    if (root.dirty.length) { flushNow(root); }
    return true;
  }

  // 宿主路由关闭后回调（barrier / 返回键 / Navigator.pop 都汇到这一条）：
  // 卸载独立根 → 结算 Promise。本端清理由 unmount 逐实例释放，页面兜底
  // （releasePageHandles）保证任何残留都不会跨面板累积。
  function panelClosed(key) {
    var p = panels[key];
    if (!p) { return false; }
    delete panels[key];
    var root = p.root || roots[key] || null;
    p.root = null;
    p.el = null;
    p.caller = null;
    if (root && root.inst) {
      var prev = activeRoot;
      activeRoot = root;
      try {
        // ops 丢弃即可：宿主那棵子树随路由一起销毁，无需回传 remove。
        root.ops = [];
        unmount(root.inst);
      } finally {
        root.ops = null;
        activeRoot = prev;
      }
      root.inst = null;
    }
    delete roots[key];
    releasePageHandles(key);
    var resolve = p.resolve;
    p.resolve = null;
    p.reject = null;
    if (resolve) { resolve(p.hasResult ? p.result : null); }
    return true;
  }

  // `Navigator.pop(context, result)` 的 JS 侧落点：结果**不回传宿主**（宿主
  // 侧路由只负责关闭），所以 pop 传的值留在本端，关闭回调时直接结算。
  //
  // 返回 false 表示 context 不在任何面板里：页面级路由由宿主 App 自己管理，
  // JS 侧不越权（也做不到——路由栈在 Dart）。
  function panelPop(context, result) {
    var p = panelOf(context);
    if (!p) {
      // 明确出声：这类调用不会被静默忽略，否则表现为「点了没反应」。
      console.warn('jsui: Navigator.pop 未命中任何弹层面板（页面级路由请由宿主管理）');
      return false;
    }
    p.result = result;
    p.hasResult = true;
    host('jsuiPanelPop', [p.key]).then(function () {}, function () {});
    return true;
  }

  // ── 对外注入（生成器对裸顶层调用原样产出同名调用，见 runtime_global_types）──
  // Dart 侧签名（NamedArgument 全部落进 options 对象，由宿主按 kind 还原）：
  //   showDialog<T>({context, builder, barrierDismissible, barrierColor, …})
  G.showDialog = function (options) { return openPanel('dialog', options); };
  // 自适应：iOS / macOS 走 Cupertino，其余走 Material（宿主调 showAdaptiveDialog）。
  G.showAdaptiveDialog = function (options) { return openPanel('adaptive', options); };
  G.showGeneralDialog = function (options) { return openPanel('general', options); };
  G.showCupertinoDialog = function (options) { return openPanel('cupertino', options); };
  G.showModalBottomSheet = function (options) { return openPanel('sheet', options); };
  // Cupertino 的模态弹层（通常承载 CupertinoActionSheet）：与 Material 的
  // showModalBottomSheet 语义不同（路由/动画/安全区归属都是 Cupertino 的）。
  G.showCupertinoModalPopup = function (options) { return openPanel('cupertinoSheet', options); };

  // `Navigator` 的对外类在 flutter.js 值类区（navigator_js.dart）：它只做
  // 形状，实际落点是上面的 panelPop / panelOf，经 `G.__core` 交接。
''';
