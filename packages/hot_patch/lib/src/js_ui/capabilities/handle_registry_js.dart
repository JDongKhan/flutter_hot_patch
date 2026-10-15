// 跨语言句柄注册表（JS 侧核心，通用层地基）。
//
// 解决问题：JS 与 Dart 各有一批「真实对象」（JS 的代理实例 / 闭包，Dart 的
// ScrollController / Key / …），一端需要操作另一端的对象。此前每个能力各写
// 一套通道 + 一张 id 表（fn / sc / tec / tc），新增能力就要动核心文件。
//
// 本片段把这件事收敛成**一套**机制：一个真实对象登记为一个**句柄**（id），
// 对端只持 id，所有操作按 id 转发给拥有端。对象、函数/block、控制器、未来
// 的 Key / VM / Widget 都只是不同 `kind`，新增能力 = 注册一个 kind 描述符，
// 核心文件（本文件 / runtime_source 骨架 / disposeRoot）零改动。
//
// id 规则：`js:<kind>#<序号>`（kind 本身可带子类，如 `ctrl/Scroll`）——
// 序号全局单调仅用于唯一化，kind 用于一眼看懂是什么对象。
//
// scope：
//   - page   ：随页面释放（登记时绑 activeRoot.key，disposeRoot 统一回收）；
//   - global ：跨页面常驻，不随页面释放；
//   - local  ：由拥有者自己的代码显式释放（如构建期事件句柄，随组件卸载释放）。
//
// 释放语义（拥有端为准 + 页面兜底）：任一端 release 都会通知对端一并释放
// （1:1 资源两端必须同时消失）；重复 release 幂等，不会形成通知回环。
//
// **为什么本片段刻意不是 [JsUiLibrary.jsFragments]**（地基而非能力）：
//   1. 它必须拼在 mini-react 骨架**之前**（见 runtime_source 的拼接位置），
//      而模板片段统一落在骨架之后；
//   2. 各能力片段的**顶层**就调用 defineHandleKind(...)（需 handleKinds 已
//      初始化）；地基必须先于一切能力；
//   3. 与宿主侧 handle_registry.dart 同因：它是插座，不是插头，永无第二实现。
const String handleRegistryJsSource = r'''
  // ===== 【1b】跨语言句柄注册表（通用层地基）===========================
  // handleSeq 与 idSeq 相互独立：句柄 id 与结点 id 分属两套命名空间。
  var handleSeq = 0;
  // id -> { id, kind, scope, key, obj, meta }
  var handles = {};
  // 对象 -> id：同一对象重复登记返回同一 id（身份去重，WeakMap 不阻止回收）。
  var handleOwnerIdx = new WeakMap();
  // kind -> { release(h) }：JS 本端登记时的真实资源清理（可选）。对端的清理
  // 由对端各自的 kind 描述符负责，跨桥只传 id + op。
  var handleKinds = {};

  function defineHandleKind(name, desc) { handleKinds[name] = desc || {}; }

  // 句柄 id：`js:<kind>#N`（kind 形如 `fn` / `ctrl/Scroll` / `key`）。
  function newHandleId(kind) {
    handleSeq += 1;
    return 'js:' + kind + '#' + handleSeq;
  }

  // 登记一个 JS 侧真实对象/函数为句柄，返回 id。scope 缺省 page（绑定当前
  // 页面）；activeRoot 缺失导致无法定位页面时退化为 global，避免「登记了却
  // 永不释放」。
  function reg(obj, kind, opts) {
    if (obj === null || obj === undefined) { return null; }
    var exist = handleOwnerIdx.get(obj);
    if (exist && handles[exist]) { return exist; }
    opts = opts || {};
    var scope = opts.scope || 'page';
    var key = null;
    if (scope === 'page') {
      key = opts.key || (activeRoot && activeRoot.key) || null;
      if (key === null) { scope = 'global'; }
    }
    var id = newHandleId(kind);
    handles[id] = {
      id: id, kind: kind, scope: scope, key: key, obj: obj,
      meta: opts.meta || null
    };
    handleOwnerIdx.set(obj, id);
    if (scope === 'page') {
      (pageHandles[key] || (pageHandles[key] = [])).push(id);
    }
    // 自动同步宿主：宿主侧同名 kind 描述符的 onCreate 据此创建真实对象
    // （scope=local 的纯本端句柄——如事件闭包——传 sync:false 不同步）。
    // pageKey 一并下发：宿主侧据此登记「句柄→页面」，页面销毁时做本端兜底回收。
    if (opts.sync !== false) {
      host('jsHandle', [{
        id: id, op: 'create', kind: kind, pageKey: key, meta: opts.meta || null
      }]);
    }
    return id;
  }

  // 释放一个句柄（本端）。幂等：不存在即返回（不回环——对端释放时本地已删，
  // 不再二次通知）。notify=false 用于纯本端句柄（如构建期事件句柄）。
  function releaseHandle(id, notify) {
    var h = handles[id];
    if (!h) { return; }
    delete handles[id];
    if (h.obj) { try { handleOwnerIdx.delete(h.obj); } catch (e) {} }
    if (h.scope === 'page' && h.key && pageHandles[h.key]) {
      var arr = pageHandles[h.key];
      var i = arr.indexOf(id);
      if (i >= 0) { arr.splice(i, 1); }
    }
    var desc = handleKinds[h.kind];
    if (desc && typeof desc.release === 'function') {
      try { desc.release(h); } catch (e) {}
    }
    if (notify !== false) { host('jsHandle', [{ id: id, op: 'release' }]); }
  }

  // 页面退出兜底：释放本页登记的全部 page 句柄（数组边遍历边被 releaseHandle
  // 摘除，故拷贝一份再遍历）。
  function releasePageHandles(pageKey) {
    var arr = pageHandles[pageKey];
    if (!arr) { return; }
    var snapshot = arr.slice();
    for (var i = 0; i < snapshot.length; i++) { releaseHandle(snapshot[i]); }
    delete pageHandles[pageKey];
  }

  // 宿主 → JS：按 id 在**本端**真实对象上执行 op（宿主侧句柄注册表经 evaluate
  // 调用，见 __jsui.call）。返回结果供宿主回填（Promise 场景）。
  //   invoke：函数句柄调用（args 数组）
  //   call  ：对象方法调用（method + args）
  //   get/set：属性读写（name）
  function callHandle(id, op, payload) {
    var h = handles[id];
    if (!h) {
      if (typeof console !== 'undefined' && console.warn) {
        console.warn('jsui: handle not found (released?): ' + id + ' op=' + op);
      }
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

  // 宿主 → JS：释放本端句柄（对端发起的 release，不再回通知）。
  function releaseFromHost(id) { releaseHandle(id, false); }

  // JS → 宿主：对本端句柄对应的**宿主端真实对象**发起 op（返回 Promise）。
  // 与 callHandle 方向相反、语义对称（call/get/set/invoke）。
  function handleOp(id, op, payload) {
    var body = { id: id, op: op };
    if (payload) { for (var k in payload) { body[k] = payload[k]; } }
    return host('jsHandle', [body]);
  }

''';
