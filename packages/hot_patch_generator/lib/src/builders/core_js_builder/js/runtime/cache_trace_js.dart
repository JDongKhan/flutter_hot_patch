// 缓存详细追踪**切面**（JS 侧，debug-only，默认关闭）。
//
// 需求：打开开关时逐条打印「JS 对象进 / 出句柄表」的日志；关闭时（含 release）
// 不得影响正常逻辑——既不计数、也不在 __registerHandle / __releaseHandle 里加分支。
//
// 做法：monkey-patch。开关关闭时 `__registerHandle` / `__releaseHandle` 就是原生
// 实现，零额外分支；打开后把它们替换为「调用原实现 + 打一条日志」的包装。
// 跨模块（flutter.js）经 `__core` 的转发函数调用，因此同样命中这层包装。
//
// 日志统一走宿主 log 通道（`debugPrint` 级别，release 下自动关闭），与 Dart 侧
// `[binding] + / -` 同格式，便于按 id 对齐两端。
const String cacheTraceJsSource = r'''
  var __cacheTraceOn = false;
  var __cacheTraceInstalled = false;

  // 一行摘要：id（构造名）· kind · scope · page · 持有者类型。
  function __cacheTraceLine(h) {
    var page = h.key || '-';
    var owner = h.owner ? (h.owner.__name || h.owner.__k || 'inst') : '-';
    return h.id + '（' + __constructorName(h) + '）· kind=' + h.kind
      + ' · scope=' + h.scope + ' · 页面=' + page + ' · 持有者=' + owner;
  }

  // 安装切面（幂等）：把 __registerHandle / __releaseHandle 换成「原实现 + 日志」。
  function __installCacheTrace() {
    if (__cacheTraceInstalled) { return; }
    __cacheTraceInstalled = true;
    var rawReg = __registerHandle;
    __registerHandle = function (obj, kind, opts) {
      // 同一对象重复登记返回同一 id（身份去重）——那种不算「新建」，不打印。
      var existed = (obj === null || obj === undefined)
        ? null : __handleOwnerIdx.get(obj);
      var id = rawReg(obj, kind, opts);
      if (__cacheTraceOn && id && id !== existed && __handles[id]) {
        G.debugPrint('[binding] + JS ' + __cacheTraceLine(__handles[id]));
      }
      return id;
    };
    var rawRelease = __releaseHandle;
    __releaseHandle = function (id, notify) {
      var h = __cacheTraceOn ? __handles[id] : null;
      rawRelease(id, notify);
      // 幂等释放（本地已删）不打印，避免与对端 release 重复刷屏。
      if (h) { G.debugPrint('[binding] - JS ' + __cacheTraceLine(h)); }
    };
  }

  // 宿主入口：打开 / 关闭详细追踪。关闭即包装内日志分支短路（只多一次布尔
  // 判断），不会再安装第二层包装。
  function __setCacheVerbose(on) {
    __cacheTraceOn = !!on;
    if (__cacheTraceOn) { __installCacheTrace(); }
  }
''';
